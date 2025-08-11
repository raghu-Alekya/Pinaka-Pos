import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pinaka_pos/Helper/api_helper.dart';
import 'package:pinaka_pos/Helper/url_helper.dart';

// Build #1.0.163: Added Logout Repository
class LogoutRepository {
  final APIHelper _helper = APIHelper();

  // Build #1.0.163: Added logout API call
  Future<String> logout() async {
    // Construct logout URL
    String url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.token}${EndUrlConstants.logout}";

    if (kDebugMode) {
      print("LogoutRepository - Initiating logout request to URL: $url");
    }

    try {
      // Make POST request to logout endpoint
      final response = await _helper.post(url, {}, true);
      if (kDebugMode) {
        print("LogoutRepository - Response received: $response");
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        print("LogoutRepository - Error during logout: $e");
      }
      rethrow;
    }
  }
}