import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/utils/constants.dart';

/// Tactile interactive Claymorphism button with 120ms spring compression,
/// scale feedback (0.96), dual-shadow depth transition, and haptic impact.
class ClayButton extends StatefulWidget {
  const ClayButton({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.borderRadius,
    this.padding,
    this.width,
    this.height,
    this.isPrimaryCta = false,
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool isPrimaryCta;
  final bool enableHaptic;

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: AppConstants.clayPressAnimationDurationMs,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppConstants.clayPressedScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius effectiveRadius = widget.borderRadius ??
        BorderRadius.circular(
          widget.isPrimaryCta
              ? AppConstants.clayPillRadius
              : AppConstants.clayCardBorderRadius,
        );

    final Color effectiveColor = widget.color ??
        (widget.isPrimaryCta
            ? ClayColors.primary
            : (isDark
                ? ClayColors.surfaceContainerDark
                : ClayColors.surfaceContainerLow));

    final List<BoxShadow> effectiveShadows = widget.isPrimaryCta
        ? ClayShadows.primaryCta(isPressed: _isPressed)
        : (_isPressed
            ? ClayShadows.pressed(isDark: isDark)
            : ClayShadows.elevated(isDark: isDark));

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          key: const ValueKey('clay_button_scale_transition'),
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: AppConstants.clayPressAnimationDurationMs,
            ),
            curve: Curves.easeOutCubic,
            width: widget.width,
            height: widget.height,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: effectiveRadius,
              boxShadow: effectiveShadows,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
