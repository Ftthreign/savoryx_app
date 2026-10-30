import 'package:flutter/material.dart';
import '../../../../core/theme/clay_colors.dart';
import '../../../../core/theme/clay_typography.dart';
import '../../../../core/widgets/clay_button.dart';

class QuickAmountGrid extends StatelessWidget {
  const QuickAmountGrid({
    super.key,
    required this.acceleratorDenoms,
    required this.onAddAccelerator,
    required this.onTripleZero,
  });

  final List<int> acceleratorDenoms;
  final ValueChanged<int> onAddAccelerator;
  final VoidCallback onTripleZero;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        ...acceleratorDenoms.map(
          (int denom) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: ClayButton(
                height: 38.0,
                padding: EdgeInsets.zero,
                color: ClayColors.tertiaryFixed,
                borderRadius: BorderRadius.circular(19.0),
                onTap: () => onAddAccelerator(denom),
                child: Center(
                  child: Text(
                    '+${denom ~/ 1000}k',
                    style: ClayTypography.labelMd(
                      color: ClayColors.onTertiaryFixed,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: ClayButton(
              height: 38.0,
              padding: EdgeInsets.zero,
              color: isDark
                  ? ClayColors.surfaceContainerDark
                  : ClayColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(19.0),
              onTap: onTripleZero,
              child: Center(
                child: Text(
                  '000',
                  style: ClayTypography.labelMd(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
