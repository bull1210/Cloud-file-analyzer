import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Simple file logger. Writes timestamped entries to Documents/cloudvault_debug.log
/// and mirrors them to the Flutter console.
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  IOSink? _sink;
  String _logPath = '';

  String get logPath => _logPath;

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logPath = '${dir.path}\\cloudvault_debug.log';
      final file = File(_logPath);
      _sink = file.openWrite(mode: FileMode.append);
      _write('');
      _write('══════════════════════════════════════════');
      _write('SESSION STARTED  ${DateTime.now()}');
      _write('══════════════════════════════════════════');
    } catch (e) {
      debugPrint('[AppLogger] Failed to open log file: $e');
    }
  }

  void log(String tag, String message) {
    _write('[$tag] $message');
  }

  void error(String tag, String message, [Object? err]) {
    _write('[ERROR][$tag] $message${err != null ? ' → $err' : ''}');
  }

  void _write(String line) {
    final entry = '${DateTime.now().toIso8601String()} $line';
    debugPrint(entry);
    _sink?.writeln(entry);
  }

  Future<void> flush() async {
    await _sink?.flush();
  }
}

/// Top-level shorthand so callers don't need to type AppLogger.instance each time.
final logger = AppLogger.instance;
