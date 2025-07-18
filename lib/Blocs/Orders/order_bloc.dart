// blocs/order_bloc.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../Constants/text.dart';
import '../../Database/db_helper.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Helper/api_response.dart';
import '../../Models/Orders/apply_discount_model.dart';
import '../../Models/Orders/get_orders_model.dart' as model;
import '../../Models/Orders/orders_model.dart';
import '../../Models/Orders/total_orders_count_model.dart';
import '../../Repositories/Orders/order_repository.dart';

class OrderBloc { // Build #1.0.25 - added by naveen
  final OrderRepository _orderRepository;

  // Build #1.0.53 : updated code - Stream Controllers ---
  late  StreamController<APIResponse<CreateOrderResponseModel>> _createOrderController;
  late  StreamController<APIResponse<model.OrderModel>> _updateOrderController;
  late  StreamController<APIResponse<model.OrderModel>> _applyCouponController; //Build #1.0.92: Updated: using OrderModel rather than UpdateOrderResponseModel
  late  StreamController<APIResponse<model.OrderModel>> _deleteOrderItemController;
  late  StreamController<APIResponse<ApplyDiscountResponse>> _applyDiscountController;
  late  StreamController<APIResponse<UpdateOrderResponseModel>> _changeOrderStatusController;
  late  StreamController<APIResponse<model.OrdersListModel>> _fetchOrdersController;
  late  StreamController<APIResponse<model.OrderModel>> _addPayoutController;
  late  StreamController<APIResponse<model.OrderModel>> _removePayoutController;
  late StreamController<APIResponse<model.OrderModel>> _removeCouponController;
  late StreamController<APIResponse<TotalOrdersResponseModel>> _fetchTotalOrdersController;

  // Build #1.0.53 : updated code -  Constructor ---
  OrderBloc(this._orderRepository) {
    _createOrderController = StreamController<APIResponse<CreateOrderResponseModel>>.broadcast();
    _updateOrderController = StreamController<APIResponse<model.OrderModel>>.broadcast();
    _applyCouponController = StreamController<APIResponse<model.OrderModel>>.broadcast();
    _deleteOrderItemController = StreamController<APIResponse<model.OrderModel>>.broadcast();
    _applyDiscountController = StreamController<APIResponse<ApplyDiscountResponse>>.broadcast();
    _changeOrderStatusController = StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();
    _fetchOrdersController = StreamController<APIResponse<model.OrdersListModel>>.broadcast();
    _addPayoutController = StreamController<APIResponse<model.OrderModel>>.broadcast(); //Build #1.0.92: Updated: using OrderModel rather than UpdateOrderResponseModel
    _removePayoutController = StreamController<APIResponse<model.OrderModel>>.broadcast();
    _removeCouponController = StreamController<APIResponse<model.OrderModel>>.broadcast();
    _fetchTotalOrdersController = StreamController<APIResponse<TotalOrdersResponseModel>>.broadcast();
    if (kDebugMode) {
      print("OrderBloc Initialized with all stream controllers.");
    }
  }

  // Build #1.0.53 : updated code -  Getters for Streams and Sinks ---
  // Create Order
  StreamSink<APIResponse<CreateOrderResponseModel>> get createOrderSink => _createOrderController.sink;
  Stream<APIResponse<CreateOrderResponseModel>> get createOrderStream => _createOrderController.stream;

  // Update Order
  StreamSink<APIResponse<model.OrderModel>> get updateOrderSink => _updateOrderController.sink;
  Stream<APIResponse<model.OrderModel>> get updateOrderStream => _updateOrderController.stream;

  // Apply Coupon
  StreamSink<APIResponse<model.OrderModel>> get applyCouponSink => _applyCouponController.sink;
  Stream<APIResponse<model.OrderModel>> get applyCouponStream => _applyCouponController.stream;

  // Delete Order Item
  StreamSink<APIResponse<model.OrderModel>> get deleteOrderItemSink => _deleteOrderItemController.sink;
  Stream<APIResponse<model.OrderModel>> get deleteOrderItemStream => _deleteOrderItemController.stream;

  // Apply Discount
  StreamSink<APIResponse<ApplyDiscountResponse>> get applyDiscountSink => _applyDiscountController.sink;
  Stream<APIResponse<ApplyDiscountResponse>> get applyDiscountStream => _applyDiscountController.stream;

  // Change Order Status
  StreamSink<APIResponse<UpdateOrderResponseModel>> get changeOrderStatusSink => _changeOrderStatusController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get changeOrderStatusStream => _changeOrderStatusController.stream;

  // Fetch Orders
  StreamSink<APIResponse<model.OrdersListModel>> get fetchOrdersSink => _fetchOrdersController.sink;
  Stream<APIResponse<model.OrdersListModel>> get fetchOrdersStream => _fetchOrdersController.stream;

  // Add Payout
  StreamSink<APIResponse<model.OrderModel>> get addPayoutSink => _addPayoutController.sink;
  Stream<APIResponse<model.OrderModel>> get addPayoutStream => _addPayoutController.stream;

  // Remove Payout
  StreamSink<APIResponse<model.OrderModel>> get removePayoutSink => _removePayoutController.sink;
  Stream<APIResponse<model.OrderModel>> get removePayoutStream => _removePayoutController.stream;
   // Remove Coupon
  StreamSink<APIResponse<model.OrderModel>> get removeCouponSink => _removeCouponController.sink;
  Stream<APIResponse<model.OrderModel>> get removeCouponStream => _removeCouponController.stream;
   //
  StreamSink<APIResponse<TotalOrdersResponseModel>> get fetchTotalOrdersSink => _fetchTotalOrdersController.sink;
  Stream<APIResponse<TotalOrdersResponseModel>> get fetchTotalOrdersStream => _fetchTotalOrdersController.stream;

