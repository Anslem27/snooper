import 'package:flutter/material.dart';

import 'general_user_activities.dart';
import 'music_activity.dart';
import 'offline_activity.dart';

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

    if (widgets.isEmpty) {
      widgets.add(
        OfflineActivityCard(
            avatarUrl: discordData['discord_user'] != null
                ? 'https://cdn.discordapp.com/avatars/${discordData["discord_user"]['id']}/${discordData["discord_user"]['avatar']}'
                : 'https://cdn.discordapp.com/embed/avatars/0.png',
            username: username),
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
