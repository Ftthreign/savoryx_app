import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/widgets/clay_button.dart';

class ClayKeypad extends StatelessWidget {
  const ClayKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onOperatorPressed,
    required this.onClear,
    required this.onBackspace,
    this.onAcceleratorPressed,
    this.acceleratorDenoms = const [10000, 50000, 100000, 500000],
    this.showAccelerators = true,
    this.showBackspaceInHeader = true,
    this.enableHaptic = true,
  });

  final ValueChanged<String> onDigitPressed;
  final ValueChanged<String> onOperatorPressed;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final ValueChanged<int>? onAcceleratorPressed;

  final List<int> acceleratorDenoms;
  final bool showAccelerators;
  final bool showBackspaceInHeader;

  final bool enableHaptic;

  void _triggerHaptic() {
    if (enableHaptic) {
      HapticFeedback.selectionClick();
    }
  }

  void _triggerClearHaptic() {
    if (enableHaptic) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAccelerators) ...[
          _buildAcceleratorHeader(context, isDark),
          const SizedBox(height: 10.0),
        ],
        _buildKeypadGrid(context, isDark),
      ],
    );
  }

  Widget _buildAcceleratorHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        ...acceleratorDenoms.map(
          (int denom) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: ClayButton(
                key: Key('clay_chip_${denom ~/ 1000}k'),
                height: 38.0,
                padding: EdgeInsets.zero,
                color: isDark
                    ? ClayColors.surfaceContainerDarkHigh
                    : ClayColors.tertiaryFixed,
                borderRadius: BorderRadius.circular(19.0),
                onTap: () {
                  _triggerHaptic();
                  onAcceleratorPressed?.call(denom);
                },
                child: Center(
                  child: Text(
                    '+${denom ~/ 1000}k',
                    style: ClayTypography.labelMd(
                      color: isDark
                          ? ClayColors.onSurfaceDark
                          : ClayColors.onTertiaryFixed,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showBackspaceInHeader)
          Padding(
            padding: const EdgeInsets.only(left: 2.5),
            child: SizedBox(
              width: 50.0,
              height: 38.0,
              child: ClayButton(
                key: const Key('clay_key_backspace'),
                padding: EdgeInsets.zero,
                color: isDark
                    ? ClayColors.surfaceContainerDark
                    : ClayColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(19.0),
                onTap: () {
                  _triggerHaptic();
                  onBackspace();
                },
                child: Center(
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 18.0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const List<List<_KeyItem>> _keypadRows = [
    [
      _KeyItem(label: '7', type: _KeyType.digit, keyId: '7'),
      _KeyItem(label: '8', type: _KeyType.digit, keyId: '8'),
      _KeyItem(label: '9', type: _KeyType.digit, keyId: '9'),
      _KeyItem(label: '÷', type: _KeyType.operator, keyId: 'divide'),
    ],
    [
      _KeyItem(label: '4', type: _KeyType.digit, keyId: '4'),
      _KeyItem(label: '5', type: _KeyType.digit, keyId: '5'),
      _KeyItem(label: '6', type: _KeyType.digit, keyId: '6'),
      _KeyItem(label: '\u00D7', type: _KeyType.operator, keyId: 'multiply'),
    ],
    [
      _KeyItem(label: '1', type: _KeyType.digit, keyId: '1'),
      _KeyItem(label: '2', type: _KeyType.digit, keyId: '2'),
      _KeyItem(label: '3', type: _KeyType.digit, keyId: '3'),
      _KeyItem(label: '-', type: _KeyType.operator, keyId: 'minus'),
    ],
    [
      _KeyItem(label: 'C', type: _KeyType.clear, keyId: 'clear'),
      _KeyItem(label: '0', type: _KeyType.digit, keyId: '0'),
      _KeyItem(label: '000', type: _KeyType.digit, keyId: '000'),
      _KeyItem(label: '+', type: _KeyType.operator, keyId: 'plus'),
    ],
  ];

  Widget _buildKeypadGrid(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _keypadRows.asMap().entries.map((entry) {
        final rowIndex = entry.key;
        final row = entry.value;

        return Padding(
          padding: EdgeInsets.only(
              bottom: rowIndex < _keypadRows.length - 1 ? 8.0 : 0.0),
          child: Row(
            children: row.asMap().entries.map((keyEntry) {
              final colIndex = keyEntry.key;
              final item = keyEntry.value;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: colIndex > 0 ? 4.0 : 0.0,
                    right: colIndex < row.length - 1 ? 4.0 : 0.0,
                  ),
                  child: _buildKeyWidget(context, item, isDark),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyWidget(BuildContext context, _KeyItem item, bool isDark) {
    Color buttonColor;
    Color textColor;

    switch (item.type) {
      case _KeyType.digit:
        buttonColor = isDark
            ? ClayColors.surfaceContainerDark
            : ClayColors.surfaceContainerLow;
        textColor = Theme.of(context).colorScheme.onSurface;
        break;
      case _KeyType.operator:
        buttonColor = isDark
            ? ClayColors.surfaceContainerDarkHigh
            : ClayColors.secondaryContainer;
        textColor = isDark
            ? ClayColors.secondaryFixed
            : ClayColors.onSecondaryContainer;
        break;
      case _KeyType.clear:
        buttonColor = ClayColors.errorContainer;
        textColor = ClayColors.onErrorContainer;
        break;
    }

    return ClayButton(
      key: Key('clay_key_${item.keyId}'),
      height: 52.0,
      padding: EdgeInsets.zero,
      color: buttonColor,
      borderRadius: BorderRadius.circular(16.0),
      onTap: () {
        switch (item.type) {
          case _KeyType.digit:
            _triggerHaptic();
            onDigitPressed(item.label);
            break;
          case _KeyType.operator:
            _triggerHaptic();
            onOperatorPressed(item.label);
            break;
          case _KeyType.clear:
            _triggerClearHaptic();
            onClear();
            break;
        }
      },
      child: Center(
        child: Text(
          item.label,
          style: item.label.length > 2
              ? ClayTypography.headlineSm(color: textColor)
              : ClayTypography.headlineMd(color: textColor),
        ),
      ),
    );
  }
}

enum _KeyType {
  digit,
  operator,
  clear,
}

class _KeyItem {
  final String label;
  final _KeyType type;
  final String keyId;

  const _KeyItem({
    required this.label,
    required this.type,
    required this.keyId,
  });
}
