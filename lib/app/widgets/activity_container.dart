import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:snooper/app/widgets/cards.dart';
import 'dart:convert';
import 'dart:async';

import '../screens/home.dart';
import 'activity.dart';

class DiscordActivityContainer extends StatefulWidget {
  final String userId;
  final String username;
  final bool showHeader;

  const DiscordActivityContainer({
    super.key,
    required this.userId,
    this.username = '',
    this.showHeader = true,
  });

  @override
  State<DiscordActivityContainer> createState() =>
      _DiscordActivityContainerState();
}

class _DiscordActivityContainerState extends State<DiscordActivityContainer> {
  Map<String, dynamic>? _discordData;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _refreshTimer;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _fetchDiscordData();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(DiscordActivityContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchDiscordData();
    }
  }

  Future<void> _fetchDiscordData() async {
    if (widget.userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.lanyard.rest/v1/users/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          _discordData = jsonData['data'];
          _isLoading = false;

          // Get display name from discord data or use provided username
          if (_discordData != null && _discordData!['discord_user'] != null) {
            _displayName = _discordData!['discord_user']['display_name'] ??
                _discordData!['discord_user']['username'] ??
                widget.username;
          } else {
            _displayName = widget.username;
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      logger.e('Error fetching Discord data: $e');
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchDiscordData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8),
            child: Row(
              children: [
                Text(
                  widget.username.isNotEmpty
                      ? '${widget.username}\'s Discord Activity'
                      : 'Discord Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchDiscordData,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ],
        if (_isLoading)
          buildLoadingCard('Loading Discord activity...', context)
        else if (_hasError)
          buildErrorCard(
              'Failed to load Discord data for ${widget.username.isNotEmpty ? widget.username : "user"}',
              context)
        else if (_discordData == null)
          buildErrorCard('No Discord data available', context)
        else
          ActivityRenderer(
            discordData: _discordData!,
            username: _displayName,
          ),
      ],
    );
  }
}
