import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../Helper/api_helper.dart';
import '../../Helper/url_helper.dart';
import '../../Models/FastKey/fastkey_product_model.dart';

class FastKeyProductRepository {  // Build #1.0.15
  final APIHelper _helper = APIHelper();

  // POST: Add products to FastKey
  Future<FastKeyProductResponse> addProductsToFastKey(FastKeyProductRequest request) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.fastKeys}${EndUrlConstants.addFastKeyProductEndUrl}";

    if (kDebugMode) {
      print("FastKeyProductRepository - POST URL: $url");
      print("Request body: ${request.toJson()}");
    }

    final response = await _helper.post(url, request.toJson(), true);

    if (kDebugMode) {
      print("FastKeyProductRepository - POST Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return FastKeyProductResponse.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing POST response: $e");
        throw Exception("Failed to parse FastKey products response");
      }
    } else if (response is Map<String, dynamic>) {
      return FastKeyProductResponse.fromJson(response);
    } else {
      throw Exception("Unexpected response type");
    }
  }

  // GET: Fetch products by FastKey ID
  Future<FastKeyProductsResponse> getProductsByFastKeyId(int fastKeyId) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.fastKeys}${EndUrlConstants.getFastKeyProductsEndUrl}$fastKeyId";

    if (kDebugMode) {
      print("FastKeyProductRepository - GET URL: $url");
    }

    final response = await _helper.get(url, true);

    if (kDebugMode) {
      print("FastKeyProductRepository - GET Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return FastKeyProductsResponse.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing GET response: $e");
        throw Exception("Failed to parse FastKey products GET response");
      }
    } else if (response is Map<String, dynamic>) {
      return FastKeyProductsResponse.fromJson(response);
    } else {
      throw Exception("Unexpected response type in GET");
    }
  }
}