  // 1. Create Order
  Future<void> createOrder(List<OrderMetaData> metaData) async {
    if (_createOrderController.isClosed) return;

    createOrderSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final request = CreateOrderRequestModel(metaData: metaData);
      final response = await _orderRepository.createOrder(request);

      if (kDebugMode) {
        print("OrderBloc - Order created with ID: ${response.id}");
        print("OrderBloc - Order Status: ${response.status}");
      }

      //Build #1.0.78: Save to DB after successful API response
      OrderHelper orderHelper = OrderHelper();
      //Build #1.0.78: Removed updateServerOrderIDInDB as it’s redundant with createOrder(serverOrderId: response.id)
      int orderId = await orderHelper.createOrder(serverOrderId: response.id);
      await orderHelper.setActiveOrder(orderId);

      createOrderSink.add(APIResponse.completed(response));
    } catch (e) {
      updateOrderSink.add(APIResponse.error(_extractErrorMessage(e))); //Build #1.0.84
      if (kDebugMode) print("Exception in createOrder: $e");
    }
  }

  Future<void> printPurchasedItems() async { // Build #1.0.80: Testing purpose added for purchasedItemsTable data
    final db = await DBHelper.instance.database;
    final items = await db.query(AppDBConst.purchasedItemsTable);

    if (kDebugMode) {
      print("===== Purchased Items Table Contents =====");
      for (var item in items) {
        print(item);
      }
      print("===== End of Table =====");
    }
  }

  // 2. Update Order Products

  ///Todo:
  ///1. check if product item is present in order table then get the item server id
  ///2. and increase/ update the quantity as per user selection
  ///3. else add new product with quantity 1 or more passed by user
  ///4. Clear order item table
  ///5. Update order table with total_tax, total and discount_total
  ///5. Save response in db for line_items
  ///6. stop loading
  ///7. Return
  Future<void> updateOrderProducts({required int orderId, required int dbOrderId, required List<OrderLineItem> lineItems, bool isEditQuantity = false}) async {
    if (_updateOrderController.isClosed) return;

    updateOrderSink.add(APIResponse.loading(TextConstants.loading));
    try {

      /// NOTE:
      // final itemsToAdd = lineItems.map((item) => OrderLineItem(
      //   productId: item.productId,
      //   quantity: item.quantity, // Setting quantity to 0 removes the item
      // )).toList();
      //  final db = await DBHelper.instance.database;
      //  final existingItem = await db.query(
      //    AppDBConst.purchasedItemsTable,
      //    where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemSKU} = ? AND ${AppDBConst.itemType} = ?',
      //    whereArgs: [dbOrderId, sku, type],
      //  );
      //
      //  if (existingItem.isNotEmpty) { //Build #1.0.78: already managing this , no need
      // //NOTE: request -> id, quantity to update existing item quantity
      // Use Line Item Id -> id
      //  }else{
      //    //NOTE: request -> product, quantity to create new item in order
      // Use Id -> product id
      //  }
      // Build #1.0.80: Updated code with fixes, duplicate products adding into order panel
      final db = await DBHelper.instance.database;
      final itemsToAdd = <OrderLineItem>[];

      // var itemsInDB = await OrderHelper().getOrderItems(orderId);
      // for(var item in itemsInDB){
      //   if (kDebugMode) {
      //     print("#### updateOrderProducts getOrderItems: dbOrderId-> $dbOrderId, orderId:$orderId, item.productId  , productId-> ${item[AppDBConst.itemProductId]}, variationId-> ${item[AppDBConst.itemVariationId]}, itemId-> ${item[AppDBConst.itemId]}");
      //   }
      // }

      for (var item in lineItems) {
        if (kDebugMode) {
          print("#### updateOrderProducts checking new line item ${item.productId} in DB.");
        }

        var existingItem = await db.query(
          AppDBConst.purchasedItemsTable,
          where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemVariationId} = ? AND ${AppDBConst.itemType} = ?',
          whereArgs: [orderId, item.productId, ItemType.product.value],
        );

        if(existingItem.isEmpty) {
          if (kDebugMode) {
            print("#### updateOrderProducts existingItem is not found with variation id ${AppDBConst.itemProductId}");
          }
          existingItem = await db.query(
            AppDBConst.purchasedItemsTable,
            where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemProductId} = ? AND ${AppDBConst.itemType} = ?',
            whereArgs: [orderId, item.productId, ItemType.product.value],
          );
          if((existingItem.isNotEmpty && (existingItem.first[AppDBConst.itemVariationId] as int) > 0)){
            if (kDebugMode) {
              print(
                  "OrderBloc - Existing item found productID: ${existingItem.first[AppDBConst.itemServerId]}, but variationId: ${existingItem.first[AppDBConst.itemVariationId]} instead ${item.productId}");
              existingItem = [];
            }
          }
        }

        if (kDebugMode) {
          print("#### updateOrderProducts: dbOrderId-> $dbOrderId, orderId:$orderId, productId-> ${item.productId}, variationId-> ${item.variationId}, itemId-> ${item.id}");
          print("#### updateOrderProducts: Server Item Id ${existingItem.isEmpty}");
        }

        if (existingItem.isNotEmpty) {
          final currentQuantity = existingItem.first[AppDBConst.itemCount] as int;
          itemsToAdd.add(OrderLineItem(
            id: existingItem.first[AppDBConst.itemServerId] as int?,
            // Build #1.0.108: We have to identify is editing product pass updated qty, else if same product adding again currentQuantity + new quantity
            // otherwise while editing product qty was doubling the value
            quantity: isEditQuantity ? item.quantity : currentQuantity + item.quantity,
          ));
          if (kDebugMode) {
            print("OrderBloc - Existing item found ID: ${existingItem.first[AppDBConst.itemServerId]}, updated quantity: ${currentQuantity + item.quantity}");
          }
        } else { // NEW Product
          itemsToAdd.add(OrderLineItem(
            productId: item.productId,
            quantity: item.quantity,
          ));
          if (kDebugMode) {
            print("OrderBloc - New item added ID: ${item.productId}");
          }
        }
      }

      final request = UpdateOrderRequestModel(lineItems: itemsToAdd);
      final response = await _orderRepository.updateOrderProducts(
        orderId: orderId,
        request: request,
      );

      if(response == null){
        updateOrderSink.add(APIResponse.error("Response is empty after updating product to order $orderId"));
        return;
      }

      if (kDebugMode) {
        print("OrderBloc - Order updated with ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
        print("OrderBloc - Line items count: ${response.lineItems.length}");
      }
      //Build 1.1.36: working on updating order items in db getting issue.....
      //Build #1.0.78: Update DB after successful API response
      OrderHelper orderHelper = OrderHelper();
      // Clear existing items for this order
      await orderHelper.clearOrderItems(orderId);
      //Build #1.0.78: Add updated items from the API response
      ///update order details like total ,tax, discounts, merchant discouts
      if (kDebugMode) {
        print("#### OrderBloc - Updating order table for orderId $orderId, total:${double.tryParse(response.total) ?? 0.0},"
            " totalTax:${double.tryParse(response.totalTax) ?? 0.0}");
      }
      await db.update(
        AppDBConst.orderTable,
        {
          AppDBConst.orderTotal: double.tryParse(response.total) ?? 0.0,
          AppDBConst.orderStatus: response.status,
          AppDBConst.orderType: response.createdVia ?? 'in-store',
          AppDBConst.orderDate: response.dateCreated,
          AppDBConst.orderTime: response.dateCreated,
          AppDBConst.orderPaymentMethod: response.paymentMethod,
          AppDBConst.orderDiscount: double.tryParse(response.discountTotal) ?? 0.0, // Store discount
          AppDBConst.orderTax: double.tryParse(response.totalTax) ?? 0.0, // Store tax
          AppDBConst.orderShipping: double.tryParse(response.shippingTotal) ?? 0.0, // Store shipping
        },
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );
      // LineItems
      for (var lineItem in response.lineItems) {
        final String variationName = lineItem.productVariationData?.metaData?.firstWhere((e) => e.key == "custom_name", orElse: () => model.MetaData(id: 0, key: "", value: "")).value ?? "";
        final int variationCount = lineItem.productData.variations?.length ?? 0;
        final String combo = lineItem.metaData.firstWhere((e) => e.value.contains('Combo'), orElse: () => model.MetaData(id: 0, key: "", value: "")).value.split(' ').first ?? "";
        ///Todo: check if these values should come from product data or product variation data or line item data
        final double salesPrice = double.parse(lineItem.productData.salePrice ?? "0.0");
        final double regularPrice = double.parse(lineItem.productData.regularPrice ?? "0.0");
        final double unitPrice = double.parse(lineItem.productData.price ?? "0.0");
        if (kDebugMode) {
          print("#### Start adding lineItem ${lineItem.id}, orderId:$orderId , ProductId:${lineItem.productId}, VariationId:${lineItem.variationId}");
          print("variationName $variationName, variationCount:$variationCount, combo:$combo, salesPrice: $salesPrice, regularPrice: $regularPrice, unitPrice: $unitPrice");
        }
        await orderHelper.addItemToOrder(
          lineItem.id,
          lineItem.name,
          lineItem.image.src ?? '', // Fixed: Access 'src' key from image Map
          double.parse(lineItem.price.toString()), // Ensure price is parsed correctly
          lineItem.quantity,
          lineItem.sku ?? '',
          orderId,
          productId:lineItem.productId, // Build #1.0.80: newly added these two
          variationId:lineItem.variationId,
          type: ItemType.product.value,
          variationName: variationName,
          variationCount: variationCount,
          combo: combo,
          salesPrice: salesPrice,
          regularPrice: regularPrice,
          unitPrice: unitPrice,
        );
        if (kDebugMode) {
          print("#### End adding lineItem ${lineItem.id}, orderId:$orderId , ProductId:${lineItem.productId}, VariationId:${lineItem.variationId}");
        }
      }
      if (kDebugMode) {
        var itemsInDB = await OrderHelper().getOrderItems(orderId);
        for(var item in itemsInDB){
            print("#### updateOrderProducts getOrderItems after adding : "
                "dbOrderId-> $dbOrderId, orderId:$orderId, orderHelper.activeOrderId!: ${orderHelper.activeOrderId!} "
                "productId-> ${item[AppDBConst.itemProductId]}, variationId-> ${item[AppDBConst.itemVariationId]}, "
              "itemId-> ${item[AppDBConst.itemServerId]}");
        }
      }
     // Fee Lines : // Build #1.0.80: No need here , we already handling addPayout method, if we add here discount also adding into orderPanel list
     //  for (var feeLine in response.feeLines) {
     //    if (feeLine.name == TextConstants.payout) {
     //      await orderHelper.addItemToOrder(
     //        feeLine.id,
     //        feeLine.name ?? '',
     //        'assets/svg/payout.svg', // Fixed: Access 'src' key from image Map
     //        double.parse(feeLine.total!), // Ensure price is parsed correctly
     //        1,
     //        '',
     //        type: ItemType.payout.value,
     //      );
     //    }
     //  }
      // Coupon Lines

      ///Todo: check if we need this function or not, we arlready updating in coupon API
      ///No need Here : Updating in coupon api method
      // for (var couponLine in response.couponLines) {
      //   await orderHelper.addItemToOrder(
      //     couponLine.id,
      //     couponLine.code ?? '',
      //     'assets/svg/coupon.svg', // Fixed: Access 'src' key from image Map
      //     double.parse(couponLine.nominalAmount!.toString()), // Ensure price is parsed correctly
      //     1,
      //     '',
      //     orderId,
      //     type: ItemType.coupon.value,
      //   );
      // }

      updateOrderSink.add(APIResponse.completed(response!));
    } catch (e, s) {
      updateOrderSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in updateOrderProducts: $e, DEBUG $s");
    }
  }

  //Build #1.0.40: fetchOrders
  Future<void> fetchOrders({bool allStatuses = false, int pageNumber =1}) async { //Build #1.0.54: updated
    if (_fetchOrdersController.isClosed) return;

    fetchOrdersSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final response = await _orderRepository.getOrders(allStatuses: allStatuses, pageNumber: pageNumber); //Build #1.0.54: updated


      if (kDebugMode) {
        print("OrderBloc - Fetched ${response.orders.length} orders");
        for (var order in response.orders) {
          print("OrderBloc - Order ID: ${order.id}, Status: ${order.status}, Items: ${order.lineItems.length}");
          for (var item in order.lineItems) {
            print("OrderBloc - Item ID: ${item.id}, Name: ${item.name}, Price: ${item.price}, Quantity: ${item.quantity}");
          }
        }
      }
      ///save order is DB here,
      OrderHelper orderHelper = OrderHelper();
      if (kDebugMode) {
        print("OrderBloc - fetchOrders calling syncOrdersFromApi with ${response.orders.length} orders");
      }
      await orderHelper.syncOrdersFromApi(response.orders); //Build #1.0.78: sync data from bloc, no need in UI screen
      fetchOrdersSink.add(APIResponse.completed(response));
    } catch (e, s) {
      fetchOrdersSink.add(APIResponse.error("Order Sync Failed")); //Build #1.0.84
      if (kDebugMode) print("Exception in fetchOrders: $e, Stack: $s");
    }
  }

  // Build #1.0.118: Added this function for Get Orders Total with count API call
  Future<void> fetchTotalOrdersCount({bool allStatuses = false, int pageNumber =1, int pageLimit = 10, String status = "", String orderType = "", String userId = ""}) async {
    if (_fetchTotalOrdersController.isClosed) return;

    fetchTotalOrdersSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final response = await _orderRepository.fetchTotalOrdersCount(allStatuses: allStatuses, pageNumber: pageNumber, pageLimit: pageLimit, status: status, orderType: orderType, userId: userId);

      if (kDebugMode) {
        print("OrderBloc - Fetched ${response.ordersData.length} total orders, Total Count: ${response.orderTotalCount}");
        for (var order in response.ordersData) {
          print("OrderBloc - Order ID: ${order.id}, Status: ${order.status}, Items: ${order.lineItems.length}");
          for (var item in order.lineItems) {
            print("OrderBloc - Item ID: ${item.id}, Name: ${item.name}, Quantity: ${item.quantity}, Total: ${item.total}");
          }
        }
      }

      // Convert List<OrderList> to List<get_orders.OrderModel>
      final orderModels = response.ordersData.map((order) => order.toOrderModel()).toList();
      OrderHelper orderHelper = OrderHelper();
      await orderHelper.syncOrdersFromApi(orderModels);
      fetchTotalOrdersSink.add(APIResponse.completed(response));
    } catch (e, s) {
      fetchTotalOrdersSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in fetchTotalOrders: $e, Stack: $s");
    }
  }

  Future<void> fetchOrder({required String orderId}) async { //Build #1.0.54: updated
    if (_fetchOrdersController.isClosed) return;

    fetchOrdersSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final response = await _orderRepository.getOrder(orderId: orderId); //Build #1.0.54: updated


      if (kDebugMode) {
        print("OrderBloc - Fetched ${response.id} order");
        print("OrderBloc - Order ID: ${response.id}, Status: ${response.status}, Items: ${response.lineItems.length}");
        for (var item in response.lineItems) {
          print("OrderBloc - Item ID: ${item.id}, Name: ${item.name}, Price: ${item.price}, Quantity: ${item.quantity}");
        }
      }

      ///save order is DB here,
      OrderHelper orderHelper = OrderHelper();
      // await orderHelper.syncOrdersFromApi(response.orders); //Build #1.0.78: sync data from bloc, no need in UI screen
      // fetchOrdersSink.add(APIResponse.completed(response));
    } catch (e,s) {
      if (e.toString().contains('SocketException')) {
        fetchOrdersSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        fetchOrdersSink.add(APIResponse.error("Order Sync Failed"));
      }
      if (kDebugMode) print("Exception in fetchOrders: $e, Stack: $s");
    }
  }

  //Build #1.0.40: fetchOrders
  Future<void> fetchFilteredOrders({bool allStatuses = false, int pageNumber =1, int pageLimit = 10, String status = "", String orderType = "", String userId = ""}) async { //Build #1.0.54: updated
    if (_fetchOrdersController.isClosed) return;

    fetchOrdersSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final response = await _orderRepository.getOrders(allStatuses: allStatuses, pageNumber: pageNumber, pageLimit: pageLimit, status: status, orderType: orderType, userId: userId); //Build #1.0.54: updated

      if (kDebugMode) {
        print("OrderBloc - Fetched ${response.orders.length} orders");
        for (var order in response.orders) {
          print("OrderBloc - Order ID: ${order.id}, Status: ${order.status}, Items: ${order.lineItems.length}");
          for (var item in order.lineItems) {
            print("OrderBloc - Item ID: ${item.id}, Name: ${item.name}, Price: ${item.price}, Quantity: ${item.quantity}");
          }
        }
      }
      ///save order is DB here,
      OrderHelper orderHelper = OrderHelper();
      if (kDebugMode) {
        print("OrderBloc - fetchFilteredOrders calling syncOrdersFromApi with ${response.orders.length} orders");
      }
      // Build #1.0.104
      await orderHelper.syncOrdersFromApi(response.orders);
      fetchOrdersSink.add(APIResponse.completed(response));
    } catch (e,s) {
      updateOrderSink.add(APIResponse.error("Order Sync Failed")); //Build #1.0.84
      if (kDebugMode) print("Exception in fetchOrders: $e, Stack: $s");
    }
  }

  // 3. Apply Coupon to Order
  Future<void> applyCouponToOrder({required int orderId, required String couponCode}) async {
    if (_applyCouponController.isClosed) return;

    applyCouponSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final request = ApplyCouponRequestModel(
        couponLines: [CouponLine(code: couponCode)],
      );
      final response = await _orderRepository.applyCouponToOrder(
        orderId: orderId,
        request: request,
      );

      // Build #1.0.92: Update order table and handle coupon lines
      OrderHelper orderHelper = OrderHelper();
      final db = await DBHelper.instance.database;
      if (kDebugMode) {
        print("#### OrderBloc - Updating order table for orderId $orderId, total: ${double.tryParse(response.total) ?? 0.0}, discount: ${double.tryParse(response.discountTotal) ?? 0.0}");
      }
      await db.update(
        AppDBConst.orderTable,
        {
          AppDBConst.orderTotal: double.tryParse(response.total) ?? 0.0,
          AppDBConst.orderStatus: response.status,
          AppDBConst.orderType: response.createdVia ?? 'in-store',
          AppDBConst.orderDate: response.dateCreated,
          AppDBConst.orderTime: response.dateCreated,
          AppDBConst.orderPaymentMethod: response.paymentMethod,
          AppDBConst.orderDiscount: double.tryParse(response.discountTotal) ?? 0.0,
          AppDBConst.orderTax: double.tryParse(response.totalTax) ?? 0.0,
          AppDBConst.orderShipping: double.tryParse(response.shippingTotal) ?? 0.0,
        },
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );

      // Build #1.0.92: Clear existing coupon items and add new ones from response
      await db.delete(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemType} = ?',
        whereArgs: [orderId, ItemType.coupon.value],
      );
      for (var couponLine in response.couponLines) {
        if (kDebugMode) {
          print("#### OrderBloc - Adding coupon line: id: ${couponLine.id}, code: ${couponLine.code}, amount: ${couponLine.nominalAmount}");
        }
        await orderHelper.addItemToOrder(
          couponLine.id,
          couponLine.code ?? '',
          'assets/svg/coupon.svg',
          double.parse(couponLine.nominalAmount?.toString() ?? '0.0'),
          1,
          '',
          orderId,
          type: ItemType.coupon.value,
        );
      }

      if (kDebugMode) {
        print("OrderBloc - Coupon applied to order ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
        print("OrderBloc - Order Status: ${response.status}");
        print("OrderBloc - Coupon lines count: ${response.couponLines.length}");
      }
      applyCouponSink.add(APIResponse.completed(response));
    } catch (e) {
      applyCouponSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in applyCouponToOrder: $e");
    }
  }

  // 4. Build #1.0.49: Added changeOrderStatus func
  Future<void> changeOrderStatus({required int orderId, required String status}) async {
    if (_changeOrderStatusController.isClosed) return;

    changeOrderStatusSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final request = OrderStatusRequest(status: status);
      final response = await _orderRepository.changeOrderStatus(orderId: orderId, request: request);

      if (kDebugMode) {
        print("OrderBloc - Order $orderId status changed to: $status");
        print("OrderBloc - Response ID: ${response.id}, Status: ${response.status}");
      }

      changeOrderStatusSink.add(APIResponse.completed(response));
    } catch (e, s) {
      updateOrderSink.add(APIResponse.error("Error: Order Status changing to status \'$status\'")); //Build #1.0.84
      if (kDebugMode) print("Exception in changeOrderStatus: $e, Stack: $s");
    }
  }
  // 5. Delete Order Item
  Future<void> deleteOrderItem({required int orderId, required List<OrderLineItem> lineItems, required int dbItemId}) async {
    if (_deleteOrderItemController.isClosed) return;

    deleteOrderItemSink.add(APIResponse.loading(TextConstants.loading));
    try {
      // For deletion, we set quantity to 0 for the items to be removed
      final itemsToDelete = lineItems.map((item) => OrderLineItem(
        id: item.id,
        quantity: 0, // Setting quantity to 0 removes the item
      )).toList();

      final request = UpdateOrderRequestModel(lineItems: itemsToDelete);
      final response = await _orderRepository.updateOrderProducts(
        orderId: orderId,
        request: request,
      );

      if(response == null){
        updateOrderSink.add(APIResponse.error("Response is empty after deleting product from order $orderId"));
        return;
      }
      if (kDebugMode) {
        print("OrderBloc - Item deleted from order ID: ${response.id}");
        print("OrderBloc - Updated total: ${response.total}");
        print("OrderBloc - Remaining items: ${response.lineItems.length}");
      }
    // Build #1.0.92: updated code
      double merchantDiscount = 0.0;
      var merchantDiscountIds = "";
      // if (response.lineItems.isEmpty) { ///TODO: do we need to reset merchant discount if we don't have line items in order panel
      //   merchantDiscount = 0.0;
      // } else
      if (response.feeLines!.isNotEmpty) {
        for (var feeLine in response.feeLines!) {
          if (feeLine.name == TextConstants.discountText) {
            if (kDebugMode) {
              print("#### TEST 5151");
            }
            merchantDiscount += double.parse(feeLine.total ?? '0.0').abs();
            merchantDiscountIds = "$merchantDiscountIds,${feeLine.id}";
          }
        }
      }
      if (kDebugMode) {
        print("#### OrderBloc - deleteOrderItem Setting merchantDiscount to $merchantDiscount AND discountsIds to $merchantDiscountIds for orderId $orderId");
      }

      // Build #1.0.92: updating order table
      final db = await DBHelper.instance.database;
      await db.update(
        AppDBConst.orderTable,
        {
          AppDBConst.orderTotal: double.tryParse(response.total) ?? 0.0,
          AppDBConst.orderStatus: response.status,
          AppDBConst.orderType: response.createdVia ?? 'in-store',
          AppDBConst.orderDate: response.dateCreated,
          AppDBConst.orderTime: response.dateCreated,
          AppDBConst.orderPaymentMethod: response.paymentMethod,
          AppDBConst.orderDiscount: double.tryParse(response.discountTotal) ?? 0.0,
          AppDBConst.orderTax: double.tryParse(response.totalTax) ?? 0.0,
          AppDBConst.orderShipping: double.tryParse(response.shippingTotal) ?? 0.0,
          AppDBConst.merchantDiscount: merchantDiscount,
          AppDBConst.merchantDiscountIds: merchantDiscountIds,
        },
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );

      //Build #1.0.78: Delete from DB after successful API response
      OrderHelper orderHelper = OrderHelper();
      await orderHelper.deleteItem(dbItemId);

      deleteOrderItemSink.add(APIResponse.completed(response!));
    } catch (e) {
      deleteOrderItemSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in deleteOrderItem: $e");
    }
  }

  // Build #1.0.49: added this function for discount api call
  Future<void> applyDiscount(int orderId, String discountCode) async {
    if (_applyDiscountController.isClosed) return;

    applyDiscountSink.add(APIResponse.loading(TextConstants.loading));
    try {
      ApplyDiscountResponse discountResponse = await _orderRepository.applyDiscount(orderId, discountCode);

      if (discountResponse.success) {
        if (kDebugMode) {
          print("ProductBloc - Discount applied for order $orderId with code: $discountCode");
          print("Discount response: ${discountResponse.toJson()}");
        }
        applyDiscountSink.add(APIResponse.completed(discountResponse));
      } else {
        applyDiscountSink.add(APIResponse.error(discountResponse.message.isNotEmpty ? discountResponse.message : "Failed to apply discount"));
      }
    } catch (e) {
      addPayoutSink.add(APIResponse.error(_extractErrorMessage(e))); // Build #1.0.80
      if (kDebugMode) print("ProductBloc - Exception in applyDiscount: $e");
    }
  }

  // Build #1.0.53 : Add Payout to Order
  Future<void> addPayout({required int orderId, required int dbOrderId, required double amount, required bool isPayOut}) async {
    if (_addPayoutController.isClosed) return;

    addPayoutSink.add(APIResponse.loading(TextConstants.loading));
    try { //Build #1.0.78: updated code
      final AddPayoutRequestModel request = AddPayoutRequestModel(
        feeLines: [
          FeeLine(
            name: isPayOut ? TextConstants.payout : TextConstants.discountText,
            taxStatus: TextConstants.none,
            total: "-${amount.toStringAsFixed(2)}",
            originalValue: amount.toStringAsFixed(2),
          ),
        ],
      );
      final response = await _orderRepository.addPayout(orderId: orderId, request: request);

      if (kDebugMode) {
        print("OrderBloc - Payout added to order ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
        print("OrderBloc - Fee lines count: ${response.feeLines?.length ?? 0}");
      }

      // Build #1.0.92: Added payout/discount to DB after successful API response
      OrderHelper orderHelper = OrderHelper();
      final db = await DBHelper.instance.database;
      double merchantDiscount = 0.0;
      var merchantDiscountIds = "";
      if (response.feeLines!.isNotEmpty) {
        for (var feeLine in response.feeLines!) {
          if (feeLine.name == TextConstants.discountText) {
            if (kDebugMode) {
              print("#### TEST 2121");
            }
            merchantDiscount += double.parse(feeLine.total ?? '0.0').abs();
            merchantDiscountIds = "$merchantDiscountIds,${feeLine.id}";
          }
          if (isPayOut || (feeLine.name == TextConstants.payout)) {
            if (kDebugMode) {
              print("#### OrderBloc - Adding payout item: id: ${response.feeLines!.last.id}, total: ${response.feeLines!.last.total}");
            }
            await orderHelper.addItemToOrder(
              feeLine.id,
              feeLine.name ?? '',
              'assets/svg/payout.svg',
              double.parse(feeLine.total ?? '0.0'),
              1,
              '',
              orderId,
              type: ItemType.payout.value,
            );
          }
        }
        if (kDebugMode) {
          print("#### OrderBloc - addPayout Setting merchantDiscount to $merchantDiscount AND discountsIds to $merchantDiscountIds for orderId $orderId");
        }
      }
      // Build #1.0.92
      await db.update(
        AppDBConst.orderTable,
        {
          AppDBConst.orderTotal: double.tryParse(response.total) ?? 0.0,
          AppDBConst.orderStatus: response.status,
          AppDBConst.orderType: response.createdVia ?? 'in-store',
          AppDBConst.orderDate: response.dateCreated,
          AppDBConst.orderTime: response.dateCreated,
          AppDBConst.orderPaymentMethod: response.paymentMethod,
          AppDBConst.orderDiscount: double.tryParse(response.discountTotal) ?? 0.0,
          AppDBConst.orderTax: double.tryParse(response.totalTax) ?? 0.0,
          AppDBConst.orderShipping: double.tryParse(response.shippingTotal) ?? 0.0,
          AppDBConst.merchantDiscount: merchantDiscount,
          AppDBConst.merchantDiscountIds: merchantDiscountIds,
        },
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );

      addPayoutSink.add(APIResponse.completed(response));
    } catch (e, s) {
      addPayoutSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in addPayout: $e, Stack: $s");
    }
  }

  // Build #1.0.53 : Remove Payout from Order
  // Build #1.0.78: Added dbOrderId parameter to access the database.
  // Deleted the payout item and reset merchantDiscount after API success.
  Future<void> removeFeeLine({required int orderId, required int feeLineId}) async {
    if (_removePayoutController.isClosed) return;

    removePayoutSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final request = RemoveFeeLinesRequestModel(
        feeLines: [FeeLine(id: feeLineId, name: null)],
      );
      final response = await _orderRepository.removeFeeLine(orderId: orderId, request: request);

      if (kDebugMode) {
        print("OrderBloc - FeeLine removed from order ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
        print("OrderBloc - Remaining fee lines: ${response.feeLines?.length ?? 0}");
      }
      // Build #1.0.92
      double merchantDiscount = 0.0;
      var merchantDiscountIds = "";
      if (response.feeLines!.isNotEmpty) {
        for (var feeLine in response.feeLines!) {
          if (feeLine.name == TextConstants.discountText) {
            if (kDebugMode) {
              print("#### TEST 3131");
            }
            merchantDiscount += double.parse(feeLine.total ?? '0.0').abs();
            merchantDiscountIds = "$merchantDiscountIds,${feeLine.id}";
          }else
          if (feeLine.name == TextConstants.payout) {
           // merchantDiscount += double.parse(feeLine.total ?? '0.0').abs();
          }
        }
      }
      if (kDebugMode) {
        print("#### OrderBloc - removeFeeLine Setting merchantDiscount to $merchantDiscount AND discountsIds to $merchantDiscountIds for orderId $orderId");
      }
      // Build #1.1.0: Update order table and reset merchantDiscount
      OrderHelper orderHelper = OrderHelper();
      final db = await DBHelper.instance.database;
      await db.update(
        AppDBConst.orderTable,
        {
          AppDBConst.orderTotal: double.tryParse(response.total) ?? 0.0,
          AppDBConst.orderStatus: response.status,
          AppDBConst.orderType: response.createdVia ?? 'in-store',
          AppDBConst.orderDate: response.dateCreated,
          AppDBConst.orderTime: response.dateCreated,
          AppDBConst.orderPaymentMethod: response.paymentMethod,
          AppDBConst.orderDiscount: double.tryParse(response.discountTotal) ?? 0.0,
          AppDBConst.orderTax: double.tryParse(response.totalTax) ?? 0.0,
          AppDBConst.orderShipping: double.tryParse(response.shippingTotal) ?? 0.0,
          AppDBConst.merchantDiscount: merchantDiscount, // Reset merchant discount
          AppDBConst.merchantDiscountIds: merchantDiscountIds,
        },
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );

      // Build #1.1.0: Delete payout item from DB
      final payoutItem = await db.query(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.itemServerId} = ? AND ${AppDBConst.itemType} = ?',
        whereArgs: [feeLineId, ItemType.payout.value],
      );
      if (payoutItem.isNotEmpty) {
        if (kDebugMode) {
          print("#### OrderBloc - Deleting payout item with serverId: $feeLineId");
        }
        await orderHelper.deleteItem(payoutItem.first[AppDBConst.itemServerId] as int);
      }

      removePayoutSink.add(APIResponse.completed(response));
    } catch (e, s) {
      removePayoutSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in removeFeeLine: $e, Stack: $s");
    }
  }

