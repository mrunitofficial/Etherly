import 'package:material_ui/material_ui.dart';
import '../services/music_app_service.dart';
import '../localization/app_localizations.dart';
import '../services/theme_data.dart';

class MusicAppPicker extends StatefulWidget {
  const MusicAppPicker({super.key});

  @override
  State<MusicAppPicker> createState() => _MusicAppPickerState();
}

class _MusicAppPickerState extends State<MusicAppPicker> {
  final MusicAppService _musicAppService = MusicAppService();
  List<Map<String, String>>? _availableOptions;

  @override
  void initState() {
    super.initState();
    _availableOptions = _musicAppService.cachedAvailableApps;
    _checkAvailableApps();
  }

  Future<void> _checkAvailableApps() async {
    final apps = await _musicAppService.getAvailableApps();
    if (mounted) {
      setState(() {
        _availableOptions = apps;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;

    return AlertDialog(
      scrollable: true,
      title: Text(
        loc?.playerPickMusicApp ?? 'Pick a music app',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_availableOptions?.isNotEmpty ?? false) ...[
            ..._availableOptions!.map((option) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pop(option['id']);
                  },
                  child: Text(
                    _getAppLabel(option['id']!, option['name']!, loc),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
            SizedBox(height: spacing.medium),
            Center(
              child: Text(
                loc?.sleepTimerOr ?? 'or',
                style: theme.textTheme.titleLarge,
              ),
            ),
            SizedBox(height: spacing.medium),
          ],
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop('internet_search');
              },
              child: Text(
                loc?.playerSearchInternet ?? 'Search internet',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.close ?? 'Close'),
        ),
      ],
    );
  }

  String _getAppLabel(String id, String defaultName, AppLocalizations? loc) {
    if (loc != null) {
      switch (id) {
        case 'youtube': return loc.settingsMusicAppYoutube;
        case 'ytmusic': return loc.settingsMusicAppYtMusic;
        case 'spotify': return loc.settingsMusicAppSpotify;
        case 'apple_music': return loc.settingsMusicAppAppleMusic;
        case 'tidal': return loc.settingsMusicAppTidal;
        case 'soundcloud': return loc.settingsMusicAppSoundcloud;
        case 'amazon': return loc.settingsMusicAppAmazon;
      }
    }
    return defaultName;
  }
}
