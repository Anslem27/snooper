import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../helpers/logger.dart';
import '../models/log.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State {
  final PersistentLogger _logger = PersistentLogger();
  List<LogEntry> _logs = [];
  List<LogEntry> _filteredLogs = [];
  String _selectedLevel = 'all';
  bool _sortNewestFirst = true;
  final TextEditingController _searchController = TextEditingController();
  static const int maxLogs = 50;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _searchController.addListener(_filterLogs);
  }

  Future _loadLogs() async {
    var logs = await _logger.getLogs();

    if (logs.length > maxLogs) {
      logs = logs.sublist(logs.length - maxLogs);
      await _logger.saveLogs(logs);
    }

    setState(() {
      _logs = logs;
      _filterLogs();
    });
  }

  void _filterLogs() {
    setState(() {
      _filteredLogs = _logs.where((log) {
        if (_selectedLevel != 'all' && log.level != _selectedLevel) {
          return false;
        }
        if (_searchController.text.isNotEmpty &&
            !log.message
                .toLowerCase()
                .contains(_searchController.text.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();

      _filteredLogs.sort((a, b) => _sortNewestFirst
          ? b.timestamp.compareTo(a.timestamp)
          : a.timestamp.compareTo(b.timestamp));
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

  void _showLogDetails(LogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Log Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _detailItem('Level', log.level.toUpperCase(),
                      _getLevelColor(log.level)),
                  _detailItem(
                      'Timestamp',
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp),
                      Theme.of(context).colorScheme.secondary),
                  _detailItem('Message', log.message, null),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      final logText =
                          '[${log.level.toUpperCase()}] ${DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)}: ${log.message}';
                      Clipboard.setData(ClipboardData(text: logText));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Log copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Log'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Application Logs'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(_sortNewestFirst
                ? PhosphorIcons.arrowDown()
                : PhosphorIcons.arrowUp()),
            onPressed: () {
              setState(() {
                _sortNewestFirst = !_sortNewestFirst;
                _filterLogs();
              });
            },
          ),
          IconButton(
            icon: Icon(PhosphorIcons.trashSimple()),
            onPressed: () => _showClearLogsDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search logs',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('all', 'All'),
                _filterChip('trace', 'Trace'),
                _filterChip('debug', 'Debug'),
                _filterChip('info', 'Info'),
                _filterChip('warning', 'Warning'),
                _filterChip('error', 'Error'),
                _filterChip('wtf', 'WTF'),
              ],
            ),
          ),
          Expanded(
            child: _filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      'No logs found',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: ListView.builder(
                      itemCount: _filteredLogs.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final log = _filteredLogs[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _showLogDetails(log),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.message,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getLevelColor(log.level)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          log.level.toUpperCase(),
                                          style: TextStyle(
                                            color: _getLevelColor(log.level),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('HH:mm:ss')
                                            .format(log.timestamp),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showClearLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('Clear'),
            onPressed: () async {
              await _logger.clearLogs();
              _loadLogs();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
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
