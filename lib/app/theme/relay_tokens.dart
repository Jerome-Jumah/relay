abstract final class RelaySpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

abstract final class RelayRadius {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const full = 999.0;
}

abstract final class RelaySizes {
  static const minimumTouchTarget = 48.0;
  static const callControl = 64.0;
  static const callControlSmall = 48.0;
  static const callControlLarge = 76.0;
}

abstract final class RelayDuration {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
}
