class OrdersListModel { //Build #1.0.40
  final List<OrderModel> orders;

  OrdersListModel({required this.orders});

  factory OrdersListModel.fromJson(List<dynamic> json) {
    return OrdersListModel(
      orders: json.map((item) => OrderModel.fromJson(item)).toList(),
    );
  }
}

class OrderModel {
  final int id;
  final int parentId;
  final String status;
  final String currency;
  final String version;
  final bool pricesIncludeTax;
  final String dateCreated;
  final String dateModified;
  final String discountTotal;
  final String discountTax;
  final String shippingTotal;
  final String shippingTax;
  final String cartTax;
  final String total;
  final String totalTax;
  final int customerId;
  final String orderKey;
  final Billing billing;
  final Shipping shipping;
  final List<LineItem> lineItems;
  List<FeeLine>? feeLines;    // For payout and discount data
  List<CouponLine>? couponLines; // For coupon data
  final List<MetaData> metaData;
  final String? datePaid;
  final String? dateCompleted;
  final String paymentMethod;
  final String paymentMethodTitle;
  final String number;
  final String currencySymbol;

  OrderModel({
    required this.id,
    required this.parentId,
    required this.status,
    required this.currency,
    required this.version,
    required this.pricesIncludeTax,
    required this.dateCreated,
    required this.dateModified,
    required this.discountTotal,
    required this.discountTax,
    required this.shippingTotal,
    required this.shippingTax,
    required this.cartTax,
    required this.total,
    required this.totalTax,
    required this.customerId,
    required this.orderKey,
    required this.billing,
    required this.shipping,
    required this.lineItems,
    this.feeLines,
    this.couponLines,
    required this.metaData,
    this.datePaid,
    this.dateCompleted,
    required this.paymentMethod,
    required this.paymentMethodTitle,
    required this.number,
    required this.currencySymbol,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      parentId: json['parent_id'] ?? 0,
      status: json['status'] ?? '',
      currency: json['currency'] ?? 'INR',
      version: json['version'] ?? '',
      pricesIncludeTax: json['prices_include_tax'] ?? false,
      dateCreated: json['date_created'] ?? '',
      dateModified: json['date_modified'] ?? '',
      discountTotal: json['discount_total'] ?? '0.00',
      discountTax: json['discount_tax'] ?? '0.00',
      shippingTotal: json['shipping_total'] ?? '0.00',
      shippingTax: json['shipping_tax'] ?? '0.00',
      cartTax: json['cart_tax'] ?? '0.00',
      total: json['total'] ?? '0.00',
      totalTax: json['total_tax'] ?? '0.00',
      customerId: json['customer_id'] ?? 0,
      orderKey: json['order_key'] ?? '',
      billing: Billing.fromJson(json['billing'] ?? {}),
      shipping: Shipping.fromJson(json['shipping'] ?? {}),
      lineItems: (json['line_items'] as List<dynamic>?)
          ?.map((item) => LineItem.fromJson(item))
          .toList() ??
          [],
      feeLines: (json['fee_lines'] as List<dynamic>?)?.map((e) => FeeLine.fromJson(e as Map<String, dynamic>)).toList(),
      couponLines: (json['coupon_lines'] as List<dynamic>?)?.map((e) => CouponLine.fromJson(e as Map<String, dynamic>)).toList(),
      metaData: (json['meta_data'] as List<dynamic>?)
          ?.map((item) => MetaData.fromJson(item))
          .toList() ??
          [],
      datePaid: json['date_paid'],
      dateCompleted: json['date_completed'],
      paymentMethod: json['payment_method'] ?? '',
      paymentMethodTitle: json['payment_method_title'] ?? '',
      number: json['number'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '₹',
    );
  }
}

class FeeLine {// Build #1.0.64
  int? id;
  String? name;
  String? taxClass;
  String? taxStatus;
  String? amount;
  String? total;
  String? totalTax;
  List<dynamic>? taxes;
  List<dynamic>? metaData;

  FeeLine({
    this.id,
    this.name,
    this.taxClass,
    this.taxStatus,
    this.amount,
    this.total,
    this.totalTax,
    this.taxes,
    this.metaData,
  });

  factory FeeLine.fromJson(Map<String, dynamic> json) {
    return FeeLine(
      id: json['id'] as int?,
      name: json['name'] as String?,
      taxClass: json['tax_class'] as String?,
      taxStatus: json['tax_status'] as String?,
      amount: json['amount'] as String?,
      total: json['total'] as String?,
      totalTax: json['total_tax'] as String?,
      taxes: json['taxes'] as List<dynamic>?,
      metaData: json['meta_data'] as List<dynamic>?,
    );
  }
}

class CouponLine { // Build #1.0.64
  int? id;
  String? code;
  String? discount;
  String? discountTax;
  double? nominalAmount;
  String? discountType;
  bool? freeShipping;
  List<MetaData>? metaData;

  CouponLine({
    this.id,
    this.code,
    this.discount,
    this.discountTax,
    this.nominalAmount,
    this.discountType,
    this.freeShipping,
    this.metaData,
  });

  factory CouponLine.fromJson(Map<String, dynamic> json) {
    return CouponLine(
      id: json['id'] as int?,
      code: json['code'] as String?,
      discount: json['discount'] as String?,
      discountTax: json['discount_tax'] as String?,
      nominalAmount: double.tryParse(json['nominal_amount'].toString()) ?? 0.0,
      discountType: json['discount_type'] as String?,
      freeShipping: json['free_shipping'] as bool?,
      metaData: (json['meta_data'] as List<dynamic>?)
          ?.map((item) => MetaData.fromJson(item))
          .toList(),
    );
  }
}

class Billing {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  Billing({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class Shipping {
  final String firstName;
  final String lastName;
  final String phone;

  Shipping({
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  factory Shipping.fromJson(Map<String, dynamic> json) {
    return Shipping(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class LineItem {
  final int id;
  final String name;
  final int quantity;
  final double price;
  final String? sku;
  final ImageData image;

  LineItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.sku,
    required this.image,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] is int ? json['price'].toDouble() : json['price']) ?? 0.0,
      sku: json['sku'],
      image: ImageData.fromJson(json['image'] ?? {}),
    );
  }
}

class MetaData {
  final int id;
  final String key;
  final dynamic value;

  MetaData({
    required this.id,
    required this.key,
    required this.value,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'],
    );
  }
}

class ImageData {
  final String id;
  final String src;

  ImageData({
    required this.id,
    required this.src,
  });

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      id: json['id']?.toString() ?? '0',
      src: json['src'] ?? '',
    );
  }
}