//Build #1.0.94
  Future<void> removeFeeLines({required int orderId, required List<String> feeLineIds}) async {
    if (_removePayoutController.isClosed) return;

    removePayoutSink.add(APIResponse.loading(TextConstants.loading));
    try {
      ///Create FeeLine array to delete from order
      List<FeeLine> feeLines = [];
      for(var feeLineId in feeLineIds){
        feeLines.add(FeeLine(id: int.parse(feeLineId), name: null));
      }
      ///Create a request to delete FeeLines
      final request = RemoveFeeLinesRequestModel(
        feeLines: feeLines,
      );
      final response = await _orderRepository.removeFeeLine(orderId: orderId, request: request);

      if (kDebugMode) {
        print("OrderBloc - FeeLine removed from order ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
        print("OrderBloc - Remaining fee lines: ${response.feeLines?.length ?? 0}");
      }
      // Build #1.0.92
      double merchantDiscount = 0.0;
      var merchantDiscountIds = "";
      if (response.feeLines!.isNotEmpty) {
        for (var feeLine in response.feeLines!) {
          if (feeLine.name == TextConstants.discountText) {
            if (kDebugMode) {
              print("#### TEST 3131");
            }
            merchantDiscount += double.parse(feeLine.total ?? '0.0').abs();
            merchantDiscountIds = "$merchantDiscountIds,${feeLine.id}";
          }else
          if (feeLine.name == TextConstants.payout) {
            // merchantDiscount += double.parse(feeLine.total ?? '0.0').abs();
          }
        }
      }
      if (kDebugMode) {
        print("#### OrderBloc - removeFeeLines Setting merchantDiscount to $merchantDiscount AND discountsIds to $merchantDiscountIds for orderId $orderId");
      }
      // Build #1.1.0: Update order table and reset merchantDiscount
      OrderHelper orderHelper = OrderHelper();
      final db = await DBHelper.instance.database;
      await db.update(
        AppDBConst.orderTable,
        {
          AppDBConst.orderTotal: double.tryParse(response.total) ?? 0.0,
          AppDBConst.orderStatus: response.status,
          AppDBConst.orderType: response.createdVia ?? 'in-store',
          AppDBConst.orderDate: response.dateCreated,
          AppDBConst.orderTime: response.dateCreated,
          AppDBConst.orderPaymentMethod: response.paymentMethod,
          AppDBConst.orderDiscount: double.tryParse(response.discountTotal) ?? 0.0,
          AppDBConst.orderTax: double.tryParse(response.totalTax) ?? 0.0,
          AppDBConst.orderShipping: double.tryParse(response.shippingTotal) ?? 0.0,
          AppDBConst.merchantDiscount: merchantDiscount, // Reset merchant discount
          AppDBConst.merchantDiscountIds: merchantDiscountIds,
        },
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );

      // Build #1.1.0: Delete payout item from DB
      for(var feeLineId in feeLineIds){
        final payoutItem = await db.query(
          AppDBConst.purchasedItemsTable,
          where: '${AppDBConst.itemServerId} = ? AND ${AppDBConst.itemType} = ?',
          whereArgs: [int.parse(feeLineId), ItemType.payout.value],
        );
        if (payoutItem.isNotEmpty) {
          if (kDebugMode) {
            print("#### OrderBloc - Deleting payout item with serverId: $feeLineId");
          }
          await orderHelper.deleteItem(payoutItem.first[AppDBConst.itemServerId] as int);
        }
      }
      removePayoutSink.add(APIResponse.completed(response));
    } catch (e,s) {
      removePayoutSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in removeFeeLine: $e, Stack: $s");
    }
  }

  // Build #1.0.64: Remove Coupon Function
  // Build #1.0.78: Added dbOrderId parameter for consistency.
  // Deleted the coupon item from the database after API success.
  Future<void> removeCoupon({required int orderId, required String couponCode}) async {
    if (_removeCouponController.isClosed) return;

    removeCouponSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final request = RemoveCouponRequestModel(
        couponLines: [CouponLine(code: couponCode, remove: true)],
      );
      final response = await _orderRepository.removeCoupon(orderId: orderId, request: request);

      if (kDebugMode) {
        print("OrderBloc - Coupon removed from order ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
        print("OrderBloc - Remaining coupon lines: ${response.couponLines.length}");
      }

      // Build #1.0.92: Update order table with API response
      OrderHelper orderHelper = OrderHelper();
      final db = await DBHelper.instance.database;
      await db.update(
        AppDBConst.orderTable,
        {
          AppDBConst.orderTotal: double.tryParse(response.total) ?? 0.0,
          AppDBConst.orderStatus: response.status,
          AppDBConst.orderType: response.createdVia ?? 'in-store',
          AppDBConst.orderDate: response.dateCreated,
          AppDBConst.orderTime: response.dateCreated,
          AppDBConst.orderPaymentMethod: response.paymentMethod,
          AppDBConst.orderDiscount: double.tryParse(response.discountTotal) ?? 0.0,
          AppDBConst.orderTax: double.tryParse(response.totalTax) ?? 0.0,
          AppDBConst.orderShipping: double.tryParse(response.shippingTotal) ?? 0.0,
        },
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );

      // Build #1.0.92: Delete coupon item from DB
      final couponItem = await db.query(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.itemName} = ? AND ${AppDBConst.itemType} = ? AND ${AppDBConst.orderIdForeignKey} = ?',
        whereArgs: [couponCode, ItemType.coupon.value, orderId],
      );
      if (couponItem.isNotEmpty) {
        if (kDebugMode) {
          print("#### OrderBloc - Deleting coupon item with code: $couponCode, serverId: ${couponItem.first[AppDBConst.itemServerId]}");
        }
        await orderHelper.deleteItem(couponItem.first[AppDBConst.itemServerId] as int);
      }

      removeCouponSink.add(APIResponse.completed(response));
    } catch (e) {
      removeCouponSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in removeCoupon: $e");
    }
  }

  // Helper function to extract error message
  String _extractErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return "Network error. Please check your connection.";
    }
    try {
      // Extract JSON part from error string
      final jsonMatch = RegExp(r'\{.*\}').firstMatch(error.toString());
      if (jsonMatch != null) {
        final errorJson = jsonDecode(jsonMatch.group(0)!);
        return errorJson['message']?.toString() ?? "Operation failed";
      }
      // Fallback to splitting error string
      return error.toString().split('message":"').last.split('","').first;
    } catch (_) {
      return "Operation failed";
    }
  }

  void dispose() {
    if (!_createOrderController.isClosed) _createOrderController.close();
    if (!_fetchOrdersController.isClosed) _fetchOrdersController.close();
    if (!_updateOrderController.isClosed) _updateOrderController.close();
    if (!_applyCouponController.isClosed) _applyCouponController.close();
    if (!_deleteOrderItemController.isClosed) _deleteOrderItemController.close();
    if (!_applyDiscountController.isClosed) _applyDiscountController.close();
    if (!_changeOrderStatusController.isClosed) _changeOrderStatusController.close();
    if (!_addPayoutController.isClosed) _addPayoutController.close();
    if (!_removePayoutController.isClosed) _removePayoutController.close();
    if (!_removeCouponController.isClosed) _removeCouponController.close();
    if (!_fetchTotalOrdersController.isClosed) _fetchTotalOrdersController.close();
    if (kDebugMode) print("OrderBloc disposed with all controllers");
  }
}