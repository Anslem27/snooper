import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:snooper/app/screens/home.dart';

import '../models/discord_friend.dart';
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

    await _notifications.initialize(initSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? permissionGranted =
        await androidPlugin?.requestNotificationsPermission();

    logger.i('Notification permission granted: $permissionGranted');

    await _loadFriends();

    _startMonitoring();

    _initialized = true;

    logger.i("Notifications initialized $_initialized");
  }

  Future<void> _loadFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? friendsJson = prefs.getString('discord_friends');

      if (friendsJson != null) {
        final List<dynamic> decodedJson = json.decode(friendsJson);
        _friends =
            decodedJson.map((item) => DiscordFriend.fromJson(item)).toList();
      }
    } catch (e) {
      logger.f('Error loading friends: $e');
      _friends = [];
    }
  }

  void _startMonitoring() {
    _stopMonitoring();

    for (final friend in _friends) {
      _subscribeToFriend(friend);
    }

    _pollingTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _pollFriendsStatus();
    });

    _pollFriendsStatus();
  }

  void _stopMonitoring() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _subscribeToFriend(DiscordFriend friend) {
    if (_subscriptions.containsKey(friend.id)) {
      return; // Already subscribed
    }

    final stream = _lanyardService.subscribeToUser(friend.id);
    _subscriptions[friend.id] = stream.listen((lanyardUser) {
      _handleUserUpdate(friend, lanyardUser);
    });
  }

  Future<void> _pollFriendsStatus() async {
    if (_friends.isEmpty) return;

    final userIds = _friends.map((f) => f.id).toList();
    final users = await _lanyardService.getUsersByRest(userIds);

    for (final lanyardUser in users) {
      final friendIndex =
          _friends.indexWhere((f) => f.id == lanyardUser.userId);
      if (friendIndex >= 0) {
        _handleUserUpdate(_friends[friendIndex], lanyardUser);
      }
    }
  }

  void _handleUserUpdate(DiscordFriend friend, LanyardUser lanyardUser) {
    final wasOnline = _currentActivities.containsKey(friend.id);
    final String? previousActivity = _currentActivities[friend.id];

    String? currentActivity;
    if (lanyardUser.activities.isNotEmpty) {
      currentActivity = lanyardUser.activities[0].name;
    }

    // Update stored activity
    _currentActivities[friend.id] = currentActivity;

    if (!wasOnline && lanyardUser.online) {
      _showOnlineNotification(friend, currentActivity);
    } else if (lanyardUser.online &&
        previousActivity != currentActivity &&
        currentActivity != null) {
      _showActivityNotification(friend, currentActivity);
    }
  }

  /*  make ntfn */
  Future<void> _showOnlineNotification(
      DiscordFriend friend, String? activity) async {
    const androidDetails = AndroidNotificationDetails(
      'discord_friend_online',
      'Discord Friend Online',
      channelDescription: 'Notifications when Discord friends come online',
      importance: Importance.high,
      priority: Priority.high,
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

    await _notifications.show(
      friend.id.hashCode,
      'Friend Online',
      message,
      details,
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

    await _notifications.show(
      (friend.id + activity).hashCode,
      'Friend Activity',
      message,
      details,
    );
  }

  List<DiscordFriend> getFriends() {
    return List.from(_friends);
  }

  Future<void> showTestNotification() async {
    // Check if initialization is complete first
    if (!_initialized) {
      logger.w('Attempted to show notification before initialization');
      await initialize();
    }

    // Request permission explicitly (especially important for iOS)
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? permissionGranted =
        await androidPlugin?.requestNotificationsPermission();

    logger.i('Notification permission granted: $permissionGranted');

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
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Test Notification',
        'This is a test notification sent at ${DateTime.now().toString()}',
        details,
      );
      logger.i('Test notification sent successfully');
    } catch (e) {
      logger.e('Error showing notification: $e');
    }
  }

  void dispose() {
    _stopMonitoring();
    _lanyardService.dispose();
  }
}
