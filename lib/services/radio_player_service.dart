import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audio_service/audio_service.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/icy_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherly/services/chrome_cast_service.dart';

Future<MyAudioHandler>? _audioHandlerFuture;
Future<MyAudioHandler> initAudioService({
  required String channelName,
  ChromeCastService? castService,
}) {
  return _audioHandlerFuture ??= AudioService.init<MyAudioHandler>(
    builder: () => MyAudioHandler(castService: castService),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.etherly.radio.channel.audio',
      androidNotificationChannelName: channelName,
      androidNotificationIcon: 'mipmap/notification_icon',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  bool _stopRequested = false;
  SharedPreferences? _prefs;
  final AudioPlayer _player = AudioPlayer(handleInterruptions: false);
  List<Station> _stations = [];
  bool _wasPlayingBeforeInterrupt = false;
  AudioSession? _audioSession;
  double _volume = 1.0;

  /// Icy service for managing ICY metadata.
  IcyService? _icyService;
  StreamSubscription<IcyMetadata?>? _icySub;

  final ChromeCastService? castService;

  double get volume => _volume;

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    try {
      _player.setVolume(_volume);
    } catch (e) {
      // Ignore errors when setting volume before audio source is loaded
    }
  }

  MyAudioHandler({this.castService}) {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _listenForIcy();
    _initAudioSession();
  }

  /// Initialize audio session and handle interruptions.
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    _audioSession = session;
    session.becomingNoisyEventStream.listen((_) async {
      await stop();
    });
    session.devicesChangedEventStream.listen((event) async {
      bool btChanged =
          event.devicesAdded.any(
            (d) =>
                d.isOutput &&
                (d.type == AudioDeviceType.bluetoothA2dp ||
                    d.type == AudioDeviceType.bluetoothLe ||
                    d.type == AudioDeviceType.bluetoothSco),
          ) ||
          event.devicesRemoved.any(
            (d) =>
                d.isOutput &&
                (d.type == AudioDeviceType.bluetoothA2dp ||
                    d.type == AudioDeviceType.bluetoothLe ||
                    d.type == AudioDeviceType.bluetoothSco),
          );
      if (btChanged) await stop();
    });
    session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        _wasPlayingBeforeInterrupt = _player.playing;
        if (_wasPlayingBeforeInterrupt) {
          await pause();
        }
      } else {
        if (_wasPlayingBeforeInterrupt) {
          _wasPlayingBeforeInterrupt = false;
          await play();
        }
      }
    });
  }

  /// Set the ICY service for metadata updates.
  void setIcyService(IcyService icyService) {
    _icyService = icyService;
  }

  void _listenForIcy() {
    _icySub?.cancel();
    _icySub = _player.icyMetadataStream.listen((meta) {
      final text = _parseIcyText(meta);
      if (text != null && text.isNotEmpty) {
        _icyService?.setText(text);
        _updateMediaItem(text);
      }
    });
  }

  String? _parseIcyText(IcyMetadata? meta) {
    try {
      final info = meta?.info;
      final title = info?.title?.trim();
      if (title != null && title.isNotEmpty) return title;
    } catch (_) {}
    return null;
  }

  /// Play a new media item (radio station).
  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    _stopRequested = false;
    _icyService?.startLoading();
    await _player.stop();
    this.mediaItem.add(mediaItem);
    if (_stopRequested) return;
    await _setAudioSource(mediaItem);
    if (_stopRequested) return;
    await _player.play();
  }

  /// All player control methods.
  @override
  Future<void> play() async {
    _stopRequested = false;
    if (_player.audioSource == null ||
        _player.processingState == ProcessingState.idle) {
      final item = mediaItem.value;
      if (item != null) {
        await _setAudioSource(item);
      }
    }
    if (!_stopRequested) {
      await _player.play();
    }
  }

  @override
  Future<void> pause() {
    _stopRequested = true;
    return _player.stop();
  }

  @override
  Future<void> stop() {
    _stopRequested = true;
    return _player.stop();
  }

  /// Logic for skipping to next/previous stations on bluetooth devices.
  int _getCurrentStationIndex() {
    if (_stations.isEmpty) return -1;
    final currentId = mediaItem.value?.id;
    if (currentId == null) return -1;
    return _stations.indexWhere((s) => s.id == currentId);
  }

  @override
  Future<void> skipToNext() async {
    final currentIndex = _getCurrentStationIndex();
    if (currentIndex == -1) return;

    final nextIndex = (currentIndex + 1) % _stations.length;
    await playMediaItem(_stations[nextIndex].toMediaItem());
  }

  @override
  Future<void> skipToPrevious() async {
    final currentIndex = _getCurrentStationIndex();
    if (currentIndex == -1) return;

    final prevIndex = (currentIndex - 1 + _stations.length) % _stations.length;
    await playMediaItem(_stations[prevIndex].toMediaItem());
  }

  /// When the app is closed, stop playback and unload rich media notification.
  @override
  Future<void> onTaskRemoved() async {
    try {
      await stop();
      if (castService != null && castService!.isConnected) {
        await castService!.endCasting().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            if (kDebugMode) print('Cast cleanup timed out');
          },
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error in onTaskRemoved: $e');
    }
    await super.onTaskRemoved();
  }

  /// Custom action handler for cleanup and other custom commands.
  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'dispose') {
      _icySub?.cancel();
      await _player.dispose();
      return;
    }
    return super.customAction(name, extras);
  }

  /// Hide the audio service notification when casting.
  Future<void> hideNotification() async {
    try {
      await _player.stop();
      final session = _audioSession;
      if (session != null) {
        await session.setActive(false);
      }

      playbackState.add(
        PlaybackState(
          controls: [],
          processingState: AudioProcessingState.idle,
          playing: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Error hiding notification: $e');
    }
  }

  /// Show the audio service notification when not casting.
  Future<void> showNotification() async {
    try {
      final session = _audioSession;
      if (session != null) {
        await session.setActive(true);
      }

      // MediaItem is already present, just restore playback state
      final current = mediaItem.value;
      if (current != null) {
        playbackState.add(_transformEvent(_player.playbackEvent));
      }
    } catch (e) {
      if (kDebugMode) print('Error showing notification: $e');
    }
  }

  void setStations(List<Station> stations) {
    _stations = stations;
  }

  void setPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  /// Prepare audio source for autoplay by loading it without starting playback.
  Future<void> prepareAudioSource(MediaItem mediaItem) async {
    try {
      _stopRequested = false;
      await _player.stop();
      this.mediaItem.add(mediaItem);
      if (_stopRequested) return;
      await _setAudioSource(mediaItem);
      // Check again after the potentially slow network operation
      if (_stopRequested) return;
      await _player.pause();
    } catch (e) {
      // Handle errors silently for autoplay preparation.
    }
  }

  /// Set the audio source MP3/AAC for playback.
  Future<void> _setAudioSource(MediaItem item) async {
    final quality = _prefs?.getString('streamQuality') ?? 'mp3';
    final Station? station = (item.id.isNotEmpty && _stations.isNotEmpty)
        ? _stations.firstWhere(
            (s) => s.id == item.id,
            orElse: () => _stations.first,
          )
        : null;

    final String? urlString = station != null
        ? ((quality == 'aac'
                  ? <String?>[station.streamAAC, station.streamMP3]
                  : <String?>[station.streamMP3, station.streamAAC])
              .firstWhere((u) => u != null && u.isNotEmpty, orElse: () => null))
        : item.extras?['url'] as String?;

    if (urlString == null || urlString.isEmpty) {
      throw Exception("No valid stream URL found for station");
    }

    final sourceUrl = Uri.parse(urlString);
    try {
      await _player.setAudioSource(AudioSource.uri(sourceUrl, tag: item));
      await _player.setVolume(_volume);
    } on PlayerInterruptedException {
      return;
    }
  }

  /// Media controls for rich media notification (RMN).
  PlaybackState _transformEvent(PlaybackEvent event) {
    final effectiveProcessingState =
        _player.playing &&
            (event.processingState == ProcessingState.buffering ||
                event.processingState == ProcessingState.loading)
        ? ProcessingState.ready
        : event.processingState;

    return PlaybackState(
      controls: [
        if (_player.playing) MediaControl.pause else MediaControl.play,
      ],
      androidCompactActionIndices: const [0, 3],
      processingState: _getProcessingState(effectiveProcessingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  void _updateMediaItem(String? artist) {
    final current = mediaItem.value;
    if (current == null) return;
    final updated = MediaItem(
      id: current.id,
      title: current.title,
      artUri: current.artUri,
      artist: artist,
      album: current.album,
      extras: current.extras,
      duration: current.duration,
      genre: current.genre,
      playable: current.playable,
      rating: current.rating,
      displayTitle: current.displayTitle,
      displaySubtitle: current.displaySubtitle,
      displayDescription: current.displayDescription,
    );
    mediaItem.add(updated);
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}

class AudioPlayerService with ChangeNotifier {
  /// Pre-cache all station artwork images to speed up UI rendering.
  Future<void> precacheAllStationArt(BuildContext context) async {
    for (final station in stations) {
      final url = station.artURL;
      if (url.isNotEmpty) {
        try {
          await precacheImage(NetworkImage(url), context);
        } catch (_) {
          // Ignore errors (e.g., network issues)
        }
      }
    }
  }

  final ValueNotifier<bool> isReady = ValueNotifier(false);
  final ValueNotifier<bool> _radioPlayerShouldClose = ValueNotifier(false);

  ValueNotifier<bool> get radioPlayerShouldClose => _radioPlayerShouldClose;
  static const String _lastStationIdKey = 'last_station_id';
  static const String _favoriteStationIdsKey = 'favorite_station_ids';
  static const String _recentStationIdsKey = 'recent_station_ids';
  static const int _maxRecentStations = 10;
  static const int _autoPlayCountdownStart = 3;

  final MyAudioHandler _audioHandler;
  final ChromeCastService? _castService;
  final IcyService icyService = IcyService();

  late final SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;

  List<Station> get recentStations {
    return _recentStationIds
        .map((id) => _stationMap[id])
        .whereType<Station>()
        .toList();
  }

  List<Station> stations = [];
  Map<String, Station> _stationMap = {};
  List<String> _favoriteStationIds = [];
  List<String> _recentStationIds = [];

  Timer? _autoplayTimer;
  bool _autoplayCancelled = false;
  bool _autoplayInProgress = false;
  final ValueNotifier<int> autoplayCountdownNotifier = ValueNotifier(0);

  /// Returns true if autoplay is currently in progress (timer running or about to play)
  bool get isAutoplayInProgress => _autoplayInProgress && !_autoplayCancelled;

  Timer? _sleepTimer;
  final ValueNotifier<bool> sleepTimerActive = ValueNotifier(false);

  bool get isSleepTimerSet => _sleepTimer != null;
  MediaItem? get mediaItem => _audioHandler.mediaItem.value;
  bool get isCastLoading => _castService?.isRemoteLoading.value ?? false;
  bool get isCasting => _castService?.isConnected ?? false;
  bool get isPlaying {
    final cast = _castService;
    if (cast != null && cast.isConnected) {
      return cast.isRemotePlaying.value;
    }
    return _audioHandler.playbackState.value.playing;
  }

  PlaybackState get playbackState => _audioHandler.playbackState.value;

  double get volume => kIsWeb ? _audioHandler.volume : 1.0;

  void setVolume(double value) {
    if (kIsWeb) {
      _audioHandler.setVolume(value);
      notifyListeners();
    }
  }

  AudioPlayerService(this._audioHandler, {ChromeCastService? castService})
    : _castService = castService {
    _castService?.isRemotePlaying.addListener(notifyListeners);
    _castService?.isRemoteLoading.addListener(notifyListeners);
    _castService?.isCastingActive.addListener(_onCastingStateChanged);
    _init();
  }

  /// Handle casting state changes to show/hide the audio service notification.
  void _onCastingStateChanged() {
    final isCasting = _castService?.isCastingActive.value ?? false;
    if (isCasting) {
      _audioHandler.hideNotification();
    } else {
      _audioHandler.showNotification();
    }
    notifyListeners();
  }

  /// Initialize service: load preferences, stations, and set up listeners.
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _requestNotificationPermission();

    _audioHandler.playbackState.listen((_) => notifyListeners());
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _saveLastStation(mediaItem.id);
        _addRecentStation(mediaItem.id);
      }
      notifyListeners();
    });

    icyService.addListener(notifyListeners);
    _audioHandler.setIcyService(icyService);
    _audioHandler.setPrefs(_prefs);

    await _loadStations();
    await _checkAutoplay();
    isReady.value = true;
  }

  /// Dispose resources when service is no longer needed.
  @override
  void dispose() {
    _castService?.isRemotePlaying.removeListener(notifyListeners);
    _castService?.isRemoteLoading.removeListener(notifyListeners);
    _castService?.isCastingActive.removeListener(_onCastingStateChanged);
    _audioHandler.customAction('dispose');
    _autoplayTimer?.cancel();
    _sleepTimer?.cancel();
    // Best-effort: end casting to avoid platform messages after shutdown.
    try {
      _castService?.endCasting();
    } catch (_) {}
    sleepTimerActive.dispose();
    autoplayCountdownNotifier.dispose();
    super.dispose();
  }

  /// Control maps for UI interaction.
  Future<void> playMediaItem(Station? station) async {
    cancelAutoplayCountdown();
    final currentId = _audioHandler.mediaItem.value?.id;
    final Station? resolved =
        station ??
        (currentId != null ? _stationMap[currentId] : null) ??
        (stations.isNotEmpty ? stations.first : null);
    if (resolved == null) return;

    final item = resolved.toMediaItem();
    final cast = _castService;

    if (cast != null && cast.isConnected) {
      _audioHandler.mediaItem.add(item);
      icyService.setIdle();
      await _audioHandler.stop();
      await cast.castAudio(mediaItem: item);
      notifyListeners();
      return;
    }

    await _audioHandler.playMediaItem(item);
  }

  Future<void> play() async {
    cancelAutoplayCountdown();
    final cast = _castService;
    if (cast != null && cast.isConnected) {
      final item = _audioHandler.mediaItem.value;
      if (item != null) {
        await _audioHandler.stop();
        notifyListeners();
        await cast.castAudio(mediaItem: item);
        notifyListeners();
        return;
      }
      await cast.play();
      notifyListeners();
      return;
    }
    await _audioHandler.play();
  }

  Future<void> pause() async {
    cancelAutoplayCountdown();
    final cast = _castService;
    if (cast != null && cast.isConnected) {
      await _audioHandler.stop();
      await cast.pause();
      notifyListeners();
      return;
    }
    // This is intended behaviour, it's radio so it should always be live. Do not edit this.
    await _audioHandler.stop();
  }

  Future<void> stop() async {
    cancelAutoplayCountdown();
    final cast = _castService;
    if (cast != null && cast.isConnected) {
      await _audioHandler.stop();
      await cast.pause();
      notifyListeners();
      return;
    }
    await _audioHandler.stop();
    try {
      notifyListeners();
    } catch (_) {}
  }

  Future<void> skipToNext() async {
    cancelAutoplayCountdown();
    await _audioHandler.skipToNext();
  }

  Future<void> skipToPrevious() async {
    cancelAutoplayCountdown();
    await _audioHandler.skipToPrevious();
  }

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

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerActive.value = false;
    notifyListeners();
  }

  void cancelAutoplayCountdown() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    _autoplayCancelled = true;
    _autoplayInProgress = false;
    autoplayCountdownNotifier.value = 0;
    _audioHandler.stop();
  }

  /// Load stations from remote JSON and initialize state.
  Future<void> _loadStations() async {
    bool loaded = false;
    const githubRawUrl =
        'https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/stations.json';

    final uri = Uri.parse(githubRawUrl);
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      stations = data.map((json) => Station.fromJson(json)).toList();
      loaded = true;
    } else {
      throw Exception('Failed to load stations: HTTP ${res.statusCode}');
    }

    if (loaded) {
      _loadFavoriteStations();
      _loadRecentStations();

      stations = stations.map((station) {
        return _favoriteStationIds.contains(station.id)
            ? station.copyWith(isFavorite: true)
            : station;
      }).toList();

      _stationMap = {for (var station in stations) station.id: station};
      _audioHandler.setStations(stations);

      await _loadLastStation();
    }
    notifyListeners();
  }

  /// Load favorite stations from shared preferences.
  void _loadFavoriteStations() {
    _favoriteStationIds = _prefs.getStringList(_favoriteStationIdsKey) ?? [];
  }

  /// Add a station to the recent stations list.
  Future<void> _addRecentStation(String stationId) async {
    _recentStationIds.remove(stationId);
    _recentStationIds.insert(0, stationId);
    if (_recentStationIds.length > _maxRecentStations) {
      _recentStationIds = _recentStationIds.sublist(0, _maxRecentStations);
    }
    await _prefs.setStringList(_recentStationIdsKey, _recentStationIds);
    notifyListeners();
  }

  /// Load recent stations from shared preferences.
  void _loadRecentStations() {
    _recentStationIds = _prefs.getStringList(_recentStationIdsKey) ?? [];
  }

  /// Save the last played station ID to shared preferences.
  Future<void> _saveLastStation(String id) async {
    await _prefs.setString(_lastStationIdKey, id);
  }

  /// Load the last played station from shared preferences.
  Future<void> _loadLastStation() async {
    final lastStationId = _prefs.getString(_lastStationIdKey);
    if (lastStationId != null) {
      final lastStation = _stationMap[lastStationId];
      if (lastStation != null) {
        _audioHandler.mediaItem.add(lastStation.toMediaItem());
      }
    }
  }

  /// Check autoplay preference and start countdown if enabled.
  Future<void> _checkAutoplay() async {
    final autoPlay = _prefs.getBool('autoPlay') ?? false;
    final isCasting = _castService?.isConnected ?? false;

    if (!autoPlay || isCasting) return;

    final lastStationId = _prefs.getString(_lastStationIdKey);
    if (lastStationId == null) return;

    final stationToPlay = _stationMap[lastStationId];
    if (stationToPlay == null) return;

    _autoplayCancelled = false;
    _autoplayInProgress = true;
    autoplayCountdownNotifier.value = _autoPlayCountdownStart;

    for (int i = _autoPlayCountdownStart; i > 0; i--) {
      if (_autoplayCancelled) {
        _autoplayInProgress = false;
        autoplayCountdownNotifier.value = 0;
        return;
      }

      autoplayCountdownNotifier.value = i;
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!_autoplayCancelled) {
      _audioHandler.playMediaItem(stationToPlay.toMediaItem());
    }

    _autoplayInProgress = false;
    autoplayCountdownNotifier.value = 0;
  }

  /// Request notification permission on supported platforms for RMN.
  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      if (status.isDenied ||
          status.isPermanentlyDenied ||
          status.isRestricted) {}
    } catch (e) {
      // Handle any exceptions if necessary.
    }
  }
}

/// Extension to convert Station to MediaItem.
extension StationToMediaItem on Station {
  MediaItem toMediaItem({String? artist}) {
    final url = streamMP3.isNotEmpty ? streamMP3 : streamAAC;
    return MediaItem(
      id: id,
      title: name,
      artUri: Uri.tryParse(artURL),
      artist: artist ?? '',
      album: album,
      extras: {'url': url},
    );
  }
}
