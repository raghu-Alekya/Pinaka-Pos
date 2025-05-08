import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/Theme/theme_model.dart';
import '../../Preferences/pinaka_preferences.dart';

/// class that will manage the theme data and notify listeners when the theme changes.
class ThemeNotifier with ChangeNotifier { // Build #1.0.6 - Added Theme code & added to Fast Key Screen for testing
  ThemeMode _themeMode = ThemeMode.light;
  final PinakaPreferences _preferences = PinakaPreferences(); // Create an instance

  ThemeNotifier();

  ThemeMode get themeMode => _themeMode;

  /// Public method to initialize theme mode
  Future<void> initializeThemeMode() async { // Build #1.0.9 : By default dark theme getting selected on launch even after changing from settings
    await _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    String? savedTheme = await _preferences.getSavedAppThemeMode() ?? ThemeMode.light.toString();
    _themeMode = _mapStringToThemeMode(savedTheme);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _preferences.saveAppThemeMode(mode); // Build #1.0.7
  }

  // Convert String? to ThemeMode
  ThemeMode _mapStringToThemeMode(String? themeString) {
    if (themeString == ThemeMode.dark.toString()) {
      return ThemeMode.dark;
    } else if (themeString == ThemeMode.light.toString()) {
      return ThemeMode.light;
    } else {
      return ThemeMode.system; // Default
    }
  }

  static const Color lightBackground = Color(0xFFE0E0E0);
  static const Color darkBackground = Color(0xFF121212);
  static const Color primaryBackground = Color(0xFF1E2745);
  static const Color buttonLight = Color(0xFF1E2745);
  static const Color buttonDark = Color(0xFF1EA628);
  static const Color cardLight = Color(0xFFFAFAFA);
  static const Color cardDark = Color(0xFF111315);
  static const Color textLight = Colors.black;
  static const Color textDark = Colors.white;

  // Light
  static final ThemeData lightTheme = ThemeData(
    secondaryHeaderColor: textLight,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(),
    primaryColor: primaryBackground,
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: const AppBarTheme(
      color: primaryBackground,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      labelLarge: TextStyle(color: Colors.white),
    ),
    typography: Typography.material2021(),
    iconTheme: const IconThemeData(color: Colors.black87),
    primaryIconTheme: const IconThemeData(color: Colors.white),
    dividerColor: Colors.grey[400],
    buttonTheme: ButtonThemeData(
      buttonColor: buttonLight,
      textTheme: ButtonTextTheme.primary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
    cardTheme: CardTheme(
      color: cardLight,
      elevation: 2,
      shadowColor: Colors.grey[300],
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(Colors.blue),
    ),
    // switchTheme: SwitchThemeData(
    //   thumbColor: WidgetStateProperty.all(Colors.blue),
    // ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Colors.blue,
      thumbColor: Colors.blue,
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: Colors.black87),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.all(Colors.white),
      elevation: WidgetStateProperty.all(2),
    ),
    searchViewTheme: SearchViewThemeData(
      backgroundColor: Colors.white,
      headerTextStyle: const TextStyle(color: Colors.black),
    ),
  );

  // Dark
  static final ThemeData darkTheme = ThemeData(
    secondaryHeaderColor: textDark,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(),
    primaryColor: primaryBackground,
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      color: primaryBackground,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textDark),
      bodyMedium: TextStyle(color: textDark),
      labelLarge: TextStyle(color: textDark),
    ),
    typography: Typography.material2021(),
    iconTheme: const IconThemeData(color: textDark),
    primaryIconTheme: const IconThemeData(color: Colors.white),
    dividerColor: Colors.grey[700],
    buttonTheme: ButtonThemeData(
      buttonColor: buttonDark,
      textTheme: ButtonTextTheme.primary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
    cardTheme: CardTheme(
      color: cardDark,
      elevation: 2,
      shadowColor: Colors.grey[900],
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(Colors.green),
    ),
    // switchTheme: SwitchThemeData(
    //   thumbColor: WidgetStateProperty.all(Colors.green),
    // ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Colors.green,
      thumbColor: Colors.green,
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: Colors.white70),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.all(Colors.grey[800]),
      elevation: WidgetStateProperty.all(2),
    ),
    searchViewTheme: SearchViewThemeData(
      backgroundColor: Colors.grey,
      headerTextStyle: const TextStyle(color: Colors.white),
    ),
  );

  // Light Scheme
  ColorScheme lightColorScheme = ColorScheme(
    primary: Colors.blue,
    secondary: Colors.blue[700]!,
    surface: const Color(0xFFFFFFFF),
    error: Colors.black,
    onError: Colors.black,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: const Color(0xFF241E30),
    brightness: Brightness.light,
  );

  // Dark Scheme
  ColorScheme darkColorScheme = ColorScheme(
    primary: Colors.blue,
    secondary: Colors.blue[700]!,
    surface: const Color(0xFFFFFFFF),
    error: Colors.black,
    onError: Colors.black,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: const Color(0xFF241E30),
    brightness: Brightness.light,
  );

  // ColorScheme darkColorScheme = ColorScheme(
  //
  // );
  ThemeData getTheme(BuildContext context) {
    if (_themeMode == ThemeMode.light) {
      return lightTheme;
    } else if (_themeMode == ThemeMode.dark) {
      return darkTheme;
    } else {
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.light ? lightTheme : darkTheme;
    }
  }
}