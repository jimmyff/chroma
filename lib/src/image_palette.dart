import 'package:image/image.dart';

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
    final smallImageEdge = drawCircle(
        smallImage,
        (smallSize / 2).round(),
        (smallSize / 2).round(),
        (smallSize / 2).round(),
        Color.fromRgb(0, 0, 0));

    final edgeSwatch = ScoredColors.fromImage(smallImageEdge);
    if (debug)
      debugData.add(ColorCollectionDebug(
          title: 'Edge swatch', colors: edgeSwatch.colors));

    return ImagePalette(
      dark: UiTheme._fromFominantColors(
          full: swatch, edge: edgeSwatch, bgLuminosity: 0.2, fgLuminosity: 0.8),
      light: UiTheme._fromFominantColors(
          full: swatch, edge: edgeSwatch, bgLuminosity: 0.8, fgLuminosity: 0.2),
      debug: debugData,
    );
  }
}

class UiTheme {
  final int bg;
  final int fg;

  final List<ColorCollectionDebug> debug;

  UiTheme({this.bg, this.fg, this.debug});

  factory UiTheme._fromFominantColors(
      {ScoredColors full,
      ScoredColors edge,
      bool debug,
      double bgLuminosity,
      double fgLuminosity}) {
    List<ColorCollectionDebug> debugData = [];
    Map<int, double> edgeBgScore = {};
    var countMax = edge.colors.keys.first;
    var minLuminosity = 30;
    var maxLuminosity = 130;
    edge.colors.forEach((color, count) {
      var hsl = rgbToHsl(getRed(color), getGreen(color), getBlue(color));
      final lum = getLuminance(color);
      edgeBgScore[color] = (hsl[1] < 0.15 || hsl[1] > 0.85 ? 0.0 : 0.6) +
          // who has the most
          (count / countMax) +
          (lum > minLuminosity && lum < maxLuminosity ? 1 : 0);
    });
    var edgeColorSorted = edgeBgScore.keys.toList()
      ..sort((k1, k2) => edgeBgScore[k2].compareTo(edgeBgScore[k1]));

    if (debug)
      debugData.add(ColorCollectionDebug(
          title: 'Edge colors scored',
          colors: Map.fromIterables(
              edgeColorSorted, edgeColorSorted.map((e) => edgeBgScore[e]))));

    var edgeColor = edgeColorSorted.first;
    var i = 1;
    while (getLuminance(edgeColor) > 100 && i < 6) {
      edgeColor = _incrementLightness(edgeColorSorted.first, -(i++ * 0.1));
    }

    edgeColor = _boostSaturation(edgeColor, 0.3, ifBelow: 0.7);

    if (debug)
      debugData.add(
          ColorCollectionDebug(title: 'Edge color', colors: {edgeColor: 1}));

    // print('Updated edge color: ${_colorDebug(edgeColor)}');

    var hsl =
        rgbToHsl(getRed(edgeColor), getGreen(edgeColor), getBlue(edgeColor));
    var idealComplimentary = Color.fromHsl(
        hsl[0] > 0.5 ? hsl[0] - 0.5 : hsl[0] + 0.5, hsl[1], hsl[2]);
    // idealComplimentary = _adjustColor(idealComplimentary, 0.70);

    idealComplimentary =
        _boostSaturation(idealComplimentary, 0.3, ifBelow: 0.7);

    for (var i = 0; i < 20; i++) {
      if (getLuminance(idealComplimentary) < 180)
        idealComplimentary =
            _incrementLightness(idealComplimentary, (i++ * 0.01));
    }

    if (debug)
      debugData.add(ColorCollectionDebug(
          title: 'Ideal Complimentary', colors: {idealComplimentary: 1}));

    var matchedFgColor = full.neuralQuantizer
        .color(full.neuralQuantizer.lookup(idealComplimentary));

    if (debug)
      debugData.add(ColorCollectionDebug(
          title: 'Matched Complimentary', colors: {matchedFgColor: 1}));

    matchedFgColor = _boostSaturation(matchedFgColor, 0.2, ifBelow: 0.4);

    for (var i = 0; i < 20; i++) {
      if (getLuminance(matchedFgColor) < 220)
        matchedFgColor = _incrementLightness(matchedFgColor, (i++ * 0.01));
    }

    print('bg: ${_colorDebug(edgeColor)}');
    print('fg: ${_colorDebug(matchedFgColor)}');

    if (debug)
      debugData.add(ColorCollectionDebug(
          title: 'Adjusted Matched Complimentary',
          colors: {matchedFgColor: 1}));

    return UiTheme(debug: debugData, fg: edgeColor, bg: matchedFgColor);
  }
}

class ScoredColors {
  // color + score (cullumative)
  final Map<int, double> colors;
  final NeuralQuantizer neuralQuantizer;

  ScoredColors({this.colors, this.neuralQuantizer});

  ScoredColors scoreLuminosity(double ideal, [double reward = 100.0]) {
    return _score(
      ideal,
      (int c) => getLuminance(c).toDouble() / 255,
      reward,
    );
  }

  ScoredColors scoreSaturation(double ideal, [double reward = 100.0]) {
    return _score(
      ideal,
      (int c) => rgbToHsl(getRed(c), getGreen(c), getBlue(c))[1].toDouble(),
      reward,
    );
  }

  ScoredColors _score(double ideal, double Function(int) getValue,
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

  factory ScoredColors.fromColors(List<int> colors) {
    return ScoredColors(
        colors: Map.fromIterables(
            colors, List.generate(colors.length, (index) => 0)));
  }

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

    var sorted = colorCount.keys.toList()
      ..sort((k1, k2) => colorCount[k2].compareTo(colorCount[k1]));

    return ScoredColors(
        neuralQuantizer: swatch,
        colors: Map.fromIterables(
            sorted, sorted.map((c) => colorCount[c].toDouble())));
  }
}

class ColorCollectionDebug {
  final String title;

  /// colors and scores
  final Map<int, num> colors;

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
