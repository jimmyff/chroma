// import 'package:test/test.dart';
// import 'package:logging/logging.dart';

// import '../lib/chroma.dart';

// /// number tolerance
// const double delta = 0.05;

// RgbColor hotPinkRgb() => new RgbColor(255.0, 105.0, 180.0);

// void main() {
//   Logger.root.level = Level.ALL;
//   Logger.root.onRecord.listen((LogRecord rec) {
//     print('${rec.level.name}: ${rec.time}: ${rec.message}');
//   });

//   group('Constructors', () {
//     test('RgbColor', () {
//       final RgbColor color = new RgbColor(192.0, 255.0, 238.0);
//       expect(color is Color, isTrue);
//       expect(color.red, closeTo(192.0, delta));
//       expect(color.green, closeTo(255.0, delta));
//       expect(color.blue, closeTo(238.0, delta));
//       expect(color.alpha, closeTo(255.0, delta));
//     });

//     test('RgbColor (from ints)', () {
//       final RgbColor color = new RgbColor.fromInts(192, 255, 238);
//       expect(color is Color, isTrue);
//       expect(color.red, closeTo(192.0, delta));
//       expect(color.green, closeTo(255.0, delta));
//       expect(color.blue, closeTo(238.0, delta));
//       expect(color.alpha, closeTo(255.0, delta));
//     });

//     test('HslColor', () {
//       final HslColor color = new HslColor(163.81, 100.0, 87.65);
//       expect(color is Color, isTrue);
//       expect(color.hue, closeTo(163.81, delta));
//       expect(color.saturation, closeTo(100.0, delta));
//       expect(color.lightness, closeTo(87.65, delta));
//       expect(color.alpha, closeTo(100.0, delta));
//     });

//     test('HslColor', () {
//       final HsvColor color = new HsvColor(330.0, 58.82, 100.0);
//       expect(color is Color, isTrue);
//       expect(color.hue, closeTo(330.0, delta));
//       expect(color.saturation, closeTo(58.82, delta));
//       expect(color.value, closeTo(100.0, delta));
//       expect(color.alpha, closeTo(100.0, delta));
//     });
//   });

//   group('Manipulattion', () {
//     test('hsl->hue', () {
//       final HslColor wrap = new HslColor(270.0, 100.0, 50.0)..hue += 100;
//       expect(wrap.hue, closeTo(10.0, delta));
//       final HslColor color = new HslColor(270.0, 100.0, 50.0)..hue = 123.0;
//       expect(color.hue, closeTo(123, delta));
//     });
//     test('hsl->saturation', () {
//       final HslColor max = new HslColor(270.0, 80.0, 50.0)..saturation += 100;
//       expect(max.saturation, closeTo(100.0, delta));
//       final HslColor min = new HslColor(270.0, 30.0, 50.0)..saturation -= 100;
//       expect(min.saturation, closeTo(0.0, delta));
//       final HslColor color = new HslColor(270.0, 30.0, 50.0)..saturation = 40.0;
//       expect(color.saturation, closeTo(40.0, delta));
//     });
//     test('hsl->lightness', () {
//       final HslColor max = new HslColor(270.0, 80.0, 50.0)..lightness += 100;
//       expect(max.lightness, closeTo(100.0, delta));
//       final HslColor min = new HslColor(270.0, 30.0, 50.0)..lightness -= 100;
//       expect(min.lightness, closeTo(0.0, delta));
//       final HslColor color = new HslColor(270.0, 30.0, 50.0)..lightness = 40.0;
//       expect(color.lightness, closeTo(40.0, delta));
//     });
//     test('hsl->alpha', () {
//       final HslColor max = new HslColor(270.0, 80.0, 50.0)..alpha += 100;
//       expect(max.alpha, closeTo(100.0, delta));
//       final HslColor min = new HslColor(270.0, 30.0, 50.0)..alpha -= 100;
//       expect(min.alpha, closeTo(0.0, delta));
//       final HslColor color = new HslColor(270.0, 30.0, 50.0)..alpha = 40.0;
//       expect(color.alpha, closeTo(40.0, delta));
//     });

