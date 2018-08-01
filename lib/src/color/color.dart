library color;

import 'package:vector_math/vector_math.dart' as v;
import 'package:logging/logging.dart';

part '_mixins.dart';

part 'rgb_color.dart';
part 'hsl_color.dart';
part 'hsv_color.dart';

final Logger _log = new Logger('chroma.colors');

abstract class Color {
  final v.Vector4 _v = v.Vector4.zero();
  v.Vector4 get vector4 => _v;
  String toHex({bool hash = true, bool alpha = false, bool short = false});
  @override
  String toString();

  num _bounds(num v, num min, num max) => v > max ? max : v < min ? min : v;
}
