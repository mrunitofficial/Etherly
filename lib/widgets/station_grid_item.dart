import 'package:etherly/models/station.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:material_ui/material_ui.dart';

/// A grid item widget representing a radio station with artwork.
class StationGridItem extends StatelessWidget {
  const StationGridItem({
    super.key,
    required this.station,
    required this.onTap,
    required this.borderRadius,
  });

  final Station station;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: Tooltip(
        message: station.name,
        triggerMode: TooltipTriggerMode.manual,
        child: Material(
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surfaceContainerHigh,
          child: Stack(
            children: [
              Positioned.fill(
                child: StationArt(
                  artUrl: station.art512.isNotEmpty ? station.art512 : station.art,
                  placeholderUrl: station.art128.isNotEmpty ? station.art128 : station.art,
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
