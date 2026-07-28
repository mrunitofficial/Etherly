import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:etherly/models/cast_device.dart';


/// Manages Chromecast device discovery, connection, and media casting via native platform channel.
class ChromeCastService with ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.mrunit.etherly/cast_control');
  static const EventChannel _eventChannel = EventChannel('com.mrunit.etherly/cast_events');

  bool _disposed = false;
  bool _initialized = false;

  final List<CastDevice> _devices = [];

  /// List of currently discovered Cast devices.
  List<CastDevice> get devices => List.unmodifiable(_devices);

  CastDevice? _connectedDevice;

  /// Currently connected Cast device, if any.
  CastDevice? get connectedDevice => _connectedDevice;

  /// Notifier for remote playback state.
  final ValueNotifier<bool> isRemotePlaying = ValueNotifier(false);

  /// Notifier for active casting status.
  final ValueNotifier<bool> isCastingActive = ValueNotifier(false);

  /// Notifier for remote volume level (0.0 to 1.0).
  final ValueNotifier<double> remoteVolume = ValueNotifier(1.0);

  StreamSubscription<dynamic>? _eventsSub;

  /// Whether Chromecast is initialized.
  bool get isInitialized => _initialized;

  /// Whether a Cast session is currently connected.
  bool get isConnected => _connectedDevice != null;

  /// Checks if Google Cast framework is available on the current platform.
  bool isCastSupported() {
    return defaultTargetPlatform == TargetPlatform.android;
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
      await refreshConnectedState();
    } catch (e) {
      if (kDebugMode) print('Failed to init ChromeCastService: $e');
    }
  }

  /// Refreshes the active connected Cast device from native side.
  Future<void> refreshConnectedState() async {
    if (!isCastSupported()) return;
    try {
      final String? deviceName = await _channel.invokeMethod<String>('getConnectedDevice');
      if (deviceName != null && deviceName.isNotEmpty) {
        _connectedDevice = CastDevice(id: 'connected', name: deviceName);
        isCastingActive.value = true;
      } else {
        _connectedDevice = null;
        isCastingActive.value = false;
      }
      notifyListeners();
    } catch (_) {}
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
    } catch (_) {}
  }

  /// Connects to the specified Cast device and waits until session is established.
  Future<void> connectAndWait(
    CastDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!isCastSupported()) return;
    if (_connectedDevice?.id == device.id && isConnected) return;

    if (!_disposed) isCastingActive.value = true;

    try {
      await _channel.invokeMethod('connect', {'id': device.id});
      final deadline = DateTime.now().add(timeout);
      while (!_disposed && !isConnected && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!isConnected && !_disposed) {
        isCastingActive.value = false;
        throw TimeoutException('Cast session connection timed out');
      }
    } catch (e) {
      if (!_disposed) isCastingActive.value = false;
      rethrow;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  /// Casts audio content of the specified [mediaItem] to the connected Cast device.
  Future<void> castAudio(MediaItem mediaItem) async {
    if (!isConnected) throw StateError('No Cast device connected');

    final urlStr = mediaItem.extras?['url'] as String?;
    if (urlStr == null || urlStr.isEmpty) return;

    final contentType = urlStr.toLowerCase().contains('aac') ? 'audio/aac' : 'audio/mpeg';

    try {
      await _channel.invokeMethod('loadMedia', {
        'url': urlStr,
        'title': mediaItem.title,
        'subtitle': mediaItem.artist ?? mediaItem.album ?? '',
        'imageUrl': mediaItem.artUri?.toString() ?? '',
        'contentType': contentType,
      });
      if (!_disposed) isRemotePlaying.value = true;
    } catch (e) {
      if (kDebugMode) print('Failed to load media on Cast: $e');
    }
  }


  /// Sends play command to the remote Cast session.
  Future<void> play() async {
    if (!isConnected) return;
    try {
      await _channel.invokeMethod('play');
      if (!_disposed) isRemotePlaying.value = true;
    } catch (_) {}
  }

  /// Sends pause command to the remote Cast session.
  Future<void> pause() async {
    if (!isConnected) return;
    try {
      await _channel.invokeMethod('pause');
      if (!_disposed) isRemotePlaying.value = false;
    } catch (_) {}
  }

  /// Sends stop command to the remote Cast session.
  Future<void> stop() async {
    if (!isConnected) return;
    try {
      await _channel.invokeMethod('stop');
      if (!_disposed) isRemotePlaying.value = false;
    } catch (_) {}
  }

  /// Sets volume for the active remote Cast session (0.0 to 1.0).
  Future<void> setRemoteVolume(double volume) async {
    if (!isConnected) return;
    final clamped = volume.clamp(0.0, 1.0);
    remoteVolume.value = clamped;
    try {
      await _channel.invokeMethod('setVolume', {'volume': clamped});
    } catch (_) {}
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
    } catch (_) {
      return null;
    }
  }

  /// Ends the current casting session.
  Future<void> endCasting() async {
    if (!isCastSupported()) return;

    try {
      await _channel.invokeMethod('disconnect');
    } catch (_) {}

    _connectedDevice = null;
    if (!_disposed) {
      isRemotePlaying.value = false;
      isCastingActive.value = false;
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
            ..addAll(list.map((item) => CastDevice.fromMap(Map<String, dynamic>.from(item as Map))));
          notifyListeners();
        }

      case 'sessionState':
        final connected = data['connected'] == true;
        if (connected) {
          final id = data['deviceId'] as String? ?? '';
          final name = data['deviceName'] as String? ?? 'Cast Device';
          _connectedDevice = CastDevice(id: id, name: name);
          isCastingActive.value = true;
        } else {
          _connectedDevice = null;
          isCastingActive.value = false;
          isRemotePlaying.value = false;
        }
        notifyListeners();

      case 'playbackState':
        final isPlaying = data['isPlaying'] == true;
        isRemotePlaying.value = isPlaying;

      case 'volumeChanged':
        if (data['volume'] is num) {
          remoteVolume.value = (data['volume'] as num).toDouble().clamp(0.0, 1.0);
        }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _eventsSub?.cancel();
    isRemotePlaying.dispose();
    isCastingActive.dispose();
    remoteVolume.dispose();
    super.dispose();
  }
}
