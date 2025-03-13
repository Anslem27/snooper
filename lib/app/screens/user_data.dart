import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllYourDataPage extends StatefulWidget {
  const AllYourDataPage({super.key});

  @override
  _AllYourDataPageState createState() => _AllYourDataPageState();
}

class _AllYourDataPageState extends State {
  Map _prefsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future _loadPrefs() async {
    setState(() => _isLoading = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map data = {};

    for (String key in keys) {
      data[key] = prefs.get(key);
    }

    setState(() {
      _prefsData = data;
      _isLoading = false;
    });
  }

  void _exportData() {
    final String jsonData = jsonEncode(_prefsData);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data exported successfully')),
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
              setState(() => _prefsData = {});
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
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
                        color: Theme.of(context).colorScheme.surfaceVariant,
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prefsData.isEmpty
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

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          key,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          value.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: value is String && _isJson(value)
                            ? IconButton(
                                icon: const Icon(Icons.visibility_outlined),
                                onPressed: () => _showJsonBottomSheet(
                                    key, jsonDecode(value)),
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportData,
        icon: const Icon(Icons.share_outlined),
        label: const Text('Export'),
      ),
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
