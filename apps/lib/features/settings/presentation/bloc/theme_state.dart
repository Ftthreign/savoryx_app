import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/app_theme.dart';
import 'package:savoryx/features/settings/domain/entities/app_font_family.dart';
import 'package:savoryx/features/settings/domain/entities/app_theme_mode.dart';

/// Dart 3 sealed class hierarchy for Theme state preventing impossible states.
sealed class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

final class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

final class ThemeLoaded extends ThemeState {
  const ThemeLoaded({
    this.mode = AppThemeMode.clayLight,
    this.font = AppFontFamily.nunitoSans,
  });

  final AppThemeMode mode;
  final AppFontFamily font;

  /// Material 3 ThemeData computed directly with active font and mode.
  ThemeData get themeData => AppTheme.getThemeData(mode: mode, font: font);

  ThemeLoaded copyWith({
    AppThemeMode? mode,
    AppFontFamily? font,
  }) {
    return ThemeLoaded(
      mode: mode ?? this.mode,
      font: font ?? this.font,
    );
  }

  @override
  List<Object?> get props => [mode, font];
}
