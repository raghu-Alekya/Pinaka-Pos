import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Screens/Home/order_summary_screen.dart';
import 'package:pinaka_pos/Widgets/widget_alert_popup_dialogs.dart';
import 'package:pinaka_pos/Widgets/widget_custom_num_pad.dart';
import 'package:pinaka_pos/Widgets/widget_nested_grid_layout.dart';
import 'package:pinaka_pos/Widgets/widget_tabs.dart';
import 'package:pinaka_pos/Widgets/widget_variants_dialog.dart';

import '../Blocs/Orders/order_bloc.dart';
import '../Blocs/Search/product_search_bloc.dart';
import '../Constants/text.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
import '../Helper/api_response.dart';
import '../Models/Orders/orders_model.dart';
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
  late OrderBloc orderBloc;
  StreamSubscription? _updateOrderSubscription;
  StreamSubscription? _fetchOrdersSubscription;
  final ProductBloc productBloc = ProductBloc(ProductRepository()); // Build #1.0.44 : Added for barcode scanning
  StreamSubscription? _productBySkuSubscription; // Build #1.0.44 : Added for product stream

  @override
  void initState() {
    if (kDebugMode) {
      print("##### OrderPanel initState");
    }
    orderBloc = OrderBloc(OrderRepository());
    super.initState();
    _getOrderTabs(); //Build #1.0.40: Load existing orders into tabs
    _fetchOrders(); //Build #1.0.40: Fetch orders on initialization
  }

  @override
  void didUpdateWidget(RightOrderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (mounted) {
      _getOrderTabs(); // Build #1.0.10 : Reload tabs when the widget updates (e.g., after item selection)
    }

    if (kDebugMode) {
      print("##### OrderPanel didUpdateWidget");
    }
  }

  // Build #1.0.10: Fetches the list of order tabs from OrderHelper
  void _getOrderTabs() async {
    if (kDebugMode) {
      print("##### DEBUG: _getOrderTabs - Loading order tabs");
    }
    await orderHelper.loadData(); // Load order data from DB

    if (mounted) {
      setState(() {
        // Convert order IDs into tab format
        tabs = orderHelper.orders
            .asMap()
            .entries
            .map((entry) => {
          "title": "#${entry.value[AppDBConst.orderServerId] ?? entry.value[AppDBConst.orderId]}",
          "subtitle": "Tab ${entry.key + 1}",
          "orderId": entry.value[AppDBConst.orderId] as Object, // Use db orderId, not serverId
        }).toList();
        if (kDebugMode) {
          print("##### DEBUG: _getOrderTabs - Loaded ${tabs.length} tabs: $tabs");
        }
      });
    }

    if (!mounted) return; // Prevent controller initialization if unmounted
    _initializeTabController(); // Initialize tab controller

    if (tabs.isNotEmpty) {
      int index = 0;
      if (orderHelper.activeOrderId != null) {
        index = orderHelper.orderIds.indexOf(orderHelper.activeOrderId!);
        if (index == -1) {
          if (kDebugMode) {
            print("##### DEBUG: _getOrderTabs - Active order ID ${orderHelper.activeOrderId} not found, defaulting to last tab");
          }
          index = tabs.length - 1;
          await orderHelper.setActiveOrder(tabs[index]["orderId"] as int);
        }
      } else {
        if (kDebugMode) {
          print("##### DEBUG: _getOrderTabs - No active order, setting to last tab");
        }
        index = tabs.length - 1;
        await orderHelper.setActiveOrder(tabs[index]["orderId"] as int);
      }
      if (mounted && _tabController != null) {
        _tabController?.index = index;
        if (kDebugMode) {
          print("##### DEBUG: _getOrderTabs - Set tab index to $index, activeOrderId: ${orderHelper.activeOrderId}");
        }
      }
      await fetchOrderItems(); // Load items for active order
    } else {
      if (kDebugMode) {
        print("##### DEBUG: _getOrderTabs - No tabs available");
      }
      if (mounted) {
        setState(() {
          orderItems.clear(); // Clear items if no tabs
        });
      }
    }
  }

  void _fetchOrders() { //Build #1.0.40: fetch orders items from API sync & updating to UI
    _fetchOrdersSubscription = orderBloc.fetchOrdersStream.listen((response) async {
      if (!mounted) return;

      if (response.status == Status.COMPLETED) {
        if (kDebugMode) {
          print("##### DEBUG: Fetched orders successfully");
        }

        await orderHelper.syncOrdersFromApi(response.data!.orders);
        _getOrderTabs();
      } else if (response.status == Status.ERROR) {
        if (kDebugMode) {
          print("##### ERROR: Fetch orders failed - ${response.message}");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? "Failed to fetch orders")),
        );
      }
    });

    orderBloc.fetchOrders();
  }

  // Build #1.0.10: Fetches order items for the active order
  Future<void> fetchOrderItems() async {
    if (orderHelper.activeOrderId != null) {
      if (kDebugMode) {
        print("##### DEBUG: fetchOrderItems - Fetching items for activeOrderId: ${orderHelper.activeOrderId}");
      }
      try {
        List<Map<String, dynamic>> items = await orderHelper.getOrderItems(orderHelper.activeOrderId!);

        if (kDebugMode) {
          print("##### DEBUG: fetchOrderItems - Retrieved ${items.length} items: $items");
        }

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
  }

  // Build #1.0.10: Initializes the tab controller and handles tab switching
  void _initializeTabController() {
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
        await fetchOrderItems(); // Load items for the selected order
        if (mounted) {
          setState(() {}); // Refresh UI
        }
      }
    });
  }

  // Build #1.0.10: Creates a new order and adds it as a new tab
  void addNewTab() async {
    int orderId = await orderHelper.createOrder(); // Create a new order
    await orderHelper.setActiveOrder(orderId); // Set the new order as active

    if (!mounted) return;
    setState(() {
      tabs.add({
        "title": "#$orderId", // New order number
        "subtitle": "Tab ${tabs.length + 1}", // Tab position
        "orderId": orderId as Object,
      });
    });

    if (!mounted) return;
    _initializeTabController(); // Reinitialize tab controller
    _tabController?.index = tabs.length - 1; // Select the new tab
    _scrollToSelectedTab(); // Ensure new tab is visible
    fetchOrderItems(); // Load items for the new order
  }

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
  void removeTab(int index) async {
    if (tabs.isNotEmpty) {
      int orderId = tabs[index]["orderId"] as int;
      bool isRemovedTabActive = orderId == orderHelper.activeOrderId;

      await orderHelper.deleteOrder(orderId); // Delete order from DB

      setState(() {
        tabs.removeAt(index); // Remove tab from the UI

        // Update subtitles to maintain order
        for (int i = 0; i < tabs.length; i++) {
          tabs[i]["subtitle"] = "Tab ${i + 1}";
        }
      });

      _initializeTabController(); // Reinitialize tabs

      if (tabs.isNotEmpty) {
        if (isRemovedTabActive) {
          // If the removed tab was active, switch to another tab
          int newIndex = index >= tabs.length ? tabs.length - 1 : index;
          _tabController!.index = newIndex;
          int newActiveOrderId = tabs[newIndex]["orderId"] as int;
          await orderHelper.setActiveOrder(newActiveOrderId);
        } else {
          // Keep the currently active tab
          int currentActiveIndex = tabs.indexWhere((tab) => tab["orderId"] == orderHelper.activeOrderId);
          if (currentActiveIndex != -1) {
            _tabController!.index = currentActiveIndex;
          }
        }

        fetchOrderItems(); // Refresh order items list
      } else {
        // No orders left, reset active order and clear UI
        orderHelper.activeOrderId = null;
        setState(() {
          orderItems = []; // Clear order items
        });
      }
    }
  }

  // Build #1.0.10: Deletes an item from the active order
  void deleteItemFromOrder(int itemId) async {
    if (orderHelper.activeOrderId != null) {
      await orderHelper.deleteItem(itemId); // Delete item from DB
      fetchOrderItems(); // Refresh the order items list
    }
  }

  @override
  void dispose() {
    _updateOrderSubscription?.cancel(); // Cancel the subscription
    orderBloc.dispose(); // Dispose the bloc if needed
    _fetchOrdersSubscription?.cancel();
    orderBloc.dispose();
    _tabController?.dispose();
    _scrollController.dispose(); // Dispose ScrollController
    _productBySkuSubscription?.cancel(); // Build #1.0.44 : Added Cancel product subscription
    productBloc.dispose(); // Added: Dispose ProductBloc
    super.dispose();
  }

  Future<String> getDeviceId() async { // Build #1.0.44 : Get Device Id
    final storeValidationRepository = StoreValidationRepository();
    try {
      final deviceDetails = await storeValidationRepository.getDeviceDetails();
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
    return BarcodeKeyboardListener( // Build #1.0.44 : Added - Wrap with BarcodeKeyboardListener for barcode scanning
      bufferDuration: Duration(milliseconds: 400),
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
            if (kDebugMode) {
              print("##### DEBUG: onBarcodeScanned - No tabs, creating new order");
            }
            String deviceId = await getDeviceId();
            OrderMetaData device = OrderMetaData(key: OrderMetaData.posDeviceId, value: deviceId);
            OrderMetaData placedBy = OrderMetaData(key: OrderMetaData.posPlacedBy, value: '${orderHelper.activeUserId ?? 1}');
            List<OrderMetaData> metaData = [device,placedBy];

            await orderBloc.createOrder(metaData);
            _getOrderTabs();
          }
          // Show loading indicator
          setState(() => _isLoading = true);
          // Fetch product by SKU
          productBloc.fetchProductBySku(barcode);
          // Cancel previous subscription to avoid overlap
          _productBySkuSubscription?.cancel();
          _productBySkuSubscription = productBloc.productBySkuStream.listen((response) async {
            setState(() => _isLoading = false);
            if (kDebugMode) {
              print("##### DEBUG: onBarcodeScanned - Product response status: ${response.status}");
            }
            if (response.status == Status.COMPLETED && response.data!.isNotEmpty) {
              final product = response.data!.first;
              if (kDebugMode) {
                print("##### DEBUG: onBarcodeScanned - Product found: ${product.name}, variations: ${product.variations.length}");
              }

              ///Todo: Need to call variation service before showing dialog
              if (product.variations.isNotEmpty) {
                // Show variants dialog for products with variations
                if (kDebugMode) {
                  print("##### DEBUG: onBarcodeScanned - Showing variants dialog");
                }
                // Assume variations contain objects with id, price, image, and attributes
                List<Map<String, dynamic>> variantMaps = product.variations.map((v) {
                  return {
                    'id': v['id'] ?? v, // Handle both object and ID cases
                    'name': (v['attributes'] as List<dynamic>?)?.join(', ') ?? 'Variant',
                    'price': v['price'] ?? product.price,
                    'image': v['image']?['src'] ?? product.images.isNotEmpty ? product.images.first.src : '',
                  };
                }).toList();
                if (!mounted) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  builder: (context) => VariantsDialog(
                    title: product.name,
                    variations: variantMaps,
                    onAddVariant: (variant, quantity) async {
                      if (kDebugMode) {
                        print("##### DEBUG: onBarcodeScanned - Adding variant: ${variant['name']}, quantity: $quantity");
                      }
                      await orderHelper.addItemToOrder(
                        variant['name'],
                        variant['image'],
                        double.parse(variant['price'].toString()),
                        quantity,
                        barcode,
                      );
                      await fetchOrderItems();
                    },
                  ),
                );
                });
              } else {
                // Add product directly to order
                if (kDebugMode) {
                  print("##### DEBUG: onBarcodeScanned - Adding product: ${product.name}");
                }
                await orderHelper.addItemToOrder(
                  product.name,
                  product.images.isNotEmpty ? product.images.first.src : '',
                  double.parse(product.price.isNotEmpty ? product.price : '0.0'),
                  1,
                  barcode,
                );
                await fetchOrderItems();
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
                                    color: isSelected ? Colors.white : Colors.grey.shade400,
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
                                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            tabs[index]["subtitle"] as String,
                                            style: const TextStyle(color: Colors.black54, fontSize: 12),
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
                                          // Build #1.0.49: Call Order Status Update API
                                          orderBloc.changeOrderStatus(
                                              orderId: orderHelper.activeOrderId!,
                                              status: TextConstants.cancelled
                                          );

                                          StreamSubscription? subscription;
                                          subscription = orderBloc.changeOrderStatusStream.listen((response) {
                                            if (response.status == Status.COMPLETED) {
                                              if (kDebugMode) {
                                                print("OrderPanel - Order ${orderHelper.activeOrderId}, successfully cancelled");
                                              }
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      TextConstants.orderCancelled,
                                                      style: const TextStyle(color: Colors.white)),
                                                      backgroundColor: Colors.black,
                                                      duration: const Duration(seconds: 3),
                                                    ),
                                                  );

                                                  // Moved inside the stream listener
                                                  if (mounted) {
                                                removeTab(index);
                                              }
                                            } else if (response.status == Status.ERROR) {
                                              if (kDebugMode) {
                                                print("OrderPanel - Cancel failed: ${response.message}");
                                              }
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      response.message ?? "Failed to cancel order",
                                                      style: const TextStyle(color: Colors.red)),
                                                      backgroundColor: Colors.black,
                                                      duration: const Duration(seconds: 3),
                                                    ),
                                                  );
                                              }
                                                  subscription?.cancel();
                                            });

                                          // Removed removeTab(index) from here
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
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        minimumSize: const Size(50, 56),
                      ),
                      child: const Text("+", style: TextStyle(color: Colors.black87, fontSize: 16)),
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
// Current Order UI
  Widget buildCurrentOrder() {
    final theme = Theme.of(context); // Build #1.0.6 - added theme for order panel
    if (kDebugMode) {
      print("Building Current Order Widget");
    } // Debug print
    // Fetch discount and tax for the active order
    double orderDiscount = 0.0;
    double orderTax = 0.0;

    if (orderHelper.activeOrderId != null) {
      final order = orderHelper.orders.firstWhere(
            (order) => order[AppDBConst.orderId] == orderHelper.activeOrderId,
        orElse: () => {},
      );
      orderDiscount = order[AppDBConst.orderDiscount] as double? ?? 0.0;
      orderTax = order[AppDBConst.orderTax] as double? ?? 0.0;
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.formattedDate,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.secondaryHeaderColor)),
                  const SizedBox(width: 8),
                  Text(widget.formattedTime, style: TextStyle(fontSize: 14, color: theme.secondaryHeaderColor)),
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
            itemCount: orderItems.length,
            proxyDecorator: (Widget child, int index, Animation<double> animation) {
              return Material(
                color: Colors.transparent, // Removes white background
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final orderItem = orderItems[index];
              return ClipRRect(
                key: ValueKey(index),
                borderRadius: BorderRadius.circular(20),
                child: SizedBox( // Ensuring Slidable matches the item height
                  height: MediaQuery.of(context).size.height * 0.1, // Adjust to match your item height
                  child: Slidable( //Build #1.0.2 : added code for delete the items in list
                    key: ValueKey(index),
                    closeOnScroll: true,
                    direction: Axis.horizontal,
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        CustomSlidableAction(
                          onPressed: (context) async { // Build #1.0.53 : when delte tap call delte order item api
                            if (kDebugMode) {
                              print("Deleting item at index $index with itemId: ${orderItem[AppDBConst.itemId]}");
                            }
                            if (orderHelper.activeOrderId != null) {
                              final order = orderHelper.orders.firstWhere(
                                    (order) => order[AppDBConst.orderId] == orderHelper.activeOrderId,
                                orElse: () => {},
                              );
                              final serverOrderId = order[AppDBConst.orderServerId] as int?;

                              if (serverOrderId != null) {
                                setState(() => _isLoading = true);

                                _updateOrderSubscription?.cancel();
                                _updateOrderSubscription = orderBloc.deleteOrderItemStream.listen((response) async {
                                  setState(() => _isLoading = false);

                                  if (response.status == Status.COMPLETED) {
                                    if (kDebugMode) {
                                      print("OrderPanel - Item deleted successfully for order $serverOrderId");
                                    }
                                    await orderHelper.deleteItem(orderItem[AppDBConst.itemId]);
                                    await fetchOrderItems();
                                    widget.refreshOrderList?.call();
                                  } else if (response.status == Status.ERROR) {
                                    if (kDebugMode) {
                                      print("OrderPanel - Delete failed: ${response.message}");
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(response.message ?? "Failed to delete item")),
                                    );
                                  }
                                });

                                await orderBloc.deleteOrderItem(
                                  orderId: serverOrderId,
                                  lineItems: [OrderLineItem(id: orderItem[AppDBConst.itemId], quantity: 0)],
                                );
                              } else {
                                // Fallback to local delete if no server ID
                                await orderHelper.deleteItem(orderItem[AppDBConst.itemId]);
                                await fetchOrderItems();
                                widget.refreshOrderList?.call();
                              }
                            }
                          },
                          backgroundColor: Colors.transparent, // No background color
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, color: Colors.red), // Ensures red tint
                              const SizedBox(height: 4),
                              const Text(TextConstants.deleteText, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        // Replace dialog with center screen

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProductScreen(
                              orderItem: orderItem,
                              onQuantityUpdated: (newQuantity) async {
                                //Build 1.1.36: Update the quantity in the database
                                if (orderHelper.activeOrderId != null) {
                                  await orderHelper.updateItemQuantity(
                                    orderItem[AppDBConst.itemId],
                                    newQuantity,
                                  );
                                }
                                // Refresh the order items to reflect the updated quantity
                                await fetchOrderItems();
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                              borderRadius: BorderRadius.circular(10),
                              child: orderItem[AppDBConst.itemImage].toString().startsWith('http')
                                  ? Image.network(
                                      orderItem[AppDBConst.itemImage],
                                      height: 30,
                                      width: 30,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return SvgPicture.asset(
                                          'assets/svg/password_placeholder.svg',
                                          height: 30,
                                          width: 30,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                  : orderItem[AppDBConst.itemImage]
                                          .toString()
                                          .startsWith('assets/')
                                      ? SvgPicture.asset(
                                          orderItem[AppDBConst.itemImage],
                                          height: 30,
                                          width: 30,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(orderItem[AppDBConst.itemImage]),
                                          height: 30,
                                          width: 30,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return SvgPicture.asset(
                                              'assets/svg/password_placeholder.svg',
                                              height: 30,
                                              width: 30,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    orderItem[AppDBConst.itemName],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  Text(
                                    "${orderItem[AppDBConst.itemCount]} * \$${orderItem[AppDBConst.itemPrice]}", // Build #1.0.12: now item count will update in order panel
                                    style:
                                        const TextStyle(color: Colors.black54, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "\$${(orderItem[AppDBConst.itemCount] * orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
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
        // Container(
        //   padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        //   // decoration: BoxDecoration(
        //   //   color: Colors.grey.shade200,
        //   //   borderRadius: BorderRadius.circular(16),
        //   // ),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //     children: [
        //       // EBT Container
        //       Expanded(
        //         child: Container(
        //           padding: EdgeInsets.all(8),
        //           decoration: BoxDecoration(
        //             color: Colors.grey.shade200,
        //           ),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.center,
        //             children: [
        //               Text(TextConstants.ebtText,
        //                   style: TextStyle(
        //                       fontSize: 14,
        //                       fontWeight: FontWeight.bold,
        //                       color: Colors.black45)),
        //               Text("\$0.00",
        //                   style: TextStyle(
        //                       fontSize: 14, fontWeight: FontWeight.bold)),
        //             ],
        //           ),
        //         ),
        //       ),
        //       // Payouts Container
        //       Expanded(
        //         child: Container(
        //           padding: EdgeInsets.all(8),
        //           decoration: BoxDecoration(
        //             color: Colors.grey.shade300,
        //           ),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.center,
        //             children: [
        //               Text(TextConstants.payoutsText,
        //                   style: TextStyle(
        //                       fontSize: 14,
        //                       fontWeight: FontWeight.bold,
        //                       color: Colors.black45)),
        //               Text("\$0.00",
        //                   style: TextStyle(
        //                       fontSize: 14, fontWeight: FontWeight.bold)),
        //             ],
        //           ),
        //         ),
        //       ),
        //       // Subtotal Container
        //       Expanded(
        //         child: Container(
        //           padding: EdgeInsets.all(8),
        //           decoration: BoxDecoration(
        //             color: Colors.grey.shade400,
        //           ),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.center,
        //             children: [
        //               Text(TextConstants.subTotalText,
        //                   style: TextStyle(
        //                       fontSize: 14,
        //                       fontWeight: FontWeight.bold,
        //                       color: Colors.black45)),
        //               Text("\$0.00",
        //                   style: TextStyle(
        //                       fontSize: 14, fontWeight: FontWeight.bold)),
        //             ],
        //           ),
        //         ),
        //       ),
        //       // Tax Container
        //       Expanded(
        //         child: Container(
        //           padding: EdgeInsets.all(8),
        //           decoration: BoxDecoration(
        //             color: Colors.grey.shade500,
        //           ),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.center,
        //             children: [
        //               Text(TextConstants.taxText,
        //                   style: TextStyle(
        //                       fontSize: 14,
        //                       fontWeight: FontWeight.bold,
        //                       color: Colors.white)),
        //               Text("\$0.00",
        //                   style: TextStyle(
        //                       fontSize: 14,
        //                       fontWeight: FontWeight.bold,
        //                       color: Colors.white)),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // Container(
        //   padding: const EdgeInsets.all(16),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: ElevatedButton(
        //           onPressed: () {},
        //           style: ElevatedButton.styleFrom(
        //             backgroundColor: Colors.white,
        //             shape: RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(10),
        //               side: const BorderSide(color: Colors.black),
        //             ),
        //           ),
        //           child: const Text(TextConstants.holdOrderText,
        //               style: TextStyle(color: Colors.black)),
        //         ),
        //       ),
        //       const SizedBox(width: 10),
        //       Expanded(
        //         child: ElevatedButton(
        //           onPressed: () {
        //             Navigator.push(context, MaterialPageRoute(builder: (context) => OrderSummaryScreen(),));
        //           },
        //           style: ElevatedButton.styleFrom(
        //             backgroundColor: Colors.green,
        //             shape: RoundedRectangleBorder(
        //                 borderRadius: BorderRadius.circular(10)),
        //           ),
        //           child: Text(
        //             "${TextConstants.payText} \$${(widget.quantities.fold(0.0, (double sum, qty) => sum + qty * 0.99)).toStringAsFixed(2)}",
        //             style: const TextStyle(color: Colors.white),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // )
///Todo: update ui as per loading from screen
        ///Show print and email invoice buttons if coming from order history screen
        ///else show regular buttons
        Column(
          children: [
            // Summary container
            Container(
              height: MediaQuery.of(context).size.height * 0.125,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Order summary section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sub total",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "\$${getSubTotal().toStringAsFixed(2)}", // only two index show
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  //const SizedBox(height: 8),

                  // Tax row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tax",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "\$${orderTax.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  //const SizedBox(height: 4),

                  // Discount row - with green text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Discount",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1BA672),
                        ),
                      ),
                      Text(
                        "-\$${orderDiscount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1BA672),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Payment button - outside the container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.0575,
              child: ElevatedButton( //Build 1.1.36: on pay tap calling updateOrderProducts api call
                onPressed: () async {
                  if (orderHelper.activeOrderId != null) {
                    setState(() {
                      _isLoading = true;
                    });

                    final order = orderHelper.orders.firstWhere(
                          (order) => order[AppDBConst.orderId] == orderHelper.activeOrderId,
                      orElse: () => {},
                    );
                    final serverOrderId = order[AppDBConst.orderServerId] as int?;

                    if (serverOrderId == null) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Server Order ID not found")),
                      );
                      return;
                    }

                    // Assign the subscription to your class variable
                    _updateOrderSubscription = orderBloc.updateOrderStream.listen((response) async {
                      if (!mounted) return; // Safety check

                      if (response.status == Status.COMPLETED) {
                        if (kDebugMode) {
                          print("###### updateOrder COMPLETED");
                        }

                        setState(() => _isLoading = false); // dismiss the loader

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrderSummaryScreen()),
                        );
                      } else if (response.status == Status.ERROR) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response.message ?? "Failed to update order")),
                        );
                      }
                    });

                    // Prepare line items for API
                    List<OrderLineItem> lineItems = orderItems.map((item) => OrderLineItem(
                      productId: item[AppDBConst.itemId],
                      quantity: item[AppDBConst.itemCount],
                    )).toList();

                    // Call API
                    await orderBloc.updateOrderProducts(
                      dbOrderId: orderHelper.activeOrderId!,
                      orderId: serverOrderId,
                      lineItems: lineItems,
                    );
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
                child: _isLoading  //Build 1.1.36: added loader for pay button in order panel
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Pay \$${getSubTotal().toStringAsFixed(2)}", // only two index show
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  num getSubTotal() {
    num total = 0;
    double orderDiscount = 0.0;
    double orderTax = 0.0;

    if (orderHelper.activeOrderId != null) {
      final order = orderHelper.orders.firstWhere(
            (order) => order[AppDBConst.orderId] == orderHelper.activeOrderId,
        orElse: () => {},
      );
      orderDiscount = order[AppDBConst.orderDiscount] as double? ?? 0.0;
      orderTax = order[AppDBConst.orderTax] as double? ?? 0.0;
    }

    for (var item in orderItems) {
      // var orderId = item[AppDBConst.itemId];
      var subTotal = item[AppDBConst.itemSumPrice];
      total = total + subTotal;
    }

    // Adjust total with tax and discount
    total = total + orderTax - orderDiscount;

    return total;
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
