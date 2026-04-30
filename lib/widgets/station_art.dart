import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StationArt extends StatelessWidget {
  const StationArt({
    super.key,
    required this.artUrl,
  });

  final String artUrl;

  @override
  Widget build(BuildContext context) {
    if (artUrl.isEmpty) {
      return const Center(child: Icon(Icons.radio_rounded));
    }

    return CachedNetworkImage(
      imageUrl: artUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.radio_rounded),
      ),
    );
  }
}
