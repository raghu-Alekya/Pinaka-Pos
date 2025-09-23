import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:pinaka_pos/Database/db_helper.dart';
import 'package:pinaka_pos/Database/user_db_helper.dart';

class FastKeyService {
  final Dio _dio = Dio();

  /// Helper to get active user token from DB
  Future<String?> _getToken() async {
    final userData = await UserDbHelper().getUserData();
    if (userData != null && userData[AppDBConst.userToken] != null) {
      return userData[AppDBConst.userToken] as String;
    }
    return null;
  }

  Future<dynamic> fetchFastkeys() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("No active user token found!");
    }

    try {
      final response = await _dio.get(
        "https://merchantretail.alektasolutions.com/wp-json/pinaka-pos/v1/fastkeys/get-by-user",
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status! < 500, // accept 403 for inspection
        ),
      );

      print("Status code: ${response.statusCode}");
      print("Response data: ${response.data}");


      if (response.statusCode == 200) {
        // ✅ Open Hive box for FastKeys
        final box = await Hive.openBox('fastKeysBox');

        // Clear old data if needed
        await box.clear();

        // Store raw response JSON
        await box.put('fastKeysData', response.data);

        if (box.containsKey('fastKeysData')) {
          print("✅ FastKeys stored in Hive successfully!");
        } else {
          print("⚠️ Failed to store FastKeys in Hive.");
        }
      } else {
        throw Exception("Request failed: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception("Dio Error: ${e.message}");
    } catch (e) {
      throw Exception("Unexpected Error: $e");
    }
  }

  /// Retrieve FastKeys JSON from Hive (offline use)
  Future<dynamic> getFastKeysFromHive() async {
    final box = await Hive.openBox('fastKeysBox');
    return box.get('fastKeysData');
  }
}