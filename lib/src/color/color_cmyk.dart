import 'dart:math' as math;
import 'color_rgb.dart';

/// Represents an CMYK color
class ColorCmyk extends ColorRgb {
  /// Creates a CMYK color
  const ColorCmyk(this.cyan, this.magenta, this.yellow, this.black,
      [double a = 1.0])
      : super((1.0 - cyan) * (1.0 - black), (1.0 - magenta) * (1.0 - black),
            (1.0 - yellow) * (1.0 - black), a);

  /// Create a CMYK color from red ,green and blue components
  const ColorCmyk.fromRgb(double r, double g, double b, [double a = 1.0])
      : black = 1.0 - r > g
            ? r
            : g > b
                ? r > g
                    ? r
                    : g
                : b,
        cyan = (1.0 -
                r -
                (1.0 - r > g
                    ? r
                    : g > b
                        ? r > g
                            ? r
                            : g
                        : b)) /
            (1.0 -
                (1.0 - r > g
                    ? r
                    : g > b
                        ? r > g
                            ? r
                            : g
                        : b)),
        magenta = (1.0 -
                g -
                (1.0 - r > g
                    ? r
                    : g > b
                        ? r > g
                            ? r
                            : g
                        : b)) /
            (1.0 -
                (1.0 - r > g
                    ? r
                    : g > b
                        ? r > g
                            ? r
                            : g
                        : b)),
        yellow = (1.0 -
                b -
                (1.0 - r > g
                    ? r
                    : g > b
                        ? r > g
                            ? r
                            : g
                        : b)) /
            (1.0 -
                (1.0 - r > g
                    ? r
                    : g > b
                        ? r > g
                            ? r
                            : g
                        : b)),
        super(r, g, b, a);

  /// Cyan component
  final double cyan;

  /// Magenta component
  final double magenta;

  /// Yellow component
  final double yellow;

  /// Black component
  final double black;

  @override
  ColorCmyk toCmyk() {
    return this;
  }

  @override
  String toString() => '$runtimeType($cyan, $magenta, $yellow, $black, $alpha)';
}
