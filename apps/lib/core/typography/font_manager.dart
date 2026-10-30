import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/settings/domain/entities/app_font_family.dart';
import '../theme/clay_colors.dart';

/// Multi-Font Switcher Engine.
/// Dynamically provides typography bindings for the 6 official fonts with transparent caching.
abstract final class FontManager {
  /// Test hook to bypass GoogleFonts HTTP download in unit/widget test environments.
  @visibleForTesting
  static bool useTestFallback = false;

  /// Generates a complete Material 3 TextTheme mapped to the selected AppFontFamily.
  static TextTheme getTextTheme({
    required AppFontFamily font,
    Color defaultColor = ClayColors.onSurface,
  }) {
    if (useTestFallback) {
      return TextTheme(
        bodyLarge: TextStyle(color: defaultColor, fontFamily: font.displayName),
        bodyMedium: TextStyle(color: defaultColor, fontFamily: font.displayName),
        bodySmall: TextStyle(color: defaultColor, fontFamily: font.displayName),
        displayLarge: TextStyle(color: defaultColor, fontFamily: font.displayName),
        displayMedium: TextStyle(color: defaultColor, fontFamily: font.displayName),
        displaySmall: TextStyle(color: defaultColor, fontFamily: font.displayName),
        headlineLarge: TextStyle(color: defaultColor, fontFamily: font.displayName),
        headlineMedium: TextStyle(color: defaultColor, fontFamily: font.displayName),
        headlineSmall: TextStyle(color: defaultColor, fontFamily: font.displayName),
        labelLarge: TextStyle(color: defaultColor, fontFamily: font.displayName),
        labelMedium: TextStyle(color: defaultColor, fontFamily: font.displayName),
        labelSmall: TextStyle(color: defaultColor, fontFamily: font.displayName),
        titleLarge: TextStyle(color: defaultColor, fontFamily: font.displayName),
        titleMedium: TextStyle(color: defaultColor, fontFamily: font.displayName),
        titleSmall: TextStyle(color: defaultColor, fontFamily: font.displayName),
      );
    }

    final baseTheme = TextTheme(
      bodyLarge: TextStyle(color: defaultColor),
      bodyMedium: TextStyle(color: defaultColor),
      bodySmall: TextStyle(color: defaultColor),
      displayLarge: TextStyle(color: defaultColor),
      displayMedium: TextStyle(color: defaultColor),
      displaySmall: TextStyle(color: defaultColor),
      headlineLarge: TextStyle(color: defaultColor),
      headlineMedium: TextStyle(color: defaultColor),
      headlineSmall: TextStyle(color: defaultColor),
      labelLarge: TextStyle(color: defaultColor),
      labelMedium: TextStyle(color: defaultColor),
      labelSmall: TextStyle(color: defaultColor),
      titleLarge: TextStyle(color: defaultColor),
      titleMedium: TextStyle(color: defaultColor),
      titleSmall: TextStyle(color: defaultColor),
    );

    switch (font) {
      case AppFontFamily.nunitoSans:
        return GoogleFonts.nunitoSansTextTheme(baseTheme);
      case AppFontFamily.inter:
        return GoogleFonts.interTextTheme(baseTheme);
      case AppFontFamily.poppins:
        return GoogleFonts.poppinsTextTheme(baseTheme);
      case AppFontFamily.ubuntu:
        return GoogleFonts.ubuntuTextTheme(baseTheme);
      case AppFontFamily.changaOne:
        return GoogleFonts.changaOneTextTheme(baseTheme);
      case AppFontFamily.tiny5:
        return GoogleFonts.tiny5TextTheme(baseTheme);
    }
  }

  /// Single TextStyle helper for ad-hoc custom widgets.
  static TextStyle getTextStyle({
    required AppFontFamily font,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    if (useTestFallback) {
      return TextStyle(
        fontFamily: font.displayName,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    switch (font) {
      case AppFontFamily.nunitoSans:
        return GoogleFonts.nunitoSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      case AppFontFamily.inter:
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      case AppFontFamily.poppins:
        return GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      case AppFontFamily.ubuntu:
        return GoogleFonts.ubuntu(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      case AppFontFamily.changaOne:
        return GoogleFonts.changaOne(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
      case AppFontFamily.tiny5:
        return GoogleFonts.tiny5(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );
    }
  }
}
