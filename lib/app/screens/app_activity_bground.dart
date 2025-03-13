import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/app_monitor.dart';

// TODO:
class AppActivityMonitorScreen extends StatefulWidget {
  const AppActivityMonitorScreen({super.key});

  @override
  State<AppActivityMonitorScreen> createState() =>
      _AppActivityMonitorScreenState();
}

class _AppActivityMonitorScreenState extends State<AppActivityMonitorScreen> {
  List<AppActivityInfo> _activities = [];
  bool _isMonitoring = false;
  bool _hasPermission = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
    _setupStreamListener();
  }

  Future<void> _checkInitialState() async {
    final hasPermission = await AppMonitorService.checkPermission();
    setState(() {
      _hasPermission = hasPermission;
    });

    if (_hasPermission) {
      _loadStoredActivities();
    }
  }

  void _setupStreamListener() {
    _subscription = AppMonitorService.appDetections.listen((activity) {
      setState(() {
        _activities.insert(0, activity);

        if (_activities.length > 100) {
          _activities = _activities.sublist(0, 100);
        }
      });
    });
  }

  Future<void> _loadStoredActivities() async {
    final activities = await AppMonitorService.getStoredActivities();
    setState(() {
      _activities = activities;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleMonitoring() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    bool success;
    if (!_isMonitoring) {
      success = await AppMonitorService.startMonitoring();
    } else {
      success = await AppMonitorService.stopMonitoring();
    }

    if (success) {
      setState(() {
        _isMonitoring = !_isMonitoring;
      });
    }
  }

  Future<void> _requestPermission() async {
    await AppMonitorService.requestPermission();
    // We'll need to check again after returning from the settings
    // TODO: use native toast
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please grant usage access permission'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Activity Monitor'),
        actions: [
          IconButton(
            icon: Icon(_hasPermission
                ? PhosphorIcons.check()
                : PhosphorIcons.warning()),
            onPressed: _hasPermission ? null : _requestPermission,
            tooltip:
                _hasPermission ? 'Permission Granted' : 'Permission Required',
          ),
        ],
      ),
      body: _hasPermission ? _buildActivityList() : _buildPermissionRequest(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleMonitoring,
        icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
        label: Text(_isMonitoring ? 'Stop Monitoring' : 'Start Monitoring'),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Usage Access Permission Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This app needs permission to monitor app usage',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _requestPermission,
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.hourglass(), size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _isMonitoring
                  ? 'Waiting for activity...'
                  : 'Start monitoring to detect app usage',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(activity.appName.substring(0, 1)),
          ),
          title: Text(activity.appName),
          subtitle: Text(activity.packageName),
          trailing: Text(
            _formatTimestamp(activity.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
