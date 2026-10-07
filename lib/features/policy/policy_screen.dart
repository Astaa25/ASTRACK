import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/saas_backend_service.dart';
import '../../app/theme/app_colors.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  final _saas = SaaSBackendService();
  bool _accepted = false;
  bool _isLoading = false;

  static const String supportEmail = 'support@astrack.app';
  static const String supportTelegram = 'https://t.me/astrack_official';

  void _submit() async {
    if (!_accepted) return;
    setState(() => _isLoading = true);
    await _saas.acceptPolicy('current_user_123'); // Record user consent
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _openEmailSupport() async {
    final uri = Uri.parse('mailto:$supportEmail?subject=ASTRACK%20Kebijakan%20%26%20Bantuan');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _copyToClipboard(supportEmail, 'Alamat email dukungan disalin ke clipboard.');
      }
    } catch (_) {
      _copyToClipboard(supportEmail, 'Alamat email dukungan disalin ke clipboard.');
    }
  }

  Future<void> _openTelegramSupport() async {
    final uri = Uri.parse(supportTelegram);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _copyToClipboard('@astrack_official', 'ID Telegram dukungan disalin ke clipboard.');
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ $message'),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final bg = isDark ? AppColors.darkDeepBg : const Color(0xFFF7FAF8);
    final textP = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';

    return PopScope(
      canPop: false, // Prevent swiping back until policy accepted
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: bg,
          elevation: 0,
          title: Text(
            isIndonesian ? 'Persetujuan Ketentuan & Privasi' : 'Terms & Privacy Policy',
            style: TextStyle(color: textP, fontWeight: FontWeight.w700),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withAlpha(75)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isIndonesian
                                ? 'Ketentuan Layanan & Privasi Diperbarui'
                                : 'Updated Terms & Privacy Policy',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textP),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isIndonesian
                                ? 'Versi 2.1 • Efektif Oktober 2026'
                                : 'Version 2.1 • Effective October 2026',
                            style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable Policy Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIndonesian
                              ? '''Kami telah memperbarui Ketentuan Layanan, Kebijakan Privasi, dan Ketentuan Langganan ASTRACK guna memastikan kepatuhan hukum, keamanan data perbankan/keuangan lokal, dan transparansi menyeluruh bagi para pengguna.'''
                              : '''We have updated our Terms of Service, Privacy Policy, and Subscription Policy to ensure regulatory compliance, data protection, and transparency.''',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildPolicySection(
                          title: isIndonesian ? '1. Pemrosesan Data & Fitur Kecerdasan Buatan (AI)' : '1. Data Processing & AI Insights',
                          body: isIndonesian
                              ? 'Data finansial Anda diproses di perangkat (on-device) dan disinkronkan hanya jika Anda terhubung ke akun cloud. Data yang diproses untuk analitik cerdas dianonimkan secara ketat dan TIDAK PERNAH dijual ke pihak ketiga atau broker data iklan.'
                              : 'Your financial data is processed on-device and in our secure cloud. Anonymized data may be used for AI insights and is never sold to third parties.',
                          isDark: isDark,
                        ),

                        _buildPolicySection(
                          title: isIndonesian ? '2. Sinkronisasi Cloud & Kedaulatan Data' : '2. Cloud Sync & Data Ownership',
                          body: isIndonesian
                              ? 'Data yang disinkronkan ke Supabase dilindungi enkripsi saat transit (TLS 1.3) dan saat diam (AES-256). Anda mempertahankan kepemilikan mutlak atas seluruh catatan finansial Anda dan dapat mengekspor atau menghapus akun Anda kapan saja melalui Pusat Privasi.'
                              : 'Data synchronized across your devices is encrypted in transit and at rest. You maintain full ownership and can export or delete your account at any time.',
                          isDark: isDark,
                        ),

                        // TODO: [LEGAL_REVIEW] Kebijakan Pengembalian Dana (Refund) & Langganan
                        _buildPolicySection(
                          title: isIndonesian
                              ? '3. Ketentuan Langganan & Kebijakan Refund (Pengembalian Dana)'
                              : '3. Subscription Terms & Refund Policy',
                          body: isIndonesian
                              ? '''• Lisensi langganan terikat pada akun Anda dan berlaku selama durasi paket yang dipilih.
• TODO: [LEGAL_REVIEW] Kebijakan pengembalian dana (refund) resmi sedang dalam peninjauan tim legal.
• Untuk kendala teknis atau pertanyaan transaksi, hubungi saluran dukungan resmi kami di bawah ini.'''
                              : '''• Subscriptions are tied to your account and valid for the billing period.
• TODO: [LEGAL_REVIEW] Official refund policy pending legal review.
• For payment inquiries or technical issues, please contact our official support channels below.''',
                          isDark: isDark,
                        ),

                        _buildPolicySection(
                          title: isIndonesian ? '4. Saluran Kontak Dukungan Resmi' : '4. Official Support Contacts',
                          body: isIndonesian
                              ? 'Untuk bantuan, klaim garansi, pengembalian dana, atau pertanyaan hukum privasi, hubungi kami melalui saluran resmi berikut:'
                              : 'For inquiries, refund requests, or privacy concerns, contact our official support team:',
                          isDark: isDark,
                        ),

                        const SizedBox(height: 8),

                        // Contact action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: BorderSide(color: primary),
                                ),
                                icon: const Icon(Icons.email_outlined, size: 16),
                                label: const Text('Email Support', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                onPressed: _openEmailSupport,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: BorderSide(color: Colors.lightBlue),
                                ),
                                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.lightBlue),
                                label: const Text('Telegram', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.lightBlue)),
                                onPressed: _openTelegramSupport,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Agreement Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _accepted,
                    activeColor: primary,
                    onChanged: (val) => setState(() => _accepted = val ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _accepted = !_accepted),
                      child: Text(
                        isIndonesian
                            ? 'Saya telah membaca, memahami, dan menyetujui Ketentuan Layanan, Kebijakan Privasi, dan Ketentuan Langganan.'
                            : 'I have read and agree to the updated Terms of Service, Privacy Policy, and Subscription Policy.',
                        style: TextStyle(fontSize: 12, color: textP, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accepted ? primary : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _accepted ? _submit : null,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          isIndonesian ? 'Setuju & Lanjutkan' : 'Accept & Continue',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection({required String title, required String body, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
