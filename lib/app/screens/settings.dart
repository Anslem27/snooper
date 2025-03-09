import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/discord_friend.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _discordIdController = TextEditingController();
  List<DiscordFriend> _friends = [];
  bool _isDarkMode = false;
  bool _isAmoledDark = false;
  bool _useSystemTheme = true;
  Color _customColor = Colors.deepPurple;
  bool _useCustomColor = false;
  bool _syncDataInBackground = true;
  int _syncInterval = 15; // in minutes
  bool _notificationsEnabled = true;
  bool _showStatusChanges = true;
  bool _showGameChanges = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _discordIdController.text = prefs.getString('discord_user_id') ?? '';
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _isAmoledDark = prefs.getBool('amoled_dark') ?? false;
      _useSystemTheme = prefs.getBool('use_system_theme') ?? true;
      _useCustomColor = prefs.getBool('use_custom_color') ?? false;
      _customColor =
          Color(prefs.getInt('custom_color') ?? Colors.deepPurple.value);
      _syncDataInBackground = prefs.getBool('sync_data_in_background') ?? true;
      _syncInterval = prefs.getInt('sync_interval') ?? 15;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _showStatusChanges = prefs.getBool('show_status_changes') ?? true;
      _showGameChanges = prefs.getBool('show_game_changes') ?? true;

      // Load friends
      final friendsJson = prefs.getString('discord_friends');
      if (friendsJson != null) {
        final friendsList = json.decode(friendsJson) as List;
        _friends = friendsList.map((f) => DiscordFriend.fromJson(f)).toList();
      }
    });
  }

  Future<void> _saveDiscordId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('discord_user_id', _discordIdController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Discord ID updated')),
    );
  }

  Future<void> _saveFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = json.encode(_friends.map((f) => f.toJson()).toList());
    await prefs.setString('discord_friends', friendsJson);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friends list updated')),
    );
  }

  Future<void> _saveThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setBool('amoled_dark', _isAmoledDark);
    await prefs.setBool('use_system_theme', _useSystemTheme);
    await prefs.setBool('use_custom_color', _useCustomColor);
    await prefs.setInt('custom_color', _customColor.value);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme settings updated')),
    );
  }

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('show_status_changes', _showStatusChanges);
    await prefs.setBool('show_game_changes', _showGameChanges);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings updated')),
    );
  }

  Future<void> _saveSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_data_in_background', _syncDataInBackground);
    await prefs.setInt('sync_interval', _syncInterval);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync settings updated')),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _customColor,
              onColorChanged: (Color color) {
                setState(() => _customColor = color);
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              showLabel: true,
              paletteType: PaletteType.hsv,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveThemeSettings();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  void _addFriend() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Discord Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Discord ID',
                hintText: 'Enter Discord ID',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter display name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (idController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                setState(() {
                  _friends.add(DiscordFriend(
                    id: idController.text,
                    name: nameController.text,
                  ));
                });
                _saveFriends();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editFriend(int index) {
    final TextEditingController idController =
        TextEditingController(text: _friends[index].id);
    final TextEditingController nameController =
        TextEditingController(text: _friends[index].name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Discord Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'Discord ID',
                hintText: 'Enter Discord ID',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter display name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (idController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                setState(() {
                  _friends[index] = DiscordFriend(
                    id: idController.text,
                    name: nameController.text,
                  );
                });
                _saveFriends();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
      body: ListView(
        children: [
          // Account Settings
          _buildSectionHeader(context, 'Account', Icons.person),
          ListTile(
            title: const Text('Discord User ID'),
            subtitle: Text(_discordIdController.text.isEmpty
                ? 'Not set'
                : 'ID: ${_discordIdController.text}'),
            leading: const Icon(Icons.discord),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Update Discord ID'),
                  content: TextField(
                    controller: _discordIdController,
                    decoration: const InputDecoration(
                      labelText: 'Discord ID',
                      hintText: 'Enter your Discord ID',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _saveDiscordId();
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // Friends Management
          _buildSectionHeader(context, 'Discord Friends', Icons.people),
          for (int i = 0; i < _friends.length; i++)
            ListTile(
              title: Text(_friends[i].name),
              subtitle: Text('ID: ${_friends[i].id}'),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Text(
                  _friends[i].name[0].toUpperCase(),
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editFriend(i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _friends.removeAt(i);
                      });
                      _saveFriends();
                    },
                  ),
                ],
              ),
            ),
          ListTile(
            title: const Text('Add Friend'),
            leading: const Icon(Icons.person_add),
            onTap: _addFriend,
          ),
          const Divider(),

          // Appearance
          _buildSectionHeader(context, 'Appearance', Icons.palette),
          SwitchListTile(
            title: const Text('Use System Theme'),
            subtitle: const Text('Follow device theme settings'),
            value: _useSystemTheme,
            onChanged: (value) {
              setState(() {
                _useSystemTheme = value;
              });
              _saveThemeSettings();
            },
          ),
          if (!_useSystemTheme)
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                _saveThemeSettings();
              },
            ),
          if (_isDarkMode)
            SwitchListTile(
              title: const Text('AMOLED Dark Mode'),
              subtitle: const Text('Pure black background for OLED screens'),
              value: _isAmoledDark,
              onChanged: (value) {
                setState(() {
                  _isAmoledDark = value;
                });
                _saveThemeSettings();
              },
            ),
          SwitchListTile(
            title: const Text('Use Custom Color'),
            value: _useCustomColor,
            onChanged: (value) {
              setState(() {
                _useCustomColor = value;
              });
              _saveThemeSettings();
            },
          ),
          if (_useCustomColor)
            ListTile(
              title: const Text('Custom Theme Color'),
              subtitle: const Text('Choose a theme color'),
              leading: CircleAvatar(
                backgroundColor: _customColor,
              ),
              onTap: _showColorPicker,
            ),
          const Divider(),

          // Notifications
          _buildSectionHeader(context, 'Notifications', Icons.notifications),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveNotificationSettings();
            },
          ),
          if (_notificationsEnabled) ...[
            SwitchListTile(
              title: const Text('Status Changes'),
              subtitle: const Text('Notify when friends change status'),
              value: _showStatusChanges,
              onChanged: (value) {
                setState(() {
                  _showStatusChanges = value;
                });
                _saveNotificationSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Game Activity'),
              subtitle: const Text('Notify when friends start playing games'),
              value: _showGameChanges,
              onChanged: (value) {
                setState(() {
                  _showGameChanges = value;
                });
                _saveNotificationSettings();
              },
            ),
          ],
          const Divider(),

          // Sync Settings
          _buildSectionHeader(context, 'Sync Settings', Icons.sync),
          SwitchListTile(
            title: const Text('Background Sync'),
            subtitle: const Text('Sync data when app is in background'),
            value: _syncDataInBackground,
            onChanged: (value) {
              setState(() {
                _syncDataInBackground = value;
              });
              _saveSyncSettings();
            },
          ),
          if (_syncDataInBackground)
            ListTile(
              title: const Text('Sync Interval'),
              subtitle: Text('$_syncInterval minutes'),
              leading: const Icon(Icons.timer),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sync Interval'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('How often should we sync data?'),
                        Slider(
                          value: _syncInterval.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: '$_syncInterval minutes',
                          onChanged: (value) {
                            setState(() {
                              _syncInterval = value.round();
                            });
                          },
                        ),
                        Text(
                          '$_syncInterval minutes',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _saveSyncSettings();
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
            ),
          const Divider(),

          // About
          _buildSectionHeader(context, 'About', Icons.info),
          ListTile(
            title: const Text('About Snooper'),
            subtitle: const Text(
                'Track your Discord activity and share it with friends'),
            leading: const Icon(Icons.discord),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Snooper',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.discord,
                  color: colorScheme.primary,
                  size: 48,
                ),
                children: [
                  const Text(
                    'Snooper lets you track your Discord activity and share it with friends. '
                    'Keep up with what your friends are playing and their online status.',
                  ),
                ],
              );
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () {
              // Navigate to privacy policy page
            },
          ),
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.gavel),
            onTap: () {
              // Navigate to terms of service page
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _discordIdController.dispose();
    super.dispose();
  }
}
