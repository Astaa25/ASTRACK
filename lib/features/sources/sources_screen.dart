import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/fund_source.dart';
import '../../models/transaction_item.dart';
import '../../core/utils/currency_formatter.dart';
import '../transactions/add_transaction_sheet.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  static const _sourceTypes = [
    {'label': 'Dompet Tunai', 'icon': 'wallet', 'emoji': 'cash'},
    {'label': 'Rekening Bank', 'icon': 'account_balance', 'emoji': 'bank'},
    {'label': 'E-Wallet / Digital', 'icon': 'phone_android', 'emoji': 'ewallet'},
    {'label': 'Tabungan / Investasi', 'icon': 'piggy_bank', 'emoji': 'savings'},
    {'label': 'Kartu Kredit', 'icon': 'credit_card', 'emoji': 'credit'},
    {'label': 'Lainnya', 'icon': 'account_balance_wallet', 'emoji': 'other'},
  ];

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'account_balance': return Icons.account_balance_rounded;
      case 'phone_android': return Icons.phone_android_rounded;
      case 'piggy_bank': return Icons.savings_rounded;
      case 'credit_card': return Icons.credit_card_rounded;
      case 'wallet': return Icons.account_balance_wallet_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }

  void _showSourceDialog(BuildContext context, [FundSource? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final balanceCtrl = TextEditingController(text: existing != null ? existing.balance.toInt().toString() : '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final isDark = theme.isDarkMode;
    String selectedIcon = existing?.iconName ?? 'wallet';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existing == null ? 'Tambah Sumber Dana' : 'Edit Sumber Dana',
            style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Account Type
              Text('Jenis Akun', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: _sourceTypes.map((t) {
                final sel = selectedIcon == t['icon'];
                return GestureDetector(
                  onTap: () => setDlg(() => selectedIcon = t['icon']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.15) : (isDark ? AppColors.darkElevatedCard : AppColors.lightBg),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary) : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    ),
                    child: Text(t['label']!, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
                  ),
                );
              }).toList()),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: const InputDecoration(hintText: 'Nama (misal: BCA Tabungan)', labelText: 'Nama Akun'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Rp 0',
                  labelText: existing == null ? 'Saldo Awal' : 'Penyesuaian Saldo',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: const InputDecoration(hintText: 'Opsional', labelText: 'Catatan'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final bal = double.tryParse(balanceCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
                if (name.isNotEmpty) {
                  if (existing == null) {
                    finance.addFundSource(FundSource(
                      id: 'src_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      balance: bal,
                      iconName: selectedIcon,
                      description: descCtrl.text.trim(),
                    ));
                  } else {
                    finance.updateFundSource(existing.copyWith(
                      name: name,
                      balance: bal,
                      iconName: selectedIcon,
                      description: descCtrl.text.trim(),
                    ));
                  }
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FundSource source) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Akun?', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontWeight: FontWeight.w700)),
        content: Text('Hapus "${source.name}"? Riwayat transaksi yang sudah ada tidak akan terhapus.', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Provider.of<FinanceProvider>(context, listen: false).deleteFundSource(source.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final finance = Provider.of<FinanceProvider>(context);
    final isDark = theme.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sumber Dana', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showSourceDialog(context))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Total card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isDark ? [const Color(0xFF0D1F12), const Color(0xFF102817)] : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Saldo Keseluruhan', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(CurrencyFormatter.format(finance.totalBalance), style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 26, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
                        ),
                        const SizedBox(height: 4),
                        Text('${finance.sources.length} Akun Aktif', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                    ),
                    onPressed: () {
                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddTransactionSheet(initialType: TransactionType.transfer));
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Transfer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('Daftar Akun & Rekening (${finance.sources.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 12),

            if (finance.sources.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                child: Center(child: Column(children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 44, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  const SizedBox(height: 10),
                  Text('Belum ada sumber dana.\nTambahkan akun pertama Anda!', textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ])),
              )
            else
              ...finance.sources.map((source) {
                return Dismissible(
                  key: Key(source.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    _confirmDelete(context, source);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.expense.withOpacity(0.15), borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showSourceDialog(context, source),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.14), shape: BoxShape.circle),
                          child: Icon(_getIcon(source.iconName), color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    source.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                  if (source.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('Utama', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary)),
                                    ),
                                ],
                              ),
                              if (source.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  source.description,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                CurrencyFormatter.format(source.balance),
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: source.balance >= 0 ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.expense,
                                ),
                              ),
                            ),
                            if (source.balance < 0)
                              Text('Overdrawn', style: TextStyle(fontSize: 10, color: AppColors.expense, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ]),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

