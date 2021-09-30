import 'dart:math' as math;

import 'color_cmyk.dart';
import 'color_hsl.dart';
import 'color_hsv.dart';

/// Represents an RGB color
class ColorRgb {
  /// Create a color with red, green, blue and alpha components
  /// values between 0 and 1
  const ColorRgb(this.red, this.green, this.blue, [this.alpha = 1.0])
      : assert(red >= 0 && red <= 1),
        assert(green >= 0 && green <= 1),
        assert(blue >= 0 && blue <= 1),
        assert(alpha >= 0 && alpha <= 1);

  /// Return a color with: 0xAARRGGBB
  const ColorRgb.fromIntRGBA(int color)
      : red = (color >> 16 & 0xff) / 255.0,
        green = (color >> 8 & 0xff) / 255.0,
        blue = (color & 0xff) / 255.0,
        alpha = (color >> 24 & 0xff) / 255.0;

  /// Return a color with: 0xAARRGGBB
  const ColorRgb.fromIntARGB(int color)
      : alpha = (color >> 16 & 0xff) / 255.0,
        red = (color >> 8 & 0xff) / 255.0,
        green = (color & 0xff) / 255.0,
        blue = (color >> 24 & 0xff) / 255.0;

  /// Can parse colors in the form:
  /// * #RRGGBBAA
  /// * #RRGGBB
  /// * #RGB
  /// * RRGGBBAA
  /// * RRGGBB
  /// * RGB
  factory ColorRgb.fromHex(String color) {
    if (color.startsWith('#')) {
      color = color.substring(1);
    }

    double red;
    double green;
    double blue;
    var alpha = 1.0;

    if (color.length == 3) {
      red = int.parse(color.substring(0, 1) * 2, radix: 16) / 255;
      green = int.parse(color.substring(1, 2) * 2, radix: 16) / 255;
      blue = int.parse(color.substring(2, 3) * 2, radix: 16) / 255;
      return ColorRgb(red, green, blue, alpha);
    }

    assert(color.length == 3 || color.length == 6 || color.length == 8);

    red = int.parse(color.substring(0, 2), radix: 16) / 255;
    green = int.parse(color.substring(2, 4), radix: 16) / 255;
    blue = int.parse(color.substring(4, 6), radix: 16) / 255;

    if (color.length == 8) {
      alpha = int.parse(color.substring(6, 8), radix: 16) / 255;
    }

    return ColorRgb(red, green, blue, alpha);
  }

  static double? getHue(
      double red, double green, double blue, double max, double delta) {
    double? hue;
    if (max == 0.0) {
      hue = 0.0;
    } else if (max == red) {
      hue = 60.0 * (((green - blue) / delta) % 6);
    } else if (max == green) {
      hue = 60.0 * (((blue - red) / delta) + 2);
    } else if (max == blue) {
      hue = 60.0 * (((red - green) / delta) + 4);
    }

    /// Set hue to 0.0 when red == green == blue.
    hue = hue!.isNaN ? 0.0 : hue;
    return hue;
  }

