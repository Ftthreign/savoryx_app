import 'package:flutter/material.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/widgets/clay_button.dart';

class CategorySelectorGrid extends StatelessWidget {
  const CategorySelectorGrid({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.isWantsMap,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final Map<String, bool>? isWantsMap;

  static const List<BoxShadow> _chipShadowsLight = [
    BoxShadow(
      offset: Offset(1.5, 2.5),
      blurRadius: 4.0,
      color: Color.fromRGBO(163, 177, 198, 0.45),
    ),
    BoxShadow(
      offset: Offset(-1.0, -1.0),
      blurRadius: 3.0,
      color: Color.fromRGBO(255, 255, 255, 0.95),
    ),
  ];

  static const List<BoxShadow> _chipShadowsDark = [
    BoxShadow(
      offset: Offset(1.5, 2.5),
      blurRadius: 4.0,
      color: Color.fromRGBO(0, 0, 0, 0.50),
    ),
    BoxShadow(
      offset: Offset(-1.0, -1.0),
      blurRadius: 3.0,
      color: Color.fromRGBO(255, 255, 255, 0.08),
    ),
  ];

  static const List<BoxShadow> _chipSelectedShadows = [
    BoxShadow(
      offset: Offset(0.0, 3.0),
      blurRadius: 6.0,
      color: Color(0x3BBA1A1A),
    ),
    BoxShadow(
      offset: Offset(-1.0, -1.0),
      blurRadius: 2.0,
      color: Color.fromRGBO(255, 255, 255, 0.35),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44.0,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final String cat = categories[index];
          final bool isSelected = cat == selectedCategory;

          final shadows = isSelected
              ? _chipSelectedShadows
              : (isDark ? _chipShadowsDark : _chipShadowsLight);

          return ClayButton(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            borderRadius: BorderRadius.circular(20.0),
            customShadows: shadows,
            color: isSelected
                ? ClayColors.primary
                : (isDark
                    ? ClayColors.surfaceContainerDark
                    : Colors.white),
            onTap: () => onCategorySelected(cat),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isWantsMap != null && isWantsMap![cat] != null) ...[
                  Container(
                    width: 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isWantsMap![cat]!
                          ? (isSelected ? Colors.white70 : ClayColors.secondary)
                          : (isSelected ? Colors.white70 : ClayColors.tertiary),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                ],
                Text(
                  cat,
                  style: ClayTypography.labelMd(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
