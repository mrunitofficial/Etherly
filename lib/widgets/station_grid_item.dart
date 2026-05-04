import 'package:etherly/models/station.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:flutter/material.dart';

/// A grid item widget representing a radio station with artwork and favorite button.
class StationGridItem extends StatelessWidget {
  const StationGridItem({
    super.key,
    required this.station,
    required this.onTap,
    required this.onFavorite,
    required this.isFavorite,
    required this.borderRadius,
  });

  final Station station;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorite;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: Tooltip(
        message: station.name,
        child: Material(
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surfaceContainerHigh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sizes = theme.extension<Sizes>()!;
              final spacing = theme.extension<Spacing>()!;
              final showFavorite = constraints.maxWidth >= sizes.largeIncreased;
              return Stack(
                children: [
                  Positioned.fill(child: StationArt(artUrl: station.art)),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: onTap),
                    ),
                  ),
                  if (showFavorite)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(spacing.extraSmall),
                        child: IconButton.filledTonal(
                          onPressed: onFavorite,
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface
                                .withAlpha(40),
                          ),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
