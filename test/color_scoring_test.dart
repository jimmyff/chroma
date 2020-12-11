import 'package:test/test.dart';
import 'package:logging/logging.dart';

import '../lib/src/image_palette.dart';
import 'package:image/image.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  group('Constructors', () {
    final colors = ScoredColors.fromColors([
      Color.fromRgb(255, 255, 255),
      Color.fromRgb(0, 0, 0),
      Color.fromRgb(127, 127, 127),
      Color.fromRgb(255, 0, 0),
      Color.fromRgb(180, 150, 150),
      Color.fromRgb(0, 150, 150),
      Color.fromRgb(180, 180, 180),
      Color.fromRgb(83, 250, 0),
      Color.fromRgb(209, 71, 71),
    ]);

    test('Score based on luminosity', () {
      final scored = colors.scoreLuminosity(1);
      // print(scored.colors);
      final scores = scored.colors.values.toList();
      expect(scores[0], equals(100.0));
      expect(scores[1], equals(0));

      // should be 127.5
      expect(scores[2], greaterThan(49));
      expect(scores[2], lessThan(50));
    });
    test('Score based on saturation', () {
      final scored = colors.scoreSaturation(1);
      // print(scored.colors);
      final scores = scored.colors.values.toList();
      expect(scores[3], equals(100.0));
      expect(scores[8], equals(60.0));
    });
  });
}
