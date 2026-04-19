import 'package:flutter/widgets.dart';

enum ScreenType {
  // Device / screen types
  smallScreenHorizontal,
  smallScreenVertical,
  tablet,
  desktop;

  bool get isLargeFormat =>
      this == ScreenType.tablet || this == ScreenType.desktop;

  // Returns the screen type based on the current context like dpi, screen size and orientation.
  static ScreenType fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    if (size.height < 650) {
      if (orientation == Orientation.landscape) {
        return ScreenType.smallScreenHorizontal;
      }
      return ScreenType.smallScreenVertical;
    }

    if (size.width >= 1400) {
      return ScreenType.desktop;
    }

    if (size.width >= 800) {
      return ScreenType.tablet;
    }

    if (orientation == Orientation.landscape) {
      return ScreenType.smallScreenHorizontal;
    }

    return ScreenType.smallScreenVertical;
  }
}
