import 'package:flutter/foundation.dart';

class Misc{
  /// use this feature for testing only, not to be used for release builds
  static bool disablePrinter = kDebugMode ? false : false;
  static bool enableCategoryProductWithSubCategoryList = kDebugMode ? false : false;
  static bool enableDBDelete = kDebugMode ? false : false; //'true' to delete the database during development/testing, in Release pass it as false

  printFeatures(){
    if (kDebugMode) {
      print("enableCategoryProductWithSubCategoryList : $enableCategoryProductWithSubCategoryList");
      print("enableDBDelete                           : $enableDBDelete");
    }
  }
}