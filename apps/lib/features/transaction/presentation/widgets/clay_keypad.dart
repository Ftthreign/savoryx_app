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

  static const List<BoxShadow> _keyShadowsLight = [
    BoxShadow(
      offset: Offset(2.0, 2.5),
      blurRadius: 4.0,
      color: Color.fromRGBO(163, 177, 198, 0.50),
    ),
    BoxShadow(
      offset: Offset(-1.5, -1.5),
      blurRadius: 3.0,
      color: Color.fromRGBO(255, 255, 255, 0.95),
    ),
  ];

  static const List<BoxShadow> _keyShadowsDark = [
    BoxShadow(
      offset: Offset(2.0, 2.5),
      blurRadius: 4.0,
      color: Color.fromRGBO(0, 0, 0, 0.55),
    ),
    BoxShadow(
      offset: Offset(-1.5, -1.5),
      blurRadius: 3.0,
      color: Color.fromRGBO(255, 255, 255, 0.08),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAccelerators) ...[
          _buildAcceleratorHeader(context, isDark),
          const SizedBox(height: 12.0),
        ],
        _buildKeypadGrid(context, isDark),
      ],
    );
  }

  Widget _buildAcceleratorHeader(BuildContext context, bool isDark) {
    final shadows = isDark ? _keyShadowsDark : _keyShadowsLight;

    return Row(
      children: [
        ...acceleratorDenoms.map(
          (int denom) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: ClayButton(
                key: Key('clay_chip_${denom ~/ 1000}k'),
                height: 36.0,
                padding: EdgeInsets.zero,
                semanticLabel: 'Tambah ${denom ~/ 1000} ribu Rupiah',
                color: isDark
                    ? ClayColors.surfaceContainerDarkHigh
                    : ClayColors.tertiaryFixed,
                borderRadius: BorderRadius.circular(18.0),
                customShadows: shadows,
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
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showBackspaceInHeader)
          Padding(
            padding: const EdgeInsets.only(left: 3.0),
            child: SizedBox(
              width: 48.0,
              height: 36.0,
              child: ClayButton(
                key: const Key('clay_key_backspace'),
                padding: EdgeInsets.zero,
                semanticLabel: 'Hapus satu digit',
                color: isDark
                    ? ClayColors.surfaceContainerDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(18.0),
                customShadows: shadows,
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
      _KeyItem(label: '7', type: _KeyType.digit, keyId: '7', semanticLabel: 'Angka 7'),
      _KeyItem(label: '8', type: _KeyType.digit, keyId: '8', semanticLabel: 'Angka 8'),
      _KeyItem(label: '9', type: _KeyType.digit, keyId: '9', semanticLabel: 'Angka 9'),
      _KeyItem(label: '÷', type: _KeyType.operator, keyId: 'divide', semanticLabel: 'Operasi Pembagian'),
    ],
    [
      _KeyItem(label: '4', type: _KeyType.digit, keyId: '4', semanticLabel: 'Angka 4'),
      _KeyItem(label: '5', type: _KeyType.digit, keyId: '5', semanticLabel: 'Angka 5'),
      _KeyItem(label: '6', type: _KeyType.digit, keyId: '6', semanticLabel: 'Angka 6'),
      _KeyItem(label: '\u00D7', type: _KeyType.operator, keyId: 'multiply', semanticLabel: 'Operasi Perkalian'),
    ],
    [
      _KeyItem(label: '1', type: _KeyType.digit, keyId: '1', semanticLabel: 'Angka 1'),
      _KeyItem(label: '2', type: _KeyType.digit, keyId: '2', semanticLabel: 'Angka 2'),
      _KeyItem(label: '3', type: _KeyType.digit, keyId: '3', semanticLabel: 'Angka 3'),
      _KeyItem(label: '-', type: _KeyType.operator, keyId: 'minus', semanticLabel: 'Operasi Pengurangan'),
    ],
    [
      _KeyItem(label: 'C', type: _KeyType.clear, keyId: 'clear', semanticLabel: 'Hapus Semua Nominal'),
      _KeyItem(label: '0', type: _KeyType.digit, keyId: '0', semanticLabel: 'Angka 0'),
      _KeyItem(label: '000', type: _KeyType.digit, keyId: '000', semanticLabel: 'Tiga Nol Ribu'),
      _KeyItem(label: '+', type: _KeyType.operator, keyId: 'plus', semanticLabel: 'Operasi Penjumlahan'),
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
            : Colors.white;
        textColor = Theme.of(context).colorScheme.onSurface;
        break;
      case _KeyType.operator:
        buttonColor = isDark
            ? ClayColors.surfaceContainerDarkHigh
            : ClayColors.secondaryFixed;
        textColor = ClayColors.onSecondaryContainer;
        break;
      case _KeyType.clear:
        buttonColor = isDark
            ? const Color(0xFF4A1818)
            : ClayColors.errorContainer;
        textColor = ClayColors.error;
        break;
    }

    final shadows = isDark ? _keyShadowsDark : _keyShadowsLight;

    return ClayButton(
      key: Key('clay_key_${item.keyId}'),
      height: 48.0,
      padding: EdgeInsets.zero,
      semanticLabel: item.semanticLabel,
      color: buttonColor,
      borderRadius: BorderRadius.circular(16.0),
      customShadows: shadows,
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
              ? ClayTypography.headlineSm(color: textColor).copyWith(
                  fontWeight: FontWeight.w700,
                )
              : ClayTypography.headlineMd(color: textColor).copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
  const _KeyItem({
    required this.label,
    required this.type,
    required this.keyId,
    this.semanticLabel,
  });

  final String label;
  final _KeyType type;
  final String keyId;
  final String? semanticLabel;
}
