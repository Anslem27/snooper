import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  bool _isIdSectionExpanded = false;
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
      _showSnackBar('Please enter a valid Discord ID');
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(12),
      ),
    );
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              onPressed: () => _fetchUserData(widget.currentUserId),
            ),
          ],
        ),
      );
    }

    if (_userData == null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.discord_rounded,
              size: 48,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect your Discord profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Click below to set up your Discord connection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect Discord'),
              onPressed: () {
                setState(() {
                  _isIdSectionExpanded = true;
                  _isEditing = true;
                });
              },
            ),
          ],
        ),
      );
    }

    // Extract user data
    final user = _userData!;
    final discordUser = user['discord_user'] ?? {};
    final username = discordUser['username'] ?? 'Unknown User';
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
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.tertiaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),

        // Profile section
        Container(
          padding: const EdgeInsets.all(20),
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
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .shadowColor
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(46),
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 3,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
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
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .shadowColor
                                    .withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: HexColor.fromHex(_getStatusColor(status))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      HexColor.fromHex(_getStatusColor(status)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  color:
                                      HexColor.fromHex(_getStatusColor(status)),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Activities
              if (activities.isNotEmpty && showUserActivitiesInCard) ...[
                Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.5),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.videogame_asset_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ACTIVITIES',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getActivityIcon(activityType),
                                  size: 20,
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
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
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
                                      ),
                                    if (activityState.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
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
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Updating...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Updated just now',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdSection() {
    return AnimatedCrossFade(
      firstChild: InkWell(
        onTap: () {
          setState(() {
            _isIdSectionExpanded = true;
          });
        },
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
               PhosphorIcons.gear(),
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'DISCORD CONNECTION',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const Spacer(),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
      secondChild: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'DISCORD ID',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isEditing
                      ? TextButton.icon(
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Save'),
                          onPressed: _saveUserId,
                        )
                      : TextButton.icon(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit'),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.expand_less_rounded),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  onPressed: () {
                    setState(() {
                      _isIdSectionExpanded = false;
                      _isEditing = false;
                    });
                  },
                  tooltip: 'Hide connection settings',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isEditing
                ? TextField(
                    controller: _userIdController,
                    decoration: InputDecoration(
                      hintText: 'Enter your Discord user ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: const Icon(Icons.numbers_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _userIdController.clear();
                        },
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _saveUserId(),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
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
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        if (widget.currentUserId.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.content_copy_rounded,
                                size: 18),
                            onPressed: () {
                              _showSnackBar('Copied to clipboard');
                            },
                            tooltip: 'Copy ID',
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This ID is used to fetch your Discord activity via the Lanyard API. Your Discord ID must be registered with Lanyard for this to work.',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      crossFadeState: _isIdSectionExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  IconData _getActivityIcon(int activityType) {
    switch (activityType) {
      case 0:
        return Icons.sports_esports_rounded;
      case 1:
        return Icons.live_tv_rounded;
      case 2:
        return Icons.headset_rounded;
      case 3:
        return Icons.movie_rounded;
      case 4:
        return Icons.emoji_emotions_rounded;
      case 5:
        return Icons.emoji_events_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile display
          _buildUserProfile(),

          // Discord ID editor section (collapsible)
          _buildIdSection(),
        ],
      ),
    );
  }
}
