import 'dart:math';
import 'package:chroma/color.dart';

class ColorScore {
  final ColorRgb color;
  final ColorHsl colorHsl;
  ColorScore(this.color) : colorHsl = color.toHsl();
  double get score => _score;
  double _score = 0;
  Map<String, double> _debug = {};

  void addScore(String description, double value, [double weight = 1.0]) {
    _score += value * weight;
    _debug[description] = value * weight;
  }

  @override
  String toString() {
    final debug = _debug.keys
        .map((desc) => '$desc=${_debug[desc]!.toStringAsFixed(3)}')
        .join(',');
    return '$color ${_score.toStringAsFixed(3)} ($debug)';
  }
}

class Palette {
  /// [colors] should be provided in order of dominance/priority
  static List<List<ColorRgb>> optionsFrom(List<ColorRgb> colors,
      {int options = 3, bool boostColors = true}) {
    print('Finding options for colors $colors');
    // Score the colors
    final scored = Palette.scoreColors(colors, boostColors);

    // find dominants
    Map<ColorScore, List<ColorScore>> dominantColors = {};

    for (final c in scored) {
      final hsl = c.colorHsl;
      final matchingDoms = dominantColors.keys
          .where((d) => ColorHsl.hueDistance(d.colorHsl, hsl) < (360 / 8))
          .toList();
      if (matchingDoms.isNotEmpty) continue;

      dominantColors[c] = [];
      if (dominantColors.length >= options) break;
    }

    // find complimentarys
    List<ColorScore> complimentaries = [];

    for (final c in scored) {
      final hsl = c.colorHsl;
      final matching = complimentaries
          .where((d) => ColorHsl.hueDistance(d.colorHsl, hsl) < (360 / 10))
          .toList();
      if (matching.isNotEmpty) continue;

      complimentaries.add(c);
    }

    // // Find most complimentary color for each dominant
    for (final d in dominantColors.keys) {
      print('Finding complimentary ${d.color}');
      Map<ColorScore, double> hueDistance = {};
      for (final c in complimentaries) {
        final dist = ColorHsl.hueDistance(d.colorHsl, c.colorHsl);
        print('${c.color} dist: $dist');
        hueDistance[c] = dist + (c._score * 4);
      }
      print('hue distances for ${d.colorHsl}');
      print(hueDistance);
      final complimentary = complimentaries
          .where(
              (c) => hueDistance[c]! > (360 / 5) && c.colorHsl.lightness > 0.1)
          .toList()
        ..sort((c1, c2) => hueDistance[c2]!.compareTo(hueDistance[c1]!));
      dominantColors[d] = complimentary.take(options).toList();

      print('complimentaries for ${d.colorHsl} : ${dominantColors[d]}');
    }

    // Add a perfect complimentary to each as a fallback

    for (final d in dominantColors.keys) {
      // Fallback
      if (dominantColors[d]!.isEmpty || dominantColors.keys.length == 1) {
        dominantColors[d]!

          // Split complimentary color
          ..add(ColorScore(ColorRgb.fromHex(
              ColorHsl((d.colorHsl.hue + 180) % 360, 0.3, 0.5).toHex())))

          // Triadic color
          ..add(ColorScore(ColorRgb.fromHex(
              ColorHsl((d.colorHsl.hue + 120) % 360, 0.3, 0.5).toHex())))

          // Triadic color
          ..add(ColorScore(ColorRgb.fromHex(
              ColorHsl((d.colorHsl.hue + 240) % 360, 0.3, 0.5).toHex())));
      }
    }

    print('Dominant colors & complimentary: ');
    print(dominantColors.keys.map((d) => '${d.color} : ${dominantColors[d]}'));

    final noMoreColors = false;

    List<List<ColorRgb>> paletteOptions = [];
    var i = 0;
    final domKeys = dominantColors.keys.toList();
    final domPairs = dominantColors.values.toList();

    while (noMoreColors == false) {
      final idx = i++ % domKeys.length;

      if (domPairs[idx].isEmpty) {
        break;
      }

      final option = [domKeys[idx].color, domPairs[idx].first.color];
      domPairs[idx] = domPairs[idx].sublist(1);

      paletteOptions.add(option);
      if (paletteOptions.length >= options) break;
    }

    print('paletteOptions: ');
    print(paletteOptions.map((d) => '$d'));

    Map<ColorRgb, ColorRgb> tunedColours = {};
    List<List<ColorRgb>> tunedPalette = [];
    final desiredContrastRatio = 7;

    // Tune the colours to be suitable for white text over
    for (final d in paletteOptions) {
      for (var colorIndex in [0, 1]) {
        if (!tunedColours.containsKey(d[colorIndex])) {
          ColorHsl tunedColor = d[colorIndex].toHsl();

          // if (tunedColor.lightness < 0.2)
          //   tunedColor = ColorHsl(tunedColor.hue, tunedColor.saturation, 0.2);

          if (tunedColor.saturation < 0.3)
            tunedColor = ColorHsl(tunedColor.hue, tunedColor.saturation * 2,
                tunedColor.lightness);

          var contrastRatio =
              ColorRgb.contrastRatioFromLuminance(1.0, tunedColor.luminance);
          while (contrastRatio < desiredContrastRatio) {
            tunedColor = tunedColor.shade(0.6);
            contrastRatio =
                ColorRgb.contrastRatioFromLuminance(1.0, tunedColor.luminance);
          }
          tunedColours[d[colorIndex]] = tunedColor;
        }
      }
      tunedPalette.add([tunedColours[d[0]]!, tunedColours[d[1]]!]);
    }

    print('tunedPalette: ');
    print(tunedPalette.map((d) => '$d'));

    return tunedPalette;
  }

