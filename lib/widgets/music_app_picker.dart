import 'package:flutter/material.dart';
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
    final spacing = Theme.of(context).extension<Spacing>()!;

    return AlertDialog(
      scrollable: true,
      title: Text(
        loc?.translate('playerPickMusicApp') ?? 'Pick a music app',
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
                loc?.translate('sleepTimerOr') ?? 'or',
                style: Theme.of(context).textTheme.titleLarge,
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
                loc?.translate('playerSearchInternet') ?? 'Search internet',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.translate('close') ?? 'Close'),
        ),
      ],
    );
  }

  String _getAppLabel(String id, String defaultName, AppLocalizations? loc) {
    final keyMap = {
      'youtube': 'settingsMusicAppYoutube',
      'ytmusic': 'settingsMusicAppYtMusic',
      'spotify': 'settingsMusicAppSpotify',
      'apple_music': 'settingsMusicAppAppleMusic',
      'tidal': 'settingsMusicAppTidal',
      'soundcloud': 'settingsMusicAppSoundcloud',
      'amazon': 'settingsMusicAppAmazon',
    };
    final key = keyMap[id];
    return (key != null ? loc?.translate(key) : null) ?? defaultName;
  }
}
