part of color;

class HsvColor extends Color with NotRgbColor, CssColor {
  double get hue => _v.x * 360;
  set hue(double value) => _v.x = value / 360 % 1;
  double get saturation => _v.y * 100;
  set saturation(double value) => _v.y = _bounds(value, 0, 100) / 100;
  double get value => _v.z * 100;
  set value(double value) => _v.z = _bounds(value, 0, 100) / 100;
  double get alpha => _v.w * 100;
  set alpha(double value) => _v.w = _bounds(value, 0, 100) / 100;

  HsvColor(double hue, double saturation, double lightness,
      [double alpha = 100.0]) {
    _log.finest('Creating HSV ($hue, $saturation, $lightness, $alpha)');
    _v.setValues(hue / 360, saturation / 100, lightness / 100, alpha / 100);
  }

  HsvColor.fromVector(v.Vector4 v) {
    _log.finest('Creating HSV from vector ($v)');
    _v.setFrom(v);
  }

  @override
  RgbColor toRgb() {
    final rgbv = _v.clone();
    v.Colors.hsvToRgb(_v, rgbv);
    return new RgbColor.fromVector(rgbv);
  }

  @override
  String toString() => 'HsvColor($hue, $saturation, $value, $alpha)';

  @override
  String toCss() => 'hsva($hue, $saturation%, $value%, $alpha%)';
}
