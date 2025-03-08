import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Use dynamic color scheme if available (Android 12+)
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Fallback color schemes
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Snooper',
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  List<AppUsageInfo> _appUsageList = [];
  Timer? _refreshTimer;

  // For Discord lanyard data
  Map<String, dynamic>? _discordData;
  bool _isLoadingDiscord = true;
  bool _hasDiscordError = false;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _initDeviceInfo();
    _initPermissions();
    _startPeriodicRefresh();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _initDeviceInfo() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        _deviceData =
            _readAndroidBuildData(await _deviceInfoPlugin.androidInfo);
      } else {
        _deviceData = <String, dynamic>{
          'error': 'This app is optimized for Android devices'
        };
      }
    } catch (e) {
      _deviceData = <String, dynamic>{
        'Error': 'Failed to get device info: $e',
      };
    }

    if (mounted) setState(() {});
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'brand': build.brand,
      'device': build.device,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'androidVersion': build.version.release,
      'sdkInt': build.version.sdkInt,
      'hardware': build.hardware,
      'isPhysicalDevice': build.isPhysicalDevice,
    };
  }

  Future<void> _initPermissions() async {
    var usageStatus = await Permission.appTrackingTransparency.request();
    if (usageStatus.isGranted) {
      await _getAppUsage();
    }

    await _fetchDiscordData();
  }

  Future<void> _getAppUsage() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(minutes: 30));

      List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(startDate, endDate);

      // Sort by most recently used
      infoList.sort((a, b) => b.endDate.compareTo(a.endDate));

      setState(() {
        _appUsageList =
            infoList.take(10).toList(); // Show top 10 most recent apps
      });
    } catch (e) {
      print('Failed to get app usage: $e');
    }
  }

  Future<void> _fetchDiscordData() async {
    setState(() {
      _isLoadingDiscord = true;
      _hasDiscordError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.lanyard.rest/v1/users/878728452155539537'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _discordData = jsonData['data'];
          _isLoadingDiscord = false;
        });
      } else {
        setState(() {
          _isLoadingDiscord = false;
          _hasDiscordError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingDiscord = false;
        _hasDiscordError = true;
      });
      print('Error fetching Discord data: $e');
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _getAppUsage();
      _fetchDiscordData();
    });
  }

  String _getMusicPlatform() {
    if (_discordData == null) return '';

    if (_discordData!['listening_to_spotify'] == true) {
      return 'spotify';
    }

    final activities = _discordData!['activities'] as List<dynamic>? ?? [];
    for (final activity in activities) {
      final name = activity['name'].toString().toLowerCase();
      if (name.contains('apple music')) return 'apple';
      if (name.contains('youtube music')) return 'youtube';
    }

    return '';
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'spotify':
        return const Color(0xFF1DB954);
      case 'apple':
        return const Color(0xFFFA243C);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return Colors.grey;
    }
  }

  Color _getActivityColor(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('code') ||
        name.contains('visual studio') ||
        name.contains('intellij')) {
      return Colors.teal;
    }
    return Colors.deepPurple;
  }

  Widget _buildWaveBars(Color color) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < 4; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 3,
                height: 10 + 20 * _getWaveHeight(i),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        );
      },
    );
  }

  double _getWaveHeight(int index) {
    final phase = index * 0.25;
    final t = (_waveController.value + phase) % 1.0;
    return 0.5 * (1 + sin(2 * 3.14159 * t));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Monitor'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _getAppUsage();
              _fetchDiscordData();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await _getAppUsage();
          await _fetchDiscordData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Device info card
            Card(
              elevation: 0,
              color: colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smartphone, color: colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Device Info',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_deviceData.isNotEmpty) ...[
                      _deviceInfoRow('Model',
                          '${_deviceData['manufacturer']} ${_deviceData['model']}'),
                      _deviceInfoRow('Android',
                          '${_deviceData['androidVersion']} (SDK ${_deviceData['sdkInt']})'),
                      _deviceInfoRow('Device', '${_deviceData['device']}'),
                    ] else ...[
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'Discord Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Discord Activity
            if (_isLoadingDiscord)
              _buildLoadingCard('Loading Discord activity...')
            else if (_hasDiscordError)
              _buildErrorCard('Failed to load Discord data')
            else if (_discordData != null)
              _buildDiscordActivities()
            else
              _buildErrorCard('No Discord data available'),

            const SizedBox(height: 24),
            Text(
              'Recent Applications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // App usage list
            if (_appUsageList.isEmpty)
              _buildInfoCard('No recent apps detected or permission denied'),

            for (final appInfo in _appUsageList) _buildAppUsageCard(appInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Monitor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (_deviceData.isNotEmpty)
                  Text(
                    '${_deviceData['manufacturer']} ${_deviceData['model']}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: const Text('System Info'),
            onTap: () {
              // Navigate to system info page
              Navigator.pop(context);
              // Add navigation here
            },
          ),
          ListTile(
            leading: const Icon(Icons.apps),
            title: const Text('App Management'),
            onTap: () {
              Navigator.pop(context);
              // Add navigation here
            },
          ),
          ListTile(
            leading: const Icon(Icons.discord),
            title: const Text('Discord Settings'),
            onTap: () {
              Navigator.pop(context);
              // Add navigation here
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Add navigation here
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Snooper',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _deviceInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscordActivities() {
    final discordUser = _discordData!['discord_user'];
    final activities = _discordData!['activities'] as List<dynamic>? ?? [];
    final musicPlatform = _getMusicPlatform();
    final widgets = <Widget>[];

    // Add Spotify activity if present
    if (musicPlatform == 'spotify' && _discordData!['spotify'] != null) {
      final spotifyData = _discordData!['spotify'];
      widgets.add(
        _buildMusicActivityCard(
          platform: 'spotify',
          title: spotifyData['song'] ?? 'Unknown Song',
          artist: spotifyData['artist'] ?? 'Unknown Artist',
          imageUrl: spotifyData['album_art_url'],
          username: discordUser['display_name'] ?? discordUser['username'],
        ),
      );
    }

    // Add all other activities
    for (final activity in activities) {
      // Skip Spotify activity as we've already added it
      if (activity['name'] == 'Spotify' && musicPlatform == 'spotify') continue;

      // Check if it's another music platform
      final name = activity['name'].toString().toLowerCase();
      if (name.contains('apple music') || name.contains('youtube music')) {
        final platform = name.contains('apple music') ? 'apple' : 'youtube';
        widgets.add(
          _buildMusicActivityCard(
            platform: platform,
            title: activity['details'] ?? 'Unknown Song',
            artist: activity['state'] ?? 'Unknown Artist',
            imageUrl: activity['assets']?['large_image'] != null
                ? 'https://cdn.discordapp.com/app-assets/${activity['application_id']}/${activity['assets']['large_image']}'
                : null,
            username: discordUser['display_name'] ?? discordUser['username'],
          ),
        );
        continue;
      }

      // Other activities (gaming, coding, etc.)
      widgets.add(
        _buildActivityCard(
          activity: activity,
          username: discordUser['display_name'] ?? discordUser['username'],
        ),
      );
    }

    // Show offline state if no activities
    if (widgets.isEmpty) {
      widgets.add(
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.discord,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${discordUser['display_name'] ?? discordUser['username']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Currently offline',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(children: widgets);
  }

  Widget _buildMusicActivityCard({
    required String platform,
    required String title,
    required String artist,
    required String username,
    String? imageUrl,
  }) {
    final color = _getPlatformColor(platform);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Album art or fallback
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: _buildWaveBars(color),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: _buildWaveBars(color),
                        ),
                      ),
                    )
                  : Center(
                      child: _buildWaveBars(color),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        platform == 'spotify'
                            ? Icons.music_note
                            : platform == 'apple'
                                ? Icons.apple
                                : Icons.play_circle_fill,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required Map<String, dynamic> activity,
    required String username,
  }) {
    final activityName = activity['name'] ?? 'Unknown Activity';
    final color = _getActivityColor(activityName);
    final details = activity['details'];
    final state = activity['state'];

    String? imageUrl;
    if (activity['assets'] != null &&
        activity['assets']['large_image'] != null) {
      imageUrl =
          'https://cdn.discordapp.com/app-assets/${activity['application_id']}/${activity['assets']['large_image']}';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          activityName.toLowerCase().contains('code')
                              ? Icons.code
                              : Icons.gamepad,
                          color: color,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          activityName.toLowerCase().contains('code')
                              ? Icons.code
                              : Icons.gamepad,
                          color: color,
                        ),
                      ),
                    )
                  : Icon(
                      activityName.toLowerCase().contains('code')
                          ? Icons.code
                          : Icons.gamepad,
                      color: color,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        activityName.toLowerCase().contains('code')
                            ? Icons.code
                            : Icons.gamepad,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activityName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (state != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      state,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
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

  Widget _buildLoadingCard(String message) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
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
