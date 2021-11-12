import 'package:image/image.dart';

import '../color.dart';
import '../palette.dart';

class UiTheme {
  static List<List<ColorRgb>> fromJpg(List<int> bytes, [int options = 3]) {
    final image = decodeJpg(bytes);
    return _fromImage(image, options);
  }

  static List<List<ColorRgb>> _fromImage(Image image, [int options = 3]) {
    const smallSize = 32;

    // reduced size
    final colors = ScoredColors.fromImage(image);

    return Palette.optionsFrom(colors.colors!.keys.toList(), options: options);
  }
}

class ScoredColors {
  // color + score (cullumative)
  final Map<ColorRgb, double>? colors;
  final NeuralQuantizer? neuralQuantizer;

  ScoredColors({this.colors, this.neuralQuantizer});

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
        // print('$x $y $swatchIndex');
        // if (color != null) color++;
        if (colorCount.containsKey(swatch.color(swatchIndex)))
          colorCount[swatch.color(swatchIndex)] =
              colorCount[swatch.color(swatchIndex)]! + 1;
        else
          print('swatch index out of range: $swatchIndex');
      }
    }
    // print(colorCount);
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
