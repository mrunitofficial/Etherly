import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

/// A dialog widget for picking a preferred music app.
class MusicAppPicker extends StatelessWidget {
  final String? initialSelection;
  
  const MusicAppPicker({super.key, this.initialSelection});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    final List<Map<String, String>> options = [
      {'id': 'youtube', 'name': 'YouTube'},
      {'id': 'ytmusic', 'name': 'YouTube Music'},
      {'id': 'spotify', 'name': 'Spotify'},
    ];

    return AlertDialog(
      title: Center(
        child: Text(
          loc?.translate('playerPickMusicApp') ?? 'Choose music app',
          textAlign: TextAlign.center,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.translate('close') ?? 'Close'),
        ),
      ],
    );
  }
}
