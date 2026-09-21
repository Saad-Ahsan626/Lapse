abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double screen = 22;
}

abstract final class Radii {
  static const double badge = 8;
  static const double chipSmall = 9;
  static const double chip = 11;
  static const double sm = 12;
  static const double control = 14;
  static const double md = 16;
  static const double card = 18;
  static const double lg = 20;
  static const double hero = 22;
  static const double xl = 24;
  static const double sheet = 28;
  static const double pill = 999;

  static double tile(double size) => size * 0.3;
}

abstract final class Sizes {
  static const double button = 48;
  static const double chip = 36;
  static const double chipSmall = 30;
  static const double badge = 26;
  static const double input = 53;
  static const double fab = 56;
  static const double minTap = 48;
  static const double iconButton = 44;
  static const double serviceTile = 44;
}
