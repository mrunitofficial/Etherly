import 'package:etherly/models/device.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:etherly/widgets/marquee_text.dart';
import 'package:material_ui/material_ui.dart';

/// A card item widget representing a song with artwork and a timestamp label.
class SongCardItem extends StatelessWidget {
  const SongCardItem({
    super.key,
    required this.songName,
    required this.artistName,
    required this.artUrl,
    required this.timeLabel,
    required this.onTap,
    required this.screenType,
  });

  final String songName;
  final String artistName;
  final String artUrl;
  final String timeLabel;
  final VoidCallback onTap;
  final ScreenType screenType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;
    final sizes = theme.extension<Sizes>()!;

    return RepaintBoundary(
      child: Tooltip(
        message: '$songName - $artistName',
        triggerMode: TooltipTriggerMode.manual,
        child: Card.filled(
          clipBehavior: Clip.hardEdge,
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(spacing.small),
              child: Row(
                children: [
                  StationArt(
                    artUrl: artUrl,
                    size: screenType.isLargeFormat ? sizes.large : sizes.normal,
                    borderRadius: shapes.small,
                  ),
                  SizedBox(width: spacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MarqueeText(
                          text: songName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          centerWhenFits: false,
                        ),
                        Text(
                          artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    timeLabel,
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
    );
  }
}
