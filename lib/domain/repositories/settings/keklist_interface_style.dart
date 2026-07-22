enum KeklistInterfaceStyle {
  material,
  liquidGlass;

  static KeklistInterfaceStyle fromIndex(int index) =>
      index >= 0 && index < values.length ? values[index] : liquidGlass;
}
