import 'package:flutter/material.dart';

/// Representation of a gated or premium feature within ASTRACK
class AstraFeature {
  final String key;
  final String title;
  final String heroTitle;
  final String heroSubtitle;
  final String requiredPlanId;
  final String requiredPlanName;
  final IconData icon;
  final List<String> benefits;

  const AstraFeature({
    required this.key,
    required this.title,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.requiredPlanId,
    required this.requiredPlanName,
    required this.icon,
    required this.benefits,
  });

  /// True if feature requires the Pro plan
  bool get requiresPro => requiredPlanId == 'plan_pro';
}

/// Catalog of all feature gates across ASTRACK
class AstraFeatures {
  static const receiptScanner = AstraFeature(
    key: 'receipt_scanner',
    title: 'Auto-Scan Struk (OCR)',
    heroTitle: 'Unlock More with ASTRACK Pro',
    heroSubtitle: 'Turn your receipts into transactions in seconds.',
    requiredPlanId: 'plan_pro',
    requiredPlanName: 'Pro',
    icon: Icons.document_scanner_outlined,
    benefits: [
      'Scan receipts automatically using smart OCR',
      'Automatic merchant and category detection',
      'Instant transaction draft generation',
      'Zero manual typing for daily expenses',
    ],
  );

  static const aiAssistant = AstraFeature(
    key: 'ai_assistant',
    title: 'Asisten Finansial AI',
    heroTitle: 'Unlock More with ASTRACK Pro',
    heroSubtitle: 'Let ASTRACK help you record and understand your finances.',
    requiredPlanId: 'plan_pro',
    requiredPlanName: 'Pro',
    icon: Icons.psychology_outlined,
    benefits: [
      'Natural language Indonesian transaction parsing',
      'Smart financial recommendations & advice',
      'Intelligent clarification on ambiguous inputs',
      'Unlimited monthly AI consultations & insights',
    ],
  );

  static const advancedAnalytics = AstraFeature(
    key: 'advanced_analytics',
    title: 'Advanced Analytics',
    heroTitle: 'Unlock More with ASTRACK Pro',
    heroSubtitle: 'See deeper insights into where your money goes.',
    requiredPlanId: 'plan_pro',
    requiredPlanName: 'Pro',
    icon: Icons.insights_rounded,
    benefits: [
      'Detailed category spending insights & burn rate',
      'Month-over-month (MoM) trend comparisons',
      'Financial health score & predictive forecasts',
      'Savings runway and cashflow projections',
    ],
  );

  static const multiDeviceSync = AstraFeature(
    key: 'multi_device_sync',
    title: 'Multi-Device Cloud Sync',
    heroTitle: 'Unlock More with ASTRACK Pro',
    heroSubtitle: 'Keep your financial data synced across all your devices.',
    requiredPlanId: 'plan_pro',
    requiredPlanName: 'Pro',
    icon: Icons.devices_other_rounded,
    benefits: [
      'Real-time Supabase financial cloud synchronization',
      'Up to 5 concurrent active devices',
      'Encrypted conflict-free offline-first sync',
      'Instant access on phone, tablet, and desktop',
    ],
  );

  static const csvImportExport = AstraFeature(
    key: 'csv_import_export',
    title: 'Impor & Ekspor CSV',
    heroTitle: 'Unlock Essential Tools with Basic',
    heroSubtitle: 'Seamlessly export and import your financial data.',
    requiredPlanId: 'plan_basic',
    requiredPlanName: 'Basic',
    icon: Icons.file_upload_outlined,
    benefits: [
      'Bulk transaction import from bank statement CSVs',
      'Instant CSV and JSON full data export',
      'Flexible data backups and spreadsheet integration',
      'Automatic duplicate transaction protection',
    ],
  );

  static const advancedReports = AstraFeature(
    key: 'advanced_reports',
    title: 'Laporan Siap Cetak (PDF)',
    heroTitle: 'Unlock Essential Tools with Basic',
    heroSubtitle: 'Detailed reports and printable financial summaries.',
    requiredPlanId: 'plan_basic',
    requiredPlanName: 'Basic',
    icon: Icons.picture_as_pdf_outlined,
    benefits: [
      'Detailed monthly financial statement generation',
      'Clean printable HTML and PDF layout',
      'Breakdown of top expense categories & balances',
      'Professional format ready for business or tax filing',
    ],
  );

  static const advancedBudget = AstraFeature(
    key: 'advanced_budget',
    title: 'Advanced Budgeting',
    heroTitle: 'Unlock Essential Tools with Basic',
    heroSubtitle: 'Plan budgets with smart threshold tracking and alerts.',
    requiredPlanId: 'plan_basic',
    requiredPlanName: 'Basic',
    icon: Icons.pie_chart_outline_rounded,
    benefits: [
      'Multi-category flexible budget allocations',
      'Proactive overspending warnings and limits',
      'Historical monthly budget variance reports',
      'Custom budget cycles and rollover management',
    ],
  );

  /// Find feature by key or return fallback
  static AstraFeature fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'receipt_scanner':
      case 'ocr_scanner':
        return receiptScanner;
      case 'ai_assistant':
      case 'ai_advisor':
        return aiAssistant;
      case 'advanced_analytics':
      case 'analytics':
        return advancedAnalytics;
      case 'multi_device_sync':
        return multiDeviceSync;
      case 'csv_import_export':
      case 'csv_import':
        return csvImportExport;
      case 'advanced_reports':
      case 'reports':
        return advancedReports;
      case 'advanced_budget':
      case 'budget':
        return advancedBudget;
      default:
        return AstraFeature(
          key: key,
          title: 'Fitur Premium ASTRACK',
          heroTitle: 'Unlock More with ASTRACK Pro',
          heroSubtitle: 'Nikmati kontrol penuh atas keuangan Anda.',
          requiredPlanId: 'plan_pro',
          requiredPlanName: 'Pro',
          icon: Icons.star_rounded,
          benefits: const [
            'Akses tak terbatas ke seluruh fitur lanjutan',
            'Sinkronisasi otomatis ke cloud yang aman',
            'Dukungan prioritas tim ASTRACK',
            'Fitur terbaru otomatis terbuka tanpa biaya tambahan',
          ],
        );
    }
  }
}
