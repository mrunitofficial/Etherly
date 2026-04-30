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
  static final _speed = Speed();

  static ThemeData getLight(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      extensions: [_shapes, _spacing, _speed],
      scaffoldBackgroundColor: colorScheme.surfaceContainer,
      appBarTheme: const AppBarTheme(toolbarHeight: 80, titleSpacing: 0.0),
      tooltipTheme: TooltipThemeData(waitDuration: _speed.long1),
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
      extensions: [_shapes, _spacing, _speed],
      scaffoldBackgroundColor: colorScheme.surfaceContainer,
      appBarTheme: const AppBarTheme(toolbarHeight: 80, titleSpacing: 0.0),
      tooltipTheme: TooltipThemeData(waitDuration: _speed.long1),
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

/// Material 3 Speed tokens (until added officialy to Flutter SDK)
class Speed extends ThemeExtension<Speed> {
  final Duration extraSmall = const Duration(milliseconds: 100);
  final Duration small = const Duration(milliseconds: 200);
  final Duration medium = const Duration(milliseconds: 300);
  final Duration large = const Duration(milliseconds: 400);
  final Duration extraLarge = const Duration(milliseconds: 500);

  final Duration short1 = const Duration(milliseconds: 50);
  final Duration short2 = const Duration(milliseconds: 100);
  final Duration short3 = const Duration(milliseconds: 150);
  final Duration short4 = const Duration(milliseconds: 200);
  final Duration medium1 = const Duration(milliseconds: 250);
  final Duration medium2 = const Duration(milliseconds: 300);
  final Duration medium3 = const Duration(milliseconds: 350);
  final Duration medium4 = const Duration(milliseconds: 400);
  final Duration long1 = const Duration(milliseconds: 450);
  final Duration long2 = const Duration(milliseconds: 500);
  final Duration long3 = const Duration(milliseconds: 550);
  final Duration long4 = const Duration(milliseconds: 600);
  final Duration extraLong1 = const Duration(milliseconds: 700);
  final Duration extraLong2 = const Duration(milliseconds: 800);
  final Duration extraLong3 = const Duration(milliseconds: 900);
  final Duration extraLong4 = const Duration(milliseconds: 1000);

  @override
  Speed copyWith() => this;
  @override
  Speed lerp(ThemeExtension<Speed>? other, double t) => this;

  // Usage: Duration: Theme.of(context).extension<Speed>()!.medium2
}
