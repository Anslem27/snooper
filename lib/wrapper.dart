import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:snooper/app/screens/home.dart';
import 'package:snooper/app/screens/local_activity.dart';

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

  List<Widget> pages = [HomeScreen(), const LocalActivity()];

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
            selectedIcon: Icon(PhosphorIcons.circlesThreePlus()),
            icon: Icon(PhosphorIconsLight.circlesThreePlus),
            label: 'Local Activity',
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