  /// Load an RGB color from a RYB color
  factory ColorRgb.fromRYB(double red, double yellow, double blue,
      [double alpha = 1.0]) {
    assert(red >= 0 && red <= 1);
    assert(yellow >= 0 && yellow <= 1);
    assert(blue >= 0 && blue <= 1);
    assert(alpha >= 0 && alpha <= 1);

    const magic = <List<double>>[
      <double>[1, 1, 1],
      <double>[1, 1, 0],
      <double>[1, 0, 0],
      <double>[1, 0.5, 0],
      <double>[0.163, 0.373, 0.6],
      <double>[0.0, 0.66, 0.2],
      <double>[0.5, 0.0, 0.5],
      <double>[0.2, 0.094, 0.0]
    ];

    double cubicInt(double t, double A, double B) {
      final weight = t * t * (3 - 2 * t);
      return A + weight * (B - A);
    }

    double getRed(double iR, double iY, double iB) {
      final x0 = cubicInt(iB, magic[0][0], magic[4][0]);
      final x1 = cubicInt(iB, magic[1][0], magic[5][0]);
      final x2 = cubicInt(iB, magic[2][0], magic[6][0]);
      final x3 = cubicInt(iB, magic[3][0], magic[7][0]);
      final y0 = cubicInt(iY, x0, x1);
      final y1 = cubicInt(iY, x2, x3);
      return cubicInt(iR, y0, y1);
    }

    double getGreen(double iR, double iY, double iB) {
      final x0 = cubicInt(iB, magic[0][1], magic[4][1]);
      final x1 = cubicInt(iB, magic[1][1], magic[5][1]);
      final x2 = cubicInt(iB, magic[2][1], magic[6][1]);
      final x3 = cubicInt(iB, magic[3][1], magic[7][1]);
      final y0 = cubicInt(iY, x0, x1);
      final y1 = cubicInt(iY, x2, x3);
      return cubicInt(iR, y0, y1);
    }

    double getBlue(double iR, double iY, double iB) {
      final x0 = cubicInt(iB, magic[0][2], magic[4][2]);
      final x1 = cubicInt(iB, magic[1][2], magic[5][2]);
      final x2 = cubicInt(iB, magic[2][2], magic[6][2]);
      final x3 = cubicInt(iB, magic[3][2], magic[7][2]);
      final y0 = cubicInt(iY, x0, x1);
      final y1 = cubicInt(iY, x2, x3);
      return cubicInt(iR, y0, y1);
    }

    final redValue = getRed(red, yellow, blue);
    final greenValue = getGreen(red, yellow, blue);
    final blueValue = getBlue(red, yellow, blue);
    return ColorRgb(redValue, greenValue, blueValue, alpha);
  }

  /// Opacity
  final double alpha;

  /// Red component
  final double red;

  /// Green component
  final double green;

  /// Blue component
  final double blue;

  /// Get the int32 representation of this color
  int toInt() =>
      ((((alpha * 255.0).round() & 0xff) << 24) |
          (((red * 255.0).round() & 0xff) << 16) |
          (((green * 255.0).round() & 0xff) << 8) |
          (((blue * 255.0).round() & 0xff) << 0)) &
      0xFFFFFFFF;

  /// Get an Hexadecimal representation of this color
  String toHex({bool alpha = true}) {
    final i = toInt();
    final rgb = (i & 0xffffff).toRadixString(16).padLeft(2, '0');
    final a = alpha ? ((i & 0xff000000) >> 24).toRadixString(16) : '';

    return '${(red * 255.0).round().toRadixString(16).padLeft(2, '0')}'
        '${(green * 255.0).round().toRadixString(16).padLeft(2, '0')}'
        '${(blue * 255.0).round().toRadixString(16).padLeft(2, '0')}';

    return '$rgb$a';
  }

  /// Convert this color to CMYK
  ColorCmyk toCmyk() {
    return ColorCmyk.fromRgb(red, green, blue, alpha);
  }

  /// Convert this color to HSV
  ColorHsv toHsv() {
    return ColorHsv.fromRgb(red, green, blue, alpha);
  }

  /// Convert this color to HSL
  ColorHsl toHsl() {
    return ColorHsl.fromRgb(red, green, blue, alpha);
  }

  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4) as double;
  }

  /// Get the luminance
  double get luminance {
    final R = _linearizeColorComponent(red);
    final G = _linearizeColorComponent(green);
    final B = _linearizeColorComponent(blue);
    return 0.2126 * R + 0.7152 * G + 0.0722 * B;
  }

  /// Build a Material Color shade using the given [strength].
  ///
  /// To lighten a color, set the [strength] value to < .5
  /// To darken a color, set the [strength] value to > .5
  ColorRgb shade(double strength) {
    final ds = 1.5 - strength;
    final hsl = toHsl();

    return ColorHsl(
        hsl.hue, hsl.saturation, (hsl.lightness * ds).clamp(0.0, 1.0));
  }

  /// Get a complementary color with hue shifted by -120°
  ColorRgb get complementary => toHsv().complementary;

  /// Get some similar colors
  List<ColorRgb> get monochromatic => toHsv().monochromatic;

  /// Returns a list of complementary colors
  List<ColorRgb> get splitcomplementary => toHsv().splitcomplementary;

  /// Returns a list of tetradic colors
  List<ColorRgb> get tetradic => toHsv().tetradic;

  /// Returns a list of triadic colors
  List<ColorRgb> get triadic => toHsv().triadic;

  /// Returns a list of analagous colors
  List<ColorRgb> get analagous => toHsv().analagous;

  @override
  String toString() => '$runtimeType($red, $green, $blue, $alpha)';
}
