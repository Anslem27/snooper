import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

import '../widgets/drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Timer? _refreshTimer;

  // For Discord lanyard data
  Map<String, dynamic>? _discordData;
  bool _isLoadingDiscord = true;
  bool _hasDiscordError = false;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
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

  Future<void> _initPermissions() async {
    var usageStatus = await Permission.appTrackingTransparency.request();
    if (usageStatus.isGranted) {}

    await _fetchDiscordData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snooper'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchDiscordData();
            },
          ),
        ],
      ),
      drawer: SonnerDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDiscordData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
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
          ],
        ),
      ),
    );
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
}
