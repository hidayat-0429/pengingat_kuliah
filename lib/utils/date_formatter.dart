class DateFormatter {
  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static String format(DateTime dt) {
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_bulan[dt.month - 1]} ${dt.year}, $jam:$menit';
  }

  static String relative(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.isNegative) {
      final hari = diff.inDays.abs();
      if (hari == 0) {
        final jam = diff.inHours.abs();
        if (jam == 0) return 'Baru saja lewat';
        return 'Terlambat $jam jam';
      }
      return 'Terlambat $hari hari';
    }

    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lagi';
    if (diff.inHours < 24) return '${diff.inHours} jam lagi';
    if (diff.inDays == 1) return 'Besok';
    if (diff.inDays < 7) return '${diff.inDays} hari lagi';
    return format(dt);
  }

  static String badgeText(DateTime dt, bool selesai) {
    if (selesai) return '';
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) return 'Terlambat';
    if (diff.inHours < 24) return 'Hari Ini';
    if (diff.inDays <= 1) return 'Besok';
    if (diff.inDays <= 3) return '${diff.inDays} Hari';
    return '';
  }
}
