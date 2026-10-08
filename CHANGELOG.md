# CHANGELOG — ASTRACK (Track Your Money)

Seluruh riwayat perubahan, pembaruan versi, dan catatan rilis resmi aplikasi ASTRACK.

---

## [v2.0.0+2] — 2026-10-08 (Rilis Utama / Major Release)

### 🚀 Peningkatan Utama & Perbaikan Bug
* **Resolusi Komprehensif RenderFlex / Pixel Overflow (Anti-Overflow Hardening)**:
  * Audit menyeluruh dan resolusi 100% dari seluruh potensi *pixel overflow* pada layar ultra-kompak (320dp hingga 360dp) di seluruh modul aplikasi.
  * `AIChatScreen`: Perbaikan tata letak header AppBar dengan `Expanded` dan teks terpotong rapi dengan elipsis.
  * `AdminDashboardScreen`: Penyesuaian rasio kartu grid KPI bawah responsif terhadap lebar layar (<360dp).
  * `AdminAppVersionsScreen`: Penyesuaian tata letak kartu rilis versi dengan `Wrap` dan pembungkusan badge adaptif.
  * `BrandIllustrations`: Perbaikan ilustrasi kartu debit onboarding dengan pelindung elipsis pada nama pemilik kartu.
  * `WelcomeScreen` & `OnboardingScreen`: Penerapan `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox` responsif mencegah overflow pada perangkat Android beresolusi kompak.
  * `PinLockScreen`: Keypad responsif dan scrollable layout yang adaptif terhadap tinggi viewport.
  * `SetupSourcesScreen`: Perbaikan baris header prompt AI dengan `Expanded` dan perlindungan elipsis.
  * `UserCustomizationScreen`: Perbaikan header salam multi-step dengan `Expanded` responsif.
  * `ReportsScreen`: Perbaikan baris header ringkasan bulanan dengan `Expanded`.
  * `SubscriptionScreen`: Perbaikan kartu ringkasan paket dan masa berlaku dengan pembungkusan fleksibel aman.
* **Integrasi Enterprise Backend & Keamanan Cloud Supabase**:
  * Eksekusi dan validasi 8 berkas migrasi skema SQL PostgreSQL: registrasi modul versi aplikasi, log audit, proteksi RLS multi-tenant, dan otorisasi Super Admin.
  * Resiliensi luring dan offline-first pada pengecekan akun langganan dengan penanganan aman tanpa crash saat Supabase belum diinisialisasi.
* **Kualitas Kode & Pengujian Otomatis**:
  * 0 issues / 0 warnings pada `flutter analyze`.
  * Seluruh pengujian otomatis pixel overflow (45 screen tests) lulus 100%.

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
  * Kebijakan Privasi Bersih: Toggle switch Crash Reporting disembunyikan dari UI pengguna sampai SDK remote resmi diintegrasikan guna menghindari ambiguitas; digantikan dengan saluran terintegrasi "Laporkan Masalah Sistem" via email (`support@astrack.id`) dan Telegram.
  * Saluran Bantuan Pengguna & Kebijakan Transaksi: Tautan email bantuan resmi (`support@astrack.id`) dan Telegram di `PolicyScreen` dan `AboutScreen`. Ketentuan pengembalian dana ditandai dengan `TODO: [LEGAL_REVIEW] Kebijakan pengembalian dana (refund) resmi sedang dalam peninjauan tim legal`.
* **Hardening Kriptografis Tingkat Tinggi (Cryptographic Hardening & Resilience)**:
  * Peningkatan mekanisme hashing PIN lokal menjadi **PBKDF2-HMAC-SHA256 100.000 iterasi** yang dieksekusi di background isolate via `compute()` guna mencegah pembekuan antarmuka utama (UI thread).
  * Eliminasi delay buatan 600ms pada `PinLockScreen`, penambahan indikator visual proses responsif (`Memproses PIN...`), dan penonaktifan interaksi keypad selama komputasi derivasi berlangsung.
  * Pemindahan hash, garam acak dinamis 16-byte (`Random.secure()`), penghitung kegagalan (*failed attempts*), dan status *lockout* ke **`FlutterSecureStorage`** (terenkripsi hardware-backed Android Keystore).
  * Mitigasi Auto Backup Android: `android:allowBackup="false"` disetel pada `<application>` di `AndroidManifest.xml` guna mencegah kebocoran data unencrypted dan desinkronisasi Keystore.
  * Resiliensi Galat Android Keystore: Penanganan `try/catch` pada `SecurityService` dengan fallback aman ke status belum diatur (`hasPin = false`), aktivasi `forceReloginNotifier`, dan metode `triggerSafeSignOut()`.
  * Migrasi transparan tanpa hambatan dari format lama (plaintext SharedPreferences atau hash legacy) ke format aman 100.000 iterasi di `FlutterSecureStorage`.
  * Proteksi serangan berbasis waktu (*Anti-Timing Attack*) menggunakan perbandingan waktu-konstan `_constantTimeEquals`.
  * Arsitektur Pembayaran Terisolasi Edge Gateway (*Zero-Secret Client*): Deployment Supabase Edge Function `payment-webhook` dengan flag `--no-verify-jwt`, validasi secret `XENDIT_WEBHOOK_TOKEN` (`x-callback-token`), verifikasi status pesanan `pending`, pencocokan nominal `gross_amount` vs `final_amount`, serta perhitungan durasi paket aktif secara dinamis dari tabel `plans`.
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
* **Automated Tests**: `flutter test` $\rightarrow$ **31 berkas pengujian / 291 tests total (100% Pass, 0 Failure, 0 Flaky; 278 passed, 13 tests live probe auto-skip jika tanpa `--dart-define`)**.
