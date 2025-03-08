import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:snooper/app/screens/home.dart';

class LocalActivity extends StatefulWidget {
  const LocalActivity({super.key});

  @override
  State<LocalActivity> createState() => _LocalActivityState();
}

class _LocalActivityState extends State<LocalActivity> {
  List<AppUsageInfo> _appUsageList = [];

  @override
  void initState() {
    _initPermissions();
    _getAppUsage();
    super.initState();
  }

  Future<void> _initPermissions() async {
    var usageStatus = await Permission.appTrackingTransparency.request();
    if (usageStatus.isGranted) {
      await _getAppUsage();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usage Access permission not granted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  Future<void> _getAppUsage() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(minutes: 30));

      List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(startDate, endDate);

      infoList.sort((a, b) => b.endDate.compareTo(a.endDate));

      setState(() {
        _appUsageList =
            infoList.take(10).toList(); // Show top 10 most recent apps
      });
    } catch (e) {
      logger.f('Failed to get app usage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Local Activity on your S${23}"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _getAppUsage();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (_appUsageList.isEmpty)
              _buildInfoCard('No recent apps detected or permission denied'),
            for (final appInfo in _appUsageList) _buildAppUsageCard(appInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageCard(AppUsageInfo appInfo) {
    final duration = appInfo.usage;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationText = minutes > 0
        ? '$minutes min ${seconds > 0 ? '$seconds sec' : ''}'
        : '${duration.inSeconds} sec';

    // Format time ago
    final timeAgo = DateTime.now().difference(appInfo.endDate);
    final timeAgoText = timeAgo.inMinutes < 1
        ? 'just now'
        : timeAgo.inMinutes == 1
            ? '1 minute ago'
            : '${timeAgo.inMinutes} minutes ago';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.apps,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          appInfo.appName.split('.').last,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('Used for $durationText'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeAgoText,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String message) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }
}