  static ColorHsl boostColorHue(ColorHsl color) {
    var boostedColor = color.toHsl();

    // sat
    boostedColor = ColorHsl(
        // Set the hue to 0 if really dark to avoid multiple dark colours
        boostedColor.lightness < 0.1
            ? 0
            : (boostedColor.saturation < 0.05
                ? Random(color.toInt()).nextInt(360).toDouble()
                : boostedColor.hue),
        boostedColor.saturation < 0.05 ? 0.3 : boostedColor.saturation,
        boostedColor.lightness);

    return boostedColor;
  }

  static ColorHsl boostColorSaturation(ColorHsl color) {
    final desiredMinSaturation = 0.25;

    var boostedColor = color.toHsl();

    // sat
    if (boostedColor.saturation < desiredMinSaturation)
      boostedColor = ColorHsl(
          boostedColor.hue, desiredMinSaturation, boostedColor.lightness);

    return boostedColor;
  }

  /// [colors] should be provided in order of dominance/priority
  static List<ColorScore> scoreColors(List<ColorRgb> colors, bool boostColors) {
    Map<ColorRgb, ColorScore> scores = {};

    // score the colours on priority
    var i = 0;

    for (final c in colors) {
      var color = c.toHsl();
      var boostedHue = false;
      var boostedSaturation = false;
      if (boostColors) {
        final hueBoost = Palette.boostColorHue(color);
        boostedHue = (color.toInt() != hueBoost.toInt());

        final satBoost = Palette.boostColorSaturation(hueBoost);
        boostedSaturation = (hueBoost.toInt() != satBoost.toInt());

        color = hueBoost;
      }
      print('Boosted: $c became $color');

      var score = ColorScore(color);

      // strip out the whites
      if (score.colorHsl.lightness > 0.8) continue;

      scores[c] = score
        ..addScore(
            'Boosted', (boostedSaturation ? -0.1 : 0) + (boostedHue ? -3 : 0))
        ..addScore('Dominance/Priority', (1 - (i++ * (1 / colors.length))));
    }

    // General scoring
    for (final c in scores.keys) {
      final hsl = c.toHsl();

      // score on closness to desired luminosity
      final lum = c.luminance;
      print('${scores[c]!.color} with lum: $lum');
      final luminanceDeviation = lum > 0.3 ? lum - 0.3 : 0.3 - lum;
      scores[c]!.addScore('Luminance', 1 - luminanceDeviation);

      // score on Saturation
      final sat = hsl.saturation;
      scores[c]!.addScore(
          'Saturation', sat > 0.5 && hsl.lightness > 0.15 ? sat : 0, 0.5);

      // score on closness to desired lightness
      final light = hsl.lightness;
      final lightnessDeviation = light > 0.4 ? light - 0.4 : 0.4 - light;
      scores[c]!.addScore(
          'Lightness', light < 0.2 || light > 0.9 ? 0 : 1 - lightnessDeviation);

      // Calculating relativey contrast to white
      final contrastRatio = ColorRgb.contrastRatioFromLuminance(1.0, lum);
      print('${scores[c]!.color} contrast ratio: $contrastRatio');
      final desiredContrast = 9;
      final contrastScore = contrastRatio < 3.5
          ? 0.0
          : (contrastRatio > desiredContrast
              ? 1.0
              : ((contrastRatio - 3.5) / (desiredContrast - 3.5)));
      scores[c]!.addScore('Contrast ratio', contrastScore);
    }

    final sorted = scores.values.toList()
      ..sort((c1, c2) => c2.score.compareTo(c1.score));

    for (var s in sorted) {
      print(s);
    }
    return sorted;
  }
}
