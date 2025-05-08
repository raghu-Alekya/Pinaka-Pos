import 'package:flutter/foundation.dart';
import 'package:pinaka_pos/Blocs/Orders/order_bloc.dart';
import 'package:pinaka_pos/Database/user_db_helper.dart';
import 'package:pinaka_pos/Models/Orders/orders_model.dart';
import 'package:pinaka_pos/Repositories/Orders/order_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Constants/text.dart';
import '../Helper/api_response.dart';
import 'db_helper.dart';

class OrderHelper { // Build #1.0.10 - Naveen: Added Order Helper to Maintain Order data
  static final OrderHelper _instance = OrderHelper._internal(); // Singleton instance to ensure only one instance of OrderHelper exists
  factory OrderHelper() => _instance;

  int? activeOrderId; // Stores the currently active order ID
  int? activeUserId; // Stores the active user ID
  List<int> orderIds = []; // List of order IDs for the active user
  List<Map<String, dynamic>> orders = [];

  OrderHelper._internal() {
    if (kDebugMode) {
      print("#### OrderHelper initialized!");
    }
    loadData(); // Load existing order data on initialization
  }

  // Loads order data from the local database and shared preferences
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    activeOrderId = prefs.getInt('activeOrderId'); // Retrieve the saved active order ID
    activeUserId = await getUserIdFromDB();
    // Fetch the user's orders from the database
    final db = await DBHelper.instance.database;
    orders = await db.query(
      AppDBConst.orderTable,
      where: '${AppDBConst.userId} = ?',
      whereArgs: [activeUserId ?? 1],
    );

    if (orders.isNotEmpty) {
      // Convert order list from DB into a list of order IDs
      orderIds = orders.map((order) => order[AppDBConst.orderId] as int).toList();
      // If activeOrderId is null or invalid, set it to the last available order ID
      if (activeOrderId == null || !orderIds.contains(activeOrderId)) {
        activeOrderId = orders.last[AppDBConst.orderId];
        await prefs.setInt('activeOrderId', activeOrderId!);
      }
    } else {
      // No orders found, reset values
      activeOrderId = null;
      orderIds = [];
      orders = [];
    }

