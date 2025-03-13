import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:snooper/app/helpers/native_calls.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snooper/app/providers/theme_provider.dart';
import 'package:snooper/app/screens/home.dart';
import 'package:snooper/app/screens/logs.dart';

import '../../models/discord_friend.dart';
import '../../models/settings_elements.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/presence_notifications.dart';
import '../user_data.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _discordIdController = TextEditingController();
  List<DiscordFriend> _friends = [];
  Color _customColor = Colors.deepPurple;
  bool _useCustomColor = false;
  bool _syncDataInBackground = true;
  int _syncInterval = 15; // in minutes
  bool _notificationsEnabled = true;
  bool _showStatusChanges = true;
  bool _showGameChanges = true;

  NativeCalls nativeCalls = NativeCalls();
  final notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _discordIdController.text = prefs.getString('discord_user_id') ?? '';
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

    nativeCalls.showNativeAndroidToast("Discord Id updated", 100);
  }

  Future<void> _saveFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = json.encode(_friends.map((f) => f.toJson()).toList());
    await prefs.setString('discord_friends', friendsJson);

    nativeCalls.showNativeAndroidToast("Friends list updated", 100);
  }

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('show_status_changes', _showStatusChanges);
    await prefs.setBool('show_game_changes', _showGameChanges);

    nativeCalls.showNativeAndroidToast("Notification settings updated", 100);
  }

  Future<void> _saveSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_data_in_background', _syncDataInBackground);
    await prefs.setInt('sync_interval', _syncInterval);

    nativeCalls.showNativeAndroidToast("Sync settings updated", 100);
  }

  void _showColorPicker(
      BuildContext context, SnooperThemeProvider themeProvider) {
    Color pickerColor = themeProvider.customColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                themeProvider.setCustomColor(pickerColor);
                Navigator.of(context).pop();
              },
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

    return Consumer<SnooperThemeProvider>(
        builder: (context, themeProvider, ___) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
        body: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            // Account Settings
            SettingsGroup(
              title: 'Account',
              icon: Icons.person,
              children: [
                SettingsTile(
                  child: ListTile(
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
                ),
                SettingsTile(
                  child: ListTile(
                    title: const Text('Logs'),
                    leading: Icon(PhosphorIcons.log()),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => LogsPage()));
                    },
                  ),
                ),
                SettingsTile(
                  child: ListTile(
                    title: const Text('Your data'),
                    leading: Icon(PhosphorIcons.database()),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AllYourDataPage()));
                    },
                  ),
                ),
                SettingsTile(
                  child: ListTile(
                    title: const Text('Export data - From Lanyard'),
                    leading: Icon(PhosphorIcons.export()),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      String data = prefs.getString('discord_user_data') ??
                          'No data found';

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Exported Data'),
                          content: SingleChildScrollView(
                            child: Text(
                              const JsonEncoder.withIndent('  ')
                                  .convert(json.decode(data)),
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: data));
                                nativeCalls.showNativeAndroidToast(
                                    "Data copied to clipboard", 100);
                                Navigator.pop(context);
                              },
                              child: const Text('Copy to Clipboard'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Friends Management
            SettingsGroup(
              title: 'Discord Friends',
              icon: Icons.people,
              children: [
                for (int i = 0; i < _friends.length; i++)
                  SettingsTile(
                    child: ListTile(
                      title: Text(_friends[i].name),
                      subtitle: Text(
                        'ID: ${_friends[i].id}',
                        style: TextStyle(fontSize: 12),
                      ),
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
                            icon: Icon(PhosphorIcons.trash()),
                            onPressed: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Friend'),
                                  content: const Text(
                                      'Are you sure you want to delete this friend?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldDelete == true) {
                                setState(() {
                                  _friends.removeAt(i);
                                });
                                _saveFriends();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                SettingsTile(
                  child: ListTile(
                    title: const Text('Add Friend'),
                    leading: const Icon(Icons.person_add),
                    onTap: _addFriend,
                  ),
                ),
                SettingsTile(
                  child: ListTile(
                    title: const Text('Export as Json'),
                    leading: Icon(PhosphorIcons.export()),
                    onTap: () async {
                      final friendsJson =
                          json.encode(_friends.map((f) => f.toJson()).toList());

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Exported Friends List'),
                          content: SingleChildScrollView(
                            child: Text(
                              const JsonEncoder.withIndent('  ')
                                  .convert(json.decode(friendsJson)),
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: friendsJson));
                                nativeCalls.showNativeAndroidToast(
                                    "Data copied to clipboard", 100);
                                Navigator.pop(context);
                              },
                              child: const Text('Copy to Clipboard'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final directory = await getDownloadsDirectory();
                                final file = File(
                                    '${directory!.path}/friends_list.json');
                                await file.writeAsString(friendsJson);
                                nativeCalls.showNativeAndroidToast(
                                    "Data saved as JSON", 100);
                                Navigator.pop(context);
                              },
                              child: const Text('Save as JSON'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SettingsTile(
                  child: ListTile(
                    title: const Text('Import from Json'),
                    leading: Icon(PhosphorIcons.bracketsCurly()),
                    onTap: () async {
                      final directory = await getDownloadsDirectory();
                      final file = File('${directory!.path}/friends_list.json');

                      if (await file.exists()) {
                        _importFriendsFromFile(file);
                      } else {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['json'],
                        );

                        if (result != null) {
                          File pickedFile = File(result.files.single.path!);
                          _importFriendsFromFile(pickedFile);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("No file selected")),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),

            // Appearance
            SettingsGroup(
              title: 'Appearance',
              icon: Icons.palette,
              children: [
                SettingsTile(
                  child: SwitchListTile(
                    title: const Text('Use System Theme'),
                    subtitle: const Text('Follow device theme settings'),
                    value: themeProvider.useSystemTheme,
                    onChanged: (value) {
                      themeProvider.setUseSystemTheme(value);
                    },
                  ),
                ),
                if (!themeProvider.useSystemTheme)
                  SettingsTile(
                    child: SwitchListTile(
                      title: const Text('Dark Mode'),
                      value: themeProvider.darkMode,
                      onChanged: (value) {
                        themeProvider.setDarkMode(value);
                      },
                    ),
                  ),
                if (themeProvider.darkMode ||
                    (themeProvider.useSystemTheme &&
                        MediaQuery.of(context).platformBrightness ==
                            Brightness.dark))
                  SettingsTile(
                    child: SwitchListTile(
                      title: const Text('AMOLED Dark Mode'),
                      subtitle:
                          const Text('Pure black background for OLED screens'),
                      value: themeProvider.amoledDark,
                      onChanged: (value) {
                        themeProvider.setAmoledDark(value);
                      },
                    ),
                  ),
                SettingsTile(
                  child: SwitchListTile(
                    title: const Text('Use Custom Color'),
                    value: themeProvider.useCustomColor,
                    onChanged: (value) {
                      themeProvider.setUseCustomColor(value);

                      setState(() {
                        _useCustomColor = value;
                      });
                    },
                  ),
                ),
                if (_useCustomColor)
                  SettingsTile(
                    child: ListTile(
                      title: const Text('Custom Theme Color'),
                      subtitle: const Text('Choose a theme color'),
                      leading: CircleAvatar(
                        backgroundColor: _customColor,
                      ),
                      onTap: () {
                        _showColorPicker(context, themeProvider);
                      },
                    ),
                  ),
              ],
            ),

            // Notifications
            SettingsGroup(
              title: 'Notifications',
              icon: Icons.notifications,
              children: [
                SettingsTile(
                  child: SwitchListTile(
                    title: const Text('Enable Notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveNotificationSettings();
                    },
                  ),
                ),
                if (_notificationsEnabled) ...[
                  SettingsTile(
                    child: SwitchListTile(
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
                  ),
                  SettingsTile(
                    child: SwitchListTile(
                      title: const Text('Game Activity'),
                      subtitle:
                          const Text('Notify when friends start playing games'),
                      value: _showGameChanges,
                      onChanged: (value) {
                        setState(() {
                          _showGameChanges = value;
                        });
                        _saveNotificationSettings();
                      },
                    ),
                  ),
                  SettingsTile(
                    child: ListTile(
                      title: const Text('Test Notification'),
                      subtitle: const Text('Show a test notification'),
                      leading: Icon(PhosphorIcons.bellZ()),
                      onTap: () async {
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
                    ),
                  ),
                ],
              ],
            ),

            // Sync Settings
            SettingsGroup(
              title: 'Sync Settings',
              icon: Icons.sync,
              children: [
                SettingsTile(
                  child: SwitchListTile(
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
                ),
                if (_syncDataInBackground)
                  SettingsTile(
                    child: ListTile(
                      title: const Text('Sync Interval'),
                      subtitle: Text('$_syncInterval minutes'),
                      leading: const Icon(Icons.timer),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sync Interval'),
                            content: StatefulBuilder(
                              builder: (context, setState) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                        'How often should we sync data?'),
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
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                );
                              },
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
                  ),
              ],
            ),

            // About
            SettingsGroup(
              title: 'About',
              icon: Icons.info,
              children: [
                SettingsTile(
                  child: ListTile(
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
                ),
                SettingsTile(
                  child: ListTile(
                    title: const Text('Privacy Policy'),
                    leading: const Icon(Icons.privacy_tip),
                    onTap: () {},
                  ),
                ),
                SettingsTile(
                  child: ListTile(
                    title: const Text('Terms of Service'),
                    leading: const Icon(Icons.gavel),
                    onTap: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }

  Future<void> _importFriendsFromFile(File file) async {
    try {
      final friendsJson = await file.readAsString();
      logger.i("Importing friends from file: ${file.path} - $friendsJson");
      final friendsList = json.decode(friendsJson) as List;
      bool anyNewFriend = false;

      for (var friendJson in friendsList) {
        final friend = DiscordFriend.fromJson(friendJson);
        if (!_friends.any((f) => f.id == friend.id)) {
          setState(() {
            _friends.add(friend);
          });
          anyNewFriend = true;
        }
      }

      if (anyNewFriend) {
        await _saveFriends();
        nativeCalls.showNativeAndroidToast(
            "Friends imported successfully", 100);
      } else {
        nativeCalls.showNativeAndroidToast("No new friends to import", 100);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to import friends: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _discordIdController.dispose();
    super.dispose();
  }
}
