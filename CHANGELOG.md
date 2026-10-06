# CHANGELOG — ASTRACK (Track Your Money)

Seluruh riwayat perubahan, pembaruan versi, dan catatan rilis resmi aplikasi ASTRACK.

---

## [v1.0.0+1] — 2026-10-06 (Beta Terbuka / Rilis Mandiri)

### 🚀 Fitur Baru & Peningkatan Utama
* **Distribusi & Pembaruan APK Mandiri (OTA Updater)**:
  * Deteksi pembaruan versi otomatis via GitHub Releases REST API dan manifest rilis resmi.
  * Validasi integritas hash biner SHA-256 sebelum instalasi guna mencegah biner korup atau serangan MitM.
  * Dialog rilis interaktif (`UpdateAvailableDialog`) dengan dukungan format Markdown changelog dan progress download visual.
  * Alur instalasi sistem Android via `open_filex` / intent PackageInstaller.
  * Whitelist domain HTTPS resmi untuk tautan unduh pembaruan (`t.me`, `telegram.me`).
* **Siklus Hidup Akun Pengguna & Privasi Lanjutan (User Lifecycle & Advanced Privacy)**:
  * Alur pemulihan kata sandi mandiri (`ForgotPasswordScreen` dan `ResetPasswordScreen`) via email verifikasi Supabase Auth.
  * Hak Penghapusan Akun Permanen (*Right to be Forgotten*) melalui RPC `delete_my_account`: pembersihan data lokal SQLite/SharedPreferences dan cascade purge akun di Supabase PostgreSQL.
  * Kontrol Privasi Telemetri & Crash Reporting: Switch opt-in/opt-out di menu Pengaturan Privasi (default nonaktif sesuai prinsip perlindungan data pribadi UU PDP).
  * Saluran Bantuan Pengguna & Kebijakan Pengembalian Dana (*Refund Policy* 7 hari SLA) di `PolicyScreen` dan `AboutScreen`.
* **Hardening Kriptografis Tingkat Tinggi (Cryptographic Hardening)**:
  * Pembaruan mekanisme hashing PIN lokal dari SHA-256 plain menjadi **PBKDF2-HMAC-SHA256 dengan 10.000 iterasi**.
  * Pengacakan garam kriptografis (*Dynamic Salt*) sepanjang 16-byte yang unik untuk setiap perangkat.
  * Proteksi serangan berbasis waktu (*Anti-Timing Attack*) menggunakan perbandingan waktu-konstan `_constantTimeEquals`.
  * Migrasi hash lama transparan tanpa memutus sesi atau memaksa reset PIN pengguna.
  * Arsitektur Pembayaran Terisolasi Edge Gateway (*Zero-Secret Client*): token dan webhook secret hanya berada di serverless Edge Function.
* **Integritas Finansial & Audit Uang Bilangan Bulat**:
  * Eliminasi residu komputasi pecahan IEEE 754 dengan pemformatan bilangan bulat (`roundToInt()`) Rupiah.
  * Penegakan aturan batas bawah nol (*Zero-Floor Rule*) pada perhitungan harga dan kupon diskon.
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
* **Automated Tests**: `flutter test` $\rightarrow$ **31 berkas pengujian / 290 tests lulus 100% (0 fail, 0 flaky)**.
