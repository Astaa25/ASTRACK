import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_storage_service.dart';
import '../../models/transaction_item.dart';
import '../../models/category.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../subscription/models/astra_feature.dart';
import '../subscription/widgets/upgrade_paywall_sheet.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _beamController;
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  bool _isScanning = false;
  String _statusText = 'Arahkan kamera ke struk belanja';

  @override
  void initState() {
    super.initState();
    _beamController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _beamController.dispose();
    super.dispose();
  }

  /// Memotret struk menggunakan kamera bawaan HP atau memilih dari galeri
  Future<void> _pickAndScan(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (picked == null) {
        // User membatalkan pengambilan gambar
        return;
      }

      final file = File(picked.path);
      setState(() {
        _capturedImage = file;
        _isScanning = true;
        _statusText = '✨ Membaca teks struk dengan AI...';
      });

      // Deteksi teks struk menggunakan engine on-device ML Kit
      final scannedData = await OCRService.scanReceipt(imagePath: file.path);

      // Simpan berkas ke private sandboxed storage
      try {
        await ReceiptStorageService.storeReceipt(
          imageFile: file,
          receiptId: '${DateTime.now().millisecondsSinceEpoch}',
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusText = 'Arahkan kamera ke struk belanja';
      });

      _showReceiptReviewSheet(scannedData, imageFile: file);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusText = 'Arahkan kamera ke struk belanja';
      });

      if (e.toString().contains('OCR_LOCKED')) {
        _showUpgradePrompt();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e is ReceiptUnreadableException
                        ? e.message
                        : 'Struk tidak terbaca jelas. Pastikan foto struk terang & fokus.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showUpgradePrompt() {
    showUpgradePaywall(
      context,
      feature: AstraFeatures.receiptScanner,
    );
  }

  void _showReceiptReviewSheet(ScannedReceipt receipt, {File? imageFile}) {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = theme.isDarkMode;

    final merchantCtrl = TextEditingController(text: receipt.merchant ?? 'Struk Belanja');
    final totalCtrl = TextEditingController(text: (receipt.total ?? 0.0).toStringAsFixed(0));
    String selectedSource = receipt.suggestedSource ?? (finance.sources.isNotEmpty ? finance.sources.first.name : 'Uang Jajan');
    DateTime selectedDate = receipt.date ?? DateTime.now();
    String selectedCategory = receipt.suggestedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (dialogCtx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Review Struk Belanja 🧾',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.income.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('OCR Selesai', style: TextStyle(color: AppColors.income, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Preview thumbnail foto struk jika tersedia
                    if (imageFile != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.file(
                            imageFile,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Tanggal (interactive picker) & Kategori Badges
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: finance.categories.any((c) => c.name.toLowerCase() == selectedCategory.toLowerCase())
                                ? finance.categories.firstWhere((c) => c.name.toLowerCase() == selectedCategory.toLowerCase()).name
                                : (finance.categories.isNotEmpty ? finance.categories.first.name : selectedCategory),
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Kategori',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                            items: finance.categories
                                .where((c) => c.type == CategoryType.expense)
                                .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setSheetState(() => selectedCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary),
                                const SizedBox(width: 6),
                                Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Merchant Field
                    Text('Nama Merchant / Toko', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: merchantCtrl,
                      style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      decoration: const InputDecoration(hintText: 'Nama Toko'),
                    ),

                    const SizedBox(height: 14),

                    // Items itemized (jika terdeteksi)
                    if (receipt.items.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daftar Belanjaan Terdeteksi (${receipt.items.length} Item)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                          TextButton(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                            onPressed: () {
                              final sum = receipt.items.fold(0.0, (s, i) => s + (i.price * i.quantity));
                              if (sum > 0) {
                                setSheetState(() => totalCtrl.text = sum.toStringAsFixed(0));
                              }
                            },
                            child: const Text('Hitung Ulang', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkElevatedCard : AppColors.lightBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          children: receipt.items.map((it) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${it.quantity}x ${it.name}',
                                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(it.price),
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.expense),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      setSheetState(() => receipt.items.remove(it));
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Total
                    Text('Total Pembayaran (Rp)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: totalCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                      decoration: const InputDecoration(prefixText: 'Rp '),
                    ),

                    const SizedBox(height: 14),

                    // Source
                    Text('Bayar Menggunakan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSource,
                      dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                      items: finance.sources.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedSource = val);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Confirm and Save
                    AppButton(
                      label: 'Simpan Transaksi Struk',
                      isLoading: isSaving,
                      backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      textColor: isDark ? Colors.black : Colors.white,
                      onPressed: () {
                        setSheetState(() => isSaving = true);
                        
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (!mounted) return;
                          
                          final totalVal = double.tryParse(totalCtrl.text) ?? (receipt.total ?? 0.0);
                          final src = finance.sources.firstWhere((s) => s.name == selectedSource, orElse: () => finance.sources.first);
                          final cat = finance.categories.firstWhere(
                            (c) => c.name.toLowerCase() == selectedCategory.toLowerCase(),
                            orElse: () => finance.categories.isNotEmpty
                                ? finance.categories.first
                                : FinancialCategory(id: 'cat_ocr', name: selectedCategory, iconName: 'receipt', colorHex: '10B981', type: CategoryType.expense),
                          );

                          final tx = TransactionItem(
                            id: 'tx_ocr_${DateTime.now().millisecondsSinceEpoch}',
                            type: TransactionType.expense,
                            amount: totalVal,
                            description: merchantCtrl.text.trim().isEmpty ? 'Struk Belanja' : merchantCtrl.text.trim(),
                            categoryId: cat.id,
                            categoryName: cat.name,
                            sourceId: src.id,
                            sourceName: src.name,
                            dateTime: selectedDate,
                            idempotencyKey: 'ocr_${selectedDate.millisecondsSinceEpoch}_${merchantCtrl.text.trim().hashCode}_${totalVal.toInt()}',
                            notes: receipt.items.isNotEmpty
                                ? 'Scan struk: ${receipt.items.length} item terdeteksi'
                                : 'Scan struk belanja',
                          );

                          finance.addTransaction(tx);
                          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Kembali ke dashboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('Struk belanja berhasil disimpan ke transaksi!')),
                                  ],
                                ),
                                backgroundColor: AppColors.income,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        });
                      },
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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan Struk Belanja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background viewfinder
          Container(
            color: const Color(0xFF0D140F),
          ),

          // Viewfinder Target Frame
          Center(
            child: Container(
              width: 290,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.2),
                    blurRadius: 20,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // Tampilkan preview foto struk jika baru saja diambil
                    if (_capturedImage != null)
                      Positioned.fill(
                        child: Image.file(
                          _capturedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 54,
                                color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _statusText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Laser beam scan animation
                    AnimatedBuilder(
                      animation: _beamController,
                      builder: (context, child) {
                        return Positioned(
                          top: _beamController.value * 360,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay saat AI sedang memproses teks struk
          if (_isScanning)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.income),
                      const SizedBox(height: 16),
                      Text(
                        '✨ Membaca teks struk...',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Controls di bagian bawah: Galeri | Shutter Kamera Bawaan HP | Tutup
          Positioned(
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tombol Galeri
                IconButton(
                  tooltip: 'Pilih dari Galeri',
                  icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                  onPressed: _isScanning ? null : () => _pickAndScan(ImageSource.gallery),
                ),
                const SizedBox(width: 36),

                // Tombol Shutter Kamera HP Bawaan
                GestureDetector(
                  onTap: _isScanning ? null : () => _pickAndScan(ImageSource.camera),
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.4),
                          blurRadius: 18,
                        )
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 36),

                // Tombol Kembali
                IconButton(
                  tooltip: 'Kembali',
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
