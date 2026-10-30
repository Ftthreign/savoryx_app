import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/widgets/clay_card.dart';

/// Health tab displaying executive financial health score and regret audit.
class HealthTab extends StatelessWidget {
  const HealthTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('health_scroll_view'),
        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 110.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EXECUTIVE REPORT',
              style: ClayTypography.labelSm(
                color: ClayColors.onSurfaceVariant,
              ),
            ),
            Text(
              'Financial Health Score',
              style: ClayTypography.headlineSm(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20.0),
            ClayCard(
              borderRadius: BorderRadius.circular(26.0),
              child: Column(
                children: [
                  Text(
                    '94 / 100',
                    style: ClayTypography.headlineXl(
                      color: ClayColors.tertiary,
                    ),
                  ),
                  Text(
                    'Optimal Financial Runway',
                    style: ClayTypography.labelLg(
                      color: ClayColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Pengeluaran harian Anda 32% di bawah batas maksimal safe-to-spend. Buffer darurat memadai untuk 42 hari ke depan.',
                    textAlign: TextAlign.center,
                    style: ClayTypography.bodyMd(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            ClayCard(
              borderRadius: BorderRadius.circular(24.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    size: 32.0,
                    color: ClayColors.secondary,
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '14-Day Regret Audit',
                          style: ClayTypography.headlineSm(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '91% pembelian Anda dalam 14 hari terakhir dinilai memuaskan dan bernilai tinggi.',
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
          ],
        ),
      ),
    );
  }
}
