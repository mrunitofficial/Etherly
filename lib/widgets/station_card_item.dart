import 'package:etherly/widgets/station_art.dart';
import 'package:flutter/material.dart';
import '../models/station.dart';

/// A card item widget representing a radio station with artwork and favorite button.
class StationCardItem extends StatelessWidget {
  const StationCardItem({
    super.key,
    required this.station,
    required this.onTap,
    required this.onFavorite,
    required this.isFavorite,
  });

  final Station station;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
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
              const SizedBox(width: 16.0),
              IconButton(
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
    );
  }
}
