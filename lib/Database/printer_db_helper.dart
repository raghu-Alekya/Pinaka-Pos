import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:pinaka_pos/Utilities/printer_settings.dart';

import 'db_helper.dart';

class PrinterDBHelper {
  static final PrinterDBHelper _instance = PrinterDBHelper._internal();
  factory PrinterDBHelper() => _instance;

  PrinterDBHelper._internal() {
    if (kDebugMode) {
      print("#### FastKeyDBHelper initialized!");
    }
  }

  Future<int> addPrinterToDB(BluetoothPrinter printer) async {
    final db = await DBHelper.instance.database;
    final int device;
    var printerDB = await getPrinterFromDB();

    if(printerDB.isEmpty){
      ///insert
      device = await db.insert(AppDBConst.printerTable, {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId: printer.productId,
        AppDBConst.printerVendorId: printer.vendorId,
        AppDBConst.printerType: EnumToString.convertToString(printer.typePrinter),
      });
    } else {
      ///update
      device = await db.update(AppDBConst.printerTable, {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId: printer.productId,
        AppDBConst.printerVendorId: printer.vendorId,
        AppDBConst.printerType: EnumToString.convertToString(printer.typePrinter),
      },
        where: '${AppDBConst.printerId} = ?',
        whereArgs: [1],
      );
    }

    if (kDebugMode) {
      print("#### Printer added in DB with deviceName: ${printer.deviceName}");
    }
    return device;
  }

  Future<int> updatePrinterToDB(BluetoothPrinter printer) async {
    final db = await DBHelper.instance.database;
    final device = await db.update(AppDBConst.printerTable, {
        AppDBConst.printerDeviceName: printer.deviceName,
        AppDBConst.printerProductId: printer.productId,
        AppDBConst.printerVendorId: printer.vendorId,
        AppDBConst.printerType: EnumToString.convertToString(printer.typePrinter),
      },
      where: '${AppDBConst.printerId} = ?',
      whereArgs: [1],
    );

    if (kDebugMode) {
      print("#### Printer added in DB with deviceName: ${printer.deviceName}");
    }
    return device;
  }

  Future<List<Map<String, dynamic>>> getPrinterFromDB() async {
    final db = await DBHelper.instance.database;
    final printerDevice = await db.query(
      AppDBConst.printerTable,
      where: '${AppDBConst.printerId} = ?',
      whereArgs: [1],
    );

    if (kDebugMode) {
      print("#### Retrieved printerDevice '${printerDevice.length}' from DB");
    }
    if(printerDevice.isNotEmpty){
      if (kDebugMode) {
        print("#### Retrieved printerDevice '${printerDevice.first[AppDBConst.printerDeviceName]}' from DB");
      }
    }
    return printerDevice;
  }
}