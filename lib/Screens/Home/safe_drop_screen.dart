import 'dart:async';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Constants/misc_features.dart';
import 'package:pinaka_pos/Helper/Extentions/extensions.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import '../../Blocs/Auth/safe_drop_bloc.dart';
import '../../Constants/text.dart';
import '../../Database/assets_db_helper.dart';
import '../../Database/db_helper.dart';
import '../../Database/printer_db_helper.dart';
import '../../Database/store_db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Helper/Extentions/nav_layout_manager.dart';
import '../../Helper/Extentions/theme_notifier.dart';
import '../../Helper/api_response.dart';
import '../../Models/Assets/asset_model.dart';
import '../../Models/Auth/safe_drop_model.dart';
import '../../Preferences/pinaka_preferences.dart';
import '../../Repositories/Auth/safe_drop_repository.dart';
import '../../Utilities/global_utility.dart';
import '../../Utilities/printer_settings.dart';
import '../../Utilities/result_utility.dart';
import '../../Widgets/widget_alert_popup_dialogs.dart';
import '../../Widgets/widget_custom_num_pad.dart';
import '../../Widgets/widget_topbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;
import '../Auth/login_screen.dart';
import 'Settings/image_utils.dart';
import 'Settings/printer_setup_screen.dart';
import 'apps_dashboard_screen.dart';

class SafeDropScreen extends StatefulWidget {
  final int? lastSelectedIndex;
  const SafeDropScreen(
      {super.key, this.lastSelectedIndex});

  @override
  State<SafeDropScreen> createState() => _SafeDropScreenState();
}

class _SafeDropScreenState extends State<SafeDropScreen> with LayoutSelectionMixin {
  bool isLoading = true;
  int _selectedSidebarIndex = 4;

  // Added: For API loading state
  bool _isApiLoading = false;

  // Modified: Map to store dynamic controllers for denominations
  final Map<String, TextEditingController> _denomControllers = {};
  final TextEditingController _totalNotesController = TextEditingController();
  final TextEditingController _totalCashController = TextEditingController();

  // Track the currently selected text field
  TextEditingController? _activeController;

  // To track totals
  late int totalNotes;
  late double totalCash;

  //Build #1.0.74: Added: List to store denominations from database
  List<Denom> _safeDenominations = [];
  // Added: SafeDropBloc instance
  late SafeDropBloc _safeDropBloc;
  final PinakaPreferences _preferences = PinakaPreferences(); // Add this
  ///printer
  var _printerSettings =  PrinterSettings();
  List<int> bytes = [];
  StreamSubscription? _safeDropSubscription; // Build #1.0.240
  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 4; // Build #1.0.7: Restore previous selection

