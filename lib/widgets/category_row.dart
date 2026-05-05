import 'package:etherly/models/station.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A simplified, theme-driven horizontal scroller for station categories.
class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.title, required this.stations});

  final String title;
  final List<Station> stations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final sizes = theme.extension<Sizes>()!;
    final shapes = theme.extension<Shapes>()!;
    final audioService = context.read<AudioPlayerService>();
    final itemSize = sizes.largeIncreased;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useWrap = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(spacing.medium),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (useWrap)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.medium),
                child: Wrap(
                  spacing: spacing.small,
                  runSpacing: spacing.small,
                  children: stations.map((station) {
                    return SizedBox(
                      width: itemSize,
                      height: itemSize,
                      child: StationGridItem(
                        station: station,
                        isFavorite: station.isFavorite,
                        onTap: () => audioService.playMediaItem(station),
                        onFavorite: () => audioService.toggleFavorite(station),
                        borderRadius: shapes.medium,
                      ),
                    );
                  }).toList(),
                ),
              )
            else
              SizedBox(
                height: itemSize,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: spacing.medium),
                  scrollDirection: Axis.horizontal,
                  itemCount: stations.length,
                  separatorBuilder: (_, _) => SizedBox(width: spacing.small),
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return SizedBox(
                      width: itemSize,
                      child: StationGridItem(
                        station: station,
                        isFavorite: station.isFavorite,
                        onTap: () => audioService.playMediaItem(station),
                        onFavorite: () => audioService.toggleFavorite(station),
                        borderRadius: shapes.medium,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
