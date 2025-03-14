import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/lanyard_user.dart';

mixin NotificationAddOns {
  String createFriendlyActivityMessage(
      String friendName, LanyardActivity activity) {
    final activityType = activity.type;
    final name = activity.name;
    final details = activity.details;
    final state = activity.state;

    // Activity types in Discord:
    // 0: Playing, 1: Streaming, 2: Listening, 3: Watching, 4: Custom, 5: Competing

    switch (activityType) {
      case 0:
        if (details != null && details.isNotEmpty) {
          return '$friendName is playing $name ($details)';
        }
        return '$friendName is playing $name';

      case 1:
        if (details != null && details.isNotEmpty) {
          return '$friendName is streaming $name: $details';
        }
        return '$friendName is streaming $name';

      case 2:
        if (name == 'Spotify' && details != null && state != null) {
          return '$friendName is listening to $details by $state on Spotify';
        } else if (name == 'YouTube Music' && details != null) {
          return '$friendName is listening to $details on YouTube Music';
        } else if (details != null) {
          return '$friendName is listening to $details on $name';
        }
        return '$friendName is listening to music on $name';

      case 3:
        if (details != null && details.isNotEmpty) {
          return '$friendName is watching $details on $name';
        }
        return '$friendName is watching something on $name';

      case 4:
        if (details != null && details.isNotEmpty) {
          return '$friendName set their status: $details';
        }
        return '$friendName updated their custom status';

      case 5:
        return '$friendName is competing in $name';

      default:
        return '$friendName is now using $name';
    }
  }

  String? getActivityImageUrl(LanyardActivity activity) {
    if (activity.assets == null) return null;

    if (activity.name == 'Spotify' &&
        activity.assets!.containsKey('large_image')) {
      final String largeImage = activity.assets!['large_image'] as String;
      if (largeImage.startsWith('spotify:')) {
        final String spotifyId = largeImage.replaceFirst('spotify:', '');
        return 'https://i.scdn.co/image/$spotifyId';
      }
    }

    if (activity.assets!.containsKey('large_image')) {
      final String largeImage = activity.assets!['large_image'] as String;

      // Check if it's a Discord CDN asset
      if (largeImage.startsWith('https://')) {
        return largeImage;
      } else if (activity.applicationId != null) {
        return 'https://cdn.discordapp.com/app-assets/${activity.applicationId}/$largeImage.png';
      }
    }

    return null;
  }

  AndroidNotificationDetails getStyledNotificationDetails(
      LanyardActivity activity) {
    if (activity.name == 'Spotify') {
      return const AndroidNotificationDetails(
        'discord_friend_spotify',
        'Discord Friend Music',
        channelDescription:
            'Notifications when Discord friends listen to music',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_stat_name',
        styleInformation: BigTextStyleInformation(''),
        color: Color(0xFF1DB954),
      );
    } else if (activity.type == 0) {
      // Game
      return const AndroidNotificationDetails(
        'discord_friend_gaming',
        'Discord Friend Gaming',
        channelDescription: 'Notifications when Discord friends play games',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_stat_name',
        styleInformation: BigTextStyleInformation(''),
        color: Color(0xFF7289DA),
      );
    } else {
      return const AndroidNotificationDetails(
        'discord_friend_activity',
        'Discord Friend Activity',
        channelDescription:
            'Notifications when Discord friends start new activities',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_stat_name',
        styleInformation: BigTextStyleInformation(''),
      );
    }
  }
}
