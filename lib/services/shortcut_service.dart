import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:etherly/models/station.dart';
import 'package:etherly/services/audio_player_service.dart';

/// Service for managing Android home screen pinned station shortcuts.
class ShortcutService {
  ShortcutService._();

  static const MethodChannel _channel = MethodChannel(
    'com.mrunit.etherly/shortcut',
  );

  static bool _isInitialized = false;

  /// Checks whether home screen shortcut pinning is supported on this device.
  static Future<bool> isSupported() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final bool? supported = await _channel.invokeMethod<bool>(
        'isPinShortcutSupported',
      );
      return supported ?? false;
    } on PlatformException catch (e) {
      debugPrint('ShortcutService.isSupported error: $e');
      return false;
    }
  }

  /// Initialises listeners for shortcut launches (cold app launch & runtime intent events).
  static Future<void> initialize(AudioPlayerService audioService) async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        _isInitialized) {
      return;
    }
    _isInitialized = true;

    // Listen for shortcut launches while app is running in background or foreground
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onStationShortcutOpened') {
        final String? stationId = call.arguments as String?;
        if (stationId != null && stationId.isNotEmpty) {
          await _playStationById(audioService, stationId);
        }
      }
    });

    // Check if app was started from a cold launch via shortcut
    try {
      final String? initialId = await _channel.invokeMethod<String>(
        'getInitialStationId',
      );
      if (initialId != null && initialId.isNotEmpty) {
        await _playStationById(audioService, initialId);
      }
    } on PlatformException catch (e) {
      debugPrint('ShortcutService.getInitialStationId error: $e');
    }
  }

  /// Requests creating a home screen pinned shortcut for the given [station].
  static Future<bool> pinStation(Station station) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      Uint8List? iconBytes;
      final String artUrl = station.getArtUrl(size: 512);

      if (artUrl.isNotEmpty) {
        try {
          final response = await http
              .get(Uri.parse(artUrl))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            iconBytes = response.bodyBytes;
          }
        } catch (e) {
          debugPrint('Failed to fetch station art for shortcut: $e');
        }
      }

      final bool? success = await _channel.invokeMethod<bool>(
        'pinStationShortcut',
        {'id': station.id, 'name': station.name, 'iconBytes': iconBytes},
      );
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('ShortcutService.pinStation error: $e');
      return false;
    }
  }

  /// Helper method to play a station by ID once audio player service is ready.
  static Future<void> _playStationById(
    AudioPlayerService audioService,
    String stationId,
  ) async {
    await audioService.initializationFuture;
    final station = audioService.stations.firstWhere(
      (s) => s.id == stationId,
      orElse: () => Station(
        id: stationId,
        name: '',
        slogan: '',
        streams: {},
        art: {},
        category: '',
        country: '',
      ),
    );
    if (station.streams.isNotEmpty || station.name.isNotEmpty) {
      await audioService.playMediaItem(station);
    }
  }
}
