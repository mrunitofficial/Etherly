import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Extracts a valid HTTP/HTTPS URL from a MediaItem.
String getSafeArtUrl(MediaItem? item) {
  final uri = Uri.tryParse(item?.artUri.toString() ?? '');
  return uri != null && uri.scheme.startsWith('http') ? uri.toString() : '';
}

/// Widget to display station artwork with caching and error handling.
class StationArt extends StatelessWidget {
  const StationArt({
    super.key,
    required this.artUrl,
    this.size = 56.0,
    this.borderRadius,
  });

  final String artUrl;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (size.isInfinite) {
      return LayoutBuilder(builder: (context, constraints) {
        final shortestSide = constraints.biggest.shortestSide;
        return _buildImage(context, shortestSide.isFinite ? shortestSide : 56.0);
      });
    }
    return _buildImage(context, size);
  }

  Widget _buildImage(BuildContext context, double size) {
    final radius = borderRadius ?? BorderRadius.circular(12.0);
    final cacheSize = (size * MediaQuery.of(context).devicePixelRatio).round();

    // WEB: Use native Image.network for stability and browser-level caching.
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          artUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          frameBuilder: (context, child, frame, wasSync) {
            if (wasSync) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _buildPlaceholder(context, size, radius, true),
          errorBuilder: (context, error, stack) =>
              _buildPlaceholder(context, size, radius, false),
        ),
      );
    }

    // MOBILE: Use CachedNetworkImage for strict memory and disk management.
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: artUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheManager: StationCacheManager.instance,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        maxWidthDiskCache: cacheSize,
        maxHeightDiskCache: cacheSize,
        fadeInDuration: const Duration(milliseconds: 300),
        useOldImageOnUrlChange: true,
        imageBuilder: (context, image) => DecoratedBox(
          decoration: BoxDecoration(image: DecorationImage(image: image, fit: BoxFit.cover)),
        ),
        placeholder: (context, url) => _buildPlaceholder(context, size, radius, true),
        errorWidget: (context, url, error) => _buildPlaceholder(context, size, radius, false),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, double size, BorderRadius radius, bool isLoading) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: radius),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: CircularProgressIndicator(strokeWidth: size * 0.1, color: colors.onSurfaceVariant),
              )
            : Icon(Icons.radio_rounded, color: colors.onSurfaceVariant, size: size * 0.5),
      ),
    );
  }
}

/// Custom CacheManager to isolate station art requests and manage storage.
class StationCacheManager {
  static final instance = kIsWeb
      ? DefaultCacheManager()
      : CacheManager(
          Config(
            'station_art_cache',
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 200,
          ),
        );
}