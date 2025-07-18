// repositories/order_repository.dart
import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import '../../Constants/text.dart';
import '../../Helper/api_helper.dart';
import '../../Helper/url_helper.dart';
import '../../Models/Orders/apply_discount_model.dart';
import '../../Models/Orders/get_orders_model.dart';
import '../../Models/Orders/orders_model.dart';
import '../../Models/Orders/total_orders_count_model.dart';

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
  Future<OrderModel> updateOrderProducts({required int orderId, required UpdateOrderRequestModel request,}) async {
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
        return OrderModel.fromJson(responseData);
      } catch (e, s) {
        if (kDebugMode) print("Error parsing update order response: $e, Stack: $s");
        throw Exception("Failed to parse update order response");
      }
    } else if (response is Map<String, dynamic>) {
      return OrderModel.fromJson(response);
    } else {
      throw Exception("Unexpected response type in update order PUT");
    }
  }
  //Build #1.0.40: getOrders
  Future<OrdersListModel> getOrders({bool allStatuses = false, int pageNumber =1, int pageLimit = 10, String status = "", String orderType = "", String userId = ""}) async {
    //Build #1.0.54: added if allStatuses is true, include all statuses; otherwise, just "processing"
    final statusString = status != "" ? status : (allStatuses
        ? TextConstants.orderScreenStatus
        : TextConstants.processing);

    orderType = orderType != "" ? orderType : "";

    //"?page=1&per_page=10&search=&status="
    var getOrdersParameter = "?auther=$userId&page=$pageNumber&per_page=${pageLimit*3+1}&created_via=$orderType&search=&status=";
    // Encode for URL (spaces become '+', commas become '%2C')
    final encodedStatus = Uri.encodeQueryComponent(statusString);
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}"
        "$getOrdersParameter$encodedStatus${UrlParameterConstants.getOrdersEndParameter}";

    if (kDebugMode) {
      print("OrderRepository - GET URL: $url");
    }

    try {
      final response = await _helper.get(url, true);

      if (kDebugMode) {
        print("OrderRepository - Raw Response Type: ${response.runtimeType}");
        print("OrderRepository - Raw Response: ${response.toString()}");
      }

      // Handle case where response is already a List<dynamic>
      if (response is List<dynamic>) {
        return OrdersListModel.fromJson(response);
      }
      // Handle case where response might be a String that needs parsing
      else if (response is String) {
        final parsed = jsonDecode(response);
        if (parsed is List<dynamic>) {
          return OrdersListModel.fromJson(parsed);
        }
        throw Exception("Unexpected parsed response type: ${parsed.runtimeType}");
      }
      // Handle any other unexpected type
      else {
        throw Exception("Unexpected response type: ${response.runtimeType}");
      }
    } catch (e,s) {
      if (kDebugMode) {
        print("OrderRepository - Error in getOrders: $e");
        print("Stack trace: $s");
      }
      throw Exception("Failed to fetch orders: $e");
    }
  }

  // Build #1.0.118: Fetch Total Orders Count API Call for Orders Screen
  Future<TotalOrdersResponseModel> fetchTotalOrdersCount({bool allStatuses = false, int pageNumber =1, int pageLimit = 10, String status = "", String orderType = "", String userId = ""}) async {

    final statusString = status != "" ? status : (allStatuses
        ? TextConstants.orderScreenStatus
        : TextConstants.processing);

    orderType = orderType != "" ? orderType : "";

    var getOrdersParameter = "?auther=$userId&page=$pageNumber&per_page=$pageLimit&created_via=$orderType&search=&status=";
    // Encode for URL (spaces become '+', commas become '%2C')
    final encodedStatus = Uri.encodeQueryComponent(statusString);
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}/${UrlMethodConstants.totalOrders}$getOrdersParameter$encodedStatus${UrlParameterConstants.getOrdersEndParameter}";

    if (kDebugMode) {
      print("OrderRepository - GET URL: $url");
    }

    try {
      final response = await _helper.get(url, true);

      if (kDebugMode) {
        print("OrderRepository - Raw Response Type: ${response.runtimeType}");
        print("OrderRepository - Raw Response: ${response.toString()}");
      }

      if (response is String) {
        final responseData = json.decode(response);
        return TotalOrdersResponseModel.fromJson(responseData);
      } else if (response is Map<String, dynamic>) {
        return TotalOrdersResponseModel.fromJson(response);
      } else {
        throw Exception("Unexpected response type in fetch total orders GET");
      }
    } catch (e, s) {
      if (kDebugMode) {
        print("OrderRepository - Error in fetchTotalOrders: $e, Stack: $s");
      }
      throw Exception("Failed to fetch total orders");
    }
  }

  Future<OrderModel> getOrder({required String orderId}) async {

    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}$orderId";

    if (kDebugMode) {
      print("OrderRepository.getOrder - GET URL: $url");
    }

    try {
      final response = await _helper.get(url, true);

      if (kDebugMode) {
        print("OrderRepository - Raw Response Type: ${response.runtimeType}");
        print("OrderRepository - Raw Response: ${response.toString()}");
      }
      if (response is String) {
          return OrderModel.fromJson(jsonDecode(response));
      }
      // Handle any other unexpected type
      else {
        throw Exception("Unexpected response type: ${response.runtimeType}");
      }
    } catch (e,s) {
      if (kDebugMode) {
        print("OrderRepository - Error in getOrders: $e");
        print("Stack trace: $s");
      }
      throw Exception("Failed to fetch orders");
    }
  }

  // 3. Apply Coupon to Order
  Future<OrderModel> applyCouponToOrder({required int orderId, required ApplyCouponRequestModel request,}) async {
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
        return OrderModel.fromJson(responseData);  //Build #1.0.92: Updated: using OrderModel rather than UpdateOrderResponseModel
      } catch (e) {
        if (kDebugMode) print("Error parsing apply coupon response: $e");
        throw Exception("Failed to parse apply coupon response");
      }
    } else if (response is Map<String, dynamic>) {
      return OrderModel.fromJson(response);
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

  // Build #1.0.49: Added changeOrderStatus api call code
  Future<UpdateOrderResponseModel> changeOrderStatus({required int orderId, required OrderStatusRequest request}) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}/$orderId";

    if (kDebugMode) {
      print("OrderRepository - POST URL for status change: $url");
      print("OrderRepository - Request Body: ${request.toJson()}");
    }

    final response = await _helper.post(url, request.toJson(), true);

    if (kDebugMode) {
      print("OrderRepository - Change status Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return UpdateOrderResponseModel.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing change order status response: $e");
        throw Exception("Failed to parse change order status response");
      }
    } else if (response is Map<String, dynamic>) {
      return UpdateOrderResponseModel.fromJson(response);
    } else {
      throw Exception("Unexpected response type in change order status POST");
    }
  }

  // Build #1.0.49: Added applyDiscount api call code
  Future<ApplyDiscountResponse> applyDiscount(int orderId, String discountCode) async {
    String url = "${UrlHelper.baseUrl}${UrlParameterConstants.applyDiscount}$orderId";

    if (kDebugMode) {
      print("ProductRepository - ApplyDiscount URL: $url");
    }

    final body = {
      'discount_code': discountCode,
    };

    final response = await _helper.post(url, body, true);

    if (kDebugMode) {
      print("ProductRepository - ApplyDiscount Raw Response: $response");
    }

    if (response is String) {
      try {
        final Map<String, dynamic> responseData = json.decode(response);
        return ApplyDiscountResponse.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) {
          print("ProductRepository - Error parsing apply discount response: $e");
        }
        throw Exception("Failed to parse apply discount response");
      }
    } else if (response is Map<String, dynamic>) {
      return ApplyDiscountResponse.fromJson(response);
    } else {
      throw Exception("Unexpected response type");
    }
  }

  // Build #1.0.53 : Add Payout to Order
  Future<OrderModel> addPayout({required int orderId, required AddPayoutRequestModel request}) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}/$orderId";

    if (kDebugMode) {
      print("OrderRepository - POST URL for add payout: $url");
      print("OrderRepository - Request Body: ${request.toJson()}");
    }

    final response = await _helper.post(url, request.toJson(), true);

    if (kDebugMode) {
      print("OrderRepository - Add Payout Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return OrderModel.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing add payout response: $e");
        throw Exception("Failed to parse add payout response");
      }
    } else if (response is Map<String, dynamic>) {
      return OrderModel.fromJson(response);
    } else {
      throw Exception("Unexpected response type in add payout POST");
    }
  }

  // Build #1.0.53 : Remove Payout from Order
  Future<OrderModel> removeFeeLine({required int orderId, required RemoveFeeLinesRequestModel request}) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}/$orderId";

    if (kDebugMode) {
      print("OrderRepository - PUT URL for remove fee line: $url");
      print("OrderRepository - Request Body: ${request.toJson()}");
    }

    final response = await _helper.put(url, request.toJson(), true);

    if (kDebugMode) {
      print("OrderRepository - Remove FeeLine Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return OrderModel.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing remove FeeLine response: $e");
        throw Exception("Failed to parse remove FeeLine response");
      }
    } else if (response is Map<String, dynamic>) {
      return OrderModel.fromJson(response);
    } else {
      throw Exception("Unexpected response type in remove FeeLine PUT");
    }
  }

  // Build #1.0.64: removeCoupon API call
  Future<OrderModel> removeCoupon({required int orderId, required RemoveCouponRequestModel request}) async {
    final url = "${UrlHelper.componentVersionUrl}${UrlMethodConstants.orders}/$orderId";

    if (kDebugMode) {
      print("OrderRepository - PUT URL for remove coupon: $url");
      print("OrderRepository - Request Body: ${request.toJson()}");
    }

    final response = await _helper.post(url, request.toJson(), true);

    if (kDebugMode) {
      print("OrderRepository - Remove Coupon Raw Response: $response");
    }

    if (response is String) {
      try {
        final responseData = json.decode(response);
        return OrderModel.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) print("Error parsing remove coupon response: $e");
        throw Exception("Failed to parse remove coupon response");
      }
    } else if (response is Map<String, dynamic>) {
      return OrderModel.fromJson(response);
    } else {
      throw Exception("Unexpected response type in remove coupon PUT");
    }
  }
}