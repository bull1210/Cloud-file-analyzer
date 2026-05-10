extension DateTimeExtensions on DateTime {
  String toRelativeString() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String toDisplayDate() {
    return '${day.toString().padLeft(2, '0')} '
        '${_monthName(month)} '
        '$year';
  }

  String toDisplayDateTime() {
    return '${toDisplayDate()} ${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  bool isOlderThanDays(int days) {
    return DateTime.now().difference(this).inDays > days;
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

extension NullableDateTimeExtensions on DateTime? {
  String toRelativeOrNever() => this?.toRelativeString() ?? 'Never';
  String toDisplayOrNever() => this?.toDisplayDate() ?? 'Never accessed';
}
