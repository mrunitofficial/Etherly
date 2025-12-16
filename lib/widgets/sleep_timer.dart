import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

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

    /// The sleep timer dialog.
    return AlertDialog(
      /// The title of the dialog.
      title: Center(
        child: Text(
          loc?.translate('sleepTimerTitle') ?? 'Sleep timer',
          textAlign: TextAlign.center,
        ),
      ),

      /// The content of the dialog.
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Predefined timer options.
            ...options.map(
              (option) => Padding(
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      onTimerSelected(option['duration']);
                    },
                    child: Text(option['label'], textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),

            /// OR text devider.
            Center(
              child: Text(
                loc?.translate('sleepTimerOr') ?? 'or',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
              ),
            ),

            /// Set exact time button.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        DateTime.now().add(const Duration(minutes: 5)),
                      ),
                    );
                    if (picked != null) {
                      final nowDateTime = DateTime.now();
                      final pickedDateTime = DateTime(
                        nowDateTime.year,
                        nowDateTime.month,
                        nowDateTime.day,
                        picked.hour,
                        picked.minute,
                      );
                      var duration = pickedDateTime.difference(nowDateTime);
                      if (duration.isNegative || duration.inSeconds == 0) {
                        final tomorrow = pickedDateTime.add(
                          const Duration(days: 1),
                        );
                        duration = tomorrow.difference(nowDateTime);
                      }
                      onTimerSelected(duration);
                    }
                  },
                  child: Text(
                    loc?.translate('sleepTimerSetExact') ?? 'Set exact time',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Close button.
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.translate('close') ?? 'Close'),
        ),
      ],
    );
  }
}
