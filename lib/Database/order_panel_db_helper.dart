import 'package:flutter/foundation.dart';
import 'package:pinaka_pos/Blocs/Orders/order_bloc.dart';
import 'package:pinaka_pos/Database/user_db_helper.dart';
import 'package:pinaka_pos/Models/Orders/orders_model.dart';
import 'package:pinaka_pos/Repositories/Orders/order_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../Constants/text.dart';
import '../Helper/api_response.dart';
import '../Models/Orders/get_orders_model.dart' as model;
import 'db_helper.dart';

// Build #1.0.64: Add ItemType enum
enum ItemType {
  customProduct(TextConstants.customProductText),
  coupon(TextConstants.couponText),
  payout(TextConstants.payoutText);

  final String value;
  const ItemType(this.value);
}

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
    await db.update(
      AppDBConst.orderTable,
      {
        AppDBConst.orderId: orderServerId, // Update order_id to API id
        AppDBConst.orderServerId: orderServerId,
        AppDBConst.orderDate: DateTime.now().toString(),
        AppDBConst.orderTime: DateTime.now().toString(),
      },
      where: '${AppDBConst.orderId} = ?',
      whereArgs: [activeOrderId],
    );

    // Update activeOrderId to the new server ID
    activeOrderId = orderServerId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeOrderId', activeOrderId!);

    if (kDebugMode) {
      print("#### Order updated with ID: Active DBOrder ID $activeOrderId, serverOrderID $orderServerId, orderDate: ${DateTime.now().toString()}");
    }
  }

  //Build #1.0.40: syncOrdersFromApi
  Future<void> syncOrdersFromApi(List<model.OrderModel> apiOrders) async {
    final db = await DBHelper.instance.database;
    if (kDebugMode) {
      print("#### DEBUG: syncOrdersFromApi - Processing ${apiOrders.length} orders");
    }

    for (var apiOrder in apiOrders) {
      if (kDebugMode) {
        print("#### DEBUG: syncOrdersFromApi - Processing order serverId: ${apiOrder.id}");
      }
      // Check if order exists in DB by API id
      final existingOrders = await db.query(
        AppDBConst.orderTable,
        where: '${AppDBConst.orderId} = ?',
        whereArgs: [apiOrder.id],
      );

      if (existingOrders.isNotEmpty) {
        await db.update(
          AppDBConst.orderTable,
          {
            AppDBConst.orderServerId: apiOrder.id,
            AppDBConst.orderTotal: double.tryParse(apiOrder.total) ?? 0.0,
            AppDBConst.orderStatus: apiOrder.status,
            AppDBConst.orderDate: apiOrder.dateCreated,
            AppDBConst.orderTime: apiOrder.dateCreated,
            AppDBConst.orderPaymentMethod: apiOrder.paymentMethod,
            AppDBConst.orderDiscount: double.tryParse(apiOrder.discountTotal) ?? 0.0, // Store discount
            AppDBConst.orderTax: double.tryParse(apiOrder.totalTax) ?? 0.0, // Store tax
          },
          where: '${AppDBConst.orderId} = ?',
          whereArgs: [apiOrder.id],
        );
        if (kDebugMode) {
          print("#### DEBUG: Updated order with serverId: ${apiOrder.id}, dbOrderId: ${apiOrder.id}");
        }
      } else {
        await db.insert(AppDBConst.orderTable, {
          AppDBConst.orderId: apiOrder.id,
          AppDBConst.userId: activeUserId ?? 1,
          AppDBConst.orderServerId: apiOrder.id,
          AppDBConst.orderTotal: double.tryParse(apiOrder.total) ?? 0.0,
          AppDBConst.orderStatus: apiOrder.status,
          AppDBConst.orderType: 'in-store',
          AppDBConst.orderDate: apiOrder.dateCreated,
          AppDBConst.orderTime: apiOrder.dateCreated,
          AppDBConst.orderPaymentMethod: apiOrder.paymentMethod,
          AppDBConst.orderDiscount: double.tryParse(apiOrder.discountTotal) ?? 0.0, // Store discount
          AppDBConst.orderTax: double.tryParse(apiOrder.totalTax) ?? 0.0, // Store tax
          AppDBConst.orderShipping: double.tryParse(apiOrder.shippingTotal) ?? 0.0, // Store shipping
        });
        if (kDebugMode) {
          print("#### DEBUG: Inserted new order with serverId: ${apiOrder.id}, dbOrderId: ${apiOrder.id}");
        }
      }

      // Sync line items using API order id
      await updateOrderItems(apiOrder.id, apiOrder.lineItems);
      await updateOrderPayoutItems(apiOrder.id, apiOrder.feeLines ?? []); // Build #1.0.64
      await updateOrderCouponItems(apiOrder.id, apiOrder.couponLines ?? []);
    }

    if (kDebugMode) {
      print("#### DEBUG: syncOrdersFromApi - Refreshing local data");
    }
    await loadData();
  }

  //Build #1.0.40: update order items using item id
  Future<void> updateOrderItems(int orderId, List<model.LineItem> apiItems) async {
    if (kDebugMode) {
      print("#### DEBUG: updateOrderItems orderId: $orderId");
    }
    final db = await DBHelper.instance.database;
    final existingItems = await db.query(
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.orderIdForeignKey} = ?',
      whereArgs: [orderId],
    );

    final existingItemsMap = {
      for (var item in existingItems) item[AppDBConst.itemId].toString(): item,
    };

    if (kDebugMode) {
      print("#### DEBUG: updateOrderItems - Processing ${apiItems.length} items for order $orderId, existing items: ${existingItems.length}");
    }

    for (var apiItem in apiItems) {
      final itemId = apiItem.id.toString();
      final double itemPrice = apiItem.price ?? 0.0;
      final int itemQuantity = apiItem.quantity ?? 0;
      final double itemSumPrice = itemPrice * itemQuantity;

      if (kDebugMode) {
        print("#### DEBUG: updateOrderItems - Processing API item ID: $itemId, name: ${apiItem.name}, price: $itemPrice, quantity: $itemQuantity, sumPrice: $itemSumPrice");
      }

      if (existingItemsMap.containsKey(itemId)) {
        final existingItem = existingItemsMap[itemId]!;
        await db.update(
          AppDBConst.purchasedItemsTable,
          {
            AppDBConst.itemName: apiItem.name ?? 'Unknown Item',
            AppDBConst.itemPrice: itemPrice,
            AppDBConst.itemCount: itemQuantity,
            AppDBConst.itemSumPrice: itemSumPrice,
            AppDBConst.itemImage: apiItem.image.src ?? '',
            AppDBConst.itemSKU: apiItem.sku ?? '',
          },
          where: '${AppDBConst.itemId} = ?',
          whereArgs: [existingItem[AppDBConst.itemId]],
        );
        if (kDebugMode) {
          print("#### DEBUG: Updated item ID: $itemId for order $orderId");
        }
        existingItemsMap.remove(itemId);
      } else {
        await db.insert(AppDBConst.purchasedItemsTable, {
          AppDBConst.itemId: apiItem.id,
          AppDBConst.itemName: apiItem.name ?? 'Unknown Item',
          AppDBConst.itemSKU: apiItem.sku ?? '',
          AppDBConst.itemPrice: itemPrice,
          AppDBConst.itemImage: apiItem.image.src ?? '',
          AppDBConst.itemCount: itemQuantity,
          AppDBConst.itemSumPrice: itemSumPrice,
          AppDBConst.orderIdForeignKey: orderId,
          AppDBConst.itemType: ItemType.customProduct.value, // Added: Add item_type
        });
        if (kDebugMode) {
          print("#### DEBUG: Inserted new item ID: $itemId for order $orderId");
        }
      }
    }

    for (var item in existingItemsMap.values) {
      await db.delete(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.itemId} = ?',
        whereArgs: [item[AppDBConst.itemId]],
      );
      if (kDebugMode) {
        print("#### DEBUG: Deleted obsolete item ID: ${item[AppDBConst.itemId]} for order $orderId");
      }
    }

    // Calculate order total from items
    final items = await getOrderItems(orderId);
    final orderTotal = items.fold(0.0, (sum, item) => sum + (item[AppDBConst.itemSumPrice] as num).toDouble());

    // Fetch discount and tax from the database (set by syncOrdersFromApi)
    final order = await db.query(
      AppDBConst.orderTable,
      where: '${AppDBConst.orderId} = ?',
      whereArgs: [orderId],
    );
    double orderDiscount = 0.0;
    double orderTax = 0.0;
    if (order.isNotEmpty) {
      orderDiscount = order.first[AppDBConst.orderDiscount] as double? ?? 0.0;
      orderTax = order.first[AppDBConst.orderTax] as double? ?? 0.0;
    }

    // Update order with total, discount, and tax
    await db.update(
      AppDBConst.orderTable,
      {
        AppDBConst.orderTotal: orderTotal,
        AppDBConst.orderDiscount: orderDiscount,
        AppDBConst.orderTax: orderTax,
      },
      where: '${AppDBConst.orderId} = ?',
      whereArgs: [orderId],
    );
    if (kDebugMode) {
      print("#### DEBUG: Updated order total: $orderTotal, discount: $orderDiscount, tax: $orderTax for order $orderId, items: $items");
    }
  }


  // Build #1.0.64 : Modified updateOrderPayoutItems to align with updateOrderItems
  Future<void> updateOrderPayoutItems(int orderId, List<model.FeeLine> feeLines) async {
    if (kDebugMode) {
      print("#### DEBUG: updateOrderPayoutItems orderId: $orderId");
    }
    final db = await DBHelper.instance.database;
    final existingItems = await db.query(
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemType} = ?',
      whereArgs: [orderId, ItemType.payout.value],
    );

    final existingItemsMap = {
      for (var item in existingItems) item[AppDBConst.itemId].toString(): item,
    };

    if (kDebugMode) {
      print("#### DEBUG: updateOrderPayoutItems - Processing ${feeLines.length} payout items for order $orderId, existing items: ${existingItems.length}");
    }

    for (var feeLine in feeLines) {
      if (feeLine.name == TextConstants.payout) {
        final itemId = feeLine.id.toString();
        final double itemPrice = double.parse(feeLine.total ?? '0.0');
        final int itemQuantity = 1;
        final double itemSumPrice = itemPrice;

        if (kDebugMode) {
          print("#### DEBUG: updateOrderPayoutItems - Processing payout item ID: $itemId, name: ${feeLine.name}, price: $itemPrice, quantity: $itemQuantity, sumPrice: $itemSumPrice");
        }

        if (existingItemsMap.containsKey(itemId)) {
          final existingItem = existingItemsMap[itemId]!;
          await db.update(
            AppDBConst.purchasedItemsTable,
            {
              AppDBConst.itemName: feeLine.name ?? 'Payout',
              AppDBConst.itemPrice: itemPrice,
              AppDBConst.itemCount: itemQuantity,
              AppDBConst.itemSumPrice: itemSumPrice,
              AppDBConst.itemImage: 'assets/svg/payout.svg',
              AppDBConst.itemSKU: '',
            },
            where: '${AppDBConst.itemId} = ?',
            whereArgs: [existingItem[AppDBConst.itemId]],
          );
          if (kDebugMode) {
            print("#### DEBUG: Updated payout item ID: $itemId for order $orderId");
          }
          existingItemsMap.remove(itemId);
        } else {
          await db.insert(AppDBConst.purchasedItemsTable, {
            AppDBConst.itemId: feeLine.id,
            AppDBConst.itemName: feeLine.name ?? 'Payout',
            AppDBConst.itemSKU: '',
            AppDBConst.itemPrice: itemPrice,
            AppDBConst.itemImage: 'assets/svg/payout.svg',
            AppDBConst.itemCount: itemQuantity,
            AppDBConst.itemSumPrice: itemSumPrice,
            AppDBConst.orderIdForeignKey: orderId,
            AppDBConst.itemType: ItemType.payout.value,
          });
          if (kDebugMode) {
            print("#### DEBUG: Inserted new payout item ID: $itemId for order $orderId");
          }
        }
      }
    }

    for (var item in existingItemsMap.values) {
      await db.delete(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.itemId} = ?',
        whereArgs: [item[AppDBConst.itemId]],
      );
      if (kDebugMode) {
        print("#### DEBUG: Deleted obsolete payout item ID: ${item[AppDBConst.itemId]} for order $orderId");
      }
    }
  }

  // Build #1.0.64 : Modified updateOrderCouponItems to align with updateOrderItems
  Future<void> updateOrderCouponItems(int orderId, List<model.CouponLine> couponLines) async {
    if (kDebugMode) {
      print("#### DEBUG: updateOrderCouponItems orderId: $orderId");
    }
    final db = await DBHelper.instance.database;
    final existingItems = await db.query(
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemType} = ?',
      whereArgs: [orderId, ItemType.coupon.value],
    );

    final existingItemsMap = {
      for (var item in existingItems) item[AppDBConst.itemId].toString(): item,
    };

    if (kDebugMode) {
      print("#### DEBUG: updateOrderCouponItems - Processing ${couponLines.length} coupon items for order $orderId, existing items: ${existingItems.length}");
    }

    for (var coupon in couponLines) {
      final itemId = coupon.id.toString();
      final double itemPrice = coupon.nominalAmount ?? 0.0;
      final int itemQuantity = 1;
      final double itemSumPrice = itemPrice;

      if (kDebugMode) {
        print("#### DEBUG: updateOrderCouponItems - Processing coupon item ID: $itemId, code: ${coupon.code}, price: $itemPrice, quantity: $itemQuantity, sumPrice: $itemSumPrice");
      }

      if (existingItemsMap.containsKey(itemId)) {
        final existingItem = existingItemsMap[itemId]!;
        await db.update(
          AppDBConst.purchasedItemsTable,
          {
            AppDBConst.itemName: coupon.code ?? 'Coupon',
            AppDBConst.itemPrice: itemPrice,
            AppDBConst.itemCount: itemQuantity,
            AppDBConst.itemSumPrice: itemSumPrice,
            AppDBConst.itemImage: 'assets/svg/coupon.svg',
            AppDBConst.itemSKU: '',
          },
          where: '${AppDBConst.itemId} = ?',
          whereArgs: [existingItem[AppDBConst.itemId]],
        );
        if (kDebugMode) {
          print("#### DEBUG: Updated coupon item ID: $itemId for order $orderId");
        }
        existingItemsMap.remove(itemId);
      } else {
        await db.insert(AppDBConst.purchasedItemsTable, {
          AppDBConst.itemId: coupon.id,
          AppDBConst.itemName: '',
          AppDBConst.itemSKU: '',
          AppDBConst.itemPrice: itemPrice,
          AppDBConst.itemImage: 'assets/svg/coupon.svg',
          AppDBConst.itemCount: itemQuantity,
          AppDBConst.itemSumPrice: itemSumPrice,
          AppDBConst.orderIdForeignKey: orderId,
          AppDBConst.itemType: ItemType.coupon.value,
        });
        if (kDebugMode) {
          print("#### DEBUG: Inserted new coupon item ID: $itemId for order $orderId");
        }
      }
    }

    for (var item in existingItemsMap.values) {
      await db.delete(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.itemId} = ?',
        whereArgs: [item[AppDBConst.itemId]],
      );
      if (kDebugMode) {
        print("#### DEBUG: Deleted obsolete coupon item ID: ${item[AppDBConst.itemId]} for order $orderId");
      }
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

  //Build 1.1.36: Clears all items for a specific order before updating order items in order bloc -> updateOrderProducts
  Future<void> clearOrderItems(int orderId) async {
    final db = await DBHelper.instance.database;
    await db.delete(
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.orderIdForeignKey} = ?',
      whereArgs: [orderId],
    );

    if (kDebugMode) {
      print('#### Cleared all items for order: $orderId');
    }
  }

  // Adds an item to the currently active order; creates an order if none exists
  Future<void> addItemToOrder(String name, String image, double price, int quantity, String sku,{VoidCallback? onItemAdded, String? type}) async {
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
        AppDBConst.itemType: type,
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

  //Build 1.1.36: required this func for issue of Edit item not updating count in order panel
  Future<void> updateItemQuantity(int itemId, int newQuantity) async {
    final db = await DBHelper.instance.database;

    // Fetch the item's current price to calculate the new sum price
    final item = await db.query(
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.itemId} = ?',
      whereArgs: [itemId],
    );

    if (item.isNotEmpty) {
      double price = (item.first[AppDBConst.itemPrice] as num).toDouble();
      double newSumPrice = price * newQuantity;

      // Update the quantity and sum price in the database
      await db.update(
        AppDBConst.purchasedItemsTable,
        {
          AppDBConst.itemCount: newQuantity,
          AppDBConst.itemSumPrice: newSumPrice,
        },
        where: '${AppDBConst.itemId} = ?',
        whereArgs: [itemId],
      );

      // Update the order total in the orders table
      final items = await getOrderItems(item.first[AppDBConst.orderIdForeignKey] as int);
      double orderTotal = items.fold(0.0, (sum, item) => sum + (item[AppDBConst.itemSumPrice] as num).toDouble());

      await db.update(
        AppDBConst.orderTable,
        {AppDBConst.orderTotal: orderTotal},
        where: '${AppDBConst.orderId} = ?',
        whereArgs: [item.first[AppDBConst.orderIdForeignKey]],
      );

      if (kDebugMode) {
        print('#### Item quantity updated: ID=$itemId, Quantity=$newQuantity, New Sum Price=$newSumPrice');
        print('#### Order total updated: Order ID=${item.first[AppDBConst.orderIdForeignKey]}, Total=$orderTotal');
      }
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