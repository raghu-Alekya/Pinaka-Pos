// Asset Model
class AssetResponse {
  final String baseUrl;
  final List<Media> media;
  final List<Tax> taxes;
  final List<Coupon> coupons;
  final List<OrderStatus> orderStatuses;
  final String currency;
  final String currencySymbol;
  final List<Role> roles;
  final SubscriptionPlan subscriptionPlans;
  final StoreDetails storeDetails;

  AssetResponse({
    required this.baseUrl,
    required this.media,
    required this.taxes,
    required this.coupons,
    required this.orderStatuses,
    required this.currency,
    required this.currencySymbol,
    required this.roles,
    required this.subscriptionPlans,
    required this.storeDetails,
  });

  factory AssetResponse.fromJson(Map<String, dynamic> json) {
    return AssetResponse(
      baseUrl: json['base_url']?.toString() ?? '',
      media: (json['media'] as List<dynamic>?)
          ?.map((item) => Media.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      taxes: (json['taxes'] as List<dynamic>?)
          ?.map((item) => Tax.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      coupons: (json['coupons'] as List<dynamic>?)
          ?.map((item) => Coupon.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      orderStatuses: (json['order_statuses'] as List<dynamic>?)
          ?.map((item) => OrderStatus.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      currency: json['currency']?.toString() ?? '',
      currencySymbol: json['currency_symbol']?.toString() ?? '',
      roles: (json['roles'] as List<dynamic>?)
          ?.map((item) => Role.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      subscriptionPlans: SubscriptionPlan.fromJson(
          json['subscription_plans'] as Map<String, dynamic>? ?? {}),
      storeDetails: StoreDetails.fromJson(
          json['store_details'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class Media {
  final int id;
  final String title;
  final String url;

  Media({required this.id, required this.title, required this.url});

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
    };
  }
}

class Tax {
  final String id;
  final String name;
  final String? className;
  final String? rate;
  final String? country;
  final String? state;
  final String? priority;
  final String? compound;
  final String? shipping;
  final List<String>? postcode;
  final int? postcodeCount;
  final int? cityCount;

  Tax({
    required this.id,
    required this.name,
     this.className,
     this.rate,
     this.country,
     this.state,
     this.priority,
     this.compound,
     this.shipping,
     this.postcode,
     this.postcodeCount,
     this.cityCount,
  });

  factory Tax.fromJson(Map<String, dynamic> json) {
    // Handle both API response (postcode as List) and database (postcode as String)
    List<String> postcodeList;
    if (json['postcode'] is List) {
      // From API response
      postcodeList = (json['postcode'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [];
    } else {
      // From database, where postcode is a comma-separated string
      postcodeList = json['postcode']?.toString().split(',') ?? [];
      // Remove empty entries if the string is empty
      postcodeList = postcodeList.where((item) => item.isNotEmpty).toList();
    }

    return Tax(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      className: json['class']?.toString() ?? '',
      rate: json['rate']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      compound: json['compound']?.toString() ?? '',
      shipping: json['shipping']?.toString() ?? '',
      postcode: postcodeList,
      postcodeCount: int.tryParse(json['postcode_count']?.toString() ?? '0') ?? 0,
      cityCount: int.tryParse(json['city_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'class': className,
      'rate': rate,
      'country': country,
      'state': state,
      'priority': priority,
      'compound': compound,
      'shipping': shipping,
      'postcode': postcode?.join(','),
      'postcode_count': postcodeCount,
      'city_count': cityCount,
    };
  }
}

class Coupon {
  final int id;
  final String code;
  final String amount;
  final String discountType;
  final String usageLimit;
  final String expiryDate;

  Coupon({
    required this.id,
    required this.code,
    required this.amount,
    required this.discountType,
    required this.usageLimit,
    required this.expiryDate,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? '',
      usageLimit: json['usage_limit']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'amount': amount,
      'discount_type': discountType,
      'usage_limit': usageLimit,
      'expiry_date': expiryDate,
    };
  }
}

class OrderStatus {
  final String slug;
  final String name;

  OrderStatus({required this.slug, required this.name});

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'name': name,
    };
  }
}

class Role {
  final String slug;
  final String name;

  Role({required this.slug, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'name': name,
    };
  }
}

class SubscriptionPlan {
  final String type;
  final String key;
  final String expiration;
  final String origin;
  final String storeId; // Changed from bool to String

  SubscriptionPlan({
    required this.type,
    required this.key,
    required this.expiration,
    required this.origin,
    required this.storeId,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      type: json['type']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      expiration: json['expiration']?.toString() ?? '',
      origin: json['origin']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '', // Changed to String
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'key': key,
      'expiration': expiration,
      'origin': origin,
      'store_id': storeId, // Updated to handle String
    };
  }
}

class StoreDetails {
  final String name;
  final String address;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String? phoneNumber; // Changed to String? to handle potential phone numbers or null

  StoreDetails({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    this.phoneNumber, // Nullable to handle missing or varied data
  });

  factory StoreDetails.fromJson(Map<String, dynamic> json) {
    return StoreDetails(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      zipCode: json['zip_code']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(), // Handle as String or null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip_code': zipCode,
      'phone_number': phoneNumber,
    };
  }
}