import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/app_font_family.dart';
import '../../domain/entities/app_theme_mode.dart';
import 'theme_state.dart';

/// Dynamic Theme and Typography state management Cubit.
/// Manages instant (<100ms) transitions between Light, Dark, OLED and 6 official fonts.
@lazySingleton
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeLoaded());

  /// Switch surface theme mode (Clay Light, Clay Dark, OLED Black).
  void setThemeMode(AppThemeMode mode) {
    if (state is ThemeLoaded) {
      final current = state as ThemeLoaded;
      if (current.mode != mode) {
        emit(current.copyWith(mode: mode));
      }
    } else {
      emit(ThemeLoaded(mode: mode));
    }
  }

  /// Switch active font family on-the-fly.
  void setFontFamily(AppFontFamily font) {
    if (state is ThemeLoaded) {
      final current = state as ThemeLoaded;
      if (current.font != font) {
        emit(current.copyWith(font: font));
      }
    } else {
      emit(ThemeLoaded(font: font));
    }
  }

  /// Quick toggle between Light and Dark surfaces.
  void toggleDarkMode() {
    if (state is ThemeLoaded) {
      final current = state as ThemeLoaded;
      final nextMode = current.mode == AppThemeMode.clayLight
          ? AppThemeMode.clayDark
          : AppThemeMode.clayLight;
      emit(current.copyWith(mode: nextMode));
    }
  }
}
