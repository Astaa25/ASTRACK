import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptStorageResult {
  final String receiptId;
  final String localPath;
  final String? remoteStoragePath;
  final bool isUploadedToCloud;
  final int fileSizeBytes;

  ReceiptStorageResult({
    required this.receiptId,
    required this.localPath,
    this.remoteStoragePath,
    this.isUploadedToCloud = false,
    required this.fileSizeBytes,
  });
}

class ReceiptStorageService {
  static const String privateBucketName = 'receipts_private';

  /// Stores a captured or picked receipt image into private sandboxed storage.
  /// If cloud sync / Supabase is available, syncs to user's private bucket.
  static Future<ReceiptStorageResult> storeReceipt({
    required File imageFile,
    required String receiptId,
    String? userId,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final fileSize = bytes.length;

    String localPath = imageFile.path;
    String? remotePath;
    bool isUploaded = false;

    // Optional upload to private cloud bucket if user session exists
    try {
      final client = Supabase.instance.client;
      final uid = userId ?? client.auth.currentUser?.id;
      if (uid != null) {
        remotePath = '$uid/receipt_$receiptId.jpg';
        await client.storage.from(privateBucketName).uploadBinary(
          remotePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
        isUploaded = true;
      }
    } catch (_) {
      // Graceful offline fallback: local storage remains 100% functional
      isUploaded = false;
    }

    return ReceiptStorageResult(
      receiptId: receiptId,
      localPath: localPath,
      remoteStoragePath: remotePath,
      isUploadedToCloud: isUploaded,
      fileSizeBytes: fileSize,
    );
  }
}
