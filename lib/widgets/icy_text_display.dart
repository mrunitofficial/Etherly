import 'package:etherly/services/theme_data.dart';
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

  const IcyTextDisplay({super.key, this.style, this.centerWhenFits = true});

  Future<void> _searchSong(
    BuildContext context,
    AudioPlayerService service,
    String songName,
  ) async {
    final prefs = service.prefs;
    String? selectedApp = prefs.getString('favoriteMusicApp');
    final wasAlwaysAsk = selectedApp == 'always_ask' || selectedApp == null;

    // Validation: Trigger picker if selected app is uninstalled
    if (!wasAlwaysAsk && selectedApp != 'internet_search') {
      final availableApps = await MusicAppService().getAvailableApps();
      if (!availableApps.any((app) => app['id'] == selectedApp)) {
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

      if (selectedApp == null) return; // User cancelled
      if (!wasAlwaysAsk) {
        await prefs.setString('favoriteMusicApp', selectedApp);
      }
    }

    final query = Uri.encodeComponent(songName);
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
      // Fallback for youtube or general failure
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

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild this root if casting state changes
    final isCasting = context.select<AudioPlayerService, bool>(
      (s) => s.isCasting,
    );
    if (isCasting) return const SizedBox.shrink();

    final service = context.read<AudioPlayerService>();
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;

    return ValueListenableBuilder(
      valueListenable: service.icyState,
      builder: (context, icy, _) {
        final String? text = icy.loading
            ? (loc?.translate('playerLoadingSong') ?? 'Loading song...')
            : (icy.title?.isNotEmpty == true ? icy.title! : null);

        if (text == null) return const SizedBox.shrink();

        final bool isSong = !icy.loading && icy.title?.isNotEmpty == true;

        final padding = EdgeInsets.only(
          left: centerWhenFits ? spacing.small : 0,
          right: spacing.small,
        );

        Widget content = Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: const StadiumBorder(),
          child: InkWell(
            onTap: isSong
                ? () {
                    HapticFeedback.lightImpact();
                    _searchSong(context, service, text);
                  }
                : null,
            onLongPress: isSong ? () => _copyToClipboard(context, text) : null,
            borderRadius: shapes.extraLarge,
            child: Padding(
              padding: padding,
              child: MarqueeText(
                text: text,
                style: style,
                centerWhenFits: centerWhenFits,
              ),
            ),
          ),
        );

        if (centerWhenFits) {
          return Align(
            alignment: Alignment.center,
            child: content,
          );
        }

        return content;
      },
    );
  }
}
