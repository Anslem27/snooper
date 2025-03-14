import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snooper/wrapper.dart';
import 'package:workmanager/workmanager.dart';

import 'app/providers/theme_provider.dart';
import 'app/screens/home.dart';
import 'app/screens/settings/settings.dart';
import 'app/services/background_service.dart';
import 'app/services/presence_notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();

      logger.d('Background task $taskName started');

      final notificationService = NotificationService();
      final success = await notificationService.checkStatusFromBackground();

      logger.d('Background task $taskName completed with success: $success');
      return Future.value(success);
    } catch (e) {
      logger.e('Background task $taskName failed: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  await Workmanager().registerPeriodicTask(
    'snooperStatusCheck',
    'snooperBackgroundChecks',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.linear,
  );

  // For more frequent checks (every minute), we'll use a foreground service
  // when the app is running
  await SharedPreferences.getInstance();

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ForegroundServiceManager.startForegroundService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ForegroundServiceManager.stopForegroundService();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ForegroundServiceManager.startForegroundService();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        ForegroundServiceManager.stopForegroundService();
        break;
      default:
        break;
    }
  }

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
