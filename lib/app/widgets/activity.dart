import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'music_activity.dart';

class ActivityRenderer extends StatelessWidget {
  final Map<String, dynamic> discordData;
  final String username;

  const ActivityRenderer({
    super.key,
    required this.discordData,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final activities = discordData['activities'] as List<dynamic>? ?? [];
    final musicPlatform = _getMusicPlatform();
    final widgets = <Widget>[];

    // Add Spotify activity if present
    if (musicPlatform == 'spotify' && discordData['spotify'] != null) {
      final spotifyData = discordData['spotify'];
      widgets.add(
        MusicActivityCard(
          platform: 'spotify',
          title: spotifyData['song'] ?? 'Unknown Song',
          artist: spotifyData['artist'] ?? 'Unknown Artist',
          imageUrl: spotifyData['album_art_url'],
          username: username,
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
          MusicActivityCard(
            platform: platform,
            title: activity['details'] ?? 'Unknown Song',
            artist: activity['state'] ?? 'Unknown Artist',
            imageUrl: activity['assets']?['large_image'] != null
                ? 'https://cdn.discordapp.com/app-assets/${activity['application_id']}/${activity['assets']['large_image']}'
                : null,
            username: username,
          ),
        );
        continue;
      }

      // Other activities (gaming, coding, etc.)
      widgets.add(
        GeneralActivityCard(
          activity: activity,
          username: username,
        ),
      );
    }

    // Show offline state if no activities
    if (widgets.isEmpty) {
      widgets.add(
        OfflineActivityCard(username: username),
      );
    }

    return Column(children: widgets);
  }

  String _getMusicPlatform() {
    if (discordData['listening_to_spotify'] == true) {
      return 'spotify';
    }

    final activities = discordData['activities'] as List<dynamic>? ?? [];
    for (final activity in activities) {
      final name = activity['name'].toString().toLowerCase();
      if (name.contains('apple music')) return 'apple';
      if (name.contains('youtube music')) return 'youtube';
    }

    return '';
  }
}

class GeneralActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final String username;

  const GeneralActivityCard({
    super.key,
    required this.activity,
    required this.username,
  });

  Color _getActivityColor(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('code') ||
        name.contains('visual studio') ||
        name.contains('intellij')) {
      return Colors.teal;
    }
    return Colors.deepPurple;
  }

  @override
  Widget build(BuildContext context) {
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
                color: color.withValues(alpha: 0.1),
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
}

class OfflineActivityCard extends StatelessWidget {
  final String username;

  const OfflineActivityCard({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                color: Colors.purple.withValues(alpha: 0.1),
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
                  '@$username',
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
    );
  }
}
