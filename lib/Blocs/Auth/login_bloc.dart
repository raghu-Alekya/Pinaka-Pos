import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../Constants/text.dart';
import '../../Database/db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Helper/api_response.dart';
import '../../Helper/file_helper.dart';
import '../../Models/Auth/login_model.dart';
import '../../Repositories/Auth/login_repository.dart';

class LoginBloc { // Build #1.0.8
  final UserDbHelper _userDbHelper = UserDbHelper();
  final LoginRepository _loginRepository;
  final StreamController<APIResponse<LoginResponse>> _loginController = StreamController<APIResponse<LoginResponse>>.broadcast();

  StreamSink<APIResponse<LoginResponse>> get loginSink => _loginController.sink;
  Stream<APIResponse<LoginResponse>> get loginStream => _loginController.stream;

  LoginBloc(this._loginRepository) {
    if (kDebugMode) {
      print("************** LoginBloc Initialized");
    }
  }

  // In LoginBloc.dart
  Future<void> fetchLoginToken(LoginRequest request) async { // Build #1.0.13: Added Login request
    if (_loginController.isClosed) return;

    loginSink.add(APIResponse.loading(TextConstants.loading));
    try {
      String token = await _loginRepository.fetchLoginToken(request);
      LoginResponse loginResponse = LoginResponse.fromJson(json.decode(token));

      if (loginResponse.token != null && loginResponse.success == true) {
        // Save user data in SQLite if not already exists
        final existingUser = await _userDbHelper.getUserData();
        if (existingUser == null ||
            existingUser[AppDBConst.userToken] != loginResponse.token) {
          await _userDbHelper.saveUserData(loginResponse); // Build #1.0.13: Saving Login Response in DB adn using from DB
        }
        loginSink.add(APIResponse.completed(loginResponse));
      } else {
        // Show the exact error message from API
        loginSink.add(APIResponse.error(
            loginResponse.message ?? "Invalid PIN or user not found."));
      }
    } catch (e, s) {
      // Handle specific API error response
      if (e.toString().contains('invalid_pin')) {
        loginSink.add(APIResponse.error("Invalid PIN or user not found."));
      } else if (e.toString().contains('SocketException')) {
        loginSink.add(APIResponse.error("Network error. Please check your connection."));
      } else {
        loginSink.add(APIResponse.error("An error occurred. Please try again."));
      }
      if (kDebugMode) print("Exception in LoginBlock.fetchLoginToken: $e; Stack: $s");
    }
  }

  void dispose() {
    if (!_loginController.isClosed) {
      _loginController.close();
      if (kDebugMode) print("LoginBloc disposed");
    }
  }
}
