import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


class GeneralActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final String username;

  const GeneralActivityCard({
    super.key,
    required this.activity,
    required this.username,
  });

  Color _getActivityColor(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('code') ||
        name.contains('visual studio') ||
        name.contains('intellij')) {
      return Colors.teal;
    } else if (name.contains('spotify') ||
        name.contains('music') ||
        name.contains('listening')) {
      return Colors.green;
    } else if (name.contains('chrome') ||
        name.contains('firefox') ||
        name.contains('safari')) {
      return Colors.blue;
    } else if (name.contains('discord') ||
        name.contains('chat') ||
        name.contains('slack')) {
      return Colors.indigo;
    }
    return Colors.deepPurple;
  }

  IconData _getActivityIcon(String activityName) {
    final name = activityName.toLowerCase();
    if (name.contains('code') ||
        name.contains('visual studio') ||
        name.contains('intellij')) {
      return Icons.code;
    } else if (name.contains('spotify') ||
        name.contains('music') ||
        name.contains('listening')) {
      return Icons.headphones;
    } else if (name.contains('chrome') ||
        name.contains('firefox') ||
        name.contains('safari')) {
      return Icons.public;
    } else if (name.contains('discord') ||
        name.contains('chat') ||
        name.contains('slack')) {
      return Icons.chat;
    } else if (name.contains('game') || name.contains('playing')) {
      return Icons.sports_esports;
    }
    return Icons.app_shortcut;
  }

  String _getTimeSpent() {
    // This would ideally use the timestamps from the Lanyard API
    // For now returning placeholder text
    return "Started 34m ago";
  }

  void _showActivityDetails(BuildContext context) {
    final activityName = activity['name'] ?? 'Unknown Activity';
    final details = activity['details'];
    final state = activity['state'];
    final color = _getActivityColor(activityName);
    final icon = _getActivityIcon(activityName);

    String? imageUrl;
    if (activity['assets'] != null &&
        activity['assets']['large_image'] != null) {
      imageUrl =
          'https://cdn.discordapp.com/app-assets/${activity['application_id']}/${activity['assets']['large_image']}';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with image
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          icon,
                          color: color,
                          size: 64,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          icon,
                          color: color,
                          size: 64,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        icon,
                        color: color,
                        size: 64,
                      ),
                    ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '@$username',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getTimeSpent(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    activityName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      details,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (state != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ],

                  // Additional Lanyard API data could be displayed here
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Timestamps and additional info
                  if (activity['timestamps'] != null) ...[
                    _buildInfoRow(context, Icons.timer, "Started",
                        _formatTimestamp(activity['timestamps']['start'])),
                    if (activity['timestamps']['end'] != null)
                      _buildInfoRow(context, Icons.timer_off, "Ends",
                          _formatTimestamp(activity['timestamps']['end'])),
                  ],

                  // Application information
                  if (activity['application_id'] != null)
                    _buildInfoRow(context, Icons.apps, "Application ID",
                        activity['application_id'].toString()),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid timestamp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityName = activity['name'] ?? 'Unknown Activity';
    final color = _getActivityColor(activityName);
    final icon = _getActivityIcon(activityName);
    final details = activity['details'];
    final state = activity['state'];

    String? imageUrl;
    if (activity['assets'] != null &&
        activity['assets']['large_image'] != null) {
      imageUrl =
          'https://cdn.discordapp.com/app-assets/${activity['application_id']}/${activity['assets']['large_image']}';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showActivityDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            icon,
                            color: color,
                            size: 28,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            icon,
                            color: color,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        color: color,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          color: color,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: color,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTimeSpent(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activityName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (details != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (state != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        state,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 24,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
