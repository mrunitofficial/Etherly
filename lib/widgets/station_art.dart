import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

/// Safely extracts a valid art URL from a MediaItem
/// Returns empty string if the URL is invalid or not HTTP/HTTPS
String getSafeArtUrl(MediaItem? mediaItem) {
  final uri = mediaItem?.artUri;
  if (uri == null) return '';

  final uriString = uri.toString();
  if (uriString.isEmpty) return '';

  final parsedUri = Uri.tryParse(uriString);

  if (parsedUri != null &&
      (parsedUri.scheme == 'http' || parsedUri.scheme == 'https')) {
    return uriString;
  }

  return '';
}

/// A compact build that resolves size once and uses local closures for placeholders/error.
class StationArt extends StatefulWidget {
  const StationArt({
    super.key,
    required this.artUrl,
    this.size = _defaultSize,
    this.borderRadius,
  });

  final String artUrl;
  final double size;
  final BorderRadius? borderRadius;
  static const _defaultSize = 56.0;

  @override
  State<StationArt> createState() => _StationArtState();
}

class _StationArtState extends State<StationArt> {
  bool _showPlaceholder = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showPlaceholder = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget buildForSize(double resolvedSize) {
      final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(12.0);
      final colorScheme = Theme.of(context).colorScheme;

      Widget fallback({required bool loading}) {
        final fallbackBackgroundColor = colorScheme.surfaceContainerHighest;
        final fallbackContentColor = colorScheme.onSurfaceVariant;
        final indicatorSize = resolvedSize * 0.30;
        final indicatorStrokeWidth = indicatorSize * 0.12;

        return Container(
          width: resolvedSize,
          height: resolvedSize,
          decoration: BoxDecoration(
            color: fallbackBackgroundColor,
            borderRadius: effectiveBorderRadius,
          ),
          child: Center(
            child: (loading && !_showPlaceholder)
                ? SizedBox(
                    width: indicatorSize,
                    height: indicatorSize,
                    child: CircularProgressIndicator(
                      color: fallbackContentColor,
                      strokeWidth: indicatorStrokeWidth,
                    ),
                  )
                : Icon(
                    Icons.radio_rounded,
                    color: fallbackContentColor,
                    size: resolvedSize * 0.30,
                  ),
          ),
        );
      }

      final devicePixelRatio =
          MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
      final cacheDimension = (resolvedSize * devicePixelRatio).round();

      return ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: CachedNetworkImage(
          imageUrl: widget.artUrl,
          height: resolvedSize,
          width: resolvedSize,
          fit: BoxFit.cover,
          memCacheWidth: cacheDimension,
          memCacheHeight: cacheDimension,
          maxWidthDiskCache: cacheDimension,
          maxHeightDiskCache: cacheDimension,
          fadeInDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 500),
          fadeOutDuration: Duration.zero,
          imageBuilder: (_, image) => DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(image: image, fit: BoxFit.cover),
            ),
          ),

          placeholder: (_, _) => Material(
            color: Colors.transparent,
            child: fallback(loading: true),
          ),
          errorWidget: (_, _, _) => fallback(loading: false),
        ),
      );
    }

    if (widget.size.isInfinite) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final shortest = constraints.biggest.shortestSide;
          final resolved = shortest.isFinite ? shortest : StationArt._defaultSize;
          return buildForSize(resolved);
        },
      );
    } else {
      return buildForSize(widget.size);
    }
  }
}
