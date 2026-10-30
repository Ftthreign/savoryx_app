import 'package:flutter/material.dart';
import '../theme/clay_colors.dart';
import '../theme/clay_shadows.dart';
import '../utils/constants.dart';

/// Fundamental Claymorphism container widget.
/// Encapsulates dual-shadow depth, custom bevel curves, and surface specular reflection.
class ClayContainer extends StatelessWidget {
  const ClayContainer({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.isPressed = false,
    this.showSpecularGlint = true,
    this.customShadows,
  });

  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool isPressed;
  final bool showSpecularGlint;
  final List<BoxShadow>? customShadows;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveColor = color ??
        (isDark ? ClayColors.surfaceContainerDark : ClayColors.surfaceContainerLowest);
    final BorderRadius effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppConstants.clayBorderRadius);

    final List<BoxShadow> effectiveShadows = customShadows ??
        (isPressed
            ? ClayShadows.pressed(isDark: isDark)
            : ClayShadows.elevated(isDark: isDark));

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: effectiveRadius,
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Stack(
          children: [
            if (showSpecularGlint && !isPressed)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: ClayShadows.specularReflectionGradient,
                  ),
                ),
              ),
            Padding(
              padding: padding ?? const EdgeInsets.all(16.0),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
