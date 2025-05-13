class AssetResponse { //Build #1.0.40
  final String baseUrl;
  final List<Media> media;
  final List<dynamic> taxes;
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
      baseUrl: json['base_url'] ?? '',
      media: (json['media'] as List<dynamic>?)
          ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      taxes: json['taxes'] ?? [],
      coupons: (json['coupons'] as List<dynamic>?)
          ?.map((e) => Coupon.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      orderStatuses: (json['order_statuses'] as List<dynamic>?)
          ?.map((e) => OrderStatus.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      currency: json['currency'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '',
      roles: (json['roles'] as List<dynamic>?)
          ?.map((e) => Role.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      subscriptionPlans:
      SubscriptionPlan.fromJson(json['subscription_plans'] ?? {}),
      storeDetails: StoreDetails.fromJson(json['store_details'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_url': baseUrl,
      'media': media.map((e) => e.toJson()).toList(),
      'taxes': taxes,
      'coupons': coupons.map((e) => e.toJson()).toList(),
      'order_statuses': orderStatuses.map((e) => e.toJson()).toList(),
      'currency': currency,
      'currency_symbol': currencySymbol,
      'roles': roles.map((e) => e.toJson()).toList(),
      'subscription_plans': subscriptionPlans.toJson(),
      'store_details': storeDetails.toJson(),
    };
  }
}

class Media {
  final int id;
  final String title;
  final String url;

  Media({
    required this.id,
    required this.title,
    required this.url,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
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
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      amount: json['amount'] ?? '',
      discountType: json['discount_type'] ?? '',
      usageLimit: json['usage_limit'] ?? '',
      expiryDate: json['expiry_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
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

  OrderStatus({
    required this.slug,
    required this.name,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
    };
  }
}

class Role {
  final String slug;
  final String name;

  Role({
    required this.slug,
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
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
  final bool storeId;

  SubscriptionPlan({
    required this.type,
    required this.key,
    required this.expiration,
    required this.origin,
    required this.storeId,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      type: json['type'] ?? '',
      key: json['key'] ?? '',
      expiration: json['expiration'] ?? '',
      origin: json['origin'] ?? '',
      storeId: json['store_id'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'key': key,
      'expiration': expiration,
      'origin': origin,
      'store_id': storeId,
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
  final bool phoneNumber;

  StoreDetails({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    required this.phoneNumber,
  });

  factory StoreDetails.fromJson(Map<String, dynamic> json) {
    return StoreDetails(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zip_code'] ?? '',
      phoneNumber: json['phone_number'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
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