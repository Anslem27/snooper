import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:snooper/app/screens/home.dart';

import '../models/discord_friendv2.dart';

class LanyardService {
  static const String _apiBaseUrl = 'https://api.lanyard.rest/v1';

  // Singleton pattern
  static final LanyardService _instance = LanyardService._internal();
  factory LanyardService() => _instance;
  LanyardService._internal();

  final Map<String, StreamController<LanyardUser>> _userControllers = {};
  Timer? _pollingTimer;

  Future<LanyardUser?> getUserByRest(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/users/$userId'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return LanyardUser.fromJson(jsonData['data']);
        }
      }
      return null;
    } catch (e) {
      logger.e('Error fetching user data: $e');
      return null;
    }
  }

  Future<List<LanyardUser>> getUsersByRest(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final response =
          await http.get(Uri.parse('$_apiBaseUrl/users/${userIds.join(",")}'));

      logger.i(response.body);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final Map<String, dynamic> usersData = jsonData['data'];
          return usersData.entries
              .map((entry) => LanyardUser.fromJson(entry.value))
              .toList();
        }
      }
      return [];
    } catch (e) {
      logger.e('Error fetching users data: $e');
      return [];
    }
  }

  Stream<LanyardUser> subscribeToUser(String userId) {
    if (!_userControllers.containsKey(userId)) {
      _userControllers[userId] = StreamController<LanyardUser>.broadcast();

      if (_pollingTimer == null) {
        _startPolling();
      }
    }

    _pollUser(userId);

    return _userControllers[userId]!.stream;
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _pollAllUsers();
    });
  }

  Future<void> _pollAllUsers() async {
    if (_userControllers.isEmpty) return;

    final userIds = _userControllers.keys.toList();
    final users = await getUsersByRest(userIds);

    for (final user in users) {
      if (_userControllers.containsKey(user.userId)) {
        _userControllers[user.userId]?.add(user);
      }
    }
  }

  Future<void> _pollUser(String userId) async {
    final user = await getUserByRest(userId);
    if (user != null && _userControllers.containsKey(userId)) {
      _userControllers[userId]?.add(user);
    }
  }

  void unsubscribeFromUser(String userId) {
    if (_userControllers.containsKey(userId)) {
      _userControllers[userId]?.close();
      _userControllers.remove(userId);

      // If no more subscriptions, stop polling
      if (_userControllers.isEmpty) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
      }
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;

    for (final controller in _userControllers.values) {
      controller.close();
    }
    _userControllers.clear();
  }
}

