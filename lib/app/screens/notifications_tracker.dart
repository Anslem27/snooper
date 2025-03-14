import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_notification.dart';
import '../services/presence_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _notificationService.notificationsStream.listen((notifications) {
      setState(() {
        _notifications = _sortNotifications(notifications);
      });
    });
  }

  void _loadNotifications() {
    setState(() {
      _notifications =
          _sortNotifications(_notificationService.getNotifications());
    });
  }

  List<AppNotification> _sortNotifications(
      List<AppNotification> notifications) {
    final sortedNotifications = List<AppNotification>.from(notifications);

    sortedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return sortedNotifications;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        scrolledUnderElevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface),
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) async {
              if (value == 'mark_read') {
                await _notificationService.markAllNotificationsAsRead();
                _loadNotifications();
              } else if (value == 'clear') {
                final shouldClear = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear all notifications?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('CLEAR'),
                      ),
                    ],
                  ),
                );

                if (shouldClear == true) {
                  await _notificationService.clearNotificationHistory();
                  _loadNotifications();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded,
                        color: colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    const Text('Mark all as read'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded,
                        color: colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    const Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_rounded,
                    size: 72,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifications will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final isUnread = !notification.isRead;
                final notificationType = notification.type;

                // Group notifications by date with headers
                final bool showDateHeader = index == 0 ||
                    !_isSameDay(_notifications[index].timestamp,
                        _notifications[index - 1].timestamp);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          _getDateHeaderText(notification.timestamp),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Dismissible(
                      key: Key(notification.id),
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24.0),
                        child: Icon(
                          Icons.delete_rounded,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) async {
                        setState(() {
                          _notifications.removeAt(index);
                        });

                        final currentNotifications =
                            _notificationService.getNotifications();
                        currentNotifications
                            .removeWhere((n) => n.id == notification.id);

                        // Trigger a save
                        await _notificationService
                            .markNotificationAsRead(notification.id);

                        setState(() {});
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isUnread
                              ? BorderSide(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.5),
                                  width: 1)
                              : BorderSide.none,
                        ),
                        color: isUnread
                            ? _getNotificationColor(
                                    notificationType, colorScheme)
                                .withValues(alpha: 0.2)
                            : colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await _notificationService
                                .markNotificationAsRead(notification.id);
                            _loadNotifications();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(
                                        notificationType, colorScheme),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getNotificationIcon(notificationType),
                                    color: _getIconColor(
                                        notificationType, colorScheme),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.title,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: isUnread
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              width: 10,
                                              height: 10,
                                              margin: const EdgeInsets.only(
                                                  left: 8),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notification.message,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTimestamp(
                                                notification.timestamp),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: colorScheme.outline,
                                            ),
                                          ),
                                          if (notification.activityName != null)
                                            Chip(
                                              label: Text(
                                                notification.activityName!,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onSecondaryContainer,
                                                ),
                                              ),
                                              backgroundColor: colorScheme
                                                  .secondaryContainer,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                        ],
                                      ),
                                      // Display image if available
                                      if (notification.imageUrl != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              notification.imageUrl!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 180,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: double.infinity,
                                                  height: 120,
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      size: 32,
                                                    ),
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  width: double.infinity,
                                                  height: 120,
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: _notifications.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                await _notificationService.markAllNotificationsAsRead();
                _loadNotifications();
              },
              tooltip: 'Mark all as read',
              elevation: 2,
              child: const Icon(Icons.done_all_rounded),
            )
          : null,
    );
  }

  Color _getNotificationColor(NotificationType type, ColorScheme colorScheme) {
    switch (type) {
      case NotificationType.friendOnline:
        return colorScheme.primaryContainer;
      case NotificationType.friendActivity:
        return colorScheme.tertiaryContainer;
      case NotificationType.system:
        return colorScheme.secondaryContainer;
      case NotificationType.test:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getIconColor(NotificationType type, ColorScheme colorScheme) {
    switch (type) {
      case NotificationType.friendOnline:
        return colorScheme.onPrimaryContainer;
      case NotificationType.friendActivity:
        return colorScheme.onTertiaryContainer;
      case NotificationType.system:
        return colorScheme.onSecondaryContainer;
      case NotificationType.test:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendOnline:
        return Icons.person_rounded;
      case NotificationType.friendActivity:
        return Icons.videogame_asset_rounded;
      case NotificationType.system:
        return Icons.system_update_rounded;
      case NotificationType.test:
        return Icons.science_rounded;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (notificationDate == today) {
      return 'Today, ${DateFormat.jm().format(timestamp)}';
    } else if (notificationDate == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(timestamp)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /* am reusing this alot, gotta clean and reuse this shit more often */
  String _getDateHeaderText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }
}
