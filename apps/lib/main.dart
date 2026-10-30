import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/theme/clay_colors.dart';
import 'core/theme/clay_typography.dart';
import 'core/utils/constants.dart';
import 'core/utils/currency_formatter.dart';
import 'core/widgets/clay_button.dart';
import 'core/widgets/clay_card.dart';
import 'core/widgets/clay_toggle_switch.dart';
import 'features/settings/domain/entities/app_font_family.dart';
import 'features/settings/domain/entities/app_theme_mode.dart';
import 'features/settings/presentation/bloc/theme_cubit.dart';
import 'features/settings/presentation/bloc/theme_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const SavoryxApp());
}

class SavoryxApp extends StatelessWidget {
  const SavoryxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => getIt<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final loadedState =
              state is ThemeLoaded ? state : const ThemeLoaded();

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: loadedState.themeData,
            home: const ClayShowcaseScreen(),
          );
        },
      ),
    );
  }
}

class ClayShowcaseScreen extends StatefulWidget {
  const ClayShowcaseScreen({super.key});

  @override
  State<ClayShowcaseScreen> createState() => _ClayShowcaseScreenState();
}

class _ClayShowcaseScreenState extends State<ClayShowcaseScreen> {
  bool _isMasked = false;
  bool _isTalanganActive = false;
  int _stashedCount = 45000;

  void _onStashImpulse() {
    setState(() {
      _stashedCount += 45000;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final themeState = themeCubit.state is ThemeLoaded
        ? (themeCubit.state as ThemeLoaded)
        : const ThemeLoaded();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Top Bar Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAVORYX // OS',
                        style: ClayTypography.labelSm(
                          color: ClayColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dynamic Engine Showcase',
                        style: ClayTypography.headlineSm(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Privacy Mask Button
                      ClayButton(
                        width: 44,
                        height: 44,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          setState(() => _isMasked = !_isMasked);
                        },
                        child: Icon(
                          _isMasked ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick Dark/Light Toggle
                      ClayButton(
                        width: 44,
                        height: 44,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(22),
                        onTap: themeCubit.toggleDarkMode,
                        child: Icon(
                          themeState.mode.isDark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- Surface Theme Mode Selector Chips (Light, Dark, OLED) ---
              Text(
                'SURFACE THEME MODE',
                style: ClayTypography.labelSm(
                  color: ClayColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppThemeMode.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final mode = AppThemeMode.values[index];
                    final isSelected = themeState.mode == mode;

                    return ClayButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? ClayColors.primary
                          : (themeState.mode.isDark
                              ? ClayColors.surfaceContainerDark
                              : ClayColors.surfaceContainerLow),
                      onTap: () => themeCubit.setThemeMode(mode),
                      child: Center(
                        child: Text(
                          mode.displayName,
                          style: ClayTypography.labelMd(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // --- Multi-Font Switcher Engine (6 Fonts) ---
              Text(
                'TYPOGRAPHY ENGINE (6 OFFICIAL FONTS)',
                style: ClayTypography.labelSm(
                  color: ClayColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppFontFamily.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final font = AppFontFamily.values[index];
                    final isSelected = themeState.font == font;

                    return ClayButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? ClayColors.tertiaryContainer
                          : (themeState.mode.isDark
                              ? ClayColors.surfaceContainerDark
                              : ClayColors.surfaceContainerLow),
                      onTap: () => themeCubit.setFontFamily(font),
                      child: Center(
                        child: Text(
                          font.displayName,
                          style: ClayTypography.labelMd(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // --- Hero Spend Card (Butter Yellow) ---
              ClayCard(
                isHero: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: ClayColors.secondaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.speed,
                                size: 16,
                                color: ClayColors.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SAFE-TO-SPEND RUNWAY',
                              style: ClayTypography.labelLg(
                                color: ClayColors.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Health: 94',
                            style: ClayTypography.labelSm(
                              color: ClayColors.tertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      CurrencyFormatter.formatMasked(
                        145000,
                        isMasked: _isMasked,
                      ),
                      style: ClayTypography.headlineXl(
                        color: ClayColors.onSurface,
                      ),
                    ),
                    Text(
                      '/ day safe remaining',
                      style: ClayTypography.labelMd(
                        color: ClayColors.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.hourglass_top,
                            size: 14,
                            color: ClayColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '≈ ${CurrencyFormatter.calculateWorkHours(145000)} working hours',
                            style: ClayTypography.labelSm(
                              color: ClayColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Fast-Action Behavioral Row ---
              Row(
                children: [
                  Expanded(
                    child: ClayButton(
                      color: ClayColors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.all(14),
                      onTap: _onStashImpulse,
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: ClayColors.tertiaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield,
                              size: 20,
                              color: ClayColors.onTertiaryFixed,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saya Batal Beli',
                                  style: ClayTypography.labelLg(
                                    color: ClayColors.onTertiary,
                                  ),
                                ),
                                Text(
                                  '+${CurrencyFormatter.formatCompactRupiah(_stashedCount)} Stashed ✨',
                                  style: ClayTypography.labelSm(
                                    color: ClayColors.tertiaryChip,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- Talangan Split Switch Card ---
              ClayCard(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: ClayColors.secondaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.group,
                            size: 20,
                            color: ClayColors.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mark as Talangan',
                              style: ClayTypography.headlineSm(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _isTalanganActive
                                  ? 'Active (Split enabled)'
                                  : 'Fronting for friends & split',
                              style: ClayTypography.bodySm(
                                color: ClayColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ClayToggleSwitch(
                      value: _isTalanganActive,
                      onChanged: (val) {
                        setState(() => _isTalanganActive = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Primary CTA Button ---
              ClayButton(
                isPrimaryCta: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense logged with 120ms tactile bounce!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Log Expense (Rp 85.000)',
                        style: ClayTypography.headlineSm(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
