import 'package:material_ui/material_ui.dart';
import '../localization/app_localizations.dart';

/// A custom confirmation dialog for clearing history.
class ClearHistoryDialog extends StatelessWidget {
  const ClearHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        loc?.historyClear ?? 'Clear History',
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        loc?.historyClearConfirmation ?? 'Are you sure you want to clear your song history? This action cannot be undone.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc?.close ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(loc?.historyClear ?? 'Clear'),
        ),
      ],
    );
  }
}
