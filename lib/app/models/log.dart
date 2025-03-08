class LogEntry {
  final String message;
  final String level;
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'level': level,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      message: json['message'],
      level: json['level'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