    // Initialize SafeDropBloc
    _safeDropBloc = SafeDropBloc(SafeDropRepository());
    // Added: Listen to safe drop stream for API responses
    // Build #1.0.240 Store the subscription and manage it properly
    _safeDropSubscription = _safeDropBloc.safeDropStream.listen((response) {  //Build #1.0.74
      if (response.status == Status.COMPLETED) {
        setState(() {
          _isApiLoading = false;
        });
        if (kDebugMode) print("#### SafeDropScreen: Safe drop created successfully: ${response.data!.message}");
        if (Misc.showDebugSnackBar) { // Build #1.0.254
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data!.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        }
        // Clear all fields after successful save
        _denomControllers.forEach((key, controller) {
          controller.text = "0";
        });
        _calculateTotals();
        /// 1. print receipt
        if(!Misc.disablePrinter) {
          _printTicket();
        }

        // Build #1.0.240
        /// 2. Navigate back to Apps screen after successful upload
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      AppsDashboardScreen(lastSelectedIndex: 4)),
            );
            if (kDebugMode) print("Navigate back to Apps screen");
          }
        });
        _safeDropSubscription?.cancel();
      }
      else if (response.status == Status.ERROR) {
        setState(() {
          _isApiLoading = false; // Build #1.0.240 : dismiss loader on add button
        });
        if (kDebugMode) {
          print("safe drop screen --- Unauthorised : ${response.message ?? " "}");
        }
        if (response.message!.contains('Unauthorised')) {
          if (kDebugMode) {
            print("Unauthorised : ${response.message}");
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (context) => LoginScreen()));

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Unauthorised. Session is expired on this device."),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        } else {
          if (kDebugMode) print("#### SafeDropScreen: Error creating safe drop: ${response.message}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                response.message ?? 'Failed to create safe drop')),
          );

          // Build #1.0.240
          /// 3. Show failure popup with dismiss button
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
                CustomDialog.showCustomItemAlert(
                  context,
                  title: TextConstants.tranFailed,
                  description: TextConstants.wantRetry,
                  buttonText: TextConstants.dismiss,
                  showCloseIcon: false
                );
            }
          });
        }
        _safeDropSubscription?.cancel(); // Build #1.0.238: cancel subscription
      }
    });

    // Initialize totals
    totalNotes = 0;
    totalCash = 0.0;
    _totalNotesController.text = "0";
    _totalCashController.text = "${TextConstants.currencySymbol}0.00";

    // Fetch denominations from database
    _fetchSafeDenominations();

    // Simulate a loading delay
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isLoading = false; // Set loading to false after 3 seconds
      });
    });
  }

  //Build #1.0.74, Added: Fetch safe denominations from AssetDBHelper
  Future<void> _fetchSafeDenominations() async {
    if (kDebugMode) print("#### SafeDropScreen: Fetching safe denominations");
    try {
      final denoms = await AssetDBHelper.instance.getSafeDenomList();
      setState(() {
        _safeDenominations = denoms;
        // Initialize controllers for each denomination
        for (var denom in _safeDenominations) {
          _denomControllers[denom.denom.toString()] = TextEditingController(text: "0");
        }
      });
      if (kDebugMode) print("#### SafeDropScreen: Loaded ${_safeDenominations.length} denominations");
    } catch (e) {
      if (kDebugMode) print("#### SafeDropScreen: Error fetching denominations: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load denominations')),
      );
    }
  }

  @override
  void dispose() {
    // Build #1.0.240 : Cancel the subscription to prevent memory leaks
    _safeDropSubscription?.cancel();
    // Dispose of controllers to prevent memory leaks
    _denomControllers.forEach((key, controller) => controller.dispose());
    _totalNotesController.dispose();
    _totalCashController.dispose();
    // Dispose SafeDropBloc
    _safeDropBloc.dispose();
    super.dispose();
  }

  // Modified: Calculate totals based on dynamic denominations
  void _calculateTotals() {
    int notes = 0;
    double cash = 0.0;

    //Build #1.0.74
    _denomControllers.forEach((denom, controller) {
      final count = double.tryParse(controller.text) ?? 0;
      final denomValue = double.parse(denom);
      notes += count.round();
      cash += count * denomValue;
    });

    setState(() {
      totalNotes = notes;
      totalCash = cash;
      _totalNotesController.text = totalNotes.toString();
      _totalCashController.text = "${TextConstants.currencySymbol}${totalCash.toStringAsFixed(2)}";
    });

    if (kDebugMode) print("#### SafeDropScreen: Updated totals - Notes: $totalNotes, Cash: $totalCash");
  }

  // Handle numeric input
  void _handleNumberPress(String value) {
    if (_activeController != null) {
      String currentText = _activeController!.text;
      // Handle special cases for the CustomNumPad
      if (value == "." && currentText.contains(".")) {
        // Don't allow multiple decimal points
        return;
      } else if (value == "00") {
        // Special case for "00"
        if (currentText == "0") {
          _activeController!.text = "0";
        } else {
          _activeController!.text = currentText + "00";
        }
      } else if (currentText == "0" && value != ".") {
        // Replace leading zero, unless adding decimal
        _activeController!.text = value;
      } else {
        // Normal case: append the value
        _activeController!.text = currentText + value;
      }
      _calculateTotals();
    }
  }

  // Clear the active field
  void _handleClear() {
    if (_activeController != null) {
      _activeController!.text = "0";
      _calculateTotals();
    }
  }

  //Build #1.0.74, Modified: Handle add button press with API call
  Future<void> _handleAdd() async {
    if(totalCash == 0 || totalNotes == 0) {  // prevent empty values
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TextConstants.notesError),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    if(_isApiLoading) return; // Prevent multiple clicks

    if (kDebugMode) print("#### SafeDropScreen: Add button pressed");
    setState(() {
      _isApiLoading = true;
    });

    int? shiftId = await UserDbHelper().getUserShiftId(); // Build #1.0.149 : using from db
    if (shiftId == null) {
      if (kDebugMode) print("####### _handleAdd() : shiftId -> $shiftId");
    }
    // Prepare SafeDropRequest
    final denominations = _denomControllers.entries.map((entry) {
      final denom = num.parse(entry.key);
      final count = int.tryParse(entry.value.text) ?? 0;
      return SafeDropDenomination(
        denomination: denom,
        denominationCount: count,
        total: denom * count,
      );
    }).toList();

    final request = SafeDropRequest(
      safeDropDenominations: denominations,
      totalCash: totalCash,
      totalNotes: totalNotes,
      shiftId: shiftId ?? 0,
    );

    if (kDebugMode) print("#### SafeDropScreen: Sending safe drop request: ${request.toJson()}");
    _safeDropBloc.createSafeDrop(request);
    ///1. prepare printer and receipt
    if(!Misc.disablePrinter) {
      _preparePrintTicket();
    }
  }

  Future<Map<String, dynamic>?> loadPrinterData() async {
    var printerDB = await PrinterDBHelper().getPrinterFromDB();
    if(printerDB.isEmpty){
      if (kDebugMode) {
        print(">>>>> OrderSummaryScreen : printerDB is empty");
      }
      return null;
    }
    return printerDB.first;

  }

  Future _preparePrintTicket() async{
    if (kDebugMode) {
      print("OrderSummaryScreen _preparePrintTicket call print receipt");
    }
    ///load header and footer
    var printerData  = await loadPrinterData();
    var header = printerData?[AppDBConst.receiptHeaderText] ?? "";
    var footer = printerData?[AppDBConst.receiptFooterText] ?? "";
    var logo = printerData?[AppDBConst.receiptIconPath] ?? "";

    if (kDebugMode) {
      print("OrderSummaryScreen _preparePrintTicket logo: $logo, iconPath: ${printerData?[AppDBConst.receiptIconPath] ?? ""}");
    }

    bytes = [];
    final ticket =  await _printerSettings.getTicket();

    ///Header
    ///   Pinaka Logo
    ///Tax Summary
    ///   Item
    ///   tax breakdown
    ///   gross total
    ///Footer
    ///   Thank You, Visit Again


    //Pinaka Logo
    final ByteData data;
    if(logo != "") {
      data = await GlobalUtility.fileToByteData(File(logo)) ?? await rootBundle.load('assets/ic_logo.png');
    } else {
      data = await rootBundle.load('assets/ic_logo.png');
    }
    if (kDebugMode) {
      print("OrderSummaryScreen _preparePrintTicket data.lengthInBytes : ${data.lengthInBytes}");
    }
    if (data.lengthInBytes > 0) {
      final Uint8List imageBytes = data.buffer.asUint8List();
      // decode the bytes into an image
      final decodedImage = img.decodeImage(imageBytes)!;
      // Create a black bottom layer
      // Resize the image to a 130x? thumbnail (maintaining the aspect ratio).
      img.Image thumbnail = img.copyResize(decodedImage, height: 130);
      // creates a copy of the original image with set dimensions
      img.Image originalImg = img.copyResize(decodedImage, width: 380, height: 130);
      // fills the original image with a white background
      img.fill(originalImg, color: img.ColorRgb8(255, 255, 255));
      var padding = (originalImg.width - thumbnail.width) / 2;

      //insert the image inside the frame and center it
      drawImage(originalImg, thumbnail, dstX: padding.toInt());

      // convert image to grayscale
      var grayscaleImage = img.grayscale(originalImg);

      bytes += ticket.feed(1);
      // bytes += generator.imageRaster(img.decodeImage(imageBytes)!, align: PosAlign.center);
      bytes += ticket.imageRaster(grayscaleImage, align: PosAlign.center);
      bytes += ticket.feed(1);
    }

    //Header
    ///New changes in Header on 2-Sep-2025
    ///Date and Time
    ///Store Id
    ///Address
    //         "Store name": "Kumar Swa D", => < increase font to 5 and bold >
    //         "address": "Q No: D 1847, Shirkey Colony",=>  first line will be <address>
    //         "city": "Mancherial", => second line will be <city>,<state>-<zip_code>
    //         "state": "Telangana",
    //         "country": "", => no need to show
    //         "zip_code": "504302",
    //         "phone_number": false => third line will be <phone_number>


    final DateTime createdDateTime = DateTime.now();
    var dateToPrint = DateFormat(TextConstants.dateFormat).format(createdDateTime);
    var timeToPrint = DateFormat(TextConstants.timeFormat).format(createdDateTime);

    var merchantDetails = await StoreDbHelper.instance.getStoreValidationData();
    var storeId = "${merchantDetails?[AppDBConst.storeId]}";
    var storePhone = "${merchantDetails?[AppDBConst.storePhone]}";

    var storeDetails = await AssetDBHelper.instance.getStoreDetails();
    var storeName = "${storeDetails?.name}";
    var address = "${storeDetails?.address},";
    var cityStateZip = "${storeDetails?.city},${storeDetails?.state}-${storeDetails?.zipCode}";
    var orderIdToPrint = "";//'${TextConstants.orderID} $orderId';

    final userData = await UserDbHelper().getUserData();
    var cashierName = "${userData?[AppDBConst.userDisplayName] ?? "Unknown Name"}";
    var cashierRole = "${userData?[AppDBConst.userRole] ?? "Unknown Role"}";

    if (kDebugMode) {
      print(" >>>>> PrintOrder  dateToPrint $dateToPrint ");
      print(" >>>>> PrintOrder  timeToPrint $timeToPrint ");
      print(" >>>>> PrintOrder  storeId $storeId ");
      print(" >>>>> PrintOrder  storeName $storeName ");
      print(" >>>>> PrintOrder  address $address ");
      print(" >>>>> PrintOrder  cityStateZip $cityStateZip ");
      print(" >>>>> PrintOrder  storePhone $storePhone ");
      print(" >>>>> PrintOrder  orderIdToPrint $orderIdToPrint ");
      print(" >>>>> PrintOrder  cashierName $cashierName ");
      print(" >>>>> PrintOrder  cashierRole $cashierRole ");
    }

    if(header != "") {
      bytes += ticket.row([
        PosColumn(
            text: "$header",
            width: 12,
            styles: PosStyles(align: PosAlign.center)),
      ]);
      bytes += ticket.feed(1);
    }

    //Store Name
    bytes += ticket.row([
      PosColumn(text: "$storeName", width: 12, styles: PosStyles(align: PosAlign.center,bold: true, height: PosTextSize.size2, width: PosTextSize.size2)), //Build #1.0.257: increase font to 5 and bold
    ]);
    bytes += ticket.feed(1); /// Add space between store name and address
    //Address
    bytes += ticket.row([
      PosColumn(text: "$address", width: 12, styles: PosStyles(align: PosAlign.center)),
    ]);
    //cityStateZip
    bytes += ticket.row([
      PosColumn(text: "$cityStateZip", width: 12, styles: PosStyles(align: PosAlign.center)),
    ]);
    //Store Phone
    bytes += ticket.row([
      PosColumn(text: "Phone: $storePhone", width: 12, styles: PosStyles(align: PosAlign.center)),
    ]);

    bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: "-----------------------------------------------", width: 12),
    ]);
    bytes += ticket.feed(1);

    //Date and Time
    bytes += ticket.row([
      PosColumn(text: "Date: $dateToPrint", width: 7, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "Time: $timeToPrint", width: 5, styles: PosStyles(align: PosAlign.left)),
    ]);

    //cashier and  store id
    bytes += ticket.row([
      PosColumn(text: "Cashier: $cashierName", width: 7, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "StoreID: $storeId", width: 5, styles: PosStyles(align: PosAlign.left)),
    ]);

    //role and order Id
    bytes += ticket.row([
      PosColumn(text: "Role: $cashierRole", width: 7, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "", width: 5, styles: PosStyles(align: PosAlign.left)),
    ]);

    bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: "-----------------------------------------------", width: 12),
    ]);
    bytes += ticket.feed(1);

    //Item header
    bytes += ticket.row([
      PosColumn(text: "#", width: 2),
      PosColumn(text: "Denomination", width:5, styles: PosStyles(align: PosAlign.right)),
      PosColumn(text: "Qty", width: 2,styles: PosStyles(align: PosAlign.center)),
      PosColumn(text: "Amt", width: 3, styles: PosStyles(align: PosAlign.right)),
    ]);
    bytes += ticket.feed(1);

    //Denominations
    int denomIndex = 0;
    _denomControllers.forEach((denom, controller) {
      denomIndex++;
      final count = double.tryParse(controller.text) ?? 0;
      final denomValue = double.parse(denom);
      var notes = count.round();
      var cash = count * denomValue;

      bytes += ticket.row([
        PosColumn(text: "$denomIndex", width: 2),
        PosColumn(text: "${TextConstants.currencySymbol}${denomValue.toStringAsFixed(2)}", width:5, styles: PosStyles(align: PosAlign.right)),
        PosColumn(text: "$notes", width:2, styles: PosStyles(align: PosAlign.center)),
        PosColumn(text: "${TextConstants.currencySymbol}${cash.toStringAsFixed(2)}", width: 3, styles: PosStyles(align: PosAlign.right)),
      ]);
    });

    bytes += ticket.feed(1);

    if (kDebugMode) {
      print(" >>>>> SafeDrop Denoms count ${_denomControllers.length} ");
      print(" SafeDrop totalNotes ${totalNotes.toString()}");
      print(" SafeDrop totalCash ${totalCash.toStringAsFixed(2)}");
    }

    //line
    bytes += ticket.row([
      PosColumn(text: "-----------------------------------------------", width: 12),
    ]);

    // bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: TextConstants.total, width: 7),
      PosColumn(text: totalNotes.toString(), width:2, styles: PosStyles(align: PosAlign.center)),
      PosColumn(text: "${TextConstants.currencySymbol}${totalCash.toStringAsFixed(2)}", width:3, styles: PosStyles(align: PosAlign.right)),
    ]);

    // bytes += ticket.row([
    //   PosColumn(text: TextConstants.cash, width: 10),
    //   PosColumn(text: totalCash.toStringAsFixed(2), width:2),
    // ]);

    bytes += ticket.feed(1);
    //Footer
    // bytes += ticket.row([
    //   PosColumn(text: "----------------------End----------------------", width: 12),
    // ]);
    // bytes += ticket.feed(1);
  }

  Future _printTicket() async{
    final ticket =  await _printerSettings.getTicket();
    final result = await _printerSettings.printTicket(bytes, ticket);

    if (kDebugMode) {
      print(">>>> PrintTicket result $result");
    }
    switch (result) {
      case Ok<BluetoothPrinter>():
      // BluetoothPrinter printer = result.value;
        break;
      case Error<BluetoothPrinter>():
        WidgetsBinding.instance.addPostFrameCallback((_) { // Build #1.0.16
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.error.getMessage,
                style: const TextStyle(color: Colors.red),
              ),
              backgroundColor: Colors.black, // ✅ Black background
              duration: const Duration(seconds: 3),
            ),
          );
          /// call printer setup screen
          if (kDebugMode) {
            print("call printer setup screen");
          }
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => PrinterSetup(),
          )).then((result) {
            if (result == TextConstants.refresh) { // Build #1.0.175: Added refresh constant string into TextConstants
              _printerSettings.loadPrinter();
              setState(() {
                // Update state to refresh the UI
                if (kDebugMode) {
                  print("SettingScreen - printer setup is done, connected printer is ${_printerSettings.selectedPrinter?.deviceName}");
                }
                if(!Misc.disablePrinter) {
                  _printTicket();
                }
              });
            }
          });
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      body: Stack( //Build #1.0.74
        children: [
          Column(
            children: [
              TopBar(
                screen: Screen.SAFE,
                onModeChanged: () async{ /// Build #1.0.192: Fixed -> Exception -> setState() callback argument returned a Future. (onModeChanged in all screens)
                  String newLayout;
                    if (sidebarPosition == SidebarPosition.left) {
                      newLayout = SharedPreferenceTextConstants.navRightOrderLeft;
                    } else if (sidebarPosition == SidebarPosition.right) {
                      newLayout = SharedPreferenceTextConstants.navBottomOrderLeft;
                    } else {
                      newLayout = SharedPreferenceTextConstants.navLeftOrderRight;
                    }

                    // Update the notifier which will trigger _onLayoutChanged
                    PinakaPreferences.layoutSelectionNotifier.value = newLayout;
                    // No need to call saveLayoutSelection here as it's handled in the notifier
                   // _preferences.saveLayoutSelection(newLayout);
                    //Build #1.0.122: update layout mode change selection to DB
                    await UserDbHelper().saveUserSettings({AppDBConst.layoutSelection: newLayout}, modeChange: true);
                  // update UI
                  setState(() {});
                },
              ),
              Divider(
                color: Colors.grey, // Light grey color
                thickness: 0.4, // Very thin line
                height: 1, // Minimal height
              ),
              Expanded(
                child: Row(
                  children: [
                    if (sidebarPosition == SidebarPosition.left)
                      custom_widgets.NavigationBar(
                        selectedSidebarIndex: _selectedSidebarIndex,
                        onSidebarItemSelected: (index) {
                          setState(() {
                            _selectedSidebarIndex = index;
                          });
                        },
                        isVertical: true, // Vertical layout for left sidebar
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 0.0, top: 15.0, right: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_back, size: 20,),
                                  SizedBox(width: 10,),
                                  Text("back", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 30,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      // Modified: Replaced static rows with GridView
                                      _safeDenominations.isEmpty
                                          ? const Center(child: CircularProgressIndicator())
                                          : GridView.builder(
                                        shrinkWrap: true,
                                       // physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 9,
                                          crossAxisSpacing: 4,
                                          mainAxisSpacing: 4,
                                        ),
                                        itemCount: 6, //_safeDenominations.length, //NOTE: Ranjeet: for now we have add only 6
                                        itemBuilder: (context, index) {
                                          final denom = _safeDenominations[index];
                                          final controller = _denomControllers[denom.denom.toString()]!;
                                          return _buildDenominationField(
                                            denom.image ?? 'assets/svg/1.svg',
                                            denom.denom.toString(),
                                            controller,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Divider(
                                    color: Colors.grey, // Light grey color
                                    thickness: 0.4, // Very thin line
                                    height: 1, // Minimal height
                                    endIndent: 70,
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    // mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.308,
                                        height: MediaQuery.of(context).size.height * 0.39,
                                        margin: EdgeInsets.only(left: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5ED),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text("Total Notes",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: ThemeNotifier.textLight
                                                    )),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.25,
                                              child: TextField(
                                                controller: _totalNotesController,
                                                readOnly: true,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.circularNavBackground : Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor : Colors.grey.shade300),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text("Total Cash",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: ThemeNotifier.textLight
                                                )),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.25,
                                              child: TextField(
                                                controller: _totalCashController,
                                                readOnly: true,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.circularNavBackground : Colors.white,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor : Colors.grey.shade300),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 150),
                                      Container(
                                        margin: EdgeInsets.only(left: 5),
                                        decoration: BoxDecoration(
                                          // color: Colors.red,//const Color(0xFFE8F5ED),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        width: MediaQuery.of(context).size.width * 0.326,
                                        height: MediaQuery.of(context).size.height * 0.391,
                                        child: CustomNumPad(
                                          onDigitPressed: _handleNumberPress,
                                          onClearPressed: _handleClear,
                                          onAddPressed: _handleAdd,
                                          actionButtonType: ActionButtonType.add,
                                          isDarkTheme: true,
                                          isLoading: _isApiLoading, // Pass the loading state here
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right Sidebar (Conditional)
                    if (sidebarPosition == SidebarPosition.right)
                      custom_widgets.NavigationBar(
                        selectedSidebarIndex: _selectedSidebarIndex,
                        onSidebarItemSelected: (index) {
                          setState(() {
                            _selectedSidebarIndex = index;
                          });
                        },
                        isVertical: true, // Vertical layout for right sidebar
                      ),
                  ],
                ),
              ),
              // Bottom Sidebar (Conditional)
              if (sidebarPosition == SidebarPosition.bottom)
                custom_widgets.NavigationBar(
                  selectedSidebarIndex: _selectedSidebarIndex,
                  onSidebarItemSelected: (index) {
                    setState(() {
                      _selectedSidebarIndex = index;
                    });
                  },
                  isVertical: false, // Horizontal layout for bottom sidebar
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateTotalForNote(String denomination, TextEditingController controller) {
    final count = int.tryParse(controller.text) ?? 0;
    final total = count * int.parse(denomination);
    return '${TextConstants.currencySymbol}${total.toStringAsFixed(2)}';
  }

  //Build #1.0.74: Added Naveen
  Future<Widget> _loadSvg(String assetPath) async {
    try {
      if (assetPath.startsWith('http')) {
        return SvgPicture.network(
          assetPath,
          height: 40,
          width: 32,
          placeholderBuilder: (context) => SvgPicture.asset(
            'assets/svg/1.svg', // Your fallback asset
            height: 40,
            width: 32,
          ),
        );
      } else {
        return SvgPicture.asset(
          assetPath,
          height: 40,
          width: 32,
        );
      }
    } catch (e) {
      if (kDebugMode) print("#### SafeDropScreen: Error loading SVG $assetPath: $e");
      return SvgPicture.asset(
        'assets/svg/1.svg', // Fallback SVG
        width: 40,
        height: 32,
      );
    }
  }

  Widget _buildDenominationField(String assetPath, String denomination, TextEditingController controller, {bool isResult = false}) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground :Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          FutureBuilder<Widget>(
            future: _loadSvg(assetPath),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              } else if (snapshot.hasError) {
                if (kDebugMode) print("#### SafeDropScreen: Error in FutureBuilder for SVG: ${snapshot.error}");
                return SvgPicture.asset(
                  'assets/svg/1.svg',
                  width: 40,
                  height: 30,
                );
              }
              return const SizedBox(width: 40, height: 32); // Placeholder while loading
            },
          ),
          const SizedBox(width: 20),
          const Text('×', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 20),
          Container(
            width: MediaQuery.of(context).size.width * 0.1,
            height: MediaQuery.of(context).size.height * 0.075,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              border: Border.all(color:themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(5),
              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.circularNavBackground : Colors.white,
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.none,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              readOnly: isResult,
              onTap: isResult
                  ? null
                  : () {
                setState(() {
                  _activeController = controller;
                });
              },
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,

              ),
            ),
          ),
          const SizedBox(width: 20),
          const Text('=', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 20),
          Container(
            width: MediaQuery.of(context).size.width * 0.1,
            height: MediaQuery.of(context).size.height * 0.075,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(5),
              color: Colors.grey.shade400,
            ),
            child: Text(
              _calculateTotalForNote(denomination, controller),
              textAlign: TextAlign.center,
              // isResult
              //     ? controller.text
              //     : '${TextConstants.currencySymbol}${((double.tryParse(controller.text) ?? 0) * denominationValue).toStringAsFixed(2)}',
              // style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}