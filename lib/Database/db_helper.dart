import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDBConst { // Build #1.0.10 - Naveen: Updated DB tables constants
  static const String dbName = 'pinaka.db'; // Database name

  // User Table
  static const String userTable = 'user_table';
  static const String userId = 'user_id';
  static const String userRole = 'role';
  static const String userDisplayName = 'display_name';
  static const String userEmail = 'email';
  static const String userFirstName = 'first_name'; // Build #1.0.13: Updated User Table
  static const String userLastName = 'last_name';
  static const String userNickname = 'nickname';
  static const String userToken = 'token';
  static const String userOrderCount = 'order_count'; // Tracks total orders by the user

  // Orders Table
  static const String orderTable = 'orders_table';
  static const String orderId = 'orders_id';
  static const String orderTotal = 'total';
  static const String orderStatus = 'status'; // e.g., pending, completed, cancelled
  static const String orderType = 'type'; // e.g., online, in-store
  static const String orderDate = 'date'; // Order creation date
  static const String orderTime = 'time'; // Order creation time
  static const String orderPaymentMethod = 'payment_method'; // e.g., cash, card, UPI
  static const String orderDiscount = 'discount'; // Optional: Discount applied to the order
  static const String orderTax = 'tax'; // Optional: Tax applied to the order
  static const String orderShipping = 'shipping'; // Optional: Shipping charges

  // Purchased Items Table
  static const String purchasedItemsTable = 'purchased_items_table';
  static const String itemId = 'items_id';
  static const String itemName = 'item_name';
  static const String itemSKU = 'item_sku'; // Stock Keeping Unit (unique identifier for the product)
  static const String itemPrice = 'item_price';
  static const String itemImage = 'item_image';
  static const String itemCount = 'items_count'; // Quantity of the item
  static const String itemSumPrice = 'item_sum_price'; // Total price (quantity * price)
  static const String orderIdForeignKey = 'order_id'; // Links to the order this item belongs to

  // Build #1.0.11 : FastKey Tabs Table Updated
  static const String fastKeyTable = 'fast_key_tabs';
  static const String fastKeyId = 'fast_key_id';
  static const String fastKeyServerId = 'fast_key_server_id';
  static const String userIdForeignKey = 'user_id';
  static const String fastKeyTabTitle = 'fast_key_tab_title';
  static const String fastKeyTabImage = 'fast_key_tab_image';
  static const String fastKeyTabCount = 'fast_key_tab_count';
  static const String fastKeyTabIndex = 'fast_key_tab_index'; // Build #1.0.12
  static const String fastKeyTabSynced = 'synced'; // Build #1.0.15 : Tracks sync status

  // Build #1.0.11 : FastKey Items Table Added
  static const String fastKeyItemsTable = 'fast_key_items';
  static const String fastKeyItemId = 'fast_key_item_id';
  static const String fastKeyProductId = 'fast_key_product_id'; // Build #1.0.19: Updated new colum's
  static const String fastKeySlNumber = 'fast_key_sl_number';
  static const String fastKeyIdForeignKey = 'fast_key_id';
  static const String fastKeyItemName = 'fast_key_item_name';
  static const String fastKeyItemImage = 'fast_key_item_image';
  static const String fastKeyItemPrice = 'fast_key_item_price';
  static const String fastKeyItemSKU = 'fast_key_item_sku';
  static const String fastKeyItemVariantId = 'fast_key_item_variant_id';
}

