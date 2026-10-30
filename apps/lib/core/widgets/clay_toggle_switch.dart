import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/clay_colors.dart';
import '../theme/clay_shadows.dart';

/// Tactile Neomorphic Pill Switch as seen in Stitch "Mark as Talangan".
class ClayToggleSwitch extends StatelessWidget {
  const ClayToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? thumbColor;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveActiveTrack =
        activeTrackColor ?? ClayColors.tertiaryFixed;
    final Color effectiveInactiveTrack = inactiveTrackColor ??
        (isDark ? ClayColors.surfaceContainerDark : ClayColors.surfaceContainer);
    final Color effectiveThumb = thumbColor ??
        (isDark ? ClayColors.surfaceContainerDarkHigh : ClayColors.surfaceContainerLowest);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 56.0,
        height: 32.0,
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: value ? effectiveActiveTrack : effectiveInactiveTrack,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: ClayShadows.pressed(isDark: isDark, scale: 0.8),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24.0,
            height: 24.0,
            decoration: BoxDecoration(
              color: effectiveThumb,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  offset: Offset(2.0, 2.0),
                  blurRadius: 4.0,
                  color: Color.fromRGBO(163, 177, 198, 0.45),
                ),
                BoxShadow(
                  offset: Offset(-1.0, -1.0),
                  blurRadius: 3.0,
                  color: Color.fromRGBO(255, 255, 255, 0.90),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
