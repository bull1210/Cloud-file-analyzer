enum AccessTimeBucket {
  recentSixMonths,
  notAccessedOneYear,
  notAccessedTwoYears,
  never;

  String get label {
    switch (this) {
      case AccessTimeBucket.recentSixMonths: return 'Active (< 6 months)';
      case AccessTimeBucket.notAccessedOneYear: return 'Idle (6 mo – 1 yr)';
      case AccessTimeBucket.notAccessedTwoYears: return 'Stale (1 – 2 yrs)';
      case AccessTimeBucket.never: return 'Dormant (2+ yrs / never)';
    }
  }

  String get description {
    switch (this) {
      case AccessTimeBucket.recentSixMonths: return 'Files accessed in the last 6 months';
      case AccessTimeBucket.notAccessedOneYear: return 'Files not accessed in 6–12 months';
      case AccessTimeBucket.notAccessedTwoYears: return 'Files not accessed in 1–2 years';
      case AccessTimeBucket.never: return 'Files not accessed in over 2 years';
    }
  }
}

class AccessTimeStats {
  const AccessTimeStats({
    required this.bucket,
    required this.fileCount,
    required this.totalBytes,
  });

  final AccessTimeBucket bucket;
  final int fileCount;
  final int totalBytes;
}

class AccessTimeStatsList {
  const AccessTimeStatsList(this.items);

  final List<AccessTimeStats> items;

  AccessTimeStats forBucket(AccessTimeBucket bucket) =>
      items.firstWhere(
        (s) => s.bucket == bucket,
        orElse: () => AccessTimeStats(bucket: bucket, fileCount: 0, totalBytes: 0),
      );
}
