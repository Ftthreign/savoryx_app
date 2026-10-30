import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/clay_colors.dart';
import '../../../../core/theme/clay_typography.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/clay_bottom_nav_bar.dart';
import '../../../../core/widgets/clay_button.dart';
import '../../../../core/widgets/clay_card.dart';
import '../../../settings/domain/entities/app_font_family.dart';
import '../../../settings/domain/entities/app_theme_mode.dart';
import '../../../settings/presentation/bloc/theme_cubit.dart';
import '../../../settings/presentation/bloc/theme_state.dart';
import '../../../transaction/presentation/widgets/rapid_input_modal.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isMasked = false;
  int _stashedFund = 45000;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _openRapidInput() {
    RapidInputModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack preserves tab states cleanly without rebuilding
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildOverviewTab(),
              _buildVaultsTab(),
              _buildHealthTab(),
              _buildSettingsTab(),
            ],
          ),

          // Floating Pill Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClayBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              onFabTap: _openRapidInput,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 0: OVERVIEW (DASHBOARD & RECENT LEDGER)
  // =========================================================================
  Widget _buildOverviewTab() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 110.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PULSESPEND // SAVORYX',
                      style: ClayTypography.labelSm(
                        color: ClayColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Overview',
                      style: ClayTypography.headlineSm(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ClayButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      borderRadius: BorderRadius.circular(18.0),
                      onTap: () {},
                      child: Text(
                        'IDR (Rp)',
                        style: ClayTypography.labelMd(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ClayButton(
                      width: 40.0,
                      height: 40.0,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(20.0),
                      onTap: () => setState(() => _isMasked = !_isMasked),
                      child: Icon(
                        _isMasked ? Icons.visibility_off : Icons.visibility,
                        size: 18.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            // Hero Spend Card (Butter Yellow)
            ClayCard(
              isHero: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 28.0,
                              height: 28.0,
                              decoration: const BoxDecoration(
                                color: ClayColors.secondaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.speed,
                                size: 16.0,
                                color: ClayColors.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'SAFE-TO-SPEND RUNWAY',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ClayTypography.labelLg(
                                  color: ClayColors.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          'Health Score: 94',
                          style: ClayTypography.labelSm(
                            color: ClayColors.tertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    CurrencyFormatter.formatMasked(145000, isMasked: _isMasked),
                    style:
                        ClayTypography.headlineXl(color: ClayColors.onSurface),
                  ),
                  Text(
                    '/ day safe remaining',
                    style: ClayTypography.labelMd(
                        color: ClayColors.onSecondaryContainer),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hourglass_top,
                            size: 14.0, color: ClayColors.secondary),
                        const SizedBox(width: 4.0),
                        Text(
                          '≈ ${CurrencyFormatter.calculateWorkHours(145000)} working hours',
                          style: ClayTypography.labelSm(
                              color: ClayColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18.0),

            // Behavioral Fast-Action Row
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    color: ClayColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(24.0),
                    padding: const EdgeInsets.all(14.0),
                    onTap: () {
                      setState(() => _stashedFund += 45000);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Impulse deflected! +Rp 45k moved to Sinking Fund 🌱'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: const BoxDecoration(
                            color: ClayColors.tertiaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield,
                              size: 20.0, color: ClayColors.onTertiaryFixed),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Saya Batal Beli',
                                  style: ClayTypography.labelLg(
                                      color: ClayColors.onTertiary)),
                              Text(
                                  '+${CurrencyFormatter.formatCompactRupiah(_stashedFund)} Stashed ✨',
                                  style: ClayTypography.labelSm(
                                      color: ClayColors.tertiaryChip)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22.0),

            // Accounts Horizontal Carousel Section
            Text('Pockets & Accounts',
                style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 12.0),
            SizedBox(
              height: 145.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _buildAccountCard('BCA Main', 14820000, Icons.account_balance,
                      ClayColors.primary),
                  const SizedBox(width: 12.0),
                  _buildAccountCard('Mandiri Payroll', 6350000,
                      Icons.credit_card, ClayColors.secondary),
                  const SizedBox(width: 12.0),
                  _buildAccountCard('Cash Pocket', 480000, Icons.payments,
                      ClayColors.tertiary),
                  const SizedBox(width: 12.0),
                  _buildAccountCard('GoPay Wallet', 320000,
                      Icons.account_balance_wallet, ClayColors.secondary),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Recent Tactile Ledger Section
            Text('Recent Tactile Ledger',
                style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 12.0),
            _buildLedgerItem('Kopi Kenangan Senopati', -38000, '10:42 AM',
                'GoPay', Icons.local_cafe, ClayColors.primary),
            const SizedBox(height: 10.0),
            _buildLedgerItem('Freelance UI Sprint', 3500000, 'Yesterday',
                'BCA Main', Icons.arrow_downward, ClayColors.tertiary),
            const SizedBox(height: 10.0),
            _buildLedgerItem('Makan Malam Sushi Tei', -180000, 'Monday, 19:15',
                'Mandiri', Icons.restaurant, ClayColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(
      String title, int amount, IconData icon, Color iconColor) {
    return ClayCard(
      width: 180.0,
      borderRadius: BorderRadius.circular(AppConstants.clayCarouselRadius),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.0, color: iconColor),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClayTypography.labelSm(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available',
                  style: ClayTypography.bodySm(
                      color: ClayColors.onSurfaceVariant)),
              Text(
                CurrencyFormatter.formatMasked(amount, isMasked: _isMasked),
                style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerItem(String title, int amount, String time, String pocket,
      IconData icon, Color color) {
    final isIncome = amount > 0;
    final prefix = isIncome ? '+' : '';

    return ClayCard(
      borderRadius: BorderRadius.circular(20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42.0,
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Icon(icon, size: 22.0, color: color),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClayTypography.bodyLg(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$time • $pocket',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClayTypography.bodySm(
                          color: ClayColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            '$prefix${CurrencyFormatter.formatMasked(amount, isMasked: _isMasked)}',
            style: ClayTypography.headlineSm(
              color: isIncome ? ClayColors.tertiary : ClayColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: VAULTS (SINKING FUNDS & AUTO-STASH)
  // =========================================================================
  Widget _buildVaultsTab() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 110.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VIRTUAL VAULTS',
                style:
                    ClayTypography.labelSm(color: ClayColors.onSurfaceVariant)),
            Text('Sinking Funds',
                style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 20.0),
            _buildVaultCard('Emergency Fund (6 Months)', 36000000, 50000000,
                Icons.shield_outlined, ClayColors.tertiary),
            const SizedBox(height: 14.0),
            _buildVaultCard('MacBook Pro M3 Pro', 22500000, 32000000,
                Icons.laptop_mac, ClayColors.primary),
            const SizedBox(height: 14.0),
            _buildVaultCard('Japan Spring Trip 2027', 8500000, 25000000,
                Icons.flight_takeoff, ClayColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultCard(
      String name, int saved, int target, IconData icon, Color accent) {
    final progress = (saved / target).clamp(0.0, 1.0);

    return ClayCard(
      borderRadius: BorderRadius.circular(24.0),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 22.0, color: accent),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClayTypography.headlineSm(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Text('${(progress * 100).toInt()}%',
                  style: ClayTypography.labelLg(color: accent)),
            ],
          ),
          const SizedBox(height: 12.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10.0,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Saved: ${CurrencyFormatter.formatMinorUnit(saved)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      ClayTypography.bodySm(color: ClayColors.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  'Target: ${CurrencyFormatter.formatMinorUnit(target)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClayTypography.labelMd(
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 110.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EXECUTIVE REPORT',
                style:
                    ClayTypography.labelSm(color: ClayColors.onSurfaceVariant)),
            Text('Financial Health Score',
                style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 20.0),
            ClayCard(
              borderRadius: BorderRadius.circular(26.0),
              child: Column(
                children: [
                  Text('94 / 100',
                      style: ClayTypography.headlineXl(
                          color: ClayColors.tertiary)),
                  Text('Optimal Financial Runway',
                      style: ClayTypography.labelLg(
                          color: ClayColors.onSurfaceVariant)),
                  const SizedBox(height: 12.0),
                  Text(
                    'Pengeluaran harian Anda 32% di bawah batas maksimal safe-to-spend. Buffer darurat memadai untuk 42 hari ke depan.',
                    textAlign: TextAlign.center,
                    style: ClayTypography.bodyMd(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            ClayCard(
              borderRadius: BorderRadius.circular(24.0),
              child: Row(
                children: [
                  const Icon(Icons.psychology,
                      size: 32.0, color: ClayColors.secondary),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('14-Day Regret Audit',
                            style: ClayTypography.headlineSm(
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        Text(
                            '91% pembelian Anda dalam 14 hari terakhir dinilai memuaskan dan bernilai tinggi.',
                            style: ClayTypography.bodySm(
                                color: ClayColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3: SETTINGS (PERSONALIZATION HUB)
  // =========================================================================
  Widget _buildSettingsTab() {
    final themeCubit = context.watch<ThemeCubit>();
    final themeState = themeCubit.state is ThemeLoaded
        ? (themeCubit.state as ThemeLoaded)
        : const ThemeLoaded();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 110.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PERSONALIZATION HUB',
                style:
                    ClayTypography.labelSm(color: ClayColors.onSurfaceVariant)),
            Text('Settings & Themes',
                style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 20.0),

            // Theme Switcher Section
            Text('Surface Theme Mode',
                style: ClayTypography.labelLg(
                    color: Theme.of(context).colorScheme.onSurface)),
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
            Text('Typography Engine (6 Fonts)',
                style: ClayTypography.labelLg(
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 10.0),
            ...AppFontFamily.values.map((font) {
              final isSelected = themeState.font == font;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClayCard(
                  borderRadius: BorderRadius.circular(18.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
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
                            Text(font.displayName,
                                style: ClayTypography.bodyLg(
                                    color:
                                        Theme.of(context).colorScheme.onSurface)),
                            Text(font.description,
                                style: ClayTypography.bodySm(
                                    color: ClayColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            size: 22.0, color: ClayColors.tertiaryContainer),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
