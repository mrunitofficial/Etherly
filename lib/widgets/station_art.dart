import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StationArt extends StatelessWidget {
  const StationArt({
    super.key,
    required this.artUrl,
    this.size,
    this.borderRadius,
  });

  final String artUrl;
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
            imageUrl: artUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => fallback,
            errorWidget: (context, url, error) => fallback,
          );

    if (borderRadius != null) {
      art = ClipRRect(
        borderRadius: borderRadius!,
        child: art,
      );
    }

    if (size != null) {
      return SizedBox.square(
        dimension: size,
        child: art,
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: art,
    );
  }
}
