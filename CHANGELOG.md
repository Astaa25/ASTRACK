# CHANGELOG — ASTRACK (Track Your Money)

Seluruh riwayat perubahan, pembaruan versi, dan catatan rilis resmi aplikasi ASTRACK.

---

## [v1.0.0+1] — 2026-10-06 (Beta Terbuka / Rilis Mandiri)

### 🚀 Fitur Baru & Peningkatan Utama
* **Distribusi & Pembaruan APK Mandiri (OTA Updater)**:
  * Deteksi pembaruan versi resmi via RPC Supabase `get_latest_app_version` pada tabel PostgreSQL `public.app_versions`.
  * Dialog rilis interaktif (`UpdateAvailableDialog`) dan layar pembaruan wajib (`ForceUpdateScreen`) jika versi klien lebih rendah dari `min_supported_build`.
  * Tautan pembaruan resmi diarahkan ke saluran Telegram resmi terverifikasi (`t.me`, `telegram.me`) dan dibuka melalui peramban eksternal via `url_launcher`.
  * Kebijakan throttling (6 jam) dan penundaan pembaruan opsional (*Snooze* 3 hari) disimpan lokal di `SharedPreferences`.
  * Prinsip *Fail-Open*: jika koneksi internet terputus, aplikasi tetap beroperasi secara luring (*offline-first*) tanpa memblokir pengguna.
* **Siklus Hidup Akun Pengguna & Privasi Lanjutan (User Lifecycle & Advanced Privacy)**:
  * Alur pemulihan kata sandi mandiri (`ForgotPasswordScreen` dan `ResetPasswordScreen`) via email verifikasi Supabase Auth dengan deep link Android `io.supabase.astrack://reset-callback`.
  * Hak Penghapusan Akun Permanen (*Right to be Forgotten*) melalui RPC `delete_my_account`: pembersihan data lokal (`SharedPreferences` dan `FlutterSecureStorage`) serta *cascade purge* akun di Supabase PostgreSQL.
  * Kontrol Privasi Telemetri & Crash Reporting: Ditandai secara transparan sebagai `[PARTIAL]` (toggle preferensi tersimpan di storage lokal; belum terhubung ke SDK remote pihak ketiga seperti Sentry/Crashlytics).
  * Saluran Bantuan Pengguna & Kebijakan Transaksi: Tautan email bantuan resmi (`support@astrack.app`) dan Telegram di `PolicyScreen` dan `AboutScreen`. Ketentuan pengembalian dana ditandai dengan `[TODO: Kebijakan refund resmi menunggu peninjauan tim legal]`.
* **Hardening Kriptografis Tingkat Tinggi (Cryptographic Hardening)**:
  * Peningkatan mekanisme hashing PIN lokal menjadi **PBKDF2-HMAC-SHA256 $\ge 100.000$ iterasi** yang dieksekusi di background isolate via `compute()` guna mencegah pembekuan antarmuka utama (UI thread).
  * Pemindahan hash, garam acak dinamis 16-byte (`Random.secure()`), penghitung kegagalan (*failed attempts*), dan status *lockout* ke **`FlutterSecureStorage`** (terenkripsi hardware-backed Android Keystore / iOS Keychain).
  * Migrasi transparan tanpa hambatan dari format lama (plaintext SharedPreferences atau hash legacy) ke format aman 100.000 iterasi di `FlutterSecureStorage`.
  * Proteksi serangan berbasis waktu (*Anti-Timing Attack*) menggunakan perbandingan waktu-konstan `_constantTimeEquals`.
  * Arsitektur Pembayaran Terisolasi Edge Gateway (*Zero-Secret Client*): Dibuat skeleton Supabase Edge Function `payment-webhook` dengan HMAC SHA-512/SHA-256, jendela toleransi replay 5 menit, dan idempotensi `payment_webhook_events`. Klien aplikasi bersih dari `webhookSecret` dan server key.
* **Integritas Finansial & Audit Uang Bilangan Bulat**:
  * Eliminasi residu komputasi pecahan IEEE 754 dengan pemformatan bilangan bulat (`roundToInt()`) Rupiah.
  * Penegakan aturan batas bawah nol (*Zero-Floor Rule*) pada perhitungan harga dan kupon diskon.
  * Penyusunan rencana tertulis migrasi arsitektur masa depan menuju `Money` Value Object dan kolom PostgreSQL `BIGINT` (`docs/integer_currency_migration_plan.md`).
* **Zero-Overflow Visual Hardening (320dp & 360dp Matrix)**:
  * Audit visual otomatis pada 27+ layar dan modal dialog pada viewport ultra-kompak (320 × 568 dp dan 360 × 640 dp).
  * Eliminasi tuntas seluruh galat `RenderFlex overflow` pada layar Anggaran (`BudgetScreen`), Tabungan (`SavingsScreen`), Transaksi (`TransactionsScreen`), Dompet (`SourcesScreen`), Impor CSV (`CsvImportScreen`), dan Tentang Aplikasi (`AboutScreen`).
  * Penerapan pembungkus fleksibel (`Expanded`, `Flexible`, `FittedBox`, `Wrap`, dan `SingleChildScrollView`).

### 🛠️ Sistem Inti & Arsitektur SaaS
* **Buku Kas Deterministik**: Double-step atomic balance reversal pada setiap edit/hapus transaksi.
* **Manajemen Multi-Dompet**: Dukungan rekening bank, dompet digital, dan kas fisik dengan isolasi RLS PostgreSQL.
* **Pagu Anggaran & Target Tabungan**: Peringatan overbudget berjenjang dan proyeksi pencapaian target.
* **Super Admin Enterprise Panel**: Moderasi pengguna, manajemen tarif produk, audit histori harga, manajemen kupon, dan antrean verifikasi transfer manual QRIS.
* **Dual-Engine OCR & AI Assistant**: Pembacaan nota belanja on-device ML Kit dan asisten percakapan cerdas dengan gerbang konfirmasi manusia (*Human-in-the-Loop*).
* **Kustomisasi Tampilan**: Pratinjau bertahap (*Staged Preview*) mode tema, warna aksen, dan skala font teks.

### 🧪 Jaminan Kualitas (QA Metrics)
* **Static Analysis**: `flutter analyze` $\rightarrow$ **0 issues found** (0 errors, 0 warnings).
* **Automated Tests**: `flutter test` $\rightarrow$ **31 berkas pengujian / 298 tests total (100% Pass, 0 Failure, 0 Flaky; 13 tests live probe auto-skip jika tanpa `--dart-define`)**.
