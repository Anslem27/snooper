enum NotificationType { friendOnline, friendActivity, system, test }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? friendId;
  final String? activityName;
  final NotificationType type;
  final String? imageUrl;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.friendId,
    this.activityName,
    required this.type,
    this.imageUrl,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'friendId': friendId,
      'activityName': activityName,
      'type': type.index,
      'imageUrl': imageUrl,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      friendId: json['friendId'],
      activityName: json['activityName'],
      type: NotificationType.values[json['type'] ?? 0],
      imageUrl: json['imageUrl'],
      isRead: json['isRead'] ?? false,
    );
  }
}
