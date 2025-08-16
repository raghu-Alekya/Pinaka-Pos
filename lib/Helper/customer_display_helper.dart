import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';

class CustomerDisplayHelper {

  /// Generates a string summary from order items for logging
  static Future<String> generateCustomerData(int serverOrderId) async {
    final items = await OrderHelper().getOrderItems(serverOrderId);
    double total = 0.0;
    StringBuffer buffer = StringBuffer();

    buffer.writeln("===== Customer Display Summary =====");

    for (var item in items) {
      final price = item[AppDBConst.itemPrice] as double? ?? 0.0;
      final quantity = item[AppDBConst.itemCount] as int? ?? 0;
      final name = item[AppDBConst.itemName] ?? 'Unknown';
      buffer.writeln("$name x$quantity - ₹${price * quantity}");
      total += price * quantity;
    }

    buffer.writeln("Total: ₹$total");
    buffer.writeln("===== End of Summary =====");

    return buffer.toString();
  }

  /// Always logs order summary (simulates no secondary display)
  static Future<void> updateCustomerDisplay(int serverOrderId) async {
    final data = await generateCustomerData(serverOrderId);

    // Since no secondary display is present, log everything
    print("No secondary device detected. Showing summary in logs:");
    print(data);
  }
}
