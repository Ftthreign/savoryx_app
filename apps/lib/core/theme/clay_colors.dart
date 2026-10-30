import 'package:flutter/material.dart';

/// Official color tokens for Savoryx extracted directly from Stitch Design System Spec.
abstract final class ClayColors {
  // --- Primary: Crimson Clay (Expenses & Primary CTA) ---
  static const Color primary = Color(0xFFD90000);
  static const Color primaryDeep = Color(0xFFAB0000);
  static const Color primaryHighlight = Color(0xFFFF3B3B);
  static const Color primaryContainer = Color(0xFFFFE8E5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFFFDAD4);
  static const Color onPrimaryFixed = Color(0xFF410000);

  // --- Secondary: Cream Butter Yellow (Safe-to-Spend Runway & Hero Balance) ---
  static const Color secondary = Color(0xFF6C5E15);
  static const Color secondaryContainer = Color(0xFFF4E08A);
  static const Color secondaryFixed = Color(0xFFF7E28C);
  static const Color onSecondaryContainer = Color(0xFF716219);
  static const Color secondaryRim = Color(0xFFC9A832);
  static const Color secondaryDeep = Color(0xFF8A6500);

  // --- Tertiary: Sage Growth Green (Income, Sinking Funds & Savings) ---
  static const Color tertiary = Color(0xFF3C5C02);
  static const Color tertiaryAccent = Color(0xFF8DB355);
  static const Color tertiaryContainer = Color(0xFF53751E);
  static const Color tertiaryChip = Color(0xFFD1FB93);
  static const Color tertiaryGlint = Color(0xFFB4D97E);
  static const Color tertiaryFixed = Color(0xFFC7F08A);
  static const Color onTertiaryFixed = Color(0xFF111F00);
  static const Color onTertiary = Color(0xFFFFFFFF);

  // --- Error & Alert Tokens ---
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // --- Neutral Canvas & Surfaces: Clay Light Theme ---
  static const Color canvasLight = Color(0xFFF9F9F9);
  static const Color surfaceLight = Color(0xFFF9F9F9);
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1B1B1B);
  static const Color onSurfaceVariant = Color(0xFF5E3F3A);
  static const Color outline = Color(0xFF936E68);
  static const Color outlineVariant = Color(0xFFE9BCB5);

  // --- Neutral Canvas & Surfaces: Clay Dark Theme ---
  static const Color canvasDark = Color(0xFF161821);
  static const Color surfaceDark = Color(0xFF161821);
  static const Color surfaceContainerDarkLow = Color(0xFF1A1D27);
  static const Color surfaceContainerDark = Color(0xFF1E222B);
  static const Color surfaceContainerDarkHigh = Color(0xFF252A36);
  static const Color surfaceContainerDarkLowest = Color(0xFF12141A);
  static const Color onSurfaceDark = Color(0xFFF1F1F1);
  static const Color onSurfaceVariantDark = Color(0xFFA5ACB8);

  // --- OLED Black ---
  static const Color oledBlack = Color(0xFF000000);

  // --- Claymorphism Dual-Shadow Physics (Light Mode) ---
  static const Color shadowDark = Color.fromRGBO(163, 177, 198, 0.55);
  static const Color shadowLight = Color.fromRGBO(255, 255, 255, 0.95);
  static const Color shadowDarkInset = Color.fromRGBO(163, 177, 198, 0.50);
  static const Color shadowLightInset = Color.fromRGBO(255, 255, 255, 0.80);

  // --- Claymorphism Dual-Shadow Physics (Dark Mode) ---
  static const Color shadowDarkDark = Color.fromRGBO(0, 0, 0, 0.65);
  static const Color shadowLightDark = Color.fromRGBO(45, 52, 68, 0.35);
  static const Color shadowDarkDarkInset = Color.fromRGBO(0, 0, 0, 0.75);
  static const Color shadowLightDarkInset = Color.fromRGBO(40, 48, 64, 0.40);
}
