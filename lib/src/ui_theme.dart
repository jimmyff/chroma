import 'package:image/image.dart';

import '../color.dart';

double _distanceScore(double v1, double v2, {bool wrapped = false}) =>
    (1 - ((v1 + (wrapped ? 1.0 : 0.0)) - (v2 + (wrapped ? 1.0 : 0.0))).abs());

// double _hueDistanceScore(double v1, double v2, {bool wrapped = false}) =>
//     (1 - ((v1 + (wrapped ? 1.0 : 0.0)) - (v2 + (wrapped ? 1.0 : 0.0))).abs());

class UiTheme {
  final ColorRgb primary;
  final ColorRgb secondary;
  final ColorRgb dark;
  final ColorRgb light;

  UiTheme({
    required this.primary,
    required this.secondary,
    required this.dark,
    required this.light,
  });

  List<String> toHexArray() {
    return [
      primary.toHex(alpha: false),
      secondary.toHex(alpha: false),
      dark.toHex(alpha: false),
      light.toHex(alpha: false),
    ];
  }

  factory UiTheme.fromJpg(List<int> bytes, {bool debug = false}) {
    final image = decodeJpg(bytes);
    return UiTheme._fromImage(image);
  }

  factory UiTheme._fromImage(Image image) {
    const smallSize = 32;
    List<ColorCollectionDebug> debugData = [];

    // reduced size
    final swatch = ScoredColors.fromImage(image);

    return UiTheme._fromDominantColors(swatch);
  }

  factory UiTheme._fromDominantColors(ScoredColors colors) {
    print(colors);
    // dominant
    final doms = colors.colorsWith(
        where: (ColorRgb c, double dominance) =>
            c.toHsl().lightness > 0.1 &&
            c.toHsl().lightness < 0.95 &&
            c.toHsl().saturation > 0.02,
        score: (ColorRgb c, double dominance) =>
            (c.toHsl().lightness < 0.2 || c.toHsl().lightness > 0.6
                ? (c.toHsl().lightness / 10)
                : (1 + _distanceScore(c.toHsl().lightness, 0.45) * 8)) +
            (c.toHsl().saturation < 0.2
                ? (c.toHsl().saturation / 10)
                : (1 + _distanceScore(c.toHsl().saturation, 1) * 3)) +
            (dominance * 5));
    var domColor = makeShade500(doms.keys.first.toHsl());

    print('Primary Colours:');
    doms.forEach((key, value) {
      print('#${key.toHex(alpha: false)} ${value?.toStringAsFixed(2)}');
    });

    final secondaryColors = colors.colorsWith(
        where: (ColorRgb c, double dominance) =>
            c.toHsl().lightness > 0.1 &&
            c.toHsl().lightness < 0.95 &&
            c.toHsl().saturation > 0.02,
        score: (ColorRgb c, double dominance) {
          final hueDelta = c.toHsl().hue > domColor.toHsl().hue
              ? c.toHsl().hue - domColor.toHsl().hue
              : domColor.toHsl().hue - c.toHsl().hue;
          final hueDiff = (hueDelta > 180 ? hueDelta - 180 : hueDelta) / 180;
          return //
              (c.toHsl().lightness < 0.15 || c.toHsl().lightness > 0.6
                      ? (c.toHsl().lightness / 10)
                      : (_distanceScore(c.toHsl().lightness, 0.4) * 8)) +
                  (c.toHsl().saturation < 0.09
                      ? (c.toHsl().saturation / 10)
                      : (_distanceScore(c.toHsl().saturation, 1) * 3)) +
                  (dominance * 1) +
                  (hueDiff * 12)
              //
              ;
        }
        // +
        // (dominance / 10))
        );
    print('Secondary Colours:');
    secondaryColors.forEach((key, value) {
      print('#${key.toHex(alpha: false)} ${value?.toStringAsFixed(2)}');
    });
    var secondaryColor = secondaryColors.keys.first.toHsl();

    // make sure we have a contrast between primary & secondary
    if (secondaryColor.hue - domColor.hue > -45 &&
        secondaryColor.hue - domColor.hue < 45)
      secondaryColor = ColorHsl(
          domColor.hue > 180 ? domColor.hue - 180 : domColor.hue + 180,
          secondaryColor.toHsl().saturation,
          secondaryColor.toHsl().lightness);

    secondaryColor = makeShade500(secondaryColor);

    // Dark
    final darkBg = colors.colorsWith(
        where: (ColorRgb c, double dominance) =>
            c.toHsl().saturation > 0.1 &&
            c.toHsl().luminance < 0.09 &&
            c.toHsl().lightness > 0.09,
        score: (ColorRgb c, double dominance) =>
            (_distanceScore(c.toHsl().luminance, 0.07) * 2) +
            _distanceScore(c.toHsl().lightness, 0.18) +
            (dominance));
    var darkBgColor = darkBg.keys.first;
    final bgHsl = darkBgColor.toHsl();
    if (darkBgColor.toHsl().lightness > 0.17)
      darkBgColor = ColorHsl(bgHsl.hue, bgHsl.saturation, 0.17);

    if (darkBgColor.toHsl().luminance > 0.03)
      darkBgColor = ColorHsl(bgHsl.hue, bgHsl.saturation, 0.1);

    // Light
    final darkFg = colors.colorsWith(
        where: (ColorRgb c, double dominance) =>
            c.toHsl().saturation > 0.01 &&
            c.toHsl().luminance > 0.2 &&
            c.toHsl().lightness < 0.90 &&
            c.toHsl().lightness > 0.4,
        score: (ColorRgb c, double dominance) =>
            (_distanceScore(c.toHsl().lightness, 0.8) / 2) +
            (_distanceScore(c.toHsl().saturation, 1) / 4) +
            ((1 -
                _distanceScore(
                    c.toHsl().hue / 360, darkBgColor.toHsl().hue / 360,
                    wrapped: true))) +
            (dominance / 4));

    var darkFgColor = darkFg.keys.first;
    final darkFgHsl = darkFgColor.toHsl();
    if (darkFgColor.toHsl().lightness < 0.83)
      darkFgColor = ColorHsl(darkFgHsl.hue, darkFgHsl.saturation, 0.83);

    return UiTheme(
        primary: domColor,
        secondary: secondaryColor,
        dark: darkBgColor,
        light: darkFgColor);
  }

