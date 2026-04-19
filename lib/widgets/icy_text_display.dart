import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/radio_player_service.dart';
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
    final wasAlwaysAsk = selectedApp == 'always_ask';

    if (selectedApp == null || wasAlwaysAsk) {
      selectedApp = await showDialog<String>(
        context: context,
        builder: (context) =>
            MusicAppPicker(initialSelection: wasAlwaysAsk ? null : selectedApp),
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
    }

    if (uri != null) {
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
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
              mode: LaunchMode.externalNonBrowserApplication,
            );
          } catch (_) {}
        }

        if (!launched && context.mounted) {
          final loc = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc?.translate('musicAppNotInstalled') ??
                    'Selected app is not installed or unavailable.',
              ),
              action: SnackBarAction(
                label: loc?.translate('change') ?? 'Change',
                onPressed: () {
                  prefs.remove('favoriteMusicApp');
                  _searchSong(context, service, songName);
                },
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Consumer<AudioPlayerService>(
      builder: (context, service, _) {
        if (service.isCasting) return const SizedBox.shrink();

        final icy = service.icyService;
        final text = icy.isLoading
            ? (loc?.translate('playerLoadingSong') ?? 'Loading song...')
            : (icy.text?.isNotEmpty == true ? icy.text! : null);

        if (text == null) return const SizedBox.shrink();

        final isSong = !icy.isLoading && icy.text?.isNotEmpty == true;

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isSong ? () => _searchSong(context, service, text) : null,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
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
        );
      },
    );
  }
}
