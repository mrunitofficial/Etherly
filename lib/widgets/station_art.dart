import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

String getSafeArtUrl(MediaItem? item) {
  final uri = Uri.tryParse(item?.artUri.toString() ?? '');
  return uri != null && uri.scheme.startsWith('http') ? uri.toString() : '';
}

class StationArt extends StatelessWidget {
  const StationArt({
    super.key,
    required this.artUrl,
    required this.size,
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
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheSize = (size * pixelRatio).round();

    if (artUrl.isEmpty) {
      return _buildPlaceholder(context, size, radius, false);
    }

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          artUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _buildPlaceholder(context, size, radius, true),
          errorBuilder: (context, error, stack) =>
              _buildPlaceholder(context, size, radius, false),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: artUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
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
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: radius,
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: CircularProgressIndicator(
                  //strokeWidth: size * 0.1,
                  color: colors.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.radio_rounded,
                color: colors.onSurfaceVariant,
                size: size * 0.5,
              ),
      ),
    );
  }
}