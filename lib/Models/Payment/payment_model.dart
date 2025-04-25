// models/payment/payment_request_model.dart
class PaymentRequestModel {  // Build #1.0.25 - added by naveen
  final String title;
  final int orderId;
  final double amount;
  final String paymentMethod;
  final int shiftId;
  final int vendorId;
  final int userId;
  final String serviceType;
  final String datetime;
  final String notes;

  PaymentRequestModel({
    required this.title,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.shiftId,
    required this.vendorId,
    required this.userId,
    required this.serviceType,
    required this.datetime,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'order_id': orderId,
      'amount': amount,
      'payment_method': paymentMethod,
      'shift_id': shiftId,
      'vendor_id': vendorId,
      'user_id': userId,
      'service_type': serviceType,
      'datetime': datetime,
      'notes': notes,
    };
  }
}

// models/payment/payment_response_model.dart
class PaymentResponseModel {
  final int postId;
  final String message;

  PaymentResponseModel({
    required this.postId,
    required this.message,
  });

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      postId: json['post_id'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

// models/payment/payment_detail_model.dart
class PaymentDetailModel {
  final int id;
  final String title;
  final String date;
  final String orderId;
  final String amount;
  final String paymentMethod;
  final String shiftId;
  final String vendorId;
  final String userId;
  final String serviceType;
  final String datetime;
  final String notes;
  final String transactionId;
  final String transactionDetails;

  PaymentDetailModel({
    required this.id,
    required this.title,
    required this.date,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.shiftId,
    required this.vendorId,
    required this.userId,
    required this.serviceType,
    required this.datetime,
    required this.notes,
    required this.transactionId,
    required this.transactionDetails,
  });

  factory PaymentDetailModel.fromJson(Map<String, dynamic> json) {
    return PaymentDetailModel(
      id: json['ID'] ?? 0,
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      orderId: json['order_id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      paymentMethod: json['payment_method'] ?? '',
      shiftId: json['shift_id']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      serviceType: json['service_type'] ?? '',
      datetime: json['datetime'] ?? '',
      notes: json['notes'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      transactionDetails: json['transaction_details'] ?? '',
    );
  }
}

// models/payment/payment_list_model.dart
class PaymentListModel {
  final int id;
  final String postAuthor;
  final String postDate;
  final String postTitle;
  final String orderId;
  final String amount;
  final String paymentMethod;
  final String shiftId;
  final String vendorId;
  final String userId;
  final String serviceType;
  final String datetime;
  final String notes;

  PaymentListModel({
    required this.id,
    required this.postAuthor,
    required this.postDate,
    required this.postTitle,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.shiftId,
    required this.vendorId,
    required this.userId,
    required this.serviceType,
    required this.datetime,
    required this.notes,
  });

  factory PaymentListModel.fromJson(Map<String, dynamic> json) {
    return PaymentListModel(
      id: json['ID'] ?? 0,
      postAuthor: json['post_author']?.toString() ?? '',
      postDate: json['post_date'] ?? '',
      postTitle: json['post_title'] ?? '',
      orderId: json['order_id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      paymentMethod: json['payment_method'] ?? '',
      shiftId: json['shift_id']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      serviceType: json['service_type'] ?? '',
      datetime: json['datetime'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}