import 'package:flutter/material.dart';
import 'package:pinaka_pos/Screens/Home/fast_key_screen.dart';
import 'package:provider/provider.dart';
import 'Database/db_helper.dart';
import 'Helper/Extentions/theme_notifier.dart';
import 'Preferences/pinaka_preferences.dart';
import 'Screens/Auth/splash_screen.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter services are ready
  await PinakaPreferences.prepareSharedPref(); //Build #1.0.7: Initialize SharedPreferences

  ThemeNotifier themeNotifier = ThemeNotifier();
  await themeNotifier.initializeThemeMode(); // Build #1.0.9 : By default dark theme getting selected on launch even after changing from settings

  await DBHelper.instance.database; // Build #1.0.10: Initialize the database
  runApp(
    ChangeNotifierProvider(
      create: (_) => themeNotifier,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return SafeArea(  //Build #1.0.2 : Fixed - status bar overlapping with design
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeNotifier.lightTheme,
        darkTheme: ThemeNotifier.darkTheme,
        themeMode: themeHelper.themeMode,
        home: Scaffold(
          body: SplashScreen(),
        ),
      ),
    );
  }
}
