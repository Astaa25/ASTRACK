import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Centralized Localization and Currency Formatting System for ASTRACK
/// Default: Bahasa Indonesia (id), Prepared for English (en)
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const Locale defaultLocale = Locale('id', 'ID');
  static const List<Locale> supportedLocales = [
    Locale('id', 'ID'),
    Locale('en', 'US'),
  ];

  static AppLocalizations of(BuildContext context) {
    final currentLocale = Localizations.maybeLocaleOf(context) ?? defaultLocale;
    return AppLocalizations(currentLocale);
  }

  bool get isIndonesian => locale.languageCode == 'id';

  // --- Financial Dictionary ---
  String get appTitle => 'ASTRACK';
  String get tagline => 'Track Your Money, Shape Your Future';
  String get totalBalance => isIndonesian ? 'Total Saldo' : 'Total Balance';
  String get safeToSpend => isIndonesian ? 'Safe to Spend' : 'Safe to Spend';
  String get monthlyExpense => isIndonesian ? 'Pengeluaran Bulan Ini' : 'This Month Spending';
  String get monthlyIncome => isIndonesian ? 'Pemasukan Bulan Ini' : 'This Month Income';
  String get budget => isIndonesian ? 'Anggaran' : 'Budget';
  String get recentTransactions => isIndonesian ? 'Transaksi Terbaru' : 'Recent Transactions';
  String get seeAll => isIndonesian ? 'Lihat Semua' : 'See All';
  String get uangJajan => isIndonesian ? 'Uang Jajan' : 'Pocket Money';
  String get tabungan => isIndonesian ? 'Tabungan' : 'Savings';
  String get expense => isIndonesian ? 'Pengeluaran' : 'Expense';
  String get income => isIndonesian ? 'Pemasukan' : 'Income';
  String get transfer => isIndonesian ? 'Transfer' : 'Transfer';
  String get saving => isIndonesian ? 'Menabung' : 'Saving';
  String get confirm => isIndonesian ? 'Konfirmasi' : 'Confirm';
  String get cancel => isIndonesian ? 'Batal' : 'Cancel';
  String get save => isIndonesian ? 'Simpan' : 'Save';
  String get delete => isIndonesian ? 'Hapus' : 'Delete';
  String get emptyStateDefault => isIndonesian
      ? 'Belum ada transaksi di sini.'
      : 'No transactions found here.';

  // --- Appearance & Personalization Dictionary ---
  String get appearanceTitle => isIndonesian ? 'Tampilan & Personalisasi' : 'Appearance & Personalization';
  String get appearanceSubtitle => isIndonesian
      ? 'Atur tema, warna aksen, ukuran teks, dan gaya tampilan'
      : 'Customize theme, accent color, text size, and UI style';

  String get themeSection => isIndonesian ? 'TEMA APLIKASI' : 'APP THEME';
  String get themeSystem => isIndonesian ? 'Sistem' : 'System';
  String get themeLight => isIndonesian ? 'Terang' : 'Light';
  String get themeDark => isIndonesian ? 'Gelap' : 'Dark';
  String get themeSystemDesc => isIndonesian
      ? 'Mengikuti pengaturan sistem perangkat'
      : 'Follows device system settings';
  String get themeLightDesc => isIndonesian
      ? 'Nuansa bersih dan segar'
      : 'Bright, clean, and crisp slate';
  String get themeDarkDesc => isIndonesian
      ? 'Fintech obsidian dengan kontras presisi'
      : 'Fintech obsidian with high contrast';

  String get accentSection => isIndonesian ? 'WARNA AKSEN' : 'ACCENT COLOR';
  String get accentDesc => isIndonesian
      ? 'Hanya diterapkan pada tombol aksi, navigasi aktif, dan sorotan penting'
      : 'Applied to primary CTAs, active nav, and key highlights';

  String get textSizeSection => isIndonesian ? 'UKURAN TEKS' : 'TEXT SIZE';
  String get textSizeDesc => isIndonesian
      ? 'Skala tipografi yang responsif tanpa risiko tata letak terpotong'
      : 'Responsive typography scaling with zero layout cut-off';

  String get uiStyleSection => isIndonesian ? 'GAYA TAMPILAN' : 'UI STYLE';
  String get uiStyleDesc => isIndonesian
      ? 'Mengubah radius sudut kartu, ketebalan border, dan elevasi'
      : 'Controls corner radius, border width, and surface elevation';

  String get livePreviewTitle => isIndonesian ? 'PRATINJAU LANGSUNG' : 'LIVE PREVIEW';
  String get reviewChangesTitle => isIndonesian ? 'Tinjau Perubahan' : 'Review Changes';
  String get reviewChangesSubtitle => isIndonesian
      ? 'Perubahan berikut akan disimpan dan diterapkan secara bersamaan:'
      : 'The following changes will be applied atomically:';
  String get discardChanges => isIndonesian ? 'Buang Perubahan' : 'Discard Changes';
  String get applyChanges => isIndonesian ? 'Terapkan Perubahan' : 'Apply Changes';
  String get changesApplied => isIndonesian
      ? 'Preferensi tampilan berhasil diterapkan!'
      : 'Appearance preferences applied successfully!';

  String changesCount(int count) {
    if (isIndonesian) {
      return '$count perubahan';
    } else {
      return count == 1 ? '1 change' : '$count changes';
    }
  }

  // --- Language Dictionary ---
  String get languageTitle => isIndonesian ? 'Bahasa (Language)' : 'Language';
  String get languageSubtitle => isIndonesian
      ? 'Pilih bahasa tampilan antarmuka'
      : 'Select interface language';
  String get indonesian => 'Bahasa Indonesia';
  String get english => 'English';
  String get languageUpdated => isIndonesian
      ? 'Bahasa aplikasi berhasil diperbarui'
      : 'App language updated successfully';

  /// Format an integer amount into Rupiah format strictly using integer math
  static String formatCurrency(
    int amount, {
    String symbol = 'Rp',
    bool showSign = false,
    bool isExpense = false,
  }) {
    final absAmount = amount.abs();
    final formatter = NumberFormat('#,###', 'id_ID');
    final formatted = formatter.format(absAmount);

    String prefix = '';
    if (showSign) {
      if (amount < 0 || isExpense) {
        prefix = '- ';
      } else if (amount > 0) {
        prefix = '+ ';
      }
    }

    return '$prefix$symbol$formatted';
  }

  /// Compact currency format for tight cards: Rp1.2jt, Rp500rb
  static String formatCompactCurrency(int amount, {String symbol = 'Rp'}) {
    final absAmount = amount.abs();
    if (absAmount >= 1000000000) {
      final val = (absAmount / 1000000000).toStringAsFixed(1).replaceAll('.0', '');
      return '$symbol${val}M';
    } else if (absAmount >= 1000000) {
      final val = (absAmount / 1000000).toStringAsFixed(1).replaceAll('.0', '');
      return '$symbol${val}jt';
    } else if (absAmount >= 1000) {
      final val = (absAmount / 1000).toStringAsFixed(0);
      return '$symbol${val}rb';
    }
    return '$symbol$absAmount';
  }
}
