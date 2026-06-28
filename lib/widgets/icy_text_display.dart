import 'package:etherly/services/theme_data.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/music_app_service.dart';
import 'package:etherly/models/music_app.dart';
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

    await MusicApp(id: selectedApp, name: '').launchSearch(songName);
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
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
            ? (loc?.playerLoadingSong ?? 'Loading song...')
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
          return Align(alignment: Alignment.center, child: content);
        }

        return content;
      },
    );
  }
}
