import 'package:image/image.dart';

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

class ColorCollectionDebug {
  final String title;

  /// colors and scores
  final Map<int, num> colors;

  ColorCollectionDebug({this.title, this.colors});

  String colorDebugText(int color) => _colorDebug(color, colors[color]);
}

class ImageSwatch {
  ImageSwatch({this.background, this.foreground, this.debug});
  final int background;
  final int foreground;
  final List<ColorCollectionDebug> debug;

  factory ImageSwatch.fromJpg(List<int> bytes, {bool debug = false}) {
    final image = decodeJpg(bytes);
    return ImageSwatch._fromImage(image, debug: debug);
  }

  factory ImageSwatch._fromImage(Image image, {bool debug = false}) {
    const smallSize = 32;
    List<ColorCollectionDebug> debugData = [];

    // reduced size
    final smallImage = copyResize(image, width: smallSize);

    final palette = DominantColors.fromImage(smallImage);

    if (debug)
      debugData.add(
          ColorCollectionDebug(title: 'Full palette', colors: palette.colors));

    // print('Full palette:');
    // palette.colors.forEach((color, count) {
    //   var hsl = rgbToHsl(getRed(color), getGreen(color), getBlue(color));
    //   print(_colorDebug(color, count));
    // });

    // reduce the focal point
    final smallImageEdge = drawCircle(
        smallImage,
        (smallSize / 2).round(),
        (smallSize / 2).round(),
        (smallSize / 2).round(),
        Color.fromRgb(0, 0, 0));

    final edgePalette = DominantColors.fromImage(smallImageEdge);
    if (debug)
      debugData.add(ColorCollectionDebug(
          title: 'Edge palette', colors: edgePalette.colors));
    // print('Edge palette:');
    // edgePalette.colors.forEach((color, count) {
    //   print(_colorDebug(color, count));
    // });

    Map<int, double> edgeBgScore = {};
    var countMax = edgePalette.colors.keys.first;
    var minLuminosity = 30;
    var maxLuminosity = 130;
    edgePalette.colors.forEach((color, count) {
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

    // edgeColorSorted.forEach((color) {
    //   print('possible: ' +
    //       _colorDebug(color, (edgeBgScore[color] * 100).round()));
    // });

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

    var matchedFgColor = palette.neuralQuantizer
        .color(palette.neuralQuantizer.lookup(idealComplimentary));

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

    return ImageSwatch(
        background: edgeColor, foreground: matchedFgColor, debug: debugData);
  }
}

class DominantColors {
  final Map<int, int> colors;
  final NeuralQuantizer neuralQuantizer;

  DominantColors({this.colors, this.neuralQuantizer});

  factory DominantColors.fromImage(Image image) {
    const maxColors = 24;

    // sample factor needs to be high to detect small colors in image
    var palette =
        NeuralQuantizer(image, numberOfColors: maxColors, samplingFactor: 1);

    Map<int, int> colorCount = {};

    for (var i = 0; i < maxColors; i++) colorCount[palette.color(i)] = 0;

    for (var x = 0; x < image.width; x++) {
      for (var y = 0; y < image.height; y++) {
        colorCount[palette.color(palette.lookup(image.getPixel(x, y)))]++;
      }
    }

    var sorted = colorCount.keys.toList()
      ..sort((k1, k2) => colorCount[k2].compareTo(colorCount[k1]));

    return DominantColors(
        neuralQuantizer: palette,
        colors: Map.fromIterables(sorted, sorted.map((c) => colorCount[c])));
  }
}
