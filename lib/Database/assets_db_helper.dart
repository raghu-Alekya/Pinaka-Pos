import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import '../Models/Assets/asset_model.dart';
import 'db_helper.dart';

class AssetDBHelper { //Build #1.0.54: added
  // Singleton instance to ensure only one instance of AssetDBHelper
  static final AssetDBHelper instance = AssetDBHelper._init();
  AssetDBHelper._init();

  Future<Database> get database async {
    if (kDebugMode) print("#### AssetDBHelper: Accessing database via DBHelper");
    return await DBHelper.instance.database;
  }

  // // Getter for the database instance
  // Future<Database> get database async {
  //   if (_database != null) {
  //     if (kDebugMode) {
  //       print("#### AssetDBHelper: Reusing existing database instance");
  //     }
  //     return _database!;
  //   }
  //   _database = await _initDB(AppDBConst.dbName);
  //   return _database!;
  // }

  // Initialize the database with the specified file path
  // Future<Database> _initDB(String filePath) async {
  //   final dbPath = await getDatabasesPath();
  //   final path = join(dbPath, filePath);
  //   if (kDebugMode) {
  //     print("#### AssetDBHelper: Initializing database at path: $path");
  //   }
  //   return await openDatabase(path, version: 1);
  // }

  // Save asset response to database within a transaction
  Future<void> saveAssets(AssetResponse assetResponse) async {
    if (kDebugMode) {
      print("#### AssetDBHelper: Starting to save assets to database");
    }
    final db = await database;
    await db.transaction((txn) async {
      try {
        int assetId = await txn.insert(AppDBConst.assetTable, {
          AppDBConst.baseUrl: assetResponse.baseUrl,
          AppDBConst.currency: assetResponse.currency,
          AppDBConst.currencySymbol: assetResponse.currencySymbol,
        });

      if (kDebugMode) {
        print("#### AssetDBHelper: Inserted asset with ID: $assetId");
      }

      // Insert Media
      for (var media in assetResponse.media) {
        await txn.insert(AppDBConst.mediaTable, {
          ...media.toMap(),
          AppDBConst.assetId: assetId,
        });
        if (kDebugMode) {
          print("#### AssetDBHelper: Inserted media with ID: ${media.id}");
        }
      }

        // Insert Taxes
        for (var tax in assetResponse.taxes) {
          var taxData = tax.toMap();
          if (kDebugMode) print("#### Inserting tax data: $taxData");
          try {
            int rowsAffected = await txn.insert(
              AppDBConst.taxTable,
              {
                ...taxData,
                AppDBConst.assetId: assetId,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            if (kDebugMode) print("#### Inserted tax with ID: ${tax.id}, Rows affected: $rowsAffected");
          } catch (e) {
            if (kDebugMode) print("#### Error inserting tax ID: ${tax.id}, Error: $e");
            rethrow;
          }
        }

      // Insert Coupons
      for (var coupon in assetResponse.coupons) {
        await txn.insert(AppDBConst.couponTable, {
          ...coupon.toMap(),
          AppDBConst.assetId: assetId,
        });
        if (kDebugMode) {
          print("#### AssetDBHelper: Inserted coupon with ID: ${coupon.id}");
        }
      }

      // Insert Order Statuses
      for (var status in assetResponse.orderStatuses) {
        await txn.insert(AppDBConst.orderStatusTable, {
          ...status.toMap(),
          AppDBConst.assetId: assetId,
        });
        if (kDebugMode) {
          print("#### AssetDBHelper: Inserted order status with slug: ${status.slug}");
        }
      }

      // Insert Roles
      for (var role in assetResponse.roles) {
        await txn.insert(AppDBConst.roleTable, {
          ...role.toMap(),
          AppDBConst.assetId: assetId,
        });
        if (kDebugMode) {
          print("#### AssetDBHelper: Inserted role with slug: ${role.slug}");
        }
      }

      // Insert Subscription Plan
      await txn.insert(AppDBConst.subscriptionPlanTable, {
        ...assetResponse.subscriptionPlans.toMap(),
        AppDBConst.assetId: assetId,
      });
      if (kDebugMode) {
        print("#### AssetDBHelper: Inserted subscription plan");
      }

      // Insert Store Details
      await txn.insert(AppDBConst.storeDetailsTable, {
        ...assetResponse.storeDetails.toMap(),
        AppDBConst.assetId: assetId,
      });
      if (kDebugMode) {
        print("#### AssetDBHelper: Inserted store details");
      }
    } catch (e) {
      if (kDebugMode) print("#### AssetDBHelper: Error saving assets: $e");
      rethrow;
      }
    });
  }


  // Retrieve the base URL from the asset table
  Future<String?> getAppBaseUrl() async {
    if (kDebugMode) {
      print("#### AssetDBHelper: Fetching base URL");
    }
    final db = await database;
    final result = await db.query(AppDBConst.assetTable,
        columns: [AppDBConst.baseUrl], limit: 1);
    if (kDebugMode) {
      print("#### AssetDBHelper: Base URL query result: $result");
    }
    return result.isNotEmpty ? result.first[AppDBConst.baseUrl] as String? : null;
  }

  // Retrieve list of order statuses
  Future<List<OrderStatus>> getOrderStatusList() async {
    if (kDebugMode) {
      print("#### AssetDBHelper: Fetching order status list");
    }
    final db = await database;
    final result = await db.query(AppDBConst.orderStatusTable);
    if (kDebugMode) {
      print("#### AssetDBHelper: Retrieved ${result.length} order statuses");
    }
    return result.map((map) => OrderStatus.fromJson(map)).toList();
  }

  // Retrieve list of media
  Future<List<Media>> getMediaList() async {
    if (kDebugMode) {
      print("#### AssetDBHelper: Fetching media list");
    }
    final db = await database;
    final result = await db.query(AppDBConst.mediaTable);
    if (kDebugMode) {
      print("#### AssetDBHelper: Retrieved ${result.length} media items");
    }
    return result.map((map) => Media.fromJson(map)).toList();
  }

  // In AssetDBHelper, update getTaxList with detailed logging
  Future<List<Tax>> getTaxList() async {
    try {
      final db = await database;
      final result = await db.query(AppDBConst.taxTable);
      if (kDebugMode) print("#### AssetDBHelper: Retrieved ${result.length} taxes: ${result.toString()}}");
      return result.map((map) => Tax.fromJson(map)).toList();
    } catch (e) {
      if (kDebugMode) print("#### AssetDBHelper: Error fetching tax list: $e}");
      return [];
    }
  }

  // Retrieve list of coupons
  Future<List<Coupon>> getCouponList() async {
    if (kDebugMode) {
      print("#### AssetDBHelper: Fetching coupon list");
    }
    final db = await database;
    final result = await db.query(AppDBConst.couponTable);
    if (kDebugMode) {
      print("#### AssetDBHelper: Retrieved ${result.length} coupons");
    }
    return result.map((map) => Coupon.fromJson(map)).toList();
  }

  // Retrieve list of roles
  Future<List<Role>> getRoleList() async {
    if (kDebugMode) {
      print("#### AssetDBHelper: Fetching role list");
    }
    final db = await database;
    final result = await db.query(AppDBConst.roleTable);
    if (kDebugMode) {
      print("#### AssetDBHelper: Retrieved ${result.length} roles");
    }
    return result.map((map) => Role.fromJson(map)).toList();
  }

  // Retrieve subscription plan
  Future<SubscriptionPlan?> getSubscriptionPlan() async {
    if (kDebugMode) {
      print("#### AssetDBHelper: Fetching subscription plan");
    }
    final db = await database;
    final result = await db.query(AppDBConst.subscriptionPlanTable, limit: 1);
    if (kDebugMode) {
      print("#### AssetDBHelper: Subscription plan query result: $result");
    }
    return result.isNotEmpty ? SubscriptionPlan.fromJson(result.first) : null;
  }

  // Retrieve store details
  Future<StoreDetails?> getStoreDetails() async {
    if (kDebugMode) {
      print("#### AssetDBHelper: Fetching store details");
    }
    final db = await database;
    final result = await db.query(AppDBConst.storeDetailsTable, limit: 1);
    if (kDebugMode) {
      print("#### AssetDBHelper: Store details query result: $result");
    }
    return result.isNotEmpty ? StoreDetails.fromJson(result.first) : null;
  }

  // Close the database connection
  Future<void> close() async {
    if (kDebugMode) {
      print("#### AssetDBHelper: Closing database connection");
    }
    final db = await database;
    await db.close();
    if (kDebugMode) {
      print("#### AssetDBHelper: Database connection closed!");
    }
  }
}