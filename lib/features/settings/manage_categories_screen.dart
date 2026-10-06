import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme/app_colors.dart';
import '../../models/category.dart';
import '../../providers/finance_provider.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  int _tabIndex = 0; // 0 = Aktif, 1 = Diarsipkan

  void _showCategoryDialog([FinancialCategory? category]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: category?.name);
    String selectedIcon = category?.iconName ?? 'category';
    String selectedColor = category?.colorHex ?? '6366F1';
    CategoryType selectedType = category?.type ?? CategoryType.expense;

    final icons = [
      'category', 'restaurant', 'local_cafe', 'shopping_bag',
      'directions_car', 'receipt', 'home', 'movie', 'favorite',
      'work', 'account_balance', 'attach_money', 'card_giftcard'
    ];

    final colors = [
      '6366F1', // Indigo
      'EC4899', // Pink
      'F59E0B', // Amber
      '10B981', // Emerald
      '3B82F6', // Blue
      '8B5CF6', // Purple
      'EF4444', // Red
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              category == null ? 'Tambah Kategori' : 'Edit Kategori',
              style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipe
                  Text('Tipe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                  const SizedBox(height: 8),
                  SegmentedButton<CategoryType>(
                    segments: const [
                      ButtonSegment(value: CategoryType.expense, label: Text('Pengeluaran')),
                      ButtonSegment(value: CategoryType.income, label: Text('Pemasukan')),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (set) => setDialogState(() => selectedType = set.first),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nama
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori',
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : AppColors.lightBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ikon
                  Text('Ikon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: icons.map((iconName) {
                      final isSelected = iconName == selectedIcon;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = iconName),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.expense.withOpacity(0.2) : Colors.transparent,
                            border: Border.all(color: isSelected ? AppColors.expense : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getIconData(iconName), color: isSelected ? AppColors.expense : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Warna
                  Text('Warna', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: colors.map((hex) {
                      final isSelected = hex == selectedColor;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = hex),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Color(int.parse('0xFF$hex')),
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent, width: 2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final finance = context.read<FinanceProvider>();
                  
                  if (category == null) {
                    finance.addCategory(FinancialCategory(
                      id: 'cat_${const Uuid().v4()}',
                      name: nameCtrl.text.trim(),
                      iconName: selectedIcon,
                      colorHex: selectedColor,
                      type: selectedType,
                    ));
                  } else {
                    finance.updateCategory(FinancialCategory(
                      id: category.id,
                      name: nameCtrl.text.trim(),
                      iconName: selectedIcon,
                      colorHex: selectedColor,
                      type: selectedType,
                      isArchived: category.isArchived,
                      isDefault: category.isDefault,
                    ));
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant_rounded;
      case 'local_cafe': return Icons.local_cafe_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'directions_car': return Icons.directions_car_rounded;
      case 'receipt': return Icons.receipt_long_rounded;
      case 'home': return Icons.home_rounded;
      case 'movie': return Icons.movie_creation_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'work': return Icons.work_rounded;
      case 'account_balance': return Icons.account_balance_rounded;
      case 'attach_money': return Icons.attach_money_rounded;
      case 'card_giftcard': return Icons.card_giftcard_rounded;
      default: return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeList = finance.activeCategories;
    final archivedList = finance.archivedCategories;

    final expenseCats = activeList.where((c) => c.type == CategoryType.expense).toList();
    final incomeCats = activeList.where((c) => c.type == CategoryType.income).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Kelola Kategori', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightBg,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Segmented Tab: Aktif vs Diarsipkan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevatedCard : Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _tabIndex == 0 ? (isDark ? AppColors.darkCard : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _tabIndex == 0 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                        ),
                        child: Center(
                          child: Text(
                            'Aktif (${activeList.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _tabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                              color: _tabIndex == 0
                                  ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _tabIndex == 1 ? (isDark ? AppColors.darkCard : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _tabIndex == 1 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                        ),
                        child: Center(
                          child: Text(
                            'Diarsipkan (${archivedList.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _tabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                              color: _tabIndex == 1
                                  ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content List
          Expanded(
            child: _tabIndex == 0
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      _buildCategorySection('Pengeluaran', expenseCats, isDark, finance, isArchived: false),
                      const SizedBox(height: 24),
                      _buildCategorySection('Pemasukan', incomeCats, isDark, finance, isArchived: false),
                    ],
                  )
                : (archivedList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.archive_outlined, size: 48, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada kategori yang diarsipkan.',
                              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        children: [
                          _buildCategorySection('Kategori Diarsipkan', archivedList, isDark, finance, isArchived: true),
                        ],
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    String title,
    List<FinancialCategory> categories,
    bool isDark,
    FinanceProvider finance, {
    required bool isArchived,
  }) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${cat.colorHex}')).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIconData(cat.iconName), color: Color(int.parse('0xFF${cat.colorHex}')), size: 20),
                ),
                title: Text(
                  cat.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: isArchived
                    ? Text('Diarsipkan • Riwayat tetap tersimpan', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isArchived) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        tooltip: 'Edit Kategori',
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                        onPressed: () => _showCategoryDialog(cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.archive_outlined, size: 20),
                        tooltip: 'Arsipkan Kategori',
                        color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
                        onPressed: () {
                          finance.archiveCategory(cat.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kategori "${cat.name}" berhasil diarsipkan.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        tooltip: 'Hapus Kategori',
                        color: AppColors.expense,
                        onPressed: () {
                          final isUsed = finance.transactions.any((t) => t.categoryId == cat.id);
                          finance.deleteCategory(cat.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isUsed
                                    ? 'Kategori sedang digunakan dan otomatis diarsipkan agar riwayat transaksi tetap aman.'
                                    : 'Kategori "${cat.name}" berhasil dihapus.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      IconButton(
                        icon: const Icon(Icons.unarchive_outlined, size: 20),
                        tooltip: 'Pulihkan Kategori',
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                        onPressed: () {
                          finance.unarchiveCategory(cat.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kategori "${cat.name}" berhasil dipulihkan ke daftar aktif.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
