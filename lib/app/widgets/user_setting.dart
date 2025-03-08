import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscordUserSettings extends StatefulWidget {
  final Function(String) onUserIdChanged;
  final String currentUserId;

  const DiscordUserSettings({
    super.key,
    required this.onUserIdChanged,
    required this.currentUserId,
  });

  @override
  State<DiscordUserSettings> createState() => _DiscordUserSettingsState();
}

class _DiscordUserSettingsState extends State<DiscordUserSettings> {
  late TextEditingController _userIdController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _userIdController = TextEditingController(text: widget.currentUserId);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _saveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('discord_user_id', _userIdController.text);
    widget.onUserIdChanged(_userIdController.text);
    setState(() {
      _isEditing = false;
    });
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
                  Icons.account_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Discord ID',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.check : Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    if (_isEditing) {
                      _saveUserId();
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
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
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _saveUserId(),
                  )
                : Text(
                    widget.currentUserId,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              Text(
                'This ID is used to fetch your Discord activity via Lanyard API',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}