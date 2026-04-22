import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/icy_service.dart';
import 'package:etherly/services/chrome_cast_service.dart';
import 'package:etherly/services/my_audio_handler.dart';

/// Service that manages the [AudioPlayer] instance, station list, and playback logic.
class AudioPlayerService with ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  late final MyAudioHandler _audioHandler;
  final IcyService icyService = IcyService();
  final ChromeCastService? _castService;
  late final SharedPreferences _prefs;

  final ValueNotifier<bool> isReady = ValueNotifier(false);
  final ValueNotifier<bool> _radioPlayerShouldClose = ValueNotifier(false);
  ValueNotifier<bool> get radioPlayerShouldClose => _radioPlayerShouldClose;

  static const String _lastStationIdKey = 'last_station_id';
  static const String _favoriteStationIdsKey = 'favorite_station_ids';
  static const String _recentStationIdsKey = 'recent_station_ids';
  static const String _volumeKey = 'volume';
  static const int _maxRecentStations = 10;
  static const int _autoPlayCountdownStart = 3;

  List<Station> stations = [];
  Map<String, Station> _stationMap = {};
  List<String> _favoriteStationIds = [];
  List<String> _recentStationIds = [];
  List<Station> get recentStations => _recentStationIds.map((id) => _stationMap[id]).whereType<Station>().toList();

  Timer? _autoplayTimer;
  bool _autoplayCancelled = false;
  final ValueNotifier<int> autoplayCountdownNotifier = ValueNotifier(0);

  Timer? _sleepTimer;
  final ValueNotifier<bool> sleepTimerActive = ValueNotifier(false);
  bool get isSleepTimerSet => _sleepTimer != null;

  MediaItem? _currentMediaItem;
  MediaItem? get mediaItem => _currentMediaItem;

  SharedPreferences get prefs => _prefs;

  bool get isCastLoading => _castService?.isRemoteLoading.value ?? false;
  bool get isCasting => _castService?.isConnected ?? false;
  bool get isPlaying {
    if (_castService != null && _castService.isConnected) {
      return _castService.isRemotePlaying.value;
    }
    return player.playing;
  }

  double get volume => kIsWeb ? player.volume : 1.0;

  AudioPlayerService({ChromeCastService? castService}) : _castService = castService {
    _castService?.isRemotePlaying.addListener(notifyListeners);
    _castService?.isRemoteLoading.addListener(notifyListeners);
    _castService?.isCastingActive.addListener(_onCastingStateChanged);
    _init();
  }

  void _onCastingStateChanged() {
    if (_castService?.isCastingActive.value ?? false) {
      _audioHandler.hideNotification();
    } else {
      _audioHandler.showNotification();
    }
    notifyListeners();
  }

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

    // Sync ICY Metadata from just_audio natively!
    player.icyMetadataStream.listen((meta) {
      final info = meta?.info;
      final title = info?.title?.trim();
      if (title != null && title.isNotEmpty) {
        icyService.setText(title);
        _audioHandler.patchMediaItemMetadata(artist: title);
      }
    });

    icyService.addListener(notifyListeners);

    if (kIsWeb) {
      final savedVolume = _prefs.getDouble(_volumeKey) ?? 1.0;
      setVolume(savedVolume);
    }

    await _loadStations();
    await _checkAutoplay();
    isReady.value = true;
  }

  void setVolume(double value) {
    if (kIsWeb) {
      final clamped = value.clamp(0.0, 1.0);
      player.setVolume(clamped);
      _prefs.setDouble(_volumeKey, clamped);
      notifyListeners();
    }
  }

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

  /// Playback Controls
  Future<void> playMediaItem(Station? station) async {
    cancelAutoplayCountdown();
    final resolved = station ?? _stationMap[_currentMediaItem?.id] ?? (stations.isNotEmpty ? stations.first : null);
    if (resolved == null) return;

    final item = resolved.toMediaItem();
    _setMediaItem(item);

    if (_castService != null && _castService.isConnected) {
      icyService.setIdle();
      await player.stop();
      await _castService.castAudio(mediaItem: item);
      notifyListeners();
      return;
    }

    icyService.startLoading();
    try {
      await player.stop();
      await _setAudioSource(item);
      player.play().catchError((_) {});
    } catch (e) {
      if (kDebugMode) print('Error playing media item: $e');
    }
  }

  Future<void> _setAudioSource(MediaItem item) async {
    final quality = _prefs.getString('streamQuality') ?? 'mp3';
    final station = _stationMap[item.id] ?? stations.first;

    final urlPriority = quality == 'aac' 
        ? [station.streamAAC, station.streamMP3] 
        : [station.streamMP3, station.streamAAC];

    final validUrls = urlPriority.where((u) => u.isNotEmpty).toList();
    if (validUrls.isEmpty) throw Exception("No valid stream URL found");

    for (int i = 0; i < validUrls.length; i++) {
        try {
            await player.setAudioSource(AudioSource.uri(Uri.parse(validUrls[i]), tag: item));
            return;
        } on PlayerInterruptedException {
            return;
        } catch (e) {
            if (i == validUrls.length - 1) return;
        }
    }
  }

  void _setMediaItem(MediaItem item) {
    _currentMediaItem = item;
    _audioHandler.updateMediaItem(item);
    _saveLastStation(item.id);
    _addRecentStation(item.id);
    notifyListeners();
  }

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

  Future<void> pause() async {
    cancelAutoplayCountdown();
    if (_castService != null && _castService.isConnected) {
      await player.pause();
      await _castService.pause();
      notifyListeners();
      return;
    }
    await player.pause();
  }

  Future<void> stop() async {
    cancelAutoplayCountdown();
    if (_castService != null && _castService.isConnected) {
      await player.stop();
      await _castService.pause();
      notifyListeners();
      return;
    }
    await player.stop();
  }

  Future<void> skipToNext() async {
    cancelAutoplayCountdown();
    final currentIndex = stations.indexWhere((s) => s.id == _currentMediaItem?.id);
    if (currentIndex == -1 || stations.isEmpty) return;
    final nextIndex = (currentIndex + 1) % stations.length;
    await playMediaItem(stations[nextIndex]);
  }

  Future<void> skipToPrevious() async {
    cancelAutoplayCountdown();
    final currentIndex = stations.indexWhere((s) => s.id == _currentMediaItem?.id);
    if (currentIndex == -1 || stations.isEmpty) return;
    final prevIndex = (currentIndex - 1 + stations.length) % stations.length;
    await playMediaItem(stations[prevIndex]);
  }

  /// Metadata & Misc
  
  Future<void> precacheAllStationArt(BuildContext context) async {
    for (final station in stations) {
      if (station.artURL.isNotEmpty) {
        try { await precacheImage(NetworkImage(station.artURL), context); } catch (_) {}
      }
    }
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
    autoplayCountdownNotifier.value = 0;
  }

  Future<void> _loadStations() async {
    bool loaded = false;
    const githubRawUrl = 'https://raw.githubusercontent.com/mrunitofficial/Etherly-Nederland/main/stations.json';

    try {
      final res = await http.get(Uri.parse(githubRawUrl)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        stations = data.map((j) => Station.fromJson(j)).toList();
        loaded = true;
      }
    } catch (e) {
      if (kDebugMode) print('Error loading stations: $e');
    }

    if (loaded) {
      _favoriteStationIds = _prefs.getStringList(_favoriteStationIdsKey) ?? [];
      _recentStationIds = _prefs.getStringList(_recentStationIdsKey) ?? [];

      stations = stations.map((s) => _favoriteStationIds.contains(s.id) ? s.copyWith(isFavorite: true) : s).toList();
      _stationMap = {for (var s in stations) s.id: s};

      await _loadLastStation();
    }
    notifyListeners();
  }

  Future<void> _addRecentStation(String stationId) async {
    _recentStationIds.remove(stationId);
    _recentStationIds.insert(0, stationId);
    if (_recentStationIds.length > _maxRecentStations) {
      _recentStationIds = _recentStationIds.sublist(0, _maxRecentStations);
    }
    await _prefs.setStringList(_recentStationIdsKey, _recentStationIds);
    notifyListeners();
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
        autoplayCountdownNotifier.value = 0; return;
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
