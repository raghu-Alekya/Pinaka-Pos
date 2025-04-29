import 'dart:io';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart'; // Added for date formatting

import '../../Blocs/Payment/payment_bloc.dart';
import '../../Constants/text.dart';
import '../../Database/db_helper.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Models/Payment/payment_model.dart';
import '../../Repositories/Payment/payment_repository.dart';
import '../../Widgets/widget_custom_num_pad.dart';
import 'edit_product_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  List<Map<String, dynamic>> orderItems = [];
  String selectedPaymentMethod = TextConstants.cash;
  TextEditingController amountController = TextEditingController();
  final PaymentBloc paymentBloc = PaymentBloc(PaymentRepository()); // Added PaymentBloc
  int? userId; // Build #1.0.29: To store user ID
  int? orderId; // server id from order table
  int shiftId = 1; // Hardcoded as per requirement
  int vendorId = 1; // Hardcoded as per requirement
  String serviceType = "default"; // Hardcoded as per requirement
  double balanceAmount = 0.0;

  @override
  void initState() {
    super.initState();
    fetchOrderItems();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async { // Build #1.0.29: get the userId from db
    final userData = await UserDbHelper().getUserData();
    if (userData != null && userData[AppDBConst.userId] != null) {
      setState(() {
        userId = userData[AppDBConst.userId] as int;
      });
    }
  }

  // void fetchOrderItems() async {
  //   // TODO: Implement actual data fetching from database
  //   setState(() {
  //     // Temporary sample data
  //     orderItems = [];
  //   });
  // }

  void deleteItemFromOrder(dynamic itemId) async {
    // TODO: Implement actual deletion logic
    setState(() {
      orderItems.removeWhere((item) => item[AppDBConst.itemId] == itemId);
    });
  }

  void _callCreatePaymentAPI() { // Build #1.0.29
    if (kDebugMode) {
      print("###### _callCreatePaymentAPI called");
    }
    if (amountController.text.isEmpty) return;
    String cleanAmount = amountController.text.replaceAll('\$', '').trim();
    final double amount = double.tryParse(cleanAmount) ?? 0.0;
    if (amount == 0.0) {
      if (kDebugMode) {
        print("Invalid amount: $cleanAmount");
      }
      return;
    }
    final String datetime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final paymentRequest = PaymentRequestModel(
      title: selectedPaymentMethod,
      orderId: orderId ?? 0,
      amount: amount,
      paymentMethod: selectedPaymentMethod,
      shiftId: shiftId,
      vendorId: vendorId,
      userId: userId ?? 0,
      serviceType: serviceType,
      datetime: datetime,
      notes: '',
    );
    paymentBloc.createPayment(paymentRequest);
    if (kDebugMode) {
      print("Creating payment with request: $paymentRequest");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header with logo and user info
            _buildHeader(),

            // Main content area: split horizontally
            Expanded(
              child: Row(
                children: [
                  // Left Side: Navigation bar + Order Summary stacked vertically
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildNavigationBar(),

                        // Order summary takes the rest of the vertical space
                        Expanded(
                          child: _buildOrderSummary(),
                        ),
                      ],
                    ),
                  ),

                  // Right Side: Payment Section
                  Expanded(
                    flex: 4,
                    child: _buildPaymentSection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pinaka logo with triangle above it
          SvgPicture.asset(
            'assets/svg/app_icon.svg',
            height: 40,
            width: 40,
          ),

          // User profile section with container and notification bell
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        "A",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'A Raghav Kumar',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        Text(
                          'I am Cashier',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(10),
                child: Icon(Icons.notifications_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        margin: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.grey[100],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      spreadRadius: 1),
                ],
              ),
              child: Row(
                children: [
                  // Icon(Icons.chevron_left, size: 20),
                  BackButton(),
                  // const SizedBox(width: 8),
                  Text('Back', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

            // Date and Time Container
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Sunday, 16 March 2025',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Time
            Row(
              children: [
                Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text(
                  '11:41 A.M',
                  style: TextStyle(
                      color: Colors.grey[700], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        margin: EdgeInsets.only(left: 20.0, right: 10.0, bottom: 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Payment Summary header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${TextConstants.orderId} #$orderId', // Build #1.0.29: orderId(serverId) from db
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      )),
                  Text(TextConstants.paymentSummary,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      )),
                ],
              ),
              const SizedBox(height: 16),

              // Order items list
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: orderItems.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      return _buildOrderItem(index);
                    },
                  ),
                ),
              ),

              // Bottom summary container
              Expanded(
                flex: 7,
                child: Container(
                  margin: EdgeInsets.only(top: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: EdgeInsets.all(15),
                  child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      // Order calculations
                      _buildOrderCalculation(TextConstants.subTotalText, '\$${getSubTotal()}',
                          isTotal: true),
                      _buildOrderCalculation(TextConstants.taxText , '\$0.0'),
                      _buildOrderCalculation(TextConstants.discount, '-\$0.0',
                          isDiscount: true),
                      SizedBox(height: 5,),
                        DottedLine(),
                      SizedBox(height: 5,),
                      _buildOrderCalculation(TextConstants.total, '\$${getSubTotal()}', isTotal: true),
                      _buildOrderCalculation(TextConstants.payByCash, '\$0.0'),
                      _buildOrderCalculation(TextConstants.payByOther, '\$0.0'),
                      _buildOrderCalculation(TextConstants.tenderAmount, '\$0.0'),
                      _buildOrderCalculation(TextConstants.change, '\$0.0'),
                    ],
                    ),
                  ),
                ),
              ),
              Expanded(flex: 0, child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  final OrderHelper orderHelper = OrderHelper(); // Helper instance to manage orders

  // Build #1.0.10: Fetches order items for the active order
  Future<void> fetchOrderItems() async {
    if (orderHelper.activeOrderId != null) {
      List<Map<String, dynamic>> items = await orderHelper.getOrderItems(orderHelper.activeOrderId!);

      //Build #1.0.29:  Fetch the orderServerId from the database
      final db = await DBHelper.instance.database;
      final List<Map<String, dynamic>> orderData = await db.query(
        AppDBConst.orderTable,
        columns: [AppDBConst.orderServerId],
        where: '${AppDBConst.orderId} = ?',
        whereArgs: [orderHelper.activeOrderId],
      );

      if (orderData.isNotEmpty) {
        setState(() {
          orderId = orderData.first[AppDBConst.orderServerId] as int? ?? 0;
          if (kDebugMode) {
            print("Fetched orderServerId: $orderId for activeOrderId: ${orderHelper.activeOrderId}");
          }
        });
      } else {
        if (kDebugMode) {
          print("No orderServerId found for activeOrderId: ${orderHelper.activeOrderId}");
        }
      }

     // Build #1.0.29: Calculate balance amount from order items
      double total = 0.0;
      for (var item in items) {
        double price = (item[AppDBConst.itemPrice] as num).toDouble();
        int count = item[AppDBConst.itemCount] as int;
        total += price * count;
      }

      if (kDebugMode) {
        print("##### fetchOrderItems :$items");
        print("Calculated balance amount: $total");
      }

      setState(() {
        orderItems = items;
        balanceAmount = total; // Update balance amount
      });
    } else {
      setState(() {
        orderItems.clear();
        balanceAmount = 0.0; // Reset balance if no items
      });
    }
  }

  Widget _buildOrderItem(int index) {
    var orderItem = orderItems[index];
    return
    //   Expanded(
    //   child: ReorderableListView.builder(
    //     onReorder: (oldIndex, newIndex) {
    //       if (kDebugMode) {
    //         print("Reordering item from $oldIndex to $newIndex");
    //       }
    //       if (oldIndex < newIndex) newIndex -= 1;
    //
    //       setState(() {
    //         final movedItem = orderItems.removeAt(oldIndex);
    //         orderItems.insert(newIndex, movedItem);
    //       });
    //     },
    //     itemCount: orderItems.length,
    //     proxyDecorator: (Widget child, int index, Animation<double> animation) {
    //       return Material(
    //         color: Colors.transparent,
    //         child: child,
    //       );
    //     },
    //     itemBuilder: (context, index) {
    //       final orderItem = orderItems[index];
    //       return ClipRRect(
    //         key: ValueKey(index),
    //         borderRadius: BorderRadius.circular(20),
    //         child: SizedBox(
    //           height: 90,
    //           child: Slidable(
    //             key: ValueKey(index),
    //             closeOnScroll: true,
    //             direction: Axis.horizontal,
    //             endActionPane: ActionPane(
    //               motion: const DrawerMotion(),
    //               children: [
    //                 CustomSlidableAction(
    //                   onPressed: (context) async {
    //                     if (kDebugMode) {
    //                       print("Deleting item at index $index");
    //                     }
    //                     deleteItemFromOrder(orderItem[AppDBConst.itemId]);
    //                     fetchOrderItems();
    //                   },
    //                   backgroundColor: Colors.transparent,
    //                   child: Column(
    //                     mainAxisAlignment: MainAxisAlignment.center,
    //                     children: [
    //                       Icon(Icons.delete, color: Colors.red),
    //                       const SizedBox(height: 4),
    //                       const Text(TextConstants.deleteText,
    //                           style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
    //                     ],
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             child: GestureDetector(
    //               // onTap: () {
    //               //   Navigator.push(
    //               //     context,
    //               //     MaterialPageRoute(
    //               //       builder: (context) => EditProductScreen(
    //               //         orderItem: orderItem,
    //               //         onQuantityUpdated: (newQuantity) {
    //               //           setState(() {
    //               //             orderItem[AppDBConst.itemCount] = newQuantity;
    //               //           });
    //               //         },
    //               //       ),
    //               //     ),
    //               //   );
    //               // },
    //               child: Container(
    //                 margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    //                 padding: const EdgeInsets.all(12),
    //                 decoration: BoxDecoration(
    //                   color: Colors.white,
    //                   borderRadius: BorderRadius.circular(20),
    //                   boxShadow: const [
    //                     BoxShadow(
    //                       color: Colors.black12,
    //                       blurRadius: 5,
    //                       spreadRadius: 1,
    //                     )
    //                   ],
    //                 ),
    //                 child: Row(
    //                   children: [
    //                     ClipRRect(
    //                       borderRadius: BorderRadius.circular(10),
    //                       child: orderItem[AppDBConst.itemImage].toString().startsWith('http')
    //                           ? Image.network(
    //                               orderItem[AppDBConst.itemImage],
    //                               height: 30,
    //                               width: 30,
    //                               fit: BoxFit.cover,
    //                               errorBuilder: (context, error, stackTrace) {
    //                                 return SvgPicture.asset(
    //                                   'assets/svg/password_placeholder.svg',
    //                                   height: 30,
    //                                   width: 30,
    //                                   fit: BoxFit.cover,
    //                                 );
    //                               },
    //                             )
    //                           : orderItem[AppDBConst.itemImage].toString().startsWith('assets/')
    //                               ? SvgPicture.asset(
    //                                   orderItem[AppDBConst.itemImage],
    //                                   height: 30,
    //                                   width: 30,
    //                                   fit: BoxFit.cover,
    //                                 )
    //                               : Image.file(
    //                                   File(orderItem[AppDBConst.itemImage]),
    //                                   height: 30,
    //                                   width: 30,
    //                                   fit: BoxFit.cover,
    //                                   errorBuilder: (context, error, stackTrace) {
    //                                     return SvgPicture.asset(
    //                                       'assets/svg/password_placeholder.svg',
    //                                       height: 30,
    //                                       width: 30,
    //                                       fit: BoxFit.cover,
    //                                     );
    //                                   },
    //                                 ),
    //                     ),
    //                     const SizedBox(width: 10),
    //                     Expanded(
    //                       child: Column(
    //                         crossAxisAlignment: CrossAxisAlignment.start,
    //                         children: [
    //                           Text(
    //                             orderItem[AppDBConst.itemName],
    //                             style: const TextStyle(
    //                                 fontSize: 16,
    //                                 fontWeight: FontWeight.bold,
    //                                 color: Colors.black),
    //                           ),
    //                           Text(
    //                             "${orderItem[AppDBConst.itemCount]} * \$${orderItem[AppDBConst.itemPrice]}",
    //                             style: const TextStyle(color: Colors.black54),
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                     Column(
    //                       mainAxisAlignment: MainAxisAlignment.center,
    //                       children: [
    //                         Text(
    //                           "\$${(orderItem[AppDBConst.itemCount] * orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}",
    //                           style: const TextStyle(
    //                               fontSize: 18,
    //                               fontWeight: FontWeight.bold),
    //                         ),
    //                       ],
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ),
    //       );
    //     },
    //   ),
    // );
      Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      child: Row(
        children: [
          // Product image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect( // Build #1.0.13 : updated images from db not static default images
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
          ),
          SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderItem[AppDBConst.itemName],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                // Text(
                //   '(350ml)',
                //   style: TextStyle(
                //     color: Colors.grey,
                //     fontSize: 14,
                //   ),
                // ),
                SizedBox(height: 4),
                Text(
                  "${orderItem[AppDBConst.itemCount]} * \$${orderItem[AppDBConst.itemPrice]}", // Build #1.0.12: now item count will update in order panel
                  style:
                  const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),

          // Price
          Text(
            "\$${(orderItem[AppDBConst.itemCount] * orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildOrderCalculation(String label, String amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                fontSize: isTotal ? 16 : 15,
                color: isTotal ? Colors.black87 : Colors.grey[700],
                height: 1,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                fontSize: isTotal ? 16 : 15,
                color: isDiscount
                    ? Colors.green[600]
                    : (isTotal ? Colors.black87 : Colors.grey[800]),
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 20.0,right: 20.0, top: 20.0,),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.grey[100],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left:20,right:20,top: 15, bottom: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Payment amount display row
                  // Update _buildAmountDisplay in _buildPaymentSection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12.0 ,
                    children: [
                      _buildAmountDisplay(
                        TextConstants.balanceAmount,
                        '\$${balanceAmount.toStringAsFixed(2)}',//'\$${getSubTotal()}',
                        amountColor: Colors.red,
                      ),
                      _buildAmountDisplay(
                        TextConstants.tenderAmount,
                        amountController.text.isEmpty ? '\$0.00' : '\$${amountController.text}',
                      ),
                      _buildAmountDisplay(
                        TextConstants.change,
                        '\$${amountController.text.isEmpty ? "0.00" : (double.tryParse(amountController.text.replaceAll('\$', '')) ?? 0.0) >= balanceAmount ? ((double.tryParse(amountController.text.replaceAll('\$', '')) ?? 0.0) - balanceAmount).toStringAsFixed(2) : "0.00"}',
                        amountColor: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Payment methods
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cash payment section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Label container
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      TextConstants.cashPayment,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Amount TextField
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: TextField(
                                      controller: amountController,
                                      textAlign: TextAlign.right,
                                      enabled: false, // Disables interaction with the TextField
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        border: InputBorder.none,
                                        hintText: '\$0.00',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400], // Light grey placeholder
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      keyboardType: TextInputType.none, // Hide default keypad
                                      onTap: () {
                                        FocusScope.of(context).unfocus(); // Hide keypad
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Quick amount buttons
                                  // Update the Row in _buildPaymentSection to use dynamic quick amounts
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildQuickAmountButton('\$${balanceAmount.toStringAsFixed(2)}'), // Match balance amount
                                      _buildQuickAmountButton('\$${(balanceAmount + 2).toStringAsFixed(2)}'), // Slightly above
                                      _buildQuickAmountButton('\$${(balanceAmount + 12).toStringAsFixed(2)}'), // More above
                                      _buildQuickAmountButton('\$${((balanceAmount ~/ 10 + 1) * 10).toStringAsFixed(2)}'), // Round up to next 10
                                      _buildQuickAmountButton('\$${((balanceAmount ~/ 50 + 1) * 50).toStringAsFixed(2)}'), // Round up to next 50
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Here you would use your custom numpad widget
                                  // CustomNumpad(useCashLayout: true),
                                  // Build #1.0.29:  Update CustomNumPad code
                                  CustomNumPad(
                                    isPayment: true,
                                    getPaidAmount: () => amountController.text,
                                    balanceAmount: balanceAmount,
                                    onDigitPressed: (value) {
                                      amountController.text = (amountController.text + value).replaceAll(r'$', '');
                                      setState(() {});
                                    },
                                    onClearPressed: () {
                                      amountController.clear();
                                      setState(() {});
                                    },
                                    onDeletePressed: () {
                                      if (amountController.text.isNotEmpty) {
                                        amountController.text = amountController.text.substring(0, amountController.text.length - 1);
                                        setState(() {});
                                      }
                                    },
                                    onPayPressed: () {
                                      _callCreatePaymentAPI();
                                    },
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Payment mode selection

                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(TextConstants.selectPaymentMode,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  SizedBox(height: 10),
                  Container(
                    width: 300,
                    height: 550,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        _buildPaymentModeButton(TextConstants.cash, Icons.money,
                            isSelected: selectedPaymentMethod == TextConstants.cash, onTap: () {
                              setState(() {
                                selectedPaymentMethod = TextConstants.cash;
                              });
                            }),
                        const SizedBox(height: 50),
                        _buildPaymentModeButton(TextConstants.card, Icons.credit_card, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.card;
                          });
                        }),
                        const SizedBox(height: 50),
                        _buildPaymentModeButton(TextConstants.wallet, Icons.account_balance_wallet, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.wallet;
                          });
                        }),
                        const SizedBox(height: 50),
                        _buildPaymentModeButton(TextConstants.ebtText, Icons.payment, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.ebtText;
                          });
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [_buildPaymentOptionButton(TextConstants.redeemPoints, Icons.stars),
                        const SizedBox(height: 20),
                        _buildPaymentOptionButton(TextConstants.manualDiscount, Icons.discount),
                        const SizedBox(height: 20),
                        _buildPaymentOptionButton(TextConstants.giftReceipt, Icons.card_giftcard),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDisplay(
      String label,
      String amount,
       {
        Color amountColor = Colors.black,
      }) {
    var size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,

      children: [
        Text(label, style: TextStyle(fontSize: 18, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          width: size.width * 0.12, //220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildQuickAmountButton(String amount, {bool isHighlighted = false}) {
  //   return GestureDetector(
  //     onTap: () {
  //       amountController.text = amount.replaceAll(r'$', '');
  //       setState(() {});
  //     },
  //     child: Container(
  //       height: 60,
  //       width: 90,
  //       alignment: Alignment.center,
  //       padding: const EdgeInsets.all(16.0),
  //       decoration: BoxDecoration(
  //       //  color: isHighlighted ? Color(0xFFBFF1C0) : Color(0xFFE0E0E0),
  //         color: Color(0xFFBFF1C0),
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: isHighlighted ? Colors.green : Colors.black, fontSize: 18)),
  //     ),
  //   );
  // }

  // Update _buildQuickAmountButton to remove isHighlighted logic for enabling
  Widget _buildQuickAmountButton(String amount) { // Build #1.0.29: updated
    return GestureDetector(
      onTap: () {
        // Remove '$' and ensure the value is numeric
        String cleanAmount = amount.replaceAll('\$', '');
        amountController.text = cleanAmount;
        setState(() {});
      },
      child: Container(
        height: 60,
        width: 90,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Color(0xFFBFF1C0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentModeButton(String label, IconData icon,
      {bool isSelected = false, VoidCallback? onTap}) { // Build #1.0.29
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: isSelected ? Colors.red.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: isSelected ? Border.all(color: Colors.red.shade300) : Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.red : Colors.grey, size: 40),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: isSelected ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionButton(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  num getSubTotal(){
    num total = 0;
    for (var item in orderItems) {
      // var orderId = item[AppDBConst.itemId];
      var subTotal = item[AppDBConst.itemSumPrice];
      total = (total + subTotal);
    }
    return total;
  }
}
