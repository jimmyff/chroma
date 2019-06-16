class IntRange {
  final int from;
  final int to;
  const IntRange(this.from, this.to);
}

enum Model { LAB }

class ColorSpace {
  final String name;
  @IntRange(ColorSpace.MIN_ID, ColorSpace.MAX_ID)
  final int id;
  final Model model;

  const ColorSpace(this.name, this.model, this.id);

  /**
     * The minimum ID value a color space can have.
     *
     * @see #getId()
     */
  static const int MIN_ID = -1; // Do not change
  /**
     * The maximum ID value a color space can have.
     *
     * @see #getId()
     */
  static const int MAX_ID = 63; // Do not change, used to encode in longs
}

class Lab extends ColorSpace {
  static final double A = 216.0 / 24389.0;
  static final double B = 841.0 / 108.0;
  static final double C = 4.0 / 29.0;
  static final double D = 6.0 / 29.0;

  // @NonNull
  //
  const Lab(String name, @IntRange(ColorSpace.MIN_ID, ColorSpace.MAX_ID) int id)
      : super(name, Model.LAB, id);

  @override
  bool isWideGamut() {
    return true;
  }

  @override
  double getMinValue(@IntRange(0, 3) int component) {
    return component == 0 ? 0.0 : -128.0;
  }

  @override
  double getMaxValue(@IntRange(0, 3) int component) {
    return component == 0 ? 100.0 : 128.0;
  }
}
