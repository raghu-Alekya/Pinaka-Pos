import 'category_model.dart';

class CategoryProduct { // Build #1.0.157: Updated model with extra values
  final int id;
  final String name;
  final String slug;
  final String dateCreated;
  final String dateModified;
  final String status;
  final String description;
  final String shortDescription;
  final String sku;
  final String price;
  final String regularPrice;
  final String salePrice;
  final String? dateOnSaleFrom;
  final String? dateOnSaleTo;
  final bool onSale;
  final bool purchasable;
  final int stockQuantity;
  final String stockStatus;
  final String backorders;
  final bool backordersAllowed;
  final String lowStockAmount;
  final String weight;
  final Dimensions dimensions;
  final List<CategoryModel>? categories;
  final List<String> images;
  final List<Attribute> attributes;
  final List<Tags>? tags;
  final List<Map<String, dynamic>> metaData;
  final String permalink;
  final List<int> variations;
  final String type;

  CategoryProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.dateCreated,
    required this.dateModified,
    required this.status,
    required this.description,
    required this.shortDescription,
    required this.sku,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    this.dateOnSaleFrom,
    this.dateOnSaleTo,
    required this.onSale,
    required this.purchasable,
    required this.stockQuantity,
    required this.stockStatus,
    required this.backorders,
    required this.backordersAllowed,
    required this.lowStockAmount,
    required this.weight,
    required this.dimensions,
    required this.categories,
    required this.images,
    required this.attributes,
    this.tags,
    required this.metaData,
    required this.permalink,
    required this.variations,
    required this.type,
  });

  factory CategoryProduct.fromJson(Map<String, dynamic> json) {
    return CategoryProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      dateCreated: json['date_created'] ?? '',
      dateModified: json['date_modified'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      sku: json['sku'] ?? '',
      price: json['price'] ?? '0',
      regularPrice: json['regular_price'] ?? '',
      salePrice: json['sale_price'] ?? '',
      dateOnSaleFrom: json['date_on_sale_from'],
      dateOnSaleTo: json['date_on_sale_to'],
      onSale: json['on_sale'] ?? false,
      purchasable: json['purchasable'] ?? false,
      stockQuantity: json['stock_quantity'] ?? 0,
      stockStatus: json['stock_status'] ?? '',
      backorders: json['backorders'] ?? '',
      backordersAllowed: json['backorders_allowed'] ?? false,
      lowStockAmount: json['low_stock_amount'] ?? '',
      weight: json['weight'] ?? '',
      dimensions: Dimensions.fromJson(json['dimensions'] ?? {}),
      categories: json['categories'] != null
          ? List<CategoryModel>.from(json['categories'].map((x) => CategoryModel.fromJson(x)))
          : null,
      images: List<String>.from(
          (json['images'] as List?)?.map((img) => img.toString()) ?? []),
      attributes: json['attributes'] != null
          ? List<Attribute>.from(json['attributes'].map((x) => Attribute.fromJson(x)))
          : [],
      tags: json['tags'] != null
          ? List<Tags>.from(json['tags'].map((x) => Tags.fromJson(x)))
          : null,
      metaData: json['meta_data'] != null
          ? List<Map<String, dynamic>>.from(json['meta_data'].map((x) => Map<String, dynamic>.from(x)))
          : [],
      permalink: json['permalink'] ?? '',
      variations: json['variations'] != null
          ? List<int>.from(json['variations'].map((x) => x))
          : [],
      type: json['type'] ?? '',
    );
  }
}

class Dimensions {
  final String length;
  final String width;
  final String height;

  Dimensions({
    required this.length,
    required this.width,
    required this.height,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(
      length: json['length'] ?? '',
      width: json['width'] ?? '',
      height: json['height'] ?? '',
    );
  }
}

class Attribute {
  final String name;
  final List<String> values;
  final bool visible;
  final bool variation;

  Attribute({
    required this.name,
    required this.values,
    required this.visible,
    required this.variation,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      name: json['name'] ?? '',
      values: json['values'] != null
          ? List<String>.from(json['values'].map((x) => x.toString()))
          : [],
      visible: json['visible'] ?? false,
      variation: json['variation'] ?? false,
    );
  }
}

class Tags {
  int? id;
  String? name;
  String? slug;

  Tags({this.id, this.name, this.slug});

  factory Tags.fromJson(Map<String, dynamic> json) {
    return Tags(
      id: json['id'] as int?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

class CategoryProductListResponse {
  final List<CategoryProduct> products;

  CategoryProductListResponse({required this.products});

  factory CategoryProductListResponse.fromJson(List<dynamic> json) {
    return CategoryProductListResponse(
      products: json.map((item) => CategoryProduct.fromJson(item)).toList(),
    );
  }
}