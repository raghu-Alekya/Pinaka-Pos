import 'dart:ffi';
import 'dart:io';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:pinaka_pos/Constants/text.dart';
import 'package:pinaka_pos/Database/db_helper.dart';
import 'package:pinaka_pos/Database/printer_db_helper.dart';
import 'package:pinaka_pos/Preferences/pinaka_preferences.dart';
import 'package:pinaka_pos/Utilities/result_utility.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/thermal_printer.dart';

import '../Screens/Home/Settings/printer_setup_screen.dart';

class PrinterSettings {

  PrinterSettings(){
    setSelectedPrinterFromDB();
  }

  var _reconnect = false;
  BTStatus _currentStatus = BTStatus.none;

  BluetoothPrinter? selectedPrinter;
  var printerManager = PrinterManager.instance;
  List<int>? pendingTask;
  final PrinterDBHelper _printerDBHelper = PrinterDBHelper();

  Future<void> loadPrinter() async{
    await setSelectedPrinterFromDB();
    if (kDebugMode) {
      print("PrinterSettings - loadPrinter called is Printer loaded: ${selectedPrinter?.deviceName ?? ''}");
    }
  }
  ///start: custom methods
  Future<Generator> getTicket() async{
    final profile = await CapabilityProfile.load(name: 'XP-N160I');
    return  Generator(PaperSize.mm80, profile);
  }

  ///1. read db and check if device is present
  ///2. if device is not present then insert new
  ///3. else update the current id 1 with new device
  ///4. retrieve device from db
  ///5. assign updated device to selected printer

  Future<void> saveSelectedPrinterToDB() async {
    if (kDebugMode) {
      ///Printer Settings saveSelectedPrinter: printer-80, 22339, 1155, PrinterType.usb
      print(">>>>> PrinterSettings before saveSelectedPrinterToDB: ${selectedPrinter?.deviceName}, ${selectedPrinter?.productId}, ${selectedPrinter?.vendorId}, ${selectedPrinter?.typePrinter}");
    }
    int printerId = await _printerDBHelper.addPrinterToDB(selectedPrinter!);

    if (kDebugMode) {
      ///Printer Settings saveSelectedPrinter: printer-80, 22339, 1155, PrinterType.usb
      print(">>>>> PrinterSettings after saveSelectedPrinterToDB: at row $printerId, ${selectedPrinter?.deviceName}, ${selectedPrinter?.productId}, ${selectedPrinter?.vendorId}, ${selectedPrinter?.typePrinter}");
    }
  }

  Future<void> setSelectedPrinterFromDB() async {
    if (kDebugMode) {
      print(">>>>> PrinterSettings before setSelectedPrinterFromDB: ${selectedPrinter?.deviceName}, ${selectedPrinter?.productId}, ${selectedPrinter?.vendorId}, ${selectedPrinter?.typePrinter}");
    }
    var printerDB = await _printerDBHelper.getPrinterFromDB();

    BluetoothPrinter printer = BluetoothPrinter();

    printer.deviceName = printerDB.first[AppDBConst.printerDeviceName];
    printer.productId = printerDB.first[AppDBConst.printerProductId];
    printer.vendorId = printerDB.first[AppDBConst.printerVendorId];
    printer.typePrinter = EnumToString.fromString(PrinterType.values, printerDB.first[AppDBConst.printerType]) ?? PrinterType.usb;

    selectedPrinter = printer;

    if (kDebugMode) {
      print("printer from db is ${printerDB.length}");
      if(printerDB.isNotEmpty){

          print("#### Retrieved printerDevice '${printerDB.first[AppDBConst.printerDeviceName]}' from DB");
      }
      print(">>>>> PrinterSettings after setSelectedPrinterFromDB: ${selectedPrinter?.deviceName}, ${selectedPrinter?.productId}, ${selectedPrinter?.vendorId}, ${selectedPrinter?.typePrinter}");
    }
    await Future.delayed(Duration(milliseconds: 2000));
  }

  void saveSelectedPrinter(){
    if (kDebugMode) {
      ///Printer Settings saveSelectedPrinter: printer-80, 22339, 1155, PrinterType.usb
      print(">>>>> PrinterSettings saveSelectedPrinter: ${selectedPrinter?.deviceName}, ${selectedPrinter?.productId}, ${selectedPrinter?.vendorId}, ${selectedPrinter?.typePrinter}");
    }
    var pref = PinakaPreferences();
    pref.saveSelectedPrinter(selectedPrinter!);
  }

