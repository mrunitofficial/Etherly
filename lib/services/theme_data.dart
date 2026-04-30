import 'package:flutter/material.dart';

/// Global ValueNotifier for ThemeMode, allowing deep widgets to change the theme
/// and trigger a rebuild of the main application widget.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<bool> dynamicColorNotifier = ValueNotifier(false);
const brandColor = Colors.blue;

class ShapeTokens extends ThemeExtension<ShapeTokens> {
  final OutlinedBorder stadium;

  const ShapeTokens({required this.stadium});

  @override
  ShapeTokens copyWith({OutlinedBorder? stadium}) {
    return ShapeTokens(stadium: stadium ?? this.stadium);
  }

  @override
  ShapeTokens lerp(ThemeExtension<ShapeTokens>? other, double t) {
    if (other is! ShapeTokens) return this;
    return ShapeTokens(
      stadium: OutlinedBorder.lerp(stadium, other.stadium, t) as OutlinedBorder,
    );
  }
}

class AppTheme {
  static const _shapeTokens = ShapeTokens(stadium: StadiumBorder());

  static ThemeData getLight(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      extensions: [_shapeTokens],
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
      extensions: [_shapeTokens],
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

