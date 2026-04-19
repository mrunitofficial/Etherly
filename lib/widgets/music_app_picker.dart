import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

/// A dialog widget for picking a preferred music app.
class MusicAppPicker extends StatefulWidget {
  final String? initialSelection;
  
  const MusicAppPicker({super.key, this.initialSelection});

  @override
  State<MusicAppPicker> createState() => _MusicAppPickerState();
}

class _MusicAppPickerState extends State<MusicAppPicker> {
  String? _selectedApp;

  @override
  void initState() {
    super.initState();
    _selectedApp = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    final List<Map<String, String>> options = [
      {'id': 'youtube', 'name': 'YouTube'},
      {'id': 'ytmusic', 'name': 'YouTube Music'},
      {'id': 'spotify', 'name': 'Spotify'},
    ];

    return AlertDialog(
      title: Center(
        child: Text(
          loc?.translate('musicAppPickerTitle') ?? 'Choose Music App',
          textAlign: TextAlign.center,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return RadioListTile<String>(
              title: Text(option['name']!),
              value: option['id']!,
              groupValue: _selectedApp,
              activeColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedApp = value;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.translate('cancel') ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: _selectedApp == null
              ? null
              : () {
                  Navigator.of(context).pop(_selectedApp);
                },
          child: Text(loc?.translate('ok') ?? 'OK'),
        ),
      ],
    );
  }
}
