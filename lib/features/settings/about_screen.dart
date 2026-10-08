import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/config/app_config.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/astrack_logo.dart';
import '../update/models/app_update_info.dart';
import '../update/screens/force_update_screen.dart';
import '../update/services/app_update_service.dart';
import '../update/widgets/update_available_dialog.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _installedVersion = AppConfig.version;
  int _installedBuild = AppConfig.buildNumber;
  bool _isCheckingUpdate = false;

  // Stable release certificate SHA-256 fingerprint for APK verification
  static const String releaseCertFingerprint =
      'B8:4C:9D:61:4E:22:8A:F3:19:62:3C:D0:A5:17:8F:90:3E:C1:2A:7D:6F:44:B2:99:38:12:05:EC:D7:AA:2F:55';
  static const String officialTelegramUrl = 'https://t.me/astrack_official';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await AppUpdateService().getInstalledVersionInfo();
    if (mounted) {
      setState(() {
        _installedVersion = info.$1;
        _installedBuild = info.$2;
      });
    }
  }

  Future<void> _handleCheckUpdate(bool isDark, bool isIndonesian) async {
    setState(() => _isCheckingUpdate = true);
    final (status, info) = await AppUpdateService().check(force: true);

    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    switch (status) {
      case UpdateStatus.forced:
        if (info != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ForceUpdateScreen(info: info)),
          );
        }
        break;
      case UpdateStatus.optional:
        if (info != null) {
          UpdateAvailableDialog.show(context, info: info, isDark: isDark);
        }
        break;
      case UpdateStatus.upToDate:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isIndonesian
                        ? 'Aplikasi sudah dalam versi terbaru (v$_installedVersion+$_installedBuild).'
                        : 'ASTRACK is already up to date (v$_installedVersion+$_installedBuild).',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        break;
      case UpdateStatus.unknown:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isIndonesian
                        ? 'Tidak dapat terhubung ke server pembaruan (offline atau gangguan jaringan).'
                        : 'Could not connect to update server (offline or network error).',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        break;
    }
  }

  static const String supportEmail = 'support@astrack.app';

  Future<void> _handleReportIssue() async {
    final subject = Uri.encodeComponent('Laporan Masalah ASTRACK (v$_installedVersion+$_installedBuild)');
    final body = Uri.encodeComponent(
      'Halo Tim Dukungan ASTRACK,\n\n'
      'Saya ingin melaporkan kendala/masukan terkait aplikasi:\n'
      '- Versi Aplikasi: v$_installedVersion+$_installedBuild\n'
      '- Perangkat: Android\n'
      '- Deskripsi Kendala:\n\n'
    );
    final emailUri = Uri.parse('mailto:$supportEmail?subject=$subject&body=$body');
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        await _openOfficialTelegram();
      }
    } catch (_) {
      await _openOfficialTelegram();
    }
  }

  Future<void> _openOfficialTelegram() async {
    final uri = Uri.parse(officialTelegramUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isIndonesian ? 'Tentang ASTRACK' : 'About ASTRACK',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              AstrackLogo(
                size: 64,
                showWordmark: true,
                isDark: isDark,
                fontSize: 28,
              ),
              const SizedBox(height: 12),

              // Official Tagline
              Text(
                AppConfig.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),

              const SizedBox(height: 24),

              // Metadata Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      isIndonesian ? 'Versi Terpasang' : 'Installed Version',
                      'v$_installedVersion (Build $_installedBuild)',
                      isDark,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      isIndonesian ? 'Kanal Distribusi' : 'Distribution Channel',
                      'APK Direct / Telegram',
                      isDark,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      isIndonesian ? 'Pengembang' : 'Author',
                      AppConfig.author,
                      isDark,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      isIndonesian ? 'Arsitektur' : 'Architecture',
                      'Flutter & Supabase PostgreSQL',
                      isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Check Update Action Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.sync_rounded, color: primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIndonesian ? 'Pembaruan Aplikasi' : 'App Updates',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                isIndonesian
                                    ? 'Periksa ketersediaan versi rilis APK terbaru'
                                    : 'Check for latest APK release availability',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isCheckingUpdate
                            ? null
                            : () => _handleCheckUpdate(isDark, isIndonesian),
                        icon: _isCheckingUpdate
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          _isCheckingUpdate
                              ? (isIndonesian ? 'Memeriksa...' : 'Checking...')
                              : (isIndonesian ? 'Periksa Pembaruan' : 'Check for Updates'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Official Support & Community Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.support_agent_rounded, color: Colors.lightBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIndonesian ? 'Bantuan & Saluran Resmi' : 'Support & Official Channels',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '@astrack_official • support@astrack.app',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isIndonesian
                          ? 'Dapatkan rilis pembaruan, ajukan pertanyaan, atau laporkan kendala teknis langsung ke tim pengembang.'
                          : 'Get release updates, ask questions, or report bugs directly to our development team.',
                      style: TextStyle(fontSize: 12, color: textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _handleReportIssue,
                            icon: const Icon(Icons.bug_report_outlined, size: 16),
                            label: Text(
                              isIndonesian ? 'Laporkan Masalah' : 'Report Issue',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              side: BorderSide(color: border),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _openOfficialTelegram,
                            icon: const Icon(Icons.send_rounded, size: 16, color: Colors.lightBlue),
                            label: Text(
                              isIndonesian ? 'Telegram' : 'Telegram',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Release Certificate Fingerprint Card (Integrity verification)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_outlined, size: 18, color: primary),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isIndonesian ? 'Sidik Jari Sertifikat Rilis' : 'Release Certificate Fingerprint',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(const ClipboardData(text: releaseCertFingerprint));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isIndonesian
                                    ? '✓ Sidik jari sertifikat disalin'
                                    : '✓ Certificate fingerprint copied'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(Icons.copy_rounded, size: 16, color: primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkDeepBg : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SelectableText(
                        releaseCertFingerprint,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isIndonesian
                          ? 'Periksa dengan "apksigner verify --print-certs" untuk memastikan keaslian berkas APK.'
                          : 'Verify with "apksigner verify --print-certs" to confirm APK authenticity.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Copyright Footer
              Text(
                AppConfig.copyright,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AST (Abrar Astafaraiz • Asset • Smart) + TRACK',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
