import 'package:flutter/material.dart';
import '../../../../core/theme/clay_colors.dart';
import '../../../../core/theme/clay_typography.dart';
import '../../../../core/widgets/clay_button.dart';

class KeypadGrid extends StatelessWidget {
  const KeypadGrid({
    super.key,
    required this.onDigitPressed,
    required this.onClear,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onClear;
  final VoidCallback onBackspace;

  static const List<String> _digits = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9'
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 10.0,
      children: [
        ..._digits.map(
          (String d) => ClayButton(
            key: Key('keypad_$d'),
            onTap: () => onDigitPressed(d),
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(18.0),
            child: Center(
              child: Text(
                d,
                style: ClayTypography.headlineMd(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        // AC button
        ClayButton(
          key: const Key('keypad_ac'),
          color: ClayColors.errorContainer,
          onTap: onClear,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18.0),
          child: Center(
            child: Text(
              'AC',
              style: ClayTypography.headlineSm(
                color: ClayColors.onErrorContainer,
              ),
            ),
          ),
        ),
        // 0 button
        ClayButton(
          key: const Key('keypad_0'),
          onTap: () => onDigitPressed('0'),
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18.0),
          child: Center(
            child: Text(
              '0',
              style: ClayTypography.headlineMd(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        // Backspace button
        ClayButton(
          key: const Key('keypad_backspace'),
          onTap: onBackspace,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18.0),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 22.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
