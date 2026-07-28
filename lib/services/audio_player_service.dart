import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:etherly/models/cast_device.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/app_audio_handler.dart';
import 'package:etherly/services/chrome_cast_service.dart';
import 'package:etherly/services/listening_stats_service.dart';

/// Service that manages the [AudioPlayer] instance, station list, and playback logic.
class AudioPlayerService with ChangeNotifier {
  static const String _lastStationIdKey = 'last_station_id';
  static const String _favoriteStationIdsKey = 'favorite_station_ids';
  static const String _volumeKey = 'volume';
  static const String _isMutedKey = 'is_muted';
  static const String _preMuteVolumeKey = 'pre_mute_volume';
  static const int _autoPlayCountdownStart = 3;

  /// The underlying [AudioPlayer] instance.
  final AudioPlayer player = AudioPlayer();

  /// ValueNotifier indicating whether the service is fully initialized.
  final ValueNotifier<bool> isReady = ValueNotifier(false);

  /// Autoplay countdown ValueNotifier.
  final ValueNotifier<int> autoplayCountdownNotifier = ValueNotifier(0);

  /// Sleep timer active status ValueNotifier.
  final ValueNotifier<bool> sleepTimerActive = ValueNotifier(false);

  /// Current ICY stream metadata song title.
  String? currentSongTitle;

  /// Available stations.
  List<Station> stations = [];

  late final AppAudioHandler _audioHandler;
  final ChromeCastService? _castService;
  late final SharedPreferences _prefs;

  bool _isTransitioning = false;
  bool _isPlayIntended = false;
  String? _connectingStationId;

  final Completer<void> _initializationCompleter = Completer<void>();
  final ValueNotifier<bool> _radioPlayerShouldClose = ValueNotifier(false);

  Map<String, Station> _stationMap = {};
  List<String> _favoriteStationIds = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _stationsSubscription;
  Timer? _listeningMinuteTimer;
  Timer? _autoplayTimer;
  bool _autoplayCancelled = false;
  Timer? _sleepTimer;
  Timer? _bufferingTimeoutTimer;
  Timer? _castTransitionTimer;
  MediaItem? _currentMediaItem;
  bool _isMuted = false;
  double _preMuteVolume = 1.0;

  /// Creates the service and attaches listeners to optional cast service.
  AudioPlayerService([this._castService]) {
    _castService?.isRemotePlaying.addListener(_onCastRemotePlayingChanged);
    _castService?.addListener(_onCastingStateChanged);
    _castService?.remoteVolume.addListener(notifyListeners);
    _init();
  }

  @override
  void dispose() {
    _castService?.isRemotePlaying.removeListener(_onCastRemotePlayingChanged);
    _castService?.removeListener(_onCastingStateChanged);
    _castService?.remoteVolume.removeListener(notifyListeners);

    _stationsSubscription?.cancel();
    _audioHandler.customAction('dispose');
    _autoplayTimer?.cancel();
    _sleepTimer?.cancel();
    _bufferingTimeoutTimer?.cancel();
    _castTransitionTimer?.cancel();

    try {
      _castService?.endCasting();
    } catch (e) {
      if (kDebugMode) print('Error ending cast during dispose: $e');
    }
    sleepTimerActive.dispose();
    autoplayCountdownNotifier.dispose();
    super.dispose();
  }

  /// Future completed once initialization finishes.
  Future<void> get initializationFuture => _initializationCompleter.future;

  /// Notifier to signal when player widget should close.
  ValueNotifier<bool> get radioPlayerShouldClose => _radioPlayerShouldClose;

  /// List of recently played stations.
  List<Station> get recentStations => ListeningStatsService().recentStationIds
      .map((id) => _stationMap[id])
      .whereType<Station>()
      .toList();

  /// List of most listened stations in the last 500 minutes.
  List<Station> get mostListenedStations => ListeningStatsService()
      .getMostListenedStationIds()
      .map((id) => _stationMap[id])
      .whereType<Station>()
      .toList();

  /// List of favorite stations in the user's custom order.
  List<Station> get favoriteStations => _favoriteStationIds
      .map((id) => _stationMap[id])
      .whereType<Station>()
      .toList();

  /// Whether a sleep timer is currently active.
  bool get isSleepTimerSet => _sleepTimer != null;

  /// Currently active [MediaItem].
  MediaItem? get mediaItem => _currentMediaItem;

  /// Currently playing station object.
  Station? get currentStation => _stationMap[_currentMediaItem?.id];

  /// Mute state for web/player.
  bool get isMuted => _isMuted;

