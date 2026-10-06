import '../models/category.dart';

class CategoryClassification {
  final String name;
  final String icon;
  final String color;
  final CategoryType type;

  const CategoryClassification(this.name, this.icon, this.color, this.type);
}

class AICategoryClassifier {
  static final Map<String, CategoryClassification> _keywordMap = {
    // Income
    'gaji': const CategoryClassification('Gaji', 'briefcase', '16A34A', CategoryType.income),
    'honor': const CategoryClassification('Gaji', 'briefcase', '16A34A', CategoryType.income),
    'upah': const CategoryClassification('Gaji', 'briefcase', '16A34A', CategoryType.income),
    'freelance': const CategoryClassification('Freelance', 'laptop', '0D9488', CategoryType.income),
    'project': const CategoryClassification('Freelance', 'laptop', '0D9488', CategoryType.income),
    'coding': const CategoryClassification('Freelance', 'laptop', '0D9488', CategoryType.income),
    'desain': const CategoryClassification('Freelance', 'pen_tool', '0D9488', CategoryType.income),
    'jual': const CategoryClassification('Penjualan', 'shopping_bag', 'F59E0B', CategoryType.income),
    'laku': const CategoryClassification('Penjualan', 'shopping_bag', 'F59E0B', CategoryType.income),
    'kirim': const CategoryClassification('Uang Saku', 'gift', '10B981', CategoryType.income),
    'saku': const CategoryClassification('Uang Saku', 'wallet', '10B981', CategoryType.income),
    'jajan masuk': const CategoryClassification('Uang Saku', 'wallet', '10B981', CategoryType.income),
    'orang tua': const CategoryClassification('Uang Saku', 'gift', '10B981', CategoryType.income),
    'bonus': const CategoryClassification('Bonus', 'star', 'F59E0B', CategoryType.income),
    'insentif': const CategoryClassification('Bonus', 'star', 'F59E0B', CategoryType.income),
    'bunga': const CategoryClassification('Bunga', 'trending_up', '3B82F6', CategoryType.income),

    // Expense
    'kopi': const CategoryClassification('Minuman', 'coffee', 'F59E0B', CategoryType.expense),
    'minum': const CategoryClassification('Minuman', 'coffee', 'F59E0B', CategoryType.expense),
    'tea': const CategoryClassification('Minuman', 'coffee', 'F59E0B', CategoryType.expense),
    'boba': const CategoryClassification('Minuman', 'coffee', 'F59E0B', CategoryType.expense),
    'makan': const CategoryClassification('Makanan', 'utensils', 'EF4444', CategoryType.expense),
    'nasi': const CategoryClassification('Makanan', 'utensils', 'EF4444', CategoryType.expense),
    'mie': const CategoryClassification('Makanan', 'utensils', 'EF4444', CategoryType.expense),
    'ayam': const CategoryClassification('Makanan', 'utensils', 'EF4444', CategoryType.expense),
    'soto': const CategoryClassification('Makanan', 'utensils', 'EF4444', CategoryType.expense),
    'roti': const CategoryClassification('Makanan', 'utensils', 'EF4444', CategoryType.expense),
    'lotion': const CategoryClassification('Perawatan Diri', 'heart', 'EC4899', CategoryType.expense),
    'skincare': const CategoryClassification('Perawatan Diri', 'heart', 'EC4899', CategoryType.expense),
    'facial': const CategoryClassification('Perawatan Diri', 'heart', 'EC4899', CategoryType.expense),
    'cukur': const CategoryClassification('Perawatan Diri', 'scissors', 'EC4899', CategoryType.expense),
    'rambut': const CategoryClassification('Perawatan Diri', 'scissors', 'EC4899', CategoryType.expense),
    'sabun': const CategoryClassification('Kebutuhan Rumah', 'home', '8B5CF6', CategoryType.expense),
    'deterjen': const CategoryClassification('Kebutuhan Rumah', 'home', '8B5CF6', CategoryType.expense),
    'galon': const CategoryClassification('Kebutuhan Rumah', 'home', '8B5CF6', CategoryType.expense),
    'gas': const CategoryClassification('Kebutuhan Rumah', 'home', '8B5CF6', CategoryType.expense),
    'internet': const CategoryClassification('Tagihan', 'wifi', '6366F1', CategoryType.expense),
    'listrik': const CategoryClassification('Tagihan', 'zap', '6366F1', CategoryType.expense),
    'pulsa': const CategoryClassification('Tagihan', 'smartphone', '6366F1', CategoryType.expense),
    'langganan': const CategoryClassification('Tagihan', 'credit_card', '6366F1', CategoryType.expense),
    'apotek': const CategoryClassification('Kesehatan', 'activity', 'EF4444', CategoryType.expense),
    'dokter': const CategoryClassification('Kesehatan', 'activity', 'EF4444', CategoryType.expense),
    'obat': const CategoryClassification('Kesehatan', 'activity', 'EF4444', CategoryType.expense),
    'klinik': const CategoryClassification('Kesehatan', 'activity', 'EF4444', CategoryType.expense),
    'konser': const CategoryClassification('Hiburan', 'music', '8B5CF6', CategoryType.expense),
    'game': const CategoryClassification('Hiburan', 'monitor', '8B5CF6', CategoryType.expense),
    'billiard': const CategoryClassification('Hiburan', 'target', '8B5CF6', CategoryType.expense),
    'nonton': const CategoryClassification('Hiburan', 'film', '8B5CF6', CategoryType.expense),
    'wisata': const CategoryClassification('Hiburan', 'map', '8B5CF6', CategoryType.expense),
    'buku': const CategoryClassification('Pendidikan', 'book', '3B82F6', CategoryType.expense),
    'kuliah': const CategoryClassification('Pendidikan', 'book_open', '3B82F6', CategoryType.expense),
    'print': const CategoryClassification('Pendidikan', 'printer', '3B82F6', CategoryType.expense),
    'fotokopi': const CategoryClassification('Pendidikan', 'copy', '3B82F6', CategoryType.expense),
    'motor': const CategoryClassification('Transportasi', 'car', '3B82F6', CategoryType.expense),
    'bensin': const CategoryClassification('Transportasi', 'car', '3B82F6', CategoryType.expense),
    'taksi': const CategoryClassification('Transportasi', 'car', '3B82F6', CategoryType.expense),
    'ojek': const CategoryClassification('Transportasi', 'car', '3B82F6', CategoryType.expense),
    'grab': const CategoryClassification('Transportasi', 'car', '3B82F6', CategoryType.expense),
    'sepatu': const CategoryClassification('Belanja', 'shopping_bag', 'EC4899', CategoryType.expense),
    'baju': const CategoryClassification('Belanja', 'shopping_bag', 'EC4899', CategoryType.expense),
    'tas': const CategoryClassification('Belanja', 'shopping_bag', 'EC4899', CategoryType.expense),
    'kos': const CategoryClassification('Tempat Tinggal', 'home', '8B5CF6', CategoryType.expense),
    'kontrakan': const CategoryClassification('Tempat Tinggal', 'home', '8B5CF6', CategoryType.expense),
    'sewa': const CategoryClassification('Tempat Tinggal', 'home', '8B5CF6', CategoryType.expense),
  };

  static CategoryClassification classify(String text, bool isIncome) {
    final lower = text.toLowerCase();
    
    // Check keyword map
    for (final entry in _keywordMap.entries) {
      if (lower.contains(entry.key)) {
        // Return only if the type matches what was detected (income/expense)
        if (entry.value.type == CategoryType.income && isIncome) {
          return entry.value;
        } else if (entry.value.type == CategoryType.expense && !isIncome) {
          return entry.value;
        }
      }
    }

    // Fallbacks
    if (isIncome) {
      return const CategoryClassification('Pendapatan Lain', 'plus_circle', '10B981', CategoryType.income);
    }
    return const CategoryClassification('Lain-lain', 'more_horizontal', '64748B', CategoryType.expense);
  }
}
