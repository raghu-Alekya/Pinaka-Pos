import 'package:flutter/services.dart';

class CustomerDisplayService {
  static const platform =
  MethodChannel('com.example.flutter_customer_display/sunmi_display');

  /// 🔹 Show default welcome screen
  static Future<void> showWelcome() async {
    try {
      print("📢 [CustomerDisplayService] Calling → showWelcome()");
      await platform.invokeMethod('showWelcome');
      print("✅ [CustomerDisplayService] showWelcome executed successfully");
    } catch (e) {
      print("⚠️ [CustomerDisplayService] Failed to show welcome: $e");
    }
  }
  static Future<void> showThankYou() async {
    try {
      print("📢 [CustomerDisplayService] Calling → showThankYou()");
      await platform.invokeMethod('showThankYou');
      print("✅ [CustomerDisplayService] showThankYou executed successfully");

      // Automatically revert to welcome after 5 seconds
      Future.delayed(const Duration(seconds: 5), () async {
        await showWelcome();
      });
    } catch (e) {
      print("⚠️ [CustomerDisplayService] Failed to show Thank You: $e");
    }
  }


/// 🔹 Update welcome screen with Store ID / Name
  static Future<void> showWelcomeWithStore({
    required String storeId,
    required String storeName,
    String? storeLogoUrl, // New optional logo
  }) async {
    try {
      print("📢 [CustomerDisplayService] showWelcomeWithStore → storeId=$storeId, storeName=$storeName, logo=$storeLogoUrl");

      await platform.invokeMethod('showWelcomeWithStore', {
        "storeId": storeId,
        "storeName": storeName,
        "storeLogoUrl": storeLogoUrl ?? "", // fallback to empty
      });

      print("✅ [CustomerDisplayService] showWelcomeWithStore executed successfully");
    } catch (e) {
      print("⚠️ [CustomerDisplayService] Failed to show store welcome: $e");
    }
  }



  /// 🔹 Send Order Data to Customer Display
  static Future<void> showCustomerData({
    required int orderId,
    required List<Map<String, dynamic>> items,
    required double grossTotal,
    required double discount,
    required double merchantDiscount,
    required double netTotal,
    required double tax,
    required double netPayable,
  }) async {
    try {
      print("📢 [CustomerDisplayService] Calling → showCustomerData()");
      print("📝 orderId: $orderId");
      print("📝 items: $items");
      print("📝 grossTotal: $grossTotal, discount: $discount, merchantDiscount: $merchantDiscount");
      print("📝 netTotal: $netTotal, tax: $tax, netPayable: $netPayable");

      await platform.invokeMethod('showCustomerData', {
        "orderId": orderId,
        "items": items,
        "grossTotal": grossTotal,
        "discount": discount,
        "merchantDiscount": merchantDiscount,
        "netTotal": netTotal,
        "tax": tax,
        "netPayable": netPayable,
      });

      print("✅ [CustomerDisplayService] showCustomerData executed successfully");
    } catch (e) {
      print("⚠️ [CustomerDisplayService] Failed to send data to customer display: $e");
    }
  }
}
