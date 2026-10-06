class DateFormatter {
  static String formatTime(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatDate(DateTime dateTime) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final m = months[dateTime.month - 1];
    return '${dateTime.day} $m ${dateTime.year}';
  }

  static String formatShortDate(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final m = months[dateTime.month - 1];
    return '${dateTime.day} $m ${dateTime.year}';
  }

  static String formatFull(DateTime dateTime) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    final dayName = days[dateTime.weekday - 1];
    return '$dayName, ${formatDate(dateTime)}, ${formatTime(dateTime)}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  static String formatCompact(DateTime dateTime) {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    return '$d/$m/${dateTime.year}';
  }

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(targetDate).inDays;
    final timeStr = formatTime(dateTime);

    if (difference == 0) {
      return 'Hari Ini, $timeStr';
    } else if (difference == 1) {
      return 'Kemarin, $timeStr';
    } else if (difference == -1) {
      return 'Besok, $timeStr';
    } else {
      return '${dateTime.day}/${dateTime.month}, $timeStr';
    }
  }

  /// Dynamic Indonesian greeting based on local time
  static String getGreeting(String userName) {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi, $userName 👋';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang, $userName ☀️';
    } else if (hour >= 15 && hour < 19) {
      return 'Selamat Sore, $userName ⛅';
    } else {
      return 'Selamat Malam, $userName 🌙';
    }
  }
}
