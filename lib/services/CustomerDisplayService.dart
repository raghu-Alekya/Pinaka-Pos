import 'package:flutter/services.dart';

class CustomerDisplayService {
  static const platform = MethodChannel('com.example.flutter_customer_display/sunmi_display');

  static Future<void> showCustomerData(String data) async {
    try {
      await platform.invokeMethod('showCustomerData', {"data": data});
    } on PlatformException catch (e) {
      print("Failed to send data to customer display: ${e.message}");
    }
  }
}
