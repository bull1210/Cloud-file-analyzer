enum CloudProvider { google, microsoft, dropbox, terabox, mega, apple }

extension CloudProviderExtension on CloudProvider {
  String get displayName => switch (this) {
        CloudProvider.google => 'Google Drive',
        CloudProvider.microsoft => 'OneDrive',
        CloudProvider.dropbox => 'Dropbox',
        CloudProvider.terabox => 'TeraBox',
        CloudProvider.mega => 'MEGA',
        CloudProvider.apple => 'iCloud Drive',
      };

  String get shortName => switch (this) {
        CloudProvider.google => 'Google',
        CloudProvider.microsoft => 'Microsoft',
        CloudProvider.dropbox => 'Dropbox',
        CloudProvider.terabox => 'TeraBox',
        CloudProvider.mega => 'MEGA',
        CloudProvider.apple => 'iCloud',
      };

  String get dbValue => name;

  static CloudProvider fromDb(String value) =>
      CloudProvider.values.firstWhere(
        (e) => e.name == value,
        orElse: () => CloudProvider.google,
      );
}

class CloudAccount {
  const CloudAccount({
    required this.id,
    required this.provider,
    required this.email,
    required this.displayName,
    required this.label,
    required this.createdAt,
    this.lastScanAt,
    this.totalFiles = 0,
    this.totalFolders = 0,
    this.totalBytes = 0,
    this.photoUrl,
  });

  final String id;
  final CloudProvider provider;
  final String email;
  final String displayName;
  final String label;
  final DateTime createdAt;
  final DateTime? lastScanAt;
  final int totalFiles;
  final int totalFolders;
  final int totalBytes;
  final String? photoUrl;

  bool get hasBeenScanned => lastScanAt != null;

  CloudAccount copyWith({
    String? label,
    DateTime? lastScanAt,
    int? totalFiles,
    int? totalFolders,
    int? totalBytes,
  }) {
    return CloudAccount(
      id: id,
      provider: provider,
      email: email,
      displayName: displayName,
      label: label ?? this.label,
      createdAt: createdAt,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      totalFiles: totalFiles ?? this.totalFiles,
      totalFolders: totalFolders ?? this.totalFolders,
      totalBytes: totalBytes ?? this.totalBytes,
      photoUrl: photoUrl,
    );
  }

  @override
  bool operator ==(Object other) => other is CloudAccount && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
