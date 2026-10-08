import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../update/services/app_update_service.dart';

class AdminAppVersionsScreen extends StatefulWidget {
  const AdminAppVersionsScreen({super.key});

  @override
  State<AdminAppVersionsScreen> createState() => _AdminAppVersionsScreenState();
}

class _AdminAppVersionsScreenState extends State<AdminAppVersionsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _versions = [];

  // Fallback in-memory list for offline/test environments
  static final List<Map<String, dynamic>> _inMemoryFallbackVersions = [
    {
      'id': 'v1-initial',
      'platform': 'android',
      'version_name': '1.0.0',
      'build_number': 1,
      'min_supported_build': 1,
      'download_url': 'https://t.me/astrack_official/1',
      'sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      'file_size_bytes': 25480000,
      'changelog_id': 'Rilis perdana aplikasi pembukuan dan keuangan ASTRACK.',
      'changelog_en': 'Initial production release of ASTRACK financial engine.',
      'is_published': true,
      'is_revoked': false,
      'created_at': DateTime.now().toIso8601String(),
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = _supabase;
    if (client == null) {
      // Offline fallback
      setState(() {
        _versions = List.from(_inMemoryFallbackVersions);
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await client
          .from('app_versions')
          .select()
          .order('build_number', ascending: false);

      final List<Map<String, dynamic>> list =
          (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (mounted) {
        setState(() {
          _versions = list.isNotEmpty ? list : List.from(_inMemoryFallbackVersions);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // If table not migrated or network error, use fallback
          _versions = List.from(_inMemoryFallbackVersions);
          _errorMessage = 'Menggunakan data lokal (Supabase: $e)';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePublished(Map<String, dynamic> item, bool value) async {
    final client = _supabase;
    final id = item['id'];

    setState(() {
      item['is_published'] = value;
    });

    if (client != null) {
      try {
        await client.from('app_versions').update({
          'is_published': value,
          'released_at': value ? DateTime.now().toIso8601String() : null,
        }).eq('id', id);
      } catch (e) {
        _showSnack('Gagal mengubah status publish: $e', isError: true);
        setState(() => item['is_published'] = !value);
        return;
      }
    }
    _showSnack(value ? '✓ Versi dipublikasikan' : 'Versi disembunyikan');
  }

  Future<void> _toggleRevoked(Map<String, dynamic> item, bool value) async {
    final client = _supabase;
    final id = item['id'];

    setState(() {
      item['is_revoked'] = value;
    });

    if (client != null) {
      try {
        await client.from('app_versions').update({
          'is_revoked': value,
        }).eq('id', id);
      } catch (e) {
        _showSnack('Gagal mengubah status revoke: $e', isError: true);
        setState(() => item['is_revoked'] = !value);
        return;
      }
    }
    _showSnack(value ? '⚠️ Versi ditarik (revoked)' : 'Versi dipulihkan dari penarikan');
  }

  Future<void> _saveVersion({
    String? id,
    required String versionName,
    required int buildNumber,
    required int minSupportedBuild,
    required String downloadUrl,
    required String sha256,
    int? fileSizeBytes,
    required String changelogId,
    required String changelogEn,
    required bool isPublished,
  }) async {
    // Validate download URL via whitelist
    if (!AppUpdateService().isSafeUrl(downloadUrl)) {
      _showSnack('URL tidak aman atau bukan host whitelist (wajib https://t.me/...)', isError: true);
      return;
    }

    final newRecord = {
      'platform': 'android',
      'version_name': versionName,
      'build_number': buildNumber,
      'min_supported_build': minSupportedBuild,
      'download_url': downloadUrl,
      'sha256': sha256.toLowerCase().trim(),
      'file_size_bytes': fileSizeBytes,
      'changelog_id': changelogId,
      'changelog_en': changelogEn,
      'is_published': isPublished,
      'is_revoked': false,
      'released_at': isPublished ? DateTime.now().toIso8601String() : null,
      'created_at': DateTime.now().toIso8601String(),
    };

    final client = _supabase;
    if (client != null) {
      try {
        if (id != null) {
          await client.from('app_versions').update(newRecord).eq('id', id);
        } else {
          await client.from('app_versions').insert(newRecord);
        }
      } catch (e) {
        _showSnack('Gagal menyimpan ke database cloud: $e', isError: true);
        return;
      }
    } else {
      // In-memory fallback
      if (id != null) {
        final idx = _inMemoryFallbackVersions.indexWhere((e) => e['id'] == id);
        if (idx != -1) {
          _inMemoryFallbackVersions[idx] = {'id': id, ...newRecord};
        }
      } else {
        _inMemoryFallbackVersions.insert(0, {'id': 'local-${DateTime.now().millisecondsSinceEpoch}', ...newRecord});
      }
    }

    _showSnack('✓ Versi rilis berhasil disimpan');
    _loadVersions();
  }

  void _showAddEditDialog({Map<String, dynamic>? existing}) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final versionNameCtrl = TextEditingController(text: existing?['version_name'] ?? '1.0.1');
    final buildNumCtrl = TextEditingController(text: existing != null ? '${existing['build_number']}' : '2');
    final minBuildCtrl = TextEditingController(text: existing != null ? '${existing['min_supported_build']}' : '1');
    final downloadUrlCtrl = TextEditingController(text: existing?['download_url'] ?? 'https://t.me/astrack_official/2');
    final sha256Ctrl = TextEditingController(text: existing?['sha256'] ?? '');
    final fileSizeMbCtrl = TextEditingController(
        text: existing?['file_size_bytes'] != null ? '${(existing!['file_size_bytes'] / (1024 * 1024)).toStringAsFixed(1)}' : '24.5');
    final changelogIdCtrl = TextEditingController(text: existing?['changelog_id'] ?? '');
    final changelogEnCtrl = TextEditingController(text: existing?['changelog_en'] ?? '');
    bool isPublished = existing?['is_published'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
            final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null ? 'Rilis Versi Baru (APK)' : 'Edit Rilis Versi',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            controller: versionNameCtrl,
                            label: 'Versi (VersionName)',
                            hint: '1.0.1',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInput(
                            controller: buildNumCtrl,
                            label: 'Build (VersionCode)',
                            hint: '2',
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: minBuildCtrl,
                      label: 'Min Supported Build (Force Update)',
                      hint: '1 (jika build < nilai ini, user wajib update)',
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: downloadUrlCtrl,
                      label: 'Download URL (Wajib HTTPS Host t.me)',
                      hint: 'https://t.me/astrack_official/2',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: sha256Ctrl,
                      label: 'SHA-256 Checksum (64 Hex Characters)',
                      hint: 'Tempel hasil Get-FileHash / sha256sum',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: fileSizeMbCtrl,
                      label: 'Ukuran Berkas (MB)',
                      hint: '24.5',
                      isDark: isDark,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: changelogIdCtrl,
                      label: 'Changelog (Bahasa Indonesia)',
                      hint: 'Rincian perbaikan dan fitur baru...',
                      isDark: isDark,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: changelogEnCtrl,
                      label: 'Changelog (English)',
                      hint: 'Bug fixes and new capabilities...',
                      isDark: isDark,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Langsung Publikasikan (is_published)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Jika mati, versi tidak akan muncul di RPC get_latest_app_version',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: isPublished,
                      activeColor: primary,
                      onChanged: (v) => setSheetState(() => isPublished = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final vName = versionNameCtrl.text.trim();
                          final bNum = int.tryParse(buildNumCtrl.text.trim()) ?? 0;
                          final mBuild = int.tryParse(minBuildCtrl.text.trim()) ?? 1;
                          final url = downloadUrlCtrl.text.trim();
                          final hash = sha256Ctrl.text.trim();
                          final mb = double.tryParse(fileSizeMbCtrl.text.trim());
                          final bytes = mb != null ? (mb * 1024 * 1024).toInt() : null;

                          if (vName.isEmpty || bNum <= 0 || url.isEmpty || hash.isEmpty) {
                            _showSnack('Mohon lengkapi Versi, Build, URL, dan SHA-256', isError: true);
                            return;
                          }

                          Navigator.pop(ctx);
                          _saveVersion(
                            id: existing?['id']?.toString(),
                            versionName: vName,
                            buildNumber: bNum,
                            minSupportedBuild: mBuild,
                            downloadUrl: url,
                            sha256: hash,
                            fileSizeBytes: bytes,
                            changelogId: changelogIdCtrl.text.trim(),
                            changelogEn: changelogEnCtrl.text.trim(),
                            isPublished: isPublished,
                          );
                        },
                        child: Text(
                          existing == null ? 'Simpan & Daftarkan Versi' : 'Perbarui Data Versi',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkMuted : AppColors.lightTextSecondary,
            ),
            isDense: true,
            filled: true,
            fillColor: isDark ? AppColors.darkDeepBg : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.expense : AppColors.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Manajemen Versi APK', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadVersions,
            tooltip: 'Segarkan',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Rilis Baru', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVersions,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 12, color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    'Riwayat Versi Rilis APK (${_versions.length})',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_versions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'Belum ada versi rilis yang terdaftar.',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    ),

                  ..._versions.map((ver) {
                    final bool isPub = ver['is_published'] == true;
                    final bool isRev = ver['is_revoked'] == true;
                    final int buildNum = ver['build_number'] ?? 0;
                    final int minBuild = ver['min_supported_build'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isRev
                              ? AppColors.expense.withAlpha(80)
                              : (isPub ? primary.withAlpha(60) : border),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primary.withAlpha(25),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'v${ver['version_name']} +$buildNum',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: primary,
                                        ),
                                      ),
                                    ),
                                    if (isRev)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.expense.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'REVOKED',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.expense),
                                        ),
                                      )
                                    else if (isPub)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.emerald.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'PUBLISHED',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emerald),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'DRAFT',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showAddEditDialog(existing: ver),
                                tooltip: 'Edit Versi',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Min Supported Build: $minBuild (Force Update jika < $minBuild)',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'URL: ${ver['download_url']}',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SHA-256: ${ver['sha256']}',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Divider(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Publish', style: TextStyle(fontSize: 12, color: textPrimary)),
                                  Switch(
                                    value: isPub,
                                    activeColor: primary,
                                    onChanged: isRev ? null : (v) => _togglePublished(ver, v),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Revoke',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isRev ? AppColors.expense : textPrimary,
                                    ),
                                  ),
                                  Switch(
                                    value: isRev,
                                    activeColor: AppColors.expense,
                                    onChanged: (v) => _toggleRevoked(ver, v),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }
}
