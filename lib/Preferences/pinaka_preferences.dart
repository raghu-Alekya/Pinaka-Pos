import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Constants/text.dart';

class PinakaPreferences { // Build #1.0.7 , Naveen - added PinakaPreferences code
  static late SharedPreferences _prefs;

  static SharedPreferences get prefs => _prefs;

  static Future<void> prepareSharedPref() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // saveThemeMode
  Future<void> saveAppThemeMode(ThemeMode mode) async {
    _prefs.setString(SharedPreferenceTextConstants.themeModeKey, mode.toString() ?? ThemeMode.light.toString() );
  }

  // Get ThemeMode from SharedPreferences
  Future<String?> getSavedAppThemeMode() async { // Build #1.0.9 : By default dark theme getting selected on launch even after changing from settings
    return _prefs.getString(SharedPreferenceTextConstants.themeModeKey);
  }
}
