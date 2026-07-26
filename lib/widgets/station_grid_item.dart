import 'package:etherly/models/station.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:material_ui/material_ui.dart';

/// A grid item widget representing a radio station with artwork.
class StationGridItem extends StatefulWidget {
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
  State<StationGridItem> createState() => _StationGridItemState();
}

/// State for StationGridItem handling focus animation and visual highlight.
class _StationGridItemState extends State<StationGridItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speed = theme.extension<Speed>() ?? Speed();

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _isFocused ? 1.04 : 1.0,
        duration: speed.short2,
        curve: Curves.easeOutCubic,
        child: Tooltip(
          message: widget.station.name,
          triggerMode: TooltipTriggerMode.manual,
          child: Material(
            borderRadius: widget.borderRadius,
            clipBehavior: Clip.antiAlias,
            color: theme.colorScheme.surfaceContainerHigh,
            child: Semantics(
              container: true,
              button: true,
              label: widget.station.name,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  border: _isFocused
                      ? Border.all(
                          color: theme.colorScheme.primary,
                          width: 3.0,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: StationArt(
                        station: widget.station,
                        size: 512,
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onFocusChange: (focused) {
                            setState(() => _isFocused = focused);
                          },
                          onTap: widget.onTap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
