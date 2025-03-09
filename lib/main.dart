import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snooper/wrapper.dart';

import 'app/providers/settings_provider.dart';
import 'app/screens/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (_) => SnooperThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<SnooperThemeProvider>(context);

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
              surface: Colors.black,
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
          },
        );
      },
    );
  }
}
