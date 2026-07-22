import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/chrome_cast_service.dart';
import 'package:etherly/services/history_service.dart';
import 'package:etherly/services/my_audio_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Service that manages the [AudioPlayer] instance, station list, and playback logic.
class AudioPlayerService with ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  late final MyAudioHandler _audioHandler;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _stationsSubscription;

  /// Pre-emptive loading transition lock
  bool _isTransitioning = false;

  /// The intended play state forced by the user/UI to prevent transition flickering
  bool _isPlayIntended = false;

  /// The ID of the station currently being connected to
  String? _connectingStationId;

  /// Current ICY stream metadata song title
  String? currentSongTitle;

  final ChromeCastService? _castService;
  late final SharedPreferences _prefs;

  final ValueNotifier<bool> isReady = ValueNotifier(false);
  final Completer<void> _initializationCompleter = Completer<void>();
  Future<void> get initializationFuture => _initializationCompleter.future;

  final ValueNotifier<bool> _radioPlayerShouldClose = ValueNotifier(false);
  ValueNotifier<bool> get radioPlayerShouldClose => _radioPlayerShouldClose;

  /// Keys for SharedPreferences.
  static const String _lastStationIdKey = 'last_station_id';
  static const String _favoriteStationIdsKey = 'favorite_station_ids';
  static const String _recentStationIdsKey = 'recent_station_ids';
  static const String _volumeKey = 'volume';
  static const String _isMutedKey = 'is_muted';
  static const String _preMuteVolumeKey = 'pre_mute_volume';
  static const int _maxRecentStations = 10;
  static const int _autoPlayCountdownStart = 3;

  /// List of all available stations and their metadata.
  List<Station> stations = [];
  Map<String, Station> _stationMap = {};
  List<String> _favoriteStationIds = [];
  List<String> _recentStationIds = [];
  List<Station> get recentStations => _recentStationIds
      .map((id) => _stationMap[id])
      .whereType<Station>()
      .toList();

  /// List of favorite stations in the user's custom order.
  List<Station> get favoriteStations => _favoriteStationIds
      .map((id) => _stationMap[id])
      .whereType<Station>()
      .toList();

  /// Autoplay countdown timer.
  Timer? _autoplayTimer;
  bool _autoplayCancelled = false;
  final ValueNotifier<int> autoplayCountdownNotifier = ValueNotifier(0);

  /// Sleep timer.
  Timer? _sleepTimer;
  final ValueNotifier<bool> sleepTimerActive = ValueNotifier(false);
  bool get isSleepTimerSet => _sleepTimer != null;

  /// Timer to track network buffering timeout and trigger live-edge reconnection.
  Timer? _bufferingTimeoutTimer;

  /// Current media item.
  MediaItem? _currentMediaItem;
  MediaItem? get mediaItem => _currentMediaItem;

  /// Currently playing station object.
  Station? get currentStation => _stationMap[_currentMediaItem?.id];

  /// Mute state for web.
  bool _isMuted = false;
  double _preMuteVolume = 1.0;
  bool get isMuted => _isMuted;

  /// Preferences.
  SharedPreferences get prefs => _prefs;

  /// Cast loading status.
  bool get isCastLoading => _castService?.isRemoteLoading.value ?? false;
  bool get isCasting => _castService?.isConnected ?? false;

  /// Unified play state for UI
  bool get isPlaying {
    if (_castService != null && _castService.isConnected) {
      return _castService.isRemotePlaying.value;
    }
    return _isPlayIntended;
  }

  /// Unified loading and buffering state for UI
  bool get isLoading {
    if (_castService != null && _castService.isConnected) {
      return _castService.isRemoteLoading.value;
    }
    final isBuffering =
        player.processingState == ProcessingState.loading ||
        (player.processingState == ProcessingState.buffering && !kIsWeb);
    return _isTransitioning || isBuffering;
  }

  /// Volume level of the player.
  double get volume => player.volume;

  /// Stream of player volume changes.
  Stream<double> get volumeStream => player.volumeStream;

  /// Creates the service and attaches listeners to the optional cast service.
  AudioPlayerService([this._castService]) {
    _castService?.isRemotePlaying.addListener(notifyListeners);
    _castService?.isRemoteLoading.addListener(notifyListeners);
    _castService?.isCastingActive.addListener(_onCastingStateChanged);
    _init();
  }

  /// Handles switching notification visibility when casting status changes.
  void _onCastingStateChanged() {
    if (_castService?.isCastingActive.value ?? false) {
      _audioHandler.hideNotification();
    } else {
      _audioHandler.showNotification();
    }
    notifyListeners();
  }

  /// Initializes the audio service, listeners, and loads user data.
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    _audioHandler = await initAudioService(
      player: player,
      channelName: 'Etherly Radio',
      onSkipToNext: skipToNext,
      onSkipToPrevious: skipToPrevious,
    );

    // Sync unified just_audio player state to our listeners
    player.playerStateStream.listen((state) {
      final processingState = state.processingState;

      // Sync play intent with native player once we are no longer connecting
      if (!_isTransitioning) {
        _isPlayIntended = state.playing;
      }

      // Only clear the connecting spinner once the player is fully ready for the intended station
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

      // Reconnect if stuck buffering on a live stream for too long
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

      notifyListeners();
    });

    player.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace st) {
        if (kDebugMode) print('Playback event error: $e');
        stop();
      },
    );

    // Sync ICY Metadata from just_audio natively
    player.icyMetadataStream.map((m) => m?.info?.title?.trim()).distinct().listen((
      title,
    ) {
      if (title != null && title.isNotEmpty) {
        final currentTag =
            player.sequenceState.currentSource?.tag as MediaItem?;

        // Only update current song UI if it matches the current user selection
        if (currentTag?.id == _currentMediaItem?.id) {
          currentSongTitle = title;
          _isTransitioning = false;
          _syncSecondaryText();
          notifyListeners();
        }

        // Record song history under the actual native source that emitted the metadata
        if (currentTag != null) {
          final parts = title.split(' - ');
          final artistName = parts.length > 1 ? parts[0].trim() : '';
          final songName = parts.length > 1
              ? parts.sublist(1).join(' - ').trim()
              : title;

          HistoryService().addSong(
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

  /// Updates the player volume.
  void setVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    player.setVolume(clamped);
    _prefs.setDouble(_volumeKey, clamped);

    // If manually setting volume > 0, unmute
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

  /// Disposes of all timers and listeners.
  @override
  void dispose() {
    _castService?.isRemotePlaying.removeListener(notifyListeners);
    _castService?.isRemoteLoading.removeListener(notifyListeners);
    _castService?.isCastingActive.removeListener(_onCastingStateChanged);
    _stationsSubscription?.cancel();
    _audioHandler.customAction('dispose');
    _autoplayTimer?.cancel();
    _sleepTimer?.cancel();
    _bufferingTimeoutTimer?.cancel();

    try {
      _castService?.endCasting();
    } catch (_) {}
    sleepTimerActive.dispose();
    autoplayCountdownNotifier.dispose();
    super.dispose();
  }

  /// Returns the secondary text:
  /// - If loading and localized [loadingText] is supplied (for in-app UI), returns [loadingText].
  /// - If ICY track title is available, returns [currentSongTitle].
  /// - Otherwise (for notifications/head units or fallback), returns station slogan.
  String getSecondaryText({String? loadingText}) {
    if (isLoading && loadingText != null && loadingText.isNotEmpty) {
      return loadingText;
    }
    if (currentSongTitle != null && currentSongTitle!.trim().isNotEmpty) {
      return currentSongTitle!.trim();
    }
    final station = _stationMap[_currentMediaItem?.id];
    return station?.slogan.isNotEmpty == true ? station!.slogan : '';
  }

  /// Syncs the current secondary text state to OS media notification & head units
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

  /// Switches to a specific station. If null, re-initializes the current live stream.
  Future<void> playMediaItem(Station? station) async {
    cancelAutoplayCountdown();
    final resolved =
        station ??
        _stationMap[_currentMediaItem?.id] ??
        (stations.isNotEmpty ? stations.first : null);
    if (resolved == null) return;

    final item = resolved.toMediaItem();
    _setMediaItem(item);

    if (_castService != null && _castService.isConnected) {
      currentSongTitle = null;
      _isTransitioning = false;
      await _audioHandler.stop();
      await _castService.castAudio(mediaItem: item);
      notifyListeners();
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

  /// Updates current metadata and saves history.
  void _setMediaItem(MediaItem item) {
    _currentMediaItem = item;
    _audioHandler.updateMediaItem(item);
    _saveLastStation(item.id);
    _addRecentStation(item.id);
    notifyListeners();
  }

  /// Starts playback. Forces a reset to the live edge.
  Future<void> play() async {
    cancelAutoplayCountdown();
    if (_castService != null && _castService.isConnected) {
      if (_currentMediaItem != null) {
        await _audioHandler.stop();
        await _castService.castAudio(mediaItem: _currentMediaItem!);
      } else {
        await _castService.play();
      }
      notifyListeners();
      return;
    }
    await playMediaItem(null);
  }

  /// Pauses playback.
  Future<void> pause() async {
    cancelAutoplayCountdown();
    _isTransitioning = false;
    _isPlayIntended = false;
    notifyListeners();
    if (_castService != null && _castService.isConnected) {
      await _audioHandler.pause();
      await _castService.pause();
      return;
    }
    await _audioHandler.pause();
  }

  /// Stops playback.
  Future<void> stop() async {
    cancelAutoplayCountdown();
    cancelSleepTimer();
    _isTransitioning = false;
    _isPlayIntended = false;
    notifyListeners();
    if (_castService != null && _castService.isConnected) {
      await _audioHandler.stop();
      await _castService.pause();
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

  /// Pre-fetches all station art icons in parallel to improve UI responsiveness.
  Future<void> precacheAllStationArt(BuildContext context) async {
    final futures = <Future<void>>[];
    for (final station in stations) {
      final art512Url = station.getArtUrl(size: 512);
      if (art512Url.isNotEmpty) {
        final provider = CachedNetworkImageProvider(art512Url);
        futures.add(precacheImage(provider, context).catchError((_) {}));
      }
    }
    await Future.wait(futures);
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

  /// Reorders the favorite stations and persists the new order.
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
        _sleepTimer = null;
        sleepTimerActive.value = false;
        notifyListeners();
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

  /// Cancels the autoplay countdown timer.
  void cancelAutoplayCountdown() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    _autoplayCancelled = true;
    autoplayCountdownNotifier.value = 0;
  }

  /// Loads the station list from local cache first for instant startup, then syncs the remote bundle.
  Future<void> _loadStations() async {
    await _readStationsFromCache();

    final fetchBundleFuture = _fetchAndLoadBundle();
    if (stations.isEmpty) {
      await fetchBundleFuture;
      await _readStationsFromCache();
    } else {
      // Refresh cache in background if already populated
      fetchBundleFuture.then((_) => _readStationsFromCache()).catchError((_) {});
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

      final loaded =
          activeDocs.map((doc) => Station.fromFirestore(doc)).toList();
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
      _recentStationIds = _prefs.getStringList(_recentStationIdsKey) ?? [];

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
      } catch (_) {}
    }
  }

  /// Adds a station to the recently played history.
  Future<void> _addRecentStation(String stationId) async {
    _recentStationIds.remove(stationId);
    _recentStationIds.insert(0, stationId);
    if (_recentStationIds.length > _maxRecentStations) {
      _recentStationIds = _recentStationIds.sublist(0, _maxRecentStations);
    }
    await _prefs.setStringList(_recentStationIdsKey, _recentStationIds);
    notifyListeners();
  }

  /// Persists the ID of the last played station.
  Future<void> _saveLastStation(String id) async {
    await _prefs.setString(_lastStationIdKey, id);
  }

  /// Restores metadata for the last played station.
  Future<void> _loadLastStation() async {
    final lastId = _prefs.getString(_lastStationIdKey);
    if (lastId != null && _stationMap.containsKey(lastId)) {
      _setMediaItem(_stationMap[lastId]!.toMediaItem());
    }
  }

  /// Manages the autoplay logic on app startup.
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
    // Pick first available stream if multiple exist, otherwise use the only one.
    final url = streams.values.isNotEmpty ? streams.values.first : '';
    final initialArtist =
        (artist != null && artist.isNotEmpty) ? artist : slogan;
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
      // Fallback/Legacy if art is not a map in extras
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
