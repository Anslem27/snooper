import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/discord_friendv2.dart';
import 'lanyard.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final LanyardService _lanyardService = LanyardService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<DiscordFriendV2> _friends = [];
  final Map<String, StreamSubscription<LanyardUser>> _subscriptions = {};
  Timer? _pollingTimer;
  bool _initialized = false;

  Function(List<DiscordFriendV2>)? onFriendsChanged;

  // Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize notifications
    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    await _loadFriends();

    // Start monitoring
    _startMonitoring();

    _initialized = true;
  }

  // Load friends from SharedPreferences
  Future<void> _loadFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? friendsJson = prefs.getString('discord_friends');

      if (friendsJson != null) {
        final List<dynamic> decodedJson = json.decode(friendsJson);
        _friends =
            decodedJson.map((item) => DiscordFriendV2.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading friends: $e');
      _friends = [];
    }
  }

  // Save friends to SharedPreferences
  Future<void> _saveFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = json.encode(_friends.map((f) => f.toJson()).toList());
      await prefs.setString('discord_friends', friendsJson);

      if (onFriendsChanged != null) {
        onFriendsChanged!(_friends);
      }
    } catch (e) {
      print('Error saving friends: $e');
    }
  }

  // Start monitoring friends
  void _startMonitoring() {
    // Cancel any existing subscriptions
    _stopMonitoring();

    // Set up WebSocket subscriptions for each friend
    for (final friend in _friends) {
      _subscribeToFriend(friend);
    }

    // Also set up a polling fallback every 2 minutes
    _pollingTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _pollFriendsStatus();
    });

    // Immediate poll
    _pollFriendsStatus();
  }

  // Stop monitoring
  void _stopMonitoring() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel polling timer
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Subscribe to real-time updates for a friend
  void _subscribeToFriend(DiscordFriendV2 friend) {
    if (_subscriptions.containsKey(friend.id)) {
      return; // Already subscribed
    }

    final stream = _lanyardService.subscribeToUser(friend.id);
    _subscriptions[friend.id] = stream.listen((lanyardUser) {
      _handleUserUpdate(friend, lanyardUser);
    });
  }

  // Poll friends status using REST API
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

  // Handle user updates from either WebSocket or REST
  void _handleUserUpdate(DiscordFriendV2 friend, LanyardUser lanyardUser) {
    final wasOnline = friend.isOnline;
    final previousActivity = friend.currentActivity;

    // Update friend with new data
    friend.updateFromLanyard(lanyardUser);

    // Check if we need to show notifications
    if (!wasOnline && friend.isOnline) {
      // Friend came online
      _showOnlineNotification(friend);
    } else if (friend.isOnline &&
        previousActivity != friend.currentActivity &&
        friend.currentActivity != null) {
      // Friend started a new activity
      _showActivityNotification(friend);
    }

    // Save updated friends list
    _saveFriends();
  }

  Future<void> _showOnlineNotification(DiscordFriendV2 friend) async {
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

    String message = '${friend.username} is now online';
    if (friend.currentActivity != null) {
      message += ' playing ${friend.currentActivity}';
    }

    await _notifications.show(
      friend.id.hashCode,
      'Friend Online',
      message,
      details,
    );
  }

  Future<void> _showActivityNotification(DiscordFriendV2 friend) async {
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

    String message = '${friend.username} is now ${friend.currentActivity}';

    await _notifications.show(
      (friend.id + friend.currentActivity!).hashCode,
      'Friend Activity',
      message,
      details,
    );
  }

  Future<void> addFriend(DiscordFriendV2 friend) async {
    if (_friends.any((f) => f.id == friend.id)) {
      return;
    }

    _friends.add(friend);
    await _saveFriends();

    _subscribeToFriend(friend);

    final lanyardUser = await _lanyardService.getUserByRest(friend.id);
    if (lanyardUser != null) {
      _handleUserUpdate(friend, lanyardUser);
    }
  }

  Future<void> removeFriend(String friendId) async {
    final friendIndex = _friends.indexWhere((f) => f.id == friendId);
    if (friendIndex >= 0) {
      _friends.removeAt(friendIndex);
      await _saveFriends();

      if (_subscriptions.containsKey(friendId)) {
        _subscriptions[friendId]?.cancel();
        _subscriptions.remove(friendId);
        _lanyardService.unsubscribeFromUser(friendId);
      }
    }
  }

  List<DiscordFriendV2> getFriends() {
    return List.from(_friends);
  }

  void dispose() {
    _stopMonitoring();
    _lanyardService.dispose();
  }
}
