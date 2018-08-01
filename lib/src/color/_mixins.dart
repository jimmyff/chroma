part of color;

abstract class CssColor {
  String toCss();
}

abstract class NotHslColor {
  HslColor toHsl();
}

abstract class NotHsvColor {
  HsvColor toHsv();
}

abstract class NotRgbColor {
  // NotRgbColor fromRgb();
  RgbColor toRgb();
  String toHex({bool hash = true, bool alpha = false, bool short = false}) =>
      toRgb().toHex(hash: hash, alpha: alpha, short: short);

  HsvColor toHsv() => toRgb().toHsv();
  HslColor toHsl() => toRgb().toHsl();
  // NotRgbColor fromHex(String value) => fromHex(value).fromRgb();
}
