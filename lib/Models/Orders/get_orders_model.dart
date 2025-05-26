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

