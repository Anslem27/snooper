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
    // Ensure we're handling null values properly
    return LanyardActivity(
      name: json['name'] ?? '',
      // Convert type to int, as Discord uses numeric activity types
      type: json['type'] is int
          ? json['type']
          : int.tryParse(json['type']?.toString() ?? '0') ?? 0,
      state: json['state'],
      details: json['details'],
      assets: json['assets'] as Map<String, dynamic>?,
    );
  }

  // Debug helper
  String toString() {
    return 'LanyardActivity(name: $name, type: $type, state: $state, details: $details)';
  }
}

// Example usage to debug the API response
void debugLanyardResponse(Map<String, dynamic> jsonResponse) {
  print('Full JSON response: $jsonResponse');

  // Check if activities exist directly in the response
  if (jsonResponse.containsKey('activities')) {
    print(
        'Activities found directly in the response: ${jsonResponse['activities']}');
  }

  // Check if activities exist in a data object
  if (jsonResponse.containsKey('data') &&
      jsonResponse['data'] is Map &&
      jsonResponse['data'].containsKey('activities')) {
    print(
        'Activities found in data object: ${jsonResponse['data']['activities']}');
  }

  // Create the user object
  final user = LanyardUser.fromJson(jsonResponse);
  print('Parsed LanyardUser: $user');
}
