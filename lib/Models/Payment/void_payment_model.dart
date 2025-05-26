// models/void_payment_model.dart
class VoidPaymentRequestModel { // Build #1.0.49: Added Void Payment model code
  final int orderId;
  final String paymentId;

  VoidPaymentRequestModel({required this.orderId, required this.paymentId});

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'payment_id': paymentId,
  };
}

class VoidPaymentResponseModel {
  final bool success;
  final String message;

  VoidPaymentResponseModel({required this.success, required this.message});

  factory VoidPaymentResponseModel.fromJson(Map<String, dynamic> json) =>
      VoidPaymentResponseModel(
        success: json['success'] ?? false,
        message: json['message'] ?? '',
      );
}