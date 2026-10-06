import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Guarantees integer representation of currency in IDR (Rupiah has no fractional cents)
  static int toIntegerAmount(num amount) => amount.round();

  /// Format as standard Indonesian Rupiah: e.g. Rp2.500.000 or -Rp15.000
  static String format(num amount, {bool showSign = false, bool isExpense = false}) {
    final intAmount = amount.round();
    final absAmount = intAmount.abs();
    final formatted = _formatter.format(absAmount);
    if (isExpense || intAmount < 0) {
      return '-$formatted';
    } else if (showSign && intAmount > 0) {
      return '+$formatted';
    }
    return formatted;
  }

  /// Compact representation: e.g. Rp2,5 jt or Rp500 rb
  static String formatCompact(num amount) {
    final absAmount = amount.abs().round();
    if (absAmount >= 1000000000) {
      final val = absAmount / 1000000000;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} M';
    } else if (absAmount >= 1000000) {
      final val = absAmount / 1000000;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} jt';
    } else if (absAmount >= 1000) {
      final val = absAmount / 1000;
      return 'Rp${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 0)} rb';
    }
    return format(absAmount);
  }

  /// Hidden balance privacy mask
  static String maskedBalance() {
    return 'Rp ••••••••';
  }
}
