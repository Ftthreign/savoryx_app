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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final String cat = categories[index];
          final bool isSelected = cat == selectedCategory;

          return ClayButton(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            borderRadius: BorderRadius.circular(21.0),
            color: isSelected
                ? ClayColors.primary
                : (isDark
                    ? ClayColors.surfaceContainerDark
                    : ClayColors.surfaceContainerLow),
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
                          ? ClayColors.secondary
                          : ClayColors.tertiary,
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
