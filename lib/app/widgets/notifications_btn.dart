import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../screens/notifications_tracker.dart';
import '../services/presence_notifications.dart';

class NotificationIconWithBAdge extends StatefulWidget {
  const NotificationIconWithBAdge({super.key});

  @override
  State<NotificationIconWithBAdge> createState() =>
      _NotificationIconWithBAdgeState();
}

class _NotificationIconWithBAdgeState extends State<NotificationIconWithBAdge> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _unreadCount = _notificationService.unreadCount;

    _notificationService.notificationsStream.listen((_) {
      setState(() {
        _unreadCount = _notificationService.unreadCount;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Badge(
        isLabelVisible: _unreadCount > 0,
        label: Text(
          _unreadCount > 99 ? '99+' : _unreadCount.toString(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Icon(PhosphorIcons.bellRinging()),
      ),
      tooltip: 'Notifications',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsPage(),
          ),
        );
      },
    );
  }
}
