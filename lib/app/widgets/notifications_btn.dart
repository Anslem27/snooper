import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/presence_notifications.dart';

class NotificationIconWithBAdge extends StatefulWidget {
  final bool isActive;
  const NotificationIconWithBAdge({super.key, required this.isActive});

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
    return Badge(
      isLabelVisible: _unreadCount > 0,
      label: Text(
        _unreadCount > 99 ? '99+' : _unreadCount.toString(),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Icon(widget.isActive
          ? PhosphorIconsFill.bellRinging
          : PhosphorIconsLight.bellRinging),
    );
  }
}
