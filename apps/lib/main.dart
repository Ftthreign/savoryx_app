import 'package:flutter/material.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/clay_colors.dart';
import 'core/theme/clay_typography.dart';
import 'core/utils/constants.dart';
import 'core/utils/currency_formatter.dart';
import 'core/widgets/clay_button.dart';
import 'core/widgets/clay_card.dart';
import 'core/widgets/clay_toggle_switch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const SavoryxApp());
}

class SavoryxApp extends StatefulWidget {
  const SavoryxApp({super.key});

  @override
  State<SavoryxApp> createState() => _SavoryxAppState();
}

class _SavoryxAppState extends State<SavoryxApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clayLight,
      darkTheme: AppTheme.clayDark,
      themeMode: _themeMode,
      home: ClayShowcaseScreen(
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class ClayShowcaseScreen extends StatefulWidget {
  const ClayShowcaseScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  final VoidCallback onToggleTheme;
  final bool isDark;

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
                        'Tactile Showcase',
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
                      // Theme Switch Button
                      ClayButton(
                        width: 44,
                        height: 44,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(22),
                        onTap: widget.onToggleTheme,
                        child: Icon(
                          widget.isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

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
                  // 'Saya Batal Beli' Shadow Fund Button
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
