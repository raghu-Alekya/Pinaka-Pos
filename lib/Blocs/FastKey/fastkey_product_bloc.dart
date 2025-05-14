import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Constants/text.dart';
import '../../Helper/api_response.dart';
import '../../Models/FastKey/fastkey_product_model.dart';
import '../../Repositories/FastKey/fastkey_product_repository.dart';
import '../../Database/fast_key_db_helper.dart';
import '../../Database/db_helper.dart';

class FastKeyProductBloc {  // Build #1.0.15
  final FastKeyProductRepository _repository;

  // Stream Controllers
  final StreamController<APIResponse<FastKeyProductResponse>> _addProductsController =
  StreamController<APIResponse<FastKeyProductResponse>>.broadcast();

  final StreamController<APIResponse<FastKeyProductsResponse>> _getProductsController =
  StreamController<APIResponse<FastKeyProductsResponse>>.broadcast();

  // Getters for Streams
  StreamSink<APIResponse<FastKeyProductResponse>> get addProductsSink => _addProductsController.sink;
  Stream<APIResponse<FastKeyProductResponse>> get addProductsStream => _addProductsController.stream;

  StreamSink<APIResponse<FastKeyProductsResponse>> get getProductsSink => _getProductsController.sink;
  Stream<APIResponse<FastKeyProductsResponse>> get getProductsStream => _getProductsController.stream;

  FastKeyProductBloc(this._repository) {
    if (kDebugMode) {
      print("FastKeyProductBloc Initialized");
    }
  }

  // POST: Add products to FastKey
  Future<void> addProducts({required int fastKeyId, required List<FastKeyProductItem> products}) async {
    if (_addProductsController.isClosed) return;

    addProductsSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final request = FastKeyProductRequest(
        fastKeyId: fastKeyId,
        products: products,
      );

      final response = await _repository.addProductsToFastKey(request);

      if (kDebugMode) {
        print("FastKeyProductBloc - Added products to FastKey: ${response.fastkeyId}");
      }
      addProductsSink.add(APIResponse.completed(response));
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        addProductsSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        addProductsSink.add(APIResponse.error("Failed to add products: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in addProducts: $e");
    }
  }

  // GET: Fetch products by FastKey ID
  Future<void> fetchProductsByFastKeyId(int fastKeyId, int fastKeyServerId) async {
    if (_getProductsController.isClosed) return;

    getProductsSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final response = await _repository.getProductsByFastKeyId(fastKeyServerId);

      if (kDebugMode) {
        print("FastKeyProductBloc - Fetched ${response.products.length} products for FastKey $fastKeyId, FastKeyServer $fastKeyServerId");
      }

      ///insert into DB

      final FastKeyDBHelper fastKeyDBHelper = FastKeyDBHelper();
      final fastKeyTabs = await fastKeyDBHelper.getFastKeyItems(fastKeyId);
      if (kDebugMode) {
        print("#### fastKeyTabs : $fastKeyTabs");
      }
      if(fastKeyTabs.length != response.products.length){
        ///if all the data mismatches then delete all db contents and replace with API response
        fastKeyDBHelper.deleteAllFastKeyProductItems(fastKeyId);
        for(var product in response.products){ ///Naveen: add few paramter as product_id, sl_number, and make price as string only
          fastKeyDBHelper.addFastKeyItem( // Build #1.0.19: Updated parameters
            fastKeyId,
            product.name,
            product.image,
            product.price, // Now stored as string
            product.productId,
            slNumber: product.slNumber);
        }
      } else {
        ///else just update the data for each fast key
        var i=0;
        for(var product in response.products){
          final updatedTab = { ///Naveen : please update the db with product id and category, sl_number
            AppDBConst.fastKeyItemName: product.name.toString(),
            AppDBConst.fastKeyItemPrice: product.price.toString(),
            AppDBConst.fastKeySlNumber: product.slNumber.toString(),
            AppDBConst.fastKeyItemImage: product.image.toString(),
            AppDBConst.fastKeyProductId: product.productId.toString(),  // Build #1.0.19: Updated parameters
          };
          fastKeyDBHelper.updateFastKeyProductItem(i++, updatedTab);
        }
      }

      getProductsSink.add(APIResponse.completed(response));
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        getProductsSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        getProductsSink.add(APIResponse.error("Failed to fetch products: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in fetchProductsByFastKeyId: $e");
    }
  }

  // Dispose all controllers
  void dispose() {
    if (!_addProductsController.isClosed) {
      _addProductsController.close();
    }
    if (!_getProductsController.isClosed) {
      _getProductsController.close();
    }
    if (kDebugMode) print("FastKeyProductBloc disposed");
  }
}