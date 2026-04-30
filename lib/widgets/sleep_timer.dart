import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../services/theme_data.dart';

/// A dialog widget for setting a sleep timer.
class SleepTimer extends StatelessWidget {
  final void Function(Duration) onTimerSelected;
  const SleepTimer({super.key, required this.onTimerSelected});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final List<Map<String, dynamic>> options = [
      {
        'label': loc?.translate('sleepTimer5min') ?? '5 minutes',
        'duration': Duration(minutes: 5),
      },
      {
        'label': loc?.translate('sleepTimer10min') ?? '10 minutes',
        'duration': Duration(minutes: 10),
      },
      {
        'label': loc?.translate('sleepTimer20min') ?? '20 minutes',
        'duration': Duration(minutes: 20),
      },
      {
        'label': loc?.translate('sleepTimer30min') ?? '30 minutes',
        'duration': Duration(minutes: 30),
      },
      {
        'label': loc?.translate('sleepTimer60min') ?? '60 minutes',
        'duration': Duration(minutes: 60),
      },
    ];

    final spacing = Theme.of(context).extension<Spacing>()!;

    /// The sleep timer dialog.
    return AlertDialog(
      scrollable: true,
      title: Text(
        loc?.translate('sleepTimerTitle') ?? 'Sleep timer',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...options.map((option) {
            final duration = option['duration'] as Duration;
            final label = option['label'] as String;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
              child: FilledButton.tonal(
                onPressed: () {
                  onTimerSelected(duration);
                  Navigator.of(context).pop();
                },
                child: Text(label, textAlign: TextAlign.center),
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
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
            child: FilledButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null && context.mounted) {
                  final now = DateTime.now();
                  var selected = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  );
                  if (selected.isBefore(now)) {
                    selected = selected.add(const Duration(days: 1));
                  }
                  onTimerSelected(selected.difference(now));
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                loc?.translate('sleepTimerSetExact') ?? 'Set exact time',
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
}
