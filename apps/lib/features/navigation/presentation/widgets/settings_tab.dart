import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/widgets/clay_button.dart';
import 'package:savoryx/core/widgets/clay_card.dart';
import 'package:savoryx/features/settings/domain/entities/app_font_family.dart';
import 'package:savoryx/features/settings/domain/entities/app_theme_mode.dart';
import 'package:savoryx/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:savoryx/features/settings/presentation/bloc/theme_state.dart';

/// Settings tab for switching themes and typography engine options.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final themeCubit = context.read<ThemeCubit>();
        final themeState =
            state is ThemeLoaded ? state : const ThemeLoaded();

        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            key: const PageStorageKey<String>('settings_scroll_view'),
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 110.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERSONALIZATION HUB',
                  style: ClayTypography.labelSm(
                    color: ClayColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Settings & Themes',
                  style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20.0),

                // Theme Switcher Section
                Text(
                  'Surface Theme Mode',
                  style: ClayTypography.labelLg(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: AppThemeMode.values.map((mode) {
                    final isSelected = themeState.mode == mode;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ClayButton(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          color: isSelected ? ClayColors.primary : null,
                          onTap: () => themeCubit.setThemeMode(mode),
                          child: Center(
                            child: Text(
                              mode.displayName,
                              style: ClayTypography.labelSm(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24.0),

                // Font Selector Section
                Text(
                  'Typography Engine (6 Fonts)',
                  style: ClayTypography.labelLg(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10.0),
                ...AppFontFamily.values.map((font) {
                  final isSelected = themeState.font == font;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClayCard(
                      borderRadius: BorderRadius.circular(18.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      onTap: () => themeCubit.setFontFamily(font),
                      color: isSelected
                          ? ClayColors.tertiaryFixed.withOpacity(0.4)
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  font.displayName,
                                  style: ClayTypography.bodyLg(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                                Text(
                                  font.description,
                                  style: ClayTypography.bodySm(
                                    color: ClayColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              size: 22.0,
                              color: ClayColors.tertiaryContainer,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
