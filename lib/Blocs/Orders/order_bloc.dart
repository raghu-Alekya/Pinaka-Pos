// blocs/order_bloc.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../Constants/text.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Helper/api_response.dart';
import '../../Models/Orders/apply_discount_model.dart';
import '../../Models/Orders/get_orders_model.dart';
import '../../Models/Orders/orders_model.dart';
import '../../Repositories/Orders/order_repository.dart';

class OrderBloc { // Build #1.0.25 - added by naveen
  final OrderRepository _orderRepository;

  // Build #1.0.53 : updated code - Stream Controllers ---
  late  StreamController<APIResponse<CreateOrderResponseModel>> _createOrderController;
  late  StreamController<APIResponse<UpdateOrderResponseModel>> _updateOrderController;
  late  StreamController<APIResponse<UpdateOrderResponseModel>> _applyCouponController;
  late  StreamController<APIResponse<UpdateOrderResponseModel>> _deleteOrderItemController;
  late  StreamController<APIResponse<ApplyDiscountResponse>> _applyDiscountController;
  late  StreamController<APIResponse<UpdateOrderResponseModel>> _changeOrderStatusController;
  late  StreamController<APIResponse<OrdersListModel>> _fetchOrdersController;
  late  StreamController<APIResponse<UpdateOrderResponseModel>> _addPayoutController;
  late  StreamController<APIResponse<UpdateOrderResponseModel>> _removePayoutController;

  // Build #1.0.53 : updated code -  Constructor ---
  OrderBloc(this._orderRepository) {
    _createOrderController = StreamController<APIResponse<CreateOrderResponseModel>>.broadcast();
    _updateOrderController = StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();
    _applyCouponController = StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();
    _deleteOrderItemController = StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();
    _applyDiscountController = StreamController<APIResponse<ApplyDiscountResponse>>.broadcast();
    _changeOrderStatusController = StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();
    _fetchOrdersController = StreamController<APIResponse<OrdersListModel>>.broadcast();
    _addPayoutController = StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();
    _removePayoutController = StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();

    if (kDebugMode) {
      print("OrderBloc Initialized with all stream controllers.");
    }
  }

  // Build #1.0.53 : updated code -  Getters for Streams and Sinks ---
  // Create Order
  StreamSink<APIResponse<CreateOrderResponseModel>> get createOrderSink => _createOrderController.sink;
  Stream<APIResponse<CreateOrderResponseModel>> get createOrderStream => _createOrderController.stream;

  // Update Order
  StreamSink<APIResponse<UpdateOrderResponseModel>> get updateOrderSink => _updateOrderController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get updateOrderStream => _updateOrderController.stream;

  // Apply Coupon
  StreamSink<APIResponse<UpdateOrderResponseModel>> get applyCouponSink => _applyCouponController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get applyCouponStream => _applyCouponController.stream;

  // Delete Order Item
  StreamSink<APIResponse<UpdateOrderResponseModel>> get deleteOrderItemSink => _deleteOrderItemController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get deleteOrderItemStream => _deleteOrderItemController.stream;

  // Apply Discount
  StreamSink<APIResponse<ApplyDiscountResponse>> get applyDiscountSink => _applyDiscountController.sink;
  Stream<APIResponse<ApplyDiscountResponse>> get applyDiscountStream => _applyDiscountController.stream;

  // Change Order Status
  StreamSink<APIResponse<UpdateOrderResponseModel>> get changeOrderStatusSink => _changeOrderStatusController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get changeOrderStatusStream => _changeOrderStatusController.stream;

  // Fetch Orders
  StreamSink<APIResponse<OrdersListModel>> get fetchOrdersSink => _fetchOrdersController.sink;
  Stream<APIResponse<OrdersListModel>> get fetchOrdersStream => _fetchOrdersController.stream;

  // Add Payout
  StreamSink<APIResponse<UpdateOrderResponseModel>> get addPayoutSink => _addPayoutController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get addPayoutStream => _addPayoutController.stream;

  // Remove Payout
  StreamSink<APIResponse<UpdateOrderResponseModel>> get removePayoutSink => _removePayoutController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get removePayoutStream => _removePayoutController.stream;


  // 1. Create Order
  Future<void> createOrder(List<OrderMetaData> metaData) async {
    _createOrderController = StreamController<APIResponse<CreateOrderResponseModel>>.broadcast();
    if (_createOrderController.isClosed) return;

    createOrderSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final request = CreateOrderRequestModel(metaData: metaData);
      final response = await _orderRepository.createOrder(request);

      if (kDebugMode) {
        print("OrderBloc - Order created with ID: ${response.id}");
        print("OrderBloc - Order Status: ${response.status}");
      }

      ///update orderServerId to DB
      OrderHelper orderHelper = OrderHelper();
      orderHelper.updateServerOrderIDInDB(response.id);
      createOrderSink.add(APIResponse.completed(response));
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        createOrderSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        createOrderSink.add(APIResponse.error("Failed to create order: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in createOrder: $e");
    }
  }

