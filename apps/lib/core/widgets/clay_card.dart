import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/utils/constants.dart';
import 'package:savoryx/core/widgets/clay_container.dart';

/// Elevated Claymorphism card for financial stats, accounts and transactions.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.isHero = false,
    this.onTap,
  });

  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool isHero;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius effectiveRadius = borderRadius ??
        BorderRadius.circular(
          isHero
              ? AppConstants.clayHeroCardBorderRadius
              : AppConstants.clayCardBorderRadius,
        );

    final Color effectiveColor = color ??
        (isHero
            ? (isDark ? const Color(0xFF383110) : ClayColors.secondaryContainer)
            : (isDark
                ? ClayColors.surfaceContainerDark
                : ClayColors.surfaceContainerLowest));

    final List<BoxShadow> effectiveShadows =
        isHero ? ClayShadows.heroCard(isDark: isDark) : ClayShadows.elevated(isDark: isDark);

    Widget cardWidget = ClayContainer(
      width: width,
      height: height,
      color: effectiveColor,
      borderRadius: effectiveRadius,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20.0),
      customShadows: effectiveShadows,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
