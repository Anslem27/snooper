import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:snooper/app/screens/home.dart';
import 'package:url_launcher/url_launcher.dart';

class AllYourDataPage extends StatefulWidget {
  const AllYourDataPage({super.key});

  @override
  _AllYourDataPageState createState() => _AllYourDataPageState();
}

class _AllYourDataPageState extends State<AllYourDataPage> {
  Map _prefsData = {};
  bool _isLoading = true;
  bool _isUploading = false;
  String? _backupUrl;
  final TextEditingController _urlController = TextEditingController();

  // add notifications when retention period is near
  ///* readMore here [https://0x0.st/?ref=public_apis&utm_medium=website]
  static const String _backupUrlKey = 'backup_url';
  static const String _nullPointerUrl = 'https://0x0.st';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    setState(() => _isLoading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map data = {};

    for (String key in keys) {
      data[key] = prefs.get(key);
    }

    setState(() {
      _prefsData = data;
      _backupUrl = prefs.getString(_backupUrlKey);
      _isLoading = false;
    });
  }

  Future<void> _backupData() async {
    if (_prefsData.isEmpty) {
      _showSnackBar('No data to backup');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final String jsonData = jsonEncode(_prefsData);

      var request = http.MultipartRequest('POST', Uri.parse(_nullPointerUrl));

      // for avoiding looking like a hijacked device response
      request.headers.addAll({
        'User-Agent': 'Flutter App/1.0',
        'Accept': '*/*',
      });

      var file = http.MultipartFile.fromString('file', jsonData,
          filename: 'snooper_app_backup.json');
      request.files.add(file);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      logger.i(response.body);

      if (response.statusCode == 200) {
        final url = response.body.trim();
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_backupUrlKey, url);

        setState(() {
          _backupUrl = url;
        });

        _showSnackBar('Backup successful!');
      } else {
        _showSnackBar('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error uploading: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _importFromUrl() async {
    if (_urlController.text.isEmpty) {
      _showSnackBar('Please enter a backup URL');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(_urlController.text));

      if (response.statusCode == 200) {
        final Map<String, dynamic> importedData = jsonDecode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // Clear existing prefs first
        await prefs.clear();

        // Import all the data
        for (var entry in importedData.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is String) {
            await prefs.setString(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is List<String>) {
            await prefs.setStringList(key, value.cast<String>());
          }
        }

        // Save the backup URL
        await prefs.setString(_backupUrlKey, _urlController.text);
        setState(() {
          _backupUrl = _urlController.text;
        });

        _loadPrefs();
        _showSnackBar('Data imported successfully!');
      } else {
        _showSnackBar('Error: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Error importing data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _copyUrlToClipboard() {
    if (_backupUrl != null) {
      Clipboard.setData(ClipboardData(text: _backupUrl!));
      _showSnackBar('URL copied to clipboard');
    }
  }

  void _showBackupInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'About Null Pointer Backup',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Your data is backed up using the Null Pointer service, a temporary file hosting service.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'File Retention:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '• Files are stored for at least 30 days\n'
                '• Maximum storage time is 1 year\n'
                '• Actual retention depends on file size\n'
                '• Smaller files are kept longer',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Important:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '• Save your backup URL in a safe place\n'
                '• Anyone with your URL can access your data\n'
                '• Create a new backup regularly\n'
                '• This is not a permanent backup solution',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              // read more here
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog() {
    _urlController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Backup URL',
                hintText: 'https://0x0.st/xxxx',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _importFromUrl();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Your Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrefs,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearAllData,
            tooltip: 'Clear All Data',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showBackupInfoSheet(context);
            },
            tooltip: 'Backup Info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBackupUrlCard(),
                Expanded(
                  child: _prefsData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.data_saver_off_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Data Available',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _prefsData.length,
                          itemBuilder: (context, index) {
                            String key = _prefsData.keys.elementAt(index);
                            dynamic value = _prefsData[key];

                            // Skip showing the backup URL in the list
                            if (key == _backupUrlKey) {
                              return const SizedBox.shrink();
                            }

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  key,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Text(
                                  value.toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                trailing: value is String && _isJson(value)
                                    ? IconButton(
                                        icon: const Icon(
                                            Icons.visibility_outlined),
                                        onPressed: () => _showJsonBottomSheet(
                                            key, jsonDecode(value)),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import',
            onPressed: _showImportDialog,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Import'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'backup',
            onPressed: _isUploading ? null : _backupData,
            icon: _isUploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.backup_outlined),
            label: Text(_isUploading ? 'Uploading...' : 'Backup'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupUrlCard() {
    if (_backupUrl == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup),
                const SizedBox(width: 8),
                Text(
                  'Your Backup Link',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: _copyUrlToClipboard,
                  tooltip: 'Copy URL',
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    if (_backupUrl != null) {
                      launchUrl(Uri.parse(_backupUrl!));
                    }
                  },
                  tooltip: 'Open URL',
                ),
                // reset the prefs to the default
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _backupUrl!,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep this link safe! Your data will be available for at least 30 days.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future _clearAllData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to delete all data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.clear();
              setState(() {
                _prefsData = {};
                _backupUrl = null;
              });
              if (mounted) Navigator.pop(context);
              _showSnackBar('All data cleared');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showJsonBottomSheet(String key, dynamic value) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  key,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(value),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isJson(String value) {
    try {
      jsonDecode(value);
      return true;
    } catch (e) {
      return false;
    }
  }
}
