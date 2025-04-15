import 'dart:io';

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Widgets/widget_custom_num_pad.dart';
import 'package:pinaka_pos/Widgets/widget_nested_grid_layout.dart';

import '../Constants/text.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
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

  @override
  void initState() {
    super.initState();
    _getOrderTabs(); // Load existing orders into tabs
  }

  @override
  void didUpdateWidget(RightOrderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _getOrderTabs(); // Build #1.0.10 : Reload tabs when the widget updates (e.g., after item selection)

    if (kDebugMode) {
      print("##### RightOrderPanel didUpdateWidget");
    }
  }

  // Build #1.0.10: Fetches the list of order tabs from OrderHelper
  void _getOrderTabs() async {
    await orderHelper.loadData(); // Load order data from DB

    if (mounted) {
      setState(() {
        // Convert order IDs into tab format
        tabs = orderHelper.orderIds
            .asMap()
            .entries
            .map((entry) => {
                  "title": "#${entry.value}", // Order number
                  "subtitle": "Tab ${entry.key + 1}", // Tab position
                  "orderId": entry.value as Object, // Order ID
                })
            .toList();
      });
    }

    _initializeTabController(); // Initialize tab controller

    if (tabs.isNotEmpty) {
      // Set the current tab index to match the active order
      if (orderHelper.activeOrderId != null) {
        int index = orderHelper.orderIds.indexOf(orderHelper.activeOrderId!);
        _tabController?.index = index;
      } else {
        _tabController?.index = tabs.length - 1; // Default to last tab if no active order
      }

      await orderHelper.setActiveOrder(orderHelper.activeOrderId!); // Save active order
      fetchOrderItems(); // Load items for active order
    }
  }

  // Build #1.0.10: Fetches order items for the active order
  Future<void> fetchOrderItems() async {
    if (orderHelper.activeOrderId != null) {
      List<Map<String, dynamic>> items = await orderHelper.getOrderItems(orderHelper.activeOrderId!);

      if (kDebugMode) {
        print("##### fetchOrderItems :$items");
      }

      setState(() {
        orderItems = items; // Update the order items list
      });
    } else {
      setState(() {
        orderItems.clear(); // Clear the order items list if no active order
      });
    }
  }

  // Build #1.0.10: Initializes the tab controller and handles tab switching
  void _initializeTabController() {
    _tabController?.dispose(); // Dispose the existing controller
    _tabController = TabController(length: tabs.length, vsync: this);

    _tabController!.addListener(() async {
      if (mounted) {
        int selectedIndex = _tabController!.index; // Get selected tab index
        int selectedOrderId = tabs[selectedIndex]["orderId"] as int;

        await orderHelper.setActiveOrder(selectedOrderId); // Set new active order
        fetchOrderItems(); // Load items for the selected order
        setState(() {}); // Refresh UI
      }
    });
  }

  // Build #1.0.10: Creates a new order and adds it as a new tab
  void addNewTab() async {
    int orderId = await orderHelper.createOrder(); // Create a new order
    await orderHelper.setActiveOrder(orderId); // Set the new order as active

    setState(() {
      tabs.add({
        "title": "#$orderId", // New order number
        "subtitle": "Tab ${tabs.length + 1}", // Tab position
        "orderId": orderId as Object,
      });
    });

    _initializeTabController(); // Reinitialize tab controller
    _tabController?.index = tabs.length - 1; // Select the new tab
    _scrollToSelectedTab(); // Ensure new tab is visible
    fetchOrderItems(); // Load items for the new order
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
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width * 0.32,
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
                                      onTap: () => removeTab(index),
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
    );
  }
// Current Order UI
  Widget buildCurrentOrder() {
    final theme = Theme.of(context); // Build #1.0.6 - added theme for order panel
    if (kDebugMode) {
      print("Building Current Order Widget");
    } // Debug print
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  height: 90, // Adjust to match your item height
                  child: Slidable( //Build #1.0.2 : added code for delete the items in list
                    key: ValueKey(index),
                    closeOnScroll: true,
                    direction: Axis.horizontal,
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        CustomSlidableAction(
                          onPressed: (context) async {
                            if (kDebugMode) {
                              print("Deleting item at index $index");
                            } // Debug print
                            deleteItemFromOrder(orderItem[AppDBConst.itemId]);
                            fetchOrderItems();
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
                              onQuantityUpdated: (newQuantity) {
                                // Handle the quantity update
                                setState(() {
                                  orderItem[AppDBConst.itemCount] = newQuantity;
                                });
                              },
                            ),
                          ),
                        );
                        // showGeneralDialog(
                        //   context: context,
                        //   pageBuilder: (context, animation, secondaryAnimation) => Container(), // Placeholder, we use transitionBuilder
                        //   barrierDismissible: true,
                        //   barrierLabel: "Dismiss",
                        //   transitionDuration: const Duration(milliseconds: 500), // Animation duration
                        //   transitionBuilder: (context, animation, secondaryAnimation, child) {
                        //     // Define the slide animation
                        //     final Tween<Offset> tween = Tween(
                        //       begin: const Offset(1.0, 0.0), // Start from the right
                        //       end: Offset.zero, // End at the center
                        //     );
                        //     final Animation<Offset> offsetAnimation = animation.drive(tween);
                        //
                        //     return SlideTransition(
                        //       position: offsetAnimation,
                        //       child: ProductEditScreen(
                        //         orderItem: orderItem,
                        //         onQuantityUpdated: (newQuantity) {
                        //           setState(() {
                        //             orderItem[AppDBConst.itemCount] = newQuantity;
                        //           });
                        //         },
                        //       ),
                        //     );
                        //   },
                        // );
                        //showProductEditScreen(context, orderItem);
                        //Navigator.push(context, MaterialPageRoute(builder: (context) => OrdersScreen()));
                        // showNumPadDialog(context, orderItem[AppDBConst.itemName], (selectedQuantity) {
                        //   setState(() {
                        //     orderItem[AppDBConst.itemCount] = selectedQuantity;
                        //   });
                        // });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        padding: const EdgeInsets.all(12),
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
                                children: [
                                  Text(
                                    orderItem[AppDBConst.itemName],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  Text(
                                    "${orderItem[AppDBConst.itemCount]} * \$${orderItem[AppDBConst.itemPrice]}", // Build #1.0.12: now item count will update in order panel
                                    style:
                                        const TextStyle(color: Colors.black54),
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
                                      fontSize: 18,
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
        Container(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          // decoration: BoxDecoration(
          //   color: Colors.grey.shade200,
          //   borderRadius: BorderRadius.circular(16),
          // ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // EBT Container
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(TextConstants.ebtText,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black45)),
                      Text("\$0.00",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              // Payouts Container
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(TextConstants.payoutsText,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black45)),
                      Text("\$0.00",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              // Subtotal Container
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(TextConstants.subTotalText,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black45)),
                      Text("\$0.00",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              // Tax Container
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(TextConstants.taxText,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text("\$0.00",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                  child: const Text(TextConstants.holdOrderText,
                      style: TextStyle(color: Colors.black)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    "${TextConstants.payText} \$${(widget.quantities.fold(0.0, (double sum, qty) => sum + qty * 0.99)).toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        )
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
