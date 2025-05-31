import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../Database/assets_db_helper.dart';

class UrlHelper {
  static const Map<String, String> environment = {
    _dev : "DEV",
    _prod : "PROD",
    _uat : "UAT",
    _AndroidApiKey : "ANDROID"
  };
//Hosts
  static const String _dev = "https://pinakapos.techkumard.com"; // Build #1.1.36: Base URL without /wp-json/
  static const  String _uat = "http://uatapi.pinaka.com/";
  static const  String _prod = "http://api.pinaka.com/";

  //API keys
  static const  String _AndroidApiKey = "?apikey=987654321";
  static const  String _iOSApiKey = "?apikey=123456789";

  // API path components
  static const String pinakaPosV1 = "pinaka-pos/v1/"; // New variable for pinaka-pos/v1
  static const String wooCommerceV3 = "wc/v3/"; // New variable for wc/v3
  static const String wpJson = "wp-json/"; // WP JSON API base path

  //Build #1.0.54: added Dynamic base URL initialized from database
  static String? _baseUrl;
  // Initialize base URL from database
  static Future<void> initializeBaseUrl() async {
    if (kDebugMode) {
      print("#### UrlHelper: Initializing base URL from database");
    }
    _baseUrl = await AssetDBHelper.instance.getAppBaseUrl();
    if (_baseUrl == null) {
      if (kDebugMode) {
        print("#### UrlHelper: No base URL in database, falling back to DEV: $_dev");
      }
      _baseUrl = _dev; // Fallback to dev URL if database is empty
    }
    if (kDebugMode) {
      print("#### UrlHelper: Base URL set to: $_baseUrl");
    }
  }

  //Build #1.0.54: Getter for base URL with /wp-json/ appended
  static String get baseUrl {
    final url = '$_baseUrl/$wpJson';
    if (kDebugMode) {
      print("#### UrlHelper: Providing base URL: $url");
    }
    return url;
  }
/////START: make changes here to switch environment
//   static const  String host = _dev ;
//   static const  String baseUrl = host;
  static const String componentVersionUrl = pinakaPosV1; // Default to pinaka-pos/v1 for existing APIs
  // static const  String apiKey = _devApiKey ;
  static final String apiKey = Platform.isIOS ? _iOSApiKey : _AndroidApiKey; // Build #1.0.8, Naveen updated this line

  // static String get apiKey => _apiKey;///do not change this setting in any circumstances
  //
  // static set apiKey(String value) {
  //   if(Platform.isIOS) {
  //     _apiKey = _iOSApiKey;
  //   } else if(Platform.isAndroid) {
  //     _apiKey = _AndroidApiKey;
  //   }
  // }
  /////END: make changes here to switch environment

  static const  String clientID = "IOS";
  static String confirmSuccessUrl = baseUrl;
  static String markerUrl =  baseUrl;

  static const  String login = "${pinakaPosV1}token"; // Build #1.0.8
  static const  String refresh = "auth/refresh_token";
  static const  String signup = "auth/signup";
  static const  String forgotPassword = "auth/reestpassword";
  static const  String updatePassword = "auth/update_password";
  static const  String myProfile = "profile/view";
  static const  String updateMyProfile = "profile/update";
  static const  String deleteProfile = "auth/logout";

  static const  String assets = "assets/public";

  static const String validateMerchant = "https://mg.techkumard.com/wp-json/custom/v1/validate-marchent";  //Build #1.0.42

}

class UrlMethodConstants { // Build #1.0.13
  static const String token          = "token";
  static const String products       = "products";
  static const String fastKeys       = "fastkeys";  // Build #1.0.15
  static const String categories           = "categories";
  static const String productByCategories  = "products-by-category"; // Build #1.0.21
  static const String payments             = "payments";
  static const String orders               = "orders";
  static const String variations           = "products"; // Used for variations endpoint
  static const String assets               = "assets"; //Build #1.0.40
}

class UrlParameterConstants { // Build #1.0.13
  static const  String productSearchParameter = "?search=";
  static const  String getOrdersParameter     = "?page=1&per_page=10&search=&status="; //Build #1.0.40
  static const  String getOrdersEndParameter  = "&show_un_paid_only=false";

  static const  String productBySku           = "?sku=";
  static const  String applyDiscount          = "custom-discount/apply/";  // Build #1.0.49
}

class EndUrlConstants { // Build #1.0.13
  static const  String productSearchEndUrl = "&page=1&limit=10";
  static const  String createFastKeyEndUrl        = "/create";  // Build #1.0.15
  static const  String getFastKeyEndUrl           = "/get-by-user";
  static const  String addFastKeyProductEndUrl    = "/add-products";
  static const  String getFastKeyProductsEndUrl   = "/get-by-fastkey-id/";
  static const String deleteFastKeyEndUrl         = "/delete-fastkey"; // Build #1.0.19
  static const String allCategoriesEndUrl         = "?page=1&per_page=100&hide_empty=true&parent="; // Build #1.0.21
  static const String createPaymentEndUrl         = "/create-payment";  // Build #1.0.25
  static const String paymentByIdEndUrl           = "/get-payment-by-id?payment_id=";
  static const String paymentByOrderIdEndUrl      = "/get-payments-by-order-id?order_id=";
  static const String variationsEndUrl            = "/variations"; //Build 1.1.36
  static const String voidPaymentEndUrl           = "/void-payment";  // Build #1.0.49
}