//     test('rgb->red', () {
//       final RgbColor max = hotPinkRgb()..red += 300;
//       expect(max.red, closeTo(255.0, delta));
//       final RgbColor min = hotPinkRgb()..red -= 300;
//       expect(min.red, closeTo(0.0, delta));
//       final RgbColor color = hotPinkRgb()..red -= 10.0;
//       expect(color.red, closeTo(245.0, delta));
//     });
//     test('rgb->green', () {
//       final RgbColor max = hotPinkRgb()..green += 300;
//       expect(max.green, closeTo(255.0, delta));
//       final RgbColor min = hotPinkRgb()..green -= 300;
//       expect(min.green, closeTo(0.0, delta));
//       final RgbColor color = hotPinkRgb()..green += 10.0;
//       expect(color.green, closeTo(115.0, delta));
//     });
//     test('rgb->blue', () {
//       final RgbColor max = hotPinkRgb()..blue += 300;
//       expect(max.blue, closeTo(255.0, delta));
//       final RgbColor min = hotPinkRgb()..blue -= 300;
//       expect(min.blue, closeTo(0.0, delta));
//       final RgbColor color = hotPinkRgb()..blue -= 10.0;
//       expect(color.blue, closeTo(170.0, delta));
//     });
//     test('rgb->alpha', () {
//       final RgbColor max = hotPinkRgb()..alpha += 500;
//       expect(max.alpha, closeTo(255.0, delta));
//       final RgbColor min = hotPinkRgb()..alpha -= 500;
//       expect(min.alpha, closeTo(0.0, delta));
//       final RgbColor color = hotPinkRgb()..alpha = 127.5;
//       expect(color.alpha, closeTo(127.5, delta));
//       expect(color.alphaAsFraction, closeTo(0.5, delta));
//       expect(color.alphaAsPercent, closeTo(50.0, delta));
//     });
//   });

//   group("Conversions", () {
//     RgbColor rgb;
//     HslColor hsl;
//     HsvColor hsv;
//     setUp(() {
//       rgb = new RgbColor(255.0, 105.0, 180.0);
//       hsl = new HslColor(330.0, 100.0, 70.59);
//       hsv = new HsvColor(330.0, 58.82, 100.0);
//     });

//     // RGB conversions
//     test("rgb->hsl", () {
//       final HslColor conversion = rgb.toHsl();
//       expect(conversion.hue, closeTo(hsl.hue, delta));
//       expect(conversion.saturation, closeTo(hsl.saturation, delta));
//       expect(conversion.lightness, closeTo(hsl.lightness, delta));
//       expect(conversion.alpha, closeTo(100.0, delta));
//     });
//     test("rgb->hsv", () {
//       final HsvColor conversion = rgb.toHsv();
//       expect(conversion.hue, closeTo(hsv.hue, delta));
//       expect(conversion.saturation, closeTo(hsv.saturation, delta));
//       expect(conversion.value, closeTo(hsv.value, delta));
//       expect(conversion.alpha, closeTo(100.0, delta));
//     });
//     test("rgb->hsl->rgb", () {
//       final RgbColor conversion = rgb.toHsl().toRgb();
//       expect(conversion.red, closeTo(rgb.red, delta));
//       expect(conversion.green, closeTo(rgb.green, delta));
//       expect(conversion.blue, closeTo(rgb.blue, delta));
//       expect(conversion.alpha, closeTo(255.0, delta));
//     });

//     // HSL conversions
//     test("hsl->rgb", () {
//       final RgbColor conversion = hsl.toRgb();
//       expect(conversion.red, closeTo(rgb.red, delta));
//       expect(conversion.green, closeTo(rgb.green, delta));
//       expect(conversion.blue, closeTo(rgb.blue, delta));
//       expect(conversion.alpha, closeTo(255.0, delta));
//     });
//     test("hsl->hsv", () {
//       final HslColor conversion = hsv.toHsl();
//       expect(conversion.hue, closeTo(hsl.hue, delta));
//       expect(conversion.saturation, closeTo(hsl.saturation, delta));
//       expect(conversion.lightness, closeTo(hsl.lightness, delta));
//       expect(conversion.alpha, closeTo(100.0, delta));
//     });

//     // HSV conversions
//     test("hsv->hsl", () {
//       final HslColor conversion = hsl.toHsl();
//       expect(conversion.hue, closeTo(hsl.hue, delta));
//       expect(conversion.saturation, closeTo(hsl.saturation, delta));
//       expect(conversion.lightness, closeTo(hsl.lightness, delta));
//       expect(conversion.alpha, closeTo(100.0, delta));
//     });
//     test("hsv->rgb", () {
//       final RgbColor conversion = hsv.toRgb();
//       expect(conversion.red, closeTo(rgb.red, delta));
//       expect(conversion.green, closeTo(rgb.green, delta));
//       expect(conversion.blue, closeTo(rgb.blue, delta));
//       expect(conversion.alpha, closeTo(255.0, delta));
//     });
//   });
// }
