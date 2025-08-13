import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Models/Search/product_by_sku_model.dart' as SKU;
import 'package:pinaka_pos/Models/Search/product_search_model.dart';
import 'package:pinaka_pos/Providers/Auth/product_variation_provider.dart';
import 'package:pinaka_pos/Screens/Home/order_summary_screen.dart';
import 'package:pinaka_pos/Widgets/widget_age_verification_popup_dialog.dart';
import 'package:pinaka_pos/Widgets/widget_alert_popup_dialogs.dart';
import 'package:pinaka_pos/Widgets/widget_custom_num_pad.dart';
import 'package:pinaka_pos/Widgets/widget_nested_grid_layout.dart';
import 'package:pinaka_pos/Widgets/widget_tabs.dart';
import 'package:pinaka_pos/Widgets/widget_topbar.dart';
import 'package:pinaka_pos/Widgets/widget_variants_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../Blocs/Orders/order_bloc.dart';
import '../Blocs/Search/product_search_bloc.dart';
import '../Constants/layout_values.dart';
import '../Constants/text.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
import '../Helper/Extentions/theme_notifier.dart';
import '../Helper/api_response.dart';
import '../Utilities/global_utility.dart';
import '../Models/Orders/orders_model.dart';
import '../Providers/Age/age_verification_provider.dart';
import '../Repositories/Auth/store_validation_repository.dart';
import '../Repositories/Orders/order_repository.dart';
import '../Repositories/Search/product_search_repository.dart';
import '../Screens/Home/add_screen.dart';
import '../Screens/Home/edit_product_screen.dart';

class RightOrderPanel extends StatefulWidget {
  final String formattedDate;
  final String formattedTime;
  final List<int> quantities;
  final VoidCallback? refreshOrderList;

  const RightOrderPanel({
    required this.formattedDate,
    required this.formattedTime,
    required this.quantities,
    this.refreshOrderList,
    Key? key,
  }) : super(key: key);

  @override
  _RightOrderPanelState createState() => _RightOrderPanelState();
}

