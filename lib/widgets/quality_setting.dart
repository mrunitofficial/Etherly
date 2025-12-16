import 'package:flutter/material.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/localization/app_localizations.dart';

/// A dialog widget for selecting the streaming quality of a radio station.
class QualitySetting extends StatelessWidget {
  final Station station;
  final String selectedQuality;
  final void Function(String) onQualitySelected;

  const QualitySetting({
    super.key,
    required this.station,
    required this.selectedQuality,
    required this.onQualitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final options = [
      {
        'key': 'mp3',
        'label': loc?.translate('settingsStreamingQualityHigh') ?? 'High (MP3)',
        'enabled': station.streamMP3.isNotEmpty,
      },
      {
        'key': 'aac',
        'label':
            loc?.translate('settingsStreamingQualityHighest') ??
            'Highest (AAC)',
        'enabled': station.streamAAC.isNotEmpty,
      },
    ];

    /// The stream quality selection dialog.
    return AlertDialog(
      /// The title of the dialog.
      title: Center(
        child: Text(
          loc?.translate('playerStreamQuality') ?? 'Stream Quality',
          textAlign: TextAlign.center,
        ),
      ),

      /// The content of the dialog.
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...options.map((opt) {
              final isSelected = selectedQuality == opt['key'];
              final isEnabled = opt['enabled'] as bool;
              final colorScheme = Theme.of(context).colorScheme;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.secondaryContainer,
                      foregroundColor: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isEnabled
                        ? () => onQualitySelected(opt['key'] as String)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                            ),
                          ),
                          Center(
                            child: Text(
                              opt['label'] as String,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),

      /// Close button.
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.translate('close') ?? 'Close'),
        ),
      ],
    );
  }
}
