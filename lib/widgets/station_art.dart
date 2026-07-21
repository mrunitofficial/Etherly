import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/theme_data.dart';

class StationArt extends StatelessWidget {
  const StationArt({
    super.key,
    this.station,
    this.artUrl,
    this.placeholderUrl,
    this.size,
    this.borderRadius,
  });

  final Station? station;
  final String? artUrl;
  final String? placeholderUrl;
  final double? size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.radio_rounded)),
    );

    final String resolvedArtUrl;
    final String resolvedPlaceholderUrl;

    if (station != null) {
      final sizes = Theme.of(context).extension<Sizes>();
      final double? targetArtSize;
      if (size != null && sizes != null) {
        if (size! <= sizes.medium) {
          targetArtSize = 128;
        } else if (size! <= sizes.extraLargeIncreased) {
          targetArtSize = 512;
        } else {
          targetArtSize = 1024;
        }
      } else {
        targetArtSize = size;
      }

      resolvedArtUrl = station!.getArtUrl(size: targetArtSize);
      // For placeholder, use a smaller 128 resolution if available
      resolvedPlaceholderUrl = station!.getArtUrl(size: 128);
    } else {
      resolvedArtUrl = artUrl ?? '';
      resolvedPlaceholderUrl = placeholderUrl ?? '';
    }

    Widget art = resolvedArtUrl.isEmpty
        ? fallback
        : CachedNetworkImage(
            key: ValueKey(resolvedArtUrl),
            imageUrl: resolvedArtUrl,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) =>
                resolvedPlaceholderUrl.isNotEmpty
                ? Image(
                    image: CachedNetworkImageProvider(resolvedPlaceholderUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => fallback,
                  )
                : fallback,
            errorWidget: (context, url, error) => fallback,
          );

    if (borderRadius != null) {
      art = ClipRRect(borderRadius: borderRadius!, child: art);
    }

    if (size != null) {
      return SizedBox.square(dimension: size, child: art);
    }

    return AspectRatio(aspectRatio: 1, child: art);
  }
}
