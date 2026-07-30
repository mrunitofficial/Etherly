import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:etherly/models/cast_device.dart';

/// Manages Chromecast device discovery, connection, and media casting via native platform channel.
class ChromeCastService with ChangeNotifier {
  static const MethodChannel _channel = MethodChannel(
    'com.mrunit.etherly/cast_control',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.mrunit.etherly/cast_events',
  );

  /// Notifier for remote playback state.
  final ValueNotifier<bool> isRemotePlaying = ValueNotifier(false);

  /// Notifier for remote buffering state.
  final ValueNotifier<bool> isRemoteBuffering = ValueNotifier(false);

  /// Notifier for remote volume level (0.0 to 1.0).
  final ValueNotifier<double> remoteVolume = ValueNotifier(1.0);

  bool _disposed = false;
  bool _initialized = false;
  final List<CastDevice> _devices = [];
  CastDevice? _connectedDevice;
  StreamSubscription<dynamic>? _eventsSub;
  Completer<void>? _connectionCompleter;

  @override
  void dispose() {
    _disposed = true;
    _eventsSub?.cancel();
    isRemotePlaying.dispose();
    isRemoteBuffering.dispose();
    remoteVolume.dispose();
    super.dispose();
  }

  /// List of currently discovered Cast devices.
  List<CastDevice> get devices => List.unmodifiable(_devices);

  /// Currently connected Cast device, if any.
  CastDevice? get connectedDevice => _connectedDevice;

  /// Whether a Cast session is currently connected.
  bool get isConnected => _connectedDevice != null;

  /// Whether Chromecast is initialized.
  bool get isInitialized => _initialized;

  /// Checks if Google Cast framework is available on the current platform.
  bool isCastSupported() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  /// Initializes device discovery and attaches event listeners.
  Future<void> init() async {
    if (_initialized || !isCastSupported()) return;
    _initialized = true;

    try {
      _eventsSub = _eventChannel.receiveBroadcastStream().listen(
        _handleNativeEvent,
        onError: (Object e) {
          if (kDebugMode) print('Cast EventChannel error: $e');
        },
      );
      await _channel.invokeMethod('init');
    } catch (e) {
      if (kDebugMode) print('Failed to init ChromeCastService: $e');
    }
  }

  /// Starts discovering nearby Cast devices.
  Future<void> startDiscovery() async {
    if (!isCastSupported()) return;
    await init();
    try {
      await _channel.invokeMethod('startDiscovery');
    } catch (e) {
      if (kDebugMode) print('Failed to start Cast discovery: $e');
    }
  }

  /// Stops Cast device discovery.
  Future<void> stopDiscovery() async {
    if (!isCastSupported()) return;
    try {
      await _channel.invokeMethod('stopDiscovery');
    } catch (e) {
      if (kDebugMode) print('Failed to stop Cast discovery: $e');
    }
  }

  /// Connects to the specified Cast device and waits until session is established.
  Future<void> connectAndWait(
    CastDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!isCastSupported()) return;
    if (_connectedDevice?.id == device.id && isConnected) return;

