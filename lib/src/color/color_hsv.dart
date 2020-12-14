import 'dart:math' as math;
import 'color_rgb.dart';

/// Same as HSB, Cylindrical geometries with hue, their angular dimension,
/// starting at the red primary at 0°, passing through the green primary
/// at 120° and the blue primary at 240°, and then wrapping back to red at 360°
class ColorHsv extends ColorRgb {
  /// Creates an HSV color
  factory ColorHsv(double hue, double saturation, double value,
      [double alpha = 1.0]) {
    final chroma = saturation * value;
    final secondary = chroma * (1.0 - (((hue / 60.0) % 2.0) - 1.0).abs());
    final match = value - chroma;

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

    return ColorHsv._(hue, saturation, value, (red + match).clamp(0.0, 1.0),
        (green + match).clamp(0.0, 1.0), (blue + match).clamp(0.0, 1.0), alpha);
  }

  const ColorHsv._(this.hue, this.saturation, this.value, double red,
      double green, double blue, double alpha)
      : assert(hue >= 0 && hue < 360),
        assert(saturation >= 0 && saturation <= 1),
        assert(value >= 0 && value <= 1),
        super(red, green, blue, alpha);

  /// Creates an HSV color from red, green, blue components
  factory ColorHsv.fromRgb(double red, double green, double blue,
      [double alpha = 1.0]) {
    final max = math.max(red, math.max(green, blue));
    final min = math.min(red, math.min(green, blue));
    final delta = max - min;

    final hue = ColorRgb.getHue(red, green, blue, max, delta);
    final saturation = max == 0.0 ? 0.0 : delta / max;

    return ColorHsv._(hue, saturation, max, red, green, blue, alpha);
  }

  /// Angular position the colorspace coordinate diagram in degrees from 0° to 360°
  final double hue;

  /// Saturation of the color
  final double saturation;

  /// Brightness
  final double value;

  @override
  ColorHsv toHsv() {
    return this;
  }

  /// Get a complementary color with hue shifted by -120°
  @override
  ColorHsv get complementary =>
      ColorHsv((hue - 120) % 360, saturation, value, alpha);

  /// Get a similar color
  @override
  List<ColorHsv> get monochromatic => <ColorHsv>[
        ColorHsv(
            hue,
            (saturation > 0.5 ? saturation - 0.2 : saturation + 0.2)
                .clamp(0, 1),
            (value > 0.5 ? value - 0.1 : value + 0.1).clamp(0, 1)),
        ColorHsv(
            hue,
            (saturation > 0.5 ? saturation - 0.4 : saturation + 0.4)
                .clamp(0, 1),
            (value > 0.5 ? value - 0.2 : value + 0.2).clamp(0, 1)),
        ColorHsv(
            hue,
            (saturation > 0.5 ? saturation - 0.15 : saturation + 0.15)
                .clamp(0, 1),
            (value > 0.5 ? value - 0.05 : value + 0.05).clamp(0, 1))
      ];

  /// Get two complementary colors with hue shifted by -120°
  @override
  List<ColorHsv> get splitcomplementary => <ColorHsv>[
        ColorHsv((hue - 150) % 360, saturation, value, alpha),
        ColorHsv((hue - 180) % 360, saturation, value, alpha),
      ];

  @override
  List<ColorHsv> get triadic => <ColorHsv>[
        ColorHsv((hue + 80) % 360, saturation, value, alpha),
        ColorHsv((hue - 120) % 360, saturation, value, alpha),
      ];

  @override
  List<ColorHsv> get tetradic => <ColorHsv>[
        ColorHsv((hue + 120) % 360, saturation, value, alpha),
        ColorHsv((hue - 150) % 360, saturation, value, alpha),
        ColorHsv((hue + 60) % 360, saturation, value, alpha),
      ];

  @override
  List<ColorHsv> get analagous => <ColorHsv>[
        ColorHsv((hue + 30) % 360, saturation, value, alpha),
        ColorHsv((hue - 20) % 360, saturation, value, alpha),
      ];

  @override
  String toString() => '$runtimeType($hue, $saturation, $value, $alpha)';
}
