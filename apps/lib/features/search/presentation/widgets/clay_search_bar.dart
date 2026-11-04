import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/theme/clay_typography.dart';

/// Tactile Claymorphism search bar with integrated 150ms debouncing.
class ClaySearchBar extends StatefulWidget {
  const ClaySearchBar({
    super.key,
    this.controller,
    this.hintText = 'Cari catatan, merchant, #tag...',
    this.onSearchDebounced,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onFilterTap,
    this.debounceDuration = const Duration(milliseconds: 150),
    this.autofocus = false,
    this.hasActiveFilter = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onSearchDebounced;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final Duration debounceDuration;
  final bool autofocus;
  final bool hasActiveFilter;

  @override
  State<ClaySearchBar> createState() => _ClaySearchBarState();
}

class _ClaySearchBarState extends State<ClaySearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.removeListener(_onTextChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChange() {
    final hasTextNow = _controller.text.isNotEmpty;
    if (hasTextNow != _hasText) {
      setState(() {
        _hasText = hasTextNow;
      });
    }

    widget.onChanged?.call(_controller.text);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        widget.onSearchDebounced?.call(_controller.text);
      }
    });
  }

  void _handleClear() {
    HapticFeedback.lightImpact();
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onClear?.call();
    widget.onSearchDebounced?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? ClayColors.surfaceDark : ClayColors.surfaceContainerLow;
    final textColor = isDark ? ClayColors.onSurfaceDark : ClayColors.onSurface;
    final hintColor = isDark ? ClayColors.onSurfaceVariantDark : ClayColors.outline;

    return Semantics(
      textField: true,
      label: 'Search transactions input',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: _isFocused
              ? ClayShadows.pressed(isDark: isDark, scale: 0.7)
              : ClayShadows.elevated(isDark: isDark, scale: 0.8),
          border: Border.all(
            color: _isFocused
                ? (isDark ? ClayColors.primaryHighlight : ClayColors.primary)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: _isFocused
                    ? (isDark ? ClayColors.primaryHighlight : ClayColors.primary)
                    : hintColor,
                size: 22.0,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: TextField(
                  key: const Key('clay_search_bar_text_field'),
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  style: ClayTypography.bodyLg(color: textColor),
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onSubmitted,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: ClayTypography.bodyMd(color: hintColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
              if (_hasText)
                GestureDetector(
                  key: const Key('clay_search_bar_clear_button'),
                  onTap: _handleClear,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? ClayColors.surfaceContainerDark : ClayColors.surfaceContainerHigh,
                      ),
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14.0,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              if (widget.onFilterTap != null) ...[
                const SizedBox(width: 4.0),
                GestureDetector(
                  key: const Key('clay_search_bar_filter_button'),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onFilterTap?.call();
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: widget.hasActiveFilter
                              ? (isDark ? ClayColors.primary.withOpacity(0.25) : ClayColors.primaryContainer)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20.0,
                          color: widget.hasActiveFilter
                              ? (isDark ? ClayColors.primaryHighlight : ClayColors.primary)
                              : hintColor,
                        ),
                      ),
                      if (widget.hasActiveFilter)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: ClayColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
