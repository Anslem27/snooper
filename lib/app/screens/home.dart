import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:snooper/app/helpers/native_calls.dart';
import 'package:snooper/app/widgets/activity_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../helpers/logger.dart';
import '../models/discord_friend.dart';
import '../services/lanyard.dart';
import '../services/presence_notifications.dart';
import '../widgets/activity.dart';
import '../widgets/friend_widgets.dart';
import '../widgets/profile_card.dart';
import 'onboard.dart';

final logger = PersistentLogger();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  Map<String, dynamic>? _discordData;
  bool _isLoadingDiscord = true;
  bool _hasDiscordError = false;
  List<DiscordFriend> _friends = [];
  final Map<String, dynamic> _friendsData = {};
  String? _currentUserId;
  bool _isFirstRun = true;

  late TabController _tabController;

  NativeCalls nativeCalls = NativeCalls();
  final LanyardService _lanyardService =
      LanyardService(); // TODO: remove hard coded calls and use this
  final notificationService = NotificationService();

  static const String _debugUserId = "878728452155539537";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedUserId();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('discord_user_id');

    if (savedUserId != null && savedUserId.isNotEmpty) {
      setState(() {
        _currentUserId = savedUserId;
        _isFirstRun = false;
      });

      _fetchDiscordData();
      _startPeriodicRefresh();
    } else {
      if (kDebugMode) {
        setState(() {
          _currentUserId = _debugUserId;
          _isFirstRun = false;
        });

        // Start data fetching with debug ID
        _fetchDiscordData();
        _startPeriodicRefresh();
      } else {
        setState(() {
          _isFirstRun = true;
          _isLoadingDiscord = false;
        });
      }
    }
  }

  Future<void> _fetchDiscordData() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return;
    }

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
      logger.e('Error fetching Discord data: $e');
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
      logger.e('Error fetching friend Discord data: $e');
    }
  }

  Future<void> _handleUserIdChanged(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('discord_user_id', userId);

    setState(() {
      _currentUserId = userId;
      _isFirstRun = false;
    });

    _fetchDiscordData();
  }

  void _handleFriendsChanged(List<DiscordFriend> friends) {
    setState(() {
      _friends = friends;
    });

    _fetchFriendsData();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchDiscordData();
      _fetchFriendsData();
    });
  }

  void _showRefreshIndicator() {
    nativeCalls.showNativeAndroidToast("Refreshing data...", 100);

    _fetchDiscordData();
    _fetchFriendsData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstRun) {
      return _buildOnboardingScreen();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: Text('Snooper'),
                expandedHeight: 120,
                floating: true,
                pinned: true,
                scrolledUnderElevation: 0,
                actions: [
                  if (kDebugMode)
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DiscordOnboardingScreen(
                              onUserIdSubmitted: (id) {},
                            ),
                          ),
                        );
                      },
                      icon: Icon(PhosphorIcons.info()),
                      tooltip: 'Debug Info',
                    ),
                  IconButton(
                    icon: Icon(PhosphorIcons.bell()),
                    onPressed: () async {
                      try {
                        logger.i('Test notification button pressed');
                        await notificationService.showTestNotification();
                      } catch (e) {
                        logger.e('Error in notification button press: $e');
                        // Optionally show a snackbar or toast to the user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Notification error: $e')),
                        );
                      }
                    },
                    tooltip: 'Test Notification',
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.arrowsClockwise()),
                    onPressed: _showRefreshIndicator,
                    tooltip: 'Refresh',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/settings");
                    },
                    icon: Icon(PhosphorIcons.gearFine()),
                    tooltip: 'Settings',
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      icon: Icon(PhosphorIcons.user()),
                      text: 'Your Activity',
                    ),
                    Tab(
                      icon: Icon(PhosphorIcons.users()),
                      text: 'Friends Activity',
                    ),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await _fetchDiscordData();
                },
                child: _buildUserActivityTab(colorScheme),
              ),
              RefreshIndicator(
                onRefresh: () async {
                  await _fetchFriendsData();
                },
                child: _buildFriendsActivityTab(colorScheme),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showRefreshIndicator,
          elevation: 2,
          child: Icon(PhosphorIcons.arrowsClockwise()),
        ),
      ),
    );
  }

  Widget _buildUserActivityTab(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(3.0),
      children: [
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DiscordProfileCard(
              currentUserId: _currentUserId ?? '',
              onUserIdChanged: _handleUserIdChanged,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_currentUserId != null)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: DiscordActivityContainer(userId: _currentUserId!),
          ),
      ],
    );
  }

  Widget _buildFriendsActivityTab(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        FriendsManagement(
          onFriendsChanged: _handleFriendsChanged,
        ),
        const SizedBox(height: 24),
        if (_friends.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              'Friends\' Activities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
          ),
          ..._buildFriendsActivityList(colorScheme),
        ] else if (!_isLoadingDiscord) ...[
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    PhosphorIcons.users(),
                    size: 48,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No friends added yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add friends to see their Discord activity',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildFriendsActivityList(ColorScheme colorScheme) {
    return _friends.map((friend) {
      final friendData = _friendsData[friend.id];
      if (friendData != null) {
        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      radius: 16,
                      child: Text(
                        friend.name.isNotEmpty
                            ? friend.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      friend.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ActivityRenderer(
                  discordData: friendData,
                  username: friend.name,
                ),
              ],
            ),
          ),
        );
      } else {
        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 16),
                Text('Loading data for ${friend.name}...'),
              ],
            ),
          ),
        );
      }
    }).toList();
  }

  Widget _buildOnboardingScreen() {
    return DiscordOnboardingScreen(
      onUserIdSubmitted: _handleUserIdChanged,
    );
  }
}
