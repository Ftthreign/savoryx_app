import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/typography/font_manager.dart';
import 'package:savoryx/features/settings/domain/entities/app_font_family.dart';
import 'package:savoryx/features/settings/domain/entities/app_theme_mode.dart';
import 'package:savoryx/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:savoryx/features/settings/presentation/bloc/theme_state.dart';

void main() {
  setUpAll(() {
    FontManager.useTestFallback = true;
  });

  group('ThemeCubit & Dynamic Theme Engine', () {
    late ThemeCubit themeCubit;

    setUp(() {
      themeCubit = ThemeCubit();
    });

    tearDown(() {
      themeCubit.close();
    });

    test('initial state is ThemeLoaded with Clay Light and Nunito Sans', () {
      expect(themeCubit.state, isA<ThemeLoaded>());
      final loaded = themeCubit.state as ThemeLoaded;
      expect(loaded.mode, equals(AppThemeMode.clayLight));
      expect(loaded.font, equals(AppFontFamily.nunitoSans));
      expect(loaded.themeData.scaffoldBackgroundColor, equals(ClayColors.canvasLight));
    });

    test('setThemeMode updates theme to Clay Dark and OLED Pure Black', () {
      themeCubit.setThemeMode(AppThemeMode.clayDark);
      expect((themeCubit.state as ThemeLoaded).mode, equals(AppThemeMode.clayDark));
      expect(
        (themeCubit.state as ThemeLoaded).themeData.scaffoldBackgroundColor,
        equals(ClayColors.canvasDark),
      );

      themeCubit.setThemeMode(AppThemeMode.oledBlack);
      expect((themeCubit.state as ThemeLoaded).mode, equals(AppThemeMode.oledBlack));
      expect(
        (themeCubit.state as ThemeLoaded).themeData.scaffoldBackgroundColor,
        equals(ClayColors.oledBlack),
      );
    });

    test('setFontFamily updates active font across all 6 official families', () {
      for (final font in AppFontFamily.values) {
        themeCubit.setFontFamily(font);
        final loaded = themeCubit.state as ThemeLoaded;
        expect(loaded.font, equals(font));
        expect(loaded.themeData.textTheme.bodyMedium, isNotNull);
      }
    });

    test('toggleDarkMode toggles between Clay Light and Clay Dark', () {
      expect((themeCubit.state as ThemeLoaded).mode, equals(AppThemeMode.clayLight));

      themeCubit.toggleDarkMode();
      expect((themeCubit.state as ThemeLoaded).mode, equals(AppThemeMode.clayDark));

      themeCubit.toggleDarkMode();
      expect((themeCubit.state as ThemeLoaded).mode, equals(AppThemeMode.clayLight));
    });
  });

  group('FontManager Multi-Font Engine', () {
    test('provides complete TextTheme for all 6 official typography families', () {
      for (final font in AppFontFamily.values) {
        final textTheme = FontManager.getTextTheme(font: font);
        expect(textTheme.headlineLarge, isNotNull);
        expect(textTheme.bodyLarge, isNotNull);
        expect(textTheme.labelSmall, isNotNull);
      }
    });

    test('getTextStyle returns valid style with specified size and weight', () {
      final style = FontManager.getTextStyle(
        font: AppFontFamily.inter,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ClayColors.primary,
      );

      expect(style.fontSize, equals(18));
      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.color, equals(ClayColors.primary));
    });
  });
}
