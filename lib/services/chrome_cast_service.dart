import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

/// Manages Chromecast device discovery, connection, and media casting.
class ChromeCastService with ChangeNotifier {
  bool isCastSupported({bool horizontalWeb = false}) {
    if (horizontalWeb) return false;
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  bool _disposed = false;

  final List<GoogleCastDevice> _devices = [];
  List<GoogleCastDevice> get devices => List.unmodifiable(_devices);

  GoogleCastDevice? _connectedDevice;
  GoogleCastDevice? get connectedDevice => _connectedDevice;

  final ValueNotifier<bool> isRemotePlaying = ValueNotifier(false);
  final ValueNotifier<bool> isRemoteLoading = ValueNotifier(false);
  final ValueNotifier<bool> isCastingActive = ValueNotifier(false);

  StreamSubscription<List<GoogleCastDevice>>? _devicesSub;
  StreamSubscription<GoogleCastSession?>? _sessionSub;
  Timer? _loadingTimeout;
  DateTime? _loadingStartTime;

  bool _initialized = false;
  bool get initialized => _initialized;

  bool get isConnected => _connectedDevice != null;

  /// Initializes the Chromecast service.
  Future<void> init() async {
    if (_initialized) return;
    if (!isCastSupported()) {
      _initialized = true;
      return;
    }

    try {
      _devicesSub?.cancel();
      _sessionSub?.cancel();
      _loadingTimeout?.cancel();
      // Don't stop existing cast sessions during initialization
      // This allows hot restart without interrupting casting
    } catch (_) {
      // Ignore all cleanup errors
    }

    await Future.delayed(const Duration(milliseconds: 100));

    const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
    final options = Platform.isIOS
        ? IOSGoogleCastOptions(
            GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
          )
        : GoogleCastOptionsAndroid(appId: appId);

    await GoogleCastContext.instance.setSharedInstanceWithOptions(options);

    _devicesSub = GoogleCastDiscoveryManager.instance.devicesStream.listen((
      devices,
    ) {
      if (_disposed) return;
      _devices
        ..clear()
        ..addAll(devices);
      if (!_disposed) notifyListeners();
    });

    _initialized = true;
    if (!_disposed) notifyListeners();
    _setupSessionListener();
  }

  /// Sets up the session state listener.
  void _setupSessionListener() {
    _sessionSub?.cancel();

    _sessionSub = GoogleCastSessionManager.instance.currentSessionStream.listen(
      (session) {
        if (_disposed) return;
        final connected =
            session != null &&
            GoogleCastSessionManager.instance.connectionState ==
                GoogleCastConnectState.connected;

        if (connected) {
          _connectedDevice = session.device;
          if (!_disposed) isCastingActive.value = true;
          if (!_devices.any((d) => d.uniqueID == _connectedDevice!.uniqueID)) {
            _devices.insert(0, _connectedDevice!);
          }
        } else {
          _connectedDevice = null;
          if (!_disposed) isCastingActive.value = false;
          if (!isRemoteLoading.value) {
            if (!_disposed) isRemotePlaying.value = false;
          }
        }
        if (!_disposed) notifyListeners();
      },
    );
  }

  /// Connects to the specified Cast device and waits until the connection is established.
  Future<void> connectAndWait(
    GoogleCastDevice device, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isCastSupported()) return;
    if (_connectedDevice?.uniqueID == device.uniqueID) return;

    _setLoading(true);

    // Immediately signal that we're about to cast to trigger notification hiding
    if (!_disposed) isCastingActive.value = true;

    await GoogleCastSessionManager.instance.startSessionWithDevice(device);

    final deadline = DateTime.now().add(timeout);
    while (_connectedDevice?.uniqueID != device.uniqueID) {
      if (DateTime.now().isAfter(deadline)) {
        if (!_disposed) isCastingActive.value = false;
        throw TimeoutException('Connection timeout');
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Casts audio content to the connected Cast device.
  /// Can accept either a MediaItem or direct parameters.
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
    
    // Small delay to ensure UI can update before loading starts
    await Future.delayed(const Duration(milliseconds: 50));

    if (mediaItem != null) {
      final urlStr = mediaItem.extras?['url'] as String?;
      if (urlStr == null || urlStr.isEmpty) {
        _setLoading(false);
        return;
      }

      contentUrl = Uri.parse(urlStr);
      contentType = urlStr.toLowerCase().contains('aac')
          ? 'audio/aac'
          : 'audio/mpeg';
      title = mediaItem.title ?? 'Etherly Radio';
      imageUrl = mediaItem.artUri;
    }

    if (contentUrl == null) {
      _setLoading(false);
      throw ArgumentError('contentUrl is required');
    }

    await GoogleCastRemoteMediaClient.instance.loadMedia(
      GoogleCastMediaInformation(
        contentId: title ?? 'Etherly Radio',
        streamType: CastMediaStreamType.live,
        contentUrl: contentUrl,
        contentType: contentType ?? 'audio/mpeg',
        metadata: GoogleCastGenericMediaMetadata(
          title: title ?? 'Etherly Radio',
          subtitle: subtitle,
          images:
              imageUrl != null &&
                  (imageUrl.scheme == 'http' || imageUrl.scheme == 'https')
              ? [GoogleCastImage(url: imageUrl, height: 512, width: 512)]
              : null,
        ),
      ),
      autoPlay: true,
      playPosition: Duration.zero,
      playbackRate: 1.0,
    );

    if (!_disposed) isRemotePlaying.value = true;
    _setLoading(false);
  }

  /// Controls for the cast session.
  Future<void> play() async {
    if (!isConnected) return;
    _setLoading(true);
    await GoogleCastRemoteMediaClient.instance.play();
    if (!_disposed) isRemotePlaying.value = true;
    _setLoading(false);
  }

  Future<void> pause() async {
    if (!isConnected) return;
    await GoogleCastRemoteMediaClient.instance.pause();
    if (!_disposed) isRemotePlaying.value = false;
  }

  /// Ends the current casting session.
  Future<void> endCasting() async {
    if (!isCastSupported()) return;

    _loadingTimeout?.cancel();

    try {
      // Add timeouts to prevent hanging
      await GoogleCastRemoteMediaClient.instance.stop().timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );
      await GoogleCastSessionManager.instance.endSessionAndStopCasting().timeout(
        const Duration(seconds: 1),
        onTimeout: () => false,
      );
    } catch (_) {
      // Ignore cleanup errors.
    }

    _connectedDevice = null;
    if (!_disposed) {
      isRemotePlaying.value = false;
      isRemoteLoading.value = false;
      isCastingActive.value = false;
      notifyListeners();
    }
  }

  /// Manages the loading state with a timeout.
  void _setLoading(bool loading) {
    if (_disposed) return;
    if (!loading) {
      // Ensure minimum loading duration of 400ms for better UX
      final startTime = _loadingStartTime;
      if (startTime != null) {
        final elapsed = DateTime.now().difference(startTime);
        final remaining = const Duration(milliseconds: 400) - elapsed;
        
        if (remaining > Duration.zero) {
          // Delay turning off the loading state
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
    _devicesSub?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }
}
