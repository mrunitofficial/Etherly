import 'package:etherly/models/device.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:material_ui/material_ui.dart';

/// A card item widget representing a radio station with artwork and favorite button.
class StationCardItem extends StatefulWidget {
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
  State<StationCardItem> createState() => _StationCardItemState();
}

/// State for StationCardItem handling focus animation and visual highlight.
class _StationCardItemState extends State<StationCardItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;
    final sizes = theme.extension<Sizes>()!;
    final speed = theme.extension<Speed>() ?? Speed();

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _isFocused ? 1.03 : 1.0,
        duration: speed.short2,
        curve: Curves.easeOutCubic,
        child: Tooltip(
          message: widget.station.name,
          triggerMode: TooltipTriggerMode.manual,
          child: Card.filled(
            clipBehavior: Clip.hardEdge,
            margin: EdgeInsets.zero,
            color: _isFocused
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: shapes.medium,
              side: _isFocused
                  ? BorderSide(color: theme.colorScheme.primary, width: 2.0)
                  : BorderSide.none,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    container: true,
                    button: true,
                    label: widget.station.name,
                    excludeSemantics: true,
                    child: InkWell(
                      onFocusChange: (focused) {
                        setState(() => _isFocused = focused);
                      },
                      onTap: widget.onTap,
                      child: Padding(
                        padding: EdgeInsets.all(spacing.small),
                        child: Row(
                          children: [
                            StationArt(
                              station: widget.station,
                              size: widget.screenType.isLargeFormat
                                  ? sizes.large
                                  : sizes.normal,
                              borderRadius: shapes.small,
                            ),
                            SizedBox(width: spacing.medium),
                            Expanded(
                              child: Text(
                                widget.station.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _isFocused
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: widget.isFavorite
                      ? 'Remove ${widget.station.name} from favorites'
                      : 'Add ${widget.station.name} to favorites',
                  icon: Icon(
                    widget.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _isFocused
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                  onPressed: widget.onFavorite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
