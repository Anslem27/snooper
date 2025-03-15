import 'package:flutter/material.dart';
import 'package:snooper/app/screens/home.dart';

import 'app/screens/notifications_tracker.dart';
import 'app/widgets/notifications_btn.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  int currentPageIndex = 0;

  @override
  initState() {
    super.initState();
  }

  List<Widget> pages = [HomeScreen(), const NotificationsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.discord),
            icon: Icon(Icons.discord_outlined),
            label: 'Presence',
          ),
          NavigationDestination(
            selectedIcon:
                NotificationIconWithBAdge(isActive: (currentPageIndex == 1)),
            icon: NotificationIconWithBAdge(isActive: (currentPageIndex == 0)),
            label: 'Notifications',
          ),
        ],
      ),
      body: pages[currentPageIndex],
    );
  }

  /* @override
  void dispose() {
    BackgroundServiceManager.stopBackgroundService();
    super.dispose();
  } */
}
