import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/hex_color.dart';

class DiscordProfileCard extends StatefulWidget {
  final Function(String) onUserIdChanged;
  final String currentUserId;

  const DiscordProfileCard({
    super.key,
    required this.onUserIdChanged,
    required this.currentUserId,
  });

  @override
  State createState() => _DiscordProfileCardState();
}

class _DiscordProfileCardState extends State<DiscordProfileCard> {
  late TextEditingController _userIdController;
  bool _isEditing = false;
  bool _isLoading = false;
  bool showUserActivitiesInCard = false;
  bool showBanner = false;
  Map<String, dynamic>? _userData;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController(text: widget.currentUserId);
    _loadCachedUserData();
    if (widget.currentUserId.isNotEmpty) {
      _fetchUserData(widget.currentUserId);
    }
  }

  @override
  void didUpdateWidget(DiscordProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUserId != oldWidget.currentUserId) {
      _fetchUserData(widget.currentUserId);
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('discord_user_data');
    final cachedUserId = prefs.getString('discord_user_id') ?? '';

    if (cachedData != null && cachedUserId == widget.currentUserId) {
      setState(() {
        _userData = jsonDecode(cachedData);
      });
    }
  }

  Future<void> _fetchUserData(String userId) async {
    if (userId.isEmpty) {
      setState(() {
        _userData = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.lanyard.rest/v1/users/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final userData = data['data'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('discord_user_data', jsonEncode(userData));

          setState(() {
            _userData = userData;
            _isLoading = false;
          });

          _refreshTimer?.cancel();
          _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
            if (mounted) _fetchUserData(userId);
          });
        } else {
          setState(() {
            _errorMessage = 'Error fetching user data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'User not found or API error';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserId() async {
    final newId = _userIdController.text.trim();
    if (newId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid Discord ID'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('discord_user_id', newId);
    widget.onUserIdChanged(newId);

    setState(() {
      _isEditing = false;
    });

    // Fetch new user data after ID change
    _fetchUserData(newId);
  }

  String _getStatusColor(String? status) {
    switch (status) {
      case 'online':
        return '#43b581';
      case 'idle':
        return '#faa61a';
      case 'dnd':
        return '#f04747';
      default:
        return '#747f8d'; // offline or invisible
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'online':
        return 'Online';
      case 'idle':
        return 'Idle';
      case 'dnd':
        return 'Do Not Disturb';
      default:
        return 'Offline';
    }
  }

  Widget _buildUserProfile() {
    if (_isLoading && _userData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () => _fetchUserData(widget.currentUserId),
            ),
          ],
        ),
      );
    }

    if (_userData == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.person_outline,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your Discord ID to view your profile',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Extract user data
    final user = _userData!;
    final discordUser = user['discord_user'] ?? {};
    final username = discordUser['username'] ?? 'Unknown User';
    // final discriminator = discordUser['discriminator'] ?? '0000';
    final avatarHash = discordUser['avatar'] ?? '';
    final status = user['discord_status'] ?? 'offline';
    final activities = (user['activities'] as List?) ?? [];

    // Build avatar URL
    String avatarUrl = 'https://cdn.discordapp.com/embed/avatars/0.png';
    if (avatarHash.isNotEmpty) {
      final userId = discordUser['id'] ?? widget.currentUserId;
      avatarUrl =
          'https://cdn.discordapp.com/avatars/$userId/$avatarHash.png?size=128';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User banner
        if (showBanner)
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),

        // Profile section
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar and basic info
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar with status indicator
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(46),
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: HexColor.fromHex(_getStatusColor(status)),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Username and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            color: HexColor.fromHex(_getStatusColor(status)),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Activities
              if (activities.isNotEmpty && showUserActivitiesInCard) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVITIES',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...activities.take(2).map((activity) {
                        final activityName =
                            activity['name'] ?? 'Unknown Activity';
                        final activityType = activity['type'] ?? 0;
                        final activityDetails = activity['details'] ?? '';
                        final activityState = activity['state'] ?? '';

                        String activityTypeText = '';
                        switch (activityType) {
                          case 0:
                            activityTypeText = 'Playing';
                            break;
                          case 1:
                            activityTypeText = 'Streaming';
                            break;
                          case 2:
                            activityTypeText = 'Listening to';
                            break;
                          case 3:
                            activityTypeText = 'Watching';
                            break;
                          case 4:
                            activityTypeText = 'Custom Status:';
                            break;
                          case 5:
                            activityTypeText = 'Competing in';
                            break;
                          default:
                            activityTypeText = '';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getActivityIcon(activityType),
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style:
                                            DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: '$activityTypeText ',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: activityName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (activityDetails.isNotEmpty)
                                      Text(
                                        activityDetails,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (activityState.isNotEmpty)
                                      Text(
                                        activityState,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              // Last updated indicator
              Align(
                alignment: Alignment.centerRight,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Last updated just now',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(int activityType) {
    switch (activityType) {
      case 0:
        return Icons.sports_esports;
      case 1:
        return Icons.live_tv;
      case 2:
        return Icons.headset;
      case 3:
        return Icons.movie;
      case 4:
        return Icons.emoji_emotions;
      case 5:
        return Icons.emoji_events;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile display
          _buildUserProfile(),

          // Discord ID editor section
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DISCORD ID',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    _isEditing
                        ? TextButton(
                            onPressed: _saveUserId,
                            child: const Text('Save'),
                          )
                        : IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            tooltip: 'Edit Discord ID',
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                _isEditing
                    ? TextField(
                        controller: _userIdController,
                        decoration: InputDecoration(
                          hintText: 'Enter your Discord user ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _userIdController.clear();
                            },
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (_) => _saveUserId(),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.currentUserId.isEmpty
                                  ? 'Not set'
                                  : widget.currentUserId,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ),
                          if (widget.currentUserId.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.content_copy, size: 16),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied to clipboard'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin: EdgeInsets.all(10),
                                  ),
                                );
                              },
                              tooltip: 'Copy ID',
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'This ID is used to fetch your Discord activity via Lanyard API',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
