import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/clay_colors.dart';

/// Claymorphism Dual-Shadow & Multi-Layer Physics Calculator.
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
          offset: Offset(-5.0 * scale, -5.0 * scale),
          blurRadius: 12.0 * scale,
          color: customLightColor ?? ClayColors.shadowLightDark,
        ),
      ];
    }

    return [
      // Deep Ambient Drop Shadow (gives clear, unmistakable 3D depth)
      BoxShadow(
        offset: Offset(5.0 * scale, 8.0 * scale),
        blurRadius: 16.0 * scale,
        spreadRadius: 0.0,
        color: customDarkColor ?? ClayColors.shadowDark,
      ),
      // Sharp Contact Shadow (grounds the object to the canvas)
      BoxShadow(
        offset: Offset(0.0, 2.5 * scale),
        blurRadius: 5.0 * scale,
        spreadRadius: 0.0,
        color: ClayColors.shadowContact,
      ),
      // Specular Top-Left Highlight Glow
      BoxShadow(
        offset: Offset(-4.0 * scale, -4.0 * scale),
        blurRadius: 12.0 * scale,
        spreadRadius: 0.0,
        color: customLightColor ?? ClayColors.shadowLight.withOpacity(0.95),
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
      return const [
        BoxShadow(
          offset: Offset(10.0, 12.0),
          blurRadius: 20.0,
          color: Color.fromRGBO(0, 0, 0, 0.70),
        ),
        BoxShadow(
          offset: Offset(-6.0, -6.0),
          blurRadius: 16.0,
          color: Color.fromRGBO(60, 68, 86, 0.35),
        ),
      ];
    }

    return const [
      // Deep Ambient Shadow
      BoxShadow(
        offset: Offset(7.0, 12.0),
        blurRadius: 22.0,
        spreadRadius: 0.0,
        color: Color(0x40334155),
      ),
      // Sharp Contact Shadow
      BoxShadow(
        offset: Offset(0.0, 3.5),
        blurRadius: 7.0,
        spreadRadius: 0.0,
        color: Color(0x260F172A),
      ),
      // Bright Specular Top-Left Glow
      BoxShadow(
        offset: Offset(-6.0, -6.0),
        blurRadius: 14.0,
        spreadRadius: 0.0,
        color: Colors.white,
      ),
    ];
  }

  /// Specialized Primary CTA button glow + bevel shadow.
  static List<BoxShadow> primaryCta({bool isPressed = false}) {
    if (isPressed) {
      return const [
        BoxShadow(
          offset: Offset(3.0, 3.0),
          blurRadius: 6.0,
          color: Color(0x99A00000),
        ),
        BoxShadow(
          offset: Offset(-2.0, -2.0),
          blurRadius: 4.0,
          color: Color(0x66FFFFFF),
        ),
      ];
    }

    return const [
      BoxShadow(
        offset: Offset(0.0, 8.0),
        blurRadius: 16.0,
        spreadRadius: 0.0,
        color: Color(0x66D90000),
      ),
      BoxShadow(
        offset: Offset(3.0, 6.0),
        blurRadius: 10.0,
        spreadRadius: 0.0,
        color: Color(0x33475569),
      ),
      BoxShadow(
        offset: Offset(-3.0, -3.0),
        blurRadius: 8.0,
        spreadRadius: 0.0,
        color: Color(0x80FFFFFF),
      ),
    ];
  }

  /// Subtle specular reflection gradient across clay surfaces.
  static const LinearGradient specularReflectionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromRGBO(255, 255, 255, 0.65),
      Color.fromRGBO(255, 255, 255, 0.0),
      Color.fromRGBO(71, 85, 105, 0.08),
    ],
    stops: [0.0, 0.45, 1.0],
  );
}
