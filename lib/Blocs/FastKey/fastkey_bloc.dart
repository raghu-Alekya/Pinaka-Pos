import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../Constants/text.dart';
import '../../Helper/api_response.dart';
import '../../Models/FastKey/fastkey_model.dart';
import '../../Repositories/FastKey/fastkey_repository.dart';
import '../../Database/fast_key_db_helper.dart';
import '../../Database/db_helper.dart';

class FastKeyBloc { // Build #1.0.15
  final FastKeyRepository _fastKeyRepository;

  // Stream Controllers
  final StreamController<APIResponse<FastKeyResponse>> _createFastKeyController =
  StreamController<APIResponse<FastKeyResponse>>.broadcast();

  final StreamController<APIResponse<FastKeyListResponse>> _getFastKeysController =
  StreamController<APIResponse<FastKeyListResponse>>.broadcast();

  // Getters for Streams
  StreamSink<APIResponse<FastKeyResponse>> get createFastKeySink => _createFastKeyController.sink;
  Stream<APIResponse<FastKeyResponse>> get createFastKeyStream => _createFastKeyController.stream;

  StreamSink<APIResponse<FastKeyListResponse>> get getFastKeysSink => _getFastKeysController.sink;
  Stream<APIResponse<FastKeyListResponse>> get getFastKeysStream => _getFastKeysController.stream;

  // Build #1.0.19: Fast Key Delete API Code
  final StreamController<APIResponse<FastKeyResponse>> _deleteFastKeyController =
  StreamController<APIResponse<FastKeyResponse>>.broadcast();

  StreamSink<APIResponse<FastKeyResponse>> get deleteFastKeySink => _deleteFastKeyController.sink;
  Stream<APIResponse<FastKeyResponse>> get deleteFastKeyStream => _deleteFastKeyController.stream;

  FastKeyBloc(this._fastKeyRepository) {
    if (kDebugMode) {
      print("FastKeyBloc Initialized");
    }
  }

  // POST: Create FastKey
  Future<void> createFastKey({required String title, required int index, required String imageUrl, required int userId}) async {
    if (_createFastKeyController.isClosed) return;

    createFastKeySink.add(APIResponse.loading(TextConstants.loading));
    try {
      final request = FastKeyRequest(
        fastkeyTitle: title,
        fastkeyIndex: index,
        fastkeyImage: imageUrl,
        userId: userId,
      );

      final response = await _fastKeyRepository.createFastKey(request);

      if (kDebugMode) {
        print("FastKeyBloc - Created FastKey: ${response.fastkeyId}");
      }
      createFastKeySink.add(APIResponse.completed(response));
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        createFastKeySink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        createFastKeySink.add(APIResponse.error("Failed to create FastKey: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in createFastKey: $e");
    }
  }

  // GET: Fetch FastKeys by User
  Future<void> fetchFastKeysByUser(int userId) async {
    if (_getFastKeysController.isClosed) return;

    getFastKeysSink.add(APIResponse.loading(TextConstants.loading));
    try {
      final response = await _fastKeyRepository.getFastKeysByUser();

      if (kDebugMode) {
        print("FastKeyBloc - Fetched ${response.fastkeys.length} fastkeys");
        print("Response: ${response}");
      }

      ///insert into DB

      final FastKeyDBHelper fastKeyDBHelper = FastKeyDBHelper();
      final fastKeyTabs = await fastKeyDBHelper.getFastKeyTabsByUserId(userId ?? 0);
      if (kDebugMode) {
        print("#### fastKeyTabs : $fastKeyTabs");
      }
      if(fastKeyTabs.length != response.fastkeys.length){
        ///if all the data mismatches then delete all db contents and replace with API response
        fastKeyDBHelper.deleteAllFastKeyTab(userId);
        for(var fastkey in response.fastkeys){
          await fastKeyDBHelper.addFastKeyTab(userId, fastkey.fastkeyTitle, "", 0, int.parse(fastkey.fastkeyIndex), fastkey.fastkeyServerId );
        }
      } else {
        ///else just update the data for each fast key
      //  var i = 0; ///@Naveen please correct this logic use tabid instead of i
        for (var fastkey in response.fastkeys) {
          // Try to find the matching local tab by server ID
          final matchingTab = fastKeyTabs.firstWhere(
                (tab) => tab[AppDBConst.fastKeyServerId] == fastkey.fastkeyServerId,
                orElse: () => {},
          );

          if (matchingTab.isNotEmpty) {
            final tabId = matchingTab[AppDBConst.fastKeyId];
            final updatedTab = {
              AppDBConst.fastKeyTabTitle: fastkey.fastkeyTitle.toString(),
              AppDBConst.fastKeyTabItemCount: fastkey.itemCount
            };
            await fastKeyDBHelper.updateFastKeyTab(tabId, updatedTab);

            if (kDebugMode) {
              print("Updated tab $tabId with title ${fastkey.fastkeyTitle}");
            }
          } else {
            if (kDebugMode) {
              print("No matching tab found for fastKeyServerId: ${fastkey.fastkeyServerId}");
            }
          }
        }
      }
      getFastKeysSink.add(APIResponse.completed(response));
    } catch (e, s) {
      if (e.toString().contains('SocketException')) {
        getFastKeysSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        getFastKeysSink.add(APIResponse.error("Failed to fetch FastKeys: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in fetchFastKeysByUser: $e , Stack: $s");
    }
  }

  // Build #1.0.19: Add this method to your FastKeyBloc class
  Future<void> deleteFastKey(int fastkeyServerId) async {
    if (_deleteFastKeyController.isClosed) return;

    deleteFastKeySink.add(APIResponse.loading(TextConstants.loading));
    try {
      final response = await _fastKeyRepository.deleteFastKey(fastkeyServerId);

      if (kDebugMode) {
        print("FastKeyBloc - Deleted FastKey: $fastkeyServerId");
      }
      deleteFastKeySink.add(APIResponse.completed(response));
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        deleteFastKeySink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        deleteFastKeySink.add(APIResponse.error("Failed to delete FastKey: ${e.toString()}"));
      }
      if (kDebugMode) print("Exception in deleteFastKey: $e");
    }
  }

// Update the dispose method to include the new controller
  void dispose() {
    if (!_createFastKeyController.isClosed) {
      _createFastKeyController.close();
    }
    if (!_getFastKeysController.isClosed) {
      _getFastKeysController.close();
    }
    if (!_deleteFastKeyController.isClosed) { // Build #1.0.19
      _deleteFastKeyController.close();
    }
    if (kDebugMode) print("FastKeyBloc disposed");
  }
}