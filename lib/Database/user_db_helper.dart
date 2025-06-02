import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../Models/Auth/login_model.dart';
import '../Models/Auth/store_validation_model.dart';
import 'db_helper.dart';

class UserDbHelper { // Build #1.0.13: Added for user data into db
  static final UserDbHelper _instance = UserDbHelper._internal();
  factory UserDbHelper() => _instance;

  UserDbHelper._internal() {
    if (kDebugMode) {
      print("#### UserDbHelper initialized!");
    }
  }

  /// ✅ Save User Data in DB
  Future<void> saveUserData(LoginResponse loginResponse) async {
    final db = await DBHelper.instance.database;

    Map<String, dynamic> userMap = {
      AppDBConst.userId: loginResponse.id,
     // AppDBConst.userRole: loginResponse.role, // need to add
      AppDBConst.userDisplayName: loginResponse.displayName,
      AppDBConst.userEmail: loginResponse.email,
      AppDBConst.userFirstName: loginResponse.firstName,
      AppDBConst.userLastName: loginResponse.lastName,
      AppDBConst.userNickname: loginResponse.nicename,
      AppDBConst.userToken: loginResponse.token
    };

    await db.insert(
      AppDBConst.userTable,
      userMap,
      conflictAlgorithm: ConflictAlgorithm.replace, // 🔹 Ensures latest data is stored
    );

    if (kDebugMode) {
      print("#### User data saved: $userMap");
    }
  }

  /// ✅ Get User Data
  Future<Map<String, dynamic>?> getUserData() async {
    final db = await DBHelper.instance.database;
    List<Map<String, dynamic>> result = await db.query(
      AppDBConst.userTable,
      orderBy: "${AppDBConst.userId} DESC", // 🔹 Get the latest user entry
      limit: 1,
    );

    if (result.isNotEmpty) {
      if (kDebugMode) print("#### Retrieved user data: ${result.first}");
      return result.first;
    }
    return null;
  }

  /// ✅ Check if User is Logged In
  Future<bool> isUserLoggedIn() async {
    try {
      final userData = await getUserData();
      return userData != null &&
          userData[AppDBConst.userToken] != null &&
          userData[AppDBConst.userToken].toString().isNotEmpty;
    } catch (e) {
      if (kDebugMode) print("Error checking user login status: $e");
      return false;
    }
  }

  //Build #1.0.42: Save Store Validation Data
  Future<void> saveStoreValidationData(StoreValidationResponse response) async {
    final db = await DBHelper.instance.database;

    Map<String, dynamic> validationMap = {
      AppDBConst.storeId: response.storeId,
      AppDBConst.storeUserId: response.userId,
      AppDBConst.username: response.username,
      AppDBConst.email: response.email,
      AppDBConst.subscriptionType: response.subscriptionType,
      AppDBConst.storeName: response.storeName,
      AppDBConst.expirationDate: response.expirationDate,
      AppDBConst.storeBaseUrl: response.storeBaseUrl,
      AppDBConst.storeAddress: response.storeAddress, //Build #1.0.54: updated
      AppDBConst.storePhone: response.storePhone,
      AppDBConst.storeInfo: response.storeInfo,
      AppDBConst.licenseKey: response.licenseKey,
      AppDBConst.licenseStatus: response.licenseStatus,
    };

    await db.insert(
      AppDBConst.storeValidationTable,
      validationMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (kDebugMode) {
      print("#### Store validation data saved: $validationMap");
    }
  }

  //Build #1.0.42: Get Store Validation Data
  Future<Map<String, dynamic>?> getStoreValidationData() async {
    final db = await DBHelper.instance.database;
    List<Map<String, dynamic>> result = await db.query(
      AppDBConst.storeValidationTable,
      orderBy: "${AppDBConst.storeValidationId} DESC",
      limit: 1,
    );

    if (result.isNotEmpty) {
      if (kDebugMode) print("#### Retrieved store validation data: ${result.first}");
      return result.first;
    }
    return null;
  }

  //Build #1.0.42: Check if Store Validation is Valid
  Future<bool> isStoreValidationValid() async {
    try {
      final validationData = await getStoreValidationData();
      if (validationData == null) return false;

      final expirationDateStr = validationData[AppDBConst.expirationDate];
      final licenseStatus = validationData[AppDBConst.licenseStatus];

      if (expirationDateStr == null || licenseStatus != 'Active') return false;

      final expirationDate = DateTime.parse(expirationDateStr);
      final now = DateTime.now();

      return expirationDate.isAfter(now);
    } catch (e) {
      if (kDebugMode) print("Error checking store validation status: $e");
      return false;
    }
  }

  /// ✅ Logout - Clear User Data
  Future<void> logout() async {
    final db = await DBHelper.instance.database;
    await db.delete(AppDBConst.userTable); // 🔹 Clears user table
    await db.delete(AppDBConst.storeValidationTable);

    if (kDebugMode) {
      print("#### User logged out, data cleared!");
    }
  }
}
