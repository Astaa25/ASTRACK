import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../providers/theme_provider.dart';
import '../models/app_update_info.dart';
import '../services/app_update_service.dart';

class ForceUpdateScreen extends StatelessWidget {
  final AppUpdateInfo info;

  const ForceUpdateScreen({
    super.key,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF8FAFC);
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
    final changelog = isIndonesian
        ? (info.changelogId.isNotEmpty ? info.changelogId : info.changelogEn)
        : (info.changelogEn.isNotEmpty ? info.changelogEn : info.changelogId);

    return PopScope(
      canPop: false, // Strictly prevents swipe back or back button
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 64,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          // Warning Icon Badge
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.expense.withAlpha(25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.expense.withAlpha(80),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.expense,
                                size: 44,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Heading
                          Text(
                            isIndonesian ? 'Pembaruan Aplikasi Wajib' : 'Mandatory Update Required',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            isIndonesian
                                ? 'Versi ASTRACK yang Anda gunakan saat ini sudah tidak didukung demi keamanan data finansial dan integritas transaksi Anda.'
                                : 'The current version of ASTRACK is no longer supported to ensure data security and transaction integrity.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Version Metadata Bento Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isIndonesian ? 'Versi Terbaru' : 'New Version',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primary.withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'v${info.versionName}+${info.buildNumber}',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),

                                if (changelog.isNotEmpty) ...[
                                  Text(
                                    isIndonesian ? 'Pembaruan Keamanan:' : 'Security & Updates:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    changelog,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                  const Divider(height: 20),
                                ],

                                // SHA-256 for integrity verification
                                Row(
                                  children: [
                                    Icon(Icons.lock_outline_rounded, size: 14, color: textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'SHA-256: ${info.sha256.substring(0, info.sha256.length > 20 ? 20 : info.sha256.length)}...',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: info.sha256));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(isIndonesian
                                                ? '✓ SHA-256 disalin ke clipboard'
                                                : '✓ SHA-256 copied to clipboard'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Icon(Icons.copy_rounded, size: 14, color: primary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Installation instruction banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primary.withAlpha(40)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isIndonesian
                                        ? 'Pasang APK versi baru langsung di atas versi ini. Jangan uninstall agar data lokal tidak terhapus.'
                                        : 'Install the new APK directly over this version. Do not uninstall to preserve local data.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Download Action Button
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download_rounded, color: Colors.white),
                              label: Text(
                                isIndonesian ? 'Unduh Pembaruan Sekarang' : 'Download Update Now',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => AppUpdateService().openDownload(info),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isIndonesian
                                ? 'Tautan unduhan resmi diverifikasi aman via Telegram Channel'
                                : 'Official download link securely verified via Telegram Channel',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
