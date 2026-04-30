import 'package:etherly/models/station.dart';
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
    return RepaintBoundary(
      child: Tooltip(
        message: station.name,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: StationArt(artUrl: station.art),
              ),
            ),
            Positioned.fill(
              child: Material(
                borderRadius: borderRadius,
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                child: InkWell(onTap: onTap),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: onFavorite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
