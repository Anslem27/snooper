import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllYourDataPage extends StatefulWidget {
  const AllYourDataPage({super.key});

  @override
  _AllYourDataPageState createState() => _AllYourDataPageState();
}

class _AllYourDataPageState extends State<AllYourDataPage> {
  Map<String, dynamic> _prefsData = {};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> data = {};

    for (String key in keys) {
      data[key] = prefs.get(key);
    }

    setState(() {
      _prefsData = data;
    });
  }

  void _exportData() {
    final String jsonData = jsonEncode(_prefsData);
    // Share.share(jsonData, subject: 'Exported SharedPreferences Data');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Your Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _prefsData.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _prefsData.length,
                itemBuilder: (context, index) {
                  String key = _prefsData.keys.elementAt(index);
                  return Card(
                    elevation: 2,
                    child: ExpansionTile(
                      title: Text(key,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${_prefsData[key]}'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportData,
        tooltip: 'Export Data',
        child: Icon(Icons.share),
      ),
    );
  }
}