class DBHelper {
  // Singleton instance to ensure only one instance of DBHelper exists
  static final DBHelper instance = DBHelper._init();
  DBHelper._init();
  Database? _database;

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppDBConst.dbName);
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    if (kDebugMode) {
      print("#### DB Path: $path");
    }
    // Uncomment the line below to delete the database during development/testing
    await deleteDatabase(path);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This removes all stored preferences

    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  // Create all tables in the database
  Future _createTables(Database db, int version) async {
    // User Table
    await db.execute('''
    CREATE TABLE ${AppDBConst.userTable} (
      ${AppDBConst.userId} INTEGER PRIMARY KEY,
      ${AppDBConst.userRole} TEXT,
      ${AppDBConst.userDisplayName} TEXT,
      ${AppDBConst.userEmail} TEXT UNIQUE NOT NULL,
      ${AppDBConst.userFirstName} TEXT,
      ${AppDBConst.userLastName} TEXT,
      ${AppDBConst.userNickname} TEXT,
      ${AppDBConst.userToken} TEXT NOT NULL,
      ${AppDBConst.userOrderCount} INTEGER DEFAULT 0 -- Optional: Tracks total orders by the user
    )
    ''');

    // Orders Table
    await db.execute('''
    CREATE TABLE ${AppDBConst.orderTable} (
      ${AppDBConst.orderId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${AppDBConst.userId} INTEGER NOT NULL,
      ${AppDBConst.orderTotal} REAL NOT NULL,
      ${AppDBConst.orderStatus} TEXT NOT NULL,
      ${AppDBConst.orderType} TEXT NOT NULL,
      ${AppDBConst.orderDate} TEXT NOT NULL,
      ${AppDBConst.orderTime} TEXT NOT NULL,
      ${AppDBConst.orderPaymentMethod} TEXT, -- Optional: Payment method (e.g., cash, card)
      ${AppDBConst.orderDiscount} REAL DEFAULT 0, -- Optional: Discount applied to the order
      ${AppDBConst.orderTax} REAL DEFAULT 0, -- Optional: Tax applied to the order
      ${AppDBConst.orderShipping} REAL DEFAULT 0, -- Optional: Shipping charges
      FOREIGN KEY(${AppDBConst.userId}) REFERENCES ${AppDBConst.userTable}(${AppDBConst.userId}) ON DELETE CASCADE
    )
    ''');

    // Purchased Items Table
    await db.execute('''
    CREATE TABLE ${AppDBConst.purchasedItemsTable} (
      ${AppDBConst.itemId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${AppDBConst.itemName} TEXT NOT NULL,
      ${AppDBConst.itemSKU} TEXT NOT NULL,
      ${AppDBConst.itemPrice} REAL NOT NULL,
      ${AppDBConst.itemImage} TEXT NOT NULL,
      ${AppDBConst.itemCount} INTEGER NOT NULL,
      ${AppDBConst.itemSumPrice} REAL NOT NULL,
      ${AppDBConst.orderIdForeignKey} INTEGER NOT NULL,
      FOREIGN KEY(${AppDBConst.orderIdForeignKey}) REFERENCES ${AppDBConst.orderTable}(${AppDBConst.orderId}) ON DELETE CASCADE
    )
    ''');

    // Build #1.0.11 : FastKey Tabs Table
    await db.execute('''
    CREATE TABLE ${AppDBConst.fastKeyTable} (
      ${AppDBConst.fastKeyId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${AppDBConst.fastKeyServerId} INTEGER NOT NULL,
      ${AppDBConst.userIdForeignKey} INTEGER NOT NULL,
      ${AppDBConst.fastKeyTabTitle} TEXT NOT NULL,
      ${AppDBConst.fastKeyTabImage} TEXT NOT NULL,
      ${AppDBConst.fastKeyTabCount} INTEGER NOT NULL,
      ${AppDBConst.fastKeyTabIndex} TEXT NOT NULL,
      ${AppDBConst.fastKeyTabSynced} INTEGER DEFAULT 0, -- 0 = false, 1 = true
      FOREIGN KEY(${AppDBConst.userIdForeignKey}) REFERENCES ${AppDBConst.userTable}(${AppDBConst.userId}) ON DELETE CASCADE
    )
    ''');

    // Build #1.0.11 : FastKey Product Items Table
    await db.execute('''
    CREATE TABLE ${AppDBConst.fastKeyItemsTable} (
      ${AppDBConst.fastKeyItemId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${AppDBConst.fastKeyIdForeignKey} INTEGER NOT NULL,
      ${AppDBConst.fastKeyItemName} TEXT NOT NULL,
      ${AppDBConst.fastKeyProductId} TEXT NOT NULL,
      ${AppDBConst.fastKeySlNumber} TEXT NOT NULL,
      ${AppDBConst.fastKeyItemImage} TEXT NOT NULL,
      ${AppDBConst.fastKeyItemPrice} REAL NOT NULL,
      ${AppDBConst.fastKeyItemSKU} TEXT NOT NULL,
      ${AppDBConst.fastKeyItemVariantId} TEXT NOT NULL,
      FOREIGN KEY(${AppDBConst.fastKeyIdForeignKey}) REFERENCES ${AppDBConst.fastKeyTable}(${AppDBConst.fastKeyId}) ON DELETE CASCADE
    )
    ''');

    if (kDebugMode) {
      print("#### All tables created successfully!");
    }
  }

  // Close the database connection
  Future<void> close() async {
    final db = await database;
    db.close();

    if (kDebugMode) {
      print("#### Database connection closed!");
    }
  }
}

