import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../Helper/api_helper.dart';
import '../../Helper/url_helper.dart';
import '../../Models/Assets/asset_model.dart';

class AssetRepository { //Build #1.0.40
  final APIHelper _helper = APIHelper();

  Future<AssetResponse> getAssets() async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.assets}";

    if (kDebugMode) {
      print("AssetRepository - GET URL: $url");
    }

    final response = await _helper.get(url, true);

    if (kDebugMode) {
      print("AssetRepository - GET Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return AssetResponse.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing assets response: $e");
        throw Exception("Failed to parse assets response");
      }
    } else if (response is Map<String, dynamic>) {
      return AssetResponse.fromJson(response);
    } else {
      throw Exception("Unexpected response type in assets GET");
    }
  }
}