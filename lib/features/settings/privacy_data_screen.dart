import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/financial_sync_service.dart';
import '../../core/utils/date_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_auth_service.dart';
import '../auth/login_screen.dart';

class PrivacyDataScreen extends StatefulWidget {
  const PrivacyDataScreen({super.key});

  @override
  State<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends State<PrivacyDataScreen> {
  bool _isSyncing = false;
  bool _crashReportingEnabled = false;
  final TextEditingController _restoreTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _crashReportingEnabled = prefs.getBool('astrack_crash_reporting_enabled') ?? false;
      });
    }
  }

  Future<void> _toggleCrashReporting(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('astrack_crash_reporting_enabled', val);
    setState(() => _crashReportingEnabled = val);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(val
            ? '✓ Laporan galat sistem anonim diaktifkan.'
            : 'Laporan galat sistem dinonaktifkan.'),
        backgroundColor: val ? AppColors.emerald : AppColors.expense,
      ),
    );
  }

  @override
  void dispose() {
    _restoreTextCtrl.dispose();
    super.dispose();
  }

  void _triggerCloudSync() async {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    setState(() => _isSyncing = true);

    final res = await FinancialSyncService().syncAll(
      sources: finance.sources,
      categories: finance.categories,
      transactions: finance.transactions,
      budgets: finance.budgets,
      savings: finance.savings,
      recurring: finance.recurring,
      onRemoteMerged: (s, c, t, b, g, r) {
        // Updated through provider if needed
      },
    );

    if (!mounted) return;
    setState(() => _isSyncing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor: res.success ? AppColors.emerald : AppColors.expense,
      ),
    );
  }

  void _copyExportData() {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final json = finance.exportData();
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Cadangan JSON berhasil disalin ke clipboard!'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  void _showRestoreDialog() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    _restoreTextCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pulihkan Data (Restore)',
          style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tempelkan teks cadangan JSON data ASTRACK:',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _restoreTextCtrl,
                maxLines: 6,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '{\n  "version": "1.0.0",\n  "sources": [...]\n}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _validateAndPreviewRestore(_restoreTextCtrl.text.trim());
            },
            child: const Text('Periksa & Pratinjau'),
          ),
        ],
      ),
    );
  }

  void _validateAndPreviewRestore(String rawJson) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final finance = Provider.of<FinanceProvider>(context, listen: false);

    if (rawJson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format JSON kosong atau tidak valid.'), backgroundColor: AppColors.expense),
      );
      return;
    }

    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final sourcesCount = (decoded['sources'] as List?)?.length ?? 0;
      final txCount = (decoded['transactions'] as List?)?.length ?? 0;
      final budgetsCount = (decoded['budgets'] as List?)?.length ?? 0;
      final savingsCount = (decoded['savings'] as List?)?.length ?? 0;
      final recurringCount = (decoded['recurring'] as List?)?.length ?? 0;
      final exportedAt = decoded['exportedAt'] as String? ?? 'Tidak diketahui';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Pratinjau Pemulihan Data 🔍',
            style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ditemukan data cadangan valid:', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                const SizedBox(height: 8),
                Text('• Transaksi: $txCount catatan'),
                Text('• Sumber Dana: $sourcesCount dompet'),
                Text('• Anggaran: $budgetsCount kategori'),
                Text('• Tabungan Target: $savingsCount impian'),
                Text('• Transaksi Rutin: $recurringCount jadwal'),
                const SizedBox(height: 8),
                Text('Waktu Cadangan: $exportedAt', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                const Text(
                  'Peringatan: Data yang ada di perangkat akan diperbarui dengan data cadangan ini.',
                  style: TextStyle(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await finance.restoreData(rawJson);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✓ Seluruh data berhasil dipulihkan!' : 'Gagal memulihkan data.'),
                    backgroundColor: success ? AppColors.emerald : AppColors.expense,
                  ),
                );
              },
              child: const Text('Konfirmasi & Pulihkan'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File cadangan rusak atau format tidak cocok: $e'), backgroundColor: AppColors.expense),
      );
    }
  }

  void _showDeleteFinancialDataDialog() {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Seluruh Data Finansial? ⚠️', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w800)),
        content: const Text(
          'Tindakan ini akan mengosongkan seluruh riwayat transaksi, anggaran, tabungan, dan dompet secara permanen. Pastikan Anda telah membuat cadangan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, foregroundColor: Colors.white),
            onPressed: () {
              finance.resetToSampleData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data finansial telah dibersihkan.'), backgroundColor: AppColors.expense),
              );
            },
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hapus Akun & Cloud',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.expense, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menghapus akun ASTRACK Anda beserta seluruh data cloud?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Akibat penghapusan akun:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '• Profil pengguna dan otentikasi akan dihapus permanen.\n'
                '• Seluruh transaksi, anggaran, dompet, dan tabungan cloud akan dihapus.\n'
                '• Langganan aktif dan token perangkat akan dicabut.\n'
                '• Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emerald.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.download_for_offline_rounded, color: AppColors.emerald, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Saran: Cadangkan data Anda ke format JSON sebelum menghapus akun.',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _copyExportData();
            },
            child: const Text('Salin Cadangan JSON Dulu', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _showFinalDeleteConfirmationDialog();
            },
            child: const Text('Lanjut Hapus'),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmationDialog() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final confirmCtrl = TextEditingController();
    bool isProcessing = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Konfirmasi Terakhir ⚠️',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.expense, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ketik kata "HAPUS" di bawah ini untuk mengonfirmasi bahwa Anda memahami data akan dihapus permanen:',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'HAPUS',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                  if (isProcessing) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.expense, strokeWidth: 2.5),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, foregroundColor: Colors.white),
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (confirmCtrl.text.trim().toUpperCase() != 'HAPUS') {
                          setDialogState(() {
                            errorText = 'Ketik "HAPUS" dengan tepat untuk melanjutkan.';
                          });
                          return;
                        }

                        setDialogState(() => isProcessing = true);

                        try {
                          final res = await SupabaseAuthService.deleteAccount();
                          final success = res['success'] == true;
                          final msg = res['message']?.toString() ?? 'Akun berhasil dihapus.';

                          // Clear SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();

                          if (!mounted) return;
                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: success ? AppColors.emerald : AppColors.expense,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          // Redirect to login screen and clear backstack
                          Navigator.of(this.context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        } catch (e) {
                          setDialogState(() {
                            isProcessing = false;
                            errorText = 'Gagal menghapus akun: $e';
                          });
                        }
                      },
                child: const Text('Konfirmasi Hapus Akun'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final syncService = FinancialSyncService();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkDeepBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Pusat Data & Privasi'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cloud Sync Section
            _buildSectionHeader('SINKRONISASI CLOUD & MULTI-DEVICE', isDark),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: AppColors.emerald, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              syncService.isCloudAvailable ? 'Terhubung ke Cloud (Supabase)' : 'Mode Lokal (Offline)',
                              style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              syncService.lastSyncTime != null
                                  ? 'Terakhir sinkron: ${DateFormatter.formatDateTime(syncService.lastSyncTime!)}'
                                  : 'Belum pernah sinkronisasi cloud.',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSyncing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.sync_rounded),
                      label: Text(_isSyncing ? 'Menyinkronkan...' : 'Sinkronkan Sekarang'),
                      onPressed: _isSyncing ? null : _triggerCloudSync,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Backup & Restore
            _buildSectionHeader('CADANGAN & PEMULIHAN DATA (BACKUP & RESTORE)', isDark),
            const SizedBox(height: 8),
            Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined, color: AppColors.emerald),
                    title: const Text('Ekspor Cadangan (JSON)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Salin seluruh data finansial ke clipboard', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.copy_rounded, size: 20),
                    onTap: _copyExportData,
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined, color: Colors.blueAccent),
                    title: const Text('Pulihkan Data (Restore)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Validasi dan impor file cadangan JSON', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showRestoreDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Telemetry & Diagnostics (Crash Reporting Opt-in)
            _buildSectionHeader('TELEMETRI & DIAGNOSTIK APLIKASI', isDark),
            const SizedBox(height: 8),
            Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  'Laporan Galat Sistem (Crash Reporting)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  'Kirim laporan galat teknis anonim ke tim pengembang untuk mempercepat perbaikan bug. Data finansial Anda TIDAK PERNAH dikirim.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.35,
                  ),
                ),
                value: _crashReportingEnabled,
                activeColor: AppColors.emerald,
                onChanged: _toggleCrashReporting,
              ),
            ),

            const SizedBox(height: 24),

            // Danger Zone
            _buildSectionHeader('ZONA PRIVASI & PEMBERSIHAN DATA', isDark),
            const SizedBox(height: 8),
            Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.expense),
                    title: const Text('Kosongkan Data Finansial Lokal', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.expense)),
                    subtitle: const Text('Hapus seluruh catatan lokal dan kembalikan ke awal', style: TextStyle(fontSize: 12)),
                    onTap: _showDeleteFinancialDataDialog,
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ListTile(
                    leading: const Icon(Icons.person_remove_rounded, color: AppColors.expense),
                    title: const Text('Hapus Akun & Data Cloud', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.expense)),
                    subtitle: const Text('Hapus permanen akun Supabase dan seluruh riwayat cloud', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.expense),
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
    );
  }
}
