import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:snooper/app/screens/home.dart';

import '../models/discord_friend.dart';
import '../models/app_notification.dart';
import '../models/discord_friendv2.dart';
import 'lanyard.dart';

class NotificationService {
  final Map<String, String?> _currentActivities = {};
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final LanyardService _lanyardService = LanyardService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<DiscordFriend> _friends = [];
  final Map<String, StreamSubscription<LanyardUser>> _subscriptions = {};
  Timer? _pollingTimer;
  bool _initialized = false;

  List<AppNotification> _notificationHistory = [];
  final StreamController<List<AppNotification>> _notificationController =
      StreamController<List<AppNotification>>.broadcast();
  Stream<List<AppNotification>> get notificationsStream =>
      _notificationController.stream;

  int get unreadCount => _notificationHistory.where((n) => !n.isRead).length;

  Function(List<DiscordFriend>)? onFriendsChanged;

  Future<void> initialize() async {
    if (_initialized) return;

    const initSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_name');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await _notifications.initialize(
      initSettings,
      // Add onDidReceiveNotificationResponse callback
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        logger.d('Notification interaction: ${response.payload}');
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? permissionGranted =
        await androidPlugin?.requestNotificationsPermission();

    logger.d('Notification permission granted: $permissionGranted');

    await _loadFriends();
    await _loadNotificationHistory();
    await _loadCurrentActivities();

    _startMonitoring();

    _initialized = true;
    logger.d('NotificationService initialized');
  }

  Future<void> _loadCurrentActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? activitiesJson = prefs.getString('current_activities');

