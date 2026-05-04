import 'package:etherly/models/device.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:flutter/material.dart';

/// A card item widget representing a radio station with artwork and favorite button.
class StationCardItem extends StatelessWidget {
  const StationCardItem({
    super.key,
    required this.station,
    required this.onTap,
    required this.onFavorite,
    required this.isFavorite,
    required this.screenType,
  });

  final Station station;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorite;
  final ScreenType screenType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;
    final sizes = theme.extension<Sizes>()!;

    return RepaintBoundary(
      child: Tooltip(
        message: station.name,
        child: Card.filled(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(spacing.small),
              child: Row(
                children: [
                  StationArt(
                    artUrl: station.art,
                    size: screenType.isLargeFormat ? sizes.large : sizes.normal,
                    borderRadius: shapes.small,
                  ),
                  SizedBox(width: spacing.medium),
                  Expanded(
                    child: Text(
                      station.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: onFavorite,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
