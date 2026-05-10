import 'cloud_file.dart';

class DuplicateGroup {
  const DuplicateGroup({
    required this.signature,
    required this.files,
  });

  /// Signature format:
  ///   "filename::sizeBytes::algo:hash"  — when provider returned a content hash (exact match)
  ///   "filename::sizeBytes"             — fallback when no hash was available (probable duplicate)
  final String signature;
  final List<CloudFile> files;

  String get fileName => files.first.name;

  /// True when all files share a content hash — an exact byte-for-byte match.
  /// False when matched by name+size only (no hash available from the provider).
  bool get hasHashMatch => signature.split('::').length == 3;
  int get fileCount => files.length;

  /// Bytes wasted = (count - 1) × size (one copy is "needed", rest are waste)
  int get wastedBytes {
    final size = files.first.sizeBytes ?? 0;
    return size * (files.length - 1);
  }

  /// Suggests keeping the newest file, deleting the rest.
  List<CloudFile> get suggestedForDeletion {
    final sorted = List<CloudFile>.from(files)
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return sorted.skip(1).toList();
  }

  /// Suggests keeping the oldest file, deleting the rest.
  List<CloudFile> get suggestedForDeletionKeepOldest {
    final sorted = List<CloudFile>.from(files)
      ..sort((a, b) => a.modifiedAt.compareTo(b.modifiedAt));
    return sorted.skip(1).toList();
  }
}
