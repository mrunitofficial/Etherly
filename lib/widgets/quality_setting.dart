import 'package:flutter/material.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/localization/app_localizations.dart';
import '../services/theme_data.dart';

/// A dialog widget for selecting the streaming quality of a radio station.
class QualitySetting extends StatelessWidget {
  final Station? station;
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
        'enabled': station != null && station!.streamMp3.isNotEmpty,
      },
      {
        'key': 'aac',
        'label':
            loc?.translate('settingsStreamingQualityHighest') ??
            'Highest (AAC)',
        'enabled': station != null && station!.streamAac.isNotEmpty,
      },
    ];
    final spacing = Theme.of(context).extension<Spacing>()!;

    return AlertDialog(
      scrollable: true,
      title: Text(
        loc?.translate('playerStreamQuality') ?? 'Stream Quality',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...options.map((opt) {
            final isSelected = selectedQuality == opt['key'];
            final isEnabled = opt['enabled'] as bool;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
              child: isSelected
                  ? FilledButton(
                      onPressed: isEnabled
                          ? () => onQualitySelected(opt['key'] as String)
                          : null,
                      child: Text(
                        opt['label'] as String,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : FilledButton.tonal(
                      onPressed: isEnabled
                          ? () => onQualitySelected(opt['key'] as String)
                          : null,
                      child: Text(
                        opt['label'] as String,
                        textAlign: TextAlign.center,
                      ),
                    ),
            );
          }),
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
}
