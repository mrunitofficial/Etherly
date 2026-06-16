import 'package:etherly/models/device.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:etherly/widgets/marquee_text.dart';
import 'package:etherly/widgets/music_app_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// A card item widget representing a song with artwork and a share/search button.
class SongCardItem extends StatelessWidget {
  const SongCardItem({
    super.key,
    required this.songName,
    required this.artistName,
    required this.artUrl,
    required this.onTap,
    required this.onShare,
    required this.screenType,
  });

  final String songName;
  final String artistName;
  final String artUrl;
  final VoidCallback onTap;
  final VoidCallback onShare;
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
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () async {
                      final selectedApp = await showDialog<String>(
                        context: context,
                        builder: (context) => const MusicAppPicker(),
                      );
                      if (selectedApp != null) {
                        onShare();
                        final songQuery = '$artistName - $songName';
                        final query = Uri.encodeComponent(songQuery);
                        final uris = {
                          'youtube': Uri.parse('vnd.youtube://results?search_query=$query'),
                          'ytmusic': Uri.parse('https://music.youtube.com/search?q=$query'),
                          'spotify': Uri.parse('spotify:search:$query'),
                          'apple_music': Uri.parse('https://music.apple.com/search?term=$query'),
                          'tidal': Uri.parse('tidal://search/$query'),
                          'soundcloud': Uri.parse('soundcloud://search?q=$query'),
                          'amazon': Uri.parse('https://music.amazon.com/search/$query'),
                          'internet_search': Uri.parse('https://www.google.com/search?q=$query'),
                        };

                        final uri = uris[selectedApp];
                        if (uri == null) return;

                        bool launched = false;
                        try {
                          launched = await launchUrl(
                            uri,
                            mode: selectedApp == 'internet_search'
                                ? LaunchMode.platformDefault
                                : LaunchMode.externalNonBrowserApplication,
                          );
                        } catch (_) {}

                        if (!launched && context.mounted) {
                          final fallbackUri = selectedApp == 'youtube'
                              ? Uri.parse('https://www.youtube.com/results?search_query=$query')
                              : (selectedApp == 'internet_search' ? uri : null);

                          if (fallbackUri != null) {
                            try {
                              await launchUrl(fallbackUri, mode: LaunchMode.platformDefault);
                            } catch (_) {}
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
