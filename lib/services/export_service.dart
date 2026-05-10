import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../core/errors/app_exception.dart';
import '../core/extensions/int_extensions.dart';
import '../domain/models/cloud_account.dart';
import '../domain/models/cloud_file.dart';
import '../domain/models/duplicate_group.dart';
import '../domain/models/storage_summary.dart';

class ExportData {
  const ExportData({
    required this.account,
    required this.files,
    required this.duplicateGroups,
    required this.summary,
  });

  final CloudAccount account;
  final List<CloudFile> files;
  final List<DuplicateGroup> duplicateGroups;
  final StorageSummary summary;
}

class ExportService {
  Future<void> exportCsv(ExportData data) async {
    try {
      final rows = <List<dynamic>>[
        // Header
        ['File Name', 'Path', 'Size', 'Size (bytes)', 'Type', 'Category', 'Modified', 'Accessed', 'Provider'],
        // Data
        ...data.files.map((f) => [
              f.name,
              f.path,
              f.sizeBytes?.toStorageString() ?? 'Unknown',
              f.sizeBytes ?? 0,
              f.mimeType,
              f.category.displayName,
              DateFormat('yyyy-MM-dd HH:mm').format(f.modifiedAt),
              f.accessedAt != null ? DateFormat('yyyy-MM-dd').format(f.accessedAt!) : 'Never',
              f.provider.displayName,
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(rows);
      final fileName =
          'cloudvault_${data.account.email}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      await _writeAndShare(csvString.codeUnits, fileName, 'text/csv');
    } catch (e) {
      throw ExportException('Failed to export CSV: $e', cause: e);
    }
  }

  Future<void> exportExcel(ExportData data) async {
    try {
      final excel = Excel.createExcel();

      // Summary sheet
      final summarySheet = excel['Summary'];
      summarySheet.appendRow([
        TextCellValue('CloudVault Analyzer Report'),
      ]);
      summarySheet.appendRow([TextCellValue('Account'), TextCellValue(data.account.label)]);
      summarySheet.appendRow([TextCellValue('Provider'), TextCellValue(data.account.provider.displayName)]);
      summarySheet.appendRow([TextCellValue('Email'), TextCellValue(data.account.email)]);
      summarySheet.appendRow([TextCellValue('Report Date'), TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()))]);
      summarySheet.appendRow([]);
      summarySheet.appendRow([TextCellValue('Total Files'), IntCellValue(data.summary.totalFiles)]);
      summarySheet.appendRow([TextCellValue('Total Folders'), IntCellValue(data.summary.totalFolders)]);
      summarySheet.appendRow([TextCellValue('Total Storage'), TextCellValue(data.summary.totalBytes.toStorageString())]);
      summarySheet.appendRow([TextCellValue('Duplicate Groups'), IntCellValue(data.summary.duplicateGroupCount)]);
      summarySheet.appendRow([TextCellValue('Wasted Space (Duplicates)'), TextCellValue(data.summary.duplicateWastedBytes.toStorageString())]);

      // All Files sheet
      final filesSheet = excel['All Files'];
      filesSheet.appendRow([
        TextCellValue('File Name'),
        TextCellValue('Path'),
        TextCellValue('Size'),
        TextCellValue('Size (bytes)'),
        TextCellValue('Category'),
        TextCellValue('Modified'),
        TextCellValue('Accessed'),
        TextCellValue('Provider'),
      ]);
      for (final f in data.files) {
        filesSheet.appendRow([
          TextCellValue(f.name),
          TextCellValue(f.path),
          TextCellValue(f.sizeBytes?.toStorageString() ?? 'Unknown'),
          IntCellValue(f.sizeBytes ?? 0),
          TextCellValue(f.category.displayName),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(f.modifiedAt)),
          TextCellValue(f.accessedAt != null ? DateFormat('yyyy-MM-dd').format(f.accessedAt!) : 'Never'),
          TextCellValue(f.provider.displayName),
        ]);
      }

      // Duplicates sheet
      if (data.duplicateGroups.isNotEmpty) {
        final dupSheet = excel['Duplicates'];
        dupSheet.appendRow([
          TextCellValue('Group'),
          TextCellValue('File Name'),
          TextCellValue('Path'),
          TextCellValue('Size'),
          TextCellValue('Modified'),
          TextCellValue('Wasted Bytes'),
        ]);
        for (var i = 0; i < data.duplicateGroups.length; i++) {
          final group = data.duplicateGroups[i];
          for (final f in group.files) {
            dupSheet.appendRow([
              TextCellValue('Group ${i + 1}'),
              TextCellValue(f.name),
              TextCellValue(f.path),
              TextCellValue(f.sizeBytes?.toStorageString() ?? 'Unknown'),
              TextCellValue(DateFormat('yyyy-MM-dd').format(f.modifiedAt)),
              IntCellValue(group.wastedBytes),
            ]);
          }
        }
      }

      // Remove default empty sheet
      excel.delete('Sheet1');

      final bytes = excel.encode();
      if (bytes == null) throw const ExportException('Excel encoding failed');

      final fileName =
          'cloudvault_${data.account.email}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      await _writeAndShare(bytes, fileName,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ExportException('Failed to export Excel: $e', cause: e);
    }
  }

  Future<void> _writeAndShare(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: 'CloudVault Analyzer Report',
    );
  }
}
