/// Official theme mode supported across Savoryx OS.
enum AppThemeMode {
  clayLight,
  clayDark,
  oledBlack;

  String get displayName {
    switch (this) {
      case AppThemeMode.clayLight:
        return 'Clay Light';
      case AppThemeMode.clayDark:
        return 'Clay Dark';
      case AppThemeMode.oledBlack:
        return 'OLED Pure Black';
    }
  }

  bool get isDark =>
      this == AppThemeMode.clayDark || this == AppThemeMode.oledBlack;

  bool get isOled => this == AppThemeMode.oledBlack;
}
