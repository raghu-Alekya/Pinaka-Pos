// models/category_product_model.dart
class CategoryProduct{ // Build #1.0.21
  final int id;
  final String name;
  final String slug;
  final String status;
  final String description;
  final String shortDescription;
  final String sku;
  final String price;
  final String regularPrice;
  final String salePrice;
  final bool onSale;
  final bool purchasable;
  final String stockStatus;
  final List<String> categories;
  final List<String> images;
  final List<dynamic> attributes;

  CategoryProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.description,
    required this.shortDescription,
    required this.sku,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.purchasable,
    required this.stockStatus,
    required this.categories,
    required this.images,
    required this.attributes,
  });

  factory CategoryProduct.fromJson(Map<String, dynamic> json) {
    return CategoryProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      sku: json['sku'] ?? '',
      price: json['price'] ?? '0',
      regularPrice: json['regular_price'] ?? '0',
      salePrice: json['sale_price'] ?? '0',
      onSale: json['on_sale'] ?? false,
      purchasable: json['purchasable'] ?? false,
      stockStatus: json['stock_status'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      images: List<String>.from(
          (json['images'] as List?)?.map((img) => img.toString()) ?? []),
      attributes: json['attributes'] ?? [],
    );
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