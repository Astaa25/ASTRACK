# Rencana Migrasi Arsitektur Finansial: Mata Uang Bilangan Bulat (Integer-Safe Currency Migration Plan)

> **Dokumen Perencanaan Arsitektur Resmi (Phase 3 Deferred Architecture Plan)**  
> **Status**: *Direncanakan (Planning Only — Belum Dieksekusi)*  
> **Target**: ASTRACK Core Financial Ledger & Supabase Cloud PostgreSQL  

---

## 1. Latar Belakang & Analisis Masalah

### 1.1 Keterbatasan Representasi Floating-Point IEEE-754
Saat ini, beberapa model data ASTRACK (`TransactionItem`, `FundSource`, `Budget`, `SavingsGoal`, `PaymentOrder`) menggunakan tipe bilangan pecahan presisi ganda `double`.  
Representasi biner IEEE-754 pada arsitektur komputer modern memiliki kelemahan matematis mendasar:
* Pecahan desimal tertentu tidak dapat direpresentasikan secara eksak dalam biner, contohnya:
  $$\text{0.1} + \text{0.2} = \text{0.30000000000000004}$$
* Pada operasi kalkulasi mutasi buku besar ribuan transaksi, galat pembulatan halus (*cumulative roundoff drift*) dapat berakumulasi dan menyebabkan selisih beberapa Rupiah antara saldo dompet fisik dan total mutasi transaksi.

### 1.2 Karakteristik Mata Uang Rupiah (IDR)
* Dalam sistem moneter Indonesia, mata uang Rupiah secara riil tidak lagi menggunakan pecahan sen dalam transaksi tunai dan perbankan konsumen harian.
* Seluruh nominal adalah bilangan bulat utuh non-negatif.
* Mengubah representasi nominal internal menjadi bilangan bulat 64-bit (`int` / `BigInt` / PostgreSQL `BIGINT`) menjamin keakuratan matematis 100% tanpa residu desimal.

---

## 2. Desain Objek Nilai Baru (`Money` Value Object)

Sebagai pengganti penggunaan tipe primitif `double` atau `int` mentah, dirancang sebuah objek nilai (*Value Object*) immutabel:

```dart
import 'package:flutter/foundation.dart';

@immutable
class Money implements Comparable<Money> {
  /// Nominal dalam unit terkecil (Rupiah utuh untuk IDR)
  final int amount;
  final String currency;

  const Money(this.amount, {this.currency = 'IDR'});

  const Money.zero([String currency = 'IDR']) : this(0, currency: currency);

  factory Money.fromRupiah(num value) => Money(value.round());

  // Operasi Aritmatika Deterministik
  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(amount - other.amount, currency: currency);
  }

  Money operator *(num multiplier) => Money((amount * multiplier).round(), currency: currency);

  Money operator /(num divisor) => Money((amount / divisor).round(), currency: currency);

  bool operator <(Money other) => amount < other.amount;
  bool operator <=(Money other) => amount <= other.amount;
  bool operator >(Money other) => amount > other.amount;
  bool operator >=(Money other) => amount >= other.amount;

  @override
  int compareTo(Money other) => amount.compareTo(other.amount);

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Mata uang tidak cocok: $currency vs ${other.currency}');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && runtimeType == other.runtimeType && amount == other.amount && currency == other.currency;

  @override
  int get hashCode => amount.hashCode ^ currency.hashCode;

  @override
  String toString() => '$currency $amount';
}
```

---

## 3. Rencana Migrasi Skema Basis Data (PostgreSQL Cloud)

### 3.1 Inventaris Tabel yang Terkena Dampak
1. `public.transactions` (`amount` $\rightarrow$ `BIGINT`)
2. `public.fund_sources` (`balance` $\rightarrow$ `BIGINT`)
3. `public.budgets` (`amount_limit` $\rightarrow$ `BIGINT`)
4. `public.savings_goals` (`target_amount`, `current_amount` $\rightarrow$ `BIGINT`)
5. `public.plans` (`monthly_price`, `yearly_price` $\rightarrow$ `BIGINT`)
6. `public.plan_price_history` (`old_monthly_price`, `new_monthly_price` $\rightarrow$ `BIGINT`)
7. `public.coupons` (`discount_value`, `minimum_purchase` $\rightarrow$ `BIGINT`)
8. `public.payment_orders` (`amount`, `discount_amount`, `final_amount` $\rightarrow$ `BIGINT`)

### 3.2 Strategi Migrasi Tanpa Downtime (*Zero-Downtime Dual-Write*)
Migrasi basis data dibagi menjadi 4 tahapan eksekusi:

