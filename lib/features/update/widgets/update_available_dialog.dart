import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../models/app_update_info.dart';
import '../services/app_update_service.dart';

class UpdateAvailableDialog extends StatelessWidget {
  final AppUpdateInfo info;
  final bool isDark;

  const UpdateAvailableDialog({
    super.key,
    required this.info,
    required this.isDark,
  });

  static Future<void> show(BuildContext context, {required AppUpdateInfo info, required bool isDark}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => UpdateAvailableDialog(info: info, isDark: isDark),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
    final changelog = isIndonesian
        ? (info.changelogId.isNotEmpty ? info.changelogId : info.changelogEn)
        : (info.changelogEn.isNotEmpty ? info.changelogEn : info.changelogId);

    final fileSizeStr = _formatFileSize(info.fileSizeBytes);

    return AlertDialog(
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.system_update_rounded, color: primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isIndonesian ? 'Pembaruan Tersedia' : 'Update Available',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ASTRACK v${info.versionName} (Build ${info.buildNumber})',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              if (fileSizeStr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${isIndonesian ? 'Ukuran file' : 'File size'}: $fileSizeStr',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              if (changelog.isNotEmpty) ...[
                Text(
                  isIndonesian ? 'Catatan Perubahan:' : 'Changelog:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDeepBg : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    changelog,
                    style: TextStyle(fontSize: 12, color: textSecondary, height: 1.45),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // SHA-256 fingerprint note
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'SHA-256: ${info.sha256.substring(0, info.sha256.length > 16 ? 16 : info.sha256.length)}...',
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
              const SizedBox(height: 10),
              Text(
                isIndonesian
                    ? 'Pasang langsung di atas aplikasi lama tanpa uninstall agar data Anda tetap tersimpan.'
                    : 'Install directly over the existing app without uninstalling to keep your data safe.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () async {
            await AppUpdateService().snooze(info.buildNumber);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(
            isIndonesian ? 'Nanti (3 Hari)' : 'Later (3 Days)',
            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            await AppUpdateService().openDownload(info);
          },
          child: Text(
            isIndonesian ? 'Perbarui Sekarang' : 'Update Now',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
