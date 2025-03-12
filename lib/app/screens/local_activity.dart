import 'package:app_usage/app_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:snooper/app/screens/home.dart';

import '../models/local_activity_models.dart';
import '../widgets/local_activity_widgets.dart';

class LocalActivity extends StatefulWidget {
  const LocalActivity({super.key});

  @override
  State<LocalActivity> createState() => _LocalActivityState();
}

class _LocalActivityState extends State<LocalActivity> {
  List<AppUsageInfo> _appUsageList = [];
  List<AppInfo> _allInstalledApps = [];
  Set<String> _selectedAppPackages = {};
  final Map<String, AppInfo?> _appInfoCache = {};
  final Map<String, String> _appCategories = {};
  String _deviceName = "Your Device";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDeviceName();
    _loadSelectedApps();
    _initPermissions();
    _getAppUsage();
    _loadAllInstalledApps();
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

  Future<void> _loadSelectedApps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> selectedApps = prefs.getStringList('selected_apps') ?? [];
    setState(() {
      _selectedAppPackages = Set.from(selectedApps);
    });
  }

  Future<void> _saveSelectedApps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_apps', _selectedAppPackages.toList());
  }

  Future<void> _loadAllInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      setState(() {
        _allInstalledApps =
            apps.where((app) => !_isSystemApp(app.packageName)).toList();
      });
    } catch (e) {
      logger.e('Failed to load installed apps: $e');
    }
  }

  Future<void> _initPermissions() async {
    var usageStatus = await Permission.appTrackingTransparency.request();
    if (usageStatus.isGranted) {
      // await _getAppUsage();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        // _showSnackBar('Usage Access permission not granted');
      }
    }
  }

  Future<void> _getAppUsage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(minutes: 5));

      List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(startDate, endDate);

      logger.d(infoList.toString());

      List<AppUsageInfo> filteredList = [];

      for (final appInfo in infoList) {
        final appDetails = await _getAppInfo(appInfo.packageName);

        // Check if app is selected by user
        bool isSelected = _selectedAppPackages.isEmpty ||
            _selectedAppPackages.contains(appInfo.packageName);

        bool isLikelySystemApp = _isSystemApp(appInfo.packageName);

        if (appDetails != null && !isLikelySystemApp && isSelected) {
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

  Future<void> _showAppSelectionDialog() async {
    final Set<String> tempSelected = Set.from(_selectedAppPackages);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSelectionBottomSheet(
        allApps: _allInstalledApps,
        selectedApps: tempSelected,
        onSelectionChanged: (newSelection) {
          tempSelected.clear();
          tempSelected.addAll(newSelection);
        },
      ),
    );
    if (!setEquals(tempSelected, _selectedAppPackages)) {
      setState(() {
        _selectedAppPackages = tempSelected;
      });
      await _saveSelectedApps();
      _getAppUsage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Activity on your $_deviceName",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16),
        ),
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.stackPlus()),
            tooltip: 'Select Apps',
            onPressed: _showAppSelectionDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: () => _getAppUsage(),
              child: _appUsageList.isEmpty
                  ? Center(
                      child: CircularProgressIndicator
                          .adaptive()) /* EmptyStateView(
                      message: _selectedAppPackages.isEmpty
                          ? 'No recent app activity detected'
                          : 'No activity for selected apps') */
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          AppUsageListView(
                            appUsageList: _appUsageList,
                            appInfoCache: _appInfoCache,
                            appCategories: _appCategories,
                            getAppInfo: _getAppInfo,
                            onAppTap: _showAppDetails,
                            allApps: _allInstalledApps,
                          ),
                        ],
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getAppUsage,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Future<void> _showAppDetails(AppUsageInfo appInfo) async {
    final appDetails = await _getAppInfo(appInfo.packageName);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AppDetailsSheet(
        appUsageInfo: appInfo,
        appInfo: appDetails,
        category: _appCategories[appInfo.packageName] ?? 'Other',
        allApps: _allInstalledApps,
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
