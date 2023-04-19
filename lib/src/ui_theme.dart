import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../color.dart';
import '../palette.dart';

class UiTheme {
  static List<List<ColorRgb>> fromJpg(Uint8List bytes, [int options = 3]) {
    final image = img.decodeJpg(bytes);
    if (image == null) {
      throw Exception('Image not decoded');
    }
    return _fromImage(image, options);
  }

  static List<List<ColorRgb>> fromImage(Uint8List bytes, [int options = 3]) {
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Image not decoded');
    }
    return _fromImage(image, options);
  }

  static List<List<ColorRgb>> _fromImage(img.Image image, [int options = 3]) {
    const smallSize = 64;

    // reduced size
    final colors = ScoredColors.fromImage(image);

    return Palette.optionsFrom(colors.colors!.keys.toList(), options: options);
  }
}

class ScoredColors {
  // color + score (cullumative)
  final Map<ColorRgb, double>? colors;
  final img.NeuralQuantizer? neuralQuantizer;

  ScoredColors({this.colors, this.neuralQuantizer});

  factory ScoredColors.fromImage(img.Image image) {
    const maxColors = 24;

    final smallImage = img.copyResize(image,
        width: 64, interpolation: img.Interpolation.cubic);

    // sample factor needs to be high to detect small colors in image
    var swatch = img.NeuralQuantizer(image,
        numberOfColors: maxColors, samplingFactor: 12);

    // <Color(int)>, <count of colours>
    Map<int, int> colorCount = {};
    for (var i = 0; i < maxColors; i++)
      colorCount[img.rgbaToUint32(
        swatch.palette.getRed(i).round(),
        swatch.palette.getGreen(i).round(),
        swatch.palette.getBlue(i).round(),
        swatch.palette.getAlpha(i).round(),
      )] = 0;

    // itterate over the image and count the colours...
    for (var x = 0; x < smallImage.width; x++) {
      for (var y = 0; y < smallImage.height; y++) {
        final qc = swatch.getQuantizedColor(smallImage.getPixel(x, y));
        final ci = img.rgbaToUint32(
            qc.r.toInt(), qc.g.toInt(), qc.b.toInt(), qc.a.toInt());

        // print('$x $y $swatchIndex');
        // if (color != null) color++;
        if (colorCount.containsKey(ci))
          colorCount[ci] = colorCount[ci]! + 1;
        else
          throw Exception('Swatch does not contain color: $ci');
      }
    }
    // print(colorCount);
    final sorted = colorCount.keys.toList()
      ..sort((k1, k2) => colorCount[k2]!.compareTo(colorCount[k1]!));

    return ScoredColors(
        neuralQuantizer: swatch,
        colors: Map.fromIterables(
            sorted.map((i) => ColorRgb(img.uint32ToRed(i) / 255,
                img.uint32ToGreen(i) / 255, img.uint32ToBlue(i) / 255)),
            //ColorRgb.fromIntRGBA(i)),
            sorted.map((c) => colorCount[c]!.toDouble())));
  }
}
