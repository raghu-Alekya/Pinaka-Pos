// repositories/category_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../Helper/api_helper.dart';
import '../../Helper/url_helper.dart';
import '../../Models/Category/category_model.dart';
import '../../Models/Category/category_product_model.dart';


class CategoryRepository { // Build #1.0.21
  final APIHelper _helper = APIHelper();

  Future<CategoryListResponse> getCategories({int parent = 0}) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.categories}${EndUrlConstants.allCategoriesEndUrl}$parent";

    if (kDebugMode) {
      print("CategoryRepository - GET URL: $url");
    }

    final response = await _helper.get(url, true);

    if (kDebugMode) {
      print("CategoryRepository - GET Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return CategoryListResponse.fromJson(List.from(responseData));
      } catch (e) {
        if (kDebugMode) print("Error parsing categories response: $e");
        throw Exception("Failed to parse categories response");
      }
    } else if (response is List) {
      return CategoryListResponse.fromJson(response);
    } else {
      throw Exception("Unexpected response type in categories GET");
    }
  }

  Future<CategoryProductListResponse> getProductsByCategory(int categoryId) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.productByCategories}/$categoryId";

    if (kDebugMode) {
      print("CategoryRepository - GET Products URL: $url");
    }

    final response = await _helper.get(url, true);

    if (kDebugMode) {
      print("CategoryRepository - GET Products Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return CategoryProductListResponse.fromJson(List.from(responseData));
      } catch (e, s) {
        if (kDebugMode) print("Error parsing products response: $e, Stack: $s");
        throw Exception("Failed to parse products response");
      }
    } else if (response is List) {
      return CategoryProductListResponse.fromJson(response);
    } else {
      throw Exception("Unexpected response type in products GET");
    }
  }
}