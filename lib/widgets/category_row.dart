import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/radio_player_service.dart';
import 'package:etherly/widgets/station_grid_item.dart';

/// A horizontal row widget displaying a category of radio stations.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.title,
    required this.stations,
    required this.audioPlayerService,
    required this.screenWidth,
  });

  final String title;
  final List<Station> stations;
  final AudioPlayerService audioPlayerService;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final double itemWidth = 128.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: stations.map((station) {
                return Selector<AudioPlayerService, Station?>(
                  selector: (context, service) => service.stations.firstWhere(
                    (s) => s.id == station.id,
                    orElse: () => station,
                  ),
                  shouldRebuild: (prev, next) =>
                      prev?.isFavorite != next?.isFavorite,
                  builder: (context, updatedStation, _) {
                    if (updatedStation == null) return const SizedBox.shrink();
                    return SizedBox(
                      width: itemWidth,
                      height: itemWidth,
                      child: RepaintBoundary(
                        child: StationGridItem(
                          station: updatedStation,
                          isFavorite: updatedStation.isFavorite,
                          onTap: () =>
                              audioPlayerService.playMediaItem(updatedStation),
                          onFavorite: () =>
                              audioPlayerService.toggleFavorite(updatedStation),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          )
        else
          SizedBox(
            height: itemWidth,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemCount: stations.length,
              itemExtent: itemWidth + 8.0,
              cacheExtent: (itemWidth * 3),
              itemBuilder: (context, index) {
                final stationId = stations[index].id;
                return Selector<AudioPlayerService, Station?>(
                  selector: (context, service) => service.stations.firstWhere(
                    (s) => s.id == stationId,
                    orElse: () => stations[index],
                  ),
                  shouldRebuild: (prev, next) =>
                      prev?.isFavorite != next?.isFavorite,
                  builder: (context, station, _) {
                    if (station == null) return const SizedBox.shrink();
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Padding(
                        key: ValueKey(station.id),
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: SizedBox(
                          width: itemWidth,
                          child: RepaintBoundary(
                            child: StationGridItem(
                              station: station,
                              isFavorite: station.isFavorite,
                              onTap: () =>
                                  audioPlayerService.playMediaItem(station),
                              onFavorite: () =>
                                  audioPlayerService.toggleFavorite(station),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
