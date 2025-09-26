import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:pinaka_pos/Database/db_helper.dart';
import 'package:pinaka_pos/Database/user_db_helper.dart';


class CategoryService {
  final Dio _dio = Dio();

  /// Helper to get active user token from DB
  Future<String?> _getToken() async {
    final userData = await UserDbHelper().getUserData();
    if (userData != null && userData[AppDBConst.userToken] != null) {
      return userData[AppDBConst.userToken] as String;
    }
    return null;
  }

  Future<dynamic> fetchCategories() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("No active user token found!");
    }

    try {
      final response = await _dio.get(
        "https://merchantretail.alektasolutions.com/wp-json/pinaka-pos/v1/categories/get-categories-products",
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": "Bearer $token", // Use token from DB
          },
        ),
      );
      if (response.statusCode == 200) {
        // Open Hive box
        final box = await Hive.openBox('categoriesBox');

        // Clear old data if needed
        await box.clear();

        // Directly store raw JSON response
        await box.put('categoriesData', response.data);
        if (box.containsKey('categoriesData')) {

          print("Categories stored in Hive successfully!");
        } else {
          print("Failed to store categories in Hive.");
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

  /// Optional: retrieve raw JSON from Hive
  Future<dynamic> getCategoriesFromHive() async {
    final box = await Hive.openBox('categoriesBox');
    return box.get('categoriesData');
  }
}
