/// Material 3 window size classes, based on available width in logical
/// pixels.
///
/// Breakpoints follow the Material Design 3 guidance:
///
/// | Class        | Width          |
/// |--------------|----------------|
/// | compact      | < 600          |
/// | medium       | 600 - 839      |
/// | expanded     | 840 - 1199     |
/// | large        | 1200 - 1599    |
/// | extraLarge   | >= 1600        |
///
/// Always classify the space that is actually available (for example from
/// `LayoutBuilder` constraints), not the physical screen size.
enum WindowSizeClass {
  /// Phones in portrait and small windows. Usually a single pane.
  compact(0),

  /// Tablets in portrait, foldables unfolded in portrait, medium windows.
  medium(600),

  /// Tablets in landscape, desktops. Usually room for two panes.
  expanded(840),

  /// Large desktop windows.
  large(1200),

  /// Very large desktop windows and external displays.
  extraLarge(1600);

  const WindowSizeClass(this.minWidth);

  /// The smallest width, in logical pixels, that belongs to this class.
  final double minWidth;

  /// Returns the size class for [width] logical pixels.
  ///
  /// Negative, NaN and zero widths are classified as [compact]. Infinite
  /// widths are classified as [extraLarge].
  static WindowSizeClass fromWidth(double width) {
    if (width.isNaN) return compact;
    for (final sizeClass in values.reversed) {
      if (width >= sizeClass.minWidth) return sizeClass;
    }
    return compact;
  }

  /// Whether this class is the same as or wider than [other].
  bool isAtLeast(WindowSizeClass other) => index >= other.index;
}
