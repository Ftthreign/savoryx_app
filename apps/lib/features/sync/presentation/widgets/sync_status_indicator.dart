import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/constants.dart';
import 'package:savoryx/features/sync/presentation/bloc/sync_state.dart';

/// Compact Claymorphism top-bar indicator displaying live sync progress,
/// offline outbox pending badge, and tap-to-sync / retry interaction.
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({
    super.key,
    required this.state,
    this.onTap,
  });

  final SyncState state;
  final VoidCallback? onTap;

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant SyncStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncAnimationState();
    }
  }

  void _syncAnimationState() {
    if (widget.state is Syncing) {
      if (!_spinController.isAnimating) {
        _spinController.repeat();
      }
    } else {
      if (_spinController.isAnimating) {
        _spinController.stop();
        _spinController.reset();
      }
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingCount = widget.state.currentPendingCount;

    final _IndicatorAppearance appearance = switch (widget.state) {
      Syncing() => _IndicatorAppearance(
          backgroundColor: ClayColors.secondaryFixed,
          iconColor: ClayColors.secondaryDeep,
          icon: Icons.sync_rounded,
          semanticLabel: 'Sedang menyinkronkan $pendingCount perubahan',
        ),
      SyncFailure() => const _IndicatorAppearance(
          backgroundColor: ClayColors.primaryContainer,
          iconColor: ClayColors.primary,
          icon: Icons.sync_problem_rounded,
          semanticLabel: 'Sinkronisasi gagal. Ketuk untuk mengulang',
        ),
      SyncSuccess() when pendingCount == 0 => const _IndicatorAppearance(
          backgroundColor: ClayColors.tertiaryChip,
          iconColor: ClayColors.tertiary,
          icon: Icons.cloud_done_rounded,
          semanticLabel: 'Semua data tersinkronisasi',
        ),
      _ when pendingCount > 0 => _IndicatorAppearance(
          backgroundColor: ClayColors.secondaryContainer,
          iconColor: ClayColors.secondary,
          icon: Icons.cloud_upload_rounded,
          semanticLabel: '$pendingCount perubahan menunggu sinkronisasi',
        ),
      _ => _IndicatorAppearance(
          backgroundColor: isDark
              ? ClayColors.surfaceContainerDarkHigh
              : ClayColors.surfaceContainerLow,
          iconColor: ClayColors.tertiaryAccent,
          icon: Icons.cloud_done_rounded,
          semanticLabel: 'Status sinkronisasi siaga',
        ),
    };

    final borderRadius = BorderRadius.circular(AppConstants.clayBorderRadius);

    return Semantics(
      button: widget.onTap != null,
      label: appearance.semanticLabel,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: appearance.backgroundColor,
                borderRadius: borderRadius,
                boxShadow: ClayShadows.elevated(isDark: isDark, scale: 0.72),
              ),
              child: Center(
                child: widget.state is Syncing
                    ? RotationTransition(
                        turns: _spinController,
                        child: Icon(
                          appearance.icon,
                          size: 20.0,
                          color: appearance.iconColor,
                        ),
                      )
                    : Icon(
                        appearance.icon,
                        size: 20.0,
                        color: appearance.iconColor,
                      ),
              ),
            ),
            if (pendingCount > 0)
              Positioned(
                top: -5.0,
                right: -5.0,
                child: Container(
                  key: const Key('sync_pending_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5.0,
                    vertical: 1.5,
                  ),
                  constraints: const BoxConstraints(minWidth: 18.0),
                  decoration: BoxDecoration(
                    color: widget.state is SyncFailure
                        ? ClayColors.primary
                        : ClayColors.secondaryFixed,
                    borderRadius:
                        BorderRadius.circular(AppConstants.clayBorderRadius),
                    border: Border.all(
                      color: isDark
                          ? ClayColors.canvasDark
                          : ClayColors.surfaceContainerLowest,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    pendingCount > 99 ? '99+' : '$pendingCount',
                    textAlign: TextAlign.center,
                    style: ClayTypography.labelSm(
                      color: widget.state is SyncFailure
                          ? ClayColors.onPrimary
                          : ClayColors.onSecondaryContainer,
                    ).copyWith(fontSize: 10.0, height: 1.1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorAppearance {
  const _IndicatorAppearance({
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.semanticLabel,
  });

  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String semanticLabel;
}
