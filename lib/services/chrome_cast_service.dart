import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:etherly/models/cast_device.dart';

/// Manages Chromecast device discovery, connection, and media casting via native platform channel.
class ChromeCastService with ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.mrunit.etherly/cast_control');
  // ignore: unused_field
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

  /// Notifier for remote loading/buffering state.
  final ValueNotifier<bool> isRemoteLoading = ValueNotifier(false);

  /// Notifier for active casting status.
  final ValueNotifier<bool> isCastingActive = ValueNotifier(false);

  /// Notifier for remote volume level (0.0 to 1.0).
  final ValueNotifier<double> remoteVolume = ValueNotifier(1.0);

  StreamSubscription<dynamic>? _eventsSub;
  Timer? _loadingTimeout;
  DateTime? _loadingStartTime;

  /// Whether Chromecast is initialized.
  bool get initialized => _initialized;

  /// Whether a Cast device is currently connected.
  bool get isConnected => _connectedDevice != null;

  /// Checks if casting is supported on the current platform.
  bool isCastSupported({bool horizontalWeb = false}) {
    if (horizontalWeb || kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// Initializes the Chromecast service and platform channel listeners.
  Future<void> init({String? appId}) async {
    if (_initialized) return;
    if (!isCastSupported()) {
      _initialized = true;
      return;
    }

    try {
      _eventsSub?.cancel();
      _loadingTimeout?.cancel();
    } catch (_) {}

    _initialized = true;
    if (!_disposed) notifyListeners();
  }

  /// Connects to the specified Cast device.
  Future<void> connectAndWait(
    CastDevice device, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isCastSupported()) return;
    if (_connectedDevice?.id == device.id) return;

    _setLoading(true);
    if (!_disposed) isCastingActive.value = true;
    _connectedDevice = device;

    try {
      await _channel.invokeMethod('connect', {'id': device.id});
    } catch (_) {}

    _setLoading(false);
  }

  /// Casts audio content to the connected Cast device.
  Future<void> castAudio({
    dynamic mediaItem,
    Uri? contentUrl,
    String? contentType,
    String? title,
    String? subtitle,
    Uri? imageUrl,
  }) async {
    if (!isConnected) throw StateError('No Cast device connected');

    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 50));

    if (mediaItem != null) {
      final urlStr = mediaItem.extras?['url'] as String?;
      if (urlStr == null || urlStr.isEmpty) {
        _setLoading(false);
        return;
      }

      contentUrl = Uri.parse(urlStr);
      contentType = urlStr.toLowerCase().contains('aac') ? 'audio/aac' : 'audio/mpeg';
      title = mediaItem.title ?? 'Etherly Radio';
      imageUrl = mediaItem.artUri;
    }

    if (contentUrl == null) {
      _setLoading(false);
      throw ArgumentError('contentUrl is required');
    }

    if (!_disposed) isRemotePlaying.value = true;
    _setLoading(false);
  }

  /// Sends play command to the remote Cast session.
  Future<void> play() async {
    if (!isConnected) return;
    _setLoading(true);
    try {
      await _channel.invokeMethod('play');
    } catch (_) {}
    if (!_disposed) isRemotePlaying.value = true;
    _setLoading(false);
  }

  /// Sends pause command to the remote Cast session.
  Future<void> pause() async {
    if (!isConnected) return;
    try {
      await _channel.invokeMethod('pause');
    } catch (_) {}
    if (!_disposed) isRemotePlaying.value = false;
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

  /// Ends the current casting session.
  Future<void> endCasting() async {
    if (!isCastSupported()) return;

    _loadingTimeout?.cancel();

    try {
      await _channel.invokeMethod('disconnect');
    } catch (_) {}

    _connectedDevice = null;
    if (!_disposed) {
      isRemotePlaying.value = false;
      isRemoteLoading.value = false;
      isCastingActive.value = false;
      notifyListeners();
    }
  }

  /// Manages loading state with a minimum display timeout.
  void _setLoading(bool loading) {
    if (_disposed) return;
    if (!loading) {
      final startTime = _loadingStartTime;
      if (startTime != null) {
        final elapsed = DateTime.now().difference(startTime);
        final remaining = const Duration(milliseconds: 400) - elapsed;

        if (remaining > Duration.zero) {
          _loadingTimeout?.cancel();
          _loadingTimeout = Timer(remaining, () {
            if (_disposed) return;
            isRemoteLoading.value = false;
            _loadingTimeout = null;
            _loadingStartTime = null;
          });
          return;
        }
      }

      _loadingTimeout?.cancel();
      _loadingTimeout = null;
      _loadingStartTime = null;
      if (!_disposed) isRemoteLoading.value = false;
      return;
    }

    _loadingStartTime = DateTime.now();
    if (!_disposed) isRemoteLoading.value = true;
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 5), () {
      if (_disposed) return;
      isRemoteLoading.value = false;
      _loadingTimeout = null;
      _loadingStartTime = null;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _loadingTimeout?.cancel();
    _eventsSub?.cancel();
    isRemotePlaying.dispose();
    isRemoteLoading.dispose();
    isCastingActive.dispose();
    remoteVolume.dispose();
    super.dispose();
  }
}
