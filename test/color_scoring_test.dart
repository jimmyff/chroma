import 'package:test/test.dart';
import 'package:logging/logging.dart';

import 'package:chroma/color.dart';
import 'package:chroma/palette.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  group('Constructors', () {
    final white = ColorRgb.fromHex('#FFFFFF');
    final black = ColorRgb.fromHex('#000000');
    final colors = [
      white,
      black,
      ColorRgb.fromHex('#FFEE33'),
      ColorRgb.fromHex('#77EE83'),
      ColorRgb.fromHex('#8898A9'),
      ColorRgb.fromHex('#258712'),
      ColorRgb.fromHex('#981235'),
    ];

    test('Luminance', () {
      final whiteLum = white.luminance;
      final blackLum = black.luminance;
      expect(whiteLum, equals(1.0));
      expect(blackLum, equals(0.0));
    });

    test('Contrast ratio', () {
      expect(
          ColorRgb.contrastRatioFromLuminance(white.luminance, black.luminance),
          equals(21.0));
      expect(
          ColorRgb.contrastRatioFromLuminance(
                  ColorRgb(148 / 255, 57 / 255, 173 / 255).luminance,
                  ColorRgb(174 / 255, 84 / 255, 199 / 255).luminance)
              .toStringAsFixed(2),
          equals('1.42'));
    });

    test('Create swatch options', () {
      final swatchOptions = Palette.optionsFrom(colors, options: 10);
      expect(swatchOptions.length, greaterThan(0));
    });
    // test('Score based on saturation', () {
    //   final scored = colors.scoreSaturation(1);
    //   // print(scored.colors);
    //   final scores = scored.colors.values.toList();
    //   expect(scores[3], equals(100.0));
    //   expect(scores[8], equals(60.0));
    // });
  });
}
