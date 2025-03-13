import '../services/lanyard.dart';

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
