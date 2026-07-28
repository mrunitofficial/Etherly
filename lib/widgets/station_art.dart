import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import 'package:etherly/models/station.dart';

import 'package:etherly/services/theme_data.dart';

/// Artwork widget for rendering station image with fallback states.
class StationArt extends StatelessWidget {
  /// Standard widget constructor.
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

  /// Pre-fetches all station art icons in two phases (128px first for immediate UI, then 512px) to improve UI responsiveness.
  static Future<void> precacheStations(
    BuildContext context,
    List<Station> stations,
  ) async {
    final lowResFutures = <Future<void>>[];
    for (final station in stations) {
      final art128Url = station.getArtUrl(size: 128);
      if (art128Url.isNotEmpty) {
        final provider = CachedNetworkImageProvider(art128Url);
        if (context.mounted) {
          lowResFutures.add(
            precacheImage(provider, context).catchError((_) {}),
          );
        }
      }
    }
    await Future.wait(lowResFutures);

    if (!context.mounted) return;

    final highResFutures = <Future<void>>[];
    for (final station in stations) {
      final art512Url = station.getArtUrl(size: 512);
      if (art512Url.isNotEmpty) {
        final provider = CachedNetworkImageProvider(art512Url);
        if (context.mounted) {
          highResFutures.add(
            precacheImage(provider, context).catchError((_) {}),
          );
        }
      }
    }
    await Future.wait(highResFutures);
  }

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.radio_rounded)),
    );

    final String resolvedArtUrl = station != null
        ? station!.getArtUrl(size: size)
        : (artUrl ?? '');

    final speed = Theme.of(context).extension<Speed>() ?? Speed();
    final fadeDuration = speed.short3;

    Widget art = resolvedArtUrl.isEmpty
        ? fallback
        : CachedNetworkImage(
            imageUrl: resolvedArtUrl,
            fit: BoxFit.cover,
            useOldImageOnUrlChange: true,
            fadeInDuration: fadeDuration,
            placeholderFadeInDuration: fadeDuration,
            placeholder: (context, url) => fallback,
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
