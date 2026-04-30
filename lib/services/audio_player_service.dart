import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/chrome_cast_service.dart';
import 'package:etherly/services/my_audio_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Service that manages the [AudioPlayer] instance, station list, and playback logic.
class AudioPlayerService with ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  late final MyAudioHandler _audioHandler;
  final ValueNotifier<({String? title, bool loading})> icyState = ValueNotifier(
    (title: null, loading: false),
  );
  final ChromeCastService? _castService;
  late final SharedPreferences _prefs;

  final ValueNotifier<bool> isReady = ValueNotifier(false);
  final ValueNotifier<bool> _radioPlayerShouldClose = ValueNotifier(false);
  ValueNotifier<bool> get radioPlayerShouldClose => _radioPlayerShouldClose;

  /// Keys for SharedPreferences.
  static const String _lastStationIdKey = 'last_station_id';
  static const String _favoriteStationIdsKey = 'favorite_station_ids';
  static const String _recentStationIdsKey = 'recent_station_ids';
  static const String _volumeKey = 'volume';
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

  /// Autoplay countdown timer.
  Timer? _autoplayTimer;
  bool _autoplayCancelled = false;
  final ValueNotifier<int> autoplayCountdownNotifier = ValueNotifier(0);

  /// Sleep timer.
  Timer? _sleepTimer;
  final ValueNotifier<bool> sleepTimerActive = ValueNotifier(false);
  bool get isSleepTimerSet => _sleepTimer != null;

  /// Current media item.
  MediaItem? _currentMediaItem;
  MediaItem? get mediaItem => _currentMediaItem;

  /// Preferences.
  SharedPreferences get prefs => _prefs;

  /// Cast loading status.
  bool get isCastLoading => _castService?.isRemoteLoading.value ?? false;
  bool get isCasting => _castService?.isConnected ?? false;
  bool get isPlaying {
    if (_castService != null && _castService.isConnected) {
      return _castService.isRemotePlaying.value;
    }
    return player.playing;
  }

  /// Volume level on web.
  double get volume => kIsWeb ? player.volume : 1.0;

  /// Creates the service and attaches listeners to the optional cast service.
  AudioPlayerService({ChromeCastService? castService})
    : _castService = castService {
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
      onPlay: play,
      onSkipToNext: skipToNext,
      onSkipToPrevious: skipToPrevious,
    );

    // Sync just_audio state to our listeners
    player.playingStream.listen((_) => notifyListeners());
    player.processingStateStream.listen((_) => notifyListeners());

    // Sync ICY Metadata from just_audio natively
    player.icyMetadataStream
        .map((m) => m?.info?.title?.trim())
        .distinct()
        .listen((title) {
          if (title != null && title.isNotEmpty) {
            icyState.value = (title: title, loading: false);
            _audioHandler.patchMediaItemMetadata(artist: title);
          }
        });

    if (kIsWeb) {
      final savedVolume = _prefs.getDouble(_volumeKey) ?? 1.0;
      setVolume(savedVolume);
    }

    await _loadStations();
    await _checkAutoplay();
    isReady.value = true;
  }

  /// Updates the player volume (Web only).
  void setVolume(double value) {
    if (kIsWeb) {
      final clamped = value.clamp(0.0, 1.0);
      player.setVolume(clamped);
      _prefs.setDouble(_volumeKey, clamped);
      notifyListeners();
    }
  }

  /// Disposes of all timers and listeners.
  @override
  void dispose() {
    _castService?.isRemotePlaying.removeListener(notifyListeners);
    _castService?.isRemoteLoading.removeListener(notifyListeners);
    _castService?.isCastingActive.removeListener(_onCastingStateChanged);
    _audioHandler.customAction('dispose');
    _autoplayTimer?.cancel();
    _sleepTimer?.cancel();
    try {
      _castService?.endCasting();
    } catch (_) {}
    sleepTimerActive.dispose();
    autoplayCountdownNotifier.dispose();
    super.dispose();
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
      icyState.value = (title: null, loading: false);
      await player.stop();
      await _castService.castAudio(mediaItem: item);
      notifyListeners();
      return;
    }

    icyState.value = (title: null, loading: true);
    try {
      await player.stop();
      await _setAudioSource(item);
      player.play().catchError((_) {});
    } catch (e) {
      if (kDebugMode) print('Error playing media item: $e');
    }
  }

  /// Sets the audio source for the player, trying available codecs.
  Future<void> _setAudioSource(MediaItem item) async {
    final quality = _prefs.getString('streamQuality') ?? 'mp3';
    final station = _stationMap[item.id] ?? stations.first;

    final availableStreams = station.streams;
    if (availableStreams.isEmpty) throw Exception("No valid stream URL found");

    // If only one stream is available, pick it regardless of preference.
    if (availableStreams.length == 1) {
      await player.setAudioSource(
        AudioSource.uri(Uri.parse(availableStreams.values.first), tag: item),
      );
      return;
    }

    // Try preferred quality first, then fallback to any other available.
    final urlPriority = [
      if (availableStreams.containsKey(quality)) availableStreams[quality]!,
      ...availableStreams.values.where((u) => u != availableStreams[quality]),
    ];

    for (int i = 0; i < urlPriority.length; i++) {
      try {
        await player.setAudioSource(
          AudioSource.uri(Uri.parse(urlPriority[i]), tag: item),
        );
        return;
      } on PlayerInterruptedException {
        rethrow;
      } catch (e) {
        if (i == urlPriority.length - 1) return;
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
        await player.stop();
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
    icyState.value = (title: icyState.value.title, loading: false);
    if (_castService != null && _castService.isConnected) {
      await player.pause();
      await _castService.pause();
      notifyListeners();
      return;
    }
    await player.pause();
  }

  /// Stops playback.
  Future<void> stop() async {
    cancelAutoplayCountdown();
    icyState.value = (title: icyState.value.title, loading: false);
    if (_castService != null && _castService.isConnected) {
      await player.stop();
      await _castService.pause();
      notifyListeners();
      return;
    }
    await player.stop();
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

  /// Pre-fetches all station art to improve UI responsiveness.
  Future<void> precacheAllStationArt(BuildContext context) async {
    for (final station in stations) {
      if (station.art.isNotEmpty) {
        try {
          await precacheImage(CachedNetworkImageProvider(station.art), context);
        } catch (_) {}
      }
    }
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

  /// Loads the station list from the remote repository.
  Future<void> _loadStations() async {
    bool loaded = false;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('stations').get();
      // Filter out inactive stations
      final activeDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['active'] == true || data['active'] == null;
      }).toList();
      stations = activeDocs.map((doc) => Station.fromFirestore(doc)).toList();
      
      // Sort by rank if it exists, otherwise leave order or sort by name
      stations.sort((a, b) {
        if (a.rank != null && b.rank != null) return a.rank!.compareTo(b.rank!);
        if (a.rank != null) return -1;
        if (b.rank != null) return 1;
        return a.name.compareTo(b.name);
      });

      loaded = true;
    } catch (e) {
      if (kDebugMode) print('Error loading stations from Firebase: $e');
    }

    if (loaded) {
      _favoriteStationIds = _prefs.getStringList(_favoriteStationIdsKey) ?? [];
      _recentStationIds = _prefs.getStringList(_recentStationIdsKey) ?? [];

      stations = stations
          .map(
            (s) => _favoriteStationIds.contains(s.id)
                ? s.copyWith(isFavorite: true)
                : s,
          )
          .toList();
      _stationMap = {for (var s in stations) s.id: s};

      await _loadLastStation();
    }
    notifyListeners();
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
    return MediaItem(
      id: id,
      title: name,
      artUri: Uri.tryParse(art),
      artist: artist ?? '',
      album: slogan,
      extras: {'url': url},
    );
  }
}

/// Extension to handle safe artwork URLs from [MediaItem].
extension MediaItemArt on MediaItem? {
  String get safeArtUrl {
    final uri = Uri.tryParse(this?.artUri?.toString() ?? '');
    return uri != null && uri.scheme.startsWith('http') ? uri.toString() : '';
  }
}
