import 'package:flutter/material.dart';
import '../services/music_app_service.dart';
import '../localization/app_localizations.dart';

class MusicAppPicker extends StatefulWidget {
  const MusicAppPicker({super.key});

  @override
  State<MusicAppPicker> createState() => _MusicAppPickerState();
}

class _MusicAppPickerState extends State<MusicAppPicker> {
  final MusicAppService _musicAppService = MusicAppService();
  bool _isLoading = true;
  List<Map<String, String>> _availableOptions = [];

  @override
  void initState() {
    super.initState();
    _checkAvailableApps();
  }

  Future<void> _checkAvailableApps() async {
    final apps = await _musicAppService.getAvailableApps();
    if (mounted) {
      setState(() {
        _availableOptions = apps;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        loc?.translate('playerPickMusicApp') ?? 'Pick a music app',
        textAlign: TextAlign.center,
      ),
      content: _isLoading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_availableOptions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        loc?.translate('playerNoMusicAppsInstalled') ??
                            'No music apps installed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ..._availableOptions.map((option) {
                      String getAppLabel(String id, String defaultName) {
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
                        return (key != null ? loc?.translate(key) : null) ??
                            defaultName;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(option['id']);
                            },
                            child: Text(
                              getAppLabel(option['id']!, option['name']!),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  // OR divider
                  Center(
                    child: Text(
                      loc?.translate('sleepTimerOr') ?? 'or',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Search Internet Button
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop('internet_search');
                        },
                        child: Text(
                          loc?.translate('playerSearchInternet') ??
                              'Search internet',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.translate('close') ?? 'Close'),
        ),
      ],
    );
  }
}
