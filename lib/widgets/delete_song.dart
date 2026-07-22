import 'package:material_ui/material_ui.dart';
import '../localization/app_localizations.dart';

/// A custom confirmation dialog for deleting a single song from history.
class DeleteSongDialog extends StatelessWidget {
  const DeleteSongDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        loc?.historyDeleteItem ?? 'Delete song',
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        loc?.historyDeleteConfirmation ??
            'Are you sure you want to remove this song from your history?',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc?.close ?? 'Close'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(loc?.historyDelete ?? 'Delete'),
        ),
      ],
    );
  }
}
