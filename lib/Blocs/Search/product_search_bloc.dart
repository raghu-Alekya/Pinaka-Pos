import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Constants/text.dart';
import '../../Helper/api_response.dart';
import '../../Models/Search/product_search_model.dart';
import '../../Models/Search/product_variation_model.dart';
import '../../Repositories/Search/product_search_repository.dart';

class ProductBloc { // Build #1.0.13: Added Product Search Bloc
  final ProductRepository _productRepository;
  late StreamController<APIResponse<List<ProductResponse>>> _productController;
  late StreamController<APIResponse<List<ProductVariation>>> _variationController;

  // Streams and sinks for products
  StreamController<APIResponse<List<ProductResponse>>> get productController => _productController;

  StreamSink<APIResponse<List<ProductResponse>>> get productSink => _productController.sink;
  Stream<APIResponse<List<ProductResponse>>> get productStream => _productController.stream;

  // Streams and sinks for variations
  StreamController<APIResponse<List<ProductVariation>>> get variationController => _variationController;
  StreamSink<APIResponse<List<ProductVariation>>> get variationSink => _variationController.sink;
  Stream<APIResponse<List<ProductVariation>>> get variationStream => _variationController.stream;

  ProductBloc(this._productRepository) {
    if (kDebugMode) {
      print("ProductBloc Initialized");
    }
    _productController = StreamController<APIResponse<List<ProductResponse>>>.broadcast();
    _variationController = StreamController<APIResponse<List<ProductVariation>>>.broadcast();
  }

  Future<void> fetchProducts({String? searchQuery}) async {
    if (_productController.isClosed) return;

    productSink.add(APIResponse.loading(TextConstants.loading));
    try {
      List<ProductResponse> products = await _productRepository.fetchProducts(searchQuery: searchQuery);

      if (products.isNotEmpty) {
        if (kDebugMode) {
          print("ProductBloc - Fetched ${products.length} products");
          print("First product: ${products.first.toJson()}");
        }
        productSink.add(APIResponse.completed(products));
      } else {
        productSink.add(APIResponse.error("No products found"));
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        productSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        productSink.add(APIResponse.error("No products found"));
      }
      if (kDebugMode) print("ProductBloc - Exception in fetchProducts: $e");
    }
  }

  //Build 1.1.36: Added Fetches product variations Api call
  Future<void> fetchProductVariations(int productId) async {
    if (_variationController.isClosed) {
      _variationController = StreamController<APIResponse<List<ProductVariation>>>.broadcast();
      if (kDebugMode) {
        print("ProductBloc - Reinitialized variationController");
      }
    }

    variationSink.add(APIResponse.loading("Loading variations..."));
    try {
      List<ProductVariation> variations = await _productRepository.fetchProductVariations(productId);

      if (variations.isNotEmpty) {
        if (kDebugMode) {
          print("ProductBloc - Fetched ${variations.length} variations for product $productId");
          print("First variation: ${variations.first.toJson()}");
        }
        variationSink.add(APIResponse.completed(variations));
      } else {
        if (kDebugMode) {
          print("ProductBloc - Fetched ${variations.length} variations for product $productId");
          print("No variations found");
        }
        variationSink.add(APIResponse.error("No variations found"));
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        variationSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        variationSink.add(APIResponse.error("Failed to fetch variations"));
      }
      if (kDebugMode) print("ProductBloc - Exception in fetchProductVariations: $e");
    }
  }

  void dispose() {
    if (!_productController.isClosed) {
      _productController.close();
      if (kDebugMode) print("ProductBloc - ProductController disposed");
    }
    if (!_variationController.isClosed) { //Build 1.1.36
      _variationController.close();
      if (kDebugMode) print("ProductBloc - VariationController disposed");
    }
  }
}