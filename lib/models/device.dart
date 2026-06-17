import 'package:flutter/widgets.dart';

enum ScreenType {
  smallScreenHorizontal,
  smallScreenVertical,
  tablet,
  desktop,
  tv;

  /// Global flag set at startup indicating if the device is a TV.
  static bool isTv = false;

  /// Whether this screen type represents a large form-factor layout.
  bool get isLargeFormat =>
      this == ScreenType.tablet ||
      this == ScreenType.desktop ||
      this == ScreenType.tv;

  /// Resolves the layout screen type based on viewport dimensions and orientation.
  static ScreenType fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    // Tv check, using method channel
    if (isTv) {
      return ScreenType.tv;
    }

    // Small height limit (e.g., phones in landscape or compact portrait displays)
    if (size.height < 650) {
      return orientation == Orientation.landscape
          ? ScreenType.smallScreenHorizontal
          : ScreenType.smallScreenVertical;
    }

    // Desktop breakpoint
    if (size.width >= 1400) {
      return ScreenType.desktop;
    }

    // Tablet breakpoint
    if (size.width >= 800) {
      return ScreenType.tablet;
    }

    // Standard phone in landscape
    if (orientation == Orientation.landscape) {
      return ScreenType.smallScreenHorizontal;
    }

    // Default: Portrait phone
    return ScreenType.smallScreenVertical;
  }
}
