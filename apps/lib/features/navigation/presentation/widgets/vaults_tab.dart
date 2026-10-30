import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';
import 'package:savoryx/core/widgets/clay_card.dart';

/// Vaults tab displaying sinking funds and emergency fund allocations.
class VaultsTab extends StatelessWidget {
  const VaultsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('vaults_scroll_view'),
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 110.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VIRTUAL VAULTS',
              style: ClayTypography.labelSm(
                color: ClayColors.onSurfaceVariant,
              ),
            ),
            Text(
              'Sinking Funds',
              style: ClayTypography.headlineSm(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20.0),
            _buildVaultCard(
              context,
              name: 'Emergency Fund (6 Months)',
              saved: 36000000,
              target: 50000000,
              icon: Icons.shield_outlined,
              accent: ClayColors.tertiary,
            ),
            const SizedBox(height: 14.0),
            _buildVaultCard(
              context,
              name: 'MacBook Pro M3 Pro',
              saved: 22500000,
              target: 32000000,
              icon: Icons.laptop_mac,
              accent: ClayColors.primary,
            ),
            const SizedBox(height: 14.0),
            _buildVaultCard(
              context,
              name: 'Japan Spring Trip 2027',
              saved: 8500000,
              target: 25000000,
              icon: Icons.flight_takeoff,
              accent: ClayColors.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultCard(
    BuildContext context, {
    required String name,
    required int saved,
    required int target,
    required IconData icon,
    required Color accent,
  }) {
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
              Text(
                '${(progress * 100).toInt()}%',
                style: ClayTypography.labelLg(color: accent),
              ),
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
                  style: ClayTypography.bodySm(
                    color: ClayColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  'Target: ${CurrencyFormatter.formatMinorUnit(target)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClayTypography.labelMd(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
