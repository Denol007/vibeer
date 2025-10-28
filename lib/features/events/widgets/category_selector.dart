import 'package:flutter/material.dart';
import 'package:vibe_app/features/events/models/event_category.dart';

/// Widget for selecting an event category
///
/// Displays a grid of category options with emoji, name, and color coding.
/// Used in event creation and filtering.
class CategorySelector extends StatelessWidget {
  final EventCategory selectedCategory;
  final ValueChanged<EventCategory> onCategorySelected;
  final bool showAllCategories;
  final String? label;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.showAllCategories = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final categories = showAllCategories
        ? EventCategory.values
        : EventCategory.mainCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category == selectedCategory;

            return _CategoryOption(
              category: category,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category),
            );
          },
        ),
      ],
    );
  }
}

/// Individual category option card
class _CategoryOption extends StatelessWidget {
  final EventCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? category.lightColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? category.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                category.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? category.color : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable chip selector for filtering
///
/// Used in map and list screens for quick category filtering.
class CategoryChipSelector extends StatelessWidget {
  final Set<EventCategory> selectedCategories;
  final ValueChanged<EventCategory> onCategoryToggled;
  final bool showAllOption;

  const CategoryChipSelector({
    super.key,
    required this.selectedCategories,
    required this.onCategoryToggled,
    this.showAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedCategories.isEmpty;
    final categories = EventCategory.mainCategories;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (showAllOption) ...[
            _CategoryChip(
              label: 'Все',
              emoji: '📋',
              isSelected: allSelected,
              color: Colors.blue,
              onTap: () {
                // Clear selection to show all
                for (final category in List.from(selectedCategories)) {
                  onCategoryToggled(category);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          ...categories.map((category) {
            final isSelected = selectedCategories.contains(category);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChip(
                label: category.displayName,
                emoji: category.emoji,
                isSelected: isSelected,
                color: category.color,
                onTap: () => onCategoryToggled(category),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Individual filter chip for category
class _CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