  /// SharedPreferences instance getter.
  SharedPreferences get prefs => _prefs;

  /// Whether a Cast session is currently connected.
  bool get isCasting => _castService?.isConnected ?? false;

  /// Unified play state for UI.
  bool get isPlaying => _isPlayIntended;

  /// Unified loading and buffering state for UI.
  bool get isLoading {
    if (isCasting) {
      if (_isTransitioning) return true;
      if (_isPlayIntended && !(_castService?.isRemotePlaying.value ?? false)) {
        return true;
      }
      return false;
    }

    if (_isTransitioning) return true;
    final isBuffering =
        player.processingState == ProcessingState.loading ||
        (player.processingState == ProcessingState.buffering && !kIsWeb);
    return isBuffering;
  }

  /// Volume level of the player or active cast session.
  double get volume => isCasting
      ? (_castService?.remoteVolume.value ?? player.volume)
      : player.volume;

  /// Stream of player volume changes.
  Stream<double> get volumeStream => player.volumeStream;

  /// Updates the player or remote cast volume.
  void setVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (isCasting) {
      _castService?.setRemoteVolume(clamped);
    } else {
      player.setVolume(clamped);
    }
    _prefs.setDouble(_volumeKey, clamped);

    if (clamped > 0 && _isMuted) {
      _isMuted = false;
      _prefs.setBool(_isMutedKey, false);
      notifyListeners();
    }
  }

  /// Toggles mute state.
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _preMuteVolume = volume;
      _prefs.setDouble(_preMuteVolumeKey, _preMuteVolume);
      player.setVolume(0.0);
    } else {
      player.setVolume(_preMuteVolume > 0 ? _preMuteVolume : 1.0);
    }
    _prefs.setBool(_isMutedKey, _isMuted);
    notifyListeners();
  }

  /// Returns the secondary text for display in UI or notifications.
  String getSecondaryText({String? loadingText}) {
    if (!isCasting &&
        isLoading &&
        loadingText != null &&
        loadingText.isNotEmpty) {
      return loadingText;
    }

    if (currentSongTitle != null && currentSongTitle!.trim().isNotEmpty) {
      return currentSongTitle!.trim();
    }
    final station = _stationMap[_currentMediaItem?.id];
    return station?.slogan.isNotEmpty == true ? station!.slogan : '';
  }

  /// Switches to a specific station or connects to a Cast device.
  Future<void> playMediaItem(Station? station, {CastDevice? castDevice}) async {
    cancelAutoplayCountdown();
    final resolved =
        station ??
        _stationMap[_currentMediaItem?.id] ??
        (stations.isNotEmpty ? stations.first : null);
    if (resolved == null) return;

    final item = resolved.toMediaItem();
    _setMediaItem(item);

    if (castDevice != null || isCasting) {
      try {
        _connectingStationId = 'cast_${castDevice?.id ?? item.id}';
        currentSongTitle = null;
        _isTransitioning = true;
        _isPlayIntended = true;
        notifyListeners();
        _startCastTransitionTimeout();

        await _audioHandler.stop();
        _audioHandler.updateRemotePlaybackState(
          playing: _castService?.isRemotePlaying.value ?? false,
          isBuffering: true,
        );
        if (castDevice != null && _castService != null) {
          await _castService.connectAndWait(castDevice);
        }
        await _castService?.castAudio(item);
      } catch (e) {
        if (kDebugMode) print('Error casting media item: $e');
        _isTransitioning = false;
        _isPlayIntended = false;
        _connectingStationId = null;
        notifyListeners();
      }
      return;
    }

    currentSongTitle = null;
    _isTransitioning = true;
    _isPlayIntended = true;
    _connectingStationId = item.id;
    notifyListeners();

    try {
      if (_currentMediaItem?.id != item.id) return;
      await _audioHandler.playMediaItem(item);
    } catch (e) {
      if (kDebugMode) print('Error playing media item: $e');
      if (_currentMediaItem?.id == item.id) {
        await _audioHandler.stop();
        _isTransitioning = false;
        _isPlayIntended = false;
        _connectingStationId = null;
        notifyListeners();
      }
    }
  }

  /// Starts playback. Forces a reset to the live edge.
  Future<void> play() async {
    cancelAutoplayCountdown();
    await playMediaItem(null);
  }

  /// Pauses playback.
  Future<void> pause() async {
    cancelAutoplayCountdown();
    _castTransitionTimer?.cancel();
    _isTransitioning = false;
    _isPlayIntended = false;
    notifyListeners();
    if (isCasting) {
      await _castService?.pause();
      return;
    }
    await _audioHandler.pause();
  }

  /// Stops playback or ends active Cast session.
  Future<void> stop() async {
    cancelAutoplayCountdown();
    cancelSleepTimer();
    _castTransitionTimer?.cancel();
    _isTransitioning = false;
    _isPlayIntended = false;
    notifyListeners();
    if (isCasting) {
      await _castService?.endCasting();
      return;
    }
    await _audioHandler.stop();
  }

  /// Skips to the next station in the list.
  Future<void> skipToNext() async {
    cancelAutoplayCountdown();
    final currentIndex = stations.indexWhere(
      (s) => s.id == _currentMediaItem?.id,
    );
    if (currentIndex == -1 || stations.isEmpty) return;
    final nextIndex = (currentIndex + 1) % stations.length;
    await playMediaItem(stations[nextIndex]);
  }

  /// Skips to the previous station in the list.
  Future<void> skipToPrevious() async {
    cancelAutoplayCountdown();
    final currentIndex = stations.indexWhere(
      (s) => s.id == _currentMediaItem?.id,
    );
    if (currentIndex == -1 || stations.isEmpty) return;
    final prevIndex = (currentIndex - 1 + stations.length) % stations.length;
    await playMediaItem(stations[prevIndex]);
  }

  /// Updates favorite status and persists it.
  Future<void> toggleFavorite(Station station) async {
    final index = stations.indexWhere((s) => s.id == station.id);
    if (index == -1) return;

    final updated = station.copyWith(isFavorite: !station.isFavorite);
    stations[index] = updated;
    _stationMap[station.id] = updated;

    if (updated.isFavorite) {
      _favoriteStationIds.add(updated.id);
    } else {
      _favoriteStationIds.remove(updated.id);
    }
    await _prefs.setStringList(_favoriteStationIdsKey, _favoriteStationIds);
    notifyListeners();
  }

  /// Reorders favorite stations and persists the new order.
  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _favoriteStationIds.length) return;
    if (newIndex < 0 || newIndex >= _favoriteStationIds.length) return;

    final String id = _favoriteStationIds.removeAt(oldIndex);
    _favoriteStationIds.insert(newIndex, id);

    notifyListeners();
    await _prefs.setStringList(_favoriteStationIdsKey, _favoriteStationIds);
  }

  /// Schedules the player to stop after a given duration.
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    if (duration.inSeconds > 0) {
      sleepTimerActive.value = true;
      _sleepTimer = Timer(duration, () {
        stop();
      });
      notifyListeners();
    }
  }

  /// Cancels any active sleep timer.
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerActive.value = false;
    notifyListeners();
  }

  /// Cancels autoplay countdown timer.
  void cancelAutoplayCountdown() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    _autoplayCancelled = true;
    autoplayCountdownNotifier.value = 0;
  }

  void _onCastRemotePlayingChanged() {
    if (isCasting) {
      final isPlaying = _castService?.isRemotePlaying.value ?? false;
      if (isPlaying) {
        _isTransitioning = false;
        _isPlayIntended = true;
        _castTransitionTimer?.cancel();
        _castTransitionTimer = null;
      }
      _audioHandler.updateRemotePlaybackState(
        playing: isPlaying,
        isBuffering: _isTransitioning,
      );
    }
    notifyListeners();
  }

  void _startCastTransitionTimeout() {
    _castTransitionTimer?.cancel();
    _castTransitionTimer = Timer(const Duration(seconds: 7), () {
      if (_isTransitioning && isCasting) {
        _isTransitioning = false;
        if (!(_castService?.isRemotePlaying.value ?? false)) {
          _isPlayIntended = false;
        }
        notifyListeners();
      }
    });
  }

  void _onCastingStateChanged() {
    _castTransitionTimer?.cancel();
    if (isReady.value) {
      if (isCasting) {
        player.stop();
        _audioHandler.updateRemotePlaybackState(
          playing: _castService?.isRemotePlaying.value ?? false,
          isBuffering: false,
        );
      } else {
        _isTransitioning = false;
        _isPlayIntended = false;
      }
    }
    notifyListeners();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    _audioHandler = await initAudioService(
      player: player,
      channelName: 'Etherly Radio',
      onSkipToNext: skipToNext,
      onSkipToPrevious: skipToPrevious,
    );

    player.playerStateStream.listen((state) {
      if (isCasting) return;
      final processingState = state.processingState;

      if (!_isTransitioning) {
        _isPlayIntended = state.playing;
      }

      final currentTag = player.sequenceState.currentSource?.tag as MediaItem?;
      if (processingState == ProcessingState.ready &&
          currentTag?.id == _connectingStationId) {
        if (_isTransitioning) {
          _isTransitioning = false;
          _syncSecondaryText();
        }
      }

      if (processingState == ProcessingState.idle ||
          processingState == ProcessingState.completed) {
        if (state.playing && !_isTransitioning) {
          stop();
        }
      }

      if (state.playing &&
          processingState == ProcessingState.buffering &&
          !kIsWeb) {
        _bufferingTimeoutTimer ??= Timer(const Duration(seconds: 10), () {
          if (kDebugMode) {
            print('Buffering timeout reached. Reconnecting to live edge...');
          }
          _bufferingTimeoutTimer = null;
          playMediaItem(null);
        });
      } else {
        _bufferingTimeoutTimer?.cancel();
        _bufferingTimeoutTimer = null;
      }

      _updateListeningMinuteTimer();
      notifyListeners();
    });

    player.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace st) {
        if (kDebugMode) print('Playback event error: $e');
        stop();
      },
    );

    player.icyMetadataStream
        .map((m) => m?.info?.title?.trim())
        .distinct()
        .listen((title) {
          if (isCasting) return;
          if (title != null && title.isNotEmpty) {
            final currentTag =
                player.sequenceState.currentSource?.tag as MediaItem?;

            if (currentTag?.id == _currentMediaItem?.id) {
              currentSongTitle = title;
              _isTransitioning = false;
              _syncSecondaryText();
              notifyListeners();
            }

            if (currentTag != null) {
              final parts = title.split(' - ');
              final artistName = parts.length > 1 ? parts[0].trim() : '';
              final songName = parts.length > 1
                  ? parts.sublist(1).join(' - ').trim()
                  : title;

              ListeningStatsService().addSong(
                title: songName,
                artist: artistName,
                stationId: currentTag.id,
                stationName: currentTag.title,
                stationArtUrl: currentTag.safeArt512Url,
              );
            }
          }
        });

    _preMuteVolume = _prefs.getDouble(_preMuteVolumeKey) ?? 1.0;
    _isMuted = _prefs.getBool(_isMutedKey) ?? false;
    final savedVolume = _prefs.getDouble(_volumeKey) ?? 1.0;

    if (_isMuted) {
      player.setVolume(0.0);
    } else {
      player.setVolume(savedVolume);
    }

    await _loadStations();
    await _checkAutoplay();
    isReady.value = true;
    if (!_initializationCompleter.isCompleted) {
      _initializationCompleter.complete();
    }
  }

  void _syncSecondaryText() {
    final text = getSecondaryText();
    if (text.isNotEmpty && _currentMediaItem != null) {
      _currentMediaItem = _currentMediaItem!.copyWith(artist: text);
      _audioHandler.patchMediaItemMetadata(
        stationId: _currentMediaItem!.id,
        artist: text,
      );
    }
  }

  void _setMediaItem(MediaItem item) {
    _currentMediaItem = item;
    _audioHandler.updateMediaItem(item);
    _saveLastStation(item.id);
    ListeningStatsService().addRecentStation(item.id);
    _updateListeningMinuteTimer();
    notifyListeners();
  }

  Future<void> _loadStations() async {
    await _readStationsFromCache();

    final fetchBundleFuture = _fetchAndLoadBundle();
    if (stations.isEmpty) {
      await fetchBundleFuture;
      await _readStationsFromCache();
    } else {
      fetchBundleFuture
          .then((_) => _readStationsFromCache())
          .catchError((_) {});
    }
  }

  Future<void> _fetchAndLoadBundle() async {
    try {
      final bundleUrl = Uri.parse(
        'https://etherly-firebase.firebaseapp.com/bundles/stations_bundle',
      );
      final response = await http
          .get(bundleUrl)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final LoadBundleTask task = FirebaseFirestore.instance.loadBundle(
          response.bodyBytes,
        );
        await task.stream.last;
        if (kDebugMode) print('Firestore bundle loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching Firestore bundle: $e');
    }
  }

  Future<void> _readStationsFromCache() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.namedQueryGet(
            'all_stations',
            options: const GetOptions(source: Source.cache),
          );

      final activeDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['active'] == true || data['active'] == null;
      }).toList();

      final loaded = activeDocs
          .map((doc) => Station.fromFirestore(doc))
          .toList();
      if (loaded.isEmpty) return;

      loaded.sort((a, b) {
        if (a.rank != null && b.rank != null) {
          return a.rank!.compareTo(b.rank!);
        }
        if (a.rank != null) return -1;
        if (b.rank != null) return 1;
        return a.name.compareTo(b.name);
      });

      _favoriteStationIds = _prefs.getStringList(_favoriteStationIdsKey) ?? [];

      stations = loaded
          .map(
            (s) => _favoriteStationIds.contains(s.id)
                ? s.copyWith(isFavorite: true)
                : s,
          )
          .toList();
      _stationMap = {for (var s in stations) s.id: s};

      _favoriteStationIds = _favoriteStationIds
          .where((id) => _stationMap.containsKey(id))
          .toList();

      await _loadLastStation();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading stations from cache: $e');
    } finally {
      try {
        await FirebaseFirestore.instance.disableNetwork();
      } catch (e) {
        if (kDebugMode) print('Error disabling Firestore network: $e');
      }
    }
  }

  void _updateListeningMinuteTimer() {
    if (isPlaying && _currentMediaItem != null) {
      _listeningMinuteTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
        if (isPlaying && _currentMediaItem != null) {
          ListeningStatsService().recordListeningMinute(_currentMediaItem!.id);
        } else {
          _listeningMinuteTimer?.cancel();
          _listeningMinuteTimer = null;
        }
      });
    } else {
      _listeningMinuteTimer?.cancel();
      _listeningMinuteTimer = null;
    }
  }

  Future<void> _saveLastStation(String id) async {
    await _prefs.setString(_lastStationIdKey, id);
  }

  Future<void> _loadLastStation() async {
    final lastId = _prefs.getString(_lastStationIdKey);
    if (lastId != null && _stationMap.containsKey(lastId)) {
      _setMediaItem(_stationMap[lastId]!.toMediaItem());
    }
  }

  Future<void> _checkAutoplay() async {
    final autoPlay = _prefs.getBool('autoPlay') ?? false;
    if (!autoPlay || (_castService?.isConnected ?? false)) return;

    final lastId = _prefs.getString(_lastStationIdKey);
    if (lastId == null || !_stationMap.containsKey(lastId)) return;

    _autoplayCancelled = false;
    autoplayCountdownNotifier.value = _autoPlayCountdownStart;

    for (int i = _autoPlayCountdownStart; i > 0; i--) {
      if (_autoplayCancelled) {
        autoplayCountdownNotifier.value = 0;
        return;
      }
      autoplayCountdownNotifier.value = i;
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!_autoplayCancelled) {
      await playMediaItem(_stationMap[lastId]);
    }
    autoplayCountdownNotifier.value = 0;
  }
}

