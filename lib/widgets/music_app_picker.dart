import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';

/// A dialog widget for picking a preferred music app, showing only installed apps.
class MusicAppPicker extends StatefulWidget {
  final String? initialSelection;

  const MusicAppPicker({super.key, this.initialSelection});

  @override
  State<MusicAppPicker> createState() => _MusicAppPickerState();
}

class _MusicAppPickerState extends State<MusicAppPicker> {
  bool _isLoading = true;
  final List<Map<String, String>> _availableOptions = [];

  @override
  void initState() {
    super.initState();
    _checkAvailableApps();
  }

  Future<void> _checkAvailableApps() async {
    final allOptions = [
      {'id': 'youtube', 'name': 'YouTube', 'scheme': 'vnd.youtube://'},
      {
        'id': 'ytmusic',
        'name': 'YouTube Music',
        'scheme': 'https://music.youtube.com',
      },
      {'id': 'spotify', 'name': 'Spotify', 'scheme': 'spotify://'},
      {
        'id': 'apple_music',
        'name': 'Apple Music',
        'scheme': 'https://music.apple.com',
      },
      {'id': 'tidal', 'name': 'Tidal', 'scheme': 'tidal://'},
      {'id': 'soundcloud', 'name': 'SoundCloud', 'scheme': 'soundcloud://'},
      {'id': 'amazon', 'name': 'Amazon Music', 'scheme': 'amznmp3://'},
    ];

    for (final option in allOptions) {
      try {
        final canOpen = await canLaunchUrl(Uri.parse(option['scheme']!));
        if (canOpen) {
          _availableOptions.add({
            'id': option['id']!,
            'name': option['name']!,
          });
        }
      } catch (_) {
        // Ignore errors for specific schemes
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Center(
        child: Text(
          loc?.translate('playerPickMusicApp') ?? 'Choose music app',
          textAlign: TextAlign.center,
        ),
      ),
      content: SizedBox(
        width: 320,
        child:
            _isLoading
                ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                )
                : _availableOptions.isEmpty
                ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        loc?.translate('musicAppNoSupportedApps') ??
                            'No supported music apps found on this device.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
                : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        _availableOptions.map((option) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                  foregroundColor:
                                      Theme.of(
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
                                  option['name']!,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
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
