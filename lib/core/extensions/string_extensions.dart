extension StringExtensions on String {
  String get fileExtension {
    final dot = lastIndexOf('.');
    if (dot == -1 || dot == length - 1) return '';
    return substring(dot + 1).toLowerCase();
  }

  String get fileName {
    final slash = lastIndexOf('/');
    if (slash == -1) return this;
    return substring(slash + 1);
  }

  String truncated(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - 3)}...';
  }

  String truncateMiddle(int maxLength) {
    if (length <= maxLength) return this;
    final half = (maxLength - 3) ~/ 2;
    return '${substring(0, half)}...${substring(length - half)}';
  }
}