  Future<void> setSelectedPrinter() async {

    /// some how below code is not loading pref when restarted the app, so comment and implement db saving
    var pref = PinakaPreferences();
    selectedPrinter = await pref.getSavedSelectedPrinter();
    if (kDebugMode) {
      print(">>>>> PrinterSettings setSelectedPrinter: ${selectedPrinter?.deviceName}, ${selectedPrinter?.productId}, ${selectedPrinter?.vendorId}, ${selectedPrinter?.typePrinter}");
    }
  }
///end: custom methods

  Future<void> selectDevice(BluetoothPrinter device) async {
    if (selectedPrinter != null) {
      if ((device.address != selectedPrinter!.address) || (device.typePrinter == PrinterType.usb && selectedPrinter!.vendorId != device.vendorId)) {
        await PrinterManager.instance.disconnect(type: selectedPrinter!.typePrinter);
      }
    }

    selectedPrinter = device;
  }

  Future<bool> connectDevice() async {
    bool isConnected = false;
    if (selectedPrinter == null) return isConnected;
    switch (selectedPrinter!.typePrinter) {
      case PrinterType.usb:
        await printerManager.connect(
            type: selectedPrinter!.typePrinter,
            model: UsbPrinterInput(name: selectedPrinter!.deviceName, productId: selectedPrinter!.productId, vendorId: selectedPrinter!.vendorId));
        isConnected = true;
        break;
      case PrinterType.bluetooth:
        await printerManager.connect(
            type: selectedPrinter!.typePrinter,
            model: BluetoothPrinterInput(
                name: selectedPrinter!.deviceName,
                address: selectedPrinter!.address!,
                isBle: selectedPrinter!.isBle ?? false,
                autoConnect: _reconnect));
        break;
      case PrinterType.network:
        await printerManager.connect(type: selectedPrinter!.typePrinter, model: TcpPrinterInput(ipAddress: selectedPrinter!.address!));
        isConnected = true;
        break;
      }
    await saveSelectedPrinterToDB();
    return isConnected;
  }

  /// print ticket
  Future<Result<BluetoothPrinter>> printTicket(List<int> bytes, Generator generator) async {
    var connectedTCP = false;
    if (kDebugMode) {
      print(">>>>> PrinterSettings printTicket selected printer is '${selectedPrinter?.deviceName}'");
    }
    if (selectedPrinter == null) return Result.error(Exception(TextConstants.noPrinter));
    if (selectedPrinter?.deviceName == null) return Result.error(Exception(TextConstants.noPrinter));
    var bluetoothPrinter = selectedPrinter!;

    switch (bluetoothPrinter.typePrinter) {
      case PrinterType.usb:
        bytes += generator.feed(2);
        bytes += generator.cut();
        await printerManager.connect(
            type: bluetoothPrinter.typePrinter,
            model: UsbPrinterInput(name: bluetoothPrinter.deviceName, productId: bluetoothPrinter.productId, vendorId: bluetoothPrinter.vendorId));
        pendingTask = null;
        break;
      case PrinterType.bluetooth:
        bytes += generator.cut();
        await printerManager.connect(
            type: bluetoothPrinter.typePrinter,
            model: BluetoothPrinterInput(
                name: bluetoothPrinter.deviceName,
                address: bluetoothPrinter.address!,
                isBle: bluetoothPrinter.isBle ?? false,
                autoConnect: _reconnect));
        pendingTask = null;
        if (Platform.isAndroid) pendingTask = bytes;
        break;
      case PrinterType.network:
        bytes += generator.feed(2);
        bytes += generator.cut();
        connectedTCP = await printerManager.connect(type: bluetoothPrinter.typePrinter, model: TcpPrinterInput(ipAddress: bluetoothPrinter.address!));
        if (!connectedTCP) print(' --- please review your connection ---');
        break;
      default:
    }
    if (bluetoothPrinter.typePrinter == PrinterType.bluetooth && Platform.isAndroid) {
      if (_currentStatus == BTStatus.connected) {
        printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
        pendingTask = null;
      }
    } else {
      printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
    }
    return Result.ok(bluetoothPrinter);
  }
}


class BluetoothPrinter {
  int? id;
  String? deviceName;
  String? address;
  String? port;
  String? vendorId;
  String? productId;
  bool? isBle;

  PrinterType typePrinter;
  bool? state;

  BluetoothPrinter(
      {this.deviceName,
        this.address,
        this.port,
        this.state,
        this.vendorId,
        this.productId,
        this.typePrinter = PrinterType.usb,
        this.isBle = false});
}

