library color;

import 'package:logging/logging.dart';

part '_mixins.dart';

part 'rgb_color.dart';
part 'hsl_color.dart';
part 'hsv_color.dart';

final Logger _log = new Logger('chroma.color');

abstract class Color32 {
  final ColorSpace colorSpace;
  final int value;
  const Color32(int value)
      : value = value & 0xFFFFFFFF,
        colorSpace = const SRgbColorSpace();
}

class SRgbColor extends Color32 {
  const SRgbColor(int value)
      : value = value & 0xFFFFFFFF,
        colorSpace = const SRgbColorSpace();

  const SRgbColor.fromARGB(int a, int r, int g, int b)
      : value = (((a & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) &
            0xFFFFFFFF;

  const SRgbColor.fromRGB(int r, int g, int b)
      : value = (((r & 0xff) << 16) | ((g & 0xff) << 8) | ((b & 0xff) << 0)) &
            0xFFFFFFFF;

  int get alpha => (0xff000000 & value) >> 24;

  double get opacity => alpha / 0xFF;

  int get red => (0x00ff0000 & value) >> 16;

  int get green => (0x0000ff00 & value) >> 8;

  int get blue => (0x000000ff & value) >> 0;

  @override
  String toString() =>
      'SRgbColor(0x${value.toRadixString(16).padLeft(8, '0')})';

  String toHexadecimalString(
          {bool hash = true, bool alpha = false, bool short = false}) =>
      '${hash ? '#' : ''}${value.toRadixString(16).padLeft(8, '0')}';

  // num _bounds(num v, num min, num max) => v > max ? max : v < min ? min : v;

  // static Color lerp(Color a, Color b, double t) {
  //   assert(t != null);
  //   if (a == null && b == null) return null;
  //   if (a == null) return _scaleAlpha(b, t);
  //   if (b == null) return _scaleAlpha(a, 1.0 - t);
  //   return new Color.fromARGB(
  //     lerpDouble(a.alpha, b.alpha, t).toInt().clamp(0, 255),
  //     lerpDouble(a.red, b.red, t).toInt().clamp(0, 255),
  //     lerpDouble(a.green, b.green, t).toInt().clamp(0, 255),
  //     lerpDouble(a.blue, b.blue, t).toInt().clamp(0, 255),
  //   );
  // }
}
