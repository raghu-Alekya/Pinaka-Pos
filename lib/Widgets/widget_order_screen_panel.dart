import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pinaka_pos/Helper/Extentions/extensions.dart';
import 'package:shimmer/shimmer.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_pos/Screens/Home/order_summary_screen.dart';
import 'package:pinaka_pos/Widgets/widget_order_panel.dart';
import 'package:pinaka_pos/Widgets/widget_order_status.dart';
import 'package:pinaka_pos/Widgets/widget_alert_popup_dialogs.dart';
import 'package:provider/provider.dart';
import '../Blocs/Orders/order_bloc.dart';
import '../Blocs/Search/product_search_bloc.dart';
import '../Constants/misc_features.dart';
import '../Constants/text.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
import '../Database/printer_db_helper.dart';
import '../Database/user_db_helper.dart';
import '../Helper/Extentions/theme_notifier.dart';
import '../Helper/api_response.dart';
import '../Utilities/global_utility.dart';
import '../Models/Orders/orders_model.dart';
import '../Repositories/Auth/store_validation_repository.dart';
import '../Repositories/Orders/order_repository.dart';
import '../Repositories/Search/product_search_repository.dart';
import '../Screens/Home/Settings/image_utils.dart';
import '../Screens/Home/Settings/printer_setup_screen.dart';
import '../Screens/Home/edit_product_screen.dart';
import '../Utilities/printer_settings.dart';
import '../Utilities/result_utility.dart';

class OrderScreenPanel extends StatefulWidget {
  final String formattedDate;
  final String formattedTime;
  final List<int> quantities;
  final VoidCallback? refreshOrderList;
  final int? activeOrderId; // Build #1.0.118: Added activeOrderId
  bool fetchOrders;

  OrderScreenPanel({
    required this.formattedDate,
    required this.formattedTime,
    required this.quantities,
    this.refreshOrderList,
    this.activeOrderId,
    this.fetchOrders = false,
    Key? key,
  }) : super(key: key);

  @override
  _OrderScreenPanelState createState() => _OrderScreenPanelState();
}

class _OrderScreenPanelState extends State<OrderScreenPanel> with TickerProviderStateMixin {
  List<Map<String, Object>> tabs = []; // List of order tabs
  TabController? _tabController; // Controller for tab switching
  List<Map<String, dynamic>> orderItems = []; // List of items in the selected order
  final OrderHelper orderHelper = OrderHelper(); // Helper instance to manage orders

  bool _isLoading = false;
  bool _isPayBtnLoading = false;
  bool _initialFetchDone = false; // Build #1.0.143: Track initial fetch of fetchOrdersData
 // late OrderBloc orderBloc;
  StreamSubscription? _updateOrderSubscription;
  StreamSubscription? _fetchOrdersSubscription;
  final ProductBloc productBloc = ProductBloc(ProductRepository()); // Build #1.0.44 : Added for barcode scanning
  StreamSubscription? _productBySkuSubscription; // Build #1.0.44 : Added for product stream

  bool _showFullSummary = false;
  late ScaffoldMessengerState _scaffoldMessenger;
  var _printerReceipt;

  void _toggleSummary() {
    setState(() {
      _showFullSummary = !_showFullSummary;
    });
  }

  @override
  void initState() {
    if (kDebugMode) {
      print("##### OrderPanel initState");
    }
  //  orderBloc = OrderBloc(OrderRepository()); // Build #1.0.143: no need
    fetchOrdersData(); // Build #1.0.104
    _initialFetchDone = true; // Build #1.0.143: Track initial fetch of fetchOrdersData, after return from order summary screen we are updating order screen panel in didUpdateWidget, added this flag for multiple re-calls of fetchOrdersData()
    super.initState();
   // _getOrderTabs(); //Build #1.0.40: Load existing orders into tabs
    //_fetchOrders(); //Build #1.0.40: Fetch orders on initialization
    loadPrinterData();

  }

  Future<void> loadPrinterData() async {
    var printerDB = await PrinterDBHelper().getPrinterFromDB();
    if(printerDB.isEmpty){
      if (kDebugMode) {
        print(">>>>> OrderScreenPanel : printerDB is empty");
      }
      return;
    }
    _printerReceipt = printerDB.first;

  }

  // Build #1.0.118: Updated fetchOrdersData to use widget.activeOrderId
  Future<void> fetchOrdersData() async { // Build #1.0.104: created this function for initial load and back button refresh
    setState(() => _isLoading = true); // show loader
    if (kDebugMode) {
      print("##### fetchOrdersData called for activeOrderId: ${widget.activeOrderId}");
    }
    await fetchOrder();
    await fetchOrderItems();

    setState(() => _isLoading = false); // Hide loader
  }

 // Updated didUpdateWidget to check activeOrderId
  @override
  void didUpdateWidget(OrderScreenPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
   // Build #1.0.143: Fixed Issue : After return from order summary screen , order screen panel not refreshing with updated response
    if (!_initialFetchDone && widget.fetchOrders) {
      if (kDebugMode) {
        print("##### widget.fetchOrders : ${widget.fetchOrders}");
      }
      fetchOrdersData();
    }
    if (mounted && widget.activeOrderId != oldWidget.activeOrderId) {  // Build #1.0.118
      if (kDebugMode) {
        print("##### OrderPanel didUpdateWidget: activeOrderId changed from ${oldWidget.activeOrderId} to ${widget.activeOrderId}");
      }
      fetchOrdersData();
    }
  }
  var _order;
  // Build #1.0.118: Update fetchOrder to use widget.activeOrderId
  Future<void> fetchOrder() async {
    if (widget.activeOrderId != null) {
      List<Map<String, dynamic>> ordersData = await orderHelper.getOrderById(widget.activeOrderId!);
      _order = ordersData.firstWhere(
            (o) => o[AppDBConst.orderServerId] == widget.activeOrderId,
        orElse: () => {AppDBConst.orderStatus: ''},
      );
    } else {
      _order = {AppDBConst.orderStatus: ''};
    }
  }

  // // Build #1.0.10: Fetches the list of order tabs from OrderHelper
  // void _getOrderTabs() async {
  //   if (kDebugMode) {
  //     print("##### DEBUG: _getOrderTabs - Loading order tabs");
  //   }
  //   await orderHelper.loadData(); // Load order data from DB
  //
  //   if (mounted) {
  //     setState(() {
  //       // Convert order IDs into tab format
  //       tabs = orderHelper.orders
  //           .asMap()
  //           .entries
  //           .map((entry) => {
  //         "title": "#${entry.value[AppDBConst.orderServerId] ?? entry.value[AppDBConst.orderId]}",
  //         "subtitle": "Tab ${entry.key + 1}",
  //         "orderId": entry.value[AppDBConst.orderId] as Object, // Use db orderId, not serverId
  //       }).toList();
  //       if (kDebugMode) {
  //         print("##### DEBUG: _getOrderTabs - Loaded ${tabs.length} tabs: $tabs");
  //       }
  //     });
  //   }
  //
  //   if (!mounted) return; // Prevent controller initialization if unmounted
  //   _initializeTabController(); // Initialize tab controller
  //
  //   if (tabs.isNotEmpty) {
  //     int index = 0;
  //     if (orderHelper.activeOrderId != null) {
  //       index = orderHelper.orderIds.indexOf(orderHelper.activeOrderId!);
  //       if (index == -1) {
  //         if (kDebugMode) {
  //           print("##### DEBUG: _getOrderTabs - Active order ID ${orderHelper.activeOrderId} not found, defaulting to last tab");
  //         }
  //         index = tabs.length - 1;
  //         await orderHelper.setActiveOrder(tabs[index]["orderId"] as int);
  //       }
  //     } else {
  //       if (kDebugMode) {
  //         print("##### DEBUG: _getOrderTabs - No active order, setting to last tab");
  //       }
  //       index = tabs.length - 1;
  //       await orderHelper.setActiveOrder(tabs[index]["orderId"] as int);
  //     }
  //     if (mounted && _tabController != null) {
  //       _tabController?.index = index;
  //       if (kDebugMode) {
  //         print("##### DEBUG: _getOrderTabs - Set tab index to $index, activeOrderId: ${orderHelper.activeOrderId}");
  //       }
  //     }
  //     await fetchOrderItems(); // Load items for active order
  //   } else {
  //     if (kDebugMode) {
  //       print("##### DEBUG: _getOrderTabs - No tabs available");
  //     }
  //     if (mounted) {
  //       setState(() {
  //         orderItems.clear(); // Clear items if no tabs
  //       });
  //     }
  //   }
  // }

