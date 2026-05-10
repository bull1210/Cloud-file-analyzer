class AppConstants {
  AppConstants._();

  static const String appName = 'CloudVault Analyzer';
  static const String appVersion = '1.0.0';

  // Scan
  static const int scanPageSize = 1000;
  static const int dbBatchInsertSize = 100;
  static const int maxLargestFiles = 15;
  static const int maxFolderRankings = 20;

  // Access time buckets (in days)
  static const int accessRecent = 180;    // 6 months
  static const int accessOld = 365;       // 1 year
  static const int accessVeryOld = 730;   // 2 years

  // UI
  static const double desktopBreakpoint = 720.0;
  static const double sidebarWidth = 240.0;
  static const double cardRadius = 16.0;
  static const double pageHorizontalPadding = 24.0;

  // Cache
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const Duration scanCacheDuration = Duration(hours: 1);
}
