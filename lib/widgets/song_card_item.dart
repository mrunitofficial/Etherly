import 'package:material_ui/material_ui.dart';

import 'package:etherly/models/device.dart';

import 'package:etherly/services/theme_data.dart';

import 'package:etherly/widgets/marquee_text.dart';
import 'package:etherly/widgets/station_art.dart';

/// A card item widget representing a song with artwork and a timestamp label.
class SongCardItem extends StatefulWidget {
  const SongCardItem({
    super.key,
    required this.songName,
    required this.artistName,
    required this.artUrl,
    required this.timeLabel,
    required this.onTap,
    this.onLongPress,
    required this.screenType,
  });

  final String songName;
  final String artistName;
  final String artUrl;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ScreenType screenType;

  @override
  State<SongCardItem> createState() => _SongCardItemState();
}

/// State for SongCardItem handling focus animation and visual highlight.
class _SongCardItemState extends State<SongCardItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;
    final sizes = theme.extension<Sizes>()!;

    return RepaintBoundary(
      child: Tooltip(
        message: '${widget.songName} - ${widget.artistName}',
        triggerMode: TooltipTriggerMode.manual,
        child: Card.filled(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: shapes.medium,
            side: _isFocused
                ? BorderSide(
                    color: theme.colorScheme.primary,
                    width: spacing.extraSmall,
                  )
                : BorderSide.none,
          ),
          child: Semantics(
            container: true,
            button: true,
            label:
                '${widget.songName} by ${widget.artistName}, ${widget.timeLabel}',
            excludeSemantics: true,
            child: InkWell(
              onFocusChange: (focused) => setState(() => _isFocused = focused),
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: Padding(
                padding: EdgeInsets.all(spacing.small),
                child: Row(
                  children: [
                    StationArt(
                      artUrl: widget.artUrl,
                      size: widget.screenType.isLargeFormat
                          ? sizes.large
                          : sizes.normal,
                      borderRadius: shapes.small,
                    ),
                    SizedBox(width: spacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MarqueeText(
                            text: widget.songName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            centerWhenFits: false,
                          ),
                          SizedBox(height: spacing.extraSmall),
                          MarqueeText(
                            text: widget.artistName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            centerWhenFits: false,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing.medium),
                    Text(
                      widget.timeLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: spacing.small),
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
