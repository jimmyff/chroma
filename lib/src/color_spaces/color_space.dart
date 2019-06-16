library chroma.color_space;

enum Named {
  SRGB,
  LINEAR_SRGB,
  EXTENDED_SRGB,
  LINEAR_EXTENDED_SRGB,
  BT709,
  BT2020,
  DCI_P3,
  DISPLAY_P3,
  NTSC_1953,
  SMPTE_C,
  ADOBE_RGB,
  PRO_PHOTO_RGB,
  ACES,
  ACESCG,
  CIE_XYZ,
  CIE_LAB
}
ColorSpace sRgb = ColorSpace.get(ColorSpace.Named.SRGB);

abstract class ColorSpace {
  const ColorSpace();
}

class SRgbColorSpace extends ColorSpace {
  const SRgbColorSpace();
}
