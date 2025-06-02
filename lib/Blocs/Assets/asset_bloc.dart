import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Constants/text.dart';
import '../../Database/assets_db_helper.dart';
import '../../Helper/api_response.dart';
import '../../Models/Assets/asset_model.dart';
import '../../Repositories/Assets/asset_repository.dart';

class AssetBloc { //Build #1.0.40
  final AssetRepository _assetRepository;
  final StreamController<APIResponse<AssetResponse>> _assetController =
  StreamController<APIResponse<AssetResponse>>.broadcast();

  StreamSink<APIResponse<AssetResponse>> get assetSink => _assetController.sink;
  Stream<APIResponse<AssetResponse>> get assetStream => _assetController.stream;

  AssetBloc(this._assetRepository) {
    if (kDebugMode) {
      print("************** AssetBloc Initialized");
    }
  }

  Future<void> fetchAssets() async {
    if (_assetController.isClosed) return;

    assetSink.add(APIResponse.loading(TextConstants.loading));
    try {
      AssetResponse assetResponse = await _assetRepository.getAssets();
      await AssetDBHelper.instance.saveAssets(assetResponse); //Build #1.0.54: Save to Assets DB
      assetSink.add(APIResponse.completed(assetResponse));
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        assetSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        assetSink.add(APIResponse.error("Failed to fetch assets: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in fetchAssets: $e");
    }
  }

  void dispose() {
    if (!_assetController.isClosed) {
      _assetController.close();
      if (kDebugMode) print("AssetBloc disposed");
    }
  }
}