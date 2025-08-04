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
  customProduct(TextConstants.customItem),
  coupon(TextConstants.couponText),
  payout(TextConstants.payoutText), //Build #1.0.68
  product(TextConstants.productText);

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
      orderIds = orders.map((order) => order[AppDBConst.orderServerId] as int).toList();
      // If activeOrderId is null or invalid, set it to the last available order ID
      if (activeOrderId == null || !orderIds.contains(activeOrderId)) {
        activeOrderId = orders.last[AppDBConst.orderServerId];///changed to order server id
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
      print("#### Order Panel DB helper loadData: activeOrderId = $activeOrderId");
      print("#### Order Panel DB helper loadData: orderIds = $orderIds");
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

    // Build #1.0.80: Count orders in the database
    final dbOrdersCount = await db.query(AppDBConst.orderTable);
    final apiOrdersCount = apiOrders.length;

    if (kDebugMode) {
      print("#### DEBUG: syncOrdersFromApi - API orders count: $apiOrdersCount, DB orders count: ${dbOrdersCount.length}");
    }

    // Check if counts match
    if (dbOrdersCount.length != apiOrdersCount) {
      if (kDebugMode) {
        print("#### DEBUG: syncOrdersFromApi - Counts do not match, deleting DB orders");
      }
      // Build #1.0.80: Delete all orders in the database
      await db.delete(AppDBConst.orderTable);
      //  delete purchasedItemsTable related data
      await db.delete(AppDBConst.purchasedItemsTable);
    }
    // Proceed with syncing only if counts match or after clearing DB
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
        where: '${AppDBConst.orderServerId} = ?', //Build #1.0.78
        whereArgs: [apiOrder.id],
      );

      if (kDebugMode) {
        print("#### DEBUG: syncOrdersFromApi - existingOrders: ${existingOrders.length}");
      }

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
          where: '${AppDBConst.orderServerId} = ?',
          whereArgs: [apiOrder.id],
        );
        if (kDebugMode) {
          print("#### DEBUG: syncOrdersFromApi Updated order with serverId: ${apiOrder.id}, orderTotal: ${apiOrder.total}");
        }
      } else {
        await db.insert(AppDBConst.orderTable, {
          // AppDBConst.orderId: apiOrder.id,
          AppDBConst.userId: activeUserId ?? 1,
          AppDBConst.orderServerId: apiOrder.id,
          AppDBConst.orderTotal: double.tryParse(apiOrder.total) ?? 0.0,
          AppDBConst.orderStatus: apiOrder.status,
          AppDBConst.orderType: apiOrder.createdVia ?? 'in-store',
          AppDBConst.orderDate: apiOrder.dateCreated,
          AppDBConst.orderTime: apiOrder.dateCreated,
          AppDBConst.orderPaymentMethod: apiOrder.paymentMethod,
          AppDBConst.orderDiscount: double.tryParse(apiOrder.discountTotal) ?? 0.0, // Store discount
          AppDBConst.orderTax: double.tryParse(apiOrder.totalTax) ?? 0.0, // Store tax
          AppDBConst.orderShipping: double.tryParse(apiOrder.shippingTotal) ?? 0.0, // Store shipping
        });
        if (kDebugMode) {
          print("#### DEBUG: syncOrdersFromApi Inserted new order with serverId: ${apiOrder.id}, orderTotal: ${apiOrder.total}");
        }
      }

      // Sync line items using API order id
      await updateOrderItems(apiOrder.id, apiOrder.lineItems);
      await updateOrderPayoutItems(apiOrder.id, apiOrder.feeLines ?? []); // Build #1.0.64
      await updateOrderCouponItems(apiOrder.id, apiOrder.couponLines ?? []);
    }

    if (kDebugMode) {
    // Calculate order total from items
      for (var order in apiOrders) {
        final items = await getOrderItems(order.id);
        for (var item in items) {
            print(
                "#### DEBUG: Check after insert if Order items ID: ${item[AppDBConst
                    .itemId]},  ${item[AppDBConst
                    .itemServerId]} for order ${order.id} is correct?, loadOrderItems 3");
        }
      }
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
      for (var item in existingItems) item[AppDBConst.itemServerId].toString(): item,
    };

    if (kDebugMode) {
      print("#### DEBUG: updateOrderItems - Processing ${apiItems.length} items for order $orderId, existing items: ${existingItemsMap.length}");
    }

    for (var apiItem in apiItems) {
      final itemId = apiItem.id.toString();
      final double itemPrice = apiItem.productData.regularPrice == '' ?  double.parse(apiItem.productData.price ?? '0.0') : double.parse(apiItem.productData.regularPrice ?? '0.0');
      final int itemQuantity = apiItem.quantity ?? 0;
      final double itemSumPrice = double.parse(apiItem.subtotal); //Build #1.0.134: updated item sum price using from api response

      if (kDebugMode) {
         print("         salesPrice: ${apiItem.productData.salePrice ?? "0.0"}, "
             "regularPrice:${apiItem.productData.regularPrice ?? "0.0"},"
             " unitPrice: ${apiItem.productData.price ?? "0.0"}");
      }

      final String variationName = apiItem.productVariationData?.metaData?.firstWhere((e) => e.key == "custom_name", orElse: () => model.MetaData(id: 0, key: "", value: "")).value ?? "";
      final int variationCount = apiItem.productData.variations?.length ?? 0;
      final String combo = apiItem.metaData.firstWhere((e) => e.value.contains('Combo'), orElse: () => model.MetaData(id: 0, key: "", value: "")).value.split(' ').first ?? "";
      ///Todo: check if these values should come from product data or product variation data or line item data
      // Build #1.0.118: Fix: Use double.tryParse to safely handle invalid or null values
      final double salesPrice = double.tryParse(apiItem.productData.salePrice ?? "0.0") ?? 0.0;
      final double regularPrice = double.tryParse(apiItem.productData.regularPrice ?? "0.0") ?? 0.0;
      final double unitPrice = double.tryParse(apiItem.productData.price ?? "0.0") ?? 0.0;

      if (kDebugMode) {
        print("#### DEBUG: updateOrderItems - Processing API item ID: $itemId, name: ${apiItem.name}, price: $itemPrice, quantity: $itemQuantity, sumPrice: $itemSumPrice");
        print("variationName $variationName, variationCount:$variationCount, combo:$combo, salesPrice: $salesPrice, regularPrice: $regularPrice, unitPrice: $unitPrice");
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
            AppDBConst.itemSalesPrice: salesPrice,
            AppDBConst.itemRegularPrice: regularPrice,
            AppDBConst.itemUnitPrice: unitPrice,
            AppDBConst.itemProductId: apiItem.productId, //Build #1.0.128: Update - missed to update productId & variationId
            AppDBConst.itemVariationId: apiItem.variationId,
           // AppDBConst.itemType: isCustomItem ? ItemType.customProduct.value :  ItemType.product.value,
          },
          where: '${AppDBConst.itemServerId} = ?',
          whereArgs: [existingItem[AppDBConst.itemServerId]], //Build #1.0.128: use itemServerId instead of itemId
        );
        if (kDebugMode) {
          print("#### DEBUG: Updated item ID: $itemId for order $orderId");
        }
        existingItemsMap.remove(itemId);
      } else {
        // Safe way to check if the item is a custom product
        bool isCustomItem = false;
        if (apiItem.productData != null &&
            apiItem.productData.tags != null &&
            apiItem.productData.tags.isNotEmpty) {
          isCustomItem = apiItem.productData.tags.any(
                  (tag) => tag.name == TextConstants.customItem
          );
        }
        await db.insert(AppDBConst.purchasedItemsTable, {
          AppDBConst.itemServerId: apiItem.id,
          AppDBConst.itemName: apiItem.name ?? 'Unknown Item',
          AppDBConst.itemSKU: apiItem.sku ?? '',
          AppDBConst.itemPrice: itemPrice,
          AppDBConst.itemImage: apiItem.image.src ?? '',
          AppDBConst.itemCount: itemQuantity,
          AppDBConst.itemSumPrice: itemSumPrice,
          AppDBConst.orderIdForeignKey: orderId,
          AppDBConst.itemType: isCustomItem ? ItemType.customProduct.value :  ItemType.product.value, //Build #1.0.128: Updated - missed to enum type
          AppDBConst.itemVariationCustomName: variationName,
          AppDBConst.itemVariationCount: variationCount,
          AppDBConst.itemCombo: combo,
          AppDBConst.itemSalesPrice: salesPrice,
          AppDBConst.itemRegularPrice: regularPrice, // Build #1.0.80: added
          AppDBConst.itemUnitPrice: unitPrice,
          AppDBConst.itemProductId: apiItem.productId, //Build #1.0.128: Updated - missed to add productId & variationId
          AppDBConst.itemVariationId: apiItem.variationId,
        });
        if (kDebugMode) {
          print("#### DEBUG: Inserted new item ID: $itemId for order $orderId");
        }
      }
    }

    for (var item in existingItemsMap.values) {
      await db.delete(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.itemServerId} = ?', //Build #1.0.128: Updated - itemId to itemServerId
        whereArgs: [item[AppDBConst.itemServerId]],
      );
      if (kDebugMode) {
        print("#### DEBUG: Deleted obsolete item ID: ${item[AppDBConst.itemServerId]} for order $orderId");
      }
    }

    // Calculate order total from items
    final items = await getOrderItems(orderId);
    for (var item in items) {
      if (kDebugMode) {
        print("#### DEBUG: Check after insert if Order items ID: ${item[AppDBConst.itemId]},  ${item[AppDBConst.itemServerId]} for order $orderId is correct?, loadOrderItems 2");
      }
    }

    // var orderTotal = items.fold(0.0, (sum, item) => sum + (item[AppDBConst.itemSumPrice] as num).toDouble());
    //
    // // Fetch discount and tax from the database (set by syncOrdersFromApi)
    // final order = await db.query(
    //   AppDBConst.orderTable,
    //   where: '${AppDBConst.orderServerId} = ?',
    //   whereArgs: [orderId],
    // );
    // double orderDiscount = 0.0;
    // double orderTax = 0.0;
    // if (order.isNotEmpty) {
    //   orderDiscount = order.first[AppDBConst.orderDiscount] as double? ?? 0.0;
    //   orderTax = order.first[AppDBConst.orderTax] as double? ?? 0.0;
    //   orderTotal = order.first[AppDBConst.orderTotal] as double? ?? 0.0;
    // }
    // orderTotal = orderTotal + orderTax;

    // Update order with total, discount, and tax
    // await db.update(
    //   AppDBConst.orderTable,
    //   {
    //     AppDBConst.orderTotal: orderTotal,
    //     AppDBConst.orderDiscount: orderDiscount,
    //     AppDBConst.orderTax: orderTax,
    //   },
    //   where: '${AppDBConst.orderServerId} = ?',
    //   whereArgs: [orderId],
    // );
    if (kDebugMode) {
      print("#### DEBUG: updateOrderItems for order id $orderId completed...");
          // print( "total: $orderTotal, discount: $orderDiscount, tax: $orderTax for order $orderId, items: $items");
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
      for (var item in existingItems) item[AppDBConst.itemServerId].toString(): item,
    };

    if (kDebugMode) {
      print("#### DEBUG: updateOrderPayoutItems - Processing ${feeLines.length} payout items for order $orderId, existing items: ${existingItems.length}");
    }
    double merchantDiscount = 0.0;
    var merchantDiscountIds = "";
    for (var feeLine in feeLines) {
      final itemId = feeLine.id.toString();
      final double itemPrice = double.parse(feeLine.total ?? '0.0');
      final int itemQuantity = 1;
      final double itemSumPrice = itemPrice;

      if (kDebugMode) {
        print("#### DEBUG: updateOrderPayoutItems - Processing payout item ID: $itemId, name: ${feeLine.name}, price: $itemPrice, quantity: $itemQuantity, sumPrice: $itemSumPrice");
      }

      if (feeLine.name == TextConstants.payout) {
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
            where: '${AppDBConst.itemServerId} = ?',
            whereArgs: [existingItem[AppDBConst.itemServerId]],
          );
          if (kDebugMode) {
            print("#### DEBUG: Updated payout item ID: $itemId for order $orderId");
          }
          existingItemsMap.remove(itemId);
        } else {
          await db.insert(AppDBConst.purchasedItemsTable, {
         //   AppDBConst.itemId: orderId,
            AppDBConst.itemServerId: feeLine.id, //Build #1.0.67: updated
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
      if (feeLine.name == TextConstants.discountText) {
        merchantDiscount += itemPrice.abs();
        merchantDiscountIds = "$merchantDiscountIds,${feeLine.id}";
      }
    }
    await db.update(
      AppDBConst.orderTable,
      {
        AppDBConst.merchantDiscount: merchantDiscount,
        AppDBConst.merchantDiscountIds: merchantDiscountIds,
      },
      where: '${AppDBConst.orderServerId} = ?',
      whereArgs: [orderId],
    );
    if (kDebugMode) {
      print("#### DEBUG: updateOrderPayoutItems - Processing merchantDiscount item IDs: $merchantDiscountIds, discountTotal: $merchantDiscount");
    }

    for (var item in existingItemsMap.values) {
      await db.delete(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.itemServerId} = ?',
        whereArgs: [item[AppDBConst.itemServerId]],
      );
      if (kDebugMode) {
        print("#### DEBUG: Deleted obsolete payout item ID: ${item[AppDBConst.itemServerId]} for order $orderId");
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
      for (var item in existingItems) item[AppDBConst.itemServerId].toString(): item,
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
          where: '${AppDBConst.itemServerId} = ?', //Build #1.0.128: Updated - itemId to itemServerId
          whereArgs: [existingItem[AppDBConst.itemServerId]],
        );
        if (kDebugMode) {
          print("#### DEBUG: Updated coupon item ID: $itemId for order $orderId");
        }
        existingItemsMap.remove(itemId);
      } else {
        await db.insert(AppDBConst.purchasedItemsTable, {
       //   AppDBConst.itemId: orderId,
          AppDBConst.itemServerId: coupon.id, //Build #1.0.67: updated
          AppDBConst.itemName: coupon.code ?? 'Coupon',
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
        where: '${AppDBConst.itemServerId} = ?', //Build #1.0.128: Updated - itemId to itemServerId
        whereArgs: [item[AppDBConst.itemServerId]],
      );
      if (kDebugMode) {
        print("#### DEBUG: Deleted obsolete coupon item ID: ${item[AppDBConst.itemServerId]} for order $orderId");
      }
    }
 }

  // Creates a new order and sets it as active
  Future<int> createOrder({int? serverOrderId}) async { // Build #1.0.11 : updated
    ///check if 'orderServerId' is 0 or not, if yes show alert
    final db = await DBHelper.instance.database;
    activeOrderId = serverOrderId;
    await db.insert(AppDBConst.orderTable, {
      AppDBConst.userId: activeUserId ?? 1,
      if (serverOrderId != null) AppDBConst.orderServerId: serverOrderId, /// server created order id, update after order created at backend
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
    await db.delete( //Build #1.0.78 : delete from db -> purchasedItemsTable
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.orderIdForeignKey} = ?',
      whereArgs: [orderId],
    );
    await db.delete( //Build #1.0.78 : delete from db -> orderTable
      AppDBConst.orderTable,
      where: '${AppDBConst.orderServerId} = ?',
      whereArgs: [orderId],
    );

    orders.removeWhere((order) => order[AppDBConst.orderServerId] == orderId);
    orderIds.remove(orderId);

    final prefs = await SharedPreferences.getInstance();

    // If the deleted order was the active order, reset the activeOrderId
    if (orderId == activeOrderId) {
      activeOrderId = orderIds.isNotEmpty ? orderIds.last : null;
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
      where: '${AppDBConst.orderServerId} = ?',
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
  Future<void> deleteItem(int itemServerId) async { // delete the item/product based on serverID not item id
    final db = await DBHelper.instance.database;
    await db.delete(
      AppDBConst.purchasedItemsTable,
      where: '${AppDBConst.itemServerId} = ?', // Build #1.0.92: using item server id , checked used places!!
      whereArgs: [itemServerId],
    );

    if (kDebugMode) {
      print('#### Item deleted with ID: $itemServerId');
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
  Future<void> addItemToOrder( // Build #1.0.80: updated
      int? serverItemId,
      String name,
      String image,
      double price,
      int quantity,
      String sku,
      int orderId,
      {
        VoidCallback? onItemAdded, String? type ,int? productId = -1, int? variationId = -1,
        String? variationName, int? variationCount, String? combo, double? salesPrice, double? regularPrice, double? unitPrice,
      }) async {
    ///Build #1.0.128: No need here , we are already doing createOrder in orderBloc of updateOrderProducts
    // if (orderId == null) {
    //   await createOrder();
    // }
    //Build #1.0.68: For default product pass enum item type was product
  //  type = ItemType.product.value;

    // Debugging log
    if (kDebugMode) {
      print("#### Adding item to order: $orderId, productId:$productId, variationId:$variationId, SKU: $sku, Type: $type, Quantity: $quantity");
      print("variationName $variationName, variationCount:$variationCount, combo:$combo, salesPrice: $salesPrice, regularPrice: $regularPrice, unitPrice: $unitPrice");
    }
    // if (activeOrderId == null) {
    //   await createOrder();
    // }
    // var order = await getOrderById(activeOrderId!);
    // orderId = order.first[AppDBConst.orderServerId];
    // List<Map<String, dynamic>> items = await getOrderItems(order.first[AppDBConst.orderServerId]);

    final db = await DBHelper.instance.database;
    var existingItem = [];

    if(variationId! > 0) {
      existingItem = await db.query(
        AppDBConst.purchasedItemsTable,
        where:
        '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemVariationId} = ? AND ${AppDBConst.itemType} = ?',
        whereArgs: [orderId, variationId, type ?? ItemType.product.value],
      );
    }
    if(existingItem.isEmpty){
      if (kDebugMode) {
        print("HELPER existingItem not found with variation id");
      }
      if(productId! > 0){
        existingItem = await db.query(
          AppDBConst.purchasedItemsTable,
          where:
          '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemProductId} = ? AND ${AppDBConst.itemType} = ?',
          whereArgs: [orderId, productId, type ?? ItemType.product.value],
        );
        if(existingItem.isNotEmpty && ((existingItem.first[AppDBConst.itemVariationId] as int) > 0)){
          if (kDebugMode) {
            print(
              "OrderDBHelper - addItemToOrder Existing item found productID: ${existingItem.first[AppDBConst.itemServerId]}, but variationId: ${existingItem.first[AppDBConst.itemVariationId]} instead $variationId");
          }
          existingItem = [];
        }
      }
    }

    if (existingItem.isNotEmpty) {
      if (kDebugMode) {
        print("HELPER existingItem");
      }
      await db.rawUpdate('''
      UPDATE ${AppDBConst.purchasedItemsTable}
      SET ${AppDBConst.itemCount} = ?,
          ${AppDBConst.itemSumPrice} = ?,
          ${AppDBConst.itemProductId} = ?,
          ${AppDBConst.itemVariationId} = ?,
          ${AppDBConst.itemSalesPrice} = ?,
          ${AppDBConst.itemRegularPrice} = ?,
          ${AppDBConst.itemUnitPrice} = ?
      WHERE ${AppDBConst.itemServerId} = ?
    ''', [quantity, price, productId, variationId, salesPrice, regularPrice, unitPrice, serverItemId]); //Build #1.0.146: Fixed Issue: We don't need to multiply with qty because we are already getting from line items sub total value
    } else {
      if (kDebugMode) {
        print("HELPER NOT existingItem");
      }
      await db.insert(AppDBConst.purchasedItemsTable, {
        AppDBConst.itemServerId: serverItemId,
        AppDBConst.itemName: name,
        AppDBConst.itemImage: image,
        AppDBConst.itemPrice: price,
        AppDBConst.itemCount: quantity,
        AppDBConst.itemSumPrice: price, //Build #1.0.146: Fixed Issue: We don't need to multiply with qty because we are already getting from line items sub total value
        AppDBConst.orderIdForeignKey: orderId,
        AppDBConst.itemSKU: sku,
        AppDBConst.itemType: type,
        AppDBConst.itemProductId: productId, // Build #1.0.80: added
        AppDBConst.itemVariationId: variationId,
        AppDBConst.itemVariationCustomName: variationName,
        AppDBConst.itemVariationCount: variationCount,
        AppDBConst.itemCombo: combo,
        AppDBConst.itemSalesPrice: salesPrice,
        AppDBConst.itemRegularPrice: regularPrice, // Build #1.0.80: added
        AppDBConst.itemUnitPrice: unitPrice,
      });
    }

    //Build #1.0.78: Update order total
    // final items = await getOrderItems(orderId);
    // final orderTotal = items.fold(0.0, (sum, item) => (item[AppDBConst.itemSumPrice] as num).toDouble());
    // if (kDebugMode) {
    //   print("orderTotal $orderTotal");
    // }
    // await db.update(
    //   AppDBConst.orderTable,
    //   {AppDBConst.orderTotal: orderTotal},
    //   where: '${AppDBConst.orderServerId} = ?',
    //   whereArgs: [orderId],
    // );

    loadData();
    if (onItemAdded != null) {
      onItemAdded();
    }

    if (kDebugMode) {
      print('#### Item added to order: $orderId, SKU: $sku, Type: $type, Quantity: $quantity, name:$name, serverItemId: $serverItemId, productId: $productId, variationId: $variationId, Type: $type');
    }
  }

  @Deprecated("Removed from current version, please use Rest API to update")
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