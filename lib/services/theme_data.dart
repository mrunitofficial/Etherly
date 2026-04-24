import 'package:flutter/material.dart';

/// Global ValueNotifier for ThemeMode, allowing deep widgets to change the theme
/// and trigger a rebuild of the main application widget.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<bool> dynamicColorNotifier = ValueNotifier(false);
const brandColor = Colors.blue;

class AppTheme {
  static ThemeData getLight(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainer,
      appBarTheme: const AppBarTheme(toolbarHeight: 80, titleSpacing: 0.0),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
      ),
      dialogTheme: const DialogThemeData(
        constraints: BoxConstraints(minWidth: 320, maxWidth: 320),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainer,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        shape: CircleBorder(),
      ),
    );
  }

  static ThemeData getDark(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainer,
      appBarTheme: const AppBarTheme(toolbarHeight: 80, titleSpacing: 0.0),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
      ),
      dialogTheme: const DialogThemeData(
        constraints: BoxConstraints(minWidth: 320, maxWidth: 320),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainer,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        shape: CircleBorder(),
      ),
    );
  }
}