    // Debugging logs
    if (kDebugMode) {
      print("#### loadData: activeOrderId = $activeOrderId");
      print("#### loadData: orderIds = $orderIds");
    }
  }

  Future<int> getUserIdFromDB() async {
    var userId = 0;
    try {
      final userData = await UserDbHelper().getUserData();

      if (userData != null && userData[AppDBConst.userId] != null) {
        userId = userData[AppDBConst.userId] as int;
      }
    } catch (e) {
      if (kDebugMode) {
        print("OrderPanelDBHelper: Exception in getUserFromDB: $e");
      }
    }
    return userId;
  }


  // Update an orderID from API
  Future<void> updateServerOrderIDInDB(int orderServerId) async {
    ///Call to Create order REST API here, it should be done on add order at UI
    // OrderBloc orderBloc = OrderBloc(OrderRepository());
    // ///Create metadata for the order
    // OrderMetaData device = OrderMetaData(key: OrderMetaData.posDeviceId, value: "b31b723b92047f4b"); /// need to add code for device id later
    // OrderMetaData placedBy = OrderMetaData(key: OrderMetaData.posPlacedBy, value: '$activeUserId');
    // List<OrderMetaData> metaData = [device,placedBy];
    // ///call create order API
    // await orderBloc.createOrder(metaData).whenComplete(() async {
    //   if (kDebugMode) {
    //     print('createOrderStream completed');
    //   }
    // });

    // await orderBloc.createOrderStream.listen((event) async {
    //   if (kDebugMode) {
    //     print('createOrderStream status: ${event.status}');
    //   }
    //   if (event.status == Status.ERROR) {
    //     if (kDebugMode) {
    //       print(
    //           'OrderPanelDBHelper createOrder: completed with ERROR');
    //     }
    //     orderBloc.createOrderSink.add(APIResponse.error(TextConstants.retryText));
    //     orderBloc.dispose();
    //   } else if (event.status == Status.COMPLETED) {
    //     final order = event.data!;
    //     orderServerId = order.id;
    //     orderStatus = order.status;
    //     if (kDebugMode) {
    //       print('>>>>>>>>>>> OrderPanelDBHelper Order created with id: $orderServerId');
    //     }
    //   }
    // });

    ///check if 'orderServerId' is 0 or not, if yes show alert
    final db = await DBHelper.instance.database;
    activeOrderId = await db.update(AppDBConst.orderTable, {
          AppDBConst.orderServerId: orderServerId, /// server created order id
          AppDBConst.orderDate: DateTime.now().toString(), /// update these from order created on server
          AppDBConst.orderTime: DateTime.now().toString(),
        },
        where: '${AppDBConst.orderId} = ?',
        whereArgs: [activeOrderId],
    );

    if (kDebugMode) {
      print("#### Order created with ID: Active DBOrder ID $activeOrderId, serverOrderID $orderServerId, orderDate: ${DateTime.now().toString()}");
    }
  }

  // Creates a new order and sets it as active
  Future<int> createOrder() async { // Build #1.0.11 : updated
    ///check if 'orderServerId' is 0 or not, if yes show alert
    final db = await DBHelper.instance.database;
    activeOrderId = await db.insert(AppDBConst.orderTable, {
      AppDBConst.userId: activeUserId ?? 1,
      // AppDBConst.orderServerId: orderServerId, /// server created order id, update after order created at backend
      AppDBConst.orderTotal: 0.0, /// initially it will be 0
      AppDBConst.orderStatus: "processing", /// initial value will be 'processing'
      AppDBConst.orderType: 'in-store',
      AppDBConst.orderDate: DateTime.now().toString(), /// update these from order created on server
      AppDBConst.orderTime: DateTime.now().toString(),
    });

    // Update the user's order count
    await db.rawUpdate('''
    UPDATE ${AppDBConst.userTable}
    SET ${AppDBConst.userOrderCount} = ${AppDBConst.userOrderCount} + 1
    WHERE ${AppDBConst.userId} = ?
    ''', [activeUserId ?? 1]);

    // Save the newly created order ID in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeOrderId', activeOrderId!);

    // Refresh the order list
    await loadData();

    if (kDebugMode) {
      print("#### Order created with ID: $activeOrderId");
    }

    return activeOrderId!;
  }

  // Deletes an order from the database and updates local storage
  Future<void> deleteOrder(int orderId) async {
    final db = await DBHelper.instance.database;
    await db.delete(
      AppDBConst.orderTable,
      where: '${AppDBConst.orderId} = ?',
      whereArgs: [orderId],
    );

    final prefs = await SharedPreferences.getInstance();

    // If the deleted order was the active order, reset the activeOrderId
    if (orderId == activeOrderId) {
      activeOrderId = null;
      await prefs.remove('activeOrderId');
    }

    // Reload the updated order list
    await loadData();

    // Debugging logs
    if (kDebugMode) {
      print('#### Order deleted with ID: $orderId');
      print('#### Updated activeOrderId: $activeOrderId');
      print('#### Updated orderIds: $orderIds');
    }
  }

  // Sets a specific order as the active order
  Future<void> setActiveOrder(int orderId) async {
    activeOrderId = orderId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeOrderId', activeOrderId!);

    // Debugging log
    if (kDebugMode) {
      print("#### Active order set to: $activeOrderId");
    }
  }

  // Fetch all orders for a specific user
  Future<List<Map<String, dynamic>>> getUserOrders(int userID) async { // Build #1.0.11 : added here from db_helper
    final db = await DBHelper.instance.database;
    return await db.query(
      AppDBConst.orderTable,
      where: '${AppDBConst.userId} = ?',
      whereArgs: [userID],
    );
  }

  // Fetch order for a specific orderId
  Future<List<Map<String, dynamic>>> getOrderById(int orderId) async { // Build #1.0.11 : added here from db_helper
    final db = await DBHelper.instance.database;
    return await db.query(
      AppDBConst.orderTable,
      where: '${AppDBConst.orderId} = ?',
      whereArgs: [orderId],
    );
  }