  // void _fetchOrders() { //Build #1.0.40: fetch orders items from API sync & updating to UI
  //   _fetchOrdersSubscription = orderBloc.fetchOrdersStream.listen((response) async {
  //     if (!mounted) return;
  //
  //     if (response.status == Status.COMPLETED) {
  //       if (kDebugMode) {
  //         print("##### DEBUG: Fetched orders successfully");
  //       }
  //
  //       await orderHelper.syncOrdersFromApi(response.data!.orders);
  //       _getOrderTabs();
  //     } else if (response.status == Status.ERROR) {
  //       if (kDebugMode) {
  //         print("##### ERROR: Fetch orders failed - ${response.message}");
  //       }
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(response.message ?? "Failed to fetch orders")),
  //       );
  //     }
  //   });
  //
  //   orderBloc.fetchOrders();
  // }

  // Build #1.0.10: Fetches order items for the active order
  Future<void> fetchOrderItems() async {
    if (orderHelper.activeOrderId != null) {
      if (kDebugMode) {
        print("##### DEBUG: Order screen panel  fetchOrderItems - Fetching items for activeOrderId: ${orderHelper.activeOrderId}");
      }
      try {
        List<Map<String, dynamic>> items = await orderHelper.getOrderItems(orderHelper.activeOrderId!);

        if (kDebugMode) {
          print("##### DEBUG: fetchOrderItems - Retrieved ${items.length} items: $items");
        }

        // total = 0.0;
        // for (var item in items) {
        //   double price = (item[AppDBConst.itemPrice] as num).toDouble();
        //   int count = item[AppDBConst.itemCount] as int;
        //   total += price * count;
        // }

        if (mounted) {
          setState(() {
            orderItems = items; // Update the order items list
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print("##### ERROR: fetchOrderItems failed - $e");
        }
        if (mounted) {
          setState(() {
            orderItems.clear(); // Clear items on error
          });
        }
      }
    } else {
      if (kDebugMode) {
        print("##### DEBUG: fetchOrderItems - No active order, clearing items");
      }
      if (mounted) {
        setState(() {
          orderItems.clear(); // Clear items if no active order
        });
      }
    }
    if (mounted) {
      setState(() => _isLoading = false); // Build #1.0.104: hide loader
    }
  }

  // // Build #1.0.10: Initializes the tab controller and handles tab switching
  // void _initializeTabController() {
  //   if (!mounted) return; // Prevent initialization if unmounted
  //   _tabController?.dispose(); // Dispose existing controller
  //   _tabController = TabController(length: tabs.length, vsync: this);
  //
  //   _tabController!.addListener(() async {
  //     if (!_tabController!.indexIsChanging && mounted) {
  //       int selectedIndex = _tabController!.index; // Get selected tab index
  //       int selectedOrderId = tabs[selectedIndex]["orderId"] as int;
  //
  //       if (kDebugMode) {
  //         print("##### DEBUG: Tab changed to index: $selectedIndex, orderId: $selectedOrderId");
  //       }
  //
  //       await orderHelper.setActiveOrder(selectedOrderId); // Set new active order
  //       await fetchOrderItems(); // Load items for the selected order
  //       if (mounted) {
  //         setState(() {}); // Refresh UI
  //       }
  //     }
  //   });
  // }

  // // Build #1.0.10: Creates a new order and adds it as a new tab
  // void addNewTab() async {
  //   int orderId = await orderHelper.createOrder(); // Create a new order
  //   await orderHelper.setActiveOrder(orderId); // Set the new order as active
  //
  //   if (!mounted) return;
  //   setState(() {
  //     tabs.add({
  //       "title": "#$orderId", // New order number
  //       "subtitle": "Tab ${tabs.length + 1}", // Tab position
  //       "orderId": orderId as Object,
  //     });
  //   });
  //
  //   if (!mounted) return;
  //   _initializeTabController(); // Reinitialize tab controller
  //   _tabController?.index = tabs.length - 1; // Select the new tab
  //   _scrollToSelectedTab(); // Ensure new tab is visible
  //   fetchOrderItems(); // Load items for the new order
  // }

  // void addNewTab() async { // Build #1.0.44 : Un-Comment if this func needed and test
  //   if (kDebugMode) {
  //     print("##### DEBUG: addNewTab - Creating new order via OrderBloc");
  //   }
  //   String deviceId = await getDeviceId();
  //   OrderMetaData device = OrderMetaData(key: OrderMetaData.posDeviceId, value: deviceId);
  //   OrderMetaData placedBy = OrderMetaData(key: OrderMetaData.posPlacedBy, value: '${orderHelper.activeUserId ?? 1}');
  //   List<OrderMetaData> metaData = [device,placedBy];
  //   // Create new order via API
  //   await orderBloc.createOrder(metaData);
  //   // Refresh tabs to include new order
  //   _getOrderTabs();
  //   // Set the new order as active
  //   await orderHelper.setActiveOrder(tabs.last["orderId"] as int); // Set the new order as active
  //   // Update tab controller and UI
  //   _initializeTabController();
  //   if (tabs.isNotEmpty) {
  //     _tabController?.index = tabs.length - 1;
  //     // Scroll to new tab
  //     _scrollToSelectedTab();
  //     // Fetch items for new order
  //     await fetchOrderItems();
  //     if (kDebugMode) {
  //       print("##### DEBUG: addNewTab - Added tab for orderId: ${orderHelper.activeOrderId}");
  //     }
  //   }
  // }

  // Scrolls to the last tab to ensure visibility
  // void _scrollToSelectedTab() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (_scrollController.hasClients) {
  //       _scrollController.animateTo(
  //         _scrollController.position.maxScrollExtent,
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeInOut,
  //       );
  //     }
  //   });
  // }

  // Build #1.0.10: Removes a tab (order) from the UI and database
  // void removeTab(int index) async {
  //   if (tabs.isNotEmpty) {
  //     int orderId = tabs[index]["orderId"] as int;
  //     bool isRemovedTabActive = orderId == orderHelper.activeOrderId;
  //
  //     await orderHelper.deleteOrder(orderId); // Delete order from DB
  //
  //     setState(() {
  //       tabs.removeAt(index); // Remove tab from the UI
  //
  //       // Update subtitles to maintain order
  //       for (int i = 0; i < tabs.length; i++) {
  //         tabs[i]["subtitle"] = "Tab ${i + 1}";
  //       }
  //     });
  //
  //     _initializeTabController(); // Reinitialize tabs
  //
  //     if (tabs.isNotEmpty) {
  //       if (isRemovedTabActive) {
  //         // If the removed tab was active, switch to another tab
  //         int newIndex = index >= tabs.length ? tabs.length - 1 : index;
  //         _tabController!.index = newIndex;
  //         int newActiveOrderId = tabs[newIndex]["orderId"] as int;
  //         await orderHelper.setActiveOrder(newActiveOrderId);
  //       } else {
  //         // Keep the currently active tab
  //         int currentActiveIndex = tabs.indexWhere((tab) => tab["orderId"] == orderHelper.activeOrderId);
  //         if (currentActiveIndex != -1) {
  //           _tabController!.index = currentActiveIndex;
  //         }
  //       }
  //
  //       fetchOrderItems(); // Refresh order items list
  //     } else {
  //       // No orders left, reset active order and clear UI
  //       orderHelper.activeOrderId = null;
  //       setState(() {
  //         orderItems = []; // Clear order items
  //       });
  //     }
  //   }
  // }

  // Build #1.0.10: Deletes an item from the active order
  // void deleteItemFromOrder(int itemId) async {
  //   if (orderHelper.activeOrderId != null) {
  //     await orderHelper.deleteItem(itemId); // Delete item from DB
  //     fetchOrderItems(); // Refresh the order items list
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    debugPrint("????? OrdersScreenPanel: didChangeDependencies");
    fetchOrderItems();
  }

  @override
  void dispose() {
    _updateOrderSubscription?.cancel(); // Cancel the subscription
   // orderBloc.dispose(); // Dispose the bloc if needed // Build #1.0.143: No need
    _fetchOrdersSubscription?.cancel();
   // orderBloc.dispose();
    productBloc.dispose();
    _tabController?.dispose();
    _productBySkuSubscription?.cancel(); // Build #1.0.44 : Added Cancel product subscription
    productBloc.dispose(); // Added: Dispose ProductBloc
    super.dispose();
  }

  Future<String> getDeviceId() async { // Build #1.0.44 : Get Device Id
    final storeValidationRepository = StoreValidationRepository();
    try {
      final deviceDetails = await GlobalUtility.getDeviceDetails(); //Build #1.0.126: updated to GlobalUtility
      return deviceDetails['device_id'] ?? 'unknown';
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching device ID: $e');
      }
      return 'unknown';
    }
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.30,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.only(top: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              // Header shimmer
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 15,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              // Content shimmer
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                width: 100,
                                height: 10,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer shimmer
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 40,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final themeHelper = Provider.of<ThemeNotifier>(context);
    final RightOrderPanel orderScreenPanel = RightOrderPanel(formattedDate: '', formattedTime: '', quantities: []);

    // If no order is active, display a blank panel.
    return (!widget.fetchOrders) ? _buildShimmerEffect()
    //     ? Container(
    //   width: MediaQuery.of(context).size.width * 0.30,
    //   padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
    //   child: Card(
    //     elevation: 4,
    //     margin: const EdgeInsets.only(top: 10),
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    //     child: Container(), // Shows an empty card
    //   ),
    // )

    // If an order is active, build the regular order panel.
        : Container(
      width: MediaQuery.of(context).size.width * 0.30,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(top: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Container( // New design for history orders
              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground: null,
              padding: const EdgeInsets.fromLTRB(10, 10,10,10),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("#${orderHelper.activeOrderId ?? 'N/A'}",style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                      StatusWidget(
                        status: _order?[AppDBConst.orderStatus] ?? '',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: buildCurrentOrder()),
          ],
        ),
      ),
    );
  }

  //Build #1.0.67: Handler methods for response and error
  Future<void> _handleResponse(
      APIResponse response,
      Map<String, dynamic> orderItem, {
        bool isPayout = false,
        bool isCoupon = false,
        bool isCustomItem = false,
        VoidCallback? retryCallback, // Call back
      }) async {
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (response.status == Status.COMPLETED) {
      _scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("${isPayout ? TextConstants.payout : isCoupon ? TextConstants.coupon : isCustomItem ? TextConstants.customItem : 'Item'}" "${TextConstants.removedSuccessfully}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      await orderHelper.deleteItem(orderItem[AppDBConst.itemId]);
      await fetchOrderItems();
      widget.refreshOrderList?.call();
    } else if (response.status == Status.ERROR) {
      _scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(response.message ?? "${TextConstants.failedToRemove}" "${isPayout ? TextConstants.payout : isCoupon ? TextConstants.coupon : isCustomItem ? TextConstants.coupon : 'item'}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      if (isPayout) {
        await CustomDialog.showDiscountNotApplied(
          context,
          errorMessageTitle: TextConstants.removePayoutFailed,
          errorMessageDes: response.message ?? TextConstants.discountNotAppliedDescription,
          onRetry: retryCallback, // Pass retry callback
        );
      } else if (isCoupon) {
        await CustomDialog.showCouponNotApplied(
          context,
          errorMessageTitle: TextConstants.removeCouponFailed,
          errorMessageDes: response.message ?? TextConstants.couponNotAppliedDescription,
          onRetry: retryCallback, // Pass retry callback
        );
      } else if (isCustomItem) {
        await CustomDialog.showCustomItemNotAdded(
          context,
          errorMessageTitle: TextConstants.removeCustomItemFailed,
          errorMessageDes: response.message ?? TextConstants.customItemCouldNotBeAddedDescription,
          onRetry: retryCallback,
        );
      }
    }
  }



// Current Order UI
  Widget buildCurrentOrder() {
    final theme = Theme.of(context); // Build #1.0.6 - added theme for order panel
    final themeHelper = Provider.of<ThemeNotifier>(context);
    final ScrollController _scrollController = ScrollController();
    // Fetch the specific order if in history mode
    final order = orderHelper.activeOrderId != null
        ? orderHelper.orders.firstWhere(
          (o) => o[AppDBConst.orderServerId] == orderHelper.activeOrderId,
      orElse: () => {},
    )
        : {};

    // Determine the date and time to display
    String displayDate = widget.formattedDate;
    String displayTime = widget.formattedTime;

    if (order.isNotEmpty && order[AppDBConst.orderDate] != null) {
      try {
        final DateTime createdDateTime = DateTime.parse(order[AppDBConst.orderDate].toString());
        displayDate = DateFormat("EEE, MMM d, yyyy").format(createdDateTime);
        displayTime = DateFormat('hh:mm a').format(createdDateTime);
      } catch (e) {
        if (kDebugMode) {
          print("Error parsing order creation date: $e");
        }
        // Fallback to raw data or default if parsing fails
        displayDate = order[AppDBConst.orderDate].toString().split(' ').first;
      }
    }
    if (kDebugMode) {
      // print("Building Current Order Widget");
    } // Debug print
    // Fetch discount and tax for the active order
    double orderDiscount = 0.0;
    double merchantDiscount = 0.0;
    double orderTax = 0.0;
    num grossTotal = GlobalUtility.getGrossTotal(orderItems);  // Build #1.0.137: GrossTotal calculation form global class for code re usability
    num netTotal = 0.0;
    num netPayable = 0.0;  //Build #1.0.67

    // Update the calculation section in buildCurrentOrder:
    // if (orderHelper.activeOrderId != null) {
      // final order = orderHelper.orders.firstWhere(
      //       (order) => order[AppDBConst.orderServerId] == orderHelper.activeOrderId,
      //   orElse: () => {},
      // );

      // Get values from order or default to 0
      orderDiscount = order[AppDBConst.orderDiscount] as double? ?? 0.0;
      merchantDiscount = order[AppDBConst.merchantDiscount] as double? ?? 0.0;
      orderTax = order[AppDBConst.orderTax] as double? ?? 0.0;

    // Build #1.0.138: Calculate net total
    netTotal = grossTotal - orderDiscount ;

    //Build #1.0.146: Apply merchant discount (this is typically a separate discount)
    netTotal = netTotal - merchantDiscount;
    ///map total with netPayable
    netPayable =  order[AppDBConst.orderTotal] as double? ?? 0.0;

    // Build #1.0.138: Ensure no negative values
    netTotal = netTotal < 0 ? 0.0 : netTotal;
    netPayable = netPayable < 0 ? 0.0 : netPayable;

    if (kDebugMode) {  //Build #1.0.67
      // print("#### ACTIVE ORDER ID: ${orderHelper.activeOrderId}");
      // print("#### orderItems: $orderItems");
      // print("#### grossTotal: $grossTotal");
      // print("#### orderDiscount: $orderDiscount");
      // print("#### merchantDiscount: $merchantDiscount");
      // print("#### orderTax: $orderTax");
      // print("#### netTotal: $netTotal");
      // print("#### netPayable: $netPayable");
    }

    return Stack(
      children: [
        Column(
          children: [
            Container(
              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground: null,
              padding: const EdgeInsets.fromLTRB(10, 5, 16, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if(orderHelper.activeOrderId != null)
                  Row(
                    spacing: 4,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset('assets/svg/calendar.svg',width: 22,height: 22,),
                      Text(displayDate,  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.secondaryHeaderColor)),
                      const SizedBox(width: 8),
                      SvgPicture.asset('assets/svg/clock.svg',width: 22,height: 22,),
                      Text(displayTime ,style: TextStyle(fontSize: 14, color: theme.secondaryHeaderColor)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: DottedLine(
                dashLength: 4,
                dashGapLength: 4,
                lineThickness: 1,
                dashColor: theme.secondaryHeaderColor,
              ),
            ),
            Expanded(
              child: Container(
                color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground: null,
                child: Padding(
                  padding:  EdgeInsets.only(left:3, right: 3),
                  child: Scrollbar(
                    controller: _scrollController,
                    scrollbarOrientation: ScrollbarOrientation.right,
                    thumbVisibility: true,
                    thickness: 8.0,
                    interactive: false,
                    radius: const Radius.circular(8),
                    trackVisibility: true,
                    child: ReorderableListView.builder( //Build #1.0.4: re-order for list
                      onReorder: (oldIndex, newIndex) {
                        if (kDebugMode) {
                          print("Reordering item from $oldIndex to $newIndex");
                        } // Debug print
                        if (oldIndex < newIndex) newIndex -= 1;

                        setState(() {
                          final movedItem = orderItems.removeAt(oldIndex);
                          orderItems.insert(newIndex, movedItem);
                        });
                      },
                      scrollController: _scrollController,
                      itemCount: orderItems.length,
                      proxyDecorator: (Widget child, int index, Animation<double> animation) {
                        return Material(
                          color: Colors.transparent, // Removes white background
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final orderItem = orderItems[index];
                        if (kDebugMode) {
                          print("@@@@@@@@@@@@@@@@@ orderItem Data : $orderItem");
                        }
                        ///Build #1.0.64:  added conditions
                        /// Compare item type
                        /// if it is payout change icon, name is empty, show amount in red colour
                        /// if it is coupon change icon, name is coupon code (show last 4 digits, prefix with 'X' for each character before last 4), show amount in red colour
                        final itemType = orderItem[AppDBConst.itemType]?.toString().toLowerCase() ?? '';
                        /// Check if the item is a payout or a coupon
                        final isPayout = itemType.contains(TextConstants.payoutText);
                        final isCoupon = itemType.contains(TextConstants.couponText);
                        final isCustomItem = itemType.contains(TextConstants.customItemText);
                        final isPayoutOrCouponOrCustomItem = isPayout || isCoupon || isCustomItem;
                        final isCouponOrPayout = isPayout || isCoupon;
                        /// Get the original name
                        final originalName = orderItem[AppDBConst.itemName]?.toString() ?? '';
                        final variationName = orderItem[AppDBConst.itemVariationCustomName]?.toString() ?? 'N/A';
                        final variationCount = orderItem[AppDBConst.itemVariationCount] ?? 0;
                        final combo = orderItem[AppDBConst.itemCombo] ?? '';

                        /// Build #1.0.134: Item Price will check sales price if it is null/empty, check regular price else unit price
                        final salesPrice =
                        (orderItem[AppDBConst.itemSalesPrice] == null || (orderItem[AppDBConst.itemSalesPrice]?.toDouble() ?? 0.0) == 0.0)
                            ? (orderItem[AppDBConst.itemRegularPrice] == null || (orderItem[AppDBConst.itemRegularPrice]?.toDouble() ?? 0.0) == 0.0)
                            ? orderItem[AppDBConst.itemUnitPrice]?.toDouble() ?? 0.0
                            : orderItem[AppDBConst.itemRegularPrice]!.toDouble()
                            : orderItem[AppDBConst.itemSalesPrice]!.toDouble();

                        final regularPrice =  (orderItem[AppDBConst.itemRegularPrice] == null || (orderItem[AppDBConst.itemRegularPrice]?.toDouble() ?? 0.0) == 0.0)
                            ? orderItem[AppDBConst.itemUnitPrice]?.toDouble() ?? 0.0
                            : orderItem[AppDBConst.itemRegularPrice]!.toDouble();

                        final itemTotalPrice = orderItem[AppDBConst.itemSumPrice] ?? '';

                        if (kDebugMode) {
                          print("#### originalName: $originalName, itemType: $itemType, isPayoutOrCouponOrCustomItem: $isPayoutOrCouponOrCustomItem");
                          print("#### variationName: $variationName, variationCount: $variationCount, combo: $combo");
                          print("#### salesPrice: $salesPrice, regularPrice: $regularPrice, itemTotalPrice: $itemTotalPrice");
                        }
                        /// Set display name based on item type
                        String displayName = originalName;
                        if (isPayout) {
                          displayName = '';
                        } else if (isCoupon) {
                          final visiblePartLength = 4;
                          final nameLength = originalName.length;
                          if (nameLength > visiblePartLength) {
                            final maskedLength = nameLength - visiblePartLength;
                            final maskedPart = 'X' * maskedLength;
                            final visiblePart = originalName.substring(nameLength - visiblePartLength);
                            displayName = '$maskedPart$visiblePart';
                          }
                        }
                        return ClipRRect(
                          key: ValueKey(index),
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox( // Ensuring Slidable matches the item height
                            height: MediaQuery.of(context).size.height * 0.12, // Adjust to match your item height
                            child: Slidable( //Build #1.0.2 : added code for delete the items in list
                              key: ValueKey(index),
                              enabled: false,
                              closeOnScroll: true,
                              direction: Axis.horizontal,
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                children: [
                                  CustomSlidableAction(
                                    onPressed: (context) => {},
                                    backgroundColor: Colors.transparent,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        const SizedBox(height: 4),
                                        const Text(TextConstants.deleteText, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  if (isPayoutOrCouponOrCustomItem) return;
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) => EditProductScreen(
                                  //       orderItem: orderItem,
                                  //       onQuantityUpdated: (newQuantity) async {
                                  //
                                  //         if (orderHelper.activeOrderId != null) {
                                  //           final order = orderHelper.orders.firstWhere(
                                  //                 (order) => order[AppDBConst.orderId] == orderHelper.activeOrderId,
                                  //             orElse: () => {},
                                  //           );
                                  //           final serverOrderId = order[AppDBConst.orderServerId] as int?;
                                  //           final dbOrderId = orderHelper.activeOrderId;
                                  //           // final lineItemId = orderItem[AppDBConst.itemServerId] as int?;
                                  //           final productId = orderItem[AppDBConst.itemServerId] as int?;
                                  //
                                  //           if (serverOrderId != null && dbOrderId != null && productId != null) {
                                  //             _updateOrderSubscription?.cancel();
                                  //             _updateOrderSubscription = orderBloc.updateOrderStream.listen((response) async {
                                  //               if (response.status == Status.COMPLETED) {
                                  //                 await orderHelper.updateItemQuantity(
                                  //                   orderItem[AppDBConst.itemId],
                                  //                   newQuantity,
                                  //                 );
                                  //                 await fetchOrderItems();
                                  //               } else if (response.status == Status.ERROR) {
                                  //                 _scaffoldMessenger.showSnackBar(
                                  //                   SnackBar(
                                  //                     content: Text(response.message ?? "Failed to update quantity"),
                                  //                     backgroundColor: Colors.red,
                                  //                     duration: const Duration(seconds: 2),
                                  //                   ),
                                  //                 );
                                  //               }
                                  //             });
                                  //             // API CALL WHILE EDITING THE PRODUCT QUANTITY
                                  //             await orderBloc.updateOrderProducts(
                                  //               orderId: serverOrderId,
                                  //               dbOrderId: dbOrderId,
                                  //               lineItems: [
                                  //                 OrderLineItem(
                                  //                   productId: productId,
                                  //                   quantity: newQuantity,
                                  //                 ),
                                  //               ],
                                  //             );
                                  //           } else {
                                  //             await orderHelper.updateItemQuantity(
                                  //               orderItem[AppDBConst.itemId],
                                  //               newQuantity,
                                  //             );
                                  //             await fetchOrderItems();
                                  //           }
                                  //         }
                                  //       },
                                  //     ),
                                  //   ),
                                  // );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Replace the ClipRRect widget with this:
                                      ClipRRect( // Build #1.0.13 : updated images from db not static default images
                                        borderRadius: BorderRadius.circular(5),
                                        child: orderItem[AppDBConst.itemImage].toString().startsWith('http')
                                            ? SizedBox(
                                          height:MediaQuery.of(context).size.height * 0.08,
                                          width: MediaQuery.of(context).size.height * 0.075,
                                              child: Image.network(
                                                orderItem[AppDBConst.itemImage],
                                                height:MediaQuery.of(context).size.height * 0.08,
                                                width: MediaQuery.of(context).size.height * 0.075,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                              return SvgPicture.asset(
                                                'assets/svg/password_placeholder.svg',
                                                height:MediaQuery.of(context).size.height * 0.08,
                                                width: MediaQuery.of(context).size.height * 0.075,
                                                fit: BoxFit.cover,
                                              );
                                                                                        },
                                                                                      ),
                                            )
                                            : orderItem[AppDBConst.itemImage]
                                            .toString()
                                            .startsWith('assets/')
                                            ? SvgPicture.asset(
                                          orderItem[AppDBConst.itemImage],
                                          height:MediaQuery.of(context).size.height * 0.08,
                                          width: MediaQuery.of(context).size.height * 0.075,
                                          fit: BoxFit.cover,
                                        )
                                            :  Platform.isWindows
                                            ? Image.asset(
                                          'assets/default.png',
                                          height: MediaQuery.of(context).size.height * 0.08,
                                          width: MediaQuery.of(context).size.height * 0.075,
                                          fit: BoxFit.cover,
                                        )
                                            : Image.file(
                                          File(orderItem[AppDBConst.itemImage]),
                                          height:MediaQuery.of(context).size.height * 0.08,
                                          width: MediaQuery.of(context).size.height * 0.075,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return SvgPicture.asset(
                                              'assets/svg/password_placeholder.svg',
                                              height:MediaQuery.of(context).size.height * 0.08,
                                              width: MediaQuery.of(context).size.height * 0.075,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                RichText(
                                                  maxLines: 2,
                                                  softWrap: true,
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: displayName,
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: themeHelper.themeMode == ThemeMode.dark
                                                                ? ThemeNotifier.textDark
                                                                : ThemeNotifier.textLight
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: combo == '' ? '' : " (Combo)",
                                                        style: TextStyle(fontSize: 8, color: Colors.cyan),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                variationCount == 0 ? SizedBox(width: 0,) : Row(
                                                  children: [
                                                    Text(
                                                      variationName == '' ? "" : "(${variationName ?? ''})",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 10, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.grey),
                                                    ),
                                                    SizedBox(
                                                      width: 4,
                                                    ),
                                                    SvgPicture.asset("assets/svg/variation.svg",height: 10, width: 10,),
                                                    SizedBox(
                                                      width: 4,
                                                    ),
                                                    Text(
                                                      "${variationCount ?? 0}",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 10, color: Color(0xFFFE6464)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            // Modified: Show quantity * price only for non-Payout/Coupon items
                                            if (!isPayoutOrCouponOrCustomItem)
                                              Text(
                                                "${TextConstants.currencySymbol} ${regularPrice.toStringAsFixed(2)} * ${orderItem[AppDBConst.itemCount]}", //Build #1.0.134: itemPrice updated
                                                style:
                                                TextStyle(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.black54, fontSize: 10),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if(!isCouponOrPayout)
                                        Text("${TextConstants.currencySymbol}${(regularPrice * orderItem[AppDBConst.itemCount]).toStringAsFixed(2)}", //Build #1.0.134: itemPrice updated
                                          style:
                                          TextStyle(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.blueGrey, fontSize: 14),
                                        ),
                                      const SizedBox(width: 20),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isCouponOrPayout ?
                                            "${TextConstants.currencySymbol}${(orderItem[AppDBConst.itemCount] * orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}" :
                                            "${TextConstants.currencySymbol}${(orderItem[AppDBConst.itemCount] * salesPrice).toStringAsFixed(2)}", //Build #1.0.134: itemTotalPrice updated
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isPayoutOrCouponOrCustomItem ? Colors.red : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight, // Added: Red color for Payout/Coupon
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            ///Todo: update ui as per loading from screen
            ///Show print and email invoice buttons if coming from order history screen
            ///else show regular buttons
            Container(
              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground: null,
              child: Column(
                children: [
                  // Summary container
                  AnimatedSize(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showFullSummary
                        ? Container(
                      margin: const EdgeInsets.only(top: 8, right: 8, left: 8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              topLeft: Radius.circular(8)),
                          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.orderPanelSummary : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: ThemeNotifier.shadow_F7,
                              blurRadius: 2,
                              // spreadRadius: LayoutValues.radius_5,
                              offset: Offset(0,0),
                            ),
                          ]
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(TextConstants.grossTotal, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), ),
                              Text("${TextConstants.currencySymbol}${grossTotal.toStringAsFixed(2)}", //Build #1.0.68
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight)),
                            ],
                          ),
                          SizedBox(height: 2,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(spacing: 5,
                                children: [
                                  SvgPicture.asset("assets/svg/discount_star.svg",height: 12, width: 12,),
                                  Text(TextConstants.discountText, style: TextStyle(color: Colors.green, fontSize: 10)),
                                ],
                              ),
                              Text("-${TextConstants.currencySymbol}${orderDiscount.toStringAsFixed(2)}", style: TextStyle(color: Colors.green,fontSize: 10 )),
                            ],
                          ),
                          SizedBox(height: 2,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(spacing: 5,
                                children: [
                                  SvgPicture.asset("assets/svg/discount_star.svg",height: 12, width: 12,),
                                  Text(TextConstants.merchantDiscount, style: TextStyle(color: Colors.blue, fontSize: 10)),

                                  // GestureDetector(
                                  //   onTap: () async {
                                  //     if (kDebugMode) {
                                  //       print("####################### Merchant Discount onTap");
                                  //     }
                                  //
                                  //     if (orderHelper.activeOrderId != null) {
                                  //       // Step 1: Show confirmation dialog
                                  //       bool? confirmed = await CustomDialog.showRemoveDiscountConfirmation(context);
                                  //       if (confirmed != true) return;
                                  //
                                  //       // Step 2: Show loading with shimmer effect
                                  //       setState(() => _isLoading = true);
                                  //
                                  //       final order = orderHelper.orders.firstWhere(
                                  //             (order) => order[AppDBConst.orderId] == orderHelper.activeOrderId,
                                  //         orElse: () => {},
                                  //       );
                                  //       final serverOrderId = order[AppDBConst.orderServerId] as int?;
                                  //
                                  //       if (serverOrderId != null) {
                                  //         final db = await DBHelper.instance.database;
                                  //         final payoutItem = await db.query(
                                  //           AppDBConst.purchasedItemsTable,
                                  //           where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemType} = ?',
                                  //           whereArgs: [orderHelper.activeOrderId, ItemType.payout.value],
                                  //         );
                                  //
                                  //         if (payoutItem.isNotEmpty) {
                                  //           final payoutId = payoutItem.first[AppDBConst.itemServerId] as int?;
                                  //
                                  //           if (payoutId != null) {
                                  //             retryCallback() async {
                                  //               setState(() => _isLoading = true);
                                  //               orderBloc.removePayoutStream.listen((response) async {
                                  //                 setState(() => _isLoading = false);
                                  //                 if (response.status == Status.COMPLETED) {
                                  //                   await db.update(
                                  //                     AppDBConst.orderTable,
                                  //                     {AppDBConst.merchantDiscount: 0.0},
                                  //                     where: '${AppDBConst.orderId} = ?',
                                  //                     whereArgs: [orderHelper.activeOrderId],
                                  //                   );
                                  //                   await orderHelper.deleteItem(payoutItem.first[AppDBConst.itemId] as int);
                                  //                   fetchOrderItems();
                                  //                   widget.refreshOrderList?.call();
                                  //
                                  //                   ScaffoldMessenger.of(context).showSnackBar(
                                  //                     SnackBar(
                                  //                       content: Text("Merchant Discount removed successfully"),
                                  //                       backgroundColor: Colors.green,
                                  //                       duration: const Duration(seconds: 2),
                                  //                     ),
                                  //                   );
                                  //                 } else {
                                  //                   ScaffoldMessenger.of(context).showSnackBar(
                                  //                     SnackBar(
                                  //                       content: Text(response.message ?? "Failed to remove discount"),
                                  //                       backgroundColor: Colors.red,
                                  //                       duration: const Duration(seconds: 2),
                                  //                     ),
                                  //                   );
                                  //                   await CustomDialog.showDiscountNotApplied(
                                  //                     context,
                                  //                     errorMessageTitle: TextConstants.removeDiscountFailed,
                                  //                     errorMessageDes: response.message ?? TextConstants.discountNotAppliedDescription,
                                  //                     onRetry: retryCallback,
                                  //                   );
                                  //                 }
                                  //               });
                                  //               await orderBloc.removePayout(orderId: serverOrderId, payoutId: payoutId);
                                  //             }
                                  //             // THIS CALL FOR LETS RETRY BUTTON TAP ON ALERT DIALOG, WE HAVE TO CALL AGAIN THIS API
                                  //             orderBloc.removePayoutStream.listen((response) async {
                                  //               setState(() => _isLoading = false);
                                  //               if (response.status == Status.COMPLETED) {
                                  //                 await db.update(
                                  //                   AppDBConst.orderTable,
                                  //                   {AppDBConst.merchantDiscount: 0.0},
                                  //                   where: '${AppDBConst.orderId} = ?',
                                  //                   whereArgs: [orderHelper.activeOrderId],
                                  //                 );
                                  //                 await orderHelper.deleteItem(payoutItem.first[AppDBConst.itemId] as int);
                                  //                 fetchOrderItems();
                                  //                 widget.refreshOrderList?.call();
                                  //                 ScaffoldMessenger.of(context).showSnackBar(
                                  //                   SnackBar(
                                  //                     content: Text("Merchant Discount removed successfully"),
                                  //                     backgroundColor: Colors.green,
                                  //                     duration: const Duration(seconds: 2),
                                  //                   ),
                                  //                 );
                                  //               } else {
                                  //                 ScaffoldMessenger.of(context).showSnackBar(
                                  //                   SnackBar(
                                  //                     content: Text(response.message ?? "Failed to remove discount"),
                                  //                     backgroundColor: Colors.red,
                                  //                     duration: const Duration(seconds: 2),
                                  //                   ),
                                  //                 );
                                  //                 await CustomDialog.showDiscountNotApplied(
                                  //                   context,
                                  //                   errorMessageTitle: TextConstants.removeDiscountFailed,
                                  //                   errorMessageDes: response.message ?? TextConstants.discountNotAppliedDescription,
                                  //                   onRetry: retryCallback,
                                  //                 );
                                  //               }
                                  //             });
                                  //             await orderBloc.removePayout(orderId: serverOrderId, payoutId: payoutId);
                                  //           } else {
                                  //             setState(() => _isLoading = false);
                                  //             ScaffoldMessenger.of(context).showSnackBar(
                                  //               SnackBar(
                                  //                 content: Text("Payout ID not found"),
                                  //                 backgroundColor: Colors.red,
                                  //                 duration: const Duration(seconds: 2),
                                  //               ),
                                  //             );
                                  //           }
                                  //         } else {
                                  //           setState(() => _isLoading = false);
                                  //           ScaffoldMessenger.of(context).showSnackBar(
                                  //             SnackBar(
                                  //               content: Text("No payout found for this order"),
                                  //               backgroundColor: Colors.red,
                                  //               duration: const Duration(seconds: 2),
                                  //             ),
                                  //           );
                                  //         }
                                  //       } else {
                                  //         setState(() => _isLoading = false);
                                  //         ScaffoldMessenger.of(context).showSnackBar(
                                  //           SnackBar(
                                  //             content: Text("Server Order ID not found"),
                                  //             backgroundColor: Colors.red,
                                  //             duration: const Duration(seconds: 2),
                                  //           ),
                                  //         );
                                  //       }
                                  //     }
                                  //   },
                                  //   child: SvgPicture.asset("assets/svg/delete.svg", height: 12, width: 12),
                                  // ),
                                ],
                              ),
                              Text("-${TextConstants.currencySymbol}${merchantDiscount.toStringAsFixed(2)}",
                                  style: TextStyle(color: Colors.blue, fontSize: 10)),
                            ],
                          ),
                          SizedBox(height: 2,),
                          const DottedLine(),
                          SizedBox(height: 2,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(TextConstants.netTotalText,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),),
                              Text("${TextConstants.currencySymbol}${netTotal.toStringAsFixed(2)}",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight )),
                            ],
                          ),
                          SizedBox(height: 2,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(TextConstants.taxText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10,color: Colors.grey),),
                              Text("${TextConstants.currencySymbol}${orderTax.toStringAsFixed(2)}",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: themeHelper.themeMode == ThemeMode.dark ? Colors.white54 : Colors.grey)),
                            ],
                          ),
                          SizedBox(height: 2,),
                          const DottedLine(),
                          SizedBox(height: 2,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(TextConstants.netPayable, style: TextStyle(fontWeight: FontWeight.bold)),
                              Text("${TextConstants.currencySymbol}${netPayable.toStringAsFixed(2)}",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight)),
                            ],
                          ),
                        ],
                      ),
                    )
                        : SizedBox.shrink(),
                  ),
                  if(orderHelper.activeOrderId != null)
                  GestureDetector(
                    onTap: _toggleSummary,
                    child: Container(
                      margin: const EdgeInsets.only(top:2, right: 8, left: 8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(8),
                              bottomLeft: Radius.circular(8)),
                          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.orderPanelSummary : Colors.grey.shade300
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${TextConstants.totalItemsText}: ${orderItems.length}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
                          Row(
                            children: [
                              Text(_showFullSummary ? 'Net Payable : ${TextConstants.currencySymbol}${netPayable.toStringAsFixed(2)}' : 'Net Payable : ${TextConstants.currencySymbol}${netPayable.toStringAsFixed(2)}',style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(_showFullSummary ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  else
                    SizedBox(),

                  // Payment button - outside the container
                  if (orderHelper.activeOrderId != null)
                    Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.0575,
                    child:
                    (_order?[AppDBConst.orderStatus] ?? '') != 'on-hold'
                        ?
                    ElevatedButton( //Build 1.1.36: on pay tap calling updateOrderProducts api call
                      onPressed: () async {
                        if (orderHelper.activeOrderId != null) {
                          setState(() {
                            _isPayBtnLoading = true;
                          });

                          if (kDebugMode) {
                            print("OrderScreenPanel - call printer setup screen, $_printerReceipt");
                          }
                          if(!Misc.disablePrinter) {
                            ///prepare receipt
                            await _preparePrintTicket();
                            ///print invoice
                            await _printTicket();
                          }
                          setState(() => _isPayBtnLoading = false);
                          // if(_printerReceipt == null || (_printerReceipt != null && _printerReceipt[AppDBConst.printerDeviceName] == '')){
                          //   /// call printer setup screen
                          //   if (kDebugMode) {
                          //     print("OrderScreenPanel - call printer setup screen");
                          //   }
                          //   Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => PrinterSetup(),
                          //       )).then((result) async {
                          //     if (result == 'refresh') {
                          //       await _printerSettings.loadPrinter();
                          //       await loadPrinterData();
                          //       setState(() async {
                          //         // Update state to refresh the UI
                          //         if (kDebugMode) {
                          //           print(
                          //               "OrderScreenPanel - printer setup is done, connected printer is ${_printerSettings.selectedPrinter?.deviceName}");
                          //         }
                          //         ///print invoice
                          //         await _printTicket();
                          //         setState(() => _isPayBtnLoading = false);
                          //       });
                          //     }
                          //   });
                          // } else {
                          //
                          // }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B), // Coral red color
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isPayBtnLoading  //Build 1.1.36: added loader for pay button in order panel
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        TextConstants.printInvoice,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                        :
                    ElevatedButton( //Build 1.1.36: on pay tap calling updateOrderProducts api call
                      onPressed: netPayable >= 0 && orderItems.isNotEmpty ? () async {
                        if (orderHelper.activeOrderId != null) {
                          setState(() => _isPayBtnLoading = true);
                          _initialFetchDone = false; // Build #1.0.143: Track initial fetch of fetchOrdersData
                          // await Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => OrderSummaryScreen()),
                          // );
                          // On the first screen (Screen 1)
                          // Navigator.push(context, MaterialPageRoute(builder: (_) => OrderSummaryScreen())).then((result) {
                          //   if (result == 'refresh') {
                          //     setState(() {
                          //       // Update state to refresh the UI
                          //     });
                          //   }
                          // });
                          // Build #1.0.104: refresh when back to this screen
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OrderSummaryScreen(formattedTime: '',formattedDate: '',)),
                          );
                          if (kDebugMode) {
                            print("###### OrderScreenPanel: Returned from OrderSummaryScreen with result: $result");
                          }
                          // Handle refresh if result is 'refresh'
                          if (result == 'refresh') {
                            if (kDebugMode) {
                              print("###### OrderScreenPanel: Refresh signal received, reinitializing entire screen");
                            }

                            // Build #1.0.143: Fixed Issue : After return from order summary screen , total order screen not refreshing with updated response
                            widget.refreshOrderList?.call();
                          }
                          setState(() => _isPayBtnLoading = false);
                      ///No need to update here now, may cause empty items added to order
                      //     // Assign the subscription to your class variable
                      //     _updateOrderSubscription = orderBloc.updateOrderStream.listen((response) async {
                      //       if (!mounted) return; // Safety check
                      //       if (response.status == Status.LOADING) { // Build #1.0.80
                      //         const Center(child: CircularProgressIndicator());
                      //       }else if (response.status == Status.COMPLETED) {
                      //         if (kDebugMode) {
                      //           print("###### updateOrder COMPLETED");
                      //         }
                      //
                      //         setState(() => _isPayBtnLoading = false); // dismiss the loader
                      //
                      //         Navigator.push(
                      //           context,
                      //           MaterialPageRoute(builder: (context) => OrderSummaryScreen()),
                      //         );
                      //       } else if (response.status == Status.ERROR) {
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           SnackBar(content: Text(response.message ?? "Failed to update order")),
                      //         );
                      //       }
                      //     });
                      //
                      //     // Prepare line items for API
                      //     List<OrderLineItem> lineItems = orderItems.map((item) => OrderLineItem(
                      //       productId: item[AppDBConst.itemId],
                      //       quantity: item[AppDBConst.itemCount],
                      //     )).toList();
                      //
                      //     // Call API
                      //     await orderBloc.updateOrderProducts(
                      //       dbOrderId: orderHelper.activeOrderId!,
                      //       orderId: serverOrderId,
                      //       lineItems: lineItems,
                      //     );
                        }
                      }
                      : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: netPayable >= 0 && orderItems.isNotEmpty ? const Color(0xFFFF6B6B) : Colors.grey, // Coral red color
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isPayBtnLoading  //Build 1.1.36: added loader for pay button in order panel
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "${TextConstants.pay} ${TextConstants.currencySymbol}${netPayable.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  else SizedBox(),
                ],
              ),
            )
          ],
        ),
        if (_isLoading) // ADDED PROGRESS INDICATOR
          Container(
            color: Colors.black.withOpacity(0.5), // Black tint overlay
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.black, // Black loader
                strokeWidth: 6.0,
              ),
            ),
          ),
      ],
    );
  }

  double total = 0.0;
  double balanceAmount = 0.0;
  double tenderAmount = 0.0; // Build #1.0.33 : added new variables
  double paidAmount = 0.0;
  double changeAmount = 0.0;
  double discount = 0.0; // Add this to track discount
  double merchantDiscount = 0.0; // Add this to track merchant discount
  double tax = 0.0; // AddED tax variable
  double payByCash = 0.0;
  double payByOther = 0.0;
  final _printerSettings =  PrinterSettings();
  List<int> bytes = [];
  Future _preparePrintTicket() async{
    var header = _printerReceipt?[AppDBConst.receiptHeaderText] ?? "";
    var footer = _printerReceipt?[AppDBConst.receiptFooterText] ?? "";

    if (kDebugMode) {
      print("OrderSummaryScreen _preparePrintTicket call print receipt ---- $header");
      print("OrderSummaryScreen _preparePrintTicket call print receipt ---- $footer");
    }
    if (_order != null) {
      setState(() {
        var orderId = _order[AppDBConst.orderServerId] as int? ?? 0;
        var orderDateTime = "${_order[AppDBConst.orderDate]} ${_order[AppDBConst.orderTime]}" ;
        balanceAmount = (_order[AppDBConst.orderTotal] as num?)?.toDouble() ?? 0.0; // Fetch total
        discount = (_order[AppDBConst.orderDiscount] as num?)?.toDouble() ?? 0.0; // Fetch discount
        merchantDiscount = (_order[AppDBConst.merchantDiscount] as num?)?.toDouble() ?? 0.0;
        tax = (_order[AppDBConst.orderTax] as num?)?.toDouble() ?? 0.0;
        var balanceAmt = total - discount - merchantDiscount + tax;
        if (kDebugMode) {
          print("Fetched orderServerId: $orderId, Discount: $discount for activeOrderId: ${orderHelper.activeOrderId}, Time: $orderDateTime");
          print("Balance amount calculated is $balanceAmt and balance from API is $balanceAmount");
        }
      });
    } else {
      if (kDebugMode) {
        print("No orderServerId found for activeOrderId: ${orderHelper.activeOrderId}");
      }
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
    final ByteData data = await rootBundle.load('assets/ic_logo.png');
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
///Header
    bytes += ticket.row([
      PosColumn(text: "$header", width: 12),
    ]);

    bytes += ticket.feed(1);

    //Item header
    bytes += ticket.row([
      PosColumn(text: "#", width: 1),
      PosColumn(text: "Description", width:5),
      PosColumn(text: "Qty", width: 1),
      PosColumn(text: "Rate", width: 2),
      PosColumn(text: "Dis", width: 1),
      PosColumn(text: "Amt", width: 2),
    ]);
    bytes += ticket.feed(1);

    if (kDebugMode) {
      print(" >>>>> Order items count ${orderItems.length} ");

    }

    //Product Items
    for(int i = 0; i< orderItems.length; i++) {

      var orderItem = orderItems[i];

      final salesPrice =
      (orderItem[AppDBConst.itemSalesPrice] == null || (orderItem[AppDBConst.itemSalesPrice]?.toDouble() ?? 0.0) == 0.0)
          ? (orderItem[AppDBConst.itemRegularPrice] == null || (orderItem[AppDBConst.itemRegularPrice]?.toDouble() ?? 0.0) == 0.0)
          ? orderItem[AppDBConst.itemUnitPrice]?.toDouble() ?? 0.0
          : orderItem[AppDBConst.itemRegularPrice]!.toDouble()
          : orderItem[AppDBConst.itemSalesPrice]!.toDouble();

      final regularPrice =  (orderItem[AppDBConst.itemRegularPrice] == null || (orderItem[AppDBConst.itemRegularPrice]?.toDouble() ?? 0.0) == 0.0)
          ? orderItem[AppDBConst.itemUnitPrice]?.toDouble() ?? 0.0
          : orderItem[AppDBConst.itemRegularPrice]!.toDouble();

      if (kDebugMode) {
        print(" >>>>> Adding item ${orderItem[AppDBConst.itemName]} to print with salesPrice $salesPrice");
      }

      bytes += ticket.row([
        PosColumn(text: "${i+1}", width: 1),
        PosColumn(text: "${orderItem[AppDBConst.itemName]}", width:5),
        PosColumn(text: "${orderItem[AppDBConst.itemCount]}", width: 1),
        PosColumn(text: "$salesPrice", width:2),
        PosColumn(text: "${(regularPrice - salesPrice).toStringAsFixed(2)}", width: 1),
        PosColumn(text: "${(orderItem[AppDBConst.itemCount] * salesPrice).toStringAsFixed(2)}", width: 2),
      ]);
      // bytes += ticket.feed(1);
    }

    bytes += ticket.feed(1);

    if (kDebugMode) {
      print(" >>>>> Printer Order balanceAmount  $balanceAmount ");
      print(" >>>>> Printer Order tenderAmount $tenderAmount ");
      print(" >>>>> Printer Order changeAmount $changeAmount ");
      print(" >>>>> Printer Order paidAmount $paidAmount ");

    }
    //Breakdown
    //         balanceAmount = total - discount - merchantDiscount + tax;
    //         tenderAmount = 0.0; // Reset for new order
    //         changeAmount = 0.0; // Reset for new order
    //         paidAmount = 0.0; // Reset for new order

    bytes += ticket.row([
      PosColumn(text: TextConstants.grossTotal, width: 10),
      PosColumn(text: total.toStringAsFixed(2), width:2),
    ]);
    // bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: TextConstants.discountText, width: 10), // Build #1.0.148
      PosColumn(text: discount.toStringAsFixed(2), width:2),
    ]);
    // bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: TextConstants.merchantDiscount, width: 10),
      PosColumn(text: merchantDiscount.toStringAsFixed(2), width:2),
    ]);
    // bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: TextConstants.taxText, width: 10),
      PosColumn(text: tax.toStringAsFixed(2), width:2),
    ]);
    // bytes += ticket.feed(1);
    //line
    bytes += ticket.row([
      PosColumn(text: "-----------------------------------------------", width: 12),
    ]);

    bytes += ticket.feed(1);
    //Net Payable
    bytes += ticket.row([
      PosColumn(text: TextConstants.netPayable, width: 10),
      PosColumn(text: balanceAmount.toStringAsFixed(2), width:2),
    ]);
    // ///Todo: get pay by cash amount
    // // bytes += ticket.feed(1);
    // bytes += ticket.row([
    //   PosColumn(text: TextConstants.payByCash, width: 8),
    //   PosColumn(text: payByCash.toStringAsFixed(2), width:4),
    // ]);
    // ///Todo: get pay by other amount
    // // bytes += ticket.feed(1);
    // bytes += ticket.row([
    //   PosColumn(text: TextConstants.payByOther, width: 8),
    //   PosColumn(text: payByOther.toStringAsFixed(2), width:4),
    // ]);
    // // bytes += ticket.feed(1);
    // bytes += ticket.row([
    //   PosColumn(text: TextConstants.tenderAmount, width: 8),
    //   PosColumn(text: tenderAmount.toStringAsFixed(2), width:4),
    // ]);
    // // bytes += ticket.feed(1);
    // bytes += ticket.row([
    //   PosColumn(text: TextConstants.change, width: 8),
    //   PosColumn(text: changeAmount.toStringAsFixed(2), width:4),
    // ]);
    bytes += ticket.feed(1);

    //Footer
    // bytes += ticket.row([
    //   PosColumn(text: "Thank You, Visit Again", width: 12),
    // ]);
    bytes += ticket.row([
      PosColumn(text: "$footer", width: 12),
    ]);

    bytes += ticket.feed(1);
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
            if (result == 'refresh') {
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

  void _handleError(String message, {bool isPayout = false, bool isCoupon = false, bool isCustomItem = false}) async {
    if (!mounted) return; // Check if widget is still mounted
    setState(() => _isLoading = false);
    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
  //Build #1.0.67
  Future<void> _handleLocalDelete(Map<String, dynamic> orderItem, BuildContext context) async {
    if (!mounted) return; // Check if widget is still mounted
    setState(() => _isLoading = false);
    await orderHelper.deleteItem(orderItem[AppDBConst.itemId]);
    await fetchOrderItems();
    widget.refreshOrderList?.call();
    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(TextConstants.itemRemoved),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
