import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:snooper/app/screens/home.dart';
import 'app/screens/notifications_tracker.dart';
import 'app/screens/settings/settings.dart';
import 'app/widgets/notifications_btn.dart';
import 'app/widgets/snooper_bottom_bar.dart';

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

  List<Widget> pages = [
    HomeScreen(),
    const NotificationsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final List<NavItemWidget> navItems = [
      NavItemWidget(
        icon: Icons.discord_outlined,
        selectedIcon: Icons.discord,
        label: 'Presence',
        customWidget: SvgPicture.asset(
          'assets/branding/transparent_small.svg',
          height: 24,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.primary,
            BlendMode.srcIn,
          ),
        ),
      ),
      NavItemWidget(
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        label: 'Notifications',
        customWidget:
            NotificationIconWithBAdge(isActive: (currentPageIndex == 1)),
      ),
      NavItemWidget(
        icon: PhosphorIcons.gearFine(),
        selectedIcon: PhosphorIconsFill.gearFine,
        label: 'Settings',
        customWidget: null,
      ),
    ];

    return Scaffold(
      bottomNavigationBar: SnooperM3Bar(
        navItems: navItems,
        selectedIndex: currentPageIndex,
        onItemSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        fabIcon: Icons.add,
        onFabPressed: () {
          print('FAB pressed');
        },
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
