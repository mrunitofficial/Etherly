import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StationArt extends StatelessWidget {
  const StationArt({super.key, required this.artUrl});

  final String artUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.radio_rounded)),
    );

    return AspectRatio(
      aspectRatio: 1,
      child: artUrl.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: artUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => fallback,
              errorWidget: (context, url, error) => fallback,
            ),
    );
  }
}
