import 'package:flutter/material.dart';

/// The header widget for screens, displaying a title and the optional segmented button.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.actions});

  final String title;
  final Widget? actions;
  static const double _headerHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _headerHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
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
            if (actions != null) actions!,
          ],
        ),
      ),
    );
  }
}
