import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
import '../services/CustomerDisplayService.dart';

class CustomerDisplayHelper {
  /// 🔹 Show welcome after login success, including optional logo
  static Future<void> updateWelcomeWithStore(
      String storeId,
      String storeName, {
        String? storeLogoUrl,
      }) async {
    print(
        "🟢 [CustomerDisplayHelper] Updating welcome → storeId: $storeId, storeName: $storeName, logo: $storeLogoUrl");
    await CustomerDisplayService.showWelcomeWithStore(
      storeId: storeId,
      storeName: storeName,
      storeLogoUrl: storeLogoUrl,
    );
  }

  /// 🔹 Update order display on customer screen
  static Future<void> updateCustomerDisplay(int serverOrderId) async {
    try {
      print(
          "🟡 [CustomerDisplayHelper] Fetching order items for serverOrderId=$serverOrderId");

      // Fetch order items
      final items = await OrderHelper().getOrderItems(serverOrderId);
      print("📦 Order Items Fetched → ${items.length} items");

      // 🔹 Show Welcome if no items
      if (items.isEmpty) {
        print(
            "⚠️ No items in order #$serverOrderId → showing Welcome screen");
        await CustomerDisplayService.showWelcome();
        return;
      }

      // Parse items for display
      List<Map<String, dynamic>> parsedItems = [];
      double grossTotal = 0.0;

      for (var item in items) {
        final isCoupon = (item[AppDBConst.itemType] ?? '') == 'coupon';
        if (isCoupon) {
          print("⏩ Skipping coupon item → ${item[AppDBConst.itemName]}");
          continue;
        }

        final salesPrice = item["item_sales_price"] as double? ?? 0.0;
        final price = salesPrice > 0
            ? salesPrice
            : item[AppDBConst.itemPrice] as double? ?? 0.0;
        final qty = item[AppDBConst.itemCount] as int? ?? 0;
        final name = item[AppDBConst.itemName] ?? 'Unknown';
        final image = item[AppDBConst.itemImage] ?? '';

        final itemTotal = price * qty;
        parsedItems.add({
          "name": name,
          "qty": qty,
          "price": itemTotal,
          "image": image,
        });

        grossTotal += itemTotal;
        print(
            "🛒 Item Parsed → $name | qty=$qty | unitPrice=$price | total=$itemTotal");
      }

      print("💰 Gross Total Calculated: $grossTotal");

      // Fetch totals directly from DB
      final db = await DBHelper.instance.database;
      final orderData = await db.query(
        AppDBConst.orderTable,
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [serverOrderId],
      );

      double discount = 0.0;
      double merchantDiscount = 0.0;
      double tax = 0.0;
      double netTotal = 0.0;
      double netPayable = 0.0;

      if (orderData.isNotEmpty) {
        final row = orderData.first;
        discount = row[AppDBConst.orderDiscount] as double? ?? 0.0;
        merchantDiscount = row["merchant_discount"] as double? ?? 0.0;
        tax = row[AppDBConst.orderTax] as double? ?? 0.0;

        // Take net totals directly from DB if available
        netTotal = row["net_total"] as double? ?? (grossTotal - discount - merchantDiscount);
        netPayable = row["net_payable"] as double? ?? (netTotal + tax);
      }

      print(
          "✅ Final Totals → netTotal=$netTotal, netPayable=$netPayable, discount=$discount, merchantDiscount=$merchantDiscount, tax=$tax");

      // Send data to customer display
      await CustomerDisplayService.showCustomerData(
        orderId: serverOrderId,
        items: parsedItems,
        grossTotal: grossTotal,
        discount: discount,
        merchantDiscount: merchantDiscount,
        netTotal: netTotal,
        tax: tax,
        netPayable: netPayable,
      );
    } catch (e, s) {
      print("❌ [CustomerDisplayHelper] Error in updateCustomerDisplay: $e");
      print("📌 StackTrace: $s");
    }
  }
}
