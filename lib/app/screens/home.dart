import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:snooper/app/widgets/activity_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/activity.dart';
import '../widgets/drawer.dart';
import '../widgets/friend_widgets.dart';
import '../widgets/user_setting.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _refreshTimer;
  Map<String, dynamic>? _discordData;
  bool _isLoadingDiscord = true;
  bool _hasDiscordError = false;
  List<DiscordFriend> _friends = [];
  final Map<String, dynamic> _friendsData = {};
  String _currentUserId = "878728452155539537"; // Default user ID

  @override
  void initState() {
    super.initState();
    _loadSavedUserId();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('discord_user_id');

    if (savedUserId != null && savedUserId.isNotEmpty) {
      setState(() {
        _currentUserId = savedUserId;
      });
    }

    // Start data fetching after loading the user ID
    _fetchDiscordData();
    _startPeriodicRefresh();
  }

  Future<void> _fetchDiscordData() async {
    setState(() {
      _isLoadingDiscord = true;
      _hasDiscordError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.lanyard.rest/v1/users/$_currentUserId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _discordData = jsonData['data'];
          _isLoadingDiscord = false;
        });
      } else {
        setState(() {
          _isLoadingDiscord = false;
          _hasDiscordError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingDiscord = false;
        _hasDiscordError = true;
      });
      print('Error fetching Discord data: $e');
    }
  }

  Future<void> _fetchFriendsData() async {
    for (var friend in _friends) {
      await _fetchFriendData(friend.id);
    }
  }

  Future<void> _fetchFriendData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.lanyard.rest/v1/users/$userId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _friendsData[userId] = jsonData['data'];
        });
      }
    } catch (e) {
      print('Error fetching friend Discord data: $e');
    }
  }

  void _handleUserIdChanged(String userId) {
    setState(() {
      _currentUserId = userId;
    });

    // Refresh data with new user ID
    _fetchDiscordData();
  }

  void _handleFriendsChanged(List<DiscordFriend> friends) {
    setState(() {
      _friends = friends;
    });

    // Fetch data for each friend
    _fetchFriendsData();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchDiscordData();
      _fetchFriendsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snooper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchDiscordData();
              _fetchFriendsData();
            },
          ),
        ],
      ),
      drawer: const SonnerDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDiscordData();
          await _fetchFriendsData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User Settings component
            DiscordProfileCard(
              currentUserId: _currentUserId,
              onUserIdChanged: _handleUserIdChanged,
            ),

            const SizedBox(height: 16),

            DiscordActivityContainer(userId: _currentUserId),

            const SizedBox(height: 24),

            Text(
              'Discord Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            const SizedBox(height: 24),

            // Friends Management component
            FriendsManagement(
              onFriendsChanged: _handleFriendsChanged,
            ),

            // Display friends' activities
            if (_friends.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Friends\' Activities',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...(_friends.map((friend) {
                final friendData = _friendsData[friend.id];
                if (friendData != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        friend.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      ActivityRenderer(
                        discordData: friendData,
                        username: friend.name,
                      ),
                    ],
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Loading data for ${friend.name}...'),
                  );
                }
              }).toList()),
            ],
          ],
        ),
      ),
    );
  }
}
