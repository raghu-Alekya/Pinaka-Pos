import 'get_orders_model.dart' as get_orders; // Alias to avoid name conflicts

class TotalOrdersResponseModel { // Build #1.0.118: Updated this class from orders_screen
  final int orderTotalCount;
  final List<OrderList> ordersData;

  TotalOrdersResponseModel({
    required this.orderTotalCount,
    required this.ordersData,
  });

  factory TotalOrdersResponseModel.fromJson(Map<String, dynamic> json) {
    return TotalOrdersResponseModel(
      orderTotalCount: json['order_total_count'] ?? 0,
      ordersData: (json['orders_data'] as List<dynamic>?)
          ?.map((e) => OrderList.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'order_total_count': orderTotalCount,
    'orders_data': ordersData.map((e) => e.toJson()).toList(),
  };
}

class OrderList {
  final int id;
  final String status;
  final String total;
  final String currency;
  final String paymentMethod;
  final String dateCreated;
  final dynamic billing;
  final List<LineItem> lineItems;
  final String orderType;

  OrderList({
    required this.id,
    required this.status,
    required this.total,
    required this.currency,
    required this.paymentMethod,
    required this.dateCreated,
    required this.billing,
    required this.lineItems,
    required this.orderType,
  });

  factory OrderList.fromJson(Map<String, dynamic> json) {
    List<LineItem> lineItemsList = [];

    if (json['line_items'] != null) {
      if (json['line_items'] is List) {
        // Handle empty array or list case
        lineItemsList = [];
      } else if (json['line_items'] is Map) {
        // Handle map case by converting to list
        final lineItemsMap = json['line_items'] as Map<String, dynamic>;
        lineItemsList = lineItemsMap.values
            .map((item) => LineItem.fromJson(item))
            .toList();
      }
    }

    return OrderList(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      total: json['total']?.toString() ?? '0.0',
      currency: json['currency'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      dateCreated: json['date_created'] ?? '',
      billing: json['billing'] ?? '',
      lineItems: lineItemsList,
      orderType: json['order_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'total': total,
    'currency': currency,
    'payment_method': paymentMethod,
    'date_created': dateCreated,
    'billing': billing,
    'line_items': lineItems.map((item) => item.toJson()).toList(),
    'order_type': orderType,
  };

  // Convert OrderList to OrderModel for compatibility with syncOrdersFromApi
  get_orders.OrderModel toOrderModel() {
    return get_orders.OrderModel(
      id: id,
      parentId: 0,
      status: status,
      currency: currency,
      version: '',
      pricesIncludeTax: false,
      dateCreated: dateCreated,
      dateModified: dateCreated,
      discountTotal: '0.00',
      discountTax: '0.00',
      shippingTotal: '0.00',
      shippingTax: '0.00',
      cartTax: '0.00',
      total: total,
      totalTax: '0.00',
      customerId: 0,
      orderKey: '',
      billing: get_orders.Billing.fromJson(
        billing is Map
            ? {
          'first_name': billing['first_name'] ?? '',
          'last_name': billing['last_name'] ?? '',
          'email': billing['email'] ?? '',
          'phone': billing['phone'] ?? '',
        }
            : {},
      ),
      shipping: get_orders.Shipping.fromJson(
        billing is Map
            ? {
          'first_name': billing['first_name'] ?? '',
          'last_name': billing['last_name'] ?? '',
          'phone': billing['phone'] ?? '',
        }
            : {},
      ),
      lineItems: lineItems
          .map(
            (item) => get_orders.LineItem(
          id: item.id,
          name: item.name,
          quantity: item.quantity,
          productId: 0, // Default, as not provided in OrderList
          variationId: 0,
          taxClass: '',
          subtotal: item.subtotal,
          subtotalTax: '0.00',
          total: item.total,
          totalTax: '0.00',
          metaData: [],
          sku: '',
          price: double.tryParse(item.total) ?? 0.0,
          image: get_orders.ImageData(id: '0', src: ''),
          productData: get_orders.ProductData(
            id: 0,
            name: item.name,
            tags: [],
            variations: [],
            regularPrice: item.total,
            salePrice: '',
            price: item.total,
          ),
          productVariationData: null,
        ),
      )
          .toList(),
      feeLines: [],
      couponLines: [],
      metaData: [],
      datePaid: null,
      dateCompleted: null,
      paymentMethod: paymentMethod,
      createdVia: orderType.isNotEmpty ? orderType : 'rest-api',
      number: id.toString(),
      currencySymbol: currency == 'INR' ? '₹' : '',
    );
  }
}

class LineItem {
  final int id;
  final String name;
  final int quantity;
  final String total;
  final String subtotal;

  LineItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.total,
    required this.subtotal,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      total: json['total']?.toString() ?? '0.0',
      subtotal: json['subtotal']?.toString() ?? '0.0',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'total': total,
    'subtotal': subtotal,
  };
}