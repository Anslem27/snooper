class DiscordFriend {
  final String id;
  final String name;

  DiscordFriend({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory DiscordFriend.fromJson(Map<String, dynamic> json) {
    return DiscordFriend(
      id: json['id'],
      name: json['name'],
    );
  }
}
