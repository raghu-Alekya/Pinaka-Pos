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
  // static double getGrossTotal(List<Map<String, dynamic>> orderItems) {
  //   return orderItems
  //       .where((item) {
  //     final type = item[AppDBConst.itemType]?.toString() ?? '';
  //     return type == ItemType.product.value || type == ItemType.customProduct.value;
  //   // }).fold(0.0, (sum, item) => sum + (item[AppDBConst.itemSumPrice] as num).toDouble());
  //   }).fold(0.0, (sum, item) {
  //     double total = sum + (item[AppDBConst.itemSumPrice] as num).toDouble();
  //     if (kDebugMode) {
  //       print("  *** getGrossTotal sum: $sum, itemSumPrice: ${item[AppDBConst.itemSumPrice]}, total: $total ***");
  //     }
  //     return total;
  //   });
  // }

  //Build #1.0.146: Updated Code - We are subtracting payout from gross total
  static double getGrossTotal(List<Map<String, dynamic>> orderItems) {
    return orderItems.fold(0.0, (sum, item) {
      final type = item[AppDBConst.itemType]?.toString() ?? '';
      final itemPrice = (item[AppDBConst.itemSumPrice] as num).toDouble();

      if (type == ItemType.product.value || type == ItemType.customProduct.value) {
        // Add product prices
        final total = sum + itemPrice;
        if (kDebugMode) {
          print("  *** Adding product: $sum + $itemPrice = $total ***");
        }
        return total;
      } else if (type == ItemType.payout.value) {
        // Subtract payout values (always reduce total, regardless of sign)
        final payoutValue = itemPrice.abs(); // Ensure we subtract a positive value
        final total = sum - payoutValue;
        if (kDebugMode) {
          print("  *** Subtracting payout: $sum - $payoutValue = $total ***");
        }
        return total;
      } else {
        // Ignore other types (like coupon)
        return sum;
      }
    });
  }
}
