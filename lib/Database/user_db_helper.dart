import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../Constants/text.dart';
import '../Models/Auth/login_model.dart';
import '../Preferences/pinaka_preferences.dart';
import 'db_helper.dart';

class UserDbHelper { //Build #1.0.126: Updated for user data into db
/// DOUBT -> NO PROBLEM IF WE USE "_instance"
/// RE-Search: Singleton pattern - `UserDbHelper()` returns the same instance every time.
/// No new object is created, only the existing static instance is reused.
/// EX: IF WE USE/CALL LIKE THIS WAY !
// final UserDbHelper _userDbHelper = UserDbHelper();
// await _userDbHelper.getUserData();
/// or use below in this call
// static final UserDbHelper instance = UserDbHelper._internal();
//   factory UserDbHelper() => instance;
/// then call using
// UserDbHelper.instance.getUserData();
  static final UserDbHelper _instance = UserDbHelper._internal();
  factory UserDbHelper() => _instance;


  UserDbHelper._internal() {
    if (kDebugMode) {
      print("#### UserDbHelper initialized!");
    }
  }

  /// Saves or updates user data in the database
  /// Updates if user exists, inserts if new
  Future<void> saveUserData(LoginResponse loginResponse) async {
    final db = await DBHelper.instance.database;

    //Build #1.0.126: Checking if user already exists
    final existingUser = await db.query(
      AppDBConst.userTable,
      where: '${AppDBConst.userId} = ?',
      whereArgs: [loginResponse.id],
    );

    Map<String, dynamic> userMap = {
      AppDBConst.userId: loginResponse.id,
      AppDBConst.userRole: loginResponse.role,
      AppDBConst.userDisplayName: loginResponse.displayName,
      AppDBConst.userEmail: loginResponse.email,
      AppDBConst.userFirstName: loginResponse.firstName,
      AppDBConst.userLastName: loginResponse.lastName,
      AppDBConst.userNickname: loginResponse.nicename,
      AppDBConst.userToken: loginResponse.token,
      AppDBConst.profilePhoto: loginResponse.avatar,
    };

    if (existingUser.isNotEmpty) {
      // Preserve existing themeMode and layoutSelection
      userMap[AppDBConst.themeMode] = existingUser.first[AppDBConst.themeMode] ?? ThemeMode.light.toString();
      userMap[AppDBConst.layoutSelection] = existingUser.first[AppDBConst.layoutSelection] ?? SharedPreferenceTextConstants.navLeftOrderRight;

      //Build #1.0.126: Updating existing user
      await db.update(
        AppDBConst.userTable,
        userMap,
        where: '${AppDBConst.userId} = ?',
        whereArgs: [loginResponse.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (kDebugMode) {
        print("#### User data updated for userId: ${loginResponse.id}, preserved theme: ${userMap[AppDBConst.themeMode]}, layout: ${userMap[AppDBConst.layoutSelection]}, data: $userMap");
      }
    } else {
      // Set default values for new user
      userMap[AppDBConst.themeMode] = ThemeMode.light.toString();
      userMap[AppDBConst.layoutSelection] = SharedPreferenceTextConstants.navLeftOrderRight;

      //Build #1.0.126: Inserting new user
      await db.insert(
        AppDBConst.userTable,
        userMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (kDebugMode) {
        print("#### New user data inserted for userId: ${loginResponse.id}, data: $userMap");
      }
    }
  }

  /// Saves or updates user settings
  Future<void> saveUserSettings(Map<String, dynamic> settings, {bool modeChange = false, bool themeChange = false}) async {
    if (kDebugMode) {
      print("#### Starting saveUserSettings with modeChange: $modeChange, themeChange: $themeChange");
    }

    //Build #1.0.122 : Using layoutSelectionNotifier for UI updates
    if (PinakaPreferences.layoutSelectionNotifier.value != settings[AppDBConst.layoutSelection]) {
      PinakaPreferences.layoutSelectionNotifier.value = settings[AppDBConst.layoutSelection];
    }

    final userData = await getUserData();
    var userId = userData?[AppDBConst.userId];
    final db = await DBHelper.instance.database;

    if(!modeChange) {
      await db.update(
        AppDBConst.userTable,
        {
          AppDBConst.themeMode: settings[AppDBConst.themeMode],
          AppDBConst.layoutSelection: settings[AppDBConst.layoutSelection],
          AppDBConst.profilePhoto: settings[AppDBConst.profilePhoto],
        },
        where: '${AppDBConst.userId} = ?',
        whereArgs: [userId],
      );

    }else if(themeChange) {
      await db.update(
        AppDBConst.userTable,
        {
          AppDBConst.themeMode: settings[AppDBConst.themeMode],
        },
        where: '${AppDBConst.userId} = ?',
        whereArgs: [userId],
      );

    } else {
      await db.update(
        AppDBConst.userTable,
        {
          AppDBConst.layoutSelection: settings[AppDBConst.layoutSelection],
        },
        where: '${AppDBConst.userId} = ?',
        whereArgs: [userId],
      );
    }

    if (kDebugMode) {
      print("#### Updated user settings: ${settings[AppDBConst.themeMode]}, ${settings[AppDBConst.layoutSelection]}");
    }
  }

  /// Retrieves user data from database
  Future<Map<String, dynamic>?> getUserData() async {
    final db = await DBHelper.instance.database;
    List<Map<String, dynamic>> result = await db.query(
      AppDBConst.userTable,
      orderBy: "${AppDBConst.userId} DESC",
      limit: 1,
    );

    if (result.isNotEmpty) {
      if (kDebugMode) print("#### Retrieved user data: ${result.first}");
      return result.first;
    }
    if (kDebugMode) print("#### No user data found in database");
    return null;
  }

  /// Checks if user is logged in by verifying token existence
  Future<bool> isUserLoggedIn() async {
    try {
      final userData = await getUserData();
      final isLoggedIn = userData != null &&
          userData[AppDBConst.userToken] != null &&
          userData[AppDBConst.userToken].toString().isNotEmpty;
      if (kDebugMode) print("#### User login status: $isLoggedIn");
      return isLoggedIn;
    } catch (e) {
      if (kDebugMode) print("#### Error checking user login status: $e");
      return false;
    }
  }

  /// Clears user data during logout
  Future<void> logout() async {
    final db = await DBHelper.instance.database;
    await db.delete(AppDBConst.userTable);
    if (kDebugMode) {
      print("#### User data cleared during logout");
    }
  }
}