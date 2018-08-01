part of color;

class HslColor extends Color with NotRgbColor, NotHsvColor, CssColor {
  double get hue => _v.x * 360;
  set hue(double value) => _v.x = value / 360 % 1;
  double get saturation => _v.y * 100;
  set saturation(double value) => _v.y = _bounds(value, 0, 100) / 100;
  double get lightness => _v.z * 100;
  set lightness(double value) => _v.z = _bounds(value, 0, 100) / 100;
  double get alpha => _v.w * 100;
  set alpha(double value) => _v.w = _bounds(value, 0, 100) / 100;

  HslColor(double hue, double saturation, double lightness,
      [double alpha = 100.0]) {
    _log.finest('Creating HSL ($hue, $saturation, $lightness, $alpha)');
    _v.setValues(hue / 360, saturation / 100, lightness / 100, alpha / 100);
  }

  HslColor.fromVector(v.Vector4 v) {
    _log.finest('Creating HSL from V ($v)');
    _v.setFrom(v);
  }

  @override
  RgbColor toRgb() {
    final rgbv = _v.clone();
    v.Colors.hslToRgb(_v, rgbv);
    return new RgbColor.fromVector(rgbv);
  }

  @override
  String toString() => 'HslColor($hue, $saturation, $lightness, $alpha)';

  @override
  String toCss() => 'hsla($hue, $saturation%, $lightness%, $alpha%)';
}
