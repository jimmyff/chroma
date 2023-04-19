import 'dart:math';
import 'package:chroma/color.dart';
import 'package:logging/logging.dart';

final log = Logger('CHROMA/PALETTE');

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
  static bool isHueBrownOrRed(hue) => hue > 352 || hue < 38;

  /// [colors] should be provided in order of dominance/priority
  static List<List<ColorRgb>> optionsFrom(List<ColorRgb> colors,
      {int options = 3, bool boostColors = true}) {
    log.fine('Finding options for colors $colors');
    // Score the colors
    var _scored = Palette.scoreColors(colors, boostColors);
    _scored = _scored.length > 3
        ? _scored
        : Palette.scoreColors(colors, boostColors, true);

    // if we have no colours. create some choices.
    if (_scored.isEmpty) {
      _scored = Palette.scoreColors([
        ColorRgb(Random().nextDouble(), Random().nextDouble(),
            Random().nextDouble()),
        ColorRgb(Random().nextDouble(), Random().nextDouble(),
            Random().nextDouble()),
        ColorRgb(Random().nextDouble(), Random().nextDouble(),
            Random().nextDouble()),
        ColorRgb(Random().nextDouble(), Random().nextDouble(),
            Random().nextDouble()),
        ColorRgb(0.5, 0.5, 0.5),
      ], true, true);
    }

    final scored = _scored;

    log.fine('scored colours: $scored');

    // find dominants
    Map<ColorScore, List<ColorScore>> initialDominantColors = {};

    for (final c in scored) {
      final hsl = c.colorHsl;

      // make sure we don't have a dominant colour too similar
      final matchingDoms = initialDominantColors.keys
          .where((d) =>
              ColorHsl.hueDistance(d.colorHsl, hsl) < (360 / 24) &&
              (d.colorHsl.saturation > hsl.saturation
                      ? d.colorHsl.saturation - hsl.saturation
                      : hsl.saturation - d.colorHsl.saturation) <
                  0.3)
          .toList();
      if (matchingDoms.isNotEmpty)
        log.fine('stripped: $hsl as too similar to ${matchingDoms.first}');
      if (matchingDoms.isNotEmpty) continue;

      initialDominantColors[c] = [];
      if (initialDominantColors.length >= options) break;
    }

    log.fine('Doms: ${initialDominantColors.keys.toList()}');

    // Give browns and reds less dominance
    final sortedDoms = initialDominantColors.keys.toList()
      ..sort((a, b) {
        log.info('a.colorHsl.hue: ${a.colorHsl.hue} a.score: ${a.score}');
        log.info('b.colorHsl.hue: ${b.colorHsl.hue} b.score: ${b.score}');
        final aScore =
            a.score + (Palette.isHueBrownOrRed(a.colorHsl.hue) ? -2 : 0);
        final bScore =
            b.score + (Palette.isHueBrownOrRed(b.colorHsl.hue) ? -2 : 0);
        return bScore.compareTo(aScore);
      });
    log.fine('scored and altered doms: $sortedDoms');

    Map<ColorScore, List<ColorScore>> dominantColors = {};
    for (var d in sortedDoms) {
      dominantColors[d] = initialDominantColors[d]!;
    }

    // find complimentarys
    List<ColorScore> complimentaries = [];

    for (final c in scored) {
      final hsl = c.colorHsl;

      // strip out colours that are too similar
      final matching = complimentaries
          .where((d) => ColorHsl.hueDistance(d.colorHsl, hsl) < (360 / 24)
              // &&
              // (d.colorHsl.saturation > hsl.saturation
              //         ? d.colorHsl.saturation - hsl.saturation
              //         : d.colorHsl.saturation - hsl.saturation) <
              //     -0.3
              )
          .toList();
      if (matching.isNotEmpty) {
        log.fine('dom: $hsl : removing ${c.colorHsl} as too similar');
        continue;
      }
      complimentaries.add(c);
    }
    log.fine('complimentaries: $complimentaries');

    // // Find most complimentayyry color for each dominant
    for (final d in dominantColors.keys) {
      log.fine('Finding complimentary ${d.color}');
      Map<ColorScore, double> hueDistance = {};

      final Map<int, double> idealDistancesAndScores = {
        180: 1.0, // complimentary
        120: 0.9, // tradic
        110: 0.9, // split complientary
        30: 0.7, // analogous
      };

      for (final c in complimentaries) {
        if (c.colorHsl.hue == d.colorHsl.hue) {
          hueDistance[c] = 0;
          continue;
        }
        final dist = ColorHsl.hueDistance(d.colorHsl, c.colorHsl);

        log.fine('${c.color} dist: $dist');
        idealDistancesAndScores.forEach((idealDist, scoreWeight) {
          final distToIdeal =
              (idealDist > dist ? (idealDist - dist) : (dist - idealDist));
          double score = ((180 - distToIdeal) * scoreWeight) + (c._score * 3);

          // If this is the highest for this then set it
          if (score > (hueDistance[c] ??= 0)) {
            hueDistance[c] = score;
          }
        });
      }
      log.fine('hue distances for ${d.colorHsl}');
      log.fine(hueDistance);
      final complimentary = complimentaries
          .where(
              (c) => hueDistance[c]! > (360 / 5) && c.colorHsl.lightness > 0.1)
          .toList()
        ..sort((c1, c2) => hueDistance[c2]!.compareTo(hueDistance[c1]!));
      dominantColors[d] = complimentary.take(options).toList();

      log.fine('complimentaries for ${d.colorHsl} : ${dominantColors[d]}');
    }

    // Add a perfect complimentary to each as a fallback

    for (final d in dominantColors.keys) {
      // Fallback
      if (dominantColors[d]!.isEmpty || dominantColors.keys.length == 1) {
        dominantColors[d]!

              // Complimentary color
              ..add(ColorScore(ColorRgb.fromHex(
                  ColorHsl((d.colorHsl.hue + 180) % 360, 0.3, 0.5).toHex())))

              // Triadic color
              ..add(ColorScore(ColorRgb.fromHex(
                  ColorHsl((d.colorHsl.hue + 120) % 360, 0.3, 0.5).toHex())))

              // Triadic color
              ..add(ColorScore(ColorRgb.fromHex(
                  ColorHsl((d.colorHsl.hue + 240) % 360, 0.3, 0.5).toHex())))

              // Split complimentary
              ..add(ColorScore(ColorRgb.fromHex(
                  ColorHsl((d.colorHsl.hue + 210) % 360, 0.3, 0.5).toHex())))

              // Split complimentary
              ..add(ColorScore(ColorRgb.fromHex(
                  ColorHsl((d.colorHsl.hue + 140) % 360, 0.3, 0.5).toHex())))

              // Analogous
              ..add(ColorScore(ColorRgb.fromHex(
                  ColorHsl((d.colorHsl.hue + 30) % 360, 0.3, 0.5).toHex())))

              // Analogous
              ..add(ColorScore(ColorRgb.fromHex(
                  ColorHsl((d.colorHsl.hue - 30) % 360, 0.3, 0.5).toHex())))
            //
            ;
      }
    }

    log.fine('Dominant colors & complimentary: ');
    log.fine(
        dominantColors.keys.map((d) => '${d.color} : ${dominantColors[d]}'));

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

    log.fine('paletteOptions: ');
    log.fine(paletteOptions.map((d) => '$d'));

    Map<ColorRgb, ColorRgb> tunedColours = {};
    List<List<ColorRgb>> tunedPalette = [];
    final desiredContrastRatio = 5.4;

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

    log.fine('tunedPalette: ');
    log.fine(tunedPalette.map((d) => '$d'));

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
    final desiredMinSaturation = 0.17;

    var boostedColor = color.toHsl();

    // sat
    if (boostedColor.saturation < desiredMinSaturation)
      boostedColor = ColorHsl(
          boostedColor.hue, desiredMinSaturation, boostedColor.lightness);

    return boostedColor;
  }

  /// [colors] should be provided in order of dominance/priority
  static List<ColorScore> scoreColors(List<ColorRgb> colors, bool boostVibrancy,
      [bool alterColours = false]) {
    Map<ColorRgb, ColorScore> scores = {};

    // score the colours on priority
    var i = 0;

    for (final c in colors) {
      var color = c.toHsl();

      log.fine('Scoring color $c');
      // strip out the really dark colours
      // if (color.luminance < 0.05) continue;
      if (!alterColours && color.saturation < 0.02) continue;
      // // strip out the whites
      if (color.lightness > 0.8) continue;
      if (color.lightness < 0.15) continue;

      var boostedSaturation = false;
      var alteredColour = false;

      if (alterColours) {
        final hueBoost = Palette.boostColorHue(color);
        alteredColour = (color.toInt() != hueBoost.toInt());

        color = hueBoost;
      }
      if (boostVibrancy) {
        final satBoost = Palette.boostColorSaturation(color);
        boostedSaturation = (color.toInt() != satBoost.toInt());

        color = satBoost;
      }
      log.fine('Boosted: $c became $color');

      var score = ColorScore(color);

      scores[c] = score
        ..addScore('Boosted',
            (boostedSaturation ? -0.7 : 0) + (alteredColour ? -1.5 : 0))
        ..addScore(
            'Dominance/Priority', (1 - (i++ * (1 / colors.length))), 1.5);
    }

    log.fine('Scored: ${scores.length} options');

    // General scoring
    for (final c in scores.keys) {
      final hsl = c.toHsl();

      // score on closness to desired luminosity
      final lum = c.luminance;
      log.fine('${scores[c]!.color} with lum: $lum');
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
      log.fine('${scores[c]!.color} contrast ratio: $contrastRatio');
      final desiredContrast = 6;
      final contrastScore = contrastRatio < 3.5
          ? 0.0
          : (contrastRatio > desiredContrast
              ? 1.0
              : ((contrastRatio - 3.5) / (desiredContrast - 3.5)));
      scores[c]!.addScore('Contrast ratio', contrastScore);
    }

    final sorted = scores.values.toList()
      ..sort((c1, c2) => c2.score.compareTo(c1.score));

    log.fine('--- Scored colours ---');
    for (var s in sorted) {
      log.fine(s);
    }
    log.fine('--- /Scored colours ---');
    return sorted;
  }
}
