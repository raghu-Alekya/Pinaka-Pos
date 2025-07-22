import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';

class GlobalUtility { //Build #1.0.126: Added for re-Use code at global level

  static Future<Map<String, String>> getDeviceDetails() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    String model = '';
    String imei = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? 'unknown';
        model = androidInfo.model ?? 'unknown';
        // IMEI typically not available without special permissions
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        model = iosInfo.model ?? 'unknown';
        // IMEI not available on iOS
      }
    } catch (e) {
      if (kDebugMode) print("Error getting device details: $e");
    }

    return {
      'device_id': deviceId,
      'model': model,
      'imei': imei,
    };
  }

  // Build #1.0.138: calculate gross total
  static double getGrossTotal(List<Map<String, dynamic>> orderItems) {
    return orderItems
        .where((item) {
      final type = item[AppDBConst.itemType]?.toString() ?? '';
      return type == ItemType.product.value || type == ItemType.customProduct.value;
    }).fold(0.0, (sum, item) => sum + (item[AppDBConst.itemSumPrice] as num).toDouble());
  }
}
