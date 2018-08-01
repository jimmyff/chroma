# Chroma

[![Build Status](https://travis-ci.org/jimmyff/chroma.svg?branch=master)]((https://travis-ci.org/jimmyff/chroma))
[![Pub Package Version](https://img.shields.io/pub/v/chroma.svg)](https://pub.dartlang.org/packages/chroma)
[![Latest Dartdocs](https://img.shields.io/badge/dartdocs-latest-blue.svg)](https://pub.dartlang.org/documentation/chroma/latest)

A simple library for manipulating colors in Dart.

## Color model classes

- RgbColor
- HslColor
- HsvColor

## Usage

### Basic use

```dart
final hotPink = new RgbColor(255.0, 105.0, 180.0);

// find the complementary color then convert back to RGB
final complimentary = (hotPink.toHsl()..hue -= 180).toRgb();


// Create from Hex
final seaFoamGreen = new RgbColor.fromHex('#71EEB8');
```

### Conversions

```dart
final hsl = hotPink.toHsl();
final hsv = hotPink.toHsv();
```

### Output to Hex or CSS strings

```dart
print ("The CSS string for hot pink is ${hotPink.toCss()}");
print ("The Hex string for hot pink is ${hotPink.toHex()}");
```

### Color mixing: Addition & subtraction

```dart
// Addition
final red = new RgbColor(255.0, 0.0, 0.0);
final blue = new RgbColor(0.0, 0.0, 255.0);
final magenta = red + blue;

// Subtraction
final green = new RgbColor(0.0, 255.0, 0.0);
final white = magenta + green;
final yellow = white - blue;
```