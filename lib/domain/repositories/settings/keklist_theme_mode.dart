enum KeklistThemeMode {
  light,
  dark,
  system;

  static KeklistThemeMode fromIndex(int index) =>
      index >= 0 && index < values.length ? values[index] : system;
}
