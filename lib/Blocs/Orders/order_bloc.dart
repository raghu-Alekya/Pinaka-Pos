// blocs/order_bloc.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Constants/text.dart';
import '../../Helper/api_response.dart';
import '../../Models/Orders/orders_model.dart';
import '../../Repositories/Orders/order_repository.dart';

class OrderBloc { // Build #1.0.25 - added by naveen
  final OrderRepository _orderRepository;

  // Stream Controllers
  final StreamController<APIResponse<CreateOrderResponseModel>> _createOrderController =
  StreamController<APIResponse<CreateOrderResponseModel>>.broadcast();

  final StreamController<APIResponse<UpdateOrderResponseModel>> _updateOrderController =
  StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();

  final StreamController<APIResponse<UpdateOrderResponseModel>> _applyCouponController =
  StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();

  final StreamController<APIResponse<UpdateOrderResponseModel>> _deleteOrderItemController =
  StreamController<APIResponse<UpdateOrderResponseModel>>.broadcast();

  // Getters for Streams
  StreamSink<APIResponse<CreateOrderResponseModel>> get createOrderSink => _createOrderController.sink;
  Stream<APIResponse<CreateOrderResponseModel>> get createOrderStream => _createOrderController.stream;

  StreamSink<APIResponse<UpdateOrderResponseModel>> get updateOrderSink => _updateOrderController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get updateOrderStream => _updateOrderController.stream;

  StreamSink<APIResponse<UpdateOrderResponseModel>> get applyCouponSink => _applyCouponController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get applyCouponStream => _applyCouponController.stream;

  StreamSink<APIResponse<UpdateOrderResponseModel>> get deleteOrderItemSink => _deleteOrderItemController.sink;
  Stream<APIResponse<UpdateOrderResponseModel>> get deleteOrderItemStream => _deleteOrderItemController.stream;

  OrderBloc(this._orderRepository) {
    if (kDebugMode) {
      print("OrderBloc Initialized with all 4 order APIs");
    }
  }

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
  Future<void> updateOrderProducts({required int orderId, required List<OrderLineItem> lineItems}) async {
    if (_updateOrderController.isClosed) return;

    updateOrderSink.add(APIResponse.loading(TextConstants.loading));
    try {
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
      if (e.toString().contains('SocketException')) {
        applyCouponSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        applyCouponSink.add(APIResponse.error("Failed to apply coupon: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in applyCouponToOrder: $e");
    }
  }

  // 4. Delete Order Item
  Future<void> deleteOrderItem({
    required int orderId,
    required List<OrderLineItem> lineItems,
  }) async {
    if (_deleteOrderItemController.isClosed) return;

    deleteOrderItemSink.add(APIResponse.loading(TextConstants.loading));
    try {
      // For deletion, we set quantity to 0 for the items to be removed
      final itemsToDelete = lineItems.map((item) => OrderLineItem(
        productId: item.productId,
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

  void dispose() {
    if (!_createOrderController.isClosed) _createOrderController.close();
    if (!_updateOrderController.isClosed) _updateOrderController.close();
    if (!_applyCouponController.isClosed) _applyCouponController.close();
    if (!_deleteOrderItemController.isClosed) _deleteOrderItemController.close();
    if (kDebugMode) print("OrderBloc disposed with all controllers");
  }
}