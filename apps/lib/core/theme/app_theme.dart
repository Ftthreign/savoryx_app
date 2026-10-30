import 'package:flutter/material.dart';
import 'package:savoryx/features/settings/domain/entities/app_font_family.dart';
import 'package:savoryx/features/settings/domain/entities/app_theme_mode.dart';
import 'package:savoryx/core/typography/font_manager.dart';
import 'package:savoryx/core/theme/clay_colors.dart';

/// App-wide theme provider configuring Material 3 ThemeData with Claymorphism tokens,
/// 3 surface modes (Light, Dark, OLED), and 6 dynamic fonts.
abstract final class AppTheme {
  /// Default Claymorphism Light Theme.
  static ThemeData clayLight({
    AppFontFamily font = AppFontFamily.nunitoSans,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ClayColors.canvasLight,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ClayColors.primary,
        onPrimary: ClayColors.onPrimary,
        primaryContainer: ClayColors.primaryContainer,
        onPrimaryContainer: ClayColors.primaryDeep,
        secondary: ClayColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: ClayColors.secondaryContainer,
        onSecondaryContainer: ClayColors.onSecondaryContainer,
        tertiary: ClayColors.tertiary,
        onTertiary: ClayColors.onTertiary,
        tertiaryContainer: ClayColors.tertiaryContainer,
        onTertiaryContainer: ClayColors.tertiaryChip,
        error: ClayColors.error,
        onError: Colors.white,
        errorContainer: ClayColors.errorContainer,
        onErrorContainer: ClayColors.onErrorContainer,
        surface: ClayColors.surfaceLight,
        onSurface: ClayColors.onSurface,
        onSurfaceVariant: ClayColors.onSurfaceVariant,
        background: ClayColors.canvasLight,
        onBackground: ClayColors.onSurface,
        outline: ClayColors.outline,
        outlineVariant: ClayColors.outlineVariant,
      ),
      textTheme: FontManager.getTextTheme(
        font: font,
        defaultColor: ClayColors.onSurface,
      ),
      dividerTheme: const DividerThemeData(
        color: ClayColors.outlineVariant,
        thickness: 1,
      ),
    );
  }

  /// Claymorphism Dark Theme.
  static ThemeData clayDark({
    AppFontFamily font = AppFontFamily.nunitoSans,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ClayColors.canvasDark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: ClayColors.primaryHighlight,
        onPrimary: Colors.white,
        primaryContainer: ClayColors.primaryDeep,
        onPrimaryContainer: ClayColors.primaryFixed,
        secondary: ClayColors.secondaryFixed,
        onSecondary: ClayColors.onPrimaryFixed,
        secondaryContainer: Color(0xFF383110),
        onSecondaryContainer: ClayColors.secondaryContainer,
        tertiary: ClayColors.tertiaryGlint,
        onTertiary: ClayColors.onTertiaryFixed,
        tertiaryContainer: Color(0xFF1E320A),
        onTertiaryContainer: ClayColors.tertiaryChip,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: ClayColors.surfaceDark,
        onSurface: ClayColors.onSurfaceDark,
        onSurfaceVariant: ClayColors.onSurfaceVariantDark,
        background: ClayColors.canvasDark,
        onBackground: ClayColors.onSurfaceDark,
        outline: Color(0xFF8A92A0),
        outlineVariant: Color(0xFF323846),
      ),
      textTheme: FontManager.getTextTheme(
        font: font,
        defaultColor: ClayColors.onSurfaceDark,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF282E3C),
        thickness: 1,
      ),
    );
  }

  /// OLED Pure Black Theme (#000000).
  static ThemeData oledBlack({
    AppFontFamily font = AppFontFamily.nunitoSans,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ClayColors.oledBlack,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: ClayColors.primaryHighlight,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF5A0000),
        onPrimaryContainer: ClayColors.primaryFixed,
        secondary: ClayColors.secondaryFixed,
        onSecondary: ClayColors.onPrimaryFixed,
        secondaryContainer: Color(0xFF241F0A),
        onSecondaryContainer: ClayColors.secondaryContainer,
        tertiary: ClayColors.tertiaryGlint,
        onTertiary: ClayColors.onTertiaryFixed,
        tertiaryContainer: Color(0xFF152207),
        onTertiaryContainer: ClayColors.tertiaryChip,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: ClayColors.oledBlack,
        onSurface: ClayColors.onSurfaceDark,
        onSurfaceVariant: ClayColors.onSurfaceVariantDark,
        background: ClayColors.oledBlack,
        onBackground: ClayColors.onSurfaceDark,
        outline: Color(0xFF454B58),
        outlineVariant: Color(0xFF222630),
      ),
      textTheme: FontManager.getTextTheme(
        font: font,
        defaultColor: ClayColors.onSurfaceDark,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1A1D24),
        thickness: 1,
      ),
    );
  }

  /// Master theme resolver supporting dynamic combinations of mode and font.
  static ThemeData getThemeData({
    required AppThemeMode mode,
    AppFontFamily font = AppFontFamily.nunitoSans,
  }) {
    switch (mode) {
      case AppThemeMode.clayLight:
        return clayLight(font: font);
      case AppThemeMode.clayDark:
        return clayDark(font: font);
      case AppThemeMode.oledBlack:
        return oledBlack(font: font);
    }
  }
}
