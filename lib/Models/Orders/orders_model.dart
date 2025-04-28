// models/order/shared/order_meta_data.dart
class OrderMetaData {  // Build #1.0.25 - added by naveen
  final String key;
  final String value;
  static const String posDeviceId = "pos_device_id";
  static const String posPlacedBy = "pos_placed_by";

  OrderMetaData({required this.key, required this.value});

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }
}

// models/order/shared/order_line_item.dart
class OrderLineItem {
  final int productId;
  final int quantity;
  final int id;


  OrderLineItem({this.id = 0, this.productId = 0, required this.quantity});

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
    };
  }
}

// models/order/shared/order_line_item_response.dart
class OrderLineItemResponse {
  final int id;
  final String name;
  final int productId;
  final int quantity;
  final num price;

  OrderLineItemResponse({
    required this.id,
    required this.name,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  factory OrderLineItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderLineItemResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
    );
  }
}

// models/order/create_order_request_model.dart
class CreateOrderRequestModel {
  final String status;
  final String? currency;
  final List<OrderMetaData> metaData;
  final List<dynamic> feeLines;
  final List<OrderLineItem> lineItems;
  final List<dynamic> taxLines;

  CreateOrderRequestModel({
    this.status = 'processing',
    this.currency,
    required this.metaData,
    this.feeLines = const [],
    this.lineItems = const [],
    this.taxLines = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'currency': currency,
      'meta_data': metaData.map((e) => e.toJson()).toList(),
      'fee_lines': feeLines,
      'line_items': lineItems.map((e) => e.toJson()).toList(),
      'tax_lines': taxLines,
    };
  }
}

// models/order/create_order_response_model.dart
class CreateOrderResponseModel {
  final int id;
  final int parentId;
  final String status;
  final String currency;

  CreateOrderResponseModel({
    required this.id,
    required this.parentId,
    required this.status,
    required this.currency,
  });

  factory CreateOrderResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponseModel(
      id: json['id'] ?? 0,
      parentId: json['parent_id'] ?? 0,
      status: json['status'] ?? '',
      currency: json['currency'] ?? '',
    );
  }
}

// models/order/update_order_request_model.dart
class UpdateOrderRequestModel {
  final List<OrderLineItem> lineItems;

  UpdateOrderRequestModel({
    required this.lineItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'line_items': lineItems.map((e) => e.toJson()).toList(),
    };
  }
}

// models/order/update_order_response_model.dart
class UpdateOrderResponseModel {
  final int id;
  final String status;
  final String total;
  final List<OrderLineItemResponse> lineItems;

  UpdateOrderResponseModel({
    required this.id,
    required this.status,
    required this.total,
    required this.lineItems,
  });

  factory UpdateOrderResponseModel.fromJson(Map<String, dynamic> json) {
    return UpdateOrderResponseModel(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      total: json['total'] ?? '0.00',
      lineItems: (json['line_items'] as List<dynamic>?)
          ?.map((e) => OrderLineItemResponse.fromJson(e))
          .toList() ??
          [],
    );
  }
}

// models/order/apply_coupon_request_model.dart
class ApplyCouponRequestModel {
  final List<CouponLine> couponLines;

  ApplyCouponRequestModel({
    required this.couponLines,
  });

  Map<String, dynamic> toJson() {
    return {
      'coupon_lines': couponLines.map((e) => e.toJson()).toList(),
    };
  }
}

class CouponLine {
  final String code;

  CouponLine({
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
    };
  }
}