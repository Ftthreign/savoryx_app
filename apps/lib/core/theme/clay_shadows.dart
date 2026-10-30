import 'package:flutter/material.dart';
import 'clay_colors.dart';

/// Claymorphism Dual-Shadow Physics Calculator.
/// Produces the signature soft, squishy tactile depth seen across Stitch screens.
abstract final class ClayShadows {
  /// Standard elevated resting shadows for cards, pills and buttons.
  static List<BoxShadow> elevated({
    bool isDark = false,
    double scale = 1.0,
    Color? customDarkColor,
    Color? customLightColor,
  }) {
    if (isDark) {
      return [
        BoxShadow(
          offset: Offset(6.0 * scale, 8.0 * scale),
          blurRadius: 16.0 * scale,
          color: customDarkColor ?? ClayColors.shadowDarkDark,
        ),
        BoxShadow(
          offset: Offset(-6.0 * scale, -6.0 * scale),
          blurRadius: 14.0 * scale,
          color: customLightColor ?? ClayColors.shadowLightDark,
        ),
      ];
    }

    return [
      BoxShadow(
        offset: Offset(8.0 * scale, 10.0 * scale),
        blurRadius: 18.0 * scale,
        color: customDarkColor ?? ClayColors.shadowDark,
      ),
      BoxShadow(
        offset: Offset(-8.0 * scale, -8.0 * scale),
        blurRadius: 16.0 * scale,
        color: customLightColor ?? ClayColors.shadowLight,
      ),
    ];
  }

  /// Pressed / Inset cavity shadows simulating depth compression.
  static List<BoxShadow> pressed({
    bool isDark = false,
    double scale = 1.0,
    Color? customDarkColor,
    Color? customLightColor,
  }) {
    if (isDark) {
      return [
        BoxShadow(
          offset: Offset(3.0 * scale, 3.0 * scale),
          blurRadius: 6.0 * scale,
          color: customDarkColor ?? ClayColors.shadowDarkDarkInset,
        ),
        BoxShadow(
          offset: Offset(-3.0 * scale, -3.0 * scale),
          blurRadius: 6.0 * scale,
          color: customLightColor ?? ClayColors.shadowLightDarkInset,
        ),
      ];
    }

    return [
      BoxShadow(
        offset: Offset(3.0 * scale, 3.0 * scale),
        blurRadius: 6.0 * scale,
        color: customDarkColor ?? ClayColors.shadowDarkInset,
      ),
      BoxShadow(
        offset: Offset(-3.0 * scale, -3.0 * scale),
        blurRadius: 6.0 * scale,
        color: customLightColor ?? ClayColors.shadowLightInset,
      ),
    ];
  }

  /// Prominent Hero Card dual-shadow (Safe-to-Spend runway card).
  static List<BoxShadow> heroCard({bool isDark = false}) {
    if (isDark) {
      return [
        const BoxShadow(
          offset: Offset(10.0, 12.0),
          blurRadius: 20.0,
          color: Color.fromRGBO(0, 0, 0, 0.70),
        ),
        const BoxShadow(
          offset: Offset(-6.0, -6.0),
          blurRadius: 16.0,
          color: Color.fromRGBO(60, 68, 86, 0.35),
        ),
      ];
    }

    return const [
      BoxShadow(
        offset: Offset(12.0, 14.0),
        blurRadius: 24.0,
        color: Color.fromRGBO(163, 177, 198, 0.65),
      ),
      BoxShadow(
        offset: Offset(-10.0, -10.0),
        blurRadius: 20.0,
        color: Color.fromRGBO(255, 255, 255, 0.95),
      ),
    ];
  }

  /// Specialized Primary CTA button glow + bevel shadow.
  static List<BoxShadow> primaryCta({bool isPressed = false}) {
    if (isPressed) {
      return const [
        BoxShadow(
          offset: Offset(4.0, 4.0),
          blurRadius: 8.0,
          color: Color.fromRGBO(120, 0, 0, 0.60),
        ),
        BoxShadow(
          offset: Offset(-3.0, -3.0),
          blurRadius: 6.0,
          color: Color.fromRGBO(255, 255, 255, 0.25),
        ),
      ];
    }

    return const [
      BoxShadow(
        offset: Offset(0.0, 10.0),
        blurRadius: 20.0,
        color: Color.fromRGBO(217, 0, 0, 0.40),
      ),
      BoxShadow(
        offset: Offset(6.0, 6.0),
        blurRadius: 12.0,
        color: Color.fromRGBO(163, 177, 198, 0.45),
      ),
      BoxShadow(
        offset: Offset(-4.0, -4.0),
        blurRadius: 10.0,
        color: Color.fromRGBO(255, 255, 255, 0.40),
      ),
    ];
  }

  /// Subtle specular reflection gradient across clay surfaces.
  static const LinearGradient specularReflectionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromRGBO(255, 255, 255, 0.38),
      Color.fromRGBO(255, 255, 255, 0.0),
      Color.fromRGBO(0, 0, 0, 0.04),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
