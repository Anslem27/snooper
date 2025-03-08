import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/log.dart';

class PersistentLogger {
  static final PersistentLogger _instance = PersistentLogger._internal();
  static const String _storageKey = 'app_logs';
  late Logger _logger;
  List<LogEntry> _logs = [];

  factory PersistentLogger() {
    return _instance;
  }

  PersistentLogger._internal() {
    _logger = Logger();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedLogs = prefs.getString(_storageKey);

    if (storedLogs != null) {
      final List<dynamic> decodedLogs = jsonDecode(storedLogs);
      _logs = decodedLogs.map((log) => LogEntry.fromJson(log)).toList();
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedLogs =
        jsonEncode(_logs.map((log) => log.toJson()).toList());
    await prefs.setString(_storageKey, encodedLogs);
  }

  Future<void> t(String message) async {
    _logger.t(message);
    await _addLog(message, 'trace');
  }

  Future<void> d(String message) async {
    _logger.d(message);
    await _addLog(message, 'debug');
  }

  Future<void> i(String message) async {
    _logger.i(message);
    await _addLog(message, 'info');
  }

  Future<void> w(String message) async {
    _logger.w(message);
    await _addLog(message, 'warning');
  }

  Future<void> e(String message) async {
    _logger.e(message);
    await _addLog(message, 'error');
  }

  Future<void> f(String message) async {
    _logger.f(message);
    await _addLog(message, 'wtf');
  }

  Future<void> _addLog(String message, String level) async {
    final log = LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
    );

    _logs.add(log);
    await _saveLogs();
  }

  Future<List<LogEntry>> getLogs() async {
    await _loadLogs(); // Ensure we have the latest logs
    return _logs;
  }

  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogs();
  }

  Future<List<LogEntry>> filterByLevel(String level) async {
    await _loadLogs();
    return _logs.where((log) => log.level == level).toList();
  }
}