  static ColorHsl makeShade500(ColorHsl hslIn) {
    var hsl = hslIn.toHsl();

    if (hsl.saturation < 0.3) hsl = ColorHsl(hsl.hue, 0.3, hsl.lightness + 0.1);

    // return hsl;
    if (hsl.lightness < 0.2 && hsl.luminance < 0.2)
      hsl = ColorHsl(hsl.hue, hsl.saturation, 0.5);
    else if (hsl.lightness < 0.3 && hsl.luminance < 0.3)
      hsl = ColorHsl(hsl.hue, hsl.saturation, 0.5);
    else if (hsl.lightness < 0.4 && hsl.luminance < 0.4)
      hsl = ColorHsl(hsl.hue, hsl.saturation, 0.45);

    if (hsl.lightness > 0.5 && hsl.luminance > 0.5)
      hsl = ColorHsl(hsl.hue, hsl.saturation, 0.5);
    else if (hsl.lightness > 0.5 && hsl.luminance > 0.4)
      hsl = ColorHsl(hsl.hue, hsl.saturation, 0.5);
    else if (hsl.lightness > 0.35 && hsl.luminance > 0.4)
      hsl = ColorHsl(hsl.hue, hsl.saturation, 0.35);

    return hsl;
  }
}

class ScoredColors {
  // color + score (cullumative)
  final Map<ColorRgb, double>? colors;
  final NeuralQuantizer? neuralQuantizer;

  ScoredColors({this.colors, this.neuralQuantizer});

  @override
  String toString() {
    var out = 'Colors:\n';
    for (var c in colors!.keys) {
      out += ('${colors![c]} #${c.toHex(alpha: false)} Lu:${c.luminance.toStringAsFixed(2)}'
          ' Li:${c.toHsl().lightness.toStringAsFixed(2)} '
          'H:${c.toHsl().hue.round()} S:${c.toHsl().saturation.toStringAsFixed(2)} \n');
    }
    return out;
  }

  void removeColors(bool Function(ColorRgb c) whereFunc) {
    colors!.removeWhere((key, value) => whereFunc(key));
  }

  Map<ColorRgb, double?> colorsWith(
      {double Function(ColorRgb c, double dominance)? score,
      bool Function(ColorRgb c, double dominance)? where}) {
    Map<ColorRgb, double> out = {};
    Map<ColorRgb, double> secondary = {};

    var countMax = colors!.values.first;

    colors!.forEach((color, count) {
      var dominance = (count / countMax);
      if (where!(color, dominance)) {
        out[color] = score!(color, dominance);
      } else
        secondary[color] = score!(color, dominance);
    });
    if (out.isEmpty) out = secondary;

    final sorted = out.keys.toList()
      ..sort((c1, c2) => out[c2]!.compareTo(out[c1]!));
    return Map<ColorRgb, double?>.fromIterables(
        sorted, sorted.map((e) => out[e]));
  }

  ScoredColors scoreLuminosity(double ideal, [double reward = 100.0]) {
    return _score(
      ideal,
      (ColorRgb c) => c.luminance,
      reward,
    );
  }

