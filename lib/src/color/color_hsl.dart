import 'dart:math' as math;
import 'color_rgb.dart';

/// Represents an HSL color
class ColorHsl extends ColorRgb {
  /// Creates an HSL color
  factory ColorHsl(double hue, double saturation, double lightness,
      [double alpha = 1.0]) {
    final chroma = (1.0 - (2.0 * lightness - 1.0).abs()) * saturation;
    final secondary = chroma * (1.0 - (((hue / 60.0) % 2.0) - 1.0).abs());
    final match = lightness - chroma / 2.0;

    double red;
    double green;
    double blue;
    if (hue < 60.0) {
      red = chroma;
      green = secondary;
      blue = 0.0;
    } else if (hue < 120.0) {
      red = secondary;
      green = chroma;
      blue = 0.0;
    } else if (hue < 180.0) {
      red = 0.0;
      green = chroma;
      blue = secondary;
    } else if (hue < 240.0) {
      red = 0.0;
      green = secondary;
      blue = chroma;
    } else if (hue < 300.0) {
      red = secondary;
      green = 0.0;
      blue = chroma;
    } else {
      red = chroma;
      green = 0.0;
      blue = secondary;
    }
    return ColorHsl._(
        hue,
        saturation,
        lightness,
        alpha,
        (red + match).clamp(0.0, 1.0),
        (green + match).clamp(0.0, 1.0),
        (blue + match).clamp(0.0, 1.0));
  }

  const ColorHsl._(this.hue, this.saturation, this.lightness, double alpha,
      double red, double green, double blue)
      : assert(hue >= 0 && hue < 360),
        assert(saturation >= 0 && saturation <= 1),
        assert(lightness >= 0 && lightness <= 1),
        super(red, green, blue, alpha);

  /// Creates an HSL color from red, green, and blue components
  factory ColorHsl.fromRgb(double red, double green, double blue,
      [double alpha = 1.0]) {
    final max = math.max(red, math.max(green, blue));
    final min = math.min(red, math.min(green, blue));
    final delta = max - min;

    final hue = ColorRgb.getHue(red, green, blue, max, delta);
    final lightness = (max + min) / 2.0;
    // Saturation can exceed 1.0 with rounding errors, so clamp it.
    final double saturation = lightness == 1.0
        ? 0.0
        : (delta / (1.0 - (2.0 * lightness - 1.0).abs())).clamp(0.0, 1.0);
    return ColorHsl._(hue, saturation, lightness, alpha, red, green, blue);
  }

  /// Hue component
  final double hue;

  /// Saturation component
  final double saturation;

  /// Lightness component
  final double lightness;

  @override
  ColorHsl toHsl() {
    return this;
  }

  @override
  String toString() => '$runtimeType($hue, $saturation, $lightness, $alpha)';
}
