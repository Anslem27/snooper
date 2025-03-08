import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snooper/app/screens/home.dart';
import 'dart:convert';

import '../models/discord_friend.dart';

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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
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
                Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Discord Friends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Friend'),
                  onPressed: () {
                    setState(() {
                      _isAddingFriend = !_isAddingFriend;
                    });
                  },
                ),
              ],
            ),
            if (_isAddingFriend) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'Discord User ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Friend\'s Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isAddingFriend = false;
                        _idController.clear();
                        _nameController.clear();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addFriend,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
            if (_friends.isEmpty && !_isAddingFriend) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No friends added yet. Add friends to track their Discord activity.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (_friends.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(friend.name),
                    subtitle: Text('ID: ${friend.id}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeFriend(index),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
