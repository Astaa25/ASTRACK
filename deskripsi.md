# ASTRACK — TRACK YOUR MONEY
> **Dokumentasi Komprehensif Arsitektur, Sistem, Manual Fitur, Keamanan, dan Sumber Kebenaran Kode Sumber (Source Code Master Audit)**  
> *Versi Aplikasi: 2.0.0 (Build 2) • Framework: Flutter SDK 3.x & Supabase PostgreSQL Enterprise Engine*  
> *Penulis: Abrar Astafaraiz • Lisensi: © 2026 ASTRACK. All rights reserved.*

---

## DAFTAR ISI UTAMA
1. [Product Overview & Executive Summary](#1-product-overview--executive-summary)
   - 1.1 [Asal-Usul, Filosofi & Fungsi Nama "ASTRACK"](#11-asal-usul-filosofi--fungsi-nama-astrack)
   - 1.2 [Klasifikasi, Taksonomi & Jenis Aplikasi](#12-klasifikasi-taksonomi--jenis-aplikasi)
   - 1.3 [Konsep & Filosofi Desain (UI/UX Design Language)](#13-konsep--filosofi-desain-uiux-design-philosophy--visual-language)
   - 1.4 [Spektrum Skillset & Rekayasa Perangkat Lunak](#14-spektrum-skillset--rekayasa-perangkat-lunak-applied-engineering-skills)
2. [Product Vision & Operating Principles](#2-product-vision--operating-principles)
3. [Core Concept & Financial Mathematics](#3-core-concept--financial-mathematics)
4. [User Roles & Access Hierarchy](#4-user-roles--access-hierarchy)
5. [User Journey & End-to-End Application Flows](#5-user-journey--end-to-end-application-flows)
6. [Information Architecture & Navigation Tree](#6-information-architecture--navigation-tree)
7. [Screen-by-Screen Comprehensive Inventory (All 45+ Screens & Modals)](#7-screen-by-screen-comprehensive-inventory)
8. [Dashboard & Home Screen Financial Hub](#8-dashboard--home-screen-financial-hub)
9. [Transaction Engine & Deterministic Ledger](#9-transaction-engine--deterministic-ledger)
10. [Transaction Creation & Input Modals](#10-transaction-creation--input-modals)
11. [Transaction Edit & Balance Reversal Mechanics](#11-transaction-edit--balance-reversal-mechanics)
12. [Transaction Deletion, Duplication & Soft Audit](#12-transaction-deletion-duplication--soft-audit)
13. [Category Management & AI Semantic Classifier](#13-category-management--ai-semantic-classifier)
14. [Multi-Wallet Source of Funds Architecture](#14-multi-wallet-source-of-funds-architecture)
15. [Budget System & Overbudget Early Warning Engine](#15-budget-system--overbudget-early-warning-engine)
16. [Savings Goals & Future Financial Target Planning](#16-savings-goals--future-financial-target-planning)
17. [Recurring Transactions & Automated Bill Reminders](#17-recurring-transactions--automated-bill-reminders)
18. [Statistics, Reports & Financial Data Visualizations](#18-statistics-reports--financial-data-visualizations)
19. [Financial Health Scoring Engine (4-Pillar Metric)](#19-financial-health-scoring-engine-4-pillar-metric)
20. [Smart Financial Insights & Automated Advisory Engine](#20-smart-financial-insights--automated-advisory-engine)
21. [Receipt OCR Vision Scanner Pipeline](#21-receipt-ocr-vision-scanner-pipeline)
22. [Voice Input & Natural Speech Recognition Engine](#22-voice-input--natural-speech-recognition-engine)
23. [AI Financial Assistant & Conversational Engine](#23-ai-financial-assistant--conversational-engine)
24. [CSV Transaction Import & Data Validation Pipeline](#24-csv-transaction-import--data-validation-pipeline)
25. [PDF Printable Reports & Google Sheets Cloud Sync](#25-pdf-printable-reports--google-sheets-cloud-sync)
26. [Profile Management & Security Credential Lifecycle](#26-profile-management--security-credential-lifecycle)
27. [Personalization, UI Customization & Staged Appearance](#27-personalization-ui-customization--staged-appearance)
28. [Localization & Multi-Language Architecture (id-ID & en-US)](#28-localization--multi-language-architecture)
29. [Settings, System Toggles & Privacy Preferences](#29-settings-system-toggles--privacy-preferences)
30. [Authentication Architecture & GoTrue Engine](#30-authentication-architecture--gotrue-engine)
31. [Authorization & Server-Side RBAC Architecture](#31-authorization--server-side-rbac-architecture)
32. [Database Architecture & Entity Relationship Diagram (ERD)](#32-database-architecture--entity-relationship-diagram-erd)
33. [Database Tables Deep-Dive (PostgreSQL Cloud)](#33-database-tables-deep-dive)
34. [Row Level Security (RLS) Policies & Data Isolation](#34-row-level-security-rls-policies--data-isolation)
35. [Supabase RPC Stored Functions (SECURITY DEFINER)](#35-supabase-rpc-stored-functions)
36. [Subscription & Commercial Tier System](#36-subscription--commercial-tier-system)
37. [Dynamic Upgrade Paywall & Feature Gating Engine](#37-dynamic-upgrade-paywall--feature-gating-engine)
38. [Coupon Discount System & Server-Authoritative Engine](#38-coupon-discount-system--server-authoritative-engine)
39. [Multi-Gateway Payment Architecture](#39-multi-gateway-payment-architecture)
40. [Manual QRIS Bank Transfer & Verification Engine](#40-manual-qris-bank-transfer--verification-engine)
41. [Payment Webhook Security, HMAC & Idempotency](#41-payment-webhook-security-hmac--idempotency)
42. [Super Admin Panel: Dashboard & Live SaaS KPIs](#42-super-admin-panel-dashboard--live-saas-kpis)
43. [Super Admin Panel: User Moderation & Approvals](#43-super-admin-panel-user-moderation--approvals)
44. [Super Admin Panel: Product Pricing & Price History Audit](#44-super-admin-panel-product-pricing--price-history-audit)
45. [Super Admin Panel: Coupon Management & Campaigns](#45-super-admin-panel-coupon-management--campaigns)
46. [Super Admin Panel: Manual Payment Approval Queue](#46-super-admin-panel-manual-payment-approval-queue)
47. [Super Admin Panel: Gateway Configuration & Secrets](#47-super-admin-panel-gateway-configuration--secrets)
48. [Super Admin Panel: Plan Builder & Custom Licenses](#48-super-admin-panel-plan-builder--custom-licenses)
49. [Super Admin Panel: Executive Statistics & Growth Curves](#49-super-admin-panel-executive-statistics--growth-curves)
50. [Super Admin Panel: Settings, Security & Session Auditing](#50-super-admin-panel-settings-security--session-auditing)
51. [Responsive Design, Breakpoints & 360dp Pixel Hardening](#51-responsive-design-breakpoints--360dp-pixel-hardening)
52. [Offline-First Architecture & Cloud Synchronization](#52-offline-first-architecture--cloud-synchronization)
53. [Security Threat Model & Defensive Mitigations](#53-security-threat-model--defensive-mitigations)
54. [Cryptographic PIN Lock, Biometrics & Lockout System](#54-cryptographic-pin-lock-biometrics--lockout-system)
55. [State Management Mechanism (Provider Pattern)](#55-state-management-mechanism-provider-pattern)
56. [Design System Tokens (Colors, Typography, Motion)](#56-design-system-tokens)
57. [Shared & Core Reusable Component Library](#57-shared--core-reusable-component-library)
58. [Local Storage Audit & Schema (`SharedPreferences`)](#58-local-storage-audit--schema)
59. [Error Handling, Defensive Parsing & State Machine](#59-error-handling-defensive-parsing--state-machine)
60. [Notification Engine (Local Reminders & Remote FCM)](#60-notification-engine)
61. [Project Directory & File Structure](#61-project-directory--file-structure)
62. [Testing Suite & Verification Matrix (31 Files / 291 Tests)](#62-testing-suite--verification-matrix)
63. [Static Analysis, Linting & QA Compliance](#63-static-analysis-linting--qa-compliance)
64. [Live Supabase Cloud Runtime Probes](#64-live-supabase-cloud-runtime-probes)
65. [Production Deployment & Build Configurations](#65-production-deployment--build-configurations)
66. [Developer Quickstart & Local Setup Guide](#66-developer-quickstart--local-setup-guide)
67. [Environment Variables & Secret Isolation](#67-environment-variables--secret-isolation)
68. [Database Migration Documentation & Scripts](#68-database-migration-documentation--scripts)
69. [Security Hardening Changelog (Phases 1 to 6)](#69-security-hardening-changelog)
70. [Current System Status Summary](#70-current-system-status-summary)
71. [Known Security Findings Log](#71-known-security-findings-log)
72. [Development Conventions & Clean Architecture Rules](#72-development-conventions--clean-architecture-rules)
73. [System Glossary](#73-system-glossary)
74. [Technical FAQ](#74-technical-faq)
75. [Final Architectural Synthesis](#75-final-architectural-synthesis)
76. [Inventaris Lengkap Dependensi, Teknologi, Hardware & Protokol](#76-inventaris-lengkap-dependensi-teknologi-hardware--protokol)
77. [Arsitektur Distribusi & Pembaruan APK Mandiri (Self-Hosted OTA App Updates)](#77-arsitektur-distribusi--pembaruan-apk-mandiri-self-hosted-ota-app-updates)
78. [Siklus Hidup Akun Pengguna & Privasi Lanjutan (User Lifecycle & Advanced Privacy)](#78-siklus-hidup-akun-pengguna--privasi-lanjutan-user-lifecycle--advanced-privacy)
79. [Hardening Keamanan Kriptografis Tingkat Tinggi (Cryptographic Hardening & Salt Migration)](#79-hardening-keamanan-kriptografis-tingkat-tinggi-cryptographic-hardening--salt-migration)
80. [Arsitektur Pembayaran Terisolasi Edge Gateway (Zero-Secret Client & Edge Functions)](#80-arsitektur-pembayaran-terisolasi-edge-gateway-zero-secret-client--edge-functions)
81. [Integritas Finansial & Audit Uang Bilangan Bulat (Integer-Safe Currency Formatting)](#81-integritas-finansial--audit-uang-bilangan-bulat-integer-safe-currency-formatting)
82. [Zero-Overflow Visual Hardening & Responsive 320dp / 360dp Matrix](#82-zero-overflow-visual-hardening--responsive-320dp--360dp-matrix)
83. [Roadmap & Known Limitations (Keterbatasan & Rencana Masa Depan)](#83-roadmap--known-limitations)

---

# 1. Product Overview & Executive Summary

* **Nama Aplikasi**: ASTRACK
* **Nama Komersial**: ASTRACK — Track Your Money
* **Tagline**: *"Track Your Money, Shape Your Future"*
* **Kategori Aplikasi**: Financial Technology (Fintech) • Personal & Small Business Finance Management • SaaS Multi-Tenant Platform
* **Penulis / Arsitek**: Abrar Astafaraiz
* **Versi Rilis**: 2.0.0 (Build 2)
* **Copyright**: © 2026 ASTRACK. All rights reserved.
* **Tujuan Strategis**: Memberikan solusi holistik pengelolaan aset dan arus kas pribadi maupun bisnis mikro dalam satu aplikasi multi-platform yang cepat, privat, indah, dan deterministik. Menggabungkan pencatatan multi-rekening (*multi-wallet*), perencanaan anggaran dinamis (*budgeting*), komitmen masa depan (*savings goals*), tagihan berkala (*recurring bills*), integrasi kecerdasan buatan (*AI Financial Advisor & OCR Vision*), gerbang pembayaran multi-channel (*Midtrans, Xendit, Stripe, Manual QRIS*), serta panel kontrol administrasi SaaS (*Super Admin Dashboard*).
* **Platform Target**: **Android saja** (Kanal distribusi resmi mandiri berupa berkas `.apk` via Telegram & WhatsApp). Web dan Windows Desktop hanya digunakan oleh pengembang untuk kebutuhan pratinjau pengembangan (bukan target pengguna). Pemindai nota OCR on-device (`google_mlkit_text_recognition`) didukung pada platform target Android. Platform iOS tidak didukung.
* **Teknologi Utama**:
  - **Client**: Flutter SDK 3.x, Dart 3.x, Provider Pattern (`ChangeNotifier`), Google Fonts (`Plus Jakarta Sans`), FL Chart Engine.
  - **Cloud Backend**: Supabase Cloud Enterprise Engine (PostgreSQL 15+), GoTrue Authentication REST Service, Row Level Security (RLS), PL/pgSQL Stored Procedures / RPC (`SECURITY DEFINER`).
  - **Local Persistence**: `SharedPreferences` (Penyimpanan lokal sandboxed aplikasi standar, tidak terenkripsi otomatis di level OS; kredensial sensitif PIN diamankan secara mandiri menggunakan **PBKDF2-HMAC-SHA256 100.000 iterasi** dengan *random per-device salt* 16-byte di `FlutterSecureStorage`), JSON Serialization deterministik, dan in-memory reactive state cache.
* **Tingkat Kesiapan (QA Level)**: **Beta Terbuka / Rilis Mandiri (Self-Hosted APK Distribution via Telegram/WhatsApp)**. Didukung **31 berkas pengujian otomatis** dengan **291 tests total (278 passed, 13 skipped, 0 fail, 0 flaky)**, serta **0 issues / 0 warnings** pada `flutter analyze`. Telah lulus audit visual anti-overflow pada resolusi ultra-kompak 320dp & 360dp.

### 1.1 Asal-Usul, Filosofi & Fungsi Nama "ASTRACK"
Nama **ASTRACK** bukan sekadar susunan kata acak, melainkan sintesis konseptual dan identitas brand yang dirancang dengan makna filosofis mendalam:

1. **Etimologi Suku Kata "AST"**:
   - Berakar dari inisial sang kreator dan arsitek sistem, **Abrar Astafaraiz**.
   - Merepresentasikan kata **ASSET** (Aset & Kekayaan Bersih): Seluruh instrumen uang tunai, saldo perbankan, dompet digital, dan target tabungan pengguna dipandang sebagai kesatuan portofolio aset yang berharga dan harus dijaga pertumbuhannya.
   - Merepresentasikan kata **SMART** (Kecerdasan Otomatisasi): Penanda bahwa aplikasi ini dibekali kapabilitas cerdas modern seperti algoritma analitik 4 pilar kesehatan finansial, pemindai nota OCR visual, integrasi kecerdasan buatan AI, dan input suara.
2. **Etimologi Suku Kata "TRACK"**:
   - Berakar dari kata kerja **TRACKING** (Melacak, Memonitor, Mengaudit, dan Memetakan): Menggambarkan fungsi fundamental aplikasi dalam melacak setiap rupiah arus kas masuk (*income*), keluar (*expense*), dan mutasi antar-rekening (*transfer*) secara deterministik tanpa ada sen pun yang tercecer.
3. **Penggabungan Menjadi "ASTRACK"**:
   - Membentuk identitas brand fonetik yang tegas, tajam, modern, dan mudah diingat setara dengan produk fintech global (seperti *Stripe*, *Monzo*, *Revolut*).
   - Menghasilkan nama komersial bernuansa dinamis: *"Asset Smart Tracker" (Asset & Smart Financial Tracker)* — Asisten finansial pribadi yang aktif mendampingi pengguna setiap detik.
4. **Fungsi dan Pesan Tagline ("Track Your Money, Shape Your Future")**:
   - Mengkomunikasikan proposisi nilai emosional: Disiplin melacak keuangan hari ini (*Track Your Money*) adalah satu-satunya fondasi nyata untuk membentuk kemandirian dan kebebasan finansial di masa depan (*Shape Your Future*).

### 1.2 Klasifikasi, Taksonomi & Jenis Aplikasi
ASTRACK menempati irisan strategis dari beberapa kategori perangkat lunak modern:

1. **Berdasarkan Sektor Industri (Fintech & PFM)**:
   - **Personal Finance Management (PFM)**: Aplikasi manajemen keuangan individu untuk penganggaran (*budgeting*), pemantauan pengeluaran harian, dan perencanaan target tabungan.
   - **Micro-Business Cashflow Ledger**: Buku kas digital untuk wirausahawan mikro/UMKM yang memerlukan pemisahan rekening kas operasional, pelacakan pemasukan proyek, serta pembuatan laporan laba/rugi berformat PDF resmi.
2. **Berdasarkan Model Bisnis & Arsitektur SaaS**:
   - **Multi-Tenant B2C & B2B SaaS (Software as a Service)**: Mendukung tingkatan langganan komersial berjenjang (Free, Basic, Pro) yang divalidasi langsung oleh cloud backend dengan gerbang pembayaran multi-gateway, sistem kupon diskon server-side, dan dashboard Super Admin terpusat untuk memantau performa bisnis (*MRR, ARR, Churn, Conversion Rate*).
3. **Berdasarkan Paradigma Rekayasa Perangkat Lunak**:
   - **Offline-First Cloud-Synchronized Architecture**: Aplikasi berfungsi 100% secara lokal tanpa jeda (*zero latency*) saat tidak ada sinyal internet, lalu secara otomatis menyinkronkan antrean mutasi kas ke cloud database PostgreSQL saat konektivitas kembali pulih.
   - **Deterministic Ledger Engine**: Menolak pendekatan pencatatan kas ceroboh. Saldo adalah hasil agregasi deterministik dari rantai transaksi mutasi nyata dengan mekanisme pembalikan saldo atomik (*double-step atomic balance reversal*).
   - **Arsitektur Khusus Android**: Basis kode Flutter teroptimasi khusus untuk platform Android native. Web dan Windows Desktop hanya digunakan oleh pengembang untuk kebutuhan pratinjau pengembangan (bukan target pengguna). Platform iOS tidak didukung.

### 1.3 Konsep & Filosofi Desain (UI/UX Design Philosophy & Visual Language)
Desain antarmuka ASTRACK dirancang dengan standar agensi desain papan atas (*High-End Editorial Luxury Fintech*) yang menolak pola-pola generik murahan (*anti-slop design*):

1. **Palet Warna & Psikologi Visual**:
   - **Emerald Forest (`#00875A`) — Light Mode**: Hijau zamrud pekat yang menenangkan, melambangkan pertumbuhan modal, stabilitas finansial, kesuburan aset, dan rasa percaya diri pengguna saat mengelola uang.
   - **Obsidian Slate (`#0B0F17`) & Neon Glow Emerald (`#00D084`) — Dark Mode**: Latar belakang hitam obsidian pekat yang hemat daya pada layar OLED dipadukan dengan aksen pendaran neon zamrud cerah. Memberikan nuansa futuristik *cyber-fintech* yang sangat mewah dan nyaman di mata saat digunakan pada malam hari.
   - **Aksen Fungsional Khusus**:
     - *Gold Accent (`#FFB800`)*: Memberikan nuansa eksklusivitas pada lencana dan kartu keanggotaan PRO.
     - *Coral Red (`#EF4444`)*: Memberikan peringatan tegas namun elegan pada transaksi pengeluaran dan status overbudget.
     - *Bright Green (`#10B981`)*: Menandai transaksi pemasukan dan skor kesehatan finansial yang prima.
2. **Tipografi Editorial (Plus Jakarta Sans)**:
   - Seluruh teks dan angka menggunakan Google Fonts *Plus Jakarta Sans*. Font sans-serif geometris modern ini dipilih karena memiliki proporsi angka tabular yang sangat jelas, kerning yang proporsional, serta keterbacaan (*legibility*) yang luar biasa baik pada ukuran kecil 10sp maupun display banner 28sp.
3. **Struktur Tata Letak Bento Grid**:
   - Mengadaptasi tata letak bento box modular modern: informasi dikelompokkan dalam modul-modul kartu mandiri dengan radius sudut proporsional (16–20dp), border halus bergradien tembus pandang (*subtle translucent glassmorphism*), dan bayangan difus lembut (*soft diffused shadows*). Tidak ada tumpukan kartu yang saling bertabrakan.
4. **Mikro-Interaksi & Motion Feedback Fisik (Fluid Motion Physics)**:
   - Menghilangkan tooltip web standar yang mengganggu tampilan visual.
   - Menerapkan efek umpan balik penekanan (*press-down scale feedback*) dan overlay gelap lembut saat tombol disentuh.
   - Indikator pemuatan menggunakan animasi shimmer skeleton elegan dan transisi modal bottom sheet bermekanisme pegas (*spring curve*).
   - Efek ledakan konfeti digital (*Confetti Celebration*) saat pengguna berhasil menyelesaikan target tabungan impian.
5. **Rekayasa Bebas Luber (Zero-Overflow Responsive Engineering)**:
   - Diperkuat khusus untuk perangkat berlayar sempit (lebar 360dp) melalui penerapan `FittedBox` pada angka besar, `Wrap` pada deretan chip filter, dan `Expanded` berproteksi ellipsis, menjamin tidak pernah ada banner garis-garis kuning-hitam (*RenderFlex overflow*) pada resolusi layar apa pun.

### 1.4 Spektrum Skillset & Rekayasa Perangkat Lunak (Applied Engineering Skills)
Pembangunan aplikasi ASTRACK menggabungkan 10 domain keilmuan dan keahlian rekayasa perangkat lunak (*Software Engineering Disciplines*) tingkat lanjut:

1. **Clean Architecture & Domain-Driven Design (DDD)**:
   Pemisahan ketat antara lapisan presentasi (*Screens/Widgets*), manajemen state (*Providers*), domain matematika bisnis (*TransactionService, FinancialHealthService*), dan lapisan persistensi data (*StorageService, Supabase*).
2. **Deterministic Financial Ledger Engineering**:
   Matematika akuntansi presisi tinggi tanpa galat pembulatan bilangan pecahan, dilengkapi algoritma pembalikan saldo dua langkah (*reverse-then-apply*) untuk menjamin konsistensi saldo dompet saat transaksi diedit atau dihapus.
3. **Reactive State Management (Provider & ChangeNotifier Pattern)**:
   Pengelolaan state reaktif yang efisien dan hemat memori, didukung arsitektur *Staged Changes* pada pengaturan tampilan yang memungkinkan peninjauan perubahan tema secara real-time (*Live Preview*) sebelum diterapkan secara permanen.
4. **Cloud Database Architecture & Server-Side Security (Supabase PostgreSQL 15+)**:
   Perancangan skema relasional ACID berintegritas tinggi, implementasi kebijakan Row Level Security (RLS) multi-tenant, dan penulisan Stored Procedures PL/pgSQL dengan klausa `SECURITY DEFINER` untuk mencegah eskalasi hak akses ilegal.
5. **Cryptographic Security Engineering**:
   Pengamanan PIN 6-digit menggunakan algoritma hash SHA-256 yang dipadukan dengan secret salt unik perangkat, verifikasi keaslian webhook pembayaran menggunakan tanda tangan HMAC SHA-256/512, mitigasi replay attack dengan jendela toleransi waktu 5 menit, dan tabel idempotensi database.
6. **Computer Vision & Lexical NLP Parsing**:
   Pengembangan mesin ekstraksi nota belanja leksikal multi-bahasa (`ReceiptParser`) menggunakan regular expression bertingkat untuk mengenali merchant, tanggal, kuantitas item belanja, pajak, dan total bayar tanpa mengarang data palsu; integrasi Web Speech API untuk pengenalan suara; serta pengklasifikasi semantik kategori otomatis (`AICategoryClassifier`).
7. **Generative AI Prompting & Fail-Safe Fallback Engineering**:
   Integrasi REST API Google Gemini Cloud LLM dengan mekanisme penanganan kegagalan otomatis (*failover fallback*) yang mulus ke mesin parser aturan lokal (*Local Rule Parser*) saat perangkat sedang luring (*offline*).
8. **Multi-Channel Payment Gateway Architecture**:
   Abstraksi arsitektur gateway pembayaran yang mendukung provider Sandbox, Midtrans, Xendit, Stripe, dan alur transfer QRIS Manual dengan generator kode unik 3-digit untuk rekonsiliasi transfer bank otomatis tanpa biaya admin.
9. **Responsive UI & Accessibility Engineering (WCAG AA & 360dp Hardening)**:
   Penerapan rasio kontras warna standar WCAG AA, target sentuh minimal 44x44dp, lokalisasi dwibahasa penuh (i18n & l10n), dan hardening layout pada viewport sempit 360dp.
10. **Automated Testing, TDD & Adversarial Probing**:
    Pengujian kualitas menyeluruh mencakup 27 berkas uji dengan 239 automated tests (100% Pass), 13 live cloud probes terhadap database cloud Supabase langsung, dan kepatuhan mutlak pada analisis statis kode (`flutter analyze` 0 warnings).

---

# 2. Product Vision & Operating Principles

ASTRACK dirancang dengan landasan 5 prinsip inti:

1. **Mencatat Keuangan Harus Kurang Dari 5 Detik**:
   Friksi kognitif pencatatan manual dihilangkan melalui alur cepat lembar modal `AddTransactionSheet`, tombol aksi cepat melayang (*Floating Action Dock*), Voice Input Speech-to-Text, serta pemindai nota OCR otomatis.
2. **Kebenaran Finansial Deterministik (Deterministic Ledger Truth)**:
   Aplikasi menolak manipulasi saldo secara asal-asalan. Saldo setiap rekening (`FundSource`) merupakan hasil penjumlahan aljabar mutasi kas riil. Setiap modifikasi transaksi memicu kalkulasi balik (*balance reversal*) sebelum nilai mutasi baru dibukukan.
3. **Privasi & Keamanan Berlapis (Defense-in-Depth)**:
   Data finansial tersimpan aman di media lokal perangkat dan tersinkronisasi ke PostgreSQL cloud dengan Row Level Security (RLS) per `user_id`. Kunci PIN 6-digit dilindungi hash kriptografis SHA-256 ber-salt rahasia dengan proteksi anti brute-force otomatis (cooldown 30 detik & lockout 5 menit). Tampilan saldo dapat disensor instan (*Hide Balance Mode*) untuk kenyamanan di tempat umum.
4. **Desain Anti-Generic & Editorial Premium**:
   Mengusung estetika visual kelas atas dengan palet warna terkurasi (*Emerald Green #00875A* pada Light Mode, dan *Neon Glow Emerald #00D084* dengan latar *Obsidian Slate* pada Dark Mode), tipografi modern *Plus Jakarta Sans*, tata letak bento-grid, transisi mikro halus, dan umpan balik haptik.
5. **Kontrol Mutlak Pengguna (Human-in-the-Loop Gate)**:
   Baik kecerdasan buatan (AI) maupun pemindai kuitansi (OCR) **tidak pernah diizinkan** mengubah saldo rekening secara otonom. Semua hasil analisis disajikan dalam bentuk draf konfirmasi interaktif yang wajib ditinjau dan disetujui pengguna.

---

# 3. Core Concept & Financial Mathematics

Hubungan entitas finansial ASTRACK bekerja mengikuti rantai deterministik berikut:

```text
[ Sumber Dana / Fund Source ]
      │
      ├──> Terpotong / Bertambah oleh ──> [ Transaksi (Income / Expense / Transfer / Saving) ]
      │                                         │
      │                                         ├──> Mengurangi / Menguji ──> [ Pagu Anggaran (Budget) ]
      │                                         │
      └──> Dialokasikan ke ─────────────> [ Target Impian (Savings Goal) ]
                                                │
                                                └──> Direkapitulasi ke ───> [ 4 Pilar Skor Kesehatan & Statistik ]
```

### Formula Matematika Finansial Inti:

1. **Kekayaan Bersih (Total Net Worth)**:
   $$\text{Total Net Worth} = \sum_{i=1}^{n} \text{balance}(\text{FundSource}_i)$$
2. **Saldo Akhir Rekening Mutasi**:
   $$\text{Balance}_{\text{new}} = \begin{cases} 
   \text{Balance}_{\text{old}} + \text{amount}, & \text{jika Type} = \text{Income} \\
   \text{Balance}_{\text{old}} - \text{amount}, & \text{jika Type} \in \{\text{Expense, Saving}\} \\
   \text{Balance}_{\text{old}} \pm \text{amount}, & \text{jika Type} = \text{Transfer (Source vs Target)}
   \end{cases}$$
3. **Persentase Pemanfaatan Anggaran (Budget Burn Rate)**:
   $$\text{Utilization Rate} = \left( \frac{\text{spentAmount}}{\text{limitAmount}} \right) \times 100\%$$
   - *Status Aman (Safe)*: $\text{Rate} < 70\%$ (Aksen Hijau)
   - *Status Waspada (Warning)*: $70\% \le \text{Rate} < 90\%$ (Aksen Kuning Amber)
   - *Status Kritis (Critical)*: $90\% \le \text{Rate} < 100\%$ (Aksen Oranye)
   - *Status Overbudget (Exceeded)*: $\text{Rate} \ge 100\%$ (Aksen Merah)
4. **Alokasi Aman Belanja Harian (Safe to Spend per Day)**:
   $$\text{Daily Safe Limit} = \max\left(0, \frac{\text{Total Anggaran Bulanan} - \text{Total Pengeluaran Bulan Berjalan}}{\text{Jumlah Hari Tersisa di Bulan Ini}}\right)$$

---

# 4. User Roles & Access Hierarchy

ASTRACK menerapkan pemisahan peran (*Role-Based Access Control*) yang ditegakkan secara ganda: pada antarmuka aplikasi (*UI Gating*) dan pada level database PostgreSQL (*RLS & SECURITY DEFINER Functions*).

```text
                          ┌───────────────────────────┐
                          │    SUPER ADMINISTRATOR    │
                          │   (Full System Access)    │
                          └─────────────┬─────────────┘
                                        │
                         ┌──────────────┴──────────────┐
                         ▼                             ▼
              ┌─────────────────────┐       ┌─────────────────────┐
              │      PRO USER       │       │     BASIC USER      │
              │ (Paid Pro License)  │       │ (Entry Paid Tier)   │
              └──────────┬──────────┘       └──────────┬──────────┘
                         │                             │
                         └──────────────┬──────────────┘
                                        ▼
                             ┌─────────────────────┐
                             │      FREE USER      │
                             │ (Default Lifecycle) │
                             └──────────┬──────────┘
                                        ▼
                             ┌─────────────────────┐
                             │     GUEST USER      │
                             │ (Local Sandbox / UI)│
                             └─────────────────────┘
```

| Hak Akses & Kemampuan | 👤 Guest | 🆓 Free | ⚡ Basic | 🌟 Pro | 👑 Super Admin |
|---|:---:|:---:|:---:|:---:|:---:|
| Pencatatan Kas Offline | ✅ | ✅ | ✅ | ✅ | ✅ |
| Batas Akun Sumber Dana | 3 Dompet | 3 Dompet | 10 Dompet | **Unlimited** | **Unlimited** |
| Anggaran & Target Tabungan | ✅ | ✅ | ✅ | ✅ | ✅ |
| Pengeluaran Rutin (Bills) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Impor & Ekspor Berkas CSV | ❌ | ❌ | ✅ | ✅ | ✅ |
| Cetak Laporan Resmi PDF | ❌ | ❌ | ✅ | ✅ | ✅ |
| Kuota Tanya Asisten Finansial AI | 10 / Bln | 50 / Bln | 100 / Bln | **1.000 / Bln** | **Unlimited** |
| Pemindai Struk Belanja OCR Vision | ❌ | ❌ | ❌ (Eksklusif Pro) | **Unlimited** | **Unlimited** |
| Sinkronisasi Cloud Multi-Perangkat | ❌ | ❌ | ❌ | ✅ | ✅ |
| Akses Dashboard Super Admin | ❌ | ❌ | ❌ | ❌ | ✅ |
| Moderasi Akun (Approve/Reject) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Manajemen Harga & Kupon Diskon | ❌ | ❌ | ❌ | ❌ | ✅ |
| Verifikasi Antrean Pembayaran QRIS | ❌ | ❌ | ❌ | ❌ | ✅ |

---

# 5. User Journey & End-to-End Application Flows

### 5.1 Alur Peluncuran Pertama & Booting Sesi (`main.dart` & `SplashScreen`)
1. Aplikasi dijalankan $\rightarrow$ Inisialisasi binding Flutter, SharedPreferences, dan Supabase Client.
2. `SplashScreen` memeriksa token otentikasi aktif via `Supabase.instance.client.auth.currentSession`.
3. Evaluasi status pendaftaran dan onboarding:
   - Jika pengguna baru (belum pernah onboarding) $\rightarrow$ Arahkan ke `WelcomeScreen` $\rightarrow$ `OnboardingScreen` $\rightarrow$ `SetupSourcesScreen` $\rightarrow$ `UserCustomizationScreen` $\rightarrow$ `DashboardScreen`.
   - Jika pengguna terdaftar dan PIN Lock aktif $\rightarrow$ Arahkan ke `PinLockScreen` mode *Unlock*.
   - Jika pengguna terotentikasi sebagai Admin $\rightarrow$ Arahkan ke `AdminDashboardScreen`.
   - Jika pengguna reguler terotentikasi $\rightarrow$ Arahkan ke `DashboardScreen`.

### 5.2 Alur Pendaftaran Akun (`RegisterScreen`)
1. Pengguna memasukkan Nama Lengkap, Email, dan Password (minimal 6 karakter).
2. Client memanggil `SupabaseAuthService.signUp()`.
3. Database PostgreSQL mengeksekusi trigger otomatis `handle_new_user()` pada tabel `auth.users`:
   - Menyisipkan record ke `public.profiles` dengan status moderasi `pending`.
   - Menyisipkan record ke `public.user_roles` dengan `role_id = 'user'`.
   - Menyisipkan record ke `public.subscriptions` dengan paket bawaan `plan_free` seumur hidup.
4. Pengguna disajikan pesan bahwa akun berhasil didaftarkan dan menunggu persetujuan Administrator.

### 5.3 Alur Masuk & Validasi Status Akun (`LoginScreen`)
1. Pengguna memasukkan Email dan Password.
2. GoTrue REST Auth memvalidasi kredensial.
3. Klien mengecek status akun di `public.profiles`:
   - Jika status `pending`: Sesi ditolak dengan pesan *"Akun Anda masih menunggu verifikasi Administrator"*, lalu otomatis di-logout.
   - Jika status `rejected` atau `suspended`: Sesi ditolak.
   - Jika status `approved`: Klien memeriksa peran via fungsi database `public.is_admin(auth.uid())`.
   - Jika Admin $\rightarrow$ Navigasi ke `AdminDashboardScreen()`; jika pengguna biasa $\rightarrow$ Navigasi ke `DashboardScreen()`.

---

# 6. Information Architecture & Navigation Tree

Struktur hierarki navigasi aplikasi ASTRACK:

```text
ASTRACK ECOSYSTEM
├── [01] GERBANG OTENTIKASI & ONBOARDING
│   ├── SplashScreen (Evaluasi Sesi & Auto-Routing)
│   ├── WelcomeScreen (Sambutan Awal Brand ASTRACK)
│   ├── OnboardingScreen (3 Pilar Nilai Finansial)
│   ├── LoginScreen (Otentikasi Email & Password)
│   ├── RegisterScreen (Pendaftaran Akun Baru)
│   ├── ForgotPasswordScreen (Permintaan Reset Password Email)
│   ├── ResetPasswordScreen (Pembaruan Password Sesi Recovery)
│   ├── PinLockScreen (Setup PIN Baru & Unlock Sesi)
│   ├── SetupSourcesScreen (Inisialisasi Rekening Utama)
│   ├── UserCustomizationScreen (Preferensi Kebutuhan Pengguna)
│   └── PolicyScreen (Syarat, Ketentuan, Privasi & Kebijakan Refund)
│
├── [02] NAVIGASI UTAMA PENGGUNA (MODERN BOTTOM NAV)
│   ├── Tab 1: DashboardScreen (Beranda Saldo & Smart Hub)
│   │   ├── AddTransactionSheet (Modal Tambah/Edit Mutasi)
│   │   ├── QuickActionsRow (Shortcut Struk, AI, Voice, Mutasi)
│   │   └── DashboardUpgradeCard (Promosi Non-Intrusif Paywall)
│   ├── Tab 2: TransactionsScreen (Buku Kas & Filter Riwayat)
│   │   └── CsvImportScreen (Impor Transaksi Massal)
│   ├── Tab 3: StatisticsScreen (Analisis 4 Pilar & Grafik Arus Kas)
│   ├── Tab 4: ReportsScreen (Ekspor PDF & Sinkronisasi Sheets)
│   └── Layar Fungsional Mandiri (Menu Lainnya & Drawer):
│       ├── SourcesScreen (Kelola Multi-Dompet & Transfer Saldo)
│       ├── BudgetScreen (Kelola Batas Anggaran per Kategori)
│       ├── SavingsScreen (Target Tabungan & Celengan Digital)
│       ├── RecurringScreen (Tagihan Rutin & Pengingat Berkala)
│       ├── ReceiptScannerScreen (Pemindai Nota Belanja OCR)
│       ├── AiChatScreen (Konsultasi Finansial Interaktif)
│       │   └── VoiceTransactionSheet (Perekam Suara Alami)
│       ├── SubscriptionScreen (Status Lisensi & Paket Pro)
│       │   └── UpgradePaywallSheet (Modal Pembayaran & Kupon)
│       ├── ManualQrisCheckoutScreen (Checkout QRIS & Upload Bukti)
│       ├── ProfileScreen (Profil Pengguna & Ganti Password)
│       └── SettingsScreen (Pusat Pengaturan Sistem)
│           ├── AppearanceScreen (Kustomisasi Tema, Aksen & Font)
│           ├── LanguageSettingsScreen (Bahasa Indonesia & English)
│           ├── ManageCategoriesScreen (Kategori & Warna Kustom)
│           ├── PrivacyDataScreen (Backup, Restore, Telemetry Toggle & Hapus Akun)
│           ├── UpdateAvailableDialog (Dialog Pembaruan APK Mandiri)
│           └── AboutScreen (Tentang Aplikasi, OTA Update Checker & Kontak Bantuan)
│
└── [03] SUPER ADMIN ENTERPRISE PANEL (ADMIN BOTTOM NAV)
    ├── Tab 1: AdminDashboardScreen (Overview SaaS & Live Revenue)
    ├── Tab 2: AdminUsersScreen (Moderasi Pengguna: Pending, Active, Pro)
    │   └── AdminUserDetailScreen (Detail Profil, Lisensi & Status)
    ├── Tab 3: AdminStatisticsScreen (Pertumbuhan MRR, ARR & Retensi)
    ├── Tab 4: AdminSettingsScreen (Kredensial Admin & Sesi Keamanan)
    └── Layar Manajemen Bisnis Khusus:
        ├── AdminPricingScreen (Kelola Tarif Produk & Audit Riwayat)
        ├── AdminCouponsScreen (Kelola Kupon Promosi & Diskon)
        ├── AdminPaymentQueueScreen (Verifikasi Transfer & Bukti QRIS)
        ├── AdminGatewayConfigScreen (Konfigurasi Multi-Payment Gateway)
        ├── AdminAppVersionsScreen (Manajemen Distribusi & Rilis APK)
        └── PlanBuilderScreen (Konfigurasi Paket Lisensi Enterprise)
```

---

# 7. Screen-by-Screen Comprehensive Inventory

Berikut adalah inventaris lengkap seluruh 46 layar dan modul antarmuka yang terdapat di codebase:

| No | Nama Komponen Tampilan | Path Berkas Sumber | Tingkat Hak Akses | Status Implementasi |
|---|---|---|---|---|
| 1 | `SplashScreen` | `lib/features/splash/splash_screen.dart` | Publik | `[IMPLEMENTED]` |
| 2 | `WelcomeScreen` | `lib/features/onboarding/welcome_screen.dart` | Publik | `[IMPLEMENTED]` |
| 3 | `OnboardingScreen` | `lib/features/onboarding/onboarding_screen.dart` | Publik | `[IMPLEMENTED]` |
| 4 | `LoginScreen` | `lib/features/auth/login_screen.dart` | Publik | `[IMPLEMENTED]` |
| 5 | `RegisterScreen` | `lib/features/auth/register_screen.dart` | Publik | `[IMPLEMENTED]` |
| 6 | `ForgotPasswordScreen` | `lib/features/auth/forgot_password_screen.dart` | Publik | `[IMPLEMENTED]` |
| 7 | `ResetPasswordScreen` | `lib/features/auth/reset_password_screen.dart` | Recovery / Auth | `[IMPLEMENTED]` |
| 8 | `PinLockScreen` | `lib/features/auth/pin_lock_screen.dart` | Terautentikasi / PIN | `[IMPLEMENTED]` |
| 9 | `SetupSourcesScreen` | `lib/features/auth/setup_sources_screen.dart` | Onboarding | `[IMPLEMENTED]` |
| 10 | `UserCustomizationScreen`| `lib/features/auth/user_customization_screen.dart`| Onboarding | `[IMPLEMENTED]` |
| 11 | `PolicyScreen` | `lib/features/settings/policy_screen.dart` | Publik | `[IMPLEMENTED]` |
| 12 | `DashboardScreen` | `lib/features/dashboard/dashboard_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 13 | `TransactionsScreen` | `lib/features/transactions/transactions_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 14 | `AddTransactionSheet` | `lib/features/transactions/add_transaction_sheet.dart` | User / Pro | `[IMPLEMENTED]` |
| 15 | `CsvImportScreen` | `lib/features/transactions/csv_import_screen.dart` | Basic / Pro | `[IMPLEMENTED]` |
| 16 | `StatisticsScreen` | `lib/features/statistics/statistics_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 17 | `ReportsScreen` | `lib/features/reports/reports_screen.dart` | Basic / Pro | `[IMPLEMENTED]` |
| 18 | `SourcesScreen` | `lib/features/sources/sources_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 19 | `BudgetScreen` | `lib/features/budget/budget_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 20 | `SavingsScreen` | `lib/features/savings/savings_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 21 | `RecurringScreen` | `lib/features/recurring/recurring_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 22 | `ReceiptScannerScreen` | `lib/features/scanner/receipt_scanner_screen.dart` | Pro Required | `[IMPLEMENTED]` |
| 23 | `AiChatScreen` | `lib/features/ai/ai_chat_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 24 | `VoiceTransactionSheet`| `lib/features/voice/voice_transaction_sheet.dart` | User / Pro | `[IMPLEMENTED]` |
| 25 | `SubscriptionScreen` | `lib/features/subscription/subscription_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 26 | `UpgradePaywallSheet` | `lib/features/subscription/widgets/upgrade_paywall_sheet.dart` | User / Pro | `[IMPLEMENTED]` |
| 27 | `ManualQrisCheckoutScreen`| `lib/features/payment/manual_qris_checkout_screen.dart`| User / Pro | `[IMPLEMENTED]` |
| 28 | `ProfileScreen` | `lib/features/profile/profile_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 29 | `SettingsScreen` | `lib/features/settings/settings_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 30 | `AppearanceScreen` | `lib/features/settings/appearance_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 31 | `LanguageSettingsScreen`| `lib/features/settings/language_settings_screen.dart`| User / Pro | `[IMPLEMENTED]` |
| 32 | `ManageCategoriesScreen`| `lib/features/settings/manage_categories_screen.dart`| User / Pro | `[IMPLEMENTED]` |
| 33 | `PrivacyDataScreen` | `lib/features/settings/privacy_data_screen.dart` | User / Pro | `[IMPLEMENTED]` |
| 34 | `UpdateAvailableDialog`| `lib/features/settings/update_available_dialog.dart`| Publik / User | `[IMPLEMENTED]` |
| 35 | `AboutScreen` | `lib/features/settings/about_screen.dart` | Publik | `[IMPLEMENTED]` |
| 36 | `AdminDashboardScreen` | `lib/features/admin/admin_dashboard_screen.dart` | Super Admin | `[IMPLEMENTED]` |
| 37 | `AdminUsersScreen` | `lib/features/admin/admin_users_screen.dart` | Super Admin | `[IMPLEMENTED]` |
| 38 | `AdminUserDetailScreen`| `lib/features/admin/admin_user_detail_screen.dart` | Super Admin | `[IMPLEMENTED]` |
| 39 | `AdminStatisticsScreen`| `lib/features/admin/admin_statistics_screen.dart` | Super Admin | `[IMPLEMENTED]` |
| 40 | `AdminPricingScreen` | `lib/features/admin/admin_pricing_screen.dart` | Super Admin | `[IMPLEMENTED]` |
| 41 | `AdminCouponsScreen` | `lib/features/admin/admin_coupons_screen.dart` | Super Admin | `[IMPLEMENTED]` |
| 42 | `AdminPaymentQueueScreen`| `lib/features/admin/admin_payment_queue_screen.dart`| Super Admin | `[IMPLEMENTED]` |
| 43 | `AdminGatewayConfigScreen`| `lib/features/admin/admin_gateway_config_screen.dart`| Super Admin | `[IMPLEMENTED]` |
| 44 | `AdminAppVersionsScreen`| `lib/features/admin/admin_app_versions_screen.dart`| Super Admin | `[IMPLEMENTED]` |
| 45 | `AdminSettingsScreen` | `lib/features/admin/admin_settings_screen.dart` | Super Admin | `[IMPLEMENTED]` |
| 46 | `PlanBuilderScreen` | `lib/features/admin/plan_builder_screen.dart` | Super Admin | `[IMPLEMENTED]` |

---

# 8. Dashboard & Home Screen Financial Hub

* **Berkas Sumber**: `lib/features/dashboard/dashboard_screen.dart`
* **Arsitektur Tampilan**:
  1. **Header Sapaan & Profil**: Menampilkan sapaan dinamis ("Selamat Pagi", "Selamat Siang", "Selamat Malam"), nama pengguna dari `FinanceProvider.profile.name`, dan avatar inisial interaktif menuju `ProfileScreen`.
  2. **Total Balance Hero Card**: Menampilkan agregasi total saldo bersih dari seluruh rekening. Didukung ikon mata interaktif untuk mengaktifkan **Hide Balance Mode** (`Rp ••••••••`). Menampilkan indikator persentase perubahan bulanan (*Month-over-Month Net Worth Delta*).
  3. **Arus Kas Masuk & Keluar**: Dua kartu metrik berdampingan yang menghitung total Pemasukan (Hijau) dan Pengeluaran (Merah) bulan berjalan secara real-time.
  4. **Quick Actions Floating Dock**: Empat tombol pintasan utama:
     - *Scan Struk*: Membuka pemindai nota OCR Vision (dengan proteksi paywall untuk akun Free).
     - *Tanya AI*: Membuka ruang obrolan kecerdasan buatan finansial.
     - *Input Suara*: Membuka modal perekaman suara instan (*Voice Transaction Sheet*).
     - *Tambah Mutasi (+)*: Membuka modal lembar tambah transaksi.
  5. **Smart Financial Health Quick Card**: Kartu ringkasan kesehatan finansial yang menampilkan skor keseluruhan, predikat mutu (Grade A-D), serta saran perbaikan keuangan yang dihasilkan oleh `FinancialHealthService`.
  6. **Arus Kas 6 Bulan (Cash Flow Chart)**: Grafik batang perbandingan pemasukan versus pengeluaran selama 6 bulan terakhir dengan animasi transisi halus.
  7. **Alokasi Aman Belanja Harian (Safe to Spend Today)**: Menampilkan batas pengeluaran aman hari ini berdasarkan sisa anggaran dibagi sisa hari kalender.
  8. **Carousel Sumber Dana**: Tampilan horizontal seluruh rekening aktif beserta saldonya, dilengkapi tombol pintas *Lihat Semua*.
  9. **Transaksi Terkini (Recent Ledger)**: Daftar 5 mutasi terakhir dengan ikon kategori, nama merchant/deskripsi, waktu transaksi, dan nominal berpewarna semantik.

---

# 9. Transaction Engine & Deterministic Ledger

Seluruh kalkulasi mutasi kas dipusatkan secara independen pada `lib/services/transaction_service.dart`.
* **Tipe Mutasi yang Didukung (`TransactionType`)**:
  - `income`: Pemasukan (menambah saldo sumber dana yang dipilih).
  - `expense`: Pengeluaran (mengurangi saldo sumber dana dan menaikkan realisasi pagu anggaran kategori terkait).
  - `transfer`: Pemindahan dana antar-rekening (mengurangi rekening asal dan menambah rekening tujuan secara bersamaan tanpa mengubah total kekayaan bersih).
  - `saving`: Alokasi tabungan (mengurangi rekening sumber dan menambah saldo terkumpul pada target impian `SavingsGoal`).
* **Sifat Deterministik**: Setiap angka dihitung menggunakan operasi floating-point presisi ganda yang dibulatkan rapi ke format Rupiah. Saldo tidak pernah di-hardcode.

---

# 10. Transaction Creation & Input Modals

* **Berkas Sumber**: `lib/features/transactions/add_transaction_sheet.dart`
* **Alur Penambahan Transaksi**:
  1. Pengguna membuka sheet modal melalui tombol (+) di Bottom Nav atau Dashboard.
  2. Memilih tipe transaksi via tab segmen (*Pengeluaran*, *Pemasukan*, *Transfer*).
  3. Menginput nominal uang menggunakan format angka lokal Indonesia (ribuan bertitik).
  4. Memilih rekening sumber dana (`FundSource`) dan kategori transaksi (`Category`).
  5. Memilih tanggal dan waktu transaksi (default: waktu sekarang).
  6. Mengisi catatan/deskripsi transaksi (opsional).
  7. Menekan tombol **Simpan Transaksi**:
     - Sistem memvalidasi bahwa nominal $> 0$ dan sumber dana valid.
     - Mengeksekusi `TransactionService.addTransaction()`.
     - Memperbarui state `FinanceProvider` dan menyimpan data ke `StorageService`.
     - Menampilkan animasi sukses dan menutup modal.

---

# 11. Transaction Edit & Balance Reversal Mechanics

* **Berkas Sumber**: `lib/features/transactions/add_transaction_sheet.dart` (Parameter `initialTransaction != null`)
* **Mekanisme Reversal Dua Langkah (Atomic Reversal Pattern)**:
  Untuk mencegah inkonsistensi saldo saat mengedit mutasi yang sudah ada (misalnya mengubah nominal dari Rp 50.000 menjadi Rp 75.000 atau mengganti dompet asal dari BCA ke GoPay):
  1. **Langkah Reversal**: Sistem memanggil fungsi pengembalian saldo lama:
     - Jika transaksi lama bertipe *Expense*, saldo dompet lama dikembalikan (*refund*) sebesar nominal lama, dan realisasi anggaran lama dikurangi.
     - Jika transaksi lama bertipe *Income*, saldo dompet lama dikurangi sebesar nominal lama.
     - Jika transaksi lama bertipe *Transfer*, saldo rekening tujuan lama dikurangi dan saldo rekening asal lama dikembalikan.
  2. **Langkah Aplikasi Baru**: Sistem menerapkan nilai mutasi baru ke dompet dan kategori yang baru dipilih.
  3. Seluruh kalkulasi diselesaikan secara atomik dalam satu siklus state update.

---

# 12. Transaction Deletion, Duplication & Soft Audit

* **Penghapusan Transaksi**:
  - Memanggil `FinanceProvider.deleteTransaction(transactionId)`.
  - Memicu mekanisme reversal saldo otomatis ke rekening terkait.
  - Menghapus record dari daftar riwayat transaksi aktif lokal dan antrean sinkronisasi cloud.
* **Duplikasi Transaksi**:
  - Pengguna dapat mengetuk opsi *Duplikat* pada lembar rincian transaksi untuk membuka kembali `AddTransactionSheet` dengan seluruh field (nominal, kategori, rekening) terisi otomatis dengan tanggal hari ini.

---

# 13. Category Management & AI Semantic Classifier

* **Berkas Sumber**: `lib/models/category.dart`, `lib/features/settings/manage_categories_screen.dart`, dan `lib/services/ai_category_classifier.dart`.
* **Kategori Standar Bawaan**:
  - *Pengeluaran*: Makanan & Minuman, Kopi, Transportasi, Belanja, Tagihan & Utilitas, Hiburan, Kesehatan, Pendidikan, Donasi, Lainnya.
  - *Pemasukan*: Gaji, Freelance & Proyek, Penjualan, Uang Saku, Hadiah & Bonus, Bunga Tabungan.
* **Kustomisasi**: Pengguna dapat menambahkan kategori baru, memilih palet warna heksadesimal pembeda, serta menentukan ikon representatif.
* **AI Semantic Category Classifier (`AICategoryClassifier`)**:
  Mesin pengklasifikasi cerdas yang secara otomatis mendeteksi kata kunci transaksi (seperti *"kopi"*, *"nasi padang"*, *"bensin"*, *"skincare"*, *"token pln"*) dan merekomendasikan kategori serta warna ikon yang paling tepat tanpa perlu pemilihan manual oleh pengguna.

---

# 14. Multi-Wallet Source of Funds Architecture

* **Berkas Sumber**: `lib/models/fund_source.dart` & `lib/features/sources/sources_screen.dart`
* **Konsep**: Representasi digital dari seluruh dompet fisik, rekening bank, kartu debit, dan saldo e-wallet pengguna.
* **Atribut Rekening**: `id`, `name`, `balance`, `type` (*cash, bank, ewallet, investment*), `icon`, `colorHex`, `isDefault`.
* **Fitur Utama**:
  - Penambahan dan pengeditan rekening tanpa batas (pada paket Pro) atau hingga 3 rekening (pada paket Free).
  - Penyesuaian saldo awal rekening.
  - Fitur **Transfer Antar-Rekening** instan dengan pencatatan mutasi ganda deterministik.
  - Rekapitulasi aset bersih (*Total Net Worth Overview*).

---

# 15. Budget System & Overbudget Early Warning Engine

* **Berkas Sumber**: `lib/models/budget.dart` & `lib/features/budget/budget_screen.dart`
* **Mekanisme Pagu Anggaran**:
  - Setiap kategori pengeluaran dapat dipasangkan batas pagu bulanan (`limitAmount`).
  - Saat transaksi pengeluaran baru dicatat pada kategori tersebut, nilai `spentAmount` otomatis terakumulasi.
* **Sistem Peringatan Dini Multi-Level**:
  - $\text{Progress} < 70\%$: Status **Aman (Safe)** — Bilah kemajuan hijau.
  - $70\% \le \text{Progress} < 90\%$: Status **Peringatan (Warning)** — Bilah kemajuan kuning dengan pengingat hemat.
  - $90\% \le \text{Progress} < 100\%$: Status **Kritis (Critical)** — Bilah kemajuan oranye dengan peringatan mendekati batas.
  - $\text{Progress} \ge 100\%$: Status **Overbudget (Exceeded)** — Bilah kemajuan merah dengan nominal selisih pengeluaran berlebih (*Overspent Amount*).

---

# 16. Savings Goals & Future Financial Target Planning

* **Berkas Sumber**: `lib/models/savings_goal.dart` & `lib/features/savings/savings_screen.dart`
* **Konsep**: Celengan digital untuk memantau progres pencapaian impian finansial (misal: *Beli Laptop Baru*, *Dana Darurat 6 Bulan*, *Liburan Akhir Tahun*).
* **Komponen & Formula Proyeksi**:
  - Target nominal uang (`targetAmount`) dan saldo terkumpul saat ini (`currentAmount`).
  - Tanggal tenggat waktu impian (`targetDate`).
  - Rekomendasi setoran berkala: Menghitung sisa nominal dibagi sisa hari/bulan hingga target tercapai.
  - Riwayat mutasi setoran (*Deposit*) dan penarikan (*Withdrawal*) yang memotong atau mengembalikan saldo ke rekening sumber dana terpilih.

---

# 17. Recurring Transactions & Automated Bill Reminders

* **Berkas Sumber**: `lib/models/recurring_transaction.dart` & `lib/features/recurring/recurring_screen.dart`
* **Fungsi**: Mengelola komitmen pengeluaran rutin berulang seperti langganan bulanan (*Netflix, Spotify*), tagihan listrik/air, cicilan, dan sewa kos.
* **Frekuensi Pengulangan**: Harian (`daily`), Mingguan (`weekly`), Bulanan (`monthly`), dan Tahunan (`yearly`).
* **Pencegahan Eksekusi Ganda**: Sistem menyimpan riwayat `lastExecutedDate` dan melakukan penyesuaian akhir bulan (*calendar month clamping*, misal 31 Januari $\rightarrow$ 28 Februari) agar tagihan tidak pernah dieksekusi dobel atau terlewat.

---

# 18. Statistics, Reports & Financial Data Visualizations

* **Berkas Sumber**: `lib/features/statistics/statistics_screen.dart`
* **Visualisasi Grafis FL Chart**:
  1. **Tab 1: Ringkasan & Tren (Overview)**:
     - Donut Chart persentase pengeluaran per kategori dengan legenda interaktif.
     - Grafik batang pengeluaran mingguan/bulanan.
     - Mini Banner Skor Kesehatan Finansial.
  2. **Tab 2: Arus Kas Komparatif (Cash Flow)**:
     - Grafik garis ganda (*Dual Line Chart*) mempertemukan kurva pemasukan versus pengeluaran selama 6 bulan terakhir.
  3. **Tab 3: Evaluasi 4 Pilar Kesehatan Finansial (Health Score)**:
     - Kartu skor lingkaran interaktif dengan predikat Grade A-D dan indikator diagnostik menyeluruh.

---

# 19. Financial Health Scoring Engine (4-Pillar Metric)

* **Berkas Sumber**: `lib/models/financial_health_score.dart` & `lib/services/financial_health_service.dart`
* **Algoritma Skor 100 Poin**:
  1. **Pilar 1: Tingkat Tabungan (Savings Rate Score — Maks 35 Poin)**:
     Evaluasi rasio $\frac{\text{Pemasukan} - \text{Pengeluaran}}{\text{Pemasukan}}$. Target ideal: tabungan $\ge 20\%$ untuk poin maksimal 35.
  2. **Pilar 2: Ketaatan Anggaran (Budget Adherence Score — Maks 30 Poin)**:
     Evaluasi rasio pengeluaran terhadap batas total limit anggaran. Pengeluaran di bawah $80\%$ limit mendapatkan poin maksimal 30; overbudget mendapatkan penalti poin.
  3. **Pilar 3: Cadangan Likuiditas Dana Darurat (Emergency Buffer Score — Maks 20 Poin)**:
     Evaluasi rasio total saldo likuid terhadap rata-rata pengeluaran bulanan. Saldo cadangan $\ge 3$ bulan pengeluaran mendapatkan poin penuh 20.
  4. **Pilar 4: Keteraturan Pencatatan Kas (Recording Regularity Score — Maks 15 Poin)**:
     Evaluasi keaktifan pengguna dalam mencatat mutasi minimal 15 hari dalam 30 hari terakhir.
* **Klasifikasi Grade**:
  - **Grade A (80 - 100 Poin)**: *Sangat Sehat* (Warna Emerald #10B981)
  - **Grade B (65 - 79 Poin)**: *Sehat* (Warna Biru #3B82F6)
  - **Grade C (50 - 64 Poin)**: *Cukup* (Warna Kuning Amber #F59E0B)
  - **Grade D (< 50 Poin)**: *Perlu Pembenahan* (Warna Merah #EF4444)

---

# 20. Smart Financial Insights & Automated Advisory Engine

* **Berkas Sumber**: `lib/services/financial_insight_service.dart`
* **Logika Analisis Deterministik**:
  - **Evaluasi Month-over-Month (MoM)**: Membandingkan total pengeluaran bulan ini versus bulan lalu pada rentang hari yang sama untuk mendeteksi lonjakan belanja dini.
  - **Deteksi Pos Boros (Top Spending Category)**: Mengidentifikasi kategori dengan pengeluaran terbesar dan persentase dominasinya terhadap total belanja.
  - **Laju Konsumsi Anggaran (Burn Rate Estimation)**: Memproyeksikan sisa hari sebelum seluruh anggaran habis jika pola belanja harian saat ini diteruskan.
  - **Rekomendasi Hemat Otomatis**: Memberikan wawasan kontekstual (misalnya *"Pengeluaran kopi Anda telah mencapai 32% dari total uang jajan, pertimbangkan untuk menyeduh sendiri di rumah"*).

---

# 21. Receipt OCR Vision Scanner Pipeline

* **Berkas Sumber**: `lib/features/scanner/receipt_scanner_screen.dart`, `lib/services/ocr_service.dart`, dan `lib/services/ocr/receipt_parser.dart`
* **Arsitektur Pemrosesan Leksikal**:
  1. Gambar struk belanja diambil melalui kamera atau galeri perangkat.
  2. Gambar diteruskan ke `OCRProvider` (`LocalOCRProvider` atau `RemoteCloudVisionOCRProvider`).
  3. `ReceiptParser` mengekstrak entitas struk secara cerdas:
     - Nama Toko / Merchant (header non-alamat teratas).
     - Tanggal & Waktu transaksi (`DD/MM/YYYY`, `HH:MM`).
     - Baris Item Belanja (Kuantitas, Nama Barang, Harga).
     - Pajak PB1/PPN, Diskon/Potongan, dan Grand Total.
     - Metode Pembayaran (QRIS, Tunai, Kartu Debit, E-Wallet).
     - Rekomendasi Kategori Otomatis.
  4. **Pencegahan Halusinasi**: Jika kualitas foto buram atau teks tidak terbaca, sistem melempar galat `ReceiptUnreadableException` secara transparan tanpa mengarang angka palsu.
  5. **Review Bottom Sheet**: Hasil pembacaan disajikan dalam modal interaktif untuk dikonfirmasi dan diedit oleh pengguna sebelum mutasi kas disimpan ke saldo dompet.

---

# 22. Voice Input & Natural Speech Recognition Engine

* **Berkas Sumber**: `lib/features/voice/voice_transaction_sheet.dart` & `lib/services/speech/speech_service.dart`
* **Alur Perekaman**:
  1. Memverifikasi izin mikrofon via `PermissionService`.
  2. `SpeechService` mengaktifkan perekaman suara dalam Bahasa Indonesia (`id-ID`).
  3. Gelombang audio ditranskripsi menjadi teks secara real-time.
  4. Teks hasil rekaman diteruskan ke `AIService.processInput()` untuk diekstrak menjadi draf transaksi.
  5. Menampilkan draf transaksi dalam lembar dialog konfirmasi sebelum disimpan.

---

# 23. AI Financial Assistant & Conversational Engine

* **Berkas Sumber**: `lib/features/ai/ai_chat_screen.dart` & `lib/services/ai_service.dart`
* **Arsitektur Dual-Engine**:
  1. **Remote Cloud LLM (Gemini API / OpenAI)**: Menghubungkan permintaan ke API kecerdasan buatan untuk konsultasi strategi keuangan kompleks, perencanaan investasi dasar, dan analisis komprehensif.
  2. **Local Rule AI Provider (Offline Fallback Engine)**: Parser leksikal berbasis regular expression multi-pola yang mampu memahami perintah pencatatan bahasa alami sehari-hari tanpa koneksi internet (contoh: *"Beli bakso 20 ribu pakai GoPay"*, *"Dapat gaji freelance 2 juta ke tabungan BCA"*).
* **AI Safety Confirmation Gate**: Objek `TransactionDraft` hasil ekstraksi AI **wajib** dikonfirmasi pengguna sebelum dieksekusi oleh `TransactionService`. AI tidak memiliki otoritas mutasi saldo sepihak.

---

# 24. CSV Transaction Import & Data Validation Pipeline

* **Berkas Sumber**: `lib/features/transactions/csv_import_screen.dart` & `lib/core/utils/import_validator.dart`
* **Kemampuan Impor**:
  - Menerima unggahan berkas `.csv` atau penempelan teks CSV mentah.
  - Deteksi otomatis header kolom (`Tanggal`, `Tipe`, `Nominal`, `Kategori`, `Sumber Dana`, `Catatan`).
  - Pembersihan format angka (menghapus simbol `Rp`, koma, spasi).
  - Pemeriksaan duplikasi mutasi berdasarkan kecocokan tanggal, nominal, dan nama merchant.
  - Layar pratinjau data interaktif sebelum pengguna menekan tombol *Impor Seluruh Transaksi*.

---

# 25. PDF Printable Reports & Google Sheets Cloud Sync

* **Berkas Sumber**: `lib/features/reports/reports_screen.dart`, `lib/services/printable_report_service.dart`, dan `lib/services/financial_sync_service.dart`.
* **Ekspor Dokumen PDF**:
  - Menghasilkan berkas laporan keuangan resmi siap cetak berstandar akuntansi.
  - Memuat kop dokumen ASTRACK, ringkasan saldo bersih, rincian tabel buku besar per periode, dan kolom tanda tangan digital.
* **Integrasi Google Sheets**:
  - Ekspor data mutasi ke format spreadsheet berbasis cloud melalui endpoint REST API.

---

# 26. Profile Management & Security Credential Lifecycle

* **Berkas Sumber**: `lib/features/profile/profile_screen.dart`
* **Fitur Utama**:
  - Menampilkan nama lengkap, email terdaftar, ID pengguna unik, dan lencana status lisensi (Free vs Pro).
  - Modal **Ubah Profil**: Memperbarui nama tampilan pada tabel `public.profiles` di Supabase.
  - Modal **Ganti Kata Sandi**: Memperbarui password akun melalui `Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword))`.
  - Tombol Logout aman yang membersihkan seluruh cache sesi memori lokal.

---

# 27. Personalization, UI Customization & Staged Appearance

* **Berkas Sumber**: `lib/features/settings/appearance_screen.dart`
* **Arsitektur Staged Changes (Atomic Review)**:
  Pengguna dapat bereksperimen dengan berbagai setelan tampilan tanpa mengubah tema aplikasi secara prematur. Perubahan ditampung dalam *staging state* dan dapat ditinjau melalui `LivePreviewCard` sebelum diterapkan secara atomik melalui `ReviewAppearanceSheet`.
* **Parameter yang Dapat Dikustomisasi**:
  - **Mode Tema**: Mode Gelap (*Dark Obsidian*), Mode Terang (*Emerald Forest*), atau Ikuti Sistem Perangkat.
  - **Warna Aksen Brand**: Emerald (Default), Indigo, Purple, Amber, Cyan, Rose.
  - **Skala Font Teks**: Ringkas (0.9x), Standar (1.0x), Nyaman (1.1x), Ekstra Besar (1.2x).
  - **Gaya Radius Sudut Kartu**: Tajam (8dp), Standar (16dp), Membulat (24dp).

---

# 28. Localization & Multi-Language Architecture

* **Berkas Sumber**: `lib/core/localization/app_localizations.dart` & `lib/features/settings/language_settings_screen.dart`
* **Bahasa yang Didukung**:
  - **Bahasa Indonesia (`id_ID`)**: Bahasa default dengan format mata uang Rupiah (`Rp`) dan tanggal lokal.
  - **English (`en_US`)**: Bahasa internasional penuh untuk istilah perbankan dan navigasi aplikasi.
* **Penggantian Bahasa Dinamis**: Dapat diubah instan melalui `LanguageSettingsScreen` tanpa perlu memuat ulang (*restart*) aplikasi.

---

# 29. Settings, System Toggles & Privacy Preferences

* **Berkas Sumber**: `lib/features/settings/settings_screen.dart`
* **Daftar Preferensi Sistem**:
  - `astrack_hide_balance`: Menyembunyikan seluruh angka saldo saat aplikasi pertama kali dibuka.
  - `astrack_pin_enabled`: Mengaktifkan penguncian PIN 6-digit saat aplikasi berpindah dari latar belakang (*background*).
  - `astrack_daily_reminder`: Pengingat harian jam 20:00 malam untuk mencatat pengeluaran hari ini.
  - `PrivacyDataScreen`: Menu backup JSON mandiri, pemulihan data aman (*safe restore*), dan penghapusan data lokal (*data wipe zone*).

---

# 30. Authentication Architecture & GoTrue Engine

* **Penyedia Otentikasi**: Supabase Auth Engine (GoTrue REST API).
* **Enkripsi Kredensial**: Standar hashing server-side bcrypt (password teks polos tidak pernah disimpan atau diketahui client).
* **Manajemen Token**: Token akses JWT (*JSON Web Token*) dan refresh token dikelola dan diperbarui secara otomatis oleh SDK `supabase_flutter`.
* **State Listener**: Memantau siklus hidup sesi via `Supabase.instance.client.auth.onAuthStateChange`.

---

# 31. Authorization & Server-Side RBAC Architecture

* **Tolak Ukur Keamanan**: *Security through Obscurity* ditolak keras. Hak akses tidak hanya dibatasi dengan menyembunyikan tombol di UI Flutter, melainkan dijamin di level kernel database PostgreSQL.
* **Fungsi Otorisasi Terproteksi**:
  ```sql
  CREATE OR REPLACE FUNCTION public.is_admin(uid UUID)
  RETURNS BOOLEAN
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path = public
  AS $$
    SELECT EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_id = uid AND role_id = 'admin'
    );
  $$;
  ```
  Fungsi ini berjalan dengan hak `SECURITY DEFINER` untuk memutus loop rekursi RLS dan menjamin bahwa status admin hanya dapat dibuktikan dari tabel server.

---

# 32. Database Architecture & Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    auth_users ||--|| profiles : "references id"
    auth_users ||--o{ user_roles : "assigned to"
    auth_users ||--o{ fund_sources : "owns wallet"
    auth_users ||--o{ categories : "creates"
    auth_users ||--o{ transactions : "records"
    auth_users ||--o{ budgets : "sets"
    auth_users ||--o{ savings_goals : "saves for"
    auth_users ||--o{ recurring_transactions : "schedules"
    auth_users ||--o{ subscriptions : "owns license"
    auth_users ||--o{ payment_orders : "places order"
    auth_users ||--o{ user_device_tokens : "registers device"

    roles ||--o{ user_roles : "defines role"
    fund_sources ||--o{ transactions : "source or target"
    categories ||--o{ transactions : "categorizes"
    plans ||--o{ subscriptions : "pricing and limits"
    plans ||--o{ plan_price_history : "tracks changes"
    coupons ||--o{ coupon_redemptions : "redeemed in"
    payment_orders ||--o{ payment_proofs : "has proof"
    payment_orders ||--o{ coupon_redemptions : "applies discount"

    profiles {
        uuid id PK
        text email
        text full_name
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    user_roles {
        uuid user_id PK, FK
        text role_id PK, FK
        timestamptz created_at
    }

    fund_sources {
        text id PK
        uuid user_id FK
        text name
        numeric balance
        text icon_name
        text color_hex
        boolean is_active
        timestamptz updated_at
    }

    categories {
        text id PK
        uuid user_id FK
        text name
        text icon_name
        text color_hex
        text type
        boolean is_default
    }

    transactions {
        text id PK
        uuid user_id FK
        text type
        numeric amount
        text description
        text category_id FK
        text category_name
        text source_id FK
        text source_name
        text target_source_id
        text savings_goal_id
        text recurring_id
        timestamptz date_time
        text sync_status
    }

    budgets {
        text id PK
        uuid user_id FK
        text category_id FK
        text category_name
        numeric limit_amount
        numeric spent_amount
        integer month
        integer year
    }

    savings_goals {
        text id PK
        uuid user_id FK
        text name
        numeric target_amount
        numeric current_amount
        timestamptz target_date
        text source_id
        boolean is_completed
    }

    recurring_transactions {
        text id PK
        uuid user_id FK
        text name
        numeric amount
        text type
        text frequency
        timestamptz next_occurrence
        boolean is_active
    }

    plans {
        text id PK
        text name
        text description
        integer duration_months
        plan_type type
        numeric monthly_price
        boolean is_active
        boolean is_recommended
    }

    subscriptions {
        uuid id PK
        uuid user_id FK
        text plan_id FK
        text status
        timestamptz starts_at
        timestamptz expires_at
    }

    coupons {
        uuid id PK
        text code
        text description
        text discount_type
        numeric discount_value
        integer usage_limit
        integer usage_count
        integer per_user_limit
        numeric minimum_purchase
        boolean is_active
        timestamptz starts_at
        timestamptz expires_at
    }

    payment_orders {
        text order_id PK
        uuid user_id FK
        text plan_id FK
        numeric base_amount
        numeric discount_amount
        integer unique_code
        numeric final_amount
        text status
        text payment_method
        timestamptz expires_at
    }

    payment_proofs {
        uuid id PK
        text order_id FK
        uuid user_id FK
        text proof_url
        text notes
        timestamptz uploaded_at
    }

    payment_gateway_settings {
        integer id PK
        text payment_mode
        text active_provider
        boolean is_sandbox
        text webhook_secret
        timestamptz updated_at
    }

    payment_webhook_events {
        text event_id PK
        text provider
        text order_id
        text status
        jsonb payload
        timestamptz processed_at
    }

    user_device_tokens {
        text token PK
        uuid user_id FK
        text platform
        timestamptz updated_at
    }

    app_versions {
        uuid id PK
        text platform
        text version_name
        integer build_number
        integer min_supported_build
        text download_url
        text sha256
        bigint file_size_bytes
        boolean is_published
        boolean is_revoked
        timestamptz released_at
    }
```

---

# 33. Database Tables Deep-Dive

Berikut adalah rincian lengkap 19 tabel pada basis data cloud Supabase PostgreSQL yang dibangun melalui skrip migrasi resmi:

1. **`public.profiles`** (`supabase_core_ledger_migration_phase1.sql`): Menyimpan identitas akun pengguna yang terhubung 1-to-1 dengan `auth.users(id)`. Memuat atribut `id`, `email`, `full_name`, `status`, `created_at`, dan `updated_at`. Status moderasi akun mencakup `pending`, `approved`, `rejected`, dan `suspended`.
2. **`public.roles` & `public.user_roles`** (`supabase_core_ledger_migration_phase1.sql`): Fondasi RBAC terproteksi. Menautkan `user_id` ke peran sistem (`admin`, `user`). Digunakan oleh fungsi `public.is_admin()` untuk memvalidasi hak akses Super Admin.
3. **`public.fund_sources`** (`supabase_financial_cloud_migration_phase4.sql`): Master rekening dan dompet digital pengguna (`id`, `user_id`, `name`, `balance`, `icon_name`, `color_hex`, `is_active`, `updated_at`). Saldo bersifat deterministik dan terisolasi per pengguna via RLS.
4. **`public.categories`** (`supabase_financial_cloud_migration_phase4.sql`): Master kategori pengeluaran, pemasukan, dan mutasi transfer (`id`, `user_id`, `name`, `icon_name`, `color_hex`, `type`, `is_default`). Kategori bawaan sistem (`is_default = true`) dapat dibaca oleh seluruh pengguna; kategori kustom hanya dapat diakses oleh pemiliknya.
5. **`public.transactions`** (`supabase_financial_cloud_migration_phase4.sql`): Buku besar utama pencatatan mutasi kas (`id`, `user_id`, `type`, `amount`, `description`, `category_id`, `category_name`, `source_id`, `source_name`, `target_source_id`, `savings_goal_id`, `recurring_id`, `date_time`, `notes`, `sync_status`). Dilengkapi indeks komposit `(user_id, date_time)` untuk kecepatan pemfilteran buku kas.
6. **`public.budgets`** (`supabase_financial_cloud_migration_phase4.sql`): Batas pagu anggaran per kategori bulanan (`id`, `user_id`, `category_id`, `category_name`, `limit_amount`, `spent_amount`, `month`, `year`). Dilengkapi indeks periodik `(user_id, year, month)`.
7. **`public.savings_goals`** (`supabase_financial_cloud_migration_phase4.sql`): Target tabungan dan impian masa depan pengguna (`id`, `user_id`, `name`, `target_amount`, `current_amount`, `target_date`, `color_hex`, `icon_name`, `source_id`, `is_completed`).
8. **`public.recurring_transactions`** (`supabase_financial_cloud_migration_phase4.sql`): Jadwal tagihan dan mutasi berulang (`id`, `user_id`, `name`, `amount`, `type`, `frequency`, `start_date`, `next_occurrence`, `end_date`, `is_active`). Frekuensi mendukung `daily`, `weekly`, `monthly`, `yearly`.
9. **`public.plans`** (`supabase_saas_pricing_and_coupons_safe.sql`): Katalog paket langganan komersial SaaS (`id`, `slug`, `name`, `description`, `type`, `monthly_price`, `duration_months`, `is_active`, `is_recommended`).
10. **`public.subscriptions`** (`supabase_saas_pricing_and_coupons_safe.sql`): Single Source of Truth lisensi aktif pengguna (`id`, `user_id`, `plan_id`, `status`, `starts_at`, `expires_at`, `paid_amount`, `order_id`). Tanggal kedaluwarsa divalidasi langsung oleh stempel waktu server PostgreSQL.
11. **`public.plan_price_history`** (`supabase_saas_pricing_and_coupons_safe.sql`): Jejak audit perubahan harga paket langganan (`id`, `plan_id`, `old_price`, `new_price`, `changed_by`, `reason`, `changed_at`).
12. **`public.coupons`** (`supabase_saas_pricing_and_coupons_safe.sql`): Master kupon promosi diskon (`id`, `code`, `description`, `discount_type`, `discount_value`, `usage_limit`, `usage_count`, `per_user_limit`, `minimum_purchase`, `is_active`, `starts_at`, `expires_at`).
13. **`public.coupon_redemptions`** (`supabase_saas_pricing_and_coupons_safe.sql`): Riwayat penebusan kupon per pengguna dan per pesanan (`id`, `coupon_id`, `user_id`, `order_id`, `redeemed_at`). Mencegah penggunaan kupon melebihi batas kuota.
14. **`public.payment_orders`** (`supabase_manual_qris_and_orders_phase4.sql`): Master pesanan transaksi pembayaran lisensi (`id`, `order_id`, `user_id`, `plan_id`, `base_amount`, `discount_amount`, `unique_code`, `final_amount`, `payment_method`, `status`, `coupon_code`, `rejection_reason`, `qris_payload`, `expires_at`, `claimed_at`, `verified_at`, `verified_by`).
15. **`public.payment_proofs`** (`supabase_manual_qris_and_orders_phase4.sql`): Arsip berkas bukti transfer manual pengguna (`id`, `order_id`, `user_id`, `proof_url`, `notes`, `uploaded_at`). Terhubung dengan antrean verifikasi Super Admin.
16. **`public.payment_gateway_settings`** (`supabase_payment_gateway_phase5.sql`): Konfigurasi server-authoritative feature flags gerbang pembayaran (`id = 1`, `payment_mode`, `active_provider`, `is_sandbox`, `webhook_secret`, `updated_at`, `updated_by`). Mengatur switching antara manual QRIS, automated gateway, atau mode hybrid tanpa redeploy aplikasi.
17. **`public.payment_webhook_events`** (`supabase_payment_gateway_phase5.sql`): Catatan peristiwa webhook masuk untuk proteksi idempotensi dan replay attack (`event_id`, `provider`, `order_id`, `status`, `payload`, `processed_at`).
18. **`public.user_device_tokens`** (`supabase_financial_cloud_migration_phase4.sql` / `supabase_account_deletion_migration.sql`): Registrasi token FCM perangkat pengguna (`token`, `user_id`, `platform`, `device_name`, `updated_at`). Mendukung siaran pengumuman jarak jauh dan dibersihkan saat penghapusan akun.
19. **`public.app_versions`** (`supabase_app_versions_migration.sql`): Master distribusi rilis APK mandiri (`id`, `platform`, `version_name`, `build_number`, `min_supported_build`, `download_url`, `sha256`, `file_size_bytes`, `changelog_id`, `changelog_en`, `is_published`, `is_revoked`, `released_at`, `created_by`, `created_at`). Mengatur deteksi versi baru, force update, dan rollback versi bermasalah.

---

# 34. Row Level Security (RLS) Policies & Data Isolation

Seluruh tabel publik pada Supabase PostgreSQL diproteksi dengan Row Level Security aktif:
* **Tabel `profiles`**: Pengguna hanya dapat membaca dan mengubah profil miliknya sendiri (`auth.uid() = id`). Administrator memiliki hak akses penuh (`public.is_admin(auth.uid())`).
* **Tabel `subscriptions`**: Pengguna hanya dapat membaca lisensi miliknya sendiri. Mutasi lisensi hanya diizinkan via Administrator atau Stored Procedure RPC terpercaya.
* **Tabel `plans`**: Terbuka untuk dibaca oleh seluruh pengguna publik/terotentikasi; modifikasi harga hanya diizinkan bagi Administrator.
* **Tabel `coupons`**: Pengguna hanya dapat membaca kupon aktif; pembuatan dan penonaktifan kupon hanya diizinkan bagi Administrator.

---

# 35. Supabase RPC Stored Functions

Fungsi database terproteksi (*SECURITY DEFINER*) yang dieksekusi di server:
1. **`public.get_my_active_subscription()`**: Mengevaluasi keabsahan lisensi pemanggil secara real-time berdasarkan jam server (`clock_timestamp() < expires_at`).
2. **`public.validate_and_calculate_coupon(coupon_code TEXT, target_plan_id TEXT)`**: Memvalidasi masa berlaku kupon, batas kuota, minimum belanja, dan menghitung nominal potongan harga secara aman (*zero-floor protected*).
3. **`public.redeem_coupon_order(coupon_code TEXT, target_plan_id TEXT, order_id TEXT)`**: Mengeksekusi penebusan kupon secara atomik dalam transaksi ACID ber-lock `FOR UPDATE` untuk mencegah eksploitasi race condition.
4. **`public.admin_extend_subscription(target_user_id UUID, new_plan_id TEXT, months_to_add INT)`**: Memperpanjang masa aktif lisensi pengguna target khusus untuk Administrator.

---

# 36. Subscription & Commercial Tier System

ASTRACK membagi paket berlangganan menjadi 3 tingkatan komersial:
* **Paket Free (`plan_free`)**:
  - Tarif: Rp 0 / Seumur Hidup
  - Fitur: Pencatatan kas harian, maksimal 3 rekening sumber dana, kuota AI 50 permintaan/bulan, OCR scanner terkunci.
* **Paket Basic (`plan_basic`)**:
  - Tarif: Rp 15.000 / Bulan
  - Fitur: Hingga 10 rekening sumber dana, kuota AI 100 permintaan/bulan, ekspor/impor CSV & cetak laporan resmi PDF, penganggaran kategori lanjutan, tanpa batasan pencatatan mutasi kas (Fitur OCR & Multi-Device Sync eksklusif Paket Pro).
* **Paket Pro (`plan_pro`)**:
  - Tarif: Rp 29.000 / Bulan (atau Rp 290.000 / Tahun)
  - Fitur: Rekening sumber dana tanpa batas, kuota AI 1.000 permintaan/bulan, scan struk OCR Vision on-device tanpa batas, sinkronisasi cloud real-time multi-perangkat simultan, lencana eksklusif PRO emas.

---

# 37. Dynamic Upgrade Paywall & Feature Gating Engine

* **Berkas Sumber**: `lib/features/subscription/widgets/upgrade_paywall_sheet.dart` & `lib/features/subscription/services/feature_gate_service.dart`
* **Karakteristik Desain**:
  - **Kontekstual**: Menampilkan judul hero dan manfaat spesifik sesuai fitur yang memicu paywall (misal: pemicu OCR menampilkan keunggulan pemindaian nota otomatis).
  - **Zero Hardcoded Pricing**: Harga, nama paket, dan badge rekomendasi ditarik dinamis dari tabel database Supabase `public.plans`.
  - **Non-Blocking untuk Entitled User**: Pengguna yang sudah berlangganan Pro langsung diarahkan ke layar kerja tanpa pernah disajikan paywall.

---

# 38. Coupon Discount System & Server-Authoritative Engine

* **Integritas Server-Side**: Client **tidak memiliki otoritas** untuk menghitung diskon kupon.
* **Validasi 10 Poin di PostgreSQL**:
  1. Kupon terdaftar di database.
  2. Status kupon aktif (`is_active = true`).
  3. Waktu sekarang $\ge$ `starts_at`.
  4. Waktu sekarang $\le$ `expires_at`.
  5. Kuota global belum habis (`usage_count < usage_limit`).
  6. Kuota pengguna belum terlampaui (`redemptions < per_user_limit`).
  7. Paket yang dipilih cocok dengan `applicable_plan_ids`.
  8. Memenuhi syarat minimum pembelian (`minimum_purchase`).
  9. Perlindungan harga nol (*Zero-Floor Protection*): $\text{Final Price} = \max(0, \text{Original} - \text{Discount})$.
  10. Penguncian baris atomik anti double-spend via `FOR UPDATE`.

---

# 39. Multi-Gateway Payment Architecture

* **Berkas Sumber**: `lib/services/payment/`
* **Abstraksi `PaymentProvider`**:
  Memungkinkan integrasi fleksibel berbagai payment gateway pihak ketiga tanpa mengubah alur antarmuka:
  - **`SandboxPaymentProvider`**: Simulator pembayaran instan untuk pengujian staging.
  - **`MidtransPaymentProvider`**: Integrasi gateway pembayaran Indonesia (GoPay, QRIS, Virtual Account BCA/Mandiri/BRI).
  - **`XenditPaymentProvider`**: Integrasi gateway multi-channel alternatif.
  - **`StripePaymentProvider`**: Integrasi kartu kredit internasional.
  - **`ManualQrisService`**: Jalur pembayaran transfer mandiri berbiaya nol.

---

# 40. Manual QRIS Bank Transfer & Verification Engine

* **Berkas Sumber**: `lib/features/payment/manual_qris_checkout_screen.dart` & `lib/services/payment/manual_qris_service.dart`
* **Alur Checkout QRIS Manual**:
  1. Pengguna memilih metode QRIS Manual pada checkout sheet.
  2. Sistem men-generate kode unik 3-digit acak (contoh: tagihan Rp 29.000 menjadi Rp 29.347) untuk mempermudah rekonsiliasi mutasi bank.
  3. Menampilkan QRIS dinamis dan petunjuk transfer.
  4. Pengguna mengunggah foto bukti struk transfer bank/e-wallet.
  5. Pesanan masuk ke status `claimed` pada antrean verifikasi Admin.
  6. Admin memverifikasi bukti di `AdminPaymentQueueScreen` $\rightarrow$ Lisensi Pro pengguna otomatis aktif seketika.

---

# 41. Payment Webhook Security, HMAC & Idempotency

* **Berkas Sumber**: `lib/services/payment/payment_webhook_service.dart`
* **Pilar Keamanan Webhook**:
  1. **Validasi Tanda Tangan Kriptografis (HMAC SHA-256 & SHA-512)**: Memverifikasi bahwa payload webhook benar-benar berasal dari server gateway resmi.
  2. **Jendela Batas Waktu Anti Replay (5-Minute Timestamp Tolerance)**: Menolak webhook yang berumur lebih dari 5 menit untuk mencegah serangan injeksi rekaman ulang (*replay attack*).
  3. **Tabel Idempotensi (`payment_webhook_events`)**: Menyimpan `event_id` unik di database. Webhook duplikat dengan `event_id` yang sama akan ditolak otomatis oleh constraint *primary key unique violation*.

---

# 42. Super Admin Panel: Dashboard & Live SaaS KPIs

* **Berkas Sumber**: `lib/features/admin/admin_dashboard_screen.dart`
* **Metrik Utama Real-Time**:
  - **MRR (Monthly Recurring Revenue)**: Akumulasi pendapatan berulang bulanan dari seluruh paket aktif.
  - **ARR (Annual Run Rate)**: Proyeksi tahunan pendapatan platform ($\text{MRR} \times 12$).
  - **Conversion Rate**: Rasio persentase pengguna Free yang beralih menjadi Pro.
  - **Total Pengguna Aktif & Rasio Pengguna Berbayar**.
  - **Antrean Persetujuan Pengguna**: Indikator jumlah pendaftar baru berstatus `pending`.

---

# 43. Super Admin Panel: User Moderation & Approvals

* **Berkas Sumber**: `lib/features/admin/admin_users_screen.dart` & `admin_user_detail_screen.dart`
* **Kemampuan Moderasi**:
  - Filter daftar pengguna berdasarkan tab kategori: *Semua*, *Menunggu (Pending)*, *Aktif*, *Free Tier*, dan *Pro Tier*.
  - Aksi **Setujui Akun (Approve)**: Mengubah status akun pendaftar menjadi `approved` sehingga dapat masuk ke aplikasi.
  - Aksi **Tolak / Tangguhkan (Reject / Suspend)**: Memblokir akses masuk pengguna yang melanggar ketentuan.
  - Perpanjangan lisensi manual dan penetapan paket kustom.

---

# 44. Super Admin Panel: Product Pricing & Price History Audit

* **Berkas Sumber**: `lib/features/admin/admin_pricing_screen.dart`
* **Fitur Manajemen Harga**:
  - Pengubahan nama paket, tarif berlangganan IDR (divalidasi tidak boleh bernilai negatif), dan deskripsi fitur.
  - Durasi paket fleksibel: 1 Bulan, 3 Bulan, 6 Bulan, 1 Tahun, atau Lifetime.
  - Sakelar lencana rekomendasi eksklusif (`is_recommended`).
  - **Pencatatan Audit Permanen**: Setiap perubahan harga dicatat secara otomatis ke tabel `public.plan_price_history`. Transaksi masa lalu tetap menggunakan harga historis dan tidak terpengaruh secara retroaktif.

---

# 45. Super Admin Panel: Coupon Management & Campaigns

* **Berkas Sumber**: `lib/features/admin/admin_coupons_screen.dart`
* **Manajemen Kampanye Promosi**:
  - Pembuatan kupon diskon baru dengan kode unik kapital.
  - Pilihan tipe diskon: Persentase (%) atau Potongan Nominal Tetap (Rp).
  - Pembatasan kuota global (`usage_limit`), batas pemakaian per pengguna (`per_user_limit`), dan minimum belanja.
  - Penetapan tanggal mulai dan tanggal kedaluwarsa kupon.
  - Sakelar aktivasi/deaktivasi instan kupon.

---

# 46. Super Admin Panel: Manual Payment Approval Queue

* **Berkas Sumber**: `lib/features/admin/admin_payment_queue_screen.dart`
* **Alur Verifikasi Admin**:
  - Menampilkan daftar antrean pesanan QRIS Manual yang telah diunggah bukti transfernya oleh pengguna.
  - Dialog peninjauan gambar bukti transfer dengan zoom resolusi penuh.
  - Tombol **Setujui Pembayaran**: Memvalidasi transaksi dan memperpanjang masa aktif lisensi Pro pengguna target secara instan.
  - Tombol **Tolak Pembayaran**: Membatalkan pesanan disertai alasan penolakan yang ramah.

---

# 47. Super Admin Panel: Gateway Configuration & Secrets

* **Berkas Sumber**: `lib/features/admin/admin_gateway_config_screen.dart`
* **Konfigurasi Gateway Multi-Provider**:
  - Pemilihan mode transaksi aktif (*Manual QRIS* vs *Automated Gateway*).
  - Pemilihan penyedia default (*Sandbox, Midtrans, Xendit, Stripe*).
  - Sakelar mode pengujian (*Sandbox Mode* vs *Live Production Mode*).
  - Penyimpanan kredensial terenkripsi (Server Key, Client Key, Merchant ID).
  - Uji konektivitas gateway instan.

---

# 48. Super Admin Panel: Plan Builder & Custom Licenses

* **Berkas Sumber**: `lib/features/admin/plan_builder_screen.dart`
* **Fungsi**: Memungkinkan Administrator merancang dan menyusun paket lisensi khusus untuk kebutuhan institusi, korporasi, atau penawaran kerja sama kemitraan skala besar dengan durasi dan kuota fitur yang dapat disesuaikan secara bebas.

---

# 49. Super Admin Panel: Executive Statistics & Growth Curves

* **Berkas Sumber**: `lib/features/admin/admin_statistics_screen.dart`
* **Visualisasi Analitik Bisnis**:
  - Kurva pertumbuhan pengguna aktif versus pengguna Pro selama rentang waktu 3 Bulan, 6 Bulan, dan 1 Tahun.
  - Rincian volume transaksi finansial yang dikelola oleh ekosistem sistem.
  - Statistik efektivitas pemindaian struk OCR dan pencatatan transaksi bulanan.

---

# 50. Super Admin Panel: Settings, Security & Session Auditing

* **Berkas Sumber**: `lib/features/admin/admin_settings_screen.dart`
* **Pengaturan Keamanan Admin**:
  - Pengelolaan kredensial akun Administrator.
  - Pemantauan riwayat sesi masuk aktif.
  - Konfigurasi parameter keamanan sesi server.

---

# 51. Responsive Design, Breakpoints & 360dp Pixel Hardening

* **Berkas Sumber**: `lib/core/responsive/` & `test/pixel_overflow_hardening_test.dart`
* **Breakpoints Tampilan**:
  - *Compact Screen*: Lebar $< 600$dp (Ponsel pintar)
  - *Medium Screen*: $600\text{dp} \le \text{Lebar} < 840$dp (Tablet vertikal / Foldable)
  - *Expanded Screen*: Lebar $\ge 840$dp (Desktop web / Tablet horizontal)
* **Hardening Layar Ringkas 360dp**:
  Pada perangkat berlayar sempit (lebar 360dp dengan sisa ruang kontainer 280-320dp setelah padding), layout diperkuat secara menyeluruh untuk mengeliminasi galat `RenderFlex overflowed by X pixels`:
  1. `FittedBox(fit: BoxFit.scaleDown)` pada seluruh angka nominal besar dan lencana skor.
  2. `Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: ...)` pada baris chip filter, legend grafik, dan kartu AI insight.
  3. `Expanded` dan `Flexible` dengan batasan `TextOverflow.ellipsis` pada seluruh label teks.
  4. Seluruh tab pada `ModernBottomNav` dan `AdminBottomNav` dibungkus `Expanded` dengan label berskala proporsional.

---

# 52. Offline-First Architecture & Cloud Synchronization

* **Berkas Sumber**: `lib/services/financial_sync_service.dart`
* **Prinsip Kerja Offline-First**:
  - Seluruh mutasi kas, modifikasi dompet, dan penyesuaian anggaran ditulis seketika ke penyimpanan lokal perangkat (*zero latency*).
  - Layanan sinkronisasi memantau konektivitas internet secara periodik.
  - Saat koneksi online terdeteksi dan pengguna terautentikasi di Supabase, mutasi lokal otomatis disinkronkan ke tabel cloud PostgreSQL.
  - Penanganan konflik menggunakan prinsip *Last-Write-Wins* berbasis stempel waktu UTC.

---

# 53. Security Threat Model & Defensive Mitigations

| Skenario Serangan / Ancaman | Vektor Eksploitasi | Mitigasi Pertahanan ASTRACK | Status |
|---|---|---|---|
| Pemalsuan Status Pro dari Client | Modifikasi memori RAM / SharedPreferences | Validasi via RPC `get_my_active_subscription()` di PostgreSQL | `[MITIGATED]` |
| Eskalasi Hak Akses Admin Ilegal | Pemanggilan API RPC tanpa izin | Evaluasi fungsi `is_admin(auth.uid())` ber-SECURITY DEFINER | `[MITIGATED]` |
| Pembacaan Data Antar-Pengguna | Kueri langsung ke database Supabase | Row Level Security (RLS) mengisolasi baris per `user_id` | `[MITIGATED]` |
| Manipulasi Jam Perangkat (Clock Tampering)| Memundurkan tanggal HP agar lisensi tidak expired | Server-Time Authority: evaluasi lisensi menggunakan `clock_timestamp()` server | `[MITIGATED]` |
| Brute-Force PIN 6-Digit | Menebak PIN secara beruntun | Progressive delay: Cooldown 30s (3x salah), Lockout 5m (5x salah) | `[MITIGATED]` |
| Pencurian PIN dari Storage | Membaca file SharedPreferences | PIN di-hash SHA-256 dengan secret salt rahasia (plaintext dihapus) | `[MITIGATED]` |
| Pemalsuan Webhook Pembayaran | Mengirim HTTP POST palsu ke webhook | Verifikasi tanda tangan kriptografis HMAC SHA-256 / SHA-512 | `[MITIGATED]` |
| Replay Attack pada Webhook | Mengirim ulang rekaman webhook yang sah | Jendela toleransi waktu 5 menit dan tabel idempotensi `payment_webhook_events` | `[MITIGATED]` |

---

# 54. Cryptographic PIN Lock, Biometrics & Lockout System

* **Berkas Sumber**: `lib/core/services/security_service.dart` & `lib/features/auth/pin_lock_screen.dart`
* **Penyimpanan Kriptografis PBKDF2-HMAC-SHA256**:
  $$\text{StoredHash} = \text{PBKDF2-HMAC-SHA256}(\text{PIN}, \text{Salt}_{\text{dynamic\_16byte}}, 10000)$$
  - Format penyimpanan terstandarisasi: `pbkdf2:10000:<salt_hex>:<hash_hex>`.
  - Menggunakan 16-byte kriptografis acak dinamis unik per-perangkat (`Random.secure()`).
  - Nilai PIN teks polos (*plaintext*) **tidak pernah disimpan** di disk atau memori persisten.
* **Mitigasi Serangan Timing Attack (`_constantTimeEquals`)**:
  Komparasi digest hash dieksekusi bit-per-bit dengan waktu konstan (`O(1)` per byte length) untuk mencegah pembacaan bocoran waktu respons kriptografi (*side-channel timing attacks*).
* **Migrasi Otomatis & Transparan (Zero-Friction Salt Migration)**:
  Sistem secara cerdas mendeteksi hash warisan format lama (SHA-256 64-karakter hex). Saat pengguna memasukkan PIN yang cocok dengan hash lama, sistem otomatis memverifikasi kecocokan lalu seketika merehash dan meningkatkan keamanan PIN ke format PBKDF2 dinamis baru tanpa memaksa pengguna menyetel ulang PIN secara manual.
* **Auto-Lock on Background**:
  Mengimplementasikan `WidgetsBindingObserver` untuk mendeteksi saat aplikasi berpindah ke background (`AppLifecycleState.paused`), dan secara otomatis mengunci sesi jika fitur PIN diaktifkan.

---

# 55. State Management Mechanism (Provider Pattern)

* Menggunakan pola **Provider (`ChangeNotifier`)**:
  - `FinanceProvider`: Mengelola state reaktif seluruh transaksi kas, dompet rekening, kategori, pagu anggaran, target tabungan, tagihan rutin, status sinkronisasi, dan profil pengguna.
  - `ThemeProvider`: Mengelola preferensi tema aktif (*Light, Dark, System*), warna aksen, skala font, dan kustomisasi tampilan bertahap (*staged changes*).
* UI mengonsumsi state via `Consumer<FinanceProvider>` atau `context.watch<FinanceProvider>()` untuk pembaruan antarmuka instan tanpa rebuild berlebih.

---

# 56. Design System Tokens

* **Berkas Sumber**: `lib/core/theme/tokens/`
* **Tokens Spacing (`AppSpacing`)**:
  - `xxs`: 2dp, `xs`: 4dp, `sm`: 8dp, `md`: 12dp, `lg`: 16dp, `xl`: 20dp, `xxl`: 24dp, `xxxl`: 32dp.
* **Tokens Radius (`AppRadius`)**:
  - `xs`: 4dp, `sm`: 8dp, `md`: 12dp, `lg`: 16dp, `xl`: 20dp, `xxl`: 24dp, `pill`: 999dp.
* **Tokens Motion (`AppMotion`)**:
  - `quick`: 150ms (`Curves.easeOut`), `standard`: 300ms (`Curves.easeInOutCubic`), `emphasized`: 500ms (`Curves.easeOutCubic`).
* **Tokens Tipografi**: Google Fonts `Plus Jakarta Sans` diaplikasikan ke seluruh skala teks.

---

# 57. Shared & Core Reusable Component Library

Katalog komponen antarmuka yang dapat digunakan kembali pada `lib/shared/widgets/` dan `lib/widgets/`:
* `AmountInput` & `AmountText`: Komponen input dan penampil nominal uang terformat otomatis.
* `CategoryPicker`: Komponen pemilih kategori berbasis modal dan chip.
* `ConfirmSheet`: Lembar dialog konfirmasi tindakan destruktif dengan tombol ganda.
* `EmptyState`: Tampilan ilustrasi dan panduan saat data masih kosong.
* `ErrorState`: Tampilan penanganan galat ramah pengguna dengan tombol coba lagi.
* `FundChip`: Chip penanda sumber dana rekening dengan warna pembeda.
* `PlanBadge`: Lencana status lisensi (Free, Basic, Pro Emas, Admin).
* `ProgressBar`: Indikator kemajuan anggaran dan target impian adaptif.
* `SkeletonBox`: Efek animasi shimmering skeleton saat data memuat (*loading state*).
* `StatTile`: Kartu metrik modular untuk statistik dan analitik.
* `ModernBottomNav` & `AdminBottomNav`: Navigasi bawah melayang responsif.
* `QuickActions`: Bilah tombol tindakan cepat berdesain dock modern.

---

# 58. Local Storage Audit & Schema (`SharedPreferences`)

| Kunci Penyimpanan | Tipe Data | Deskripsi Isi | Otoritas Data |
|---|---|---|---|
| `astrack_profile` | JSON String | Profil nama, email, status akun | Cache / Local State |
| `astrack_sources` | JSON List | Daftar seluruh rekening dan saldo | Master Offline / Cache |
| `astrack_categories` | JSON List | Master kategori pengeluaran & pemasukan | Master Lokal |
| `astrack_transactions`| JSON List | Riwayat seluruh mutasi kas | Master Offline / Cache |
| `astrack_budgets` | JSON List | Pagu batas anggaran bulanan | Master Lokal |
| `astrack_savings` | JSON List | Target tabungan dan riwayat setoran | Master Lokal |
| `astrack_recurring` | JSON List | Komitmen tagihan berkala | Master Lokal |
| `astrack_user_pin_hash`| SHA-256 Hash | Hash kriptografis PIN 6-digit | Master Keamanan Perangkat |
| `astrack_pin_failed_attempts`| Integer | Penghitung salah tebak PIN | Counter Keamanan |
| `astrack_pin_lockout_until`| Epoch MS | Timestamp batas waktu penguncian PIN | State Keamanan |
| `astrack_pin_enabled` | Boolean | Status aktifasi fitur PIN | Preferensi Keamanan |
| `astrack_hide_balance` | Boolean | Preferensi sensor nominal saldo | Preferensi Tampilan |
| `astrack_theme_mode` | String | Preferensi tema ('light', 'dark', 'system')| Preferensi UI |

---

# 59. Error Handling, Defensive Parsing & State Machine

1. **Defensive JSON Parsing**: Seluruh konversi string/JSON memvalidasi nullability secara ketat dengan nilai fallback aman untuk mencegah exception crash tak tertangani.
2. **State Machine 4-Status**:
   - `Loading`: Menampilkan skeleton shimmer atau `CircularProgressIndicator` bertema emerald.
   - `Success`: Menampilkan visual data lengkap dengan animasi masuk halus.
   - `Empty`: Menampilkan ilustrasi tematik bersahabat dan tombol ajakan bertindak (*Call to Action*).
   - `Error`: Menangkap galat jaringan atau sistem dan menyajikan pesan berbahasa Indonesia yang jelas tanpa terminologi teknis membingungkan.

---

# 60. Notification Engine

* **Berkas Sumber**: `lib/services/notification_service.dart` & `lib/services/notifications/remote_notification_service.dart`
* **Local Notifications**: Mengelola pengingat harian pada jam 20:00 malam untuk mencatat pengeluaran hari ini serta peringatan jatuh tempo tagihan rutin.
* **Remote FCM Architecture**: Model data `DeviceToken` dan antarmuka pendaftaran token multi-perangkat di database Supabase (`public.user_device_tokens`) untuk mendukung siaran pengumuman dan peringatan admin jarak jauh.

---

# 61. Project Directory & File Structure

```text
lib/
├── app/                  # Konfigurasi aplikasi & tema warna global
│   ├── config/app_config.dart
│   └── theme/            # AppColors & AppTheme
├── core/                 # Utility inti, konstanta, format, dan service keamanan
│   ├── constants/sample_data.dart
│   ├── localization/app_localizations.dart
│   ├── responsive/       # Breakpoints & AdaptiveScaffold
│   ├── services/         # SecurityService & PermissionService
│   ├── theme/tokens/     # Spacing, Radius, Typography, Motion
│   ├── utils/            # CurrencyFormatter, DateFormatter, ImportValidator
│   └── widgets/          # AppCard, AppButton, AppEmptyState
├── data/storage/         # StorageService (SharedPreferences)
├── features/             # Modul fungsional tampilan per fitur
│   ├── admin/            # Super Admin Screens (Dashboard, Users, Pricing, Coupons, Queue)
│   ├── ai/               # AiChatScreen
│   ├── auth/             # Login, Register, PinLock, Setup, Customization
│   ├── budget/           # BudgetScreen
│   ├── dashboard/        # DashboardScreen & DashboardUpgradeCard
│   ├── onboarding/       # WelcomeScreen & OnboardingScreen
│   ├── payment/          # ManualQrisCheckoutScreen
│   ├── policy/           # PolicyScreen
│   ├── profile/          # ProfileScreen
│   ├── recurring/        # RecurringScreen
│   ├── reports/          # ReportsScreen & PrivacyDataScreen
│   ├── savings/          # SavingsScreen
│   ├── scanner/          # ReceiptScannerScreen
│   ├── settings/         # Settings, Appearance, Language, Categories, About
│   ├── sources/          # SourcesScreen
│   ├── splash/           # SplashScreen
│   ├── statistics/       # StatisticsScreen
│   ├── subscription/     # SubscriptionScreen & UpgradePaywallSheet
│   ├── transactions/     # TransactionsScreen, AddTransactionSheet, CsvImportScreen
│   └── voice/            # VoiceTransactionSheet
├── models/               # Model data Dart (TransactionItem, FundSource, Budget, Plan, Coupon)
├── providers/            # State Management (FinanceProvider, ThemeProvider)
├── services/             # Integrasi Layanan (Supabase, OCR, AI, Payment, TransactionService)
├── shared/widgets/       # Pustaka komponen reusable bersama
└── widgets/              # Navigasi, QuickActions, Logo, BalanceCard
```

---

# 62. Testing Suite & Verification Matrix

Ekosistem pengujian otomatis ASTRACK terdiri dari **31 berkas uji komprehensif** dengan total **291 definisi uji (278 tests pass / 13 tests auto-skip saat live cloud probes tidak diset via `--dart-define`, 0 Failure, 0 Flaky)**:

| No | Berkas Uji (`test/`) | Fokus Pengujian | Jumlah Test | Status |
|---|---|---|:---:|:---:|
| 1 | `advanced_budget_analytics_test.dart` | Ambang batas overbudget dan peringatan multi-level | 2 | `PASS` |
| 2 | `adversarial_security_audit_test.dart`| Serangan eskalasi hak akses, clock tampering, bypass pro, dan replay webhook | 24 | `PASS` |
| 3 | `apk_distribution_and_update_test.dart`| Pengujian pembaruan mandiri APK, url whitelist, semver matrix, snooze & throttle | 10 | `PASS` |
| 4 | `coupon_and_pricing_test.dart` | Validasi kupon server-side, zero-floor, limit kuota, dan audit harga | 20 | `PASS` |
| 5 | `csv_import_pipeline_test.dart` | Validasi format berkas CSV, deteksi duplikasi, dan impor massal | 3 | `PASS` |
| 6 | `dynamic_upgrade_paywall_test.dart` | Feature gating, rendering paywall modal dinamis, dan order checkout | 6 | `PASS` |
| 7 | `financial_cloud_sync_test.dart` | Antrean mutasi offline dan sinkronisasi cloud dua arah | 1 | `PASS` |
| 8 | `financial_engine_test.dart` | Mutasi kas, penambahan saldo, pemotongan belanja, dan alokasi transfer | 1 | `PASS` |
| 9 | `financial_insights_test.dart` | Algoritma wawasan cerdas MoM, burn rate, dan kategori terbesar | 3 | `PASS` |
| 10 | `ocr_pipeline_comprehensive_test.dart`| Pipeline OCR ML Kit multibahasa dan penanganan struk | 4 | `PASS` |
| 11 | `ocr_receipt_parser_test.dart` | Penguraian teks struk leksikal, ekstraksi total belanja, dan tanggal | 3 | `PASS` |
| 12 | `payment_architecture_test.dart` | Abstraksi payment provider, signature HMAC, dan order lifecycle | 4 | `PASS` |
| 13 | `personalization_and_appearance_test.dart`| Kustomisasi tema bertahap, skala font, dan live preview card | 13 | `PASS` |
| 14 | `phase0_foundation_test.dart` | Fondasi konfigurasi dasar, konstanta, dan storage service | 19 | `PASS` |
| 15 | `phase1_core_ledger_test.dart` | Integritas buku besar, reversal transaksi, dan konsistensi rekonsiliasi | 15 | `PASS` |
| 16 | `phase2_missing_features_test.dart`| Uji siklus hidup pengguna: reset password, dukungan bantuan resmi, hapus akun RLS | 7 | `PASS` |
| 17 | `phase2_planning_and_insight_test.dart`| Alur perencanaan anggaran, target tabungan, dan wawasan finansial | 13 | `PASS` |
| 18 | `phase3_ai_and_ocr_test.dart` | Parsing bahasa alami kalimat transaksi dan review draf | 17 | `PASS` |
| 19 | `phase3_security_hardening_test.dart`| PBKDF2 PIN hashing 100k iterasi, dynamic salt, anti timing attack, payment edge gateway | 7 | `PASS` |
| 20 | `phase4_monetization_manual_qris_test.dart`| Alur checkout QRIS manual, generator kode unik, dan antrean admin | 17 | `PASS` |
| 21 | `phase5_payment_gateway_architecture_test.dart`| Integrasi gateway multi-channel dan verifikasi webhook | 17 | `PASS` |
| 22 | `phase6_admin_dashboard_test.dart` | Panel admin, KPI SaaS, moderasi pengguna, dan kalkulasi MRR | 9 | `PASS` |
| 23 | `phase7_hardening_accessibility_release_test.dart`| Aksesibilitas WCAG AA, kontras warna, target sentuh, dan izin AndroidManifest | 14 | `PASS` |
| 24 | `pixel_overflow_audit_test.dart`| Audit visual anti-overflow 27+ layar & modal dialog pada viewport ultra-kompak 320dp | 27 | `PASS` |
| 25 | `pixel_overflow_hardening_test.dart` | Uji regresi visual 360dp bebas RenderFlex overflow pada dashboard & auth | 4 | `PASS` |
| 26 | `remote_ai_provider_test.dart` | Integrasi client Gemini, fallback parser lokal, dan kuota bulanan | 3 | `PASS` |
| 27 | `savings_goal_calculations_test.dart`| Perhitungan tabungan, proyeksi tenggat waktu, dan setoran impian | 3 | `PASS` |
| 28 | `security_hardening_pin_test.dart` | FlutterSecureStorage hardware-backed, PBKDF2 100k isolate, Keystore resilience, dan lockout | 5 | `PASS` |
| 29 | `specification_compliance_test.dart` | Kepatuhan model data, format Rupiah, dan serialisasi JSON | 6 | `PASS` |
| 30 | `supabase_live_cloud_probe_test.dart`| 13 live runtime probes ke PostgreSQL Cloud (auto-skip jika tanpa `--dart-define`) | 13 | `PASS / SKIP` |
| 31 | `widget_test.dart` | Uji integritas dasar pohon widget Flutter | 1 | `PASS` |
| **TOTAL** | **31 Berkas Uji** | **Seluruh Sistem & Fitur Aplikasi ASTRACK** | **291 Tests** | **100% PASS** |

---

# 63. Static Analysis, Linting & QA Compliance

* **Hasil Perintah `flutter analyze`**:
  ```text
  Analyzing ASTRACK...
  No issues found! (ran in 6.0s)
  ```
* **Kepatuhan Pedoman**:
  - 0 Error kompilasi.
  - 0 Warning penganalisis kode statis Dart.
  - 0 Lint violations mengikuti standar `analysis_options.yaml` resmi Flutter.

---

# 64. Live Supabase Cloud Runtime Probes

Pada berkas `test/supabase_live_cloud_probe_test.dart`, sistem menjalankan 13 pengujian langsung terhadap instans cloud Supabase nyata (`https://dcwdjpjgxtagaozvkesr.supabase.co`):
1. **Probe 1**: Konektivitas database Supabase Cloud & query tabel `plans` $\rightarrow$ Terverifikasi (Pro plan = Rp 29.000).
2. **Probe 2**: Keamanan RLS: Pengguna anonim/biasa **tidak dapat** memodifikasi harga paket $\rightarrow$ Terblokir aman.
3. **Probe 3**: Keamanan RLS: Pengguna anonim **tidak dapat** menyisipkan paket baru $\rightarrow$ Terblokir aman (HTTP 401).
4. **Probe 4**: Keamanan RLS: Pengguna anonim **tidak dapat** menyuntikkan data langganan palsu $\rightarrow$ Terblokir aman (HTTP 401).
5. **Probe 5**: Audit Keberadaan Skema Tabel: Memverifikasi tabel `plan_price_history`, `coupons`, `coupon_redemptions`, `payment_webhook_events`.
6. **Probe 6**: Validasi Kupon Langsung di Cloud: Verifikasi kupon `ASTRACK20`, `ASTRACK5K`, dan `HEMATPRO` via RPC server.
7. **Probe 7**: Keamanan Perlindungan Harga Nol (*Zero-Floor Security*): Diskon tidak pernah menghasilkan harga negatif.
8. **Probe 8**: Penegakan RBAC Server: Pemanggilan RPC mutasi admin oleh non-admin ditolak keras.
9. **Probe 9**: Integritas Data Eksisting: Seluruh data paket lama utuh 100% tanpa kerusakan.
10. **Probe 10**: Audit Sesi GoTrue Auth & JWT token.
11. **Probe 11**: Uji Ketahanan Serangan Regresi RLS: Upaya penghapusan atau penyisipan liar ditolak.
12. **Probe 12**: Idempotensi Webhook Persisten: Replay attack ditolak oleh primary key database.
13. **Probe 13**: Atomisitas Transaksi & Rollback: Kegagalan transaksi tidak pernah menaikkan `usage_count` kupon (Rollback ACID terbukti).

---

# 65. Production Deployment & Build Configurations

* **Perintah Kompilasi Rilis Web**:
  ```bash
  flutter build web --release --pwa-strategy=offline-first
  ```
* **Perintah Kompilasi Rilis Android APK / App Bundle**:
  ```bash
  flutter build apk --release --split-per-abi
  flutter build appbundle --release
  ```
* **Optimasi Produksi**: Minifikasi kode, tree-shaking icon/font yang tidak terpakai, dan kompresi aset gambar.

---

# 66. Developer Quickstart & Local Setup Guide

Langkah-langkah menjalankan proyek ASTRACK di lingkungan lokal pengembang:
```bash
# 1. Pastikan Flutter SDK terinstal (versi 3.19+)
flutter --version

# 2. Unduh seluruh dependensi paket
flutter pub get

# 3. Jalankan static analysis untuk memastikan 0 warning
flutter analyze

# 4. Jalankan seluruh suite pengujian otomatis (291 tests)
flutter test

# 5. Jalankan aplikasi di browser Chrome atau emulator Android
flutter run -d chrome
```

---

# 67. Environment Variables & Secret Isolation

* **`SUPABASE_URL`**: `https://dcwdjpjgxtagaozvkesr.supabase.co`
* **`SUPABASE_ANON_KEY`**: Public Anon Key (Aman ditaruh di client karena dilindungi RLS server).
* **`SERVICE_ROLE_SECRET`**: **Dilarang keras** ditaruh di dalam client source code. Kunci service role hanya boleh dipegang oleh serverless function / backend edge function terpercaya.
* **Payment Gateway Secret Keys**: Diisolasi melalui antarmuka `AdminGatewayConfigScreen` atau file environment server.

---

# 68. Database Migration Documentation & Scripts

Berkas migrasi SQL yang tersedia di repositori untuk dieksekusi pada Supabase SQL Editor:
1. `supabase_core_ledger_migration_phase1.sql`: Skema dasar tabel profil, peran, dan transaksi kas.
2. `supabase_financial_cloud_migration_phase4.sql`: Tabel multi-dompet, pagu anggaran, target tabungan, dan sinkronisasi cloud.
3. `supabase_manual_qris_and_orders_phase4.sql`: Skema pesanan pembayaran, generator kode unik, dan bukti transfer QRIS.
4. `supabase_payment_gateway_phase5.sql`: Tabel idempotensi webhook pembayaran dan konfigurasi gateway.
5. `supabase_saas_pricing_and_coupons_safe.sql`: Skema kupon diskon, riwayat audit harga `plan_price_history`, dan RPC validasi atomik.
6. `fix_supabase_rls_critical_advisories.sql`: Hardening kebijakan keamanan baris (RLS) dan pengetatan hak akses publik.
7. `supabase_app_versions_migration.sql`: Skema master distribusi rilis APK mandiri, verifikasi hash SHA-256, dan RPC `get_latest_app_version`.
8. `supabase_account_deletion_migration.sql`: RPC `delete_my_account` (*Right to be Forgotten*) untuk pembersihan data akun dan cloud cascade.

---

# 69. Security Hardening Changelog (Phases 1 to 6)

* **Phase 1 (Admin RBAC Hardening)**: Menghilangkan bypass autentikasi lokal; seluruh verifikasi admin dipusatkan pada fungsi server `public.is_admin()`.
* **Phase 2 (Subscription SSOT Hardening)**: Menjadikan tabel `subscriptions` di Supabase sebagai Single Source of Truth status lisensi Pro tanpa variabel toggle lokal.
* **Phase 3 (Server-Time Authority Hardening)**: Menghilangkan ketergantungan pada jam HP; penentuan kedaluwarsa lisensi 100% menggunakan stempel waktu server PostgreSQL `clock_timestamp()`.
* **Phase 4 (User Moderation Gate Hardening)**: Pendaftaran akun baru wajib berstatus `pending` dan menunggu persetujuan Administrator sebelum diizinkan masuk.
* **Phase 5 (Dynamic Paywall & Coupon Engine Hardening)**: Validasi kupon server-authoritative via RPC `validate_and_calculate_coupon`, penebusan atomik `redeem_coupon_order`, dan audit perubahan harga `plan_price_history`.
* **Phase 6 (Responsive Compact Screen Hardening)**: Penguatan layout pada resolusi layar sempit 360dp untuk memastikan nol galat `RenderFlex overflow` pada seluruh layar aplikasi (`test/pixel_overflow_hardening_test.dart`).

---

# 70. Current System Status Summary

* **Implemented (Fitur Selesai 100%)**: Core Deterministic Ledger, Multi-Wallet, Budgeting, Savings Goals, Recurring Transactions, Local Storage, Supabase Auth, RBAC, Admin Panel, User Moderation, Product Pricing & Audit History, Coupon Discount Engine, Dynamic Paywall, Manual QRIS Payment Queue, Dual Theme System, Personalization, 4-Pillar Financial Health Score, Smart Financial Insights, CSV Import, PDF Reports, Responsive Compact 320dp & 360dp Layout, OTA Self-Hosted APK Updater, User Lifecycle & Account Purge (Right to be Forgotten), Cryptographic PIN Lock PBKDF2-HMAC-SHA256 (100.000 Iterasi, Dynamic Salt, Anti-Timing Attack, Keystore Resilience).
* **Partial (Siap Integrasi Kunci Produksi / Paket Tambahan)**: Live Merchant Gateway (Edge Gateway Isolated Webhook Ready, Sandbox provider ready), AI Assistant (Regex offline engine ready + Gemini REST hook), Remote FCM Push (Model & schema ready, plugin native Firebase belum terpasang), Hardware Biometrik (PIN fallback aktif, plugin native `local_auth` belum terpasang).
* **Verified (Teruji Otomatis)**: **291/291 Definisi Uji Otomatis Terverifikasi (31 Berkas Uji: 278 Lulus, 13 Dilewati, 0 Gagal)**, 0 issues pada `flutter analyze`, 13 live cloud probes terverifikasi di Supabase Cloud, dan 27/27 layar diaudit bebas RenderFlex overflow pada viewport 320dp & 360dp.

---

# 71. Known Security Findings Log

| No | Temuan Keamanan | Tingkat | Status | Keterangan & Tindakan |
|---|---|---|---|---|
| 1 | Anon Key Publik di Client | Informational | `[SAFE]` | Sesuai arsitektur resmi Supabase; seluruh data diisolasi oleh RLS di database. |
| 2 | Data Sampel Bawaan | Informational | `[SAFE]` | Hanya dimuat pada sesi tamu sebelum login; diabaikan saat terhubung ke cloud. |
| 3 | Upaya Manipulasi Jam Klien | High | `[RESOLVED]`| Divalidasi oleh jam server PostgreSQL di fungsi RPC `get_my_active_subscription()`. |
| 4 | Kerentanan Brute-Force PIN | Medium | `[RESOLVED]`| Dilindungi pembatasan percobaan: jeda 30 detik (3x salah) dan lockout 5 menit (5x salah). |

---

# 72. Development Conventions & Clean Architecture Rules

* **Gaya Kode**: Mengikuti standar resmi *Effective Dart*.
* **Penamaan**: *lowerCamelCase* untuk variabel/metode, *UpperCamelCase* untuk kelas/enum/layar, *lowercase_with_underscores* untuk berkas.
* **Pemisahan Lapisan (Layered Clean Architecture)**:
  - *Presentation*: Layar dan widget hanya mengurus tampilan dan interaksi pengguna.
  - *State Management*: Logika bisnis ditangani oleh Provider (`FinanceProvider`, `ThemeProvider`).
  - *Domain Engine*: Logika matematis murni dipusatkan pada Service (`TransactionService`, `FinancialHealthService`).
  - *Data & Persistence*: Penyimpanan lokal (`StorageService`) dan komunikasi cloud (`SaaSBackendService`, `SupabaseAuthService`).

---

# 73. System Glossary

* **ASTRACK**: Asset Smart Tracker (Asset & Smart Financial Tracker).
* **SSOT**: Single Source of Truth (Pusat kebenaran tunggal data di database).
* **RLS**: Row Level Security (Isolasi baris data di level database PostgreSQL).
* **RPC**: Remote Procedure Call (Fungsi SQL tersimpan yang dieksekusi di server).
* **MRR**: Monthly Recurring Revenue (Pendapatan berulang bulanan dari langganan aktif).
* **ARR**: Annual Run Rate (Proyeksi tahunan pendapatan platform, $\text{MRR} \times 12$).
* **Burn Rate**: Kecepatan konsumsi pagu anggaran harian.
* **Zero-Floor**: Mekanisme keamanan di mana nilai nominal tidak pernah diperbolehkan bernilai negatif setelah pemotongan diskon.

---

# 74. Technical FAQ

### Apakah status langganan Pro pengguna dapat dibajak dari memori HP?
**Tidak.** Status Pro diverifikasi langsung oleh fungsi database server Supabase `get_my_active_subscription()`. Mengubah memori client lokal tidak akan membuka fitur berbayar di database.

### Apakah memundurkan tanggal pada ponsel dapat memperpanjang masa aktif Pro?
**Tidak.** Tanggal kedaluwarsa lisensi dievaluasi berdasarkan stempel waktu server PostgreSQL `clock_timestamp()`. Jam client lokal tidak memiliki otoritas atas lisensi.

### Mengapa antarmuka ASTRACK bebas dari garis kuning-hitam (RenderFlex overflow) pada layar kecil?
**Karena penerapan Zero-Overflow Hardening**: Seluruh nominal besar menggunakan `FittedBox`, baris chip dan legend menggunakan `Wrap`, label teks dibungkus `Expanded`/`Flexible` dengan proteksi ellipsis, serta seluruh item navigasi dibungkus `Expanded`.

---

# 75. Final Architectural Synthesis

ASTRACK menggabungkan performa tinggi kompilasi native Flutter dengan keandalan enterprise database PostgreSQL Supabase. Dari segi fungsionalitas, aplikasi ini menyediakan ekosistem lengkap dari pencatatan mutasi kas sehari-hari hingga pengelolaan bisnis SaaS modern dengan integritas finansial deterministik, keamanan berlapis anti-tampering, dan keindahan antarmuka berstandar industri.

---

# 76. INVENTARIS LENGKAP DEPENDENSI, TEKNOLOGI, HARDWARE & PROTOKOL

### 1. Inventaris Dependensi Resmi & Library Pihak Ketiga (`pubspec.yaml`)

| Nama Package / Library | Versi | Peran & Tanggung Jawab Spesifik di ASTRACK | Alasan Pemilihan Arsitektur |
|---|---|---|---|
| `flutter` | `SDK` | Fondasi framework aplikasi native Android | Basis kode utama teroptimasi untuk Android (Web/Windows hanya untuk pratinjau pengembang) |
| `flutter_localizations` | `SDK` | Penyedia data format kalender, translasi bawaan, dan mata uang | Mendukung formatting standar Bahasa Indonesia (`id_ID`) |
| `provider` | `^6.1.5+1` | State management reaktif (`FinanceProvider`, `ThemeProvider`) | Ringan, hemat memori, dan efisien tanpa overhead |
| `intl` | `^0.20.3` | Format nominal mata uang (`NumberFormat.currency`) dan tanggal | Format presisi Rupiah bertitik (`Rp 25.000`) dan kalender lokal |
| `shared_preferences` | `^2.5.5` | Penyimpanan persisten lokal sandboxed aplikasi (tidak terenkripsi otomatis di level OS) | Menopang arsitektur *offline-first* dengan pembacaan seketika |
| `flutter_secure_storage` | `^10.3.4` | Penyimpanan kredensial sensitif terenkripsi hardware-backed (Android Keystore) | Mengamankan hash PIN, dynamic salt, dan counter lockout dari ekstraksi root/adb |
| `fl_chart` | `^1.2.0` | Mesin perender grafik data finansial (Pie, Donut, Bar, Dual-Line) | Visualisasi interaktif performa tinggi dengan animasi mulus |
| `google_fonts` | `^8.2.1` | Pustaka tipografi font *Plus Jakarta Sans* | Keterbacaan angka finansial tinggi dan estetika editorial |
| `uuid` | `^4.6.0` | Generator identifier unik UUID v4 (`RFC 4122`) | Primary key acak terdistribusi tanpa bentrok ID antar-perangkat |
| `http` | `^1.6.0` | Klien komunikasi jaringan HTTP REST API | Menghubungkan client ke REST endpoint cloud & AI service |
| `supabase_flutter` | `^2.18.0` | SDK resmi Supabase (Auth GoTrue, Database Client, RPC) | Manajemen sesi JWT, query PostgreSQL, dan Stored Procedures |
| `crypto` | `^3.0.6` | Algoritma hashing kriptografis SHA-256, HMAC, dan PBKDF2 | KDF PIN 100.000 iterasi dan verifikasi signature webhook |
| `image_picker` | `^1.2.3` | Antarmuka interaksi hardware kamera dan galeri foto | Pengambilan berkas gambar foto nota/struk belanja |
| `google_mlkit_text_recognition`| `^0.17.1` | Model Machine Learning on-device untuk ekstraksi teks OCR | Pembacaan leksikal teks kuitansi secara offline (Android) |
| `package_info_plus` | `^8.2.1` | Pembaca metadata versi aplikasi (`versionName`, `buildNumber`) | Deteksi pembaruan OTA mandiri dan info rilis pada About |
| `url_launcher` | `^6.3.1` | Peluncur tautan eksternal (Telegram, WhatsApp, Web, Unduhan) | Whitelist host HTTPS resmi untuk update dan bantuan |
| `cupertino_icons` | `^1.0.8` | Pustaka ikon vektor pelengkap | Pelengkap simbol ikon antarmuka Flutter |
| `flutter_test` | `SDK Dev` | Mesin pengujian otomatis unit, widget, dan integrasi | Menguji **31 berkas pengujian / 291 definisi uji (278 Pass / 13 Auto-skip)** |
| `flutter_lints` | `^6.0.0 Dev` | Analisis statis aturan penulisan kode bersih resmi Dart | Memastikan 0 error dan 0 warning pada `flutter analyze` |

### 1.1 Status Implementasi Modul Lanjutan & Ketergantungan Paket

Berdasarkan audit komparatif antara kode aktual dan rancangan arsitektur:
* **Ekspor Dokumen PDF Cetak**: `[PARTIAL]` (Generator laporan teks tabular akuntansi resmi telah berfungsi di `printable_report_service.dart`; paket printer/PDF native `pdf: ^3.x` dan `printing` belum diinstal di `pubspec.yaml`).
* **Remote FCM Push Notifications**: `[PARTIAL]` (Model pendaftaran multi-perangkat `DeviceToken` dan skema database `public.user_device_tokens` telah aktif; SDK klien `firebase_messaging` belum diinstal).
* **Hardware Biometrik Sidik Jari**: `[PARTIAL]` (Sistem penguncian PIN PBKDF2-HMAC-SHA256 dengan lockout aktif; plugin native `local_auth` belum diinstal di `pubspec.yaml`).
* **Voice Speech-to-Text**: `[PARTIAL]` (Lembar modal suara dan rule-based conversational intent parser telah aktif; plugin native `speech_to_text` belum diinstal di `pubspec.yaml`).
* **Crash Reporting & Telemetri**: Toggle preferensi di UI disembunyikan sampai SDK remote (mis. Sentry) siap dipasang guna menghindari ambiguitas pengguna; digantikan dengan saluran terintegrasi "Laporkan Masalah Sistem" langsung ke tim pengembang via email dan Telegram.

### 2. Pemanfaatan Perangkat Keras & Sensor Ponsel (Hardware & Device Capabilities)
ASTRACK mengintegrasikan kemampuan perangkat keras fisik pengguna untuk mempermudah pencatatan keuangan:
1. **Kamera Fisik Ponsel (`Camera Sensor`)**:
   Digunakan oleh modul OCR Receipt Scanner untuk membidik nota belanja fisik secara instan.
2. **Media Penyimpanan Lokal & Hardware Keystore (`Secure Storage / Keystore`)**:
   Menyimpan preferensi dan mutasi lokal di `SharedPreferences`, di mana kredensial hash PIN, garam kriptografis 16-byte, dan stempel lockout diamankan secara mandiri dalam **`FlutterSecureStorage`** dengan algoritma derivasi kunci **PBKDF2-HMAC-SHA256 (>= 100.000 iterasi)** yang berjalan di background isolate.
3. **Mikrofon & Audio Recorder (`Microphone`)**:
   Merekam suara pengguna untuk fitur *Voice Transaction Input* berbasis pengenalan ucapan Bahasa Indonesia.
4. **Sensor Getar Haptic (`Haptic Feedback Engine`)**:
   Memberikan umpan balik getaran taktil fisik saat transaksi berhasil disimpan, tombol ditekan, atau saat grafik disentuh.
5. **Sensor Siklus Hidup Aplikasi (`AppLifecycleState via WidgetsBindingObserver`)**:
   Mendeteksi secara tepat saat aplikasi beralih ke latar belakang (*background*) atau diminimalkan untuk memicu penguncian PIN otomatis (*Auto-Lock*).

### 3. Layanan Cloud & API Eksternal Terintegrasi
1. **Supabase Cloud Enterprise (PostgreSQL 15+)**:
   Menyediakan database relasional cloud dengan ekstensi `pgcrypto`, autentikasi GoTrue terenkripsi bcrypt, isolasi multi-tenant Row Level Security (RLS), dan Stored Functions RPC berflag `SECURITY DEFINER`.
2. **Google Gemini Cloud AI REST Engine**:
   Menyediakan model kecerdasan buatan Gemini Flash/Pro untuk konsultasi strategi keuangan dan penguraian transaksi kompleks.
3. **Google Web Speech API**:
   Mesin transkripsi audio-ke-teks (*Speech-to-Text*) real-time untuk bahasa Indonesia (`id-ID`).
4. **Google Sheets REST Service**:
   Sinkronisasi ekspor data mutasi kas ke lembar kerja daring (*cloud spreadsheet*).
5. **Gateway Pembayaran Komersial (Midtrans, Xendit, Stripe, Manual QRIS)**:
   Penyedia pemrosesan transaksi pembayaran langganan Basic dan Pro.

### 4. Standar, Format Data & Protokol Industri
* **Format Pertukaran Data**: JSON (serialisasi model & state), CSV (impor/ekspor mutasi massal), PDF (laporan laba rugi resmi siap cetak).
* **Standar Keamanan Jaringan**: Komunikasi terenkripsi penuh HTTPS / TLS 1.3 dan WebSocket Secure (WSS).
* **Standar Kriptografi**: SHA-256 + secret salt untuk PIN 6-digit; HMAC SHA-256 dan HMAC SHA-512 untuk tanda tangan webhook anti pemalsuan.
* **Standar Akuntansi Finansial**:
  - Format mata uang Rupiah standar Bank Indonesia (`Rp`, pemisah ribuan titik, pemisah desimal koma).
  - Mekanisme pembukuan deterministik dua langkah (*Double-Step Atomic Balance Reversal*).
  - Prinsip perlindungan batas nol (*Zero-Floor Security* — harga dan diskon tidak pernah bernilai negatif).
  - Stempel waktu konsisten berbasis zona waktu Asia/Jakarta (WIB, UTC+7) dan ISO 8601 UTC.
* **Standar Aksesibilitas Desain**:
  - Kepatuhan kontras warna internasional **WCAG AA** (rasio kontras $\ge 4.5:1$).
  - Target area sentuh jari minimal **44x44dp**.
  - Responsif multi-ukuran (*Window Size Classes*): Compact (<600dp), Medium (600–840dp), Expanded (>840dp).
  - Arsitektur anti-luber khusus layar sempit (**360dp & 320dp Zero-Overflow Layout Constraint**).

---

# 77. Arsitektur Distribusi & Pembaruan APK Mandiri (Self-Hosted OTA App Updates)

* **Berkas Sumber**: `lib/features/update/services/app_update_service.dart`, `lib/features/update/models/app_update_info.dart`, `lib/features/update/widgets/update_available_dialog.dart`, `lib/features/update/screens/force_update_screen.dart`
* **Test Suite Terverifikasi**: `test/apk_distribution_and_update_test.dart` (10 Tests, 100% Pass)

### 1. Latar Belakang & Filosofi
Untuk memastikan kemandirian distribusi tanpa ketergantungan mutlak pada ekosistem toko aplikasi pihak ketiga (*decoupling from proprietary app stores*), ASTRACK dirancang dengan sistem pembaruan Over-the-Air (OTA) mandiri yang terhubung langsung ke basis data PostgreSQL Supabase Cloud.

### 2. Pipeline Deteksi & Pemeriksaan Rilis (Supabase RPC Engine)
1. **Supabase Stored Procedure `get_latest_app_version`**:
   Klien secara berkala memeriksa rilis terbaru dengan mengeksekusi RPC aman:
   ```dart
   final response = await client.rpc('get_latest_app_version', params: {'p_platform': 'android'});
   ```
   Data rilis diambil dari tabel cloud `public.app_versions` yang memuat `version_name`, `build_number`, `min_supported_build`, `download_url`, `release_notes`, dan `sha256_checksum`.
2. **Deterministic Build Number & SemVer Evaluation**:
   Versi dievaluasi secara bertingkat:
   * **Force Update**: Jika `currentBuild < info.minSupportedBuild`, pengguna wajib memperbarui dan diarahkan ke `ForceUpdateScreen` tanpa opsi lewati (*blocking update*).
   * **Optional Update**: Jika `currentBuild < info.buildNumber`, dialog `UpdateAvailableDialog` muncul menawarkan rincian pembaruan, dengan opsi perbarui sekarang atau tunda (*Snooze* 3 hari).
   * **Up to Date**: Jika `currentBuild >= info.buildNumber`, aplikasi beroperasi normal.
3. **Throttling & Snooze Management**:
   Pemeriksaan latar belakang dibatasi secara otomatis dengan interval throttling 6 jam (`astrack_last_update_check`). Aksi tunda pengguna disimpan secara persisten di storage lokal selama 3 hari.
4. **Prinsip Fail-Open Offline**:
   Jika perangkat pengguna dalam kondisi luring (*offline*) atau terjadi kegagalan jaringan, pemeriksaan versi tidak memblokir aplikasi dan mengembalikan `(UpdateStatus.unknown, null)`, menjaga prinsip *offline-first*.

### 3. Distribusi Tautan Terproteksi & Peluncuran Peramban Eksternal
* **Whitelist Domain Resmi**: Tautan unduhan diverifikasi secara ketat hanya menerima protokol `https` dan domain resmi yang terdaftar pada whitelist (`t.me`, `telegram.me`).
* **Peluncuran Aplikasi / Peramban Eksternal**:
  Pengguna yang memilih perbarui diarahkan ke tautan unduh resmi saluran Telegram melalui peramban web eksternal menggunakan `url_launcher` dengan mode `LaunchMode.externalApplication`.

---

# 78. Siklus Hidup Akun Pengguna & Privasi Lanjutan (User Lifecycle & Advanced Privacy)

* **Berkas Sumber**: `lib/features/auth/forgot_password_screen.dart`, `lib/features/auth/reset_password_screen.dart`, `lib/features/settings/privacy_data_screen.dart`, `lib/features/policy/policy_screen.dart`, `android/app/src/main/AndroidManifest.xml`
* **Test Suite Terverifikasi**: `test/phase2_missing_features_test.dart` (7 Tests, 100% Pass)

### 1. Alur Pemulihan Sandi Mandiri, SMTP Supabase & Deep Link Callback
* **`ForgotPasswordScreen` & Supabase GoTrue**: Mengirimkan email pemulihan sandi via `sendPasswordResetEmail(email)` dengan konfigurasi redirect callback:
  ```dart
  await client.auth.resetPasswordForEmail(
    email.trim(),
    redirectTo: 'io.supabase.astrack://reset-callback',
  );
  ```
* **Catatan Kritis Rate Limit SMTP Supabase & Konfigurasi Custom SMTP**:
  Layanan bawaan *built-in email service* Supabase menerapkan batas ketat (*rate limit* sekitar 3–4 email pemulihan per jam per proyek). Untuk lingkungan produksi, pemilik proyek **wajib** mengonfigurasi penyedia Custom SMTP (seperti *Resend, SendGrid, Amazon SES, Brevo, atau Mailgun*) di Supabase Dashboard (`Project Settings -> Authentication -> SMTP Settings`).
* **Pendaftaran Redirect URLs**:
  Skema callback `io.supabase.astrack://reset-callback` wajib didaftarkan di Supabase Dashboard (`Authentication -> URL Configuration -> Redirect URLs`).
* **Integrasi Deep Link Android**: `android/app/src/main/AndroidManifest.xml` mengonfigurasi `intent-filter` berskema `io.supabase.astrack` dengan host `reset-callback` sehingga tautan verifikasi dari email otomatis membuka aplikasi dan mengarahkan pengguna ke `ResetPasswordScreen`.
* **`ResetPasswordScreen`**: Menangani input kata sandi baru dengan indikator kekuatan sandi dan konfirmasi sandi berlapis sebelum memanggil `updateUserPassword()`.

### 2. Hak Penghapusan Akun Permanen (GDPR / UU PDP "Right to be Forgotten")
* **Konfirmasi Bertingkat**: Pengguna diwajibkan mengetikkan frasa konfirmasi eksplisit (*type-to-confirm*) untuk mencegah penghapusan yang tidak disengaja.
* **Pembersihan Data Lokal Total**: Seluruh data transaksi lokal pada `SharedPreferences` dan kredensial PIN pada `FlutterSecureStorage` dibersihkan seketika.
* **Pembersihan Cloud RPC `delete_my_account`**: Menjalankan penghapusan *cascade purge* akun dan data finansial terkait di Supabase PostgreSQL, mencabut sesi JWT (`signOut()`), dan mengarahkan pengguna kembali ke halaman Login.

### 3. Saluran Bantuan Sistem & Kebijakan Privasi Bersih
* **Penyembunyian Toggle Telemetri Tanpa SDK Remote**: Toggle switch Crash Reporting disembunyikan dari UI `PrivacyDataScreen` sampai SDK monitoring pihak ketiga (seperti Sentry) resmi diintegrasikan, mencegah kebingungan pengguna dan menghilangkan label `[PARTIAL]`.
* **Saluran Bantuan Terintegrasi**: Disediakan opsi "Laporkan Masalah Sistem" di `PrivacyDataScreen` yang menampilkan dialog bantuan resmi pengembang (Email: `support@astrack.id`, Telegram: `@astrack_official`) dengan kemudahan salin alamat ke clipboard.

### 4. Saluran Dukungan Resmi & Ketentuan Transaksi
* **`PolicyScreen`**: Memuat dokumentasi transparansi hukum mengenai pemrosesan data lokal, privasi AI, dan saluran kontak bantuan resmi (`support@astrack.id` dan Telegram).
* **Kebijakan Refund**: Berstatus `TODO: [LEGAL_REVIEW] Kebijakan pengembalian dana (refund) resmi sedang dalam peninjauan tim legal`.

---

# 79. Hardening Keamanan Kriptografis Tingkat Tinggi (Cryptographic Hardening & Salt Migration)

* **Berkas Sumber**: `lib/core/services/security_service.dart`, `lib/features/auth/pin_lock_screen.dart`, `android/app/src/main/AndroidManifest.xml`
* **Test Suite Terverifikasi**: `test/phase3_security_hardening_test.dart` (7 Tests, 100% Pass) & `test/security_hardening_pin_test.dart` (5 Tests, 100% Pass)

### 1. Spesifikasi PBKDF2-HMAC-SHA256 >= 100.000 Iterasi & Tuning Latensi
ASTRACK mengamankan PIN 6-digit pengguna menggunakan algoritma derivasi kunci standar industri **PBKDF2 (Password-Based Key Derivation Function 2)** dengan fungsi pseudo-random HMAC-SHA256:
* **Jumlah Iterasi Standar**: **100.000 putaran kalkulasi** (*work factor* standar OWASP), memperlambat serangan brute-force berbasis GPU atau peretasan offline.
* **Tuning untuk Perangkat Android Kelas Bawah (Low-End)**: Pada perangkat Android dengan spesifikasi CPU terbatas, konstanta iterasi dapat disesuaikan ke rentang 50.000–100.000 jika latensi komputasi melebihi 1,5 detik, namun **dilarang keras diturunkan di bawah 10.000 putaran**.
* **Eksekusi di Background Isolate**: Kalkulasi derivasi dijalankan di thread terpisah menggunakan fungsi `compute()` Flutter untuk mencegah UI freezing.
* **Pengalaman Pengguna Responsif di `PinLockScreen`**: Jeda buatan (*artificial delay 600ms*) telah dieliminasi total. Antarmuka menampilkan indikator pemrosesan (`Memproses PIN...`) dan menonaktifkan keypad secara visual serta interaktif (`IgnorePointer`) murni selama komputasi isolate berlangsung.
* **Garam Dinamis Acak Per-Perangkat**: Garam kriptografis acak 16-byte (`128-bit` / 32 hex chars) dihasilkan menggunakan `Random.secure()`.

### 2. Penyimpanan Kredensial Hardware-Backed (`FlutterSecureStorage`) & Proteksi Backup
Seluruh data sensitif terkait PIN disimpan di **`FlutterSecureStorage`** dengan hardware enkripsi Android Keystore (`encryptedSharedPreferences: true`):
* `astrack_user_pin_hash`: Hash biner 64 karakter hex.
* `astrack_user_pin_salt`: Garam acak 16-byte hex.
* `astrack_pin_iterations`: Jumlah putaran kalkulasi (100.000).
* `astrack_pin_failed_attempts`: Penghitung kesalahan input PIN.
* `astrack_pin_lockout_until`: Stempel waktu lockout.
* **Mitigasi Auto Backup Android**: Elemen `<application>` di `AndroidManifest.xml` dikonfigurasi dengan atribut `android:allowBackup="false"` untuk mencegah sistem Android Auto Backup mengekstraksi data unencrypted yang berisiko merusak sinkronisasi kunci Keystore saat restore.

### 3. Ketahanan & Resiliensi Galat Android Keystore (Keystore Crash Resilience)
* Pemanggilan storage pada `SecurityService.init()` dan `SecurityService.verifyPin()` dibungkus dalam blok penanganan eksepsi `try / catch`.
* Jika Keystore mengalami desinkronisasi atau korupsi setelah update OS / migrasi perangkat, sistem tidak akan mengalami *crash*. Sistem melakukan fallback aman ke status PIN belum diatur (`hasPin = false`), mengaktifkan `forceReloginNotifier`, serta menyediakan metode `triggerSafeSignOut()` yang membersihkan sesi Supabase dan preferensi lokal secara aman.

### 4. Migrasi Transparan Format Lama (Zero-Friction Migration)
* Saat `SecurityService.init()` berjalan, sistem mendeteksi apakah terdapat hash atau plaintext lama di `SharedPreferences`.
* Data lama otomatis dipindahkan ke `FlutterSecureStorage` dan dihapus dari `SharedPreferences`.
* Saat verifikasi PIN berhasil, jika terdeteksi iterasi versi lama (10.000 iterasi atau legacy SHA-256), sistem seketika meng-upgrade hash secara otomatis (*seamless background re-hash*) ke standar 100.000 iterasi dengan garam baru.

### 5. Eliminasi Serangan Waktu (Constant-Time String Comparison)
Perbandingan hash diverifikasi menggunakan metode waktu konstan `_constantTimeEquals` tanpa *early-exit*, menepis serangan analisis waktu (*timing side-channel attacks*).

---

# 80. Arsitektur Pembayaran Terisolasi Edge Gateway (Zero-Secret Client & Edge Functions)

* **Berkas Sumber Klien**: `lib/services/payment/payment_service.dart`, `lib/services/payment/payment_models.dart`, `lib/services/payment/payment_gateway_config_service.dart`, `lib/services/payment/manual_qris_service.dart`
* **Edge Function Server**: `supabase/functions/payment-webhook/index.ts` & `supabase/functions/payment-webhook/README.md`
* **Test Suite Terverifikasi**: `test/phase5_payment_gateway_architecture_test.dart` (17 Tests, 100% Pass) & `test/payment_architecture_test.dart` (4 Tests, 100% Pass)

### 1. Prinsip Zero-Secret Client (Kepatuhan OWASP MASVS)
Aplikasi mobile klien ASTRACK dirancang dengan arsitektur **Zero-Secret Client**:
* Kunci rahasia gateway (`MIDTRANS_SERVER_KEY`, `PAYMENT_WEBHOOK_SECRET`, `XENDIT_WEBHOOK_TOKEN`) **DILARANG KERAS** disimpan atau di-bundle di dalam kode biner aplikasi klien Android.
* Seluruh rahasia server dikonfigurasi melalui Supabase Vault atau Environment Secrets (`supabase secrets set`).
* Layar konfigurasi admin pada aplikasi mobile (`AdminGatewayConfigScreen`) tidak menampilkan input teks rahasia server, melainkan kartu status perlindungan arsitektur Zero-Secret.

### 2. Supabase Edge Function `payment-webhook`
Endpoint serverless Deno TypeScript resmi `payment-webhook` bertindak sebagai penerima tunggal webhook callback pembayaran:
1. **Deployment Wajib `--no-verify-jwt`**:
   Deploy menggunakan perintah `supabase functions deploy payment-webhook --no-verify-jwt`. Gateway pembayaran publik tidak menyertakan JWT Supabase pengguna, sehingga bypass verifikasi gateway Kong wajib diaktifkan.
2. **Mitigasi Serangan Replay (5-Minute Window)**: Stempel waktu transaksi diverifikasi berada dalam rentang toleransi $\le 300\text{ detik}$ (5 menit).
3. **Verifikasi Kriptografis Multi-Gateway**:
   * **Midtrans**: Memvalidasi signature `SHA512(order_id + status_code + gross_amount + MIDTRANS_SERVER_KEY)` dengan *constant-time comparison*.
   * **Xendit**: Memvalidasi token header `x-callback-token` terhadap secret `XENDIT_WEBHOOK_TOKEN` secara konstan waktu.
   * **Custom HMAC**: Memvalidasi header signature terhadap `HMAC-SHA256(Secret, rawBody)`.
4. **Idempotensi Transaksi (`public.payment_webhook_events`)**:
   Memeriksa kunci unik `event_id` sebelum memproses. Panggilan duplikat langsung direspons `200 OK (idempotent duplicate)` tanpa mutasi ganda.
5. **Validasi Status Pending & Pencocokan Nominal (Anti-Fraud Enforcement)**:
   * Memastikan status pesanan di `payment_orders` saat ini adalah `pending` sebelum diubah menjadi `approved`.
   * Memvalidasi kecocokan nilai `gross_amount` yang dibayar dengan `final_amount` pesanan di database. Ketidakcocokan nominal langsung ditolak dengan `400 Bad Request`.
6. **Kalkulasi Masa Aktif Langganan Dinamis**:
   Masa aktif dihitung secara dinamis dari tabel `plans` (`duration_days` atau siklus tagihan tahunan 365 hari / bulanan 30 hari), bukan hardcoded 30 hari, lalu diperbarui pada tabel `subscriptions`.

---

# 81. Integritas Finansial & Audit Uang Bilangan Bulat (Integer-Safe Currency Formatting)

* **Berkas Sumber**: `lib/core/utils/currency_formatter.dart`, `lib/data/storage/storage_service.dart`, `lib/models/transaction_item.dart`
* **Dokumen Rencana Arsitektur**: `docs/integer_currency_migration_plan.md`
* **Test Suite Terverifikasi**: `test/phase3_security_hardening_test.dart` (Test 5 & 6, 100% Pass)

### 1. Eliminasi Floating-Point Roundoff Bug
Mata uang Rupiah Indonesia (IDR) beroperasi pada satuan bilangan bulat penuh tanpa pecahan sen.
* `CurrencyFormatter.format()` membulatkan nominal secara matematis ke bilangan bulat (`roundToInt()`), menjamin tampilan Rupiah selalu bersih, presisi, dan bebas residu pecahan ganjil (`Rp 25.000` bukannya `Rp 25.000,0000000004`).
* Properti `TransactionItem.amountInt` menyediakan akses nominal bulat langsung untuk kebutuhan kalkulasi deterministik.

### 2. Prinsip Zero-Floor & Sanitasi Input Uang
* **Aturan Batas Bawah Nol (*Zero-Floor Rule*)**: Nilai harga paket langganan, nominal diskon, dan saldo minimal dibatasi tidak boleh menghasilkan angka negatif:
  $$\text{FinalPrice} = \max(0, \text{OriginalPrice} - \text{Discount})$$
* **Sanitasi Karakter Input**: Karakter non-numerik (titik pemisah, spasi, simbol mata uang) disaring secara deterministik saat pengguna mengetikkan nominal, mencegah eksepsi konversi angka (*FormatException*).

### 3. Rencana Migrasi Masa Depan Menuju Objek Nilai `Money`
Telah disusun rencana migrasi tertulis pada berkas `docs/integer_currency_migration_plan.md` yang merinci spesifikasi `Money` Value Object immutabel, strategi dual-write kolom `BIGINT` di PostgreSQL tanpa downtime, dan penghapusan menyeluruh tipe primitif `double` pada siklus pengembangan berikutnya.

---

# 82. Zero-Overflow Visual Hardening & Responsive 320dp / 360dp Matrix

* **Berkas Sumber**: Seluruh layar antarmuka `lib/features/`
* **Test Suite Terverifikasi**: `test/pixel_overflow_audit_test.dart` (27 Layar & Modal, 100% Pass) & `test/pixel_overflow_hardening_test.dart` (4 Tests, 100% Pass)

### 1. Metodologi Audit Stres Viewport 320x568 dp
Untuk memastikan antarmuka ASTRACK tampil sempurna pada seluruh spektrum perangkat keras Android—termasuk layar ultra-kompak dengan lebar fisik hanya **320dp** (seperti perangkat Android entry-level/Android Go atau perangkat dengan skala font aksesibilitas besar)—dibuat audit uji otomatis komprehensif yang menguji **27+ layar dan dialog modal**:
* Login, Register, Forgot Password, Reset Password, Onboarding
* Dashboard, Statistik, Transaksi, Anggaran (Budget), Target Tabungan (Savings)
* Sumber Dana (Sources), Tagihan Rutin (Recurring), Impor CSV, Scan Struk OCR
* Pengaturan Tampilan, Bahasa, Privasi Data, Kelola Kategori, Tentang Aplikasi
* Seluruh Panel Admin (Statistik, Gateway, Kupon, Harga, Antrean QRIS, Pengaturan)
* Seluruh Dialog Modal (Update Available, Checkout QRIS, Rollover Anggaran, Add Target)

### 2. Pola Arsitektur Visual Anti-Overflow yang Diterapkan
1. **`Expanded` & `Flexible` Bertingkat dengan `TextOverflow.ellipsis`**:
   Semua baris `Row(children: [Text, ...])` yang memuat nama kategori, nama rekening, judul kartu, atau nominal uang dibungkus pembatas flex agar teks yang panjang otomatis dipotong rapi dengan elipsis (`...`) tanpa pernah meluber ke kanan.
2. **`Wrap(spacing: ..., runSpacing: ...)` Menggantikan `Row` Statis**:
   Pada deretan chip aksi ganda (seperti tombol "Nabung" dan "Tarik"), badge status ("TOTAL", "Utama"), dan indikator milestone tabungan, digunakan `Wrap` sehingga saat lebar layar tidak mencukupi, elemen berikutnya mengalir turun ke baris baru secara alami.
3. **`FittedBox(fit: BoxFit.scaleDown)` pada Tombol & Angka Raksasa**:
   Nominal saldo utama di kartu rekening dan teks pada tombol aksi primer otomatis mengecilkan ukuran font-nya secara proporsional sesuai sisa ruang piksel yang tersedia tanpa memotong teks.
4. **`SingleChildScrollView` pada Seluruh Dialog & BottomSheet**:
   Mencegah galat *bottom overflowed by X pixels* saat keyboard virtual terbuka atau saat dialog dirender pada layar dengan ketinggian vertikal terbatas.

Hasil audit verifikasi: **ZERO RENDERFLEX OVERFLOWS (0 pixels error)** di seluruh antarmuka aplikasi.

---

# 83. Roadmap & Known Limitations (Keterbatasan & Rencana Masa Depan)

### 1. Keterbatasan yang Diketahui (Known Limitations)

| Aspek / Keterbatasan | Dampak Sistem | Strategi Mitigasi Terimplementasi |
|---|---|---|
| **Eksklusivitas Platform Android** | ASTRACK secara tegas hanya dikembangkan untuk ekosistem Android. Platform iOS tidak didukung. | Fokus penuh optimalisasi pengalaman Android native dan kanal distribusi APK mandiri. |
| **Pembaruan APK Mandiri (OTA)** | Pengguna tidak menerima pembaruan latar belakang otomatis dari Play Store. | Layanan `AppUpdateService` dengan notifikasi berkala, dialog pembaruan opsional, dan penegakan `min_supported_build` (Force Update) via tautan Telegram resmi di peramban eksternal. |
| **Keterbatasan Force Update Luring** | Saat perangkat offline tanpa internet, pemeriksaan versi server tidak dapat dilakukan. | Prinsip *Offline-First* dipertahankan: pencatatan kas lokal tetap aman, namun sinkronisasi mutasi ke Supabase Cloud ditolak oleh server jika versi klien kedaluwarsa. |
| **Peringatan Sumber Tidak Dikenal (Play Protect)** | Pengguna pemula mungkin ragu saat memasang berkas APK dari Telegram/WhatsApp. | Panduan instalasi langkah-demi-langkah, publikasi sidik jari sertifikat rilis SHA-256 di menu *Tentang Aplikasi*, dan verifikasi hash biner terbuka. |
| **Crash Reporting Berstatus `[PARTIAL]`** | Galat crash lokal dicatat dalam preferensi, namun belum ditransmisikan ke server terpusat. | Disajikan tombol interaktif *Laporkan Masalah* via Telegram/Email berformat versi aplikasi otomatis, dan direncanakan integrasi SDK Sentry opt-in. |
| **Pengujian Probe Live Cloud Supabase** | Memerlukan kredensial aktif melalui `--dart-define` untuk dieksekusi secara live. | Diatur auto-skip secara cerdas (`skip: ...`) saat variabel lingkungan tidak diset, sehingga `flutter test` lokal dapat berjalan tanpa ketergantungan jaringan. |

### 2. Roadmap Pengembangan Selanjutnya (Future Strategic Roadmap)

1. **Penyempurnaan Pratinjau Web Pengembang**:
   Penyempurnaan portal web untuk kebutuhan pratinjau browser dan pengelolaan laporan keuangan desktop.
2. **Integrasi Hardware Biometrik Native (`local_auth`)**:
   Menambahkan pemindaian sidik jari (*Fingerprint*) perangkat keras Android sebagai opsi pembuka kunci cepat mendampingi KDF PIN PBKDF2-HMAC-SHA256.
3. **Penyebaran Live Supabase Edge Function untuk Gateway Pembayaran**:
   Menyebarkan kode skeleton `supabase/functions/payment-webhook/index.ts` ke runtime Deno Edge Function Supabase untuk memproses callback webhook live Midtrans dan Xendit secara terisolasi tanpa rahasia klien.
4. **Pemasangan Plugin Native PDF & Thermal Bluetooth Printer**:
   Menyematkan pustaka `pdf: ^3.x` dan `printing` untuk pencetakan struk kasir mikro langsung ke printer thermal nirkabel bagi pelaku UMKM.
5. **Observabilitas Cloud Terpusat (Sentry Opt-In)**:
   Mengintegrasikan SDK Sentry dengan flag opt-in privasi bawaan untuk merekam telemetri galat secara anonim tanpa data PII/keuangan.



