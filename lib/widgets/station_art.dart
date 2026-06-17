import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

class StationArt extends StatelessWidget {
  const StationArt({
    super.key,
    required this.artUrl,
    this.placeholderUrl,
    this.size,
    this.borderRadius,
  });

  final String artUrl;
  final String? placeholderUrl;
  final double? size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.radio_rounded)),
    );

    Widget art = artUrl.isEmpty
        ? fallback
        : CachedNetworkImage(
            key: ValueKey(artUrl),
            imageUrl: artUrl,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) =>
                placeholderUrl != null && placeholderUrl!.isNotEmpty
                ? Image(
                    image: CachedNetworkImageProvider(placeholderUrl!),
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