  ScoredColors scoreSaturation(double ideal, [double reward = 100.0]) {
    return _score(
      ideal,
      (ColorRgb c) => c.toHsl().saturation,
      reward,
    );
  }

  ScoredColors _score(double ideal, double Function(ColorRgb) getValue,
      [double reward = 100.0]) {
    var scores = colors!.values.toList();

    for (int i = 0, l = colors!.keys.length; i < l; i++) {
      // print('${colors.keys.elementAt(i)} = ' +
      //     getValue(colors.keys.elementAt(i)).toString());
      var similiarity =
          1 - ((getValue(colors!.keys.elementAt(i)) - ideal).abs());
      scores[i] += reward * similiarity;
    }
    return ScoredColors(
        colors: Map.fromIterables(colors!.keys, scores),
        neuralQuantizer: neuralQuantizer);
  }

  // factory ScoredColors.fromColors(List<int> colors) {
  //   return ScoredColors(
  //       colors: Map.fromIterables(
  //           colors, List.generate(colors.length, (index) => 0)));
  // }

  factory ScoredColors.fromImage(Image image) {
    const maxColors = 24;

    final smallImage =
        copyResize(image, width: 32, interpolation: Interpolation.cubic);

    // sample factor needs to be high to detect small colors in image
    var swatch =
        NeuralQuantizer(image, numberOfColors: maxColors, samplingFactor: 10);

    // index of color, count of colours
    Map<int, int> colorCount = {};
    for (var i = 0; i < maxColors; i++) colorCount[swatch.color(i)] = 0;

    for (var x = 0; x < smallImage.width; x++) {
      for (var y = 0; y < smallImage.height; y++) {
        final swatchIndex = swatch.lookup(smallImage.getPixel(x, y));
        print('$x $y $swatchIndex');
        // if (color != null) color++;
        if (colorCount.containsKey(swatch.color(swatchIndex)))
          colorCount[swatch.color(swatchIndex)] =
              colorCount[swatch.color(swatchIndex)]! + 1;
        else
          print('swatch index out of range: $swatchIndex');
      }
    }
    print(colorCount);
    final sorted = colorCount.keys.toList()
      ..sort((k1, k2) => colorCount[k2]!.compareTo(colorCount[k1]!));

    return ScoredColors(
        neuralQuantizer: swatch,
        colors: Map.fromIterables(
            sorted.map((i) =>
                ColorRgb(getRed(i) / 255, getGreen(i) / 255, getBlue(i) / 255)),
            //ColorRgb.fromIntRGBA(i)),
            sorted.map((c) => colorCount[c]!.toDouble())));
  }
}

class ColorCollectionDebug {
  final String? title;

  /// colors and scores
  final Map<ColorRgb, num>? colors;

  ColorCollectionDebug({this.title, this.colors});

  String colorDebugText(int color) =>
      _colorDebug(color, colors![color as ColorRgb]);
}

int _boostSaturation(int color, double percentage, {double ifBelow = 1.0}) {
  final hsl = rgbToHsl(getRed(color), getGreen(color), getBlue(color));
  var newSat = hsl[1] > ifBelow ? hsl[1] : hsl[1] * (1 + percentage);
  return Color.fromHsl(
      hsl[0], newSat < 0 ? 0 : (newSat > 1 ? 1 : newSat), hsl[2]);
}

int _adjustColor(int color, double lightness) {
  final hsl = rgbToHsl(getRed(color), getGreen(color), getBlue(color));

  num diffFraction = hsl[2] - lightness;
  var newSat = hsl[1] * (1 + diffFraction);
  return Color.fromHsl(
      hsl[0], newSat < 0 ? 0 : (newSat > 1 ? 1 : newSat), lightness);
}

int _incrementLightness(int color, double lightness) {
  final hsl = rgbToHsl(getRed(color), getGreen(color), getBlue(color));
  num newLightness = hsl[2] + lightness;
  var diffFraction = hsl[2] - newLightness;
  var newSat = hsl[1] * (1 + diffFraction);
  print('old l: ${hsl[2]} new l: $newLightness');
  return Color.fromHsl(hsl[0], newSat < 0 ? 0 : (newSat > 1 ? 1 : newSat),
      newLightness < 0 ? 0 : (newLightness > 1 ? 1 : newLightness));
}

String _rgbFromInt(int i) => 'rgb(${getRed(i)},${getGreen(i)},${getBlue(i)})';
String _colorDebug(int c, [num? count]) {
  var hsl = rgbToHsl(getRed(c), getGreen(c), getBlue(c));
  return 'x${count != null ? count : ''} LUM:${getLuminance(c)} '
      ' H:${(hsl[0] * 100).round()} S:${(hsl[1] * 100).round()} L:${(hsl[2] * 100).round()}'
      '${_rgbFromInt(c)}';
}