      if (activitiesJson != null) {
        final Map<String, dynamic> decodedJson = json.decode(activitiesJson);
        _currentActivities.clear();
        decodedJson.forEach((key, value) {
          _currentActivities[key] = value as String?;
        });
        logger.d('Loaded ${_currentActivities.length} activities from storage');
      } else {
        logger.d('No activities found in storage');
      }
    } catch (e) {
      logger.e('Error loading activities: $e');
      _currentActivities.clear();
    }
  }

  Future<void> _saveCurrentActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'current_activities', json.encode(_currentActivities));
      logger.d('Saved ${_currentActivities.length} activities to storage');
    } catch (e) {
      logger.e('Error saving activities: $e');
    }
  }

  Future<void> _loadFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? friendsJson = prefs.getString('discord_friends');

      if (friendsJson != null) {
        final List<dynamic> decodedJson = json.decode(friendsJson);
        _friends =
            decodedJson.map((item) => DiscordFriend.fromJson(item)).toList();
        logger.d('Loaded ${_friends.length} friends from storage');
      } else {
        logger.d('No friends found in storage');
      }
    } catch (e) {
      logger.e('Error loading friends: $e');
      _friends = [];
    }
  }

  Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString('notification_history');

      if (notificationsJson != null) {
        final List<dynamic> decodedJson = json.decode(notificationsJson);
        _notificationHistory =
            decodedJson.map((item) => AppNotification.fromJson(item)).toList();

        _notificationHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        logger.d(
            'Loaded ${_notificationHistory.length} notifications from storage');

        _notificationController.add(_notificationHistory);
      } else {
        logger.d('No notification history found in storage');
      }
    } catch (e) {
      logger.e('Error loading notification history: $e');
      _notificationHistory = [];
    }
  }

  Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = _notificationHistory.map((n) => n.toJson()).toList();
      await prefs.setString('notification_history', json.encode(jsonData));
      logger.d('Saved ${_notificationHistory.length} notifications to storage');

      _notificationController.add(_notificationHistory);
    } catch (e) {
      logger.e('Error saving notification history: $e');
    }
  }

  void _startMonitoring() {
    _stopMonitoring();

    _pollingTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _pollFriendsStatus();
    });

    _pollFriendsStatus();

    logger.d('Started monitoring ${_friends.length} friends');
  }

  void _stopMonitoring() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _pollingTimer?.cancel();
    _pollingTimer = null;

    logger.d('Stopped monitoring');
  }

  Future<void> _pollFriendsStatus() async {
    if (_friends.isEmpty) {
      logger.d('No friends to poll');
      return;
    }

    logger.d('Polling status for ${_friends.length} friends');
    try {
      final userIds = _friends.map((f) => f.id).toList();
      final users = await _lanyardService.getUsersByRest(userIds);

      logger.d('Received status updates for ${users.length} friends');

      for (final lanyardUser in users) {
        logger.i(lanyardUser.activities
            .map((element) => element.details)
            .join(', '));

        final friendIndex =
            _friends.indexWhere((f) => f.id == lanyardUser.userId);

        _handleUserUpdate(_friends[friendIndex], lanyardUser);
        if (friendIndex >= 0) {
          _handleUserUpdate(_friends[friendIndex], lanyardUser);
        }
      }

      // Save current activities after updates
      await _saveCurrentActivities();
    } catch (e) {
      logger.e('Error polling friend status: $e');
    }
  }

  void _handleUserUpdate(DiscordFriend friend, LanyardUser lanyardUser) {
    logger.f("CALLED");
    // Get previous state information
    final wasOnline = _currentActivities.containsKey(friend.id);
    final String? previousActivity = _currentActivities[friend.id];

    // Get current activity
    String? currentActivity;
    if (lanyardUser.activities.isNotEmpty) {
      currentActivity = lanyardUser.activities[0].name;
    }

    logger.d(
        'Friend update: ${friend.name} - Online: ${lanyardUser.online}, Activity: $currentActivity');

    // CASE 1: Friend was offline and is now online
    if (!wasOnline && lanyardUser.online) {
      logger.d('Friend came online: ${friend.name}');
      _showOnlineNotification(friend, currentActivity);
      _currentActivities[friend.id] = currentActivity;
      return;
    }

    // CASE 2: Friend was online and is now offline
    if (wasOnline && !lanyardUser.online) {
      logger.d('Friend went offline: ${friend.name}');
      // We don't show notification for going offline
      _currentActivities.remove(friend.id);
      return;
    }

    // CASE 3: Friend still online but activity changed
    if (wasOnline &&
        lanyardUser.online &&
        previousActivity != currentActivity) {
      logger.d('Friend activity changed: ${friend.name} - $currentActivity');
      _showActivityNotification(friend, currentActivity ?? 'online');
      _currentActivities[friend.id] = currentActivity;
      return;
    }

    // Update the status map if online, but don't notify (no relevant change)
    if (lanyardUser.online) {
      _currentActivities[friend.id] = currentActivity;
    } else {
      _currentActivities.remove(friend.id);
    }
  }

  Future<void> _showOnlineNotification(
      DiscordFriend friend, String? activity) async {
    const androidDetails = AndroidNotificationDetails(
      'discord_friend_online',
      'Discord Friend Online',
      channelDescription: 'Notifications when Discord friends come online',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_stat_name',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    String message = '${friend.name} is now online';
    if (activity != null) {
      message += ' playing $activity';
    }

    // Create and store notification history entry
    final notification = AppNotification(
      id: '${friend.id}_online_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Friend Online',
      message: message,
      timestamp: DateTime.now(),
      friendId: friend.id,
      activityName: activity,
      type: NotificationType.friendOnline,
    );

    _notificationHistory.add(notification);
    await _saveNotificationHistory();

    // Add notification payload
    final payload = '{"friend_id": "${friend.id}", "type": "online"}';

    logger.d('Showing online notification for ${friend.name}');
    await _notifications.show(
      friend.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: payload,
    );
  }

  Future<void> _showActivityNotification(
      DiscordFriend friend, String activity) async {
    const androidDetails = AndroidNotificationDetails(
      'discord_friend_activity',
      'Discord Friend Activity',
      channelDescription:
          'Notifications when Discord friends start new activities',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@drawable/ic_stat_name',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    String message = '${friend.name} is now $activity';

    // Create and store notification history entry
    final notification = AppNotification(
      id: '${friend.id}_activity_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Friend Activity',
      message: message,
      timestamp: DateTime.now(),
      friendId: friend.id,
      activityName: activity,
      type: NotificationType.friendActivity,
    );

    _notificationHistory.add(notification);
    await _saveNotificationHistory();

    // Add notification payload
    final payload =
        '{"friend_id": "${friend.id}", "activity": "$activity", "type": "activity"}';

    logger.d('Showing activity notification for ${friend.name}: $activity');
    await _notifications.show(
      (friend.id + activity).hashCode,
      notification.title,
      notification.message,
      details,
      payload: payload,
    );
  }

  Future<void> updateFriends(List<DiscordFriend> friends) async {
    _friends = List.from(friends);

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = _friends.map((f) => f.toJson()).toList();
      await prefs.setString('discord_friends', json.encode(jsonData));
      logger.d('Saved ${_friends.length} friends to storage');
    } catch (e) {
      logger.e('Error saving friends: $e');
    }

    _startMonitoring();

    if (onFriendsChanged != null) {
      onFriendsChanged!(_friends);
    }
  }

  // Method to manually check status (can be called from UI)
  Future<void> checkStatusNow() async {
    logger.d('Manual status check requested');
    await _pollFriendsStatus();
  }

  List<DiscordFriend> getFriends() {
    return List.from(_friends);
  }

  List<AppNotification> getNotifications() {
    return List.from(_notificationHistory);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final index =
        _notificationHistory.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notificationHistory[index].isRead = true;
      await _saveNotificationHistory();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    for (var notification in _notificationHistory) {
      notification.isRead = true;
    }
    await _saveNotificationHistory();
  }

  Future<void> removeNotification(String notificationId) async {
    final index =
        _notificationHistory.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notificationHistory.removeAt(index);
      await _saveNotificationHistory();
    }
  }

  Future<void> clearNotificationHistory() async {
    _notificationHistory.clear();
    await _saveNotificationHistory();
  }

  void dispose() {
    _stopMonitoring();
    _lanyardService.dispose();
    _notificationController.close();
  }
}
/* 
 Future<void> showTestNotification() async {
    if (!_initialized) {
      logger.w('Attempted to show notification before initialization');
      await initialize();
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? permissionGranted =
        await androidPlugin?.requestNotificationsPermission();

    logger.d('Notification permission granted: $permissionGranted');

    const androidDetails = AndroidNotificationDetails(
      'test_notification_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_stat_name',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      enableLights: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final message =
          'This is a test notification sent at ${DateTime.now().toString()}';

      final notification = AppNotification(
        id: 'test_$notificationId',
        title: 'Test Notification',
        message: message,
        timestamp: DateTime.now(),
        type: NotificationType.test,
      );

      _notificationHistory.add(notification);
      await _saveNotificationHistory();

      await _notifications.show(
        notificationId,
        notification.title,
        notification.message,
        details,
      );

      logger.i('Test notification sent successfully');
    } catch (e) {
      logger.e('Error showing notification: $e');
    }
  }
 */