    _connectionCompleter = Completer<void>();
    try {
      await _channel.invokeMethod('connect', {'id': device.id});
      await _connectionCompleter!.future.timeout(timeout);
    } on TimeoutException {
      throw TimeoutException('Cast session connection timed out');
    } finally {
      _connectionCompleter = null;
    }
  }

  /// Casts audio content of the specified [mediaItem] to the connected Cast device.
  Future<void> castAudio(MediaItem mediaItem) async {
    if (!isConnected) throw StateError('No Cast device connected');

    final urlStr = mediaItem.extras?['url'] as String?;
    if (urlStr == null || urlStr.isEmpty) return;

    final contentType = urlStr.toLowerCase().contains('aac')
        ? 'audio/aac'
        : 'audio/mpeg';

    try {
      await _channel.invokeMethod('loadMedia', {
        'url': urlStr,
        'title': mediaItem.title,
        'subtitle': mediaItem.artist ?? mediaItem.album ?? '',
        'imageUrl': mediaItem.artUri?.toString() ?? '',
        'contentType': contentType,
      });
    } catch (e) {
      if (kDebugMode) print('Failed to load media on Cast: $e');
    }
  }

  /// Sends play command to the remote Cast session.
  Future<void> play() async {
    if (!isConnected) return;
    try {
      await _channel.invokeMethod('play');
    } catch (e) {
      if (kDebugMode) print('Failed to send play command: $e');
    }
  }

  /// Sends pause command to the remote Cast session.
  Future<void> pause() async {
    if (!isConnected) return;
    try {
      await _channel.invokeMethod('pause');
      if (!_disposed) isRemotePlaying.value = false;
    } catch (e) {
      if (kDebugMode) print('Failed to send pause command: $e');
    }
  }

  /// Sends stop command to the remote Cast session.
  Future<void> stop() async {
    if (!isConnected) return;
    try {
      await _channel.invokeMethod('stop');
      if (!_disposed) isRemotePlaying.value = false;
    } catch (e) {
      if (kDebugMode) print('Failed to send stop command: $e');
    }
  }

  /// Sets volume for the active remote Cast session (0.0 to 1.0).
  Future<void> setRemoteVolume(double volume) async {
    if (!isConnected) return;
    final clamped = volume.clamp(0.0, 1.0);
    remoteVolume.value = clamped;
    try {
      await _channel.invokeMethod('setVolume', {'volume': clamped});
    } catch (e) {
      if (kDebugMode) print('Failed to set remote volume: $e');
    }
  }

  /// Fetches volume level from the active remote Cast session.
  Future<double?> getRemoteVolume() async {
    if (!isConnected) return null;
    try {
      final vol = await _channel.invokeMethod<double>('getVolume');
      if (vol != null && !_disposed) {
        remoteVolume.value = vol.clamp(0.0, 1.0);
      }
      return vol;
    } catch (e) {
      if (kDebugMode) print('Failed to get remote volume: $e');
      return null;
    }
  }

  /// Natively terminates local AudioService and MediaSession on Android.
  Future<void> destroyLocalMediaSession() async {
    if (!isCastSupported()) return;
    try {
      await _channel.invokeMethod('destroyLocalMediaSession');
    } catch (e) {
      if (kDebugMode) print('Failed to destroy local media session: $e');
    }
  }

  /// Ends the current casting session.
  Future<void> endCasting() async {
    if (!isCastSupported()) return;
    try {
      await _channel.invokeMethod('disconnect');
    } catch (e) {
      if (kDebugMode) print('Failed to disconnect Cast session: $e');
    }

    _connectedDevice = null;
    if (!_disposed) {
      isRemoteBuffering.value = false;
      isRemotePlaying.value = false;
      notifyListeners();
    }
  }

  /// Handles incoming real-time events from native Android EventChannel.
  void _handleNativeEvent(dynamic data) {
    if (_disposed || data is! Map) return;

    final eventType = data['event'] as String?;
    switch (eventType) {
      case 'devicesChanged':
        final list = data['devices'] as List?;
        if (list != null) {
          _devices
            ..clear()
            ..addAll(
              list.map(
                (item) =>
                    CastDevice.fromMap(Map<String, dynamic>.from(item as Map)),
              ),
            );
          notifyListeners();
        }

      case 'sessionState':
        final connected = data['connected'] == true;
        if (connected) {
          final id = data['deviceId'] as String? ?? '';
          final name = data['deviceName'] as String? ?? 'Cast Device';
          _connectedDevice = CastDevice(id: id, name: name);
          if (_connectionCompleter?.isCompleted == false) {
            _connectionCompleter?.complete();
          }
        } else {
          _connectedDevice = null;
          isRemoteBuffering.value = false;
          isRemotePlaying.value = false;
          if (_connectionCompleter?.isCompleted == false) {
            _connectionCompleter?.completeError(
              StateError('Cast session disconnected'),
            );
          }
        }
        notifyListeners();

      case 'playbackState':
        final isPlaying = data['isPlaying'] == true;
        final isBuffering = data['isLoading'] == true;
        isRemoteBuffering.value = isBuffering;
        isRemotePlaying.value = isPlaying;

      case 'volumeChanged':
        if (data['volume'] is num) {
          remoteVolume.value = (data['volume'] as num).toDouble().clamp(
            0.0,
            1.0,
          );
        }
    }
  }
}
