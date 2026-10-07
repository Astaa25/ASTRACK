# Supabase Edge Function: `payment-webhook`

## 1. Ikhtisar Arsitektur Zero-Secret Client (OWASP MASVS)
Fungsi Edge ini merupakan titik masuk tunggal (*Single Source of Truth*) yang memproses seluruh callback dan webhook pembayaran dari gateway komersial (Midtrans, Xendit, dsb.) secara terisolasi di sisi server (Deno runtime).

Kode biner aplikasi mobile klien (Android/iOS) **DILARANG KERAS** memuat atau menyimpan kunci rahasia server (`MIDTRANS_SERVER_KEY`, `XENDIT_SECRET_KEY`, atau webhook secrets).

## 2. Manajemen Rahasia (Secrets via Supabase Vault / Environment)

Semua kunci rahasia gateway diisolasi di lingkungan server aman dan tidak pernah di-bundle ke dalam build Flutter:

### Cara Mengatur Rahasia via Supabase CLI
```bash
# Set environment secrets untuk Edge Functions
supabase secrets set \
  MIDTRANS_SERVER_KEY="SB-Mid-server-XXXXX" \
  PAYMENT_WEBHOOK_SECRET="whsec_astrack_live_secret_XXXXX" \
  ENVIRONMENT="production"
```

### Konfigurasi via Supabase Vault (PostgreSQL pgcrypto)
Kunci rahasia juga dapat disimpan di dalam tabel `vault.decrypted_secrets` menggunakan ekstensi resmi Supabase Vault:
```sql
SELECT vault.create_secret('SB-Mid-server-XXXXX', 'midtrans_server_key', 'Midtrans Merchant Server Secret');
SELECT vault.create_secret('whsec_astrack_live_secret_XXXXX', 'payment_webhook_secret', 'HMAC Webhook Ingress Key');
```

## 3. Fitur Keamanan yang Ditegakkan
1. **Mitigasi Serangan Replay (5-Minute Tolerance Window)**:
   - Stempel waktu transaksi (`transaction_time`, `settlement_time`, atau header `x-webhook-timestamp`) wajib berada dalam rentang toleransi $\le 300\text{ detik}$ (5 menit) dari waktu server.
   - Panggilan webhook di luar batas waktu langsung ditolak dengan kode `400 Bad Request`.
2. **Verifikasi Kriptografis Multi-Gateway (Anti-Tampering)**:
   - **Midtrans**: Menghitung `SHA512(order_id + status_code + gross_amount + MIDTRANS_SERVER_KEY)` dan memvalidasi kecocokan dengan `signature_key` menggunakan *constant-time comparison* (`timingSafeEqual`).
   - **Xendit / Generic HMAC**: Memvalidasi header `x-callback-signature` terhadap `HMAC-SHA256(PAYMENT_WEBHOOK_SECRET, raw_body)`.
3. **Idempotensi Transaksi (`public.payment_webhook_events`)**:
   - Setiap payload diperiksa terhadap kunci unik `event_id`.
   - Jika event sudah pernah diproses, fungsi mengembalikan `200 OK (idempotent duplicate)` secara langsung tanpa melakukan mutasi ganda pada saldo atau masa aktif langganan.
4. **Aktivasi Langganan Otomatis**:
   - Jika status transaksi adalah `settlement` atau `capture` (dan `fraud_status: accept`), pesanan pada `payment_orders` diperbarui menjadi `approved` dan masa aktif paket pada `subscriptions` otomatis diperbarui 30 hari ke depan.
