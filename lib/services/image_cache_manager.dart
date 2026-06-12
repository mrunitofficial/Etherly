import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class StationArtCacheManager {
  static const String key = 'station_art_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Cache files for 30 days
      maxNrOfCacheObjects: 200,             // Keep up to 200 items in cache
    ),
  );
}
