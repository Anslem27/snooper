import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snooper/app/screens/home.dart';
import 'dart:convert';

import '../models/discord_friend.dart';
import 'animated_fade.dart';

class FriendsManagement extends StatefulWidget {
  final Function(List<DiscordFriend>) onFriendsChanged;

  const FriendsManagement({
    super.key,
    required this.onFriendsChanged,
  });

  @override
  State<FriendsManagement> createState() => _FriendsManagementState();
}

class _FriendsManagementState extends State<FriendsManagement> {
  List<DiscordFriend> _friends = [];
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isAddingFriend = false;
  bool _isListExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = prefs.getString('discord_friends') ?? '[]';

    try {
      final List<dynamic> friendsList = json.decode(friendsJson);
      setState(() {
        _friends = friendsList
            .map((friend) => DiscordFriend.fromJson(friend))
            .toList();
      });

      // Notify parent about loaded friends
      widget.onFriendsChanged(_friends);
    } catch (e) {
      logger.e('Error loading friends: $e');
    }
  }

  Future<void> _saveFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = json.encode(_friends.map((f) => f.toJson()).toList());
    await prefs.setString('discord_friends', friendsJson);
    widget.onFriendsChanged(_friends);
  }

  void _addFriend() {
    if (_idController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both ID and name'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
      return;
    }

    setState(() {
      _friends.add(
        DiscordFriend(
          id: _idController.text,
          name: _nameController.text,
        ),
      );
      _idController.clear();
      _nameController.clear();
      _isAddingFriend = false;
      _isListExpanded = true;
    });

    _saveFriends();
  }

  void _removeFriend(int index) {
    setState(() {
      _friends.removeAt(index);
    });
    _saveFriends();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.group,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discord Friends',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '${_friends.length} friends',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isListExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isListExpanded = !_isListExpanded;
                    });
                  },
                  tooltip:
                      _isListExpanded ? 'Hide friend list' : 'Show friend list',
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add'),
                  onPressed: () {
                    setState(() {
                      _isAddingFriend = !_isAddingFriend;
                      if (_isAddingFriend) {
                        _isListExpanded = true;
                      }
                    });
                  },
                ),
              ],
            ),
            AnimatedSizeAndFade(
              show: _isAddingFriend,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Friend',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _idController,
                          decoration: InputDecoration(
                            labelText: 'Discord User ID',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon:
                                Icon(Icons.numbers, color: colorScheme.primary),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Friend\'s Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon:
                                Icon(Icons.person, color: colorScheme.primary),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isAddingFriend = false;
                                  _idController.clear();
                                  _nameController.clear();
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: _addFriend,
                              child: const Text('Add Friend'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSizeAndFade(
              show: _isListExpanded && _friends.isNotEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondaryContainer,
                            foregroundColor: colorScheme.onSecondaryContainer,
                            child: Text(
                              friend.name.isNotEmpty
                                  ? friend.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(
                            friend.name,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          subtitle: Text(
                            'ID: ${friend.id}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: colorScheme.error,
                            ),
                            tooltip: 'Remove friend',
                            onPressed: () => _removeFriend(index),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_friends.isEmpty && _isListExpanded) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: (0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.person_search,
                            size: 48,
                            color: colorScheme.primary.withValues(
                              alpha: (0.7),
                            )),
                        const SizedBox(height: 12),
                        Text(
                          'No friends added yet',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add friends to track their Discord activity.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
