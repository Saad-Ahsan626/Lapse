enum AppThemeMode {
  system,
  light,
  dark
  ;

  static AppThemeMode? fromStorage(String? value) =>
      value == null ? null : values.asNameMap()[value];
}
