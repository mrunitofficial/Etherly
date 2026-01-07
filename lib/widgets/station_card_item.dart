import 'package:etherly/widgets/station_art.dart';
import 'package:flutter/material.dart';
import '../models/station.dart';
import '../models/device.dart';

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
    return Tooltip(
      message: station.name,
      waitDuration: const Duration(milliseconds: 400),
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                StationArt(
                  artUrl: station.artURL,
                  size: screenType == ScreenType.largeScreen ? 84.0 : 56.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.all(8.0),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: onFavorite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
