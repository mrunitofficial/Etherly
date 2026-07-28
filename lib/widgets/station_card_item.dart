import 'package:material_ui/material_ui.dart';

import 'package:etherly/models/device.dart';
import 'package:etherly/models/station.dart';

import 'package:etherly/services/theme_data.dart';

import 'package:etherly/widgets/station_art.dart';

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
  bool _isCardFocused = false;
  late final FocusNode _favoriteFocusNode;

  @override
  void initState() {
    super.initState();
    _favoriteFocusNode = FocusNode();
    _favoriteFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _favoriteFocusNode.removeListener(_onFocusChange);
    _favoriteFocusNode.dispose();
    super.dispose();
  }

  /// Rebuilds card border highlight when favorite button focus state changes.
  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;
    final sizes = theme.extension<Sizes>()!;

    final baseColor = theme.colorScheme.surfaceContainerHigh;
    final focusColor = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.12),
      baseColor,
    );

    return RepaintBoundary(
      child: Tooltip(
        message: widget.station.name,
        triggerMode: TooltipTriggerMode.manual,
        child: Card.filled(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          color: _isCardFocused ? focusColor : baseColor,
          shape: RoundedRectangleBorder(
            borderRadius: shapes.medium,
            side: _isCardFocused
                ? BorderSide(
                    color: theme.colorScheme.primary,
                    width: spacing.extraSmall,
                  )
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
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    onFocusChange: (focused) {
                      setState(() => _isCardFocused = focused);
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
                                color: theme.colorScheme.onSurface,
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
                focusNode: _favoriteFocusNode,
                tooltip: widget.isFavorite
                    ? 'Remove ${widget.station.name} from favorites'
                    : 'Add ${widget.station.name} to favorites',
                icon: Icon(
                  widget.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: widget.onFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
