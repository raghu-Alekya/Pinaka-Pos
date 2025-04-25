// repositories/order_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../Helper/api_helper.dart';
import '../../Helper/url_helper.dart';
import '../../Models/Orders/orders_model.dart';

class OrderRepository {  // Build #1.0.25 - added by naveen
  final APIHelper _helper = APIHelper();

  // 1. Create Order
  Future<CreateOrderResponseModel> createOrder(CreateOrderRequestModel request) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}";

    if (kDebugMode) {
      print("OrderRepository - POST URL: $url");
      print("OrderRepository - Request Body: ${request.toJson()}");
    }

    final response = await _helper.post(url, request.toJson(), true);

    if (kDebugMode) {
      print("OrderRepository - Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return CreateOrderResponseModel.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing order response: $e");
        throw Exception("Failed to parse order response");
      }
    } else if (response is Map<String, dynamic>) {
      return CreateOrderResponseModel.fromJson(response);
    } else {
      throw Exception("Unexpected response type in order POST");
    }
  }

  // 2. Update Order Products
  Future<UpdateOrderResponseModel> updateOrderProducts({required int orderId, required UpdateOrderRequestModel request,}) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}/$orderId";

    if (kDebugMode) {
      print("OrderRepository - POST URL: $url");
      print("OrderRepository - Request Body: ${request.toJson()}");
    }

    final response = await _helper.post(url, request.toJson(), true);

    if (kDebugMode) {
      print("OrderRepository - Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return UpdateOrderResponseModel.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing update order response: $e");
        throw Exception("Failed to parse update order response");
      }
    } else if (response is Map<String, dynamic>) {
      return UpdateOrderResponseModel.fromJson(response);
    } else {
      throw Exception("Unexpected response type in update order PUT");
    }
  }

  // 3. Apply Coupon to Order
  Future<UpdateOrderResponseModel> applyCouponToOrder({required int orderId, required ApplyCouponRequestModel request,}) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}/$orderId";

    if (kDebugMode) {
      print("OrderRepository - POST URL: $url");
      print("OrderRepository - Request Body: ${request.toJson()}");
    }

    final response = await _helper.post(url, request.toJson(), true);

    if (kDebugMode) {
      print("OrderRepository - Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return UpdateOrderResponseModel.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing apply coupon response: $e");
        throw Exception("Failed to parse apply coupon response");
      }
    } else if (response is Map<String, dynamic>) {
      return UpdateOrderResponseModel.fromJson(response);
    } else {
      throw Exception("Unexpected response type in apply coupon POST");
    }
  }

  // 4. Delete Order Item (uses updateOrderProducts with quantity=0)
  Future<UpdateOrderResponseModel> deleteOrderItem({required int orderId, required UpdateOrderRequestModel request,}) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}/$orderId";

    if (kDebugMode) {
      print("OrderRepository - POST URL: $url");
      print("OrderRepository - Request Body (delete items): ${request.toJson()}");
    }

    final response = await _helper.post(url, request.toJson(), true);

    if (kDebugMode) {
      print("OrderRepository - Raw Response (delete): $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return UpdateOrderResponseModel.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing delete order item response: $e");
        throw Exception("Failed to parse delete order item response");
      }
    } else if (response is Map<String, dynamic>) {
      return UpdateOrderResponseModel.fromJson(response);
    } else {
      throw Exception("Unexpected response type in delete order item PUT");
    }
  }
}