import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/music_app_service.dart';
import 'package:etherly/widgets/marquee_text.dart';
import 'package:etherly/widgets/music_app_picker.dart';

/// A widget that displays the current ICY metadata (song title)
class IcyTextDisplay extends StatelessWidget {
  final TextStyle? style;
  final bool centerWhenFits;
  final EdgeInsetsGeometry? padding;

  const IcyTextDisplay({
    super.key,
    this.style,
    this.centerWhenFits = true,
    this.padding,
  });

  Future<void> _searchSong(
    BuildContext context,
    AudioPlayerService service,
    String songName,
  ) async {
    final prefs = service.prefs;
    String? selectedApp = prefs.getString('favoriteMusicApp');
    final wasAlwaysAsk = selectedApp == 'always_ask' || selectedApp == null;

    // Validation: If an app was selected but is no longer installed, trigger the picker
    if (!wasAlwaysAsk && selectedApp != 'internet_search') {
      final musicAppService = MusicAppService();
      final availableApps = await musicAppService.getAvailableApps();
      if (!availableApps.any((app) => app['id'] == selectedApp)) {
        // App is uninstalled, reset preference and show picker
        await prefs.setString('favoriteMusicApp', 'always_ask');
        selectedApp = null;
      }
    }

    if (selectedApp == null || wasAlwaysAsk) {
      if (!context.mounted) return;
      selectedApp = await showDialog<String>(
        context: context,
        builder: (context) => const MusicAppPicker(),
      );

      if (selectedApp != null) {
        // Only persist if it wasn't already set to "always_ask"
        if (!wasAlwaysAsk) {
          await prefs.setString('favoriteMusicApp', selectedApp);
        }
      } else {
        return; // User cancelled
      }
    }

    Uri? uri;
    final query = Uri.encodeComponent(songName);
    switch (selectedApp) {
      case 'youtube':
        uri = Uri.parse('vnd.youtube://results?search_query=$query');
      case 'ytmusic':
        uri = Uri.parse('https://music.youtube.com/search?q=$query');
      case 'spotify':
        uri = Uri.parse('spotify:search:$query');
      case 'apple_music':
        uri = Uri.parse('https://music.apple.com/search?term=$query');
      case 'tidal':
        uri = Uri.parse('tidal://search/$query');
      case 'soundcloud':
        uri = Uri.parse('soundcloud://search?q=$query');
      case 'amazon':
        uri = Uri.parse('https://music.amazon.com/search/$query');
      case 'internet_search':
        uri = Uri.parse('https://www.google.com/search?q=$query');
    }

    if (uri != null) {
      bool launched = false;
      try {
        // Use platformDefault for internet search to allow browser fallback
        // Use externalNonBrowserApplication for specific apps to ensure we don't just open a browser tab
        launched = await launchUrl(
          uri,
          mode: selectedApp == 'internet_search'
              ? LaunchMode.platformDefault
              : LaunchMode.externalNonBrowserApplication,
        );
      } catch (_) {
        launched = false;
      }

      if (!launched && context.mounted) {
        // Fallback for youtube if vnd.youtube fails
        if (selectedApp == 'youtube') {
          try {
            launched = await launchUrl(
              Uri.parse('https://www.youtube.com/results?search_query=$query'),
              mode: LaunchMode.platformDefault,
            );
          } catch (_) {}
        } else if (selectedApp == 'internet_search') {
          // If even platformDefault failed for internet search (very unlikely), try externalApplication
          try {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Consumer<AudioPlayerService>(
      builder: (context, service, _) {
        if (service.isCasting) return const SizedBox.shrink();

        return ValueListenableBuilder(
          valueListenable: service.icyState,
          builder: (context, icy, _) {
            final text = icy.loading
                ? (loc?.translate('playerLoadingSong') ?? 'Loading song...')
                : (icy.title?.isNotEmpty == true ? icy.title! : null);

            if (text == null) return const SizedBox.shrink();

            final isSong = !icy.loading && icy.title?.isNotEmpty == true;

            return Align(
              alignment: centerWhenFits
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                shape: const StadiumBorder(),
                child: InkWell(
                  onTap: isSong
                      ? () => _searchSong(context, service, text)
                      : null,
                  onLongPress: isSong
                      ? () => _copyToClipboard(context, text)
                      : null,
                  child: Padding(
                    padding:
                        padding ?? const EdgeInsets.symmetric(horizontal: 12.0),
                    child: MarqueeText(
                      text: text,
                      style:
                          style ??
                          theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      centerWhenFits: centerWhenFits,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
