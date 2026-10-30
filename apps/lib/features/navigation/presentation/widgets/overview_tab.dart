import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/constants.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';
import 'package:savoryx/core/widgets/clay_button.dart';
import 'package:savoryx/core/widgets/clay_card.dart';

/// Overview tab displaying safe-to-spend runway, quick actions,
/// account balances, and recent ledger entries.
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  bool _isMasked = false;
  int _stashedFund = 45000;

  void _toggleMask() {
    setState(() => _isMasked = !_isMasked);
  }

  void _stashImpulse() {
    setState(() => _stashedFund += 45000);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impulse deflected! +Rp 45k moved to Sinking Fund'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('overview_scroll_view'),
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
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
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
                      onTap: _toggleMask,
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
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
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
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.hourglass_top,
                          size: 14.0,
                          color: ClayColors.secondary,
                        ),
                        const SizedBox(width: 4.0),
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
            const SizedBox(height: 18.0),

            // Behavioral Fast-Action Row
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    color: ClayColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(24.0),
                    padding: const EdgeInsets.all(14.0),
                    onTap: _stashImpulse,
                    child: Row(
                      children: [
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: const BoxDecoration(
                            color: ClayColors.tertiaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield,
                            size: 20.0,
                            color: ClayColors.onTertiaryFixed,
                          ),
                        ),
                        const SizedBox(width: 10.0),
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
                                '+${CurrencyFormatter.formatCompactRupiah(_stashedFund)} Stashed',
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
            const SizedBox(height: 22.0),

            // Accounts Horizontal Carousel Section
            Text(
              'Pockets & Accounts',
              style: ClayTypography.headlineSm(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12.0),
            SizedBox(
              height: 145.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _buildAccountCard(
                    'BCA Main',
                    14820000,
                    Icons.account_balance,
                    ClayColors.primary,
                  ),
                  const SizedBox(width: 12.0),
                  _buildAccountCard(
                    'Mandiri Payroll',
                    6350000,
                    Icons.credit_card,
                    ClayColors.secondary,
                  ),
                  const SizedBox(width: 12.0),
                  _buildAccountCard(
                    'Cash Pocket',
                    480000,
                    Icons.payments,
                    ClayColors.tertiary,
                  ),
                  const SizedBox(width: 12.0),
                  _buildAccountCard(
                    'GoPay Wallet',
                    320000,
                    Icons.account_balance_wallet,
                    ClayColors.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Recent Tactile Ledger Section
            Text(
              'Recent Tactile Ledger',
              style: ClayTypography.headlineSm(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12.0),
            _buildLedgerItem(
              'Kopi Kenangan Senopati',
              -38000,
              '10:42 AM',
              'GoPay',
              Icons.local_cafe,
              ClayColors.primary,
            ),
            const SizedBox(height: 10.0),
            _buildLedgerItem(
              'Freelance UI Sprint',
              3500000,
              'Yesterday',
              'BCA Main',
              Icons.arrow_downward,
              ClayColors.tertiary,
            ),
            const SizedBox(height: 10.0),
            _buildLedgerItem(
              'Makan Malam Sushi Tei',
              -180000,
              'Monday, 19:15',
              'Mandiri',
              Icons.restaurant,
              ClayColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    String title,
    int amount,
    IconData icon,
    Color iconColor,
  ) {
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
              Text(
                'Available',
                style: ClayTypography.bodySm(
                  color: ClayColors.onSurfaceVariant,
                ),
              ),
              Text(
                CurrencyFormatter.formatMasked(amount, isMasked: _isMasked),
                style: ClayTypography.headlineSm(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerItem(
    String title,
    int amount,
    String time,
    String pocket,
    IconData icon,
    Color color,
  ) {
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
}
