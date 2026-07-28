import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../models/station.dart';
import '../services/theme_data.dart';

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

    final String resolvedArtUrl;
    final String resolvedPlaceholderUrl;

    if (station != null) {
      final sizes = Theme.of(context).extension<Sizes>();
      final double? targetArtSize;
      if (size != null && sizes != null) {
        if (size! <= sizes.extraLargeIncreased) {
          targetArtSize = 512;
        } else {
          targetArtSize = 1024;
        }
      } else {
        targetArtSize = size ?? 512;
      }

      resolvedArtUrl = station!.getArtUrl(size: targetArtSize);
      // For placeholder, use 512 if target size is 1024, otherwise 128
      resolvedPlaceholderUrl =
          station!.getArtUrl(size: targetArtSize == 1024 ? 512 : 128);
    } else {
      resolvedArtUrl = artUrl ?? '';
      resolvedPlaceholderUrl = placeholderUrl ?? '';
    }

    final speed = Theme.of(context).extension<Speed>() ?? Speed();
    final fadeDuration = speed.medium1;

    final bool hasSeparatePlaceholder =
        resolvedPlaceholderUrl.isNotEmpty && resolvedPlaceholderUrl != resolvedArtUrl;

    Widget art = resolvedArtUrl.isEmpty
        ? fallback
        : CachedNetworkImage(
            imageUrl: resolvedArtUrl,
            fit: BoxFit.cover,
            useOldImageOnUrlChange: true,
            fadeInDuration: hasSeparatePlaceholder ? Duration.zero : fadeDuration,
            placeholder: (context, url) => hasSeparatePlaceholder
                ? CachedNetworkImage(
                    imageUrl: resolvedPlaceholderUrl,
                    fit: BoxFit.cover,
                    useOldImageOnUrlChange: true,
                    fadeInDuration: fadeDuration,
                    errorWidget: (context, url, error) => fallback,
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
