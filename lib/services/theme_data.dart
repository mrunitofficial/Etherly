import 'package:flutter/material.dart';

/// Global ValueNotifier for ThemeMode, allowing deep widgets to change the theme
/// and trigger a rebuild of the main application widget.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<bool> dynamicColorNotifier = ValueNotifier(false);
const brandColor = Colors.blue;

/// Theme Data for Etherly
class AppTheme {
  static final _shapes = Shapes();
  static final _spacing = Spacing();

  static ThemeData getLight(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      extensions: [_shapes, _spacing],
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
      extensions: [_shapes, _spacing],
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

/// Material 3 Spacing tokens (until added officialy to Flutter SDK)
class Spacing extends ThemeExtension<Spacing> {
  final double extraSmall = 4.0;
  final double small = 8.0;
  final double medium = 16.0;
  final double large = 24.0;
  final double extraLarge = 32.0;

  @override
  Spacing copyWith() => this;
  @override
  Spacing lerp(ThemeExtension<Spacing>? other, double t) => this;

  // Usage: padding: EdgeInsets.all(Theme.of(context).extension<Spacing>()!.medium)
}

/// Material 3 Shape tokens (until added officialy to Flutter SDK)
class Shapes extends ThemeExtension<Shapes> {
  final BorderRadius extraSmall = BorderRadius.circular(4);
  final BorderRadius small = BorderRadius.circular(8);
  final BorderRadius medium = BorderRadius.circular(12);
  final BorderRadius large = BorderRadius.circular(16);
  final BorderRadius largeIncreased = BorderRadius.circular(20);
  final BorderRadius extraLarge = BorderRadius.circular(28);
  final BorderRadius extraLargeIncreased = BorderRadius.circular(32);
  final BorderRadius extraExtraLarge = BorderRadius.circular(48);

  @override
  Shapes copyWith() => this;
  @override
  Shapes lerp(ThemeExtension<Shapes>? other, double t) => this;

  // Usage: borderRadius: Theme.of(context).extension<Shapes>()!.largeIncreased
}
