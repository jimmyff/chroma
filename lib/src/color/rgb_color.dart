part of color;

class RgbColor extends Color with NotHslColor, NotHsvColor, CssColor {
  double get red => _v.x * 255;
  set red(double value) => _v.x = _bounds(value, 0, 255) / 255;
  double get green => _v.y * 255;
  set green(double value) => _v.y = _bounds(value, 0, 255) / 255;
  double get blue => _v.z * 255;
  set blue(double value) => _v.z = _bounds(value, 0, 255) / 255;
  double get alpha => _v.w * 255;
  set alpha(double value) => _v.w = _bounds(value, 0, 255) / 255;
  double get alphaAsFraction => _v.w;
  double get alphaAsPercent => _v.w * 100;

  RgbColor(double red, double green, double blue, [double alpha = 255.0]) {
    _log.finest('Creating RGB ($red, $green, $blue, $alpha)');
    _v.setValues(red / 255.0, green / 255.0, blue / 255.0, alpha / 255.0);
  }

  RgbColor.fromInts(int red, int green, int blue, [int alpha = 255]) {
    _log.finest('Creating RGB ($red, $green, $blue, $alpha)');
    v.Colors.fromRgba(red, green, blue, alpha, _v);
  }
  RgbColor.fromHex(String value) {
    v.Colors.fromHexString(value, _v);
  }
  RgbColor.fromVector(v.Vector4 v) {
    _log.finest('Creating RGB from V ($v)');
    _v.setFrom(v);
  }

  @override
  HslColor toHsl() {
    final hsl = _v.clone();
    v.Colors.rgbToHsl(_v, hsl);
    return new HslColor.fromVector(hsl);
  }

  @override
  HsvColor toHsv() {
    final hsv = _v.clone();
    v.Colors.rgbToHsv(_v, hsv);
    return new HsvColor.fromVector(hsv);
  }

  @override
  String toHex({bool hash = true, bool alpha = false, bool short = false}) =>
      '${hash ? '#' : ''}${v.Colors.toHexString(_v, alpha: alpha, short: short)}';

  @override
  String toString() => 'RgbColor($red, $green, $blue, $alpha)';

  @override
  String toCss() => 'rgba($red, $green, $blue, $alphaAsFraction)';

  RgbColor operator +(RgbColor c) {
    final vec = _v.clone()..add(c.vector4);
    return RgbColor.fromVector(vec);
  }
}
