extension IntStorageExtensions on int {
  /// Converts bytes to human-readable storage string: "1.23 GB", "456 MB", etc.
  String toStorageString() {
    if (this <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    if (unitIndex == 0) return '${value.toInt()} B';
    return '${value.toStringAsFixed(value >= 100 ? 0 : value >= 10 ? 1 : 2)} ${units[unitIndex]}';
  }

  /// Short storage label: "1.2GB", "456MB"
  String toStorageShort() {
    if (this <= 0) return '0B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    if (unitIndex == 0) return '${value.toInt()}B';
    return '${value.toStringAsFixed(1)}${units[unitIndex]}';
  }

  String toFileCountLabel() {
    if (this >= 1000000) return '${(this / 1000000).toStringAsFixed(1)}M files';
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K files';
    return '$this file${this == 1 ? '' : 's'}';
  }

  String toFolderCountLabel() {
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}K folders';
    return '$this folder${this == 1 ? '' : 's'}';
  }
}

extension NullableIntExtensions on int? {
  String toStorageStringOrUnknown() => this?.toStorageString() ?? 'Unknown size';
}
