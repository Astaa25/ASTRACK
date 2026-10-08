# ASTRACK — TRACK YOUR MONEY

> **Track Your Money, Shape Your Future**  
> *SaaS Multi-Tenant Personal & Micro-Business Financial Ledger Platform*  
> *Arsitek & Pengembang: Abrar Astafaraiz • Versi: 2.0.0 (Build 2)*

---

## 📱 Ringkasan Produk

**ASTRACK** adalah platform pengelolaan keuangan pribadi dan buku kas usaha mikro (*SaaS Multi-Tenant*) yang cepat, privat, indah, dan deterministik. Aplikasi ini mengintegrasikan pencatatan multi-rekening (*multi-wallet*), perencanaan anggaran (*budgeting*), target tabungan (*savings goals*), transaksi berkala (*recurring bills*), pemindai kuitansi belanja berbasis OCR on-device (*ML Kit*), integrasi kecerdasan buatan (*AI Financial Advisor*), gerbang pembayaran multi-channel (*Midtrans, Xendit, Manual QRIS*), serta panel administrasi terpusat (*Super Admin Dashboard*).

### 🎯 Platform Target
* **Target Pengguna**: **Android Saja** (`minSdk = 21`, `targetSdk = 34`).
* **Pratinjau Pengembang**: Web dan Windows Desktop hanya digunakan secara internal oleh pengembang untuk kebutuhan inspeksi dan pratinjau pengembangan (bukan target pengguna). Platform iOS tidak didukung.

---

## 🛡️ Pilar Keamanan & Rekayasa Perangkat Lunak (OWASP Compliance)

1. **Hardware-Backed Cryptographic PIN**:
   * Kredensial PIN 6-digit diamankan menggunakan **PBKDF2-HMAC-SHA256 100.000 iterasi** dengan garam acak dinamis 16-byte (`Random.secure()`).
   * Seluruh kredensial disimpan terisolasi di hardware Keystore via **`FlutterSecureStorage`**.
   * Kalkulasi derivasi dieksekusi di background isolate via `compute()` guna menjamin kelancaran antarmuka (60 FPS bebas freeze).
   * Ketahanan Keystore pasca-restore sistem operasi: penanganan eksepsi `try/catch` dengan fallback aman ke status belum diatur (`hasPin = false`) dan trigger pembersihan sesi aman.
2. **Proteksi Cadangan Android (`allowBackup="false"`)**:
   * Elemen `<application>` di `AndroidManifest.xml` disetel `android:allowBackup="false"` guna mencegah kebocoran data unencrypted dan desinkronisasi enkripsi Keystore.
3. **Arsitektur Zero-Secret Client**:
   * Kode aplikasi klien Android bersih dari kunci rahasia server (`MIDTRANS_SERVER_KEY`, `PAYMENT_WEBHOOK_SECRET`, `XENDIT_WEBHOOK_TOKEN`).
   * Webhook pembayaran diproses secara terisolasi di sisi server oleh **Supabase Edge Function** (`supabase/functions/payment-webhook`) dengan validasi tanda tangan kriptografis, verifikasi status pesanan `pending`, toleransi replay 5 menit, dan idempotensi database.
4. **Buku Kas Deterministik (*Deterministic Ledger*)**:
   * Mekanisme *double-step atomic balance reversal* pada setiap operasi edit atau hapus transaksi mencegah inkonsistensi saldo kas.
   * Representasi nominal Rupiah dibulatkan secara matematis ke bilangan bulat (`roundToInt()`), menepis galat akumulasi floating-point IEEE-754.
5. **Hak Penghapusan Akun Permanen (*Right to be Forgotten*)**:
   * Pengguna memiliki kendali penuh menghapus akun via RPC `delete_my_account` yang membersihkan data lokal dan menjalankan *cascade purge* di cloud PostgreSQL Supabase.

---

## 🧪 Jaminan Kualitas & Hasil Pengujian (QA Matrix)

* **Analisis Kode Statis**: `flutter analyze` $\rightarrow$ **0 Issues Found (0 Error, 0 Warning)**.
* **Pengujian Otomatis**: `flutter test` $\rightarrow$ **31 Berkas Pengujian / 291 Tests Total**:
  * **278 Tests Lulus (100% Pass)**.
  * **13 Tests Dilewati (Auto-skip)**: Uji live cloud probe Supabase yang membutuhkan kredensial `--dart-define`.
  * **0 Tests Gagal (Zero Failure / Zero Flaky)**.
* **Audit Tampilan Visual**: Lulus audit anti-overflow pada viewport ultra-kompak 320dp & 360dp bebas `RenderFlex overflow`.

---

## 🚀 Panduan Memulai Cepat (Developer Quickstart)

### Prasyarat
* Flutter SDK $\ge 3.24.x$
* Dart SDK $\ge 3.5.x$
* Android SDK (API Level 21–34)

### Menjalankan Proyek
```bash
# 1. Unduh seluruh dependensi paket
flutter pub get

# 2. Jalankan penganalisis kode statis
flutter analyze

# 3. Jalankan suite pengujian otomatis
flutter test

# 4. Jalankan aplikasi pada perangkat/emulator Android
flutter run
```

---

## 📂 Struktur Dokumentasi Proyek

* [`deskripsi.md`](file:///d:/.Mine/Informatic%20engineering/ASTRACK/deskripsi.md): Master audit sistem dan spesifikasi teknis lengkap (83 bab komprehensif).
* [`CHANGELOG.md`](file:///d:/.Mine/Informatic%20engineering/ASTRACK/CHANGELOG.md): Catatan rilis resmi dan riwayat perubahan versi.
* [`docs/integer_currency_migration_plan.md`](file:///d:/.Mine/Informatic%20engineering/ASTRACK/docs/integer_currency_migration_plan.md): Rencana teknis masa depan representasi mata uang bilangan bulat `BIGINT`.
* [`supabase/functions/payment-webhook/README.md`](file:///d:/.Mine/Informatic%20engineering/ASTRACK/supabase/functions/payment-webhook/README.md): Spesifikasi deployment Edge Function dan verifikasi webhook pembayaran.

---

## 📄 Lisensi & Hak Cipta

© 2026 **ASTRACK** (Abrar Astafaraiz). Seluruh hak cipta dilindungi undang-undang.
