import 'package:material_ui/material_ui.dart';

/// Global ValueNotifier for ThemeMode, allowing deep widgets to change the theme
/// and trigger a rebuild of the main application widget.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

/// Global ValueNotifier for toggling dynamic material system colors.
final ValueNotifier<bool> dynamicColorNotifier = ValueNotifier(false);

/// Global ValueNotifier for managing active language locale settings.
final ValueNotifier<String> languageNotifier = ValueNotifier('system');

/// Primary brand color for seed fallback color scheme generation.
const brandColor = Colors.blue;

/// Theme Data configuration for Etherly application.
class AppTheme {
  static final _shapes = Shapes();
  static final _spacing = Spacing();
  static final _speed = Speed();
  static final _sizes = Sizes();

  /// Generates light [ThemeData] from custom [colorScheme].
  static ThemeData getLight(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      extensions: [_shapes, _spacing, _speed, _sizes],
      scaffoldBackgroundColor: colorScheme.surfaceContainer,
      appBarTheme: const AppBarTheme(toolbarHeight: 80, titleSpacing: 0.0),
      tooltipTheme: TooltipThemeData(waitDuration: _speed.long1),
      dialogTheme: const DialogThemeData(
        constraints: BoxConstraints(minWidth: 280, maxWidth: 560),
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

  /// Generates dark [ThemeData] from custom [colorScheme].
  static ThemeData getDark(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      extensions: [_shapes, _spacing, _speed, _sizes],
      scaffoldBackgroundColor: colorScheme.surfaceContainer,
      appBarTheme: const AppBarTheme(toolbarHeight: 80, titleSpacing: 0.0),
      tooltipTheme: TooltipThemeData(waitDuration: _speed.long1),
      dialogTheme: const DialogThemeData(
        constraints: BoxConstraints(minWidth: 280, maxWidth: 560),
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

/// Material 3 Spacing tokens (until added officially to Flutter SDK)
class Spacing extends ThemeExtension<Spacing> {
  /// Extra extra small spacing (2.0 dp).
  final double extraExtraSmall = 2.0;

  /// Extra small spacing (4.0 dp).
  final double extraSmall = 4.0;

  /// Small spacing (8.0 dp).
  final double small = 8.0;

  /// Medium spacing (16.0 dp).
  final double medium = 16.0;

  /// Large spacing (24.0 dp).
  final double large = 24.0;

  /// Extra large spacing (32.0 dp).
  final double extraLarge = 32.0;

  @override
  Spacing copyWith() => this;

  @override
  Spacing lerp(ThemeExtension<Spacing>? other, double t) => this;
}

/// Material 3 Shape tokens (until added officially to Flutter SDK)
class Shapes extends ThemeExtension<Shapes> {
  /// Extra small border radius (4 dp).
  final BorderRadius extraSmall = BorderRadius.circular(4);

  /// Small border radius (8 dp).
  final BorderRadius small = BorderRadius.circular(8);

  /// Medium border radius (12 dp).
  final BorderRadius medium = BorderRadius.circular(12);

  /// Large border radius (16 dp).
  final BorderRadius large = BorderRadius.circular(16);

  /// Large increased border radius (20 dp).
  final BorderRadius largeIncreased = BorderRadius.circular(20);

  /// Extra large border radius (28 dp).
  final BorderRadius extraLarge = BorderRadius.circular(28);

  /// Extra large increased border radius (32 dp).
  final BorderRadius extraLargeIncreased = BorderRadius.circular(32);

  /// Extra extra large border radius (48 dp).
  final BorderRadius extraExtraLarge = BorderRadius.circular(48);

  @override
  Shapes copyWith() => this;

  @override
  Shapes lerp(ThemeExtension<Shapes>? other, double t) => this;
}

/// Material 3 Speed tokens (until added officially to Flutter SDK)
class Speed extends ThemeExtension<Speed> {
  /// Short 1 duration (50ms).
  final Duration short1 = const Duration(milliseconds: 50);

  /// Short 2 duration (100ms).
  final Duration short2 = const Duration(milliseconds: 100);

  /// Short 3 duration (150ms).
  final Duration short3 = const Duration(milliseconds: 150);

  /// Short 4 duration (200ms).
  final Duration short4 = const Duration(milliseconds: 200);

  /// Medium 1 duration (250ms).
  final Duration medium1 = const Duration(milliseconds: 250);

  /// Medium 2 duration (300ms).
  final Duration medium2 = const Duration(milliseconds: 300);

  /// Medium 3 duration (350ms).
  final Duration medium3 = const Duration(milliseconds: 350);

  /// Medium 4 duration (400ms).
  final Duration medium4 = const Duration(milliseconds: 400);

  /// Long 1 duration (450ms).
  final Duration long1 = const Duration(milliseconds: 450);

  /// Long 2 duration (500ms).
  final Duration long2 = const Duration(milliseconds: 500);

  /// Long 3 duration (550ms).
  final Duration long3 = const Duration(milliseconds: 550);

  /// Long 4 duration (600ms).
  final Duration long4 = const Duration(milliseconds: 600);

  /// Extra long 1 duration (700ms).
  final Duration extraLong1 = const Duration(milliseconds: 700);

  /// Extra long 2 duration (800ms).
  final Duration extraLong2 = const Duration(milliseconds: 800);

  /// Extra long 3 duration (900ms).
  final Duration extraLong3 = const Duration(milliseconds: 900);

  /// Extra long 4 duration (1000ms).
  final Duration extraLong4 = const Duration(milliseconds: 1000);

  @override
  Speed copyWith() => this;

  @override
  Speed lerp(ThemeExtension<Speed>? other, double t) => this;
}

/// Material 3 Size tokens (until added officially to Flutter SDK)
class Sizes extends ThemeExtension<Sizes> {
  /// Extra small size token (16 dp).
  final double extraSmall = 16.0;

  /// Small size token (40 dp).
  final double small = 40.0;

  /// Normal size token (56 dp).
  final double normal = 56.0;

  /// Medium size token (80 dp).
  final double medium = 80.0;

  /// Large size token (96 dp).
  final double large = 96.0;

  /// Large increased size token (120 dp).
  final double largeIncreased = 120.0;

  /// Extra large size token (136 dp).
  final double extraLarge = 136.0;

  /// Extra large increased size token (160 dp).
  final double extraLargeIncreased = 160.0;

  @override
  Sizes copyWith() => this;

  @override
  Sizes lerp(ThemeExtension<Sizes>? other, double t) => this;
}
