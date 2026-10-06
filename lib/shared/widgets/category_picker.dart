import 'package:flutter/material.dart';
import '../../core/theme/astrack_theme_extension.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_radius.dart';

class CategoryItemData {
  final String id;
  final String name;
  final IconData icon;
  final Color? color;

  const CategoryItemData({
    required this.id,
    required this.name,
    required this.icon,
    this.color,
  });
}

/// Bottom Sheet or Modal Category Picker
class CategoryPicker extends StatefulWidget {
  final List<CategoryItemData> categories;
  final String? selectedCategoryId;
  final ValueChanged<CategoryItemData> onSelect;
  final String title;

  const CategoryPicker({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onSelect,
    this.title = 'Pilih Kategori',
  });

  static Future<CategoryItemData?> show(
    BuildContext context, {
    required List<CategoryItemData> categories,
    String? selectedCategoryId,
    String title = 'Pilih Kategori',
  }) {
    return showModalBottomSheet<CategoryItemData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryPicker(
        categories: categories,
        selectedCategoryId: selectedCategoryId,
        title: title,
        onSelect: (cat) => Navigator.of(ctx).pop(cat),
      ),
    );
  }

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = context.astrackTheme;
    final filtered = widget.categories
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: AppRadius.sheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: AppRadius.full,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Search box
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Cari kategori...',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: theme.textSecondary),
              filled: true,
              fillColor: theme.surfaceSubtle,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: BorderSide(color: theme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide: BorderSide(color: theme.border),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, idx) {
                final cat = filtered[idx];
                final isSelected = cat.id == widget.selectedCategoryId;
                final catColor = cat.color ?? theme.primaryEmerald;

                return GestureDetector(
                  onTap: () => widget.onSelect(cat),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withValues(alpha: 0.25)
                              : theme.surfaceSubtle,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? catColor : theme.border,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Icon(
                          cat.icon,
                          color: isSelected ? catColor : theme.textPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? catColor : theme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
