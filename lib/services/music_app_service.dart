import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for detecting installed external music applications and managing search deep links.
class MusicAppService {
  static final MusicAppService _instance = MusicAppService._internal();

  final List<Map<String, dynamic>> _allApps = [
    {
      'id': 'youtube',
      'name': 'YouTube',
      'scheme': 'vnd.youtube://',
      'detectionSchemes': ['vnd.youtube://'],
    },
    {
      'id': 'ytmusic',
      'name': 'YT Music',
      'scheme': 'https://music.youtube.com/',
      'detectionSchemes': [
        'youtubemusic://',
        'youtube-music://',
        'vnd.youtube.music://',
      ],
    },
    {
      'id': 'spotify',
      'name': 'Spotify',
      'scheme': 'spotify:search:',
      'detectionSchemes': ['spotify:'],
    },
    {
      'id': 'apple_music',
      'name': 'Apple Music',
      'scheme': 'https://music.apple.com/',
      'detectionSchemes': ['music://', 'vnd.apple.music://', 'apple-music://'],
    },
    {
      'id': 'tidal',
      'name': 'Tidal',
      'scheme': 'tidal://',
      'detectionSchemes': ['tidal://'],
    },
    {
      'id': 'soundcloud',
      'name': 'SoundCloud',
      'scheme': 'soundcloud://',
      'detectionSchemes': ['soundcloud://'],
    },
    {
      'id': 'amazon',
      'name': 'Amazon Music',
      'scheme': 'amznmp3://',
      'detectionSchemes': ['amznmp3://'],
    },
  ];

  List<Map<String, String>>? _cachedAvailableApps;

  /// Factory constructor returning the singleton instance.
  factory MusicAppService() => _instance;
  MusicAppService._internal();

  /// Resolves all available installed music applications.
  Future<List<Map<String, String>>> getAvailableApps({
    bool forceRefresh = false,
  }) async {
    if (_cachedAvailableApps != null && !forceRefresh) {
      return _cachedAvailableApps!;
    }

    final List<Map<String, String>> available = [];
    for (final app in _allApps) {
      try {
        final List<String> schemes = List<String>.from(app['detectionSchemes']);
        bool isInstalled = false;

        for (final scheme in schemes) {
          if (await canLaunchUrl(Uri.parse(scheme))) {
            isInstalled = true;
            break;
          }
        }

        if (isInstalled) {
          available.add({
            'id': app['id'] as String,
            'name': app['name'] as String,
            'scheme': app['scheme'] as String,
          });
        }
      } catch (e) {
        if (kDebugMode) print('Error checking app availability: $e');
      }
    }

    _cachedAvailableApps = available;
    return available;
  }

  /// Returns the cached available apps, if any.
  List<Map<String, String>>? get cachedAvailableApps => _cachedAvailableApps;

  /// Returns the list of all supported apps, regardless of installation.
  List<Map<String, dynamic>> getAllSupportedApps() => List.from(_allApps);
}
