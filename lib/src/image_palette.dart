import 'package:image/image.dart';

import 'package:chroma/color.dart';

class ImagePalette {
  final UiTheme dark;
  final UiTheme light;
  final int dominant;
  final List<ColorCollectionDebug> debug;

  ImagePalette({this.debug, this.dark, this.light, this.dominant});

  factory ImagePalette.fromJpg(List<int> bytes, {bool debug = false}) {
    final image = decodeJpg(bytes);
    return ImagePalette._fromImage(image, debug: debug);
  }

  factory ImagePalette._fromImage(Image image, {bool debug = false}) {
    const smallSize = 32;
    List<ColorCollectionDebug> debugData = [];

    // reduced size
    final smallImage = copyResize(image, width: smallSize);

    final swatch = ScoredColors.fromImage(smallImage);

    if (debug)
      debugData.add(
          ColorCollectionDebug(title: 'Full swatch', colors: swatch.colors));

    // reduce the focal point
    final smallImageEdge = fillCircle(
        smallImage,
        (smallSize / 2).round(),
        (smallSize / 2).round(),
        (smallSize / 2).round(),
        Color.fromRgb(0, 0, 0));

    final edgeSwatch = ScoredColors.fromImage(smallImageEdge)
      ..removeColors((ColorRgb c) => c.toHsl().lightness == 0.0);
    if (debug)
      debugData.add(ColorCollectionDebug(
          title: 'Edge swatch', colors: edgeSwatch.colors));

    return ImagePalette(
      dark: UiTheme._fromDominantColors(
          full: swatch,
          edge: edgeSwatch,
          bgLuminosity: 0.2,
          fgLuminosity: 0.75),
      light: UiTheme._fromDominantColors(
          full: swatch,
          edge: edgeSwatch,
          bgLuminosity: 0.85,
          fgLuminosity: 0.2),
      debug: debugData,
    );
  }
}

double _distanceScore(double v1, double v2, {bool wrapped = false}) =>
    (1 - ((v1 + (wrapped ? 1.0 : 0.0)) - (v2 + (wrapped ? 1.0 : 0.0))).abs());

class UiTheme {
  final ColorRgb bg;
  final ColorRgb fg;

  final List<ColorCollectionDebug> debug;

  UiTheme({this.bg, this.fg, this.debug});

  factory UiTheme._fromDominantColors(
      {ScoredColors full,
      ScoredColors edge,
      bool debug = false,
      double bgLuminosity,
      double fgLuminosity}) {
    List<ColorCollectionDebug> debugData = [];
    Map<int, double> edgeBgScore = {};

    var bg = edge.colorsWith(
        where: (ColorRgb c, double dominance) =>
            c.toHsl().saturation > 0.1 &&
            c.toHsl().luminance < 0.07 &&
            c.toHsl().lightness > 0.05,
        score: (ColorRgb c, double dominance) =>
            (_distanceScore(c.toHsl().luminance, 0.05) * 2) +
            _distanceScore(c.toHsl().lightness, 0.15) +
            (dominance));
    var bgColor = bg.keys.first;
    final bgHsl = bgColor.toHsl();
    if (bgColor.toHsl().lightness > 0.2)
      bgColor = ColorHsl(bgHsl.hue, bgHsl.saturation, 0.2);
    var fg = full.colorsWith(
        where: (ColorRgb c, double dominance) =>
            c.toHsl().saturation > 0.3 &&
            c.toHsl().luminance > 0.2 &&
            c.toHsl().lightness < 0.90 &&
            c.toHsl().lightness > 0.4,
        score: (ColorRgb c, double dominance) =>
            _distanceScore(c.toHsl().lightness, 0.8) +
            (_distanceScore(c.toHsl().saturation, 1) / 4) +
            ((1 -
                _distanceScore(c.toHsl().hue, bgColor.toHsl().hue,
                    wrapped: true))) +
            (dominance / 6));

    var fgColor = fg.keys.first;
    final fgHsl = fgColor.toHsl();
    if (fgColor.toHsl().lightness < 0.8)
      fgColor = ColorHsl(fgHsl.hue, fgHsl.saturation, 0.8);

    return UiTheme(fg: fgColor, bg: bgColor);
  }
}

class ScoredColors {
  // color + score (cullumative)
  final Map<ColorRgb, double> colors;
  final NeuralQuantizer neuralQuantizer;

  ScoredColors({this.colors, this.neuralQuantizer});

  void removeColors(bool Function(ColorRgb c) whereFunc) {
    colors.removeWhere((key, value) => whereFunc(key));
  }

