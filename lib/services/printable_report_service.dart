import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_item.dart';

class PrintableReportService {
  static String generateMonthlyReport({
    required FinanceProvider finance,
    required DateTime month,
  }) {
    final formatter = DateFormat('MMMM yyyy', 'id');
    final txFormatter = DateFormat('dd MMM yyyy, HH:mm', 'id');
    final moneyFmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    // Filter transactions for selected month
    final monthTx = finance.transactions.where((t) {
      return t.dateTime.year == month.year && t.dateTime.month == month.month;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryExpense = {};
    final Map<String, double> categoryIncome = {};

    for (final tx in monthTx) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
        categoryIncome[tx.categoryName] = (categoryIncome[tx.categoryName] ?? 0) + tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
        categoryExpense[tx.categoryName] = (categoryExpense[tx.categoryName] ?? 0) + tx.amount;
      }
    }

    final netFlow = totalIncome - totalExpense;
    final netColor = netFlow >= 0 ? '#22c55e' : '#ef4444';

    // Sort category maps
    final sortedExpCat = categoryExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedIncCat = categoryIncome.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String buildCategoryBars(List<MapEntry<String, double>> cats, double total, String color) {
      if (cats.isEmpty) return '<p style="color:#9ca3af;font-size:13px;">Tidak ada data</p>';
      return cats.map((e) {
        final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
        return '''
        <div style="margin-bottom:10px;">
          <div style="display:flex;justify-content:space-between;margin-bottom:4px;">
            <span style="font-size:13px;color:#374151;">${_escapeHtml(e.key)}</span>
            <span style="font-size:13px;font-weight:700;color:$color;">${moneyFmt.format(e.value)}</span>
          </div>
          <div style="background:#f3f4f6;border-radius:6px;height:8px;overflow:hidden;">
            <div style="width:$pct%;background:$color;height:100%;border-radius:6px;"></div>
          </div>
        </div>''';
      }).join('\n');
    }

    String buildTransactionRows(List<TransactionItem> txs) {
      if (txs.isEmpty) {
        return '<tr><td colspan="5" style="text-align:center;color:#9ca3af;padding:20px;">Tidak ada transaksi pada bulan ini</td></tr>';
      }
      return txs.map((tx) {
        final isIncome = tx.type == TransactionType.income;
        final isTransfer = tx.type == TransactionType.transfer;
        final color = isIncome ? '#22c55e' : isTransfer ? '#3b82f6' : '#ef4444';
        final sign = isIncome ? '+' : isTransfer ? '↔' : '-';
        final typeLabel = isIncome ? 'Pemasukan' : isTransfer ? 'Transfer' : 'Pengeluaran';
        return '''
        <tr style="border-bottom:1px solid #f3f4f6;">
          <td style="padding:10px 8px;font-size:12px;color:#6b7280;">${txFormatter.format(tx.dateTime)}</td>
          <td style="padding:10px 8px;font-size:12px;">
            <span style="display:inline-block;padding:2px 8px;border-radius:20px;background:${color}20;color:$color;font-size:11px;font-weight:600;">$typeLabel</span>
          </td>
          <td style="padding:10px 8px;font-size:12px;color:#374151;">${_escapeHtml(tx.categoryName)}</td>
          <td style="padding:10px 8px;font-size:13px;color:#374151;max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${_escapeHtml(tx.description)}</td>
          <td style="padding:10px 8px;font-size:13px;font-weight:700;color:$color;text-align:right;">$sign ${moneyFmt.format(tx.amount)}</td>
        </tr>''';
      }).join('\n');
    }

    final name = finance.profile.name.isNotEmpty ? finance.profile.name : 'Pengguna';
    final email = finance.profile.email.isNotEmpty ? finance.profile.email : '';
    final printDate = DateFormat('dd MMMM yyyy, HH:mm', 'id').format(DateTime.now());

    return '''<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Laporan Keuangan ASTRACK — ${formatter.format(month)}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
    
    * { margin: 0; padding: 0; box-sizing: border-box; }
    
    body {
      font-family: 'Plus Jakarta Sans', -apple-system, sans-serif;
      background: #f8fafc;
      color: #111827;
      padding: 0;
    }
    
    .wrapper {
      max-width: 860px;
      margin: 0 auto;
      padding: 40px 24px;
    }

    /* Header */
    .header {
      background: linear-gradient(135deg, #059669 0%, #0ea5e9 100%);
      border-radius: 20px;
      padding: 32px;
      margin-bottom: 28px;
      color: white;
      position: relative;
      overflow: hidden;
    }
    .header::before {
      content: '';
      position: absolute;
      right: -40px; top: -40px;
      width: 180px; height: 180px;
      background: rgba(255,255,255,0.08);
      border-radius: 50%;
    }
    .header-logo {
      display: flex;
      align-items: center;
      gap: 10px;
      margin-bottom: 16px;
    }
    .logo-badge {
      width: 40px; height: 40px;
      background: rgba(255,255,255,0.2);
      border-radius: 10px;
      display: flex; align-items: center; justify-content: center;
      font-size: 18px; font-weight: 900;
    }
    .header-title { font-size: 26px; font-weight: 800; margin-bottom: 4px; }
    .header-period { font-size: 15px; opacity: 0.85; }
    .header-meta { margin-top: 12px; font-size: 12px; opacity: 0.7; }

    /* Summary Cards */
    .summary-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 14px;
      margin-bottom: 24px;
    }
    .summary-card {
      background: white;
      border-radius: 16px;
      padding: 20px;
      border: 1px solid #e5e7eb;
      box-shadow: 0 1px 4px rgba(0,0,0,0.04);
    }
    .summary-label {
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #9ca3af;
      margin-bottom: 8px;
    }
    .summary-value {
      font-size: 22px;
      font-weight: 800;
    }
    .summary-sub {
      font-size: 11px;
      color: #9ca3af;
      margin-top: 4px;
    }

    /* Sections */
    .section {
      background: white;
      border-radius: 16px;
      border: 1px solid #e5e7eb;
      padding: 24px;
      margin-bottom: 20px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.04);
    }
    .section-title {
      font-size: 15px;
      font-weight: 800;
      color: #111827;
      margin-bottom: 16px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .section-title .dot {
      width: 8px; height: 8px;
      border-radius: 50%;
      display: inline-block;
    }

    /* Table */
    .tx-table {
      width: 100%;
      border-collapse: collapse;
      font-family: 'Plus Jakarta Sans', sans-serif;
    }
    .tx-table th {
      background: #f9fafb;
      padding: 10px 8px;
      text-align: left;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      color: #6b7280;
      border-bottom: 2px solid #f3f4f6;
    }
    .tx-table th:last-child { text-align: right; }
    .tx-table tr:hover { background: #fafafa; }

    /* Footer */
    .footer {
      text-align: center;
      font-size: 11px;
      color: #d1d5db;
      margin-top: 32px;
      padding-top: 16px;
      border-top: 1px solid #e5e7eb;
    }

    /* Print */
    @media print {
      body { background: white; }
      .wrapper { padding: 16px; max-width: 100%; }
      .no-print { display: none !important; }
      .section { page-break-inside: avoid; }
    }
  </style>
</head>
<body>
  <div class="wrapper">

    <!-- Print button (hidden in print) -->
    <div class="no-print" style="text-align:right;margin-bottom:16px;">
      <button onclick="window.print()" style="background:linear-gradient(135deg,#059669,#0ea5e9);color:white;border:none;border-radius:12px;padding:10px 24px;font-size:14px;font-weight:700;cursor:pointer;font-family:inherit;">
        🖨️ Cetak / Simpan sebagai PDF
      </button>
    </div>

    <!-- Header -->
    <div class="header">
      <div class="header-logo">
        <div class="logo-badge">A</div>
        <span style="font-size:16px;font-weight:800;letter-spacing:0.06em;">ASTRACK</span>
      </div>
      <div class="header-title">Laporan Keuangan Bulanan</div>
      <div class="header-period">${formatter.format(month)}</div>
      <div class="header-meta">
        Pemilik: $name${email.isNotEmpty ? ' · $email' : ''} &nbsp;|&nbsp; Dibuat: $printDate
      </div>
    </div>

    <!-- Summary Cards -->
    <div class="summary-grid">
      <div class="summary-card">
        <div class="summary-label">Total Pemasukan</div>
        <div class="summary-value" style="color:#22c55e;">${moneyFmt.format(totalIncome)}</div>
        <div class="summary-sub">${sortedIncCat.length} kategori sumber</div>
      </div>
      <div class="summary-card">
        <div class="summary-label">Total Pengeluaran</div>
        <div class="summary-value" style="color:#ef4444;">${moneyFmt.format(totalExpense)}</div>
        <div class="summary-sub">${sortedExpCat.length} kategori pengeluaran</div>
      </div>
      <div class="summary-card">
        <div class="summary-label">Arus Kas Bersih</div>
        <div class="summary-value" style="color:$netColor;">${netFlow >= 0 ? '+' : ''}${moneyFmt.format(netFlow)}</div>
        <div class="summary-sub">${monthTx.length} transaksi total</div>
      </div>
    </div>

    <!-- Category Breakdown: Expense -->
    <div class="section">
      <div class="section-title">
        <span class="dot" style="background:#ef4444;"></span>
        Rincian Pengeluaran per Kategori
      </div>
      ${buildCategoryBars(sortedExpCat, totalExpense, '#ef4444')}
    </div>

    <!-- Category Breakdown: Income -->
    <div class="section">
      <div class="section-title">
        <span class="dot" style="background:#22c55e;"></span>
        Rincian Pemasukan per Kategori
      </div>
      ${buildCategoryBars(sortedIncCat, totalIncome, '#22c55e')}
    </div>

    <!-- Transaction Table -->
    <div class="section">
      <div class="section-title">
        <span class="dot" style="background:#6366f1;"></span>
        Riwayat Transaksi (${monthTx.length} data)
      </div>
      <div style="overflow-x:auto;">
        <table class="tx-table">
          <thead>
            <tr>
              <th>Tanggal</th>
              <th>Tipe</th>
              <th>Kategori</th>
              <th>Keterangan</th>
              <th style="text-align:right;">Nominal</th>
            </tr>
          </thead>
          <tbody>
            ${buildTransactionRows(monthTx)}
          </tbody>
        </table>
      </div>
    </div>

    <!-- Footer -->
    <div class="footer">
      Laporan ini dibuat secara otomatis oleh ASTRACK Financial Tracker &nbsp;·&nbsp; ${formatter.format(month)} &nbsp;·&nbsp; Bersifat rahasia
    </div>
  </div>
</body>
</html>''';
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
