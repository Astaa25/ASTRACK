# Supabase Edge Function: `payment-webhook`

## 1. Ikhtisar Arsitektur Zero-Secret Client (OWASP MASVS)
Fungsi Edge ini merupakan titik masuk tunggal (*Single Source of Truth*) yang memproses seluruh callback dan webhook pembayaran dari gateway komersial (Midtrans, Xendit, dsb.) secara terisolasi di sisi server (Deno runtime).

Kode biner aplikasi klien Android **DILARANG KERAS** memuat atau menyimpan kunci rahasia server (`MIDTRANS_SERVER_KEY`, `XENDIT_SECRET_KEY`, atau webhook secrets).

## 2. Manajemen Rahasia (Secrets via Supabase Vault / Environment)

Semua kunci rahasia gateway diisolasi di lingkungan server aman dan tidak pernah di-bundle ke dalam build Flutter:

### Cara Mengatur Rahasia via Supabase CLI
```bash
# Set environment secrets untuk Edge Functions
supabase secrets set \
  MIDTRANS_SERVER_KEY="SB-Mid-server-XXXXX" \
  PAYMENT_WEBHOOK_SECRET="whsec_astrack_live_secret_XXXXX" \
  XENDIT_WEBHOOK_TOKEN="xendit_callback_token_XXXXX" \
  ENVIRONMENT="production"
```

### Deployment Wajib Menggunakan Flag `--no-verify-jwt`
Gateway pembayaran pihak ketiga (Midtrans, Xendit) mengirimkan webhook callback langsung dari server publik mereka dan tidak menyertakan Supabase JWT bearer token dalam header `Authorization`. Oleh karena itu, deployment Edge Function **WAJIB** menggunakan flag `--no-verify-jwt`:
```bash
supabase functions deploy payment-webhook --no-verify-jwt
```
> **Catatan Keamanan**: Walaupun verifikasi JWT dinonaktifkan di layer ingress gateway Kong, keamanan tetap terjamin 100% karena Edge Function secara internal memvalidasi integritas pesan melalui tanda tangan kriptografis (`SHA-512` Midtrans, `x-callback-token` Xendit, dan `HMAC-SHA256` timing-safe comparison).

### Konfigurasi via Supabase Vault (PostgreSQL pgcrypto)
Kunci rahasia juga dapat disimpan di dalam tabel `vault.decrypted_secrets` menggunakan ekstensi resmi Supabase Vault:
```sql
SELECT vault.create_secret('SB-Mid-server-XXXXX', 'midtrans_server_key', 'Midtrans Merchant Server Secret');
SELECT vault.create_secret('whsec_astrack_live_secret_XXXXX', 'payment_webhook_secret', 'HMAC Webhook Ingress Key');
SELECT vault.create_secret('xendit_callback_token_XXXXX', 'xendit_webhook_token', 'Xendit Callback Ingress Token');
```

## 3. Fitur Keamanan & Validasi Bisnis yang Ditegakkan
1. **Mitigasi Serangan Replay (5-Minute Tolerance Window)**:
   - Stempel waktu transaksi (`transaction_time`, `settlement_time`, atau header `x-webhook-timestamp`) wajib berada dalam rentang toleransi $\le 300\text{ detik}$ (5 menit) dari waktu server.
   - Panggilan webhook di luar batas waktu langsung ditolak dengan kode `400 Bad Request`.
2. **Verifikasi Kriptografis Multi-Gateway (Anti-Tampering)**:
   - **Midtrans**: Menghitung `SHA512(order_id + status_code + gross_amount + MIDTRANS_SERVER_KEY)` dan memvalidasi kecocokan dengan `signature_key` menggunakan *constant-time comparison* (`timingSafeEqual`).
   - **Xendit**: Memvalidasi token header `x-callback-token` terhadap `XENDIT_WEBHOOK_TOKEN` secara konstan waktu (`timingSafeEqual`).
   - **Generic HMAC**: Memvalidasi header `x-callback-signature` terhadap `HMAC-SHA256(PAYMENT_WEBHOOK_SECRET, raw_body)`.
3. **Idempotensi Transaksi (`public.payment_webhook_events`)**:
   - Setiap payload diperiksa terhadap kunci unik `event_id`.
   - Jika event sudah pernah diproses, fungsi mengembalikan `200 OK (idempotent duplicate)` secara langsung tanpa melakukan mutasi ganda pada saldo atau masa aktif langganan.
4. **Validasi Status & Nominal Pesanan (Zero-Fraud Protection)**:
   - Memeriksa status pesanan pada `payment_orders`. Hanya pesanan berstatus `pending` yang dapat ditransisikan ke `approved`.
   - Mencocokkan nominal `gross_amount` yang dibayar terhadap `final_amount` pesanan di database dengan toleransi desimal aman. Jika nominal tidak cocok, mutasi ditolak dengan `400 Bad Request`.
5. **Aktivasi Masa Aktif Langganan Dinamis**:
   - Durasi paket dihitung secara dinamis dari tabel `plans` (`duration_days` atau siklus tagihan tahunan 365 hari / bulanan 30 hari), bukan hardcoded.
   - Memperbarui tabel `subscriptions` dengan tanggal kedaluwarsa baru yang tepat.