  Map<ColorRgb, double> colorsWith(
      {double Function(ColorRgb c, double dominance) score,
      bool Function(ColorRgb c, double dominance) where}) {
    Map<ColorRgb, double> out = {};
    Map<ColorRgb, double> secondary = {};

    var countMax = colors.values.first;

    colors.forEach((color, count) {
      var dominance = (count / countMax);
      if (where(color, dominance)) {
        out[color] = score(color, dominance);
      } else
        secondary[color] = score(color, dominance);
    });
    if (out.isEmpty) out = secondary;

    final sorted = out.keys.toList()
      ..sort((c1, c2) => out[c2].compareTo(out[c1]));
    return Map<ColorRgb, double>.fromIterables(
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
    var scores = colors.values.toList();

    for (int i = 0, l = colors.keys.length; i < l; i++) {
      // print('${colors.keys.elementAt(i)} = ' +
      //     getValue(colors.keys.elementAt(i)).toString());
      var similiarity =
          1 - ((getValue(colors.keys.elementAt(i)) - ideal).abs());
      scores[i] += reward * similiarity;
    }
    return ScoredColors(
        colors: Map.fromIterables(colors.keys, scores),
        neuralQuantizer: neuralQuantizer);
  }

  // factory ScoredColors.fromColors(List<int> colors) {
  //   return ScoredColors(
  //       colors: Map.fromIterables(
  //           colors, List.generate(colors.length, (index) => 0)));
  // }

  factory ScoredColors.fromImage(Image image) {
    const maxColors = 24;

    // sample factor needs to be high to detect small colors in image
    var swatch =
        NeuralQuantizer(image, numberOfColors: maxColors, samplingFactor: 1);

    Map<int, int> colorCount = {};

    for (var i = 0; i < maxColors; i++) colorCount[swatch.color(i)] = 0;

    for (var x = 0; x < image.width; x++) {
      for (var y = 0; y < image.height; y++) {
        colorCount[swatch.color(swatch.lookup(image.getPixel(x, y)))]++;
      }
    }

    final sorted = colorCount.keys.toList()
      ..sort((k1, k2) => colorCount[k2].compareTo(colorCount[k1]));

    return ScoredColors(
        neuralQuantizer: swatch,
        colors: Map.fromIterables(
            sorted.map((i) =>
                ColorRgb(getRed(i) / 255, getGreen(i) / 255, getBlue(i) / 255)),
            //ColorRgb.fromIntRGBA(i)),
            sorted.map((c) => colorCount[c].toDouble())));
  }
}

class ColorCollectionDebug {
  final String title;

  /// colors and scores
  final Map<ColorRgb, num> colors;

  ColorCollectionDebug({this.title, this.colors});

  String colorDebugText(int color) => _colorDebug(color, colors[color]);
}

int _boostSaturation(int color, double percentage, {double ifBelow = 1.0}) {
  final hsl = rgbToHsl(getRed(color), getGreen(color), getBlue(color));
  var newSat = hsl[1] > ifBelow ? hsl[1] : hsl[1] * (1 + percentage);
  return Color.fromHsl(
      hsl[0], newSat < 0 ? 0 : (newSat > 1 ? 1 : newSat), hsl[2]);
}

int _adjustColor(int color, double lightness) {
  final hsl = rgbToHsl(getRed(color), getGreen(color), getBlue(color));

  var diffFraction = hsl[2] - lightness;
  var newSat = hsl[1] * (1 + diffFraction);
  return Color.fromHsl(
      hsl[0], newSat < 0 ? 0 : (newSat > 1 ? 1 : newSat), lightness);
}

int _incrementLightness(int color, double lightness) {
  final hsl = rgbToHsl(getRed(color), getGreen(color), getBlue(color));
  var newLightness = hsl[2] + lightness;
  var diffFraction = hsl[2] - newLightness;
  var newSat = hsl[1] * (1 + diffFraction);
  print('old l: ${hsl[2]} new l: $newLightness');
  return Color.fromHsl(hsl[0], newSat < 0 ? 0 : (newSat > 1 ? 1 : newSat),
      newLightness < 0 ? 0 : (newLightness > 1 ? 1 : newLightness));
}

String _rgbFromInt(int i) => 'rgb(${getRed(i)},${getGreen(i)},${getBlue(i)})';
String _colorDebug(int c, [num count]) {
  var hsl = rgbToHsl(getRed(c), getGreen(c), getBlue(c));
  return 'x${count != null ? count : ''} LUM:${getLuminance(c)} '
      ' H:${(hsl[0] * 100).round()} S:${(hsl[1] * 100).round()} L:${(hsl[2] * 100).round()}'
      '${_rgbFromInt(c)}';
}
