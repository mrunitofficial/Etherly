import 'package:etherly/services/theme_data.dart';
import 'package:flutter/material.dart';

/// The header widget for screens, displaying a title and the optional segmented button.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.actions});

  final String title;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<Spacing>()!;
    final sizes = Theme.of(context).extension<Sizes>()!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.medium,
        spacing.medium + spacing.small,
        spacing.medium,
        spacing.small,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: sizes.normal),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            ?actions,
          ],
        ),
      ),
    );
  }
}
