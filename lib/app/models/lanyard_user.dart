import 'package:snooper/app/screens/home.dart';

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
    final user = json['discord_user'] as Map<String, dynamic>? ?? {};
    final presence = json['discord_status'] ?? 'offline';
    final data = json;

    List<dynamic> activitiesJson =
        data['activities'] is List ? data['activities'] as List<dynamic> : [];

    return LanyardUser(
      userId: user['id'] ?? 'N/A',
      username: user['username'],
      discriminator: user['discriminator'],
      avatarUrl: user['avatar'] != null
          ? 'https://cdn.discordapp.com/avatars/${user['id']}/${user['avatar']}.png'
          : null,
      online: presence != 'offline',
      status: presence,
      activities: activitiesJson
          .map((activity) => LanyardActivity.fromJson(activity))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'LanyardUser(userId: $userId, username: $username, activities.length: ${activities.length})';
  }
}

class LanyardActivity {
  final String name;
  final int type;
  final String? details;
  final String? state;
  final String? applicationId;
  final Map<String, dynamic>? assets;
  final DateTime createdAt;

  LanyardActivity({
    required this.name,
    required this.type,
    this.details,
    this.state,
    this.applicationId,
    this.assets,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LanyardActivity.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at']);
      } catch (e) {
        logger.e('Error parsing created_at for lanyard Activity: $e');
      }
    }

    return LanyardActivity(
      name: json['name'] ?? 'Unknown',
      type: json['type'] ?? 0,
      details: json['details'],
      state: json['state'],
      applicationId: json['application_id'],
      assets: json['assets'] is Map
          ? Map<String, dynamic>.from(json['assets'])
          : null,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'LanyardActivity(name: $name, type: $type, details: $details, state: $state)';
  }
}
