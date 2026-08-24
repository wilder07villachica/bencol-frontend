class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 900;
  static const double medium = 1200;

  static bool isCompact(double width) {
    return width < compact;
  }

  static bool isMedium(double width) {
    return width >= compact && width < medium;
  }

  static bool isLarge(double width) {
    return width >= medium;
  }
}
