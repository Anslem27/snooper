import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:snooper/app/screens/home.dart';

import '../models/local_activity_models.dart';

class LocalActivity extends StatefulWidget {
  const LocalActivity({super.key});

  @override
  State<LocalActivity> createState() => _LocalActivityState();
}

class _LocalActivityState extends State<LocalActivity> {
  List<AppUsageInfo> _appUsageList = [];
  final Map<String, AppInfo?> _appInfoCache = {};
  final Map<String, String> _appCategories = {};
  String _deviceName = "Your Device";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDeviceName();
    _initPermissions();
  }

  Future<void> _initDeviceName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDeviceName = prefs.getString('device_name');

    if (savedDeviceName == null) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      String newDeviceName = androidInfo.model;
      await prefs.setString('device_name', newDeviceName);
      setState(() => _deviceName = newDeviceName);
    } else {
      setState(() => _deviceName = savedDeviceName);
    }
  }

  Future<void> _initPermissions() async {
    var usageStatus = await Permission.appTrackingTransparency.request();
    if (usageStatus.isGranted) {
      await _getAppUsage();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Usage Access permission not granted');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _getAppUsage() async {
    setState(() => _isLoading = true);

    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(minutes: 5));

      List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(startDate, endDate);

      logger.i(infoList.toString());

      // Filter out system apps and populate app info cache
      List<AppUsageInfo> filteredList = [];

      for (final appInfo in infoList) {
        final appDetails = await _getAppInfo(appInfo.packageName);

        // heuristic approach
        bool isLikelySystemApp = _isSystemApp(appInfo.packageName);

        if (appDetails != null && !isLikelySystemApp) {
          filteredList.add(appInfo);

          await categorizeApp(appInfo.packageName);
        }
      }

      filteredList.sort((a, b) => b.endDate.compareTo(a.endDate));

      setState(() {
        _appUsageList = filteredList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      logger.e('Failed to get app usage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Activity on your $_deviceName"),
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: () => _getAppUsage(),
              child: _appUsageList.isEmpty
                  ? EmptyStateView(
                      message: 'No recent non-system apps detected')
                  : AppUsageListView(
                      appUsageList: _appUsageList,
                      appInfoCache: _appInfoCache,
                      appCategories: _appCategories,
                      getAppInfo: _getAppInfo,
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getAppUsage,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Future<AppInfo?> _getAppInfo(String packageName) async {
    if (!_appInfoCache.containsKey(packageName)) {
      _appInfoCache[packageName] = await InstalledApps.getAppInfo(packageName);
    }
    return _appInfoCache[packageName];
  }

  bool _isSystemApp(String packageName) {
    // Common system app package prefixes
    final systemPackagePrefixes = [
      'com.android.',
      'com.google.android.',
      'android.',
      'com.sec.android.',
      'com.samsung.',
    ];

    return systemPackagePrefixes
        .any((prefix) => packageName.startsWith(prefix));
  }

  Future<void> categorizeApp(String packageName) async {
    if (!_appCategories.containsKey(packageName)) {
      final RegExp socialRegex = RegExp(
          r'(facebook|twitter|instagram|snapchat|tiktok|whatsapp|telegram|messenger|discord)');
      final RegExp gameRegex =
          RegExp(r'(game|games|gaming|play\.|puzzles|arcade)');
      final RegExp productivityRegex =
          RegExp(r'(office|docs|sheets|slides|work|calendar|drive|note|task)');
      final RegExp mediaRegex = RegExp(
          r'(photo|video|camera|gallery|netflix|youtube|spotify|music|player|audio|media)');

      String category = 'Other';

      if (socialRegex.hasMatch(packageName.toLowerCase())) {
        category = 'Social';
      } else if (gameRegex.hasMatch(packageName.toLowerCase())) {
        category = 'Games';
      } else if (productivityRegex.hasMatch(packageName.toLowerCase())) {
        category = 'Productivity';
      } else if (mediaRegex.hasMatch(packageName.toLowerCase())) {
        category = 'Media';
      }

      _appCategories[packageName] = category;
    }
  }
}
