/// Application-wide constants.
abstract final class AppConstants {
  static const String appName = 'Savoryx';
  static const String appVersion = '1.0.0';
  static const String defaultCurrency = 'IDR';

  static const int targetLaunchTimeMs = 500;
  static const double targetMaxApkSizeMb = 9.5;

  // Claymorphism Radius Tokens (Stitch Spec)
  static const double clayRadiusSm = 16.0;
  static const double clayBorderRadius = 20.0;
  static const double clayCardBorderRadius = 24.0;
  static const double clayCarouselRadius = 26.0;
  static const double clayHeroCardBorderRadius = 28.0;
  static const double clayPillRadius = 9999.0;

  // Claymorphism Tactile Physics & Animation
  static const int clayPressAnimationDurationMs = 120;
  static const double clayPressedScale = 0.96;

  // Masking token for privacy shield toggle
  static const String privacyMask = '••••••••';
}
