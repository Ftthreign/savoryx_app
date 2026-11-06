import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/utils/constants.dart';

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
    this.constraints,
    this.isPressed = false,
    this.showSpecularGlint = true,
    this.showBorder = false,
    this.border,
    this.customShadows,
    this.semanticLabel,
  });

  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final bool isPressed;
  final bool showSpecularGlint;
  final bool showBorder;
  final Border? border;
  final List<BoxShadow>? customShadows;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveColor = color ??
        (isDark
            ? ClayColors.surfaceContainerDark
            : ClayColors.surfaceContainerLowest);
    final BorderRadius effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppConstants.clayBorderRadius);

    final List<BoxShadow> effectiveShadows = customShadows ??
        (isPressed
            ? ClayShadows.pressed(isDark: isDark)
            : ClayShadows.elevated(isDark: isDark));

    final Border? effectiveBorder = showBorder
        ? (border ??
            Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.85),
              width: 1.5,
            ))
        : null;

    final Widget containerWidget = Container(
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
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

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        container: true,
        excludeSemantics: true,
        child: containerWidget,
      );
    }

    return containerWidget;
  }
}
