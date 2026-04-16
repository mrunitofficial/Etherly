enum ScreenType {
  smallScreenHorizontal,
  smallScreenVertical,
  tablet,
  desktop;

  bool get isLargeFormat => this == ScreenType.tablet || this == ScreenType.desktop;
}
