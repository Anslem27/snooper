import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class LanyardService {
  static const String _apiBaseUrl = 'https://api.lanyard.rest/v1';
  static const String _wsUrl = 'wss://api.lanyard.rest/socket';

  WebSocketChannel? _wsChannel;
  Timer? _heartbeatTimer;
  final Map<String, StreamController<LanyardUser>> _userControllers = {};

  // Singleton pattern
  static final LanyardService _instance = LanyardService._internal();

  factory LanyardService() {
    return _instance;
  }

  LanyardService._internal();

  // REST API methods
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
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<List<LanyardUser>> getUsersByRest(List<String> userIds) async {
    try {
      final response =
          await http.get(Uri.parse('$_apiBaseUrl/users/${userIds.join(",")}'));

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
      print('Error fetching users data: $e');
      return [];
    }
  }

  // WebSocket API methods
  void _connectWebSocket() {
    _wsChannel = WebSocketChannel.connect(Uri.parse(_wsUrl));

    _wsChannel!.stream.listen(
      (message) {
        final data = json.decode(message);
        final op = data['op'];

        switch (op) {
          case 1:
            // Start heartbeating
            final heartbeatInterval = data['d']['heartbeat_interval'] as int;
            _startHeartbeat(heartbeatInterval);

            // Identify/Subscribe to users
            _subscribeToUsers();
            break;

          case 0: // Event dispatch
            _handleEventDispatch(data);
            break;
        }
      },
      onDone: _reconnect,
      onError: (error) {
        print('WebSocket error: $error');
        _reconnect();
      },
    );
  }

  void _startHeartbeat(int interval) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      _wsChannel?.sink.add(json.encode({'op': 3}));
    });
  }

  void _subscribeToUsers() {
    if (_userControllers.isNotEmpty) {
      _wsChannel?.sink.add(json.encode({
        'op': 2, // Identify
        'd': {
          'subscribe_to_ids': _userControllers.keys.toList(),
        }
      }));
    }
  }

  void _handleEventDispatch(Map<String, dynamic> data) {
    final eventType = data['t'];
    final eventData = data['d'];

    if (eventType == 'PRESENCE_UPDATE') {
      final userId = eventData['discord_id'];
      if (_userControllers.containsKey(userId)) {
        final user = LanyardUser.fromJson(eventData);
        _userControllers[userId]?.add(user);
      }
    }
  }

  void _reconnect() {
    _wsChannel?.sink.close();
    _heartbeatTimer?.cancel();

    // Attempt to reconnect after a delay
    Future.delayed(Duration(seconds: 5), () {
      if (_userControllers.isNotEmpty) {
        _connectWebSocket();
      }
    });
  }

  // Public API for streaming user data
  Stream<LanyardUser> subscribeToUser(String userId) {
    if (!_userControllers.containsKey(userId)) {
      _userControllers[userId] = StreamController<LanyardUser>.broadcast();

      // If this is the first subscription, connect to WebSocket
      if (_wsChannel == null || _wsChannel!.closeCode != null) {
        _connectWebSocket();
      } else {
        // Otherwise, just subscribe to the new user
        _wsChannel?.sink.add(json.encode({
          'op': 2,
          'd': {
            'subscribe_to_id': userId,
          }
        }));
      }
    }

    return _userControllers[userId]!.stream;
  }

  void unsubscribeFromUser(String userId) {
    if (_userControllers.containsKey(userId)) {
      // Unsubscribe on server side
      _wsChannel?.sink.add(json.encode({
        'op': 4,
        'd': {
          'unsubscribe_from_id': userId,
        }
      }));

      // Close and remove the controller
      _userControllers[userId]?.close();
      _userControllers.remove(userId);

      // If no more subscriptions, close connection
      if (_userControllers.isEmpty) {
        _wsChannel?.sink.close();
        _heartbeatTimer?.cancel();
        _wsChannel = null;
        _heartbeatTimer = null;
      }
    }
  }

  void dispose() {
    _wsChannel?.sink.close();
    _heartbeatTimer?.cancel();
    for (final controller in _userControllers.values) {
      controller.close();
    }
    _userControllers.clear();
    _wsChannel = null;
    _heartbeatTimer = null;
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