  // 2. Update Order Products
  Future<void> updateOrderProducts({required int orderId, required int dbOrderId, required List<OrderLineItem> lineItems}) async {
    if (_updateOrderController.isClosed) return;

    updateOrderSink.add(APIResponse.loading(TextConstants.loading));
    try {

      // final itemsToAdd = lineItems.map((item) => OrderLineItem(
      //   productId: item.productId,
      //   quantity: item.quantity, // Setting quantity to 0 removes the item
      // )).toList();

      final request = UpdateOrderRequestModel(lineItems: lineItems);
      final response = await _orderRepository.updateOrderProducts(
        orderId: orderId,
        request: request,
      );

      if (kDebugMode) {
        print("OrderBloc - Order updated with ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
        print("OrderBloc - Line items count: ${response.lineItems.length}");
      }
       //Build 1.1.36: working on updating order items in db getting issue.....
      // OrderHelper orderHelper = OrderHelper();
      // // Clear existing items for this order
      // await orderHelper.clearOrderItems(dbOrderId);
      //
      // // Add updated items from the API response
      // for (var lineItem in response.lineItems) {
      //   if (kDebugMode) {
      //     print("### Debug 124");
      //   }
      //
      //   await orderHelper.addItemToOrder(
      //     lineItem.name,
      //     lineItem.image['src'] ?? '', // Fixed: Access 'src' key from image Map
      //     double.parse(lineItem.price.toString()), // Ensure price is parsed correctly
      //     lineItem.quantity,
      //     lineItem.sku,
      //   );
     // }

      updateOrderSink.add(APIResponse.completed(response));
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        updateOrderSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        updateOrderSink.add(APIResponse.error("Failed to update order: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in updateOrderProducts: $e");
    }
  }

  //Build #1.0.40: fetchOrders
  Future<void> fetchOrders({bool allStatuses = false}) async { //Build #1.0.54: updated
    if (_fetchOrdersController.isClosed) return;

    fetchOrdersSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final response = await _orderRepository.getOrders(allStatuses: allStatuses); //Build #1.0.54: updated

      if (kDebugMode) {
        print("OrderBloc - Fetched ${response.orders.length} orders");
        for (var order in response.orders) {
          print("OrderBloc - Order ID: ${order.id}, Status: ${order.status}, Items: ${order.lineItems.length}");
          for (var item in order.lineItems) {
            print("OrderBloc - Item ID: ${item.id}, Name: ${item.name}, Price: ${item.price}, Quantity: ${item.quantity}");
          }
        }
      }

      fetchOrdersSink.add(APIResponse.completed(response));
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        fetchOrdersSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        fetchOrdersSink.add(APIResponse.error("Failed to fetch orders: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in fetchOrders: $e");
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

      if (kDebugMode) {
        print("OrderBloc - Coupon applied to order ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
        print("OrderBloc - Order Status: ${response.status}");
      }

      applyCouponSink.add(APIResponse.completed(response));
    } catch (e) {
      applyCouponSink.add(APIResponse.error(_extractErrorMessage(e))); // Build #1.0.53 : Extracting the message from error
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
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        changeOrderStatusSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        changeOrderStatusSink.add(APIResponse.error("Failed to change order status: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in changeOrderStatus: $e");
    }
  }
  // 5. Delete Order Item
  Future<void> deleteOrderItem({
    required int orderId,
    required List<OrderLineItem> lineItems,
  }) async {
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

      if (kDebugMode) {
        print("OrderBloc - Item deleted from order ID: ${response.id}");
        print("OrderBloc - Updated total: ${response.total}");
        print("OrderBloc - Remaining items: ${response.lineItems.length}");
      }

      deleteOrderItemSink.add(APIResponse.completed(response));
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        deleteOrderItemSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        deleteOrderItemSink.add(APIResponse.error("Failed to delete order item: ${e.toString()}"));
      }
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
      if (e.toString().contains('SocketException')) {
        applyDiscountSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        applyDiscountSink.add(APIResponse.error("Failed to apply discount"));
      }
      if (kDebugMode) print("ProductBloc - Exception in applyDiscount: $e");
    }
  }

  // Build #1.0.53 : Add Payout to Order
  Future<void> addPayout({required int orderId, required double amount, required bool isPayOut}) async {
    if (_addPayoutController.isClosed) return;

    addPayoutSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final AddPayoutRequestModel request;
      if (isPayOut == true) {
        request = AddPayoutRequestModel(
          feeLines: [
            FeeLine(
              name: TextConstants.payout,
              taxStatus: TextConstants.none,
              total: "-${amount.toStringAsFixed(2)}",
              originalValue: amount.toStringAsFixed(2),
            )
          ],
        );
      } else {
        request = AddPayoutRequestModel(
          feeLines: [
            FeeLine(
              name: TextConstants.discountText,
              taxStatus: TextConstants.none,
              total: "-${amount.toStringAsFixed(2)}",
              originalValue: amount.toStringAsFixed(2),
            )
          ],
        );
      }
      final response = await _orderRepository.addPayout(orderId: orderId, request: request);

      if (kDebugMode) {
        print("OrderBloc - Payout added to order ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
      }

      addPayoutSink.add(APIResponse.completed(response));
    } catch (e) {
      addPayoutSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in addPayout: $e");
    }
  }

  // Build #1.0.53 : Remove Payout from Order
  Future<void> removePayout({required int orderId, required int payoutId}) async {
    if (_removePayoutController.isClosed) return;

    removePayoutSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final request = RemovePayoutRequestModel(
        feeLines: [FeeLine(id: payoutId, name: null)],
      );
      final response = await _orderRepository.removePayout(orderId: orderId, request: request);

      if (kDebugMode) {
        print("OrderBloc - Payout removed from order ID: ${response.id}");
        print("OrderBloc - New total: ${response.total}");
      }

      removePayoutSink.add(APIResponse.completed(response));
    } catch (e) {
      removePayoutSink.add(APIResponse.error(_extractErrorMessage(e)));
      if (kDebugMode) print("Exception in removePayout: $e");
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
    if (kDebugMode) print("OrderBloc disposed with all controllers");
  }
}