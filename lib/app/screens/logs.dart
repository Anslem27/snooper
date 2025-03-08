import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../helpers/logger.dart';
import '../models/log.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final PersistentLogger _logger = PersistentLogger();
  List<LogEntry> _logs = [];
  List<LogEntry> _filteredLogs = [];
  String _selectedLevel = 'all';
  bool _sortNewestFirst = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();

    _searchController.addListener(() {
      _filterLogs();
    });
  }

  Future<void> _loadLogs() async {
    final logs = await _logger.getLogs();
    setState(() {
      _logs = logs;
      _filterLogs();
    });
  }

  void _filterLogs() {
    setState(() {
      _filteredLogs = _logs.where((log) {
        // Filter by level
        if (_selectedLevel != 'all' && log.level != _selectedLevel) {
          return false;
        }

        // Filter by search text
        if (_searchController.text.isNotEmpty &&
            !log.message
                .toLowerCase()
                .contains(_searchController.text.toLowerCase())) {
          return false;
        }

        return true;
      }).toList();

      // Sort logs
      _filteredLogs.sort((a, b) {
        if (_sortNewestFirst) {
          return b.timestamp.compareTo(a.timestamp);
        } else {
          return a.timestamp.compareTo(b.timestamp);
        }
      });
    });
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'trace':
        return Colors.grey;
      case 'debug':
        return Colors.blue;
      case 'info':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'wtf':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Logs'),
        actions: [
          IconButton(
            icon: Icon(
                _sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _sortNewestFirst = !_sortNewestFirst;
                _filterLogs();
              });
            },
            tooltip: _sortNewestFirst ? 'Newest first' : 'Oldest first',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Logs'),
                  content:
                      const Text('Are you sure you want to clear all logs?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text('Clear'),
                      onPressed: () async {
                        await _logger.clearLogs();
                        _loadLogs();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search logs',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 8),
                _filterChip('all', 'All'),
                _filterChip('trace', 'Trace'),
                _filterChip('debug', 'Debug'),
                _filterChip('info', 'Info'),
                _filterChip('warning', 'Warning'),
                _filterChip('error', 'Error'),
                _filterChip('wtf', 'WTF'),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(child: Text('No logs found'))
                : RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: ListView.builder(
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = _filteredLogs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color:
                              _getLevelColor(log.level).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _getLevelColor(log.level),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              log.message,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)} • ${log.level.toUpperCase()}',
                              style: TextStyle(
                                color: _getLevelColor(log.level),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                // Copy log to clipboard
                                final logText =
                                    '[${log.level.toUpperCase()}] ${DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)}: ${log.message}';

                                Clipboard.setData(ClipboardData(text: logText));

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Log copied to clipboard'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: EdgeInsets.all(10),
                                  ),
                                );
                              },
                              tooltip: 'Copy log',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadLogs,
        tooltip: 'Refresh logs',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: _selectedLevel == value,
        onSelected: (selected) {
          setState(() {
            _selectedLevel = selected ? value : 'all';
            _filterLogs();
          });
        },
        backgroundColor: value == 'all'
            ? Colors.grey.shade200
            : _getLevelColor(value).withValues(alpha: 0.1),
        selectedColor: value == 'all'
            ? Colors.blue.shade100
            : _getLevelColor(value).withValues(alpha: 0.3),
        checkmarkColor: value == 'all' ? Colors.blue : _getLevelColor(value),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