class _RightOrderPanelState extends State<RightOrderPanel> with TickerProviderStateMixin {
  List<Map<String, Object>> tabs = []; // List of order tabs
  TabController? _tabController; // Controller for tab switching
  final ScrollController _scrollController = ScrollController(); // Scroll controller for tab scrolling
  List<Map<String, dynamic>> orderItems = []; // List of items in the selected order
  final OrderHelper orderHelper = OrderHelper(); // Helper instance to manage orders
  bool _isLoading = false;
  bool _isPayBtnLoading = false;
  late OrderBloc orderBloc;
  StreamSubscription? _updateOrderSubscription;
  StreamSubscription? _fetchOrdersSubscription;
  final ProductBloc productBloc = ProductBloc(ProductRepository()); // Build #1.0.44 : Added for barcode scanning
  StreamSubscription? _productBySkuSubscription; // Build #1.0.44 : Added for product stream
  StreamSubscription? _removePayoutOrDiscountSubscription;
  StreamSubscription? _removeCouponSubscription;
  bool _showFullSummary = false;
  late ScaffoldMessengerState _scaffoldMessenger;
  bool _isFetchingInitialData = false; // Build #1.0.128: Added this flag to track if we're in the middle of initial fetch

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
    orderBloc = OrderBloc(OrderRepository());
    super.initState();
    // Build #1.0.161 - Fixed Issue: when comes from orders screen to order panel screens selected orderId changing
    orderHelper.restoreActiveOrderId(); // Build #1.0.161:
    fetchOrdersData(); // Build #1.0.104
  }

  // Build #1.0.104: created this function for initial call & while back to this screen
  void fetchOrdersData(){
    if (kDebugMode) {
      print("##### fetchOrdersData called");
    }
    setState(() { // Build #1.0.128: Added this flag to track if we're in the middle of initial fetch
      _isFetchingInitialData = true;
      _isLoading = true;
    });
    /// No need _getOrderTabs here calling inside _fetchOrders (because of this before api call db order tabs showing)
   // _getOrderTabs(); //Build #1.0.40: Load existing orders into tabs
    _fetchOrders(); //Build #1.0.40: Fetch orders on initialization
  }

  @override
  void didUpdateWidget(RightOrderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
   // if (mounted) {
    //  if(tabs.isNotEmpty){ // Build #1.0.104: Adding this conditions for old orderId's are showing before sync api call
    //    _getOrderTabs(); // Build #1.0.10 : Reload tabs when the widget updates (e.g., after item selection)
    //  }
   // }
    if (mounted && !_isFetchingInitialData) { // Build #1.0.128: hOnly update if not in initial fetch
      setState(() => _isLoading = true); // Build #1.0.131: show loader in order panel after selecting item/product
      if (kDebugMode) {
        print("##### _isFetchingInitialData : $_isFetchingInitialData");
      }
      _getOrderTabs();
    }

    if (kDebugMode) {
      print("##### OrderPanel didUpdateWidget");
    }
  }

  // Build #1.0.10: Fetches the list of order tabs from OrderHelper
  void _getOrderTabs() async {
    if (kDebugMode) {
      print("##### DEBUG: _getOrderTabs - Loading order tabs, loadOrderItems 1");
    }
    await orderHelper.loadData(); // Load order data from DB

    if (kDebugMode) {
      print("#### Order Panel loadData: activeOrderId = ${orderHelper.activeOrderId}");
      print("#### Order Panel loadData: orderIds = ${orderHelper.orderIds}");
    }
    if (mounted) {
      setState(() {
        // Convert order IDs into tab format
        tabs = orderHelper.orders
            .asMap()
            .entries
            .map((entry) => {
          "title": "#${entry.value[AppDBConst.orderServerId] ?? entry.value[AppDBConst.orderId]}",
          "subtitle": "Tab ${entry.key + 1}",
          "orderId": entry.value[AppDBConst.orderServerId] as Object, // Use db orderId, not serverId
        }).toList();
        if (kDebugMode) {
          print("##### DEBUG: _getOrderTabs - Loaded ${tabs.length} tabs: $tabs");
        }
      });
    }
    if (kDebugMode) {
      print("##### DEBUG: _getOrderTabs - orderHelper.activeOrderId ${orderHelper.activeOrderId} tab: $tabs, index: ${orderHelper.orderIds.indexOf(orderHelper.activeOrderId ?? 0)}"); // Build #1.0.104: unwrap issue fixed
    }

    if (!mounted) return; // Prevent controller initialization if unmounted
    _initializeTabController(); // Initialize tab controller
    if (kDebugMode) {
      print("##### _getOrderTabs saveLastActiveOrderId tabs.isNotEmpty ${tabs.isNotEmpty}");
    }
    if (tabs.isNotEmpty) {
      int index = -1;
      if (orderHelper.activeOrderId != null) {
        index = orderHelper.orderIds.indexOf(orderHelper.activeOrderId!);
        if (kDebugMode) {
          print("##### _getOrderTabs saveLastActiveOrderId index: $index");
        }
        if (index == -1) {
          if (kDebugMode) {
            print("##### DEBUG: _getOrderTabs - Active order ID ${orderHelper.activeOrderId} not found, defaulting to last tab");
          }
          index = tabs.length - 1;
        }
        await orderHelper.setActiveOrder(tabs[index]["orderId"] as int);
        if (kDebugMode) {
          print("saveLastActiveOrderId _getOrderTabs yes active tab, orderHelper.activeOrderId: ${orderHelper.activeOrderId}, orderID: ${tabs[index]["orderId"]}");
        }
        await orderHelper.saveLastActiveOrderId(tabs[index]["orderId"] as int); // Build #1.0.161

      } else {
        if (kDebugMode) {
          print("##### DEBUG: _getOrderTabs - No active order, setting to last tab");
        }
        index = tabs.length - 1;
        await orderHelper.setActiveOrder(tabs[index]["orderId"] as int);
        if (kDebugMode) {
          print("saveLastActiveOrderId _getOrderTabs no active tab, orderHelper.activeOrderId: ${orderHelper.activeOrderId}, orderID: ${tabs[index]["orderId"]}");
        }
        await orderHelper.saveLastActiveOrderId(tabs[index]["orderId"] as int); // Build #1.0.161
      }
      if (mounted && _tabController != null) {
        _tabController?.index = index;
        if (kDebugMode) {
          print("##### DEBUG: _getOrderTabs - Set tab index to $index, orderID: ${tabs[index]["orderId"]} activeOrderId: ${orderHelper.activeOrderId}");
        }
      }

      //Build #1.0.78: FIX: Scroll to ensure active tab is visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && _tabController != null) {
          final tabWidth = 180.0; // Adjust this based on your actual tab width
          final screenWidth = MediaQuery.of(context).size.width * 0.58; // Panel width
          final activeIndex = _tabController!.index;
          final offset = (activeIndex * tabWidth) - (screenWidth / 2) + (tabWidth / 2);

          _scrollController.animateTo(
            offset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });

      await fetchOrderItems(); // Load items for active order
      if(mounted) {
        setState(() => _isLoading = false); // Build #1.0.104: Hide loader
      }
    } else {
      if (kDebugMode) {
        print("##### DEBUG: _getOrderTabs - No tabs available");
      }
      if (mounted) {
        setState(() {
          orderItems = [];// Build #1.0.104: Clear items if no tabs
        });
      }
      setState(() => _isLoading = false); // Hide loader
    }
  }

  void _fetchOrders() { //Build #1.0.40: fetch orders items from API sync & updating to UI
    // updated above
    // setState(() => _isLoading = true); // Build #1.0.104: Show loader
    _fetchOrdersSubscription = orderBloc.fetchOrdersStream.listen((response) async {
      if (!mounted) return;

      if (response.status == Status.COMPLETED) {
        if (kDebugMode) {
          print("##### DEBUG: Fetched orders successfully 33333, total orders: ${orderHelper.orders.length}");
        }
        setState(() => _isFetchingInitialData = false); // Build #1.0.128: Initial fetch complete
        _getOrderTabs();
        //_fetchOrdersSubscription?.cancel();
      } else if (response.status == Status.ERROR) {
        if (kDebugMode) {
          print("##### ERROR: Fetch orders failed - ${response.message}");
        }
        setState(() {
          _isLoading = false;
          _isFetchingInitialData = false; // Build #1.0.128
        }); // Build #1.0.104: Hide loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? "Failed to fetch orders")),
        );
      }
    });

    orderBloc.fetchOrders();
  }

  // Build #1.0.10: Fetches order items for the active order
  Future<void> fetchOrderItems() async {
    if (kDebugMode) {
      print("##### DEBUG: fetchOrderItems 112233");
    }
    if (orderHelper.activeOrderId != null) {
      if (kDebugMode) {
        print("##### DEBUG: order panel fetchOrderItems - Fetching items for activeOrderId: ${orderHelper.activeOrderId}");
      }
      try {
        var order = await orderHelper.getOrderById(orderHelper.activeOrderId!);
        if (kDebugMode) {
          print("##### DEBUG: fetchOrderItems - Retrieved ${order.length}");
          print("##### DEBUG: fetchOrderItems - Retrieved items: ${order.first[AppDBConst.orderServerId]}");
          print("##### DEBUG: fetchOrderItems - Retrieved items: ${order.first[AppDBConst.itemProductId]}");
        }
        List<Map<String, dynamic>> items = await orderHelper.getOrderItems(order.first[AppDBConst.orderServerId]);

        if (kDebugMode) {
          print("##### DEBUG: fetchOrderItems - Retrieved ${items.length} items: $items");
        }

        if (mounted) {
          setState(() {
            orderItems = items; // Update the order items list
          });
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("##### ERROR: fetchOrderItems failed - $e, Stack: $s");
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
      setState(() => _isLoading = false); // Build #1.0.104: Hide loader
      if (mounted) {
        setState(() {
          orderItems.clear(); // Clear items if no active order
        });
      }
    }
  }

  // Build #1.0.10: Initializes the tab controller and handles tab switching
  void _initializeTabController() {
    if (kDebugMode) {
      print("##### _initializeTabController");
    }
    if (!mounted) return; // Prevent initialization if unmounted
    _tabController?.dispose(); // Dispose existing controller
    _tabController = TabController(length: tabs.length, vsync: this);

    _tabController!.addListener(() async {
      if (!_tabController!.indexIsChanging && mounted) {
        int selectedIndex = _tabController!.index; // Get selected tab index
        int selectedOrderId = tabs[selectedIndex]["orderId"] as int;

        if (kDebugMode) {
          print("##### DEBUG: Tab changed to index: $selectedIndex, orderId: $selectedOrderId");
        }

        await orderHelper.setActiveOrder(selectedOrderId); // Set new active order
        if (kDebugMode) {
          print("saveLastActiveOrderId _initializeTabController, selectedOrderId: $selectedOrderId, Tab selectedIndex: $selectedIndex");
        }
        await orderHelper.saveLastActiveOrderId(selectedOrderId); // Build #1.0.161
        await fetchOrderItems(); // Load items for the selected order
        if (mounted) {
          setState(() {}); // Refresh UI
        }
      }
    });
  }

  // Build #1.0.10: Creates a new order and adds it as a new tab
  //Build #1.0.78: Explanation!
  // Removed orderHelper.createOrder and setActiveOrder as they’re now handled in OrderBloc.
  // Updated UI (tabs, tab controller, items) after API success.
  // Added alert dialog for error handling with retry option.
  // Loader is shown via _isLoading during the API call.
  void addNewTab() async {
    // Create new order if none exists
    if (kDebugMode) {
      print("##### DEBUG: addNewTab - Creating new order");
    }
    /// Build #1.0.128: No need here , now we are handling from Order repository class
    // final prefs = await SharedPreferences.getInstance();
    // final shiftId = prefs.getString(TextConstants.shiftId);
    //
    // //Build #1.0.78: Validation required : if shift id is empty show toast or alert user to start the shift first
    // if (shiftId == null || shiftId.isEmpty) {
    //   if (kDebugMode) print("####### _createOrder() : shiftId -> $shiftId");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text("Please start your shift before creating an order."),
    //       backgroundColor: Colors.green,
    //       duration: const Duration(seconds: 2),
    //     ),
    //   );
    // }
    setState(() => _isLoading = true); // Show loader
    // String deviceId = await getDeviceId();
    // OrderMetaData device = OrderMetaData(key: OrderMetaData.posDeviceId, value: deviceId);
    // OrderMetaData placedBy = OrderMetaData(key: OrderMetaData.posPlacedBy, value: '${orderHelper.activeUserId ?? 1}');
    // OrderMetaData shiftIdValue = OrderMetaData(key: OrderMetaData.shiftId, value: shiftId!);
    // List<OrderMetaData> metaData = [device, placedBy, shiftIdValue];

    _updateOrderSubscription?.cancel();
    _updateOrderSubscription = orderBloc.createOrderStream.listen((response) async {
      if (!mounted) return;

      if (response.status == Status.COMPLETED) {
        setState(() => _isLoading = false); // Hide loader
        if (kDebugMode) {
          print("##### DEBUG: addNewTab - Order created successfully, serverOrderId: ${response.data!.id}");
        }
        setState(() {
          tabs.add({
            "title": "#${response.data!.id}",
            "subtitle": "Tab ${tabs.length + 1}",
            "orderId": response.data!.id as Object,
          });
        });

        _initializeTabController();
        _tabController?.index = tabs.length - 1;
        _scrollToSelectedTab();
        await fetchOrderItems();

        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Order created successfully"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (response.status == Status.ERROR) {
        setState(() => _isLoading = false); //Build #1.0.99: Hide loader
        if (kDebugMode) {
          print("##### ERROR: addNewTab - Failed to create order: ${response.message}");
        }
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(response.message ?? "Failed to create order"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    await orderBloc.createOrder(); // Build #1.0.128
  }

  // Scrolls to the last tab to ensure visibility
  void _scrollToSelectedTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Build #1.0.10: Removes a tab (order) from the UI and database
  //Build #1.0.78:Explanation:
  // Removed orderHelper.deleteOrder from the API success block, as it’s now handled in OrderBloc.changeOrderStatus.
  // Kept local deletion for non-API orders (serverOrderId == null).
  // Ensured loader is shown (_isLoading = true) and hidden appropriately.
  // Added alert dialog for error handling with retry option.
  void removeTab(int index) async {
    if (tabs.isNotEmpty) {
      int orderId = tabs[index]["orderId"] as int;
      bool isRemovedTabActive = orderId == orderHelper.activeOrderId;

      setState(() => _isLoading = true); // Show loader
      // final order = orderHelper.orders.firstWhere(
      //       (order) => order[AppDBConst.orderServerId] == orderHelper.activeOrderId,
      //   orElse: () => {},
      // );
      final serverOrderId = orderHelper.activeOrderId;//order[AppDBConst.orderServerId] as int?;

      if (serverOrderId != null) {
        _updateOrderSubscription?.cancel();
        _updateOrderSubscription = orderBloc.changeOrderStatusStream.listen((response) async {
          if (!mounted) return;
          if (response.status == Status.COMPLETED) {
            setState(() => _isLoading = false); //Build #1.0.92: loader hide
            if (kDebugMode) {
              print("##### DEBUG: removeTab - Order $orderId successfully cancelled");
            }
            setState(() {
              tabs.removeAt(index);
              for (int i = 0; i < tabs.length; i++) {
                tabs[i]["subtitle"] = "Tab ${i + 1}";
              }
            });
            _initializeTabController();
            if (tabs.isNotEmpty) {
              if (isRemovedTabActive) {
                int newIndex = index >= tabs.length ? tabs.length - 1 : index;
                _tabController!.index = newIndex;
                int newActiveOrderId = tabs[newIndex]["orderId"] as int;
                await orderHelper.setActiveOrder(newActiveOrderId);
                print("saveLastActiveOrderId removeTab serverOrderId: $serverOrderId, newActiveOrderId: $newActiveOrderId");
                await orderHelper.saveLastActiveOrderId(newActiveOrderId); // Build #1.0.161
              } else {
                int currentActiveIndex = tabs.indexWhere((tab) => tab["orderId"] == orderHelper.activeOrderId);
                if (currentActiveIndex != -1) {
                  _tabController!.index = currentActiveIndex;
                }
              }
              await fetchOrderItems(); // Refresh order items list
            } else {
              print("removeTab serverOrderId: $serverOrderId, orderHelper.activeOrderId to null");
              orderHelper.activeOrderId = null;
              setState(() {
                orderItems = [];
              });
               _fetchOrders(); // Build #1.0.128: we have to refresh the orders , if orders are empty , otherwise if you add new item creating with new order and prev order also appear issue.
            }
            _scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(TextConstants.orderCancelled),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (response.status == Status.ERROR) {
            setState(() => _isLoading = false); //Build #1.0.99: Hide loader
            if (kDebugMode) {
              print("##### ERROR: removeTab - Cancel failed: ${response.message}");
            }
            _scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(response.message ?? "Failed to cancel order"),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
        await orderBloc.changeOrderStatus(orderId: serverOrderId, status: TextConstants.cancelled);
      } else {
        // Local deletion for orders without serverOrderId
        await orderHelper.deleteOrder(orderId);
        setState(() {
          tabs.removeAt(index);
          for (int i = 0; i < tabs.length; i++) {
            tabs[i]["subtitle"] = "Tab ${i + 1}";
          }
        });
        _initializeTabController();
        if (tabs.isNotEmpty) {
          if (isRemovedTabActive) {
            int newIndex = index >= tabs.length ? tabs.length - 1 : index;
            _tabController!.index = newIndex;
            int newActiveOrderId = tabs[newIndex]["orderId"] as int;
            await orderHelper.setActiveOrder(newActiveOrderId);
            print("saveLastActiveOrderId removeTab serverOrderId: $serverOrderId, newActiveOrderId: $newActiveOrderId");
            await orderHelper.saveLastActiveOrderId(newActiveOrderId); // Build #1.0.161
          } else {
            int currentActiveIndex = tabs.indexWhere((tab) => tab["orderId"] == orderHelper.activeOrderId);
            if (currentActiveIndex != -1) {
              _tabController!.index = currentActiveIndex;
            }
          }
          await fetchOrderItems();
        } else {
          // No orders left, reset active order and clear UI
          print("removeTab serverOrderId: $serverOrderId, orderHelper.activeOrderId to null");
          orderHelper.activeOrderId = null;
          setState(() {
            orderItems = [];
          });
        }
        setState(() => _isLoading = false); // Hide loader
        _scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(TextConstants.orderCancelled),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Build #1.0.10: Deletes an item from the active order
  //Build #1.0.78: Explanation!
  // Removed database operations (orderHelper.deleteItem) as they’re now in OrderBloc.
  // Added dbOrderId and dbItemId to deleteOrderItem, removeFeeLines, and removeCoupon calls.
  // Used sku in OrderLineItem for custom items and products.
  // Ensured loader is shown during API calls.
  // Kept local deletion for non-API orders.
  void deleteItemFromOrder(int itemId) async {

    if (orderHelper.activeOrderId != null) {

      setState(() {
        _isLoading = true;
        if (kDebugMode) {
          print("##### deleteItemFromOrder: _isLoading: $_isLoading");
        }
      }); // Show loader

      // final order = orderHelper.orders.firstWhere(
      //       (order) => order[AppDBConst.orderServerId] == orderHelper.activeOrderId,
      //   orElse: () => {},
      // );
      final serverOrderId = orderHelper.activeOrderId;//order[AppDBConst.orderServerId] as int?;
     // final dbOrderId = orderHelper.activeOrderId!;
      final item = orderItems.firstWhere(
            (item) => item[AppDBConst.itemServerId] == itemId,
        orElse: () => {},
      );
      final itemType = item[AppDBConst.itemType]?.toString().toLowerCase() ?? '';
      final isPayout = itemType.contains(TextConstants.payoutText);
      final isCoupon = itemType.contains(TextConstants.couponText);
      final isCustomItem = itemType.contains(TextConstants.customItemText);

      if (serverOrderId != null) {
        _updateOrderSubscription?.cancel();
        if (isPayout) {
          final db = await DBHelper.instance.database;
          final payoutItem = await db.query(
            AppDBConst.purchasedItemsTable,
            where: '${AppDBConst.itemServerId} = ? AND ${AppDBConst.itemType} = ?',
            whereArgs: [itemId, ItemType.payout.value],
          );
          if (payoutItem.isNotEmpty) {
            final payoutId = payoutItem.first[AppDBConst.itemServerId] as int?;
            if (payoutId != null) {
              _removePayoutOrDiscountSubscription?.cancel(); //Build #1.0.99
              retryCallback() async {
                setState(() => _isLoading = true);
                await orderBloc.removeFeeLine(orderId: serverOrderId, feeLineId: payoutId); //Build #1.0.92: dbOrderId and serverOrderId is same, no need then
                //Build #1.0.99: Dismiss dialog after retry
                Navigator.of(context, rootNavigator: true).pop();
              }
              _removePayoutOrDiscountSubscription = orderBloc.removePayoutStream.listen((response) async {
                await _handleResponse(response, item, isPayout: true, retryCallback: retryCallback);
              });
              await orderBloc.removeFeeLine(orderId: serverOrderId, feeLineId: payoutId); //Build #1.0.92: dbOrderId and serverOrderId is same
            } else {
              await _handleLocalDelete(item, context);
              _handleError("Payout ID not found in database, removed locally", isPayout: true);
            }
          } else {
            _handleError("Payout not found", isPayout: true);
          }
        } else if (isCoupon) {
          final couponCode = item[AppDBConst.itemName]?.toString() ?? '';
          if (couponCode.isNotEmpty) {
            _removeCouponSubscription?.cancel(); //Build #1.0.99
            retryCallback() async {
              setState(() => _isLoading = true);
              await orderBloc.removeCoupon(orderId: serverOrderId, couponCode: couponCode);
              //Build #1.0.99: Dismiss dialog after retry
              Navigator.of(context, rootNavigator: true).pop();
            }
            _removeCouponSubscription = orderBloc.removeCouponStream.listen((response) async {
              await _handleResponse(response, item, isCoupon: true, retryCallback: retryCallback);
            });
            await orderBloc.removeCoupon(orderId: serverOrderId, couponCode: couponCode);
          } else {
            await _handleLocalDelete(item, context);
            _handleError("Coupon code not found in database, removed locally", isCoupon: true);
          }
        } else if (isCustomItem) {
          final db = await DBHelper.instance.database;
          final customItem = await db.query(
            AppDBConst.purchasedItemsTable,
            where: '${AppDBConst.itemServerId} = ? AND ${AppDBConst.itemType} = ?', //Build #1.0.92: updated to itemServerId
            whereArgs: [itemId, ItemType.customProduct.value],
          );
          if (customItem.isNotEmpty) {
            final customItemId = customItem.first[AppDBConst.itemServerId] as int?;
            if (customItemId != null) {
              retryCallback() async {
                setState(() => _isLoading = true);
                await orderBloc.deleteOrderItem(
                  orderId: serverOrderId,
                  // dbOrderId: dbOrderId,
                  dbItemId: itemId,
                  lineItems: [
                    OrderLineItem(
                      id: customItemId,
                      quantity: 0,
                      //  sku: item[AppDBConst.itemSKU] ?? '',
                    ),
                  ],
                );
                //Build #1.0.99 : Dismiss dialog after retry
                Navigator.of(context, rootNavigator: true).pop();
              }
              _updateOrderSubscription = orderBloc.deleteOrderItemStream.listen((response) async {
                await _handleResponse(response, item, isCustomItem: true, retryCallback: retryCallback);
              });
              await orderBloc.deleteOrderItem(
                orderId: serverOrderId,
                //  dbOrderId: dbOrderId,
                dbItemId: itemId,
                lineItems: [
                  OrderLineItem(
                    id: customItemId,
                    quantity: 0,
                    //   sku: item[AppDBConst.itemSKU] ?? '',
                  ),
                ],
              );
            } else {
              await _handleLocalDelete(item, context);
              _handleError("Custom item ID not found in database, removed locally", isCustomItem: true);
            }
          } else {
            _handleError("Custom item not found", isCustomItem: true);
          }
        } else {
          final productId = item[AppDBConst.itemServerId] as int?;
          if (productId != null) {
            retryCallback() async {
              setState(() => _isLoading = true);
              await orderBloc.deleteOrderItem(
                orderId: serverOrderId,
                // dbOrderId: dbOrderId,
                dbItemId: itemId,
                lineItems: [
                  OrderLineItem(
                    id: productId,
                    quantity: 0,
                    //   sku: item[AppDBConst.itemSKU] ?? '',
                  ),
                ],
              );
              //Build #1.0.99 : Dismiss dialog after retry
              Navigator.of(context, rootNavigator: true).pop();
            }
            _updateOrderSubscription = orderBloc.deleteOrderItemStream.listen((response) async {
              await _handleResponse(response, item, retryCallback: retryCallback);
            });
            await orderBloc.deleteOrderItem(
              orderId: serverOrderId,
              //  dbOrderId: dbOrderId,
              dbItemId: itemId,
              lineItems: [
                OrderLineItem(
                  id: productId,
                  quantity: 0,
                  //  sku: item[AppDBConst.itemSKU] ?? '',
                ),
              ],
            );
          } else {
            await _handleLocalDelete(item, context);
          }
        }
      } else {
        await _handleLocalDelete(item, context);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _updateOrderSubscription?.cancel(); // Cancel the subscription
    orderBloc.dispose(); // Dispose the bloc if needed
    _fetchOrdersSubscription?.cancel();
    orderBloc.dispose();
    productBloc.dispose();
    _tabController?.dispose();
    _scrollController.dispose(); // Dispose ScrollController
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return BarcodeKeyboardListener( // Build #1.0.44 : Added - Wrap with BarcodeKeyboardListener for barcode scanning
      bufferDuration: Duration(milliseconds: 3000),
      //Build #1.0.78: Removed orderHelper.addItemToOrder from the API success block, as it’s now in OrderBloc.updateOrderProducts.
      // Kept local addItemToOrder for non-API orders.
      // Ensured loader is shown during API calls and hidden afterward.
      onBarcodeScanned: (barcode) async {
        if (kDebugMode) {
          print("##### DEBUG: onBarcodeScanned - Scanned barcode: $barcode");
        }
        if (barcode.isNotEmpty) {
          if (kDebugMode) {
            print("##### DEBUG: onBarcodeScanned - Scanned barcode: $barcode");
          }

          // Create new order if none exists
          if (tabs.isEmpty) {
            addNewTab();
            if (kDebugMode) {
              print("##### DEBUG: onBarcodeScanned - No tabs, creating new order");
            }
          }
          setState(() => _isLoading = true); // Show loader
          productBloc.fetchProductBySku(barcode);
          _productBySkuSubscription?.cancel();
          _productBySkuSubscription = productBloc.productBySkuStream.listen((response) async {

            if (response.status == Status.COMPLETED && response.data!.isNotEmpty) {
              setState(() => _isLoading = false); //Build #1.0.92
              final product = response.data!.first;
              if (kDebugMode) {
                print("##### DEBUG: onBarcodeScanned - Product found: ${product.name}, variations: ${product.variations.length}");
              }
              // Build #1.0.80: MISSED CODE ADDED
              /// use product id:22, sku:woo-fashion-socks
              // var isVerified = await _ageRestrictedProduct(product);
              // Use the new provider to check for age restriction
              if(!mounted) {
                return;
              }
              final ageVerificationProvider = AgeVerificationProvider();
              var isVerified = await ageVerificationProvider.ageRestrictedProduct(context, product);

              /// Verify Age and proceed else return
              if(!isVerified){
                return;
              }
              ///Todo: Need to call variation service before adding product to the order
              if (product.variations.isNotEmpty) {
                ///1. Call _productBloc.fetchProductVariations(product.id!);
                ///2. load Variation popup
                ///3. On add button from variation popup -> add to order list
                VariationPopup(product.id, product.name, orderHelper, onProductSelected: ({required bool isVariant}) {
                  if (kDebugMode) {
                    print("VariationPopup returned with isVariant $isVariant");
                  }
                  Navigator.pop(context);
                  fetchOrderItems(); //onItemTapped(index, variantAdded: isVariant); //Build #1.0.78: Pass isVariant to onItemTapped
                },
                ).showVariantDialog(context: context);

                // Show variants dialog for products with variations
                if (kDebugMode) {
                  print("##### DEBUG: onBarcodeScanned - Showing variants dialog");
                }
              } else {

                ///Comment below code not we are using only server order id as to check orders, skip checking db order id
                // final order = orderHelper.orders.firstWhere(
                //       (order) => order[AppDBConst.orderId] == orderHelper.activeOrderId,
                //   orElse: () => {},
                // );
                final serverOrderId = orderHelper.activeOrderId;//order[AppDBConst.orderServerId] as int?;
                final dbOrderId = orderHelper.activeOrderId;
                if (product.id != null) { // Build #1.0.128
                  setState(() => _isLoading = true);
                  _updateOrderSubscription?.cancel();
                  _updateOrderSubscription = orderBloc.updateOrderStream.listen((response) async {
                    if (response.status == Status.LOADING) { // Build #1.0.80
                      const Center(child: CircularProgressIndicator()); // Added Loader
                    }else if (response.status == Status.COMPLETED) {
                      if (kDebugMode) {
                        print("##### DEBUG: onBarcodeScanned - Product added successfully");
                      }
                      await fetchOrderItems();
                      setState(() {
                        _isLoading = false;
                      });
                      _scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text("Product added successfully"),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else if (response.status == Status.ERROR) {
                      setState(() => _isLoading = false); //Build #1.0.99 : Hide loader
                      if (kDebugMode) {
                        print("##### ERROR: onBarcodeScanned - Failed to add product: ${response.message}");
                      }
                      _scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(response.message ?? "Failed to add product"),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                  await orderBloc.updateOrderProducts(
                    orderId: serverOrderId,
                    dbOrderId: dbOrderId,
                    lineItems: [
                      OrderLineItem(
                        productId: product.id,
                        quantity: 1,
                        // sku: product.sku ?? '',
                      ),
                    ],
                  );
                } else {
                  // Add product directly to order
                  if (kDebugMode) {
                    print("##### DEBUG: onBarcodeScanned - Not Adding product to DB directly: ${product.name}");
                  }
                  // await orderHelper.addItemToOrder(
                  //   product.id,
                  //   product.name,
                  //   product.images.isNotEmpty ? product.images.first.src : '',
                  //   double.parse(product.price.isNotEmpty ? product.price : '0.0'),
                  //   1,
                  //   product.sku ?? barcode,
                  //   type: ItemType.product.value,
                  //   onItemAdded: (){
                  //     if (kDebugMode) {
                  //       print("Item Added stop loading ");
                  //       _isLoading = false;
                  //       setState(() {
                  //
                  //       });
                  //     }
                  //   }
                  // );
                  await fetchOrderItems();
                  _scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("Product did not added to order. OrderId not found."),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  setState(() => _isLoading = false);
                }
              }
            } else {
              // Show error if product not found
              if (kDebugMode) {
                print("##### DEBUG: onBarcodeScanned - Product not found for SKU: $barcode");
              }
              if (!mounted) return;
              await CustomDialog.showCustomItemNotAdded(context).then((_) { //Build #1.0.54: added
                // Navigate to AddScreen when "Let's Try Again" is pressed
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddScreen(
                      barcode: barcode,
                      selectedTabIndex: 2, // Custom items tab
                    ),
                  ),
                );
              });
              setState(() => _isLoading = false);
            }
          });
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.30,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.only(top: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Container(
                color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground: null,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollController,
                        child: Row(
                          children: List.generate(tabs.length, (index) {
                            final bool isSelected = _tabController!.index == index;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tabController!.index = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ?  ThemeNotifier.orderPanelTabSelection : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.orderPanelTabBackground : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tabs[index]["title"] as String,
                                            style: TextStyle(color: isSelected ? Colors.black : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            tabs[index]["subtitle"] as String,
                                            style: TextStyle(color: isSelected ? Colors.black54 : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.black54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 40),
                                      // Always show the close button
                                      GestureDetector(
                                        ///ToDo: Change the status of order to 'cancelled' here
                                        onTap: () {
                                          if (kDebugMode) {
                                            print("Tab $index, close button tapped");
                                          }
                                          ///call alert  box before delete
                                          CustomDialog.showAreYouSure(context,
                                              confirm: () {
                                                removeTab(index);
                                              });
                                        },
                                        child: const Icon(Icons.close, size: 18, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: addNewTab,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.orderPanelAddButton : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        elevation: 2, // Controls the size and blur of the shadow
                        shadowColor: ThemeNotifier.shadow_F7,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        minimumSize: const Size(50, 56),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("+", style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                          Text(TextConstants.newText,style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: buildCurrentOrder()),
            ],
          ),
        ),
      ),
    );
  }

//   Future<bool> _ageRestrictedProduct(SKU.ProductBySkuResponse product) async {
//     ///@
// //
// // ANSI 636026100102DL00410277ZA03180012DLDAQD05848559 DCSBELE SHRAVAN DDEN DACKUMAR DDFNvDADNONEaDDGNrDCAD DCBNONEtDCDNONEaDBD02052025gDBB07181978gDBA09032030 DBC1=DAU070 in DAYBROpDAG233 W FELLARS DRrDAIPHOENIXoDAJAZdDAK850237501  uDCF003402EB0B124005cDCGUSAtDCK48102972534.DDAFtDDB02282023aDDD1gDAZBLKsDAW196?DDK1
// //     ZAZAAN.ZACN
//
//     var isVerified = false;
//     var tagg = product.tags?.firstWhere((element) => element.name == "Age Restricted", orElse: () => SKU.Tags());
//     var hasAgeRestriction = tagg?.name?.contains("Age Restricted");
//
//     if (kDebugMode) {
//       print("Order Panel _ageRestrictedProduct hasAgeRestriction = $hasAgeRestriction");
//     }
//
//     if (hasAgeRestriction ?? false) {
//       var tag = product.tags?.firstWhere((element) => element.name == "Age Restricted", orElse: () => SKU.Tags());
//       if (kDebugMode) {
//         print("Order Panel _ageRestrictedProduct hasAgeRestriction tag = ${tag?.id}, ${tag?.name}, ${tag?.slug}");
//       }
//       if (tag?.slug == "") {
//         return isVerified;
//       }
//       await AgeVerificationHelper.showAgeVerification(
//         context: context,
//         // productName: product.name,
//         minimumAge: int.parse(tag?.slug ?? "0"),
//         onManualVerify: () {
//           // Add product to cart - manually verified
//           // _addToCart(product);
//           isVerified = true;
//         },
//         onAgeVerified: () {
//           // Add product to cart - age verified
//           // _addToCart(product);
//           isVerified = true;
//         },
//         onCancel: () {
//           // User cancelled - don't add to cart
//           isVerified = false;
//           Navigator.pop(context);
//         },
//       );
//     } else {
//       // No age restriction - add directly
//       // _addToCart(product);
//       isVerified = true;
//     }
//     return isVerified;
//   }

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
    if (response.status == Status.COMPLETED) {
      setState(() => _isLoading = false); //Build #1.0.92
      _scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("${isPayout ? 'Payout' : isCoupon ? 'Coupon' : isCustomItem ? 'Custom Item' : 'Item'} removed successfully"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      await orderHelper.deleteItem(orderItem[AppDBConst.itemServerId]);
      await fetchOrderItems();
      widget.refreshOrderList?.call();
    } else if (response.status == Status.ERROR) {
      setState(() => _isLoading = false); //Build #1.0.99 : hide loader
      _scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Failed to remove ${isPayout ? 'payout' : isCoupon ? 'coupon' : isCustomItem ? 'custom item' : 'item'}"),
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

  //Build #1.0.67
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
    //Build #1.0.99: Dismiss any open dialog
    Navigator.of(context, rootNavigator: true).pop();
  }

  //Build #1.0.67
  Future<void> _handleLocalDelete(Map<String, dynamic> orderItem, BuildContext context) async {
    if (!mounted) return; // Check if widget is still mounted
    setState(() => _isLoading = false);
    await orderHelper.deleteItem(orderItem[AppDBConst.itemServerId]); //Build #1.0.92
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

// Current Order UI
  Widget buildCurrentOrder() {
    final theme = Theme.of(context); // Build #1.0.6 - added theme for order panel
    bool isKeyboardVisible = View.of(context).viewInsets.bottom > 0;
    if (kDebugMode) {
      print("keyBoard visible : $isKeyboardVisible");
    }
    if(_isLoading == true){
      if (kDebugMode) {
        print("###### buildCurrentOrder: _isLoading: $_isLoading");
      }
    }
    final themeHelper = Provider.of<ThemeNotifier>(context);
    // ADD THIS: Create a ScrollController for the scrollbar
    final ScrollController scrollController = ScrollController();
    if (kDebugMode) {
      print("Building Current Order Widget _isLoading: $_isLoading and orderHelper.activeOrderId : ${orderHelper.activeOrderId}");
    } // Debug print
    // Fetch discount and tax for the active order
    double orderDiscount = 0.0;
    double merchantDiscount = 0.0;
    double orderTax = 0.0;
    num grossTotal = GlobalUtility.getGrossTotal(orderItems);  // Get Items Gross Total
    num netTotal = 0.0;
    num netPayable = 0.0;  //Build #1.0.67

    // Update the calculation section in buildCurrentOrder:
    if (orderHelper.activeOrderId != null) {

      // var orders = await orderHelper.getOrderById(orderHelper.activeOrderId!);
      // var order = orders.first;
      final order = orderHelper.orders.firstWhere(
            (order) => order[AppDBConst.orderServerId] == orderHelper.activeOrderId,
        orElse: () => {},
      );

      // Get values from order or default to 0
      orderDiscount = order[AppDBConst.orderDiscount] as double? ?? 0.0;
      merchantDiscount = order[AppDBConst.merchantDiscount] as double? ?? 0.0;
      orderTax = order[AppDBConst.orderTax] as double? ?? 0.0;

      // Build #1.0.138: Calculate net total
      netTotal = grossTotal - orderDiscount; // Build #1.0.137

      //Build #1.0.146: Apply merchant discount (this is typically a separate discount)
      netTotal = netTotal - merchantDiscount;

      ///map total with netPayable
      netPayable =  order[AppDBConst.orderTotal] as double? ?? 0.0;

      // Ensure netPayable is not negative
      // Build #1.0.138: Ensure no negative values
      netTotal = netTotal < 0 ? 0.0 : netTotal;
      netPayable = netPayable < 0 ? 0.0 : netPayable;
      if (kDebugMode) {
        print("#### netPayable: $netPayable, orderTotal: ${order[AppDBConst.orderTotal] as double? ?? 0.0}");
      }
    }

    if (kDebugMode) {  //Build #1.0.67
      print("#### ACTIVE ORDER ID: ${orderHelper.activeOrderId}");
      print("#### orderItems: $orderItems");
      print("#### grossTotal: $grossTotal");
      print("#### orderDiscount: $orderDiscount");
      print("#### merchantDiscount: $merchantDiscount");
      print("#### orderTax: $orderTax");
      print("#### netTotal: $netTotal");
      print("#### netPayable: $netPayable");
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
                  if (orderHelper.activeOrderId != null)
                  Row(
                    spacing: 4,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                            'assets/svg/calendar.svg', width: 22, height: 22),
                        Text(widget.formattedDate,
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.secondaryHeaderColor)),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                            'assets/svg/clock.svg', width: 22, height: 22),
                        Text(widget.formattedTime, style: TextStyle(
                            fontSize: 14, color: theme.secondaryHeaderColor)),

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
                  padding: const EdgeInsets.only(left:3, right: 3),
                  child: Scrollbar(
                    controller: scrollController,
                    scrollbarOrientation: ScrollbarOrientation.right,
                    thumbVisibility: true,
                    thickness: 8.0,
                    interactive: false,
                    radius: const Radius.circular(8),
                    trackVisibility: true,
                    child: ReorderableListView.builder(
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
                      scrollController: scrollController,
                      itemCount: orderItems.length,
                      proxyDecorator: (Widget child, int index, Animation<double> animation) {
                        return Material(
                          color: Colors.transparent,// Removes white background
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
                        if (kDebugMode) {
                          print("#### originalName: $originalName, itemType: $itemType, isPayoutOrCouponOrCustomItem: $isPayoutOrCouponOrCustomItem");
                          print("#### variationName: $variationName, variationCount: $variationCount");
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

                        return ClipRRect(
                        // Build #1.0.151: FIXED - change ensures that sliding an item in one order does not affect the Slidable state of items at the same index in other orders.
                        key: ValueKey('${orderHelper.activeOrderId}_$index'), // Updated key to include order ID
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.12,
                            child: Slidable(
                              // Build #1.0.151: FIXED - change ensures that sliding an item in one order does not affect the Slidable state of items at the same index in other orders.
                              key: ValueKey('${orderHelper.activeOrderId}_$index'), // Updated key to include order ID
                              closeOnScroll: true,
                              direction: Axis.horizontal,
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                children: [
                                  CustomSlidableAction(
                                    onPressed: (context) async {
                                      if (isPayoutOrCouponOrCustomItem) {
                                        if (kDebugMode) {
                                          print("#### CustomSlidableAction isPayoutOrCouponOrCustomItem true");
                                        }
                                        await CustomDialog.showRemoveSpecialOrderItemsConfirmation(context, type: itemType, confirm: () async {
                                          deleteItemFromOrder(orderItem[AppDBConst.itemServerId]);
                                        });
                                      } else {
                                        deleteItemFromOrder(orderItem[AppDBConst.itemServerId]);
                                      }
                                    },
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
                                //Removed orderHelper.updateItemQuantity from the API success block, as it’s now in OrderBloc.updateOrderProducts.
                                // Kept local updateItemQuantity for non-API orders.
                                // Ensured loader is shown during API calls.
                                onTap: () {
                                  if (isPayoutOrCouponOrCustomItem) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProductScreen(
                                        orderItem: orderItem,
                                        onQuantityUpdated: (newQuantity) async {
                                          if (orderHelper.activeOrderId != null) {
                                            // final order = orderHelper.orders.firstWhere(
                                            //       (order) => order[AppDBConst.orderServerId] == orderHelper.activeOrderId,
                                            //   orElse: () => {},
                                            // );
                                            final serverOrderId = orderHelper.activeOrderId;//order[AppDBConst.orderServerId] as int?;
                                            final dbOrderId = orderHelper.activeOrderId;
                                            // Build #1.0.108: Fixed : Edit product not working
                                            // prev we are passing itemServerId rather than itemProductId & based on variation id we have to pass that id
                                            final productId = orderItem[AppDBConst.itemProductId] as int?;
                                            final serverVariationId = orderItem[AppDBConst.itemVariationId] as int?;
                                            // Use productId if serverVariationId is null or 0, otherwise use serverVariationId
                                            final variationOrProductId = (serverVariationId == null || serverVariationId == 0)
                                                ? productId
                                                : serverVariationId;
                                            if (serverOrderId != null && dbOrderId != null && productId != null) {
                                              setState(() => _isLoading = true);
                                              _updateOrderSubscription?.cancel();
                                              _updateOrderSubscription = orderBloc.updateOrderStream.listen((response) async {
                                                if (response.status == Status.LOADING) { // Build #1.0.80
                                                  const Center(child: CircularProgressIndicator());
                                                }else if (response.status == Status.COMPLETED) {
                                                  if (kDebugMode) {
                                                    print("##### DEBUG: EditProductScreen - Quantity updated successfully");
                                                  }
                                                  setState(() => _isLoading = false); //Build #1.0.92, Fixed Issue: Loader in order panel does not stop on edit item

                                                  await fetchOrderItems();
                                                  _scaffoldMessenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text("Quantity updated successfully"),
                                                      backgroundColor: Colors.green,
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                } else if (response.status == Status.ERROR) {
                                                  if (kDebugMode) {
                                                    print("##### ERROR: EditProductScreen - Failed to update quantity: ${response.message}");
                                                  }
                                                  _scaffoldMessenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text("Failed to update quantity"),
                                                      backgroundColor: Colors.red,
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                  setState(() => _isLoading = false); //Build #1.0.92: Fixed Issue: Loader in order panel does not stop on edit item
                                                }
                                              });

                                              if (kDebugMode) { // Build #1.0.108:
                                                print("##### DEBUG: 4321 , variationOrProductId: $variationOrProductId, productId: $productId, serverVariationId: $serverVariationId");
                                              }

                                              await orderBloc.updateOrderProducts(
                                                orderId: serverOrderId,
                                                dbOrderId: dbOrderId,
                                                isEditQuantity: true,
                                                lineItems: [
                                                  OrderLineItem(
                                                    productId: variationOrProductId, // Build #1.0.108: we have to pass itemProductId or itemVariationId, otherwise it won't update qty.
                                                    quantity: newQuantity,
                                                    // sku: orderItem[AppDBConst.itemSKU] ?? '',
                                                  ),
                                                ],
                                              );
                                            } else {

                                              ///Todo: do not handle this code, remove if required as we are not saving until API call made with response
                                              // await orderHelper.updateItemQuantity(
                                              //   orderItem[AppDBConst.itemId],
                                              //   newQuantity,
                                              // );
                                              await fetchOrderItems();
                                              _scaffoldMessenger.showSnackBar(
                                                SnackBar(
                                                  content: Text("Failed to update quantity, Network error."),
                                                  backgroundColor: Colors.green,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                              setState(() => _isLoading = false);
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
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
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: orderItem[AppDBConst.itemImage].toString().startsWith('http')
                                            ? SizedBox(
                                                height: MediaQuery.of(context).size.height * 0.08,
                                                width: MediaQuery.of(context).size.height * 0.075,
                                                child: Image.network(
                                                  orderItem[AppDBConst.itemImage],
                                                  height: MediaQuery.of(context).size.height * 0.08,
                                                  width: MediaQuery.of(context).size.height * 0.075,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return SvgPicture.asset(
                                                      'assets/svg/password_placeholder.svg',
                                                      height: MediaQuery.of(context).size.height * 0.08,
                                                      width: MediaQuery.of(context).size.height * 0.08,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                ),
                                              )
                                            : orderItem[AppDBConst.itemImage].toString().startsWith('assets/')
                                            ? SvgPicture.asset(
                                          orderItem[AppDBConst.itemImage],
                                          height: MediaQuery.of(context).size.height * 0.08,
                                          width: MediaQuery.of(context).size.height * 0.075,
                                          fit: BoxFit.cover,
                                        )
                                                : Platform.isWindows
                                                    ? Image.asset(
                                                        'assets/default.png',
                                                        height: MediaQuery.of(context).size.height * 0.08,
                                                        width: MediaQuery.of(context).size.height * 0.075,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        File(orderItem[AppDBConst.itemImage]),
                                          height: MediaQuery.of(context).size.height * 0.08,
                                          width: MediaQuery.of(context).size.height * 0.075,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return SvgPicture.asset(
                                              'assets/svg/password_placeholder.svg',
                                              height: MediaQuery.of(context).size.height * 0.08,
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
                                            /// TODO: Change here to apply meta values for (mix & match) "combo" and "variation"
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
                                                        text:///Todo: use combo here
                                                        combo == '' ? '' : " (Combo)",
                                                        style: TextStyle(fontSize: 8, color: Colors.cyan),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                variationCount == 0 ? SizedBox(width: 0,) : Row(
                                                  children: [
                                                    Text(
                                                      ///Todo: use variation name here
                                                      variationName == '' ? "" : "(${variationName ?? ''})",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 10, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.grey),
                                                    ),
                                                    SizedBox(
                                                      width: 4,
                                                    ),
                                                    ///Todo: show variation icon if variation count is no zero
                                                    SvgPicture.asset("assets/svg/variation.svg",height: 10, width: 10,),
                                                    SizedBox(
                                                      width: 4,
                                                    ),
                                                    Text(///Todo: show variation count if no zero
                                                      "${variationCount ?? 0}",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 10, color: Color(0xFFFE6464)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            if (!isPayoutOrCouponOrCustomItem)
                                              Text(
                                                "${TextConstants.currencySymbol} ${regularPrice.toStringAsFixed(2)} * ${orderItem[AppDBConst.itemCount]} ", //Build #1.0.134: updated price * count
                                                style: TextStyle(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!isCouponOrPayout)
                                        Text(
                                          "${TextConstants.currencySymbol} ${(regularPrice * orderItem[AppDBConst.itemCount]).toStringAsFixed(2)}",
                                          style: TextStyle(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.blueGrey, fontSize: 14),
                                        ),
                                      SizedBox(width: 20,),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isCouponOrPayout
                                                ? "${TextConstants.currencySymbol}${(orderItem[AppDBConst.itemCount] * orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}"
                                                : "${TextConstants.currencySymbol}${(orderItem[AppDBConst.itemCount] * salesPrice).toStringAsFixed(2)}",
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
                  if (tabs.isNotEmpty)
                    AnimatedSize(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: (!isKeyboardVisible && _showFullSummary)
                          ? Container(
                        margin: const EdgeInsets.only(top: 8, right: 8, left: 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(topRight: Radius.circular(8), topLeft: Radius.circular(8)),
                            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.orderPanelSummary : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: ThemeNotifier.shadow_F7,
                                blurRadius: 2,
                                // spreadRadius: LayoutValues.radius_5,
                                offset: Offset(LayoutValues.zero,LayoutValues.zero),
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
                                Text(TextConstants.grossTotal, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight), ),
                                Text("${TextConstants.currencySymbol}${grossTotal.toStringAsFixed(2)}", //Build #1.0.68
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight)),
                              ],
                            ),
                            SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  spacing: 5,
                                  children: [
                                    SvgPicture.asset("assets/svg/discount_star.svg", height: 12, width: 12),
                                    Text(TextConstants.discountText, style: TextStyle(color: Colors.green, fontSize: 10)),
                                  ],
                                ),
                                Text("-${TextConstants.currencySymbol}${orderDiscount.toStringAsFixed(2)}",
                                    style: TextStyle(color: Colors.green, fontSize: 10)),
                              ],
                            ),
                            SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  spacing: 5,
                                  children: [
                                    SvgPicture.asset("assets/svg/discount_star.svg", height: 12, width: 12),
                                    Text(TextConstants.merchantDiscount, style: TextStyle(color: Colors.blue, fontSize: 10)),
                                    merchantDiscount.toStringAsFixed(2) == '0.00' ? SizedBox() : GestureDetector(
                                      onTap: () async {
                                        //Passed dbOrderId to removeFeeLines.
                                        // Removed database operations, as they’re now in OrderBloc.removeFeeLines.
                                        // Ensured loader is shown during API calls.
                                        if (kDebugMode) {
                                          print("####################### Merchant Discount onTap");
                                        }
                                        if (orderHelper.activeOrderId != null) {
                                          // Step 1: Show confirmation dialog
                                          await CustomDialog.showRemoveSpecialOrderItemsConfirmation(context, confirm: () async {
                                            // Step 2: Show loader
                                            setState(() => _isLoading = true);
                                            // final order = orderHelper.orders.firstWhere(
                                            //       (order) => order[AppDBConst.orderServerId] == orderHelper.activeOrderId,
                                            //   orElse: () => {},
                                            // );
                                            final serverOrderId = orderHelper.activeOrderId;//order[AppDBConst.orderServerId] as int?;
                                            final dbOrderId = orderHelper.activeOrderId!;

                                            if (serverOrderId != null) {
                                              final db = await DBHelper.instance.database;
                                              ///TODO : Update below table code for new discount id code
                                              final merchantDiscountValue = await db.query(
                                                AppDBConst.orderTable,
                                                where: '${AppDBConst.orderServerId} = ? AND ${AppDBConst.merchantDiscount} = ?',
                                                whereArgs: [dbOrderId, merchantDiscount],
                                              );

                                              if (merchantDiscountValue.isNotEmpty) {
                                                final payoutIds = merchantDiscountValue.first[AppDBConst.merchantDiscountIds].toString().split(',') ?? [];
                                                //remove the empty id
                                                payoutIds.removeAt(0);
                                                if (kDebugMode) {
                                                  print("OrderPanel - payouts to delete $payoutIds");
                                                }
                                                if (payoutIds.isNotEmpty) {
                                                  //Build #1.0.99: Cancel any existing subscription to prevent multiple listeners
                                                  _removePayoutOrDiscountSubscription?.cancel();
                                                  retryCallback() async {
                                                    setState(() => _isLoading = true);
                                                    await orderBloc.removeFeeLines(orderId: serverOrderId, feeLineIds: payoutIds);
                                                    // Dismiss dialog after retry
                                                    Navigator.of(context, rootNavigator: true).pop();
                                                  };
                                                    _removePayoutOrDiscountSubscription =
                                                        orderBloc.removePayoutStream.listen((response) async {
                                                          if (response.status == Status.COMPLETED) {
                                                            setState(() => _isLoading = false); //Build #1.0.92
                                                            await fetchOrderItems();
                                                            widget.refreshOrderList?.call();
                                                            _scaffoldMessenger.showSnackBar(
                                                              SnackBar(content: Text("Merchant Discount removed successfully"),
                                                                backgroundColor: Colors.green,
                                                                duration: const Duration(seconds: 2),
                                                              ),
                                                            );
                                                          } else if (response.status == Status.ERROR) {
                                                            if (kDebugMode) {
                                                              print("###### Delete Discount API error");
                                                            }
                                                            setState(() => _isLoading = false);
                                                            _scaffoldMessenger.showSnackBar(
                                                              SnackBar(
                                                                content: Text("Failed to remove discount"),
                                                                backgroundColor: Colors.red,
                                                                duration: const Duration(seconds: 2),
                                                              ),
                                                            );
                                                            await CustomDialog.showDiscountNotApplied(context,
                                                              errorMessageTitle: TextConstants.removeDiscountFailed,
                                                              errorMessageDes: response.message ?? TextConstants.discountNotAppliedDescription,
                                                              onRetry: retryCallback,
                                                            );
                                                          }
                                                        });
                                                    await orderBloc.removeFeeLines(orderId: serverOrderId,feeLineIds: payoutIds);
                                                } else {
                                                  setState(() => _isLoading = false);
                                                  _scaffoldMessenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text("Payout ID not found"),
                                                      backgroundColor: Colors.red,
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              } else {
                                                setState(() => _isLoading = false);
                                                _scaffoldMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text("No payout found for this order"),
                                                    backgroundColor: Colors.red,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } else {
                                              setState(() => _isLoading = false);
                                              _scaffoldMessenger.showSnackBar(
                                                SnackBar(
                                                  content: Text("Server Order ID not found"),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          });
                                        }
                                      },
                                      child: SvgPicture.asset("assets/svg/delete.svg", height: 20, width: 20),
                                    ),
                                  ],
                                ),
                                Text("-${TextConstants.currencySymbol}${merchantDiscount.toStringAsFixed(2)}",
                                    style: TextStyle(color: Colors.blue, fontSize: 10)),
                              ],
                            ),
                            SizedBox(height: 2),
                            const DottedLine(),
                            SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(TextConstants.netTotalText,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight),),
                                Text("${TextConstants.currencySymbol}${netTotal.toStringAsFixed(2)}",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight)),
                              ],
                            ),
                            SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(TextConstants.taxText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10,color: themeHelper.themeMode == ThemeMode.dark ? Colors.white54 : Colors.grey),),
                                Text("${TextConstants.currencySymbol}${orderTax.toStringAsFixed(2)}", //Build #1.0.92: removed minus "-"
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: themeHelper.themeMode == ThemeMode.dark ? Colors.white54 :Colors.grey)),
                              ],
                            ),
                            SizedBox(height: 2),
                            const DottedLine(),
                            SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(TextConstants.netPayable, style: TextStyle(fontWeight: FontWeight.bold, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight)),
                                Text("${TextConstants.currencySymbol}${netPayable.toStringAsFixed(2)}",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight)),
                              ],
                            ),
                          ],
                        ),
                      )
                          : SizedBox.shrink(),
                    ),
                  if (tabs.isNotEmpty)
                    GestureDetector(
                      onTap: isKeyboardVisible ? null : _toggleSummary,
                      child: Container(
                        margin: const EdgeInsets.only(top: 2, right: 8, left: 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(bottomRight: Radius.circular(8), bottomLeft: Radius.circular(8)),
                            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.orderPanelSummary : Colors.grey.shade300
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${TextConstants.totalItemsText}: ${orderItems.length}",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Text(
                                    _showFullSummary
                                        ? 'Net Payable : ${TextConstants.currencySymbol}${netPayable.toStringAsFixed(2)}'
                                        : 'Net Payable : ${TextConstants.currencySymbol}${netPayable.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Icon(_showFullSummary ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Payment button - outside the container
                  if (tabs.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.0575,
                      child: ElevatedButton( //Build 1.1.36: on pay tap calling updateOrderProducts api call
                        onPressed: netPayable >= 0 && orderItems.isNotEmpty
                            ? () async {
                          setState(() => _isPayBtnLoading = true);
                          // await Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => OrderSummaryScreen()),
                          // );
                          // On the first screen (Screen 1)
                          // Build #1.0.104: Navigate to OrderSummaryScreen and listen for result
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OrderSummaryScreen(formattedDate: '',formattedTime: '',)),
                          );
                          if (kDebugMode) {
                            print("###### FastKeyScreen: Returned from OrderSummaryScreen with result: $result");
                          }
                          // Handle refresh if result is 'refresh'
                          if (result == 'refresh') {
                            if (kDebugMode) {
                              print("###### FastKeyScreen: Refresh signal received, reinitializing entire screen");
                            }
                            setState(() {
                              fetchOrdersData(); // call
                            });
                          }
                          setState(() => _isPayBtnLoading = false);
    ///No need to update here now, may cause empty items added to order
    //                       if (orderHelper.activeOrderId != null) {
    //                         setState(() => _isPayBtnLoading = true);
    //                         // final order = orderHelper.orders.firstWhere(
    //                         //       (order) => order[AppDBConst.orderServerId] == orderHelper.activeOrderId,
    //                         //   orElse: () => {},
    //                         // );
    //                         final serverOrderId = orderHelper.activeOrderId;//order[AppDBConst.orderServerId] as int?;
    //                         final dbOrderId = orderHelper.activeOrderId!;
    //
    //                         if (serverOrderId == null) {
    //                           setState(() => _isPayBtnLoading = false);
    //                           ScaffoldMessenger.of(context).showSnackBar(
    //                             SnackBar(content: Text("Server Order ID not found")),
    //                           );
    //                           return;
    //                         }
    //
    //                         // Assign the subscription to your class variable
    //                         _updateOrderSubscription = orderBloc.updateOrderStream.listen((response) async {
    //                           if (!mounted) return;
    //                           if (response.status == Status.COMPLETED) {
    //                             setState(() => _isPayBtnLoading = false);
    //                             if (kDebugMode) {
    //                               print("###### updateOrder COMPLETED");
    //                             }
    //                             Navigator.push(
    //                               context,
    //                               MaterialPageRoute(builder: (context) => OrderSummaryScreen()),
    //                             );
    //                           } else if (response.status == Status.ERROR) {
    //                             ScaffoldMessenger.of(context).showSnackBar(
    //                               SnackBar(content: Text(response.message ?? "Failed to update order")),
    //                             );
    //                           }
    //                         });
    //                         // Prepare line items for API
    //                         List<OrderLineItem> lineItems = orderItems.map((item) => OrderLineItem(
    //                           productId: item[AppDBConst.itemServerId],
    //                           quantity: item[AppDBConst.itemCount],
    //                           //  sku: item[AppDBConst.itemSKU] ?? '',
    //                         )).toList();
    //
    //                         await orderBloc.updateOrderProducts(
    //                           dbOrderId: dbOrderId,
    //                           orderId: serverOrderId,
    //                           lineItems: lineItems,
    //                         );
    //                       }
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: netPayable >= 0 && orderItems.isNotEmpty ? const Color(0xFFFF6B6B) : Colors.grey,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isPayBtnLoading  //Build 1.1.36: added loader for pay button in order panel
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          "Pay ${TextConstants.currencySymbol}${netPayable.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 6.0,
              ),
            ),
          ),
      ],
    );
  }
/// //Build #1.0.2 : Added showNumPadDialog if user tap on order layout list item

// New method to show product edit screen (replace the existing showNumPadDialog)
// void showProductEditScreen(BuildContext context, Map<String, dynamic> orderItem) {
//   showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//     return ProductEditScreen(
//       orderItem: orderItem,
//       onQuantityUpdated: (newQuantity) {
//         setState(() {
//           orderItem[AppDBConst.itemCount] = newQuantity;
//         });
//         // Here you would update the database if needed
//         // For now we're just updating the UI state
//         fetchOrderItems();
//       },
//     );
//   }
//   );
// }
// void showNumPadDialog(BuildContext context, String itemName, Function(int) onQuantitySelected) {
//   TextEditingController controller = TextEditingController();
//   int quantity = 0;
//
//   showDialog(
//     context: context,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           void updateQuantity(int newQuantity) {
//             setState(() {
//               quantity = newQuantity;
//               controller.text = quantity == 0 ? "" : quantity.toString();
//             });
//           }
//
//           return Dialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 100),
//             child: Container(
//               width: 600,
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Title
//                   Text(TextConstants.enterQuanText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
//                   Text(itemName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   SizedBox(height: 12),
//
//                   // TextField with + and - buttons
//                   Container(
//                     width: 500,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.grey.shade400, width: 1.5),
//                       color: Colors.grey.shade100,
//                     ),
//                     padding: EdgeInsets.symmetric(horizontal: 20), // Match NumPad padding
//                     child: Row(
//                       children: [
//                         // Decrement Button
//                         IconButton(
//                           icon: Icon(Icons.remove_circle, size: 32, color: Colors.redAccent),
//                           onPressed: () {
//                             if (quantity > 0) updateQuantity(quantity - 1);
//                           },
//                         ),
//
//                         // Quantity TextField
//                         Expanded(
//                           child: TextField(
//                             controller: controller,
//                             textAlign: TextAlign.center,
//                             readOnly: true,
//                             style: TextStyle(
//                               fontSize: 28,
//                               fontWeight: controller.text.isEmpty ? FontWeight.normal : FontWeight.bold,
//                               color: controller.text.isEmpty ? Colors.grey : Colors.black87, // Fix: Color updates correctly
//                             ),
//                             decoration: InputDecoration(
//                               border: InputBorder.none,
//                               hintText: "00", // Fix: Shows properly when empty
//                               hintStyle: TextStyle(fontSize: 28, color: Colors.grey),
//                               contentPadding: EdgeInsets.symmetric(vertical: 12), // Fix: Consistent padding
//                             ),
//                           ),
//                         ),
//
//                         // Increment Button
//                         IconButton(
//                           icon: Icon(Icons.add_circle, size: 32, color: Colors.green),
//                           onPressed: () {
//                             updateQuantity(quantity + 1);
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 16),
//
//                   // CustomNumPad with OK button
//                   CustomNumPad(
//                     onDigitPressed: (digit) {
//                       setState(() {
//                         int newQty = int.tryParse((controller.text.isEmpty ? "0" : controller.text) + digit) ?? quantity;
//                         updateQuantity(newQty);
//                       });
//                     },
//                     onClearPressed: () => updateQuantity(0),
//                     onConfirmPressed: () {
//                       onQuantitySelected(quantity);
//                       Navigator.pop(context);
//                     },
//                     actionButtonType: ActionButtonType.ok, // OK instead of Delete
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }
// void showProductEditScreen(BuildContext context, Map<String, dynamic> orderItem) {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext dialogContext) {
//       return ProductEditScreen(
//         orderItem: orderItem,
//         onQuantityUpdated: (newQuantity) async {
//           // Update the item in the database first
//           // if (orderHelper.activeOrderId != null) {
//           //   await orderHelper.updateItemQuantity(
//           //       orderItem[AppDBConst.itemId],
//           //       newQuantity
//           //   );
//           // }
//
//           // Then update the UI state
//           setState(() {
//             orderItem[AppDBConst.itemCount] = newQuantity;
//             // Also update the sum price to maintain consistency
//             orderItem[AppDBConst.itemSumPrice] =
//                 orderItem[AppDBConst.itemPrice] * newQuantity;
//           });
//
//           // Refresh the order items
//           fetchOrderItems();
//         },
//       );
//     },
//   );
// }
}