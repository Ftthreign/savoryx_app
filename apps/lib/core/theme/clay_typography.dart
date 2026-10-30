import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clay_colors.dart';

/// Official typography tokens and scale using GoogleFonts `Nunito Sans`.
abstract final class ClayTypography {
  static TextStyle headlineXl({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 36,
        height: 44 / 36,
        letterSpacing: -1.44, // -0.04em
        fontWeight: FontWeight.w900,
        color: color,
      );

  static TextStyle headlineXlMobile({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 30,
        height: 36 / 30,
        letterSpacing: -0.9, // -0.03em
        fontWeight: FontWeight.w900,
        color: color,
      );

  static TextStyle headlineLg({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 26,
        height: 32 / 26,
        letterSpacing: -0.52, // -0.02em
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle headlineMd({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 20,
        height: 26 / 20,
        letterSpacing: -0.2, // -0.01em
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle headlineSm({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle bodyLg({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyMd({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bodySm({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle labelLg({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 14,
        height: 18 / 14,
        letterSpacing: 0.28, // 0.02em
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle labelMd({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.36, // 0.03em
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle labelSm({Color color = ClayColors.onSurface}) =>
      GoogleFonts.nunitoSans(
        fontSize: 10,
        height: 14 / 10,
        letterSpacing: 0.4, // 0.04em
        fontWeight: FontWeight.w800,
        color: color,
      );

  /// Builds a complete Material 3 TextTheme mapped to Nunito Sans.
  static TextTheme createTextTheme({Color defaultColor = ClayColors.onSurface}) {
    return TextTheme(
      displayLarge: headlineXl(color: defaultColor),
      displayMedium: headlineXlMobile(color: defaultColor),
      headlineLarge: headlineLg(color: defaultColor),
      headlineMedium: headlineMd(color: defaultColor),
      headlineSmall: headlineSm(color: defaultColor),
      bodyLarge: bodyLg(color: defaultColor),
      bodyMedium: bodyMd(color: defaultColor),
      bodySmall: bodySm(color: defaultColor),
      labelLarge: labelLg(color: defaultColor),
      labelMedium: labelMd(color: defaultColor),
      labelSmall: labelSm(color: defaultColor),
    );
  }
}
