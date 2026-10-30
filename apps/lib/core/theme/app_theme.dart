import 'package:flutter/material.dart';
import 'clay_colors.dart';
import 'clay_typography.dart';

/// App-wide theme provider configuring Material 3 ThemeData with Claymorphism tokens.
abstract final class AppTheme {
  /// Default Claymorphism Light Theme.
  static ThemeData get clayLight {
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
      textTheme: ClayTypography.createTextTheme(
        defaultColor: ClayColors.onSurface,
      ),
      dividerTheme: const DividerThemeData(
        color: ClayColors.outlineVariant,
        thickness: 1,
      ),
    );
  }

  /// Claymorphism Dark Theme.
  static ThemeData get clayDark {
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
      textTheme: ClayTypography.createTextTheme(
        defaultColor: ClayColors.onSurfaceDark,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF282E3C),
        thickness: 1,
      ),
    );
  }
}
