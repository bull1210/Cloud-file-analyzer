enum FileCategory {
  image,
  video,
  audio,
  document,
  pdf,
  spreadsheet,
  presentation,
  archive,
  code,
  other;

  String get displayName {
    switch (this) {
      case FileCategory.image: return 'Images';
      case FileCategory.video: return 'Videos';
      case FileCategory.audio: return 'Audio';
      case FileCategory.document: return 'Documents';
      case FileCategory.pdf: return 'PDFs';
      case FileCategory.spreadsheet: return 'Spreadsheets';
      case FileCategory.presentation: return 'Presentations';
      case FileCategory.archive: return 'Archives';
      case FileCategory.code: return 'Code';
      case FileCategory.other: return 'Other';
    }
  }

  String get iconAsset {
    switch (this) {
      case FileCategory.image: return '🖼️';
      case FileCategory.video: return '🎬';
      case FileCategory.audio: return '🎵';
      case FileCategory.document: return '📄';
      case FileCategory.pdf: return '📕';
      case FileCategory.spreadsheet: return '📊';
      case FileCategory.presentation: return '📽️';
      case FileCategory.archive: return '🗜️';
      case FileCategory.code: return '💻';
      case FileCategory.other: return '📁';
    }
  }
}

class FileTypeUtils {
  FileTypeUtils._();

  static final Map<String, FileCategory> _extensionMap = {
    // Images
    'jpg': FileCategory.image, 'jpeg': FileCategory.image,
    'png': FileCategory.image, 'gif': FileCategory.image,
    'bmp': FileCategory.image, 'webp': FileCategory.image,
    'svg': FileCategory.image, 'heic': FileCategory.image,
    'tiff': FileCategory.image, 'ico': FileCategory.image,
    'raw': FileCategory.image, 'cr2': FileCategory.image,

    // Videos
    'mp4': FileCategory.video, 'mov': FileCategory.video,
    'avi': FileCategory.video, 'mkv': FileCategory.video,
    'wmv': FileCategory.video, 'flv': FileCategory.video,
    'm4v': FileCategory.video, 'webm': FileCategory.video,
    '3gp': FileCategory.video, 'mts': FileCategory.video,

    // Audio
    'mp3': FileCategory.audio, 'wav': FileCategory.audio,
    'flac': FileCategory.audio, 'aac': FileCategory.audio,
    'ogg': FileCategory.audio, 'm4a': FileCategory.audio,
    'wma': FileCategory.audio, 'opus': FileCategory.audio,

    // PDFs
    'pdf': FileCategory.pdf,

    // Documents
    'doc': FileCategory.document, 'docx': FileCategory.document,
    'txt': FileCategory.document, 'rtf': FileCategory.document,
    'odt': FileCategory.document, 'pages': FileCategory.document,
    'md': FileCategory.document, 'epub': FileCategory.document,

    // Spreadsheets
    'xls': FileCategory.spreadsheet, 'xlsx': FileCategory.spreadsheet,
    'csv': FileCategory.spreadsheet, 'ods': FileCategory.spreadsheet,
    'numbers': FileCategory.spreadsheet,

    // Presentations
    'ppt': FileCategory.presentation, 'pptx': FileCategory.presentation,
    'odp': FileCategory.presentation, 'key': FileCategory.presentation,

    // Archives
    'zip': FileCategory.archive, 'rar': FileCategory.archive,
    '7z': FileCategory.archive, 'tar': FileCategory.archive,
    'gz': FileCategory.archive, 'bz2': FileCategory.archive,
    'xz': FileCategory.archive, 'dmg': FileCategory.archive,
    'iso': FileCategory.archive,

    // Code
    'dart': FileCategory.code, 'py': FileCategory.code,
    'js': FileCategory.code, 'ts': FileCategory.code,
    'java': FileCategory.code, 'kt': FileCategory.code,
    'swift': FileCategory.code, 'cpp': FileCategory.code,
    'c': FileCategory.code, 'h': FileCategory.code,
    'cs': FileCategory.code, 'go': FileCategory.code,
    'rs': FileCategory.code, 'rb': FileCategory.code,
    'php': FileCategory.code, 'html': FileCategory.code,
    'css': FileCategory.code, 'json': FileCategory.code,
    'xml': FileCategory.code, 'yaml': FileCategory.code,
    'yml': FileCategory.code, 'sh': FileCategory.code,
  };

  static final Map<String, FileCategory> _mimeTypeMap = {
    'application/pdf': FileCategory.pdf,
    'application/zip': FileCategory.archive,
    'application/x-rar-compressed': FileCategory.archive,
    'application/vnd.google-apps.document': FileCategory.document,
    'application/vnd.google-apps.spreadsheet': FileCategory.spreadsheet,
    'application/vnd.google-apps.presentation': FileCategory.presentation,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': FileCategory.document,
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': FileCategory.spreadsheet,
    'application/vnd.openxmlformats-officedocument.presentationml.presentation': FileCategory.presentation,
    'application/msword': FileCategory.document,
    'application/vnd.ms-excel': FileCategory.spreadsheet,
    'application/vnd.ms-powerpoint': FileCategory.presentation,
  };

  static FileCategory categorize({String? extension, String? mimeType}) {
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) return FileCategory.image;
      if (mimeType.startsWith('video/')) return FileCategory.video;
      if (mimeType.startsWith('audio/')) return FileCategory.audio;
      if (mimeType.startsWith('text/')) return FileCategory.document;
      final fromMime = _mimeTypeMap[mimeType];
      if (fromMime != null) return fromMime;
    }
    if (extension != null) {
      final fromExt = _extensionMap[extension.toLowerCase()];
      if (fromExt != null) return fromExt;
    }
    return FileCategory.other;
  }

  static bool isGoogleWorkspaceFile(String mimeType) {
    return mimeType.startsWith('application/vnd.google-apps.');
  }
}