// Fetch all items for a specific order
  Future<List<Map<String, dynamic>>> getOrderItems(int orderID) async {
    final db = await DBHelper.instance.database;
    return await db.query(
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.orderIdForeignKey} = ?',
      whereArgs: [orderID],
    );
  }

// Delete an item from an order
  Future<void> deleteItem(int itemID) async {
    final db = await DBHelper.instance.database;
    await db.delete(
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.itemId} = ?',
      whereArgs: [itemID],
    );

    if (kDebugMode) {
      print('#### Item deleted with ID: $itemID');
    }
  }

  // Adds an item to the currently active order; creates an order if none exists
  Future<void> addItemToOrder(String name, String image, double price, int quantity, String sku, {VoidCallback? onItemAdded}) async {
    // Ensure there is an active order; create one if needed
    if (activeOrderId == null) {
      await createOrder();
    }

    // Debugging log
    if (kDebugMode) {
      print("#### Adding item to order: $activeOrderId");
    }

    final db = await DBHelper.instance.database;
    final existingItem = await db.query(
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemSKU} = ?',
      whereArgs: [activeOrderId, sku],
    );

    if (existingItem.isNotEmpty) {
      // Update the quantity and sum price
      await db.rawUpdate('''
      UPDATE ${AppDBConst.purchasedItemsTable}
      SET ${AppDBConst.itemCount} = ${AppDBConst.itemCount} + ?,
          ${AppDBConst.itemSumPrice} = ${AppDBConst.itemSumPrice} + ?
      WHERE ${AppDBConst.itemId} = ?
      ''', [quantity, price * quantity, existingItem.first[AppDBConst.itemId]]);
    } else {
      // Insert the item into the purchased items table
      await db.insert(AppDBConst.purchasedItemsTable, {
        AppDBConst.itemName: name,
        AppDBConst.itemImage: image,
        AppDBConst.itemPrice: price,
        AppDBConst.itemCount: quantity,
        AppDBConst.itemSumPrice: price * quantity,
        AppDBConst.orderIdForeignKey: activeOrderId,
        AppDBConst.itemSKU: sku,
      });
    }

    // Trigger callback if provided (used for UI updates)
    if (onItemAdded != null) {
      onItemAdded();
    }

    if (kDebugMode) {
      print('#### Item added to order: $name');
    }
  }

  // If using a StatefulWidget
  // Future<void> updateItemQuantity(int itemId, int quantity) async {
  //   final db = await DBHelper.instance.database;
  //
  //   // Calculate the new sum price based on the updated quantity
  //   final item = await db.query(
  //     AppDBConst.purchasedItemsTable,
  //     where: '${AppDBConst.itemId} = ?',
  //     whereArgs: [itemId],
  //   );
  //
  //   if (item.isNotEmpty) {
  //     double price = (item.first[AppDBConst.itemPrice] as num).toDouble();
  //     double newSumPrice = price * quantity;
  //
  //     await db.update(
  //         AppDBConst.purchasedItemsTable,
  //         {
  //           AppDBConst.itemCount: quantity,
  //           AppDBConst.itemSumPrice: newSumPrice
  //         },
  //         where: '${AppDBConst.itemId} = ?',
  //         whereArgs: [itemId]
  //     );
  //
  //     if (kDebugMode) {
  //       print('#### Item quantity updated: ID=$itemId, Quantity=$quantity');
  //     }
  //
  //     // After database update, refresh the UI
  //     // setState(() {
  //     //   // If needed, update any widget state variables here
  //     // });
  //
  //     // Or if using a provider
  //     // Provider.of<YourProvider>(context, listen: false).refreshItems();
  //   }
  // }
}