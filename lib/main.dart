import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snooper/wrapper.dart';

import 'app/providers/theme_provider.dart';
import 'app/screens/home.dart';
import 'app/screens/settings.dart';
import 'app/services/app_monitor.dart';
import 'app/services/presence_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppMonitorService.initialize();
  await SharedPreferences.getInstance();

  bool hasPermission = await AppMonitorService.checkPermission();
  if (hasPermission) {
    await AppMonitorService.startMonitoring();
  }

  AppMonitorService.appDetections.listen((AppActivityInfo appInfo) {
    if (kDebugMode) {
      logger.d(
          'App Detected: ${appInfo.appName} (${appInfo.packageName}) at ${appInfo.timestamp}');
    } else {
      print(
          'App Detected: ${appInfo.appName} (${appInfo.packageName}) at ${appInfo.timestamp}');
    }
  });

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SnooperThemeProvider>(
          create: (_) => SnooperThemeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SnooperThemeProvider>(
      builder: (context, themeProvider, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            ThemeData lightTheme;
            ThemeData darkTheme;

            if (lightDynamic != null &&
                darkDynamic != null &&
                !themeProvider.useCustomColor) {
              lightTheme = ThemeData(
                colorScheme: lightDynamic.harmonized(),
                useMaterial3: true,
              );

              ColorScheme darkColorScheme = darkDynamic.harmonized();
              if (themeProvider.amoledDark) {
                darkColorScheme = darkColorScheme.copyWith(
                  surface: const Color.fromARGB(255, 42, 26, 26),
                  surfaceContainerHighest: const Color(0xFF121212),
                );
              }

              darkTheme = ThemeData(
                colorScheme: darkColorScheme,
                useMaterial3: true,
              );
            } else {
              lightTheme = themeProvider.getLightTheme();
              darkTheme = themeProvider.getDarkTheme();
            }

            return MaterialApp(
              title: 'Snooper',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              home: const Wrapper(),
              routes: {
                '/settings': (context) => const SettingsPage(),
                '/home': (context) => const HomeScreen(),
              },
            );
          },
        );
      },
    );
  }
}