#### Tahap 1: Penambahan Kolom Transisi & Trigger Sinkronisasi
```sql
-- Tambahkan kolom integer paralel
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS amount_int BIGINT;
ALTER TABLE public.fund_sources ADD COLUMN IF NOT EXISTS balance_int BIGINT;

-- Trigger dual-write otomatis selama masa transisi
CREATE OR REPLACE FUNCTION sync_transaction_amount_int()
RETURNS TRIGGER AS $$
BEGIN
  NEW.amount_int := ROUND(NEW.amount);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_tx_amount_int
BEFORE INSERT OR UPDATE ON public.transactions
FOR EACH ROW EXECUTE FUNCTION sync_transaction_amount_int();
```

#### Tahap 2: Backfill Data Historis
```sql
-- Backfill baris lama secara bertahap (batch update)
UPDATE public.transactions 
SET amount_int = ROUND(amount) 
WHERE amount_int IS NULL;

UPDATE public.fund_sources 
SET balance_int = ROUND(balance) 
WHERE balance_int IS NULL;
```

#### Tahap 3: Verifikasi Integritas & Audit Rekonsiliasi
```sql
-- Pastikan tidak ada selisih antara kolom lama dan kolom integer
SELECT COUNT(*) FROM public.transactions 
WHERE amount_int != ROUND(amount);
-- Wajib menghasilkan 0 baris
```

#### Tahap 4: Swap Kolom & Finalisasi Skema
```sql
ALTER TABLE public.transactions DROP COLUMN amount;
ALTER TABLE public.transactions RENAME COLUMN amount_int TO amount;
```

---

## 4. Rencana Migrasi Kode Klien (Dart/Flutter)

### 4.1 Tahap 1: Lapisan Kompatibilitas Model (*Adapter Pattern*)
Pada model Dart (`TransactionItem`, `FundSource`, dll.):
* Simpan `final int amountInt;` sebagai *field* utama.
* Sediakan `double get amount => amountInt.toDouble();` sebagai getter *backward-compatible* agar widget yang belum dimigrasi tidak mengalami kompilasi galat (*compile break*).
* Sediakan konstruktor yang menerima `int` atau `num`:
  ```dart
  TransactionItem({
    required int amountInt,
    ...
  })
  ```

### 4.2 Tahap 2: Pembaruan Layanan Hitung Keuangan (`TransactionService`)
* Seluruh fungsi `calculateTotalExpense`, `calculateTotalIncome`, `calculateBalance` diubah menerima dan mengembalikan `int`.
* Operasi pembagian anggaran (`burnRate`, `percentage`) tetap menghasilkan rasio desimal normal (`double` antara `0.0` sampai `1.0`), namun nominal sisa anggaran tetap `int`.

### 4.3 Tahap 3: Pembaruan Widget Input & Tampilan
* `AmountInput`: Menangani pengetikan karakter angka secara langsung ke `int` tanpa konversi `double.parse()`.
* `CurrencyFormatter.format()`: Dioptimalkan untuk memformat `int` secara langsung tanpa pembulatan runtime berulang.

---

## 5. Rencana Pengujian & Kriteria Kelayakan (Safety Rollout Matrix)

| Fase | Aksi Verifikasi | Kriteria Kelulusan |
|---|---|---|
| **Uji Unit Model** | Uji serialisasi JSON model `TransactionItem.toJson()` dan `fromJson()`. | Nilai `amount` integer terserialisasi presisi tanpa `null`. |
| **Uji Stres Akumulasi** | Menghitung penjumlahan 100.000 transaksi acak antara `Money` vs `double`. | `Money` menghasilkan selisih 0 Rupiah terhadap data acuan. |
| **Uji Kompatibilitas Cloud** | Uji interaksi REST PostgREST Supabase dengan kolom `BIGINT`. | Seluruh query SELECT dan INSERT mengembalikan status HTTP 200/201. |
| **Regresi UI** | Menjalankan seluruh 31 berkas pengujian otomatis (`flutter test`). | **100% Pass (0 error, 0 fail)**. |

---

## 6. Rekomendasi Eksekusi
1. Rencana migrasi ini **tidak dieksekusi pada fase rilis saat ini** guna menjaga stabilitas biner rilis v1.0.0.
2. Eksekusi migrasi dijadwalkan pada siklus rilis berikutnya (v1.1.0) dengan mengaplikasikan skrip SQL Tahap 1 terlebih dahulu di Supabase Cloud staging.