/// Extension to convert [Station] model to [MediaItem] for audio service.
extension StationToMediaItem on Station {
  MediaItem toMediaItem({String? artist}) {
    final url = streams.values.isNotEmpty ? streams.values.first : '';
    final initialArtist = (artist != null && artist.isNotEmpty)
        ? artist
        : slogan;
    return MediaItem(
      id: id,
      title: name,
      artUri: Uri.tryParse(getArtUrl()),
      artist: initialArtist,
      album: slogan,
      extras: {'url': url, 'streams': streams, 'art': art},
    );
  }
}

/// Extension to handle safe artwork URLs from [MediaItem].
extension MediaItemArt on MediaItem? {
  String getArtUrl({double? size}) {
    if (this == null) return '';
    final rawArt = this?.extras?['art'];
    final Map<String, String> artMap = {};
    if (rawArt is Map) {
      rawArt.forEach((k, v) {
        artMap[k.toString()] = v.toString();
      });
    } else {
      final extras = this?.extras;
      if (extras != null) {
        if (extras['art128'] != null) {
          artMap['128'] = extras['art128'].toString();
        }
        if (extras['art512'] != null) {
          artMap['512'] = extras['art512'].toString();
        }
        if (extras['art1024'] != null) {
          artMap['1024'] = extras['art1024'].toString();
        }
      }
      final defaultArt = safeArtUrl;
      if (defaultArt.isNotEmpty) {
        artMap['default'] = defaultArt;
      }
    }

    return getArtUrlFromMap(artMap, size: size);
  }

  String get safeArtUrl {
    final uri = Uri.tryParse(this?.artUri?.toString() ?? '');
    return uri != null && uri.scheme.startsWith('http') ? uri.toString() : '';
  }

  String get safeArt128Url {
    return getArtUrl(size: 128);
  }

  String get safeArt512Url {
    return getArtUrl(size: 512);
  }

  String get safeArt1024Url {
    return getArtUrl(size: 1024);
  }
}
