class DiscordFriendV2 {
  final String id;
  final String username;
  final String? avatarUrl;
  bool isOnline;
  String? currentActivity;
  String? previousActivity;
  DateTime? lastOnlineTime;
  DateTime? lastStatusChangeTime;

  DiscordFriendV2({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isOnline = false,
    this.currentActivity,
    this.previousActivity,
    this.lastOnlineTime,
    this.lastStatusChangeTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'currentActivity': currentActivity,
      'lastOnlineTime': lastOnlineTime?.toIso8601String(),
      'lastStatusChangeTime': lastStatusChangeTime?.toIso8601String(),
    };
  }

  factory DiscordFriendV2.fromJson(Map<String, dynamic> json) {
    return DiscordFriendV2(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatarUrl'],
      isOnline: json['isOnline'] ?? false,
      currentActivity: json['currentActivity'],
      lastOnlineTime: json['lastOnlineTime'] != null
          ? DateTime.parse(json['lastOnlineTime'])
          : null,
      lastStatusChangeTime: json['lastStatusChangeTime'] != null
          ? DateTime.parse(json['lastStatusChangeTime'])
          : null,
    );
  }

  // Update friend with Lanyard data
  void updateFromLanyard(LanyardUser lanyardUser) {
    final wasOnline = isOnline;
    final previousActivity = currentActivity;

    isOnline = lanyardUser.online;

    if (lanyardUser.activities.isNotEmpty) {
      currentActivity = lanyardUser.activities.first.name;

      final activity = lanyardUser.activities.first;
      if (activity.details != null) {
        currentActivity = '$currentActivity (${activity.details})';
      } else if (activity.state != null) {
        currentActivity = '$currentActivity (${activity.state})';
      }
    } else {
      currentActivity = null;
    }

    // Track status changes
    final now = DateTime.now();

    if (wasOnline != isOnline) {
      lastStatusChangeTime = now;
      if (isOnline) {
        lastOnlineTime = now;
      }
    }

    if (isOnline && previousActivity != currentActivity) {
      this.previousActivity = previousActivity;
      lastStatusChangeTime = now;
    }
  }
}

/* models */

class LanyardUser {
  final String userId;
  final String? username;
  final String? discriminator;
  final String? avatarUrl;
  final bool online;
  final String? status;
  final List<LanyardActivity> activities;

  LanyardUser({
    required this.userId,
    this.username,
    this.discriminator,
    this.avatarUrl,
    this.online = false,
    this.status,
    this.activities = const [],
  });

  factory LanyardUser.fromJson(Map<String, dynamic> json) {
    final user = json['discord_user'] ?? {};
    final presence = json['discord_status'] ?? 'offline';
    final activitiesJson = json['activities'] as List<dynamic>? ?? [];

    return LanyardUser(
      userId: json['discord_id'] ?? '',
      username: user['username'],
      discriminator: user['discriminator'],
      avatarUrl: user['avatar'] != null
          ? 'https://cdn.discordapp.com/avatars/${json['discord_id']}/${user['avatar']}.png'
          : null,
      online: presence != 'offline',
      status: presence,
      activities: activitiesJson
          .map((activity) => LanyardActivity.fromJson(activity))
          .toList(),
    );
  }
}

class LanyardActivity {
  final String name;
  final String type;
  final String? state;
  final String? details;
  final Map<String, dynamic>? assets;

  LanyardActivity({
    required this.name,
    required this.type,
    this.state,
    this.details,
    this.assets,
  });

  factory LanyardActivity.fromJson(Map<String, dynamic> json) {
    return LanyardActivity(
      name: json['name'] ?? '',
      type: json['type']?.toString() ?? '',
      state: json['state'],
      details: json['details'],
      assets: json['assets'] as Map<String, dynamic>?,
    );
  }
}
