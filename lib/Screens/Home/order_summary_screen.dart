import 'dart:async';
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
import '../../Helper/api_response.dart';
import '../../Models/Payment/payment_model.dart';
import '../../Repositories/Payment/payment_repository.dart';
import '../../Widgets/widget_custom_num_pad.dart';
import '../../Widgets/widget_payment_dialog.dart';
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
  String? userDisplayName; // Build #1.0.29: To store user ID
  String? userRole;
  int? orderId; // server id from order table
  String? orderDateTime = "";
  int shiftId = 1; // Hardcoded as per requirement
  int vendorId = 1; // Hardcoded as per requirement
  String serviceType = "default"; // Hardcoded as per requirement
  double balanceAmount = 0.0;
  double tenderAmount = 0.0; // Build #1.0.33 : added new variables
  double paidAmount = 0.0;
  double changeAmount = 0.0;
  bool isLoading = false; // Add this to track loading state
  // final TextEditingController _paymentController = TextEditingController();

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
        userDisplayName = userData[AppDBConst.userDisplayName];
        userRole = userData[AppDBConst.userRole];
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
    if (amountController.text.isEmpty) { //Build #1.0.34: updated code
      if (kDebugMode) {
        print("Error: Amount TextField is empty");
      }
      return;
    }

    String cleanAmount = amountController.text.replaceAll('\$', '').trim();
    final double amount = double.tryParse(cleanAmount) ?? 0.0;
    if (amount == 0.0) {
      if (kDebugMode) {
        print("Error: Invalid amount: $cleanAmount");
      }
      return;
    }

    setState(() {
      isLoading = true; //Build 1.1.36: Show loader on PAY tap
    });

    // Prepare payment request
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

    if (kDebugMode) {
      print("Creating payment with request: $paymentRequest");
    }

    //Build #1.0.34: updated code for API response and listen to stream then show popup
    paymentBloc.createPayment(paymentRequest);
    StreamSubscription? subscription;
    subscription = paymentBloc.createPaymentStream.listen((paymentResponse) {
      if (kDebugMode) {
        print("Payment stream response: $paymentResponse");
      }
      if (paymentResponse.data != null) {
        if (paymentResponse.status == Status.ERROR) {
          if (kDebugMode) {
            print("Payment API Error: ${paymentResponse.message}");
          }
          setState(() {
            isLoading = false; // Hide loader on error
          });
          subscription?.cancel();
        } else if (paymentResponse.status == Status.COMPLETED) {
          final paymentData = paymentResponse.data!;
          if (paymentData.message == "Payment Created Successfully") {
            setState(() {
              isLoading = false; // Hide loader on success
            });
            paidAmount = amount; // Current payment amount

            // Determine payment type
            final bool isExactPayment = (amount == balanceAmount);
            final bool isOverPayment = (amount > balanceAmount);
            final bool isPartialPayment = (amount < balanceAmount);

            if (isOverPayment) {
              if (kDebugMode) {
                print("#### isOverPayment");
              }
              changeAmount += amount - balanceAmount; // Calculate change
              balanceAmount = 0.0; // Balance fully paid
              tenderAmount += balanceAmount + amount;
            } else if (isExactPayment) {
              if (kDebugMode) {
                print("#### isExactPayment");
              }
              tenderAmount += amount;
              changeAmount = 0.0; // No change for exact payment
              balanceAmount = 0.0; // Balance fully paid
            } else if (isPartialPayment) {
              if (kDebugMode) {
                print("#### isPartialPayment");
              }
              tenderAmount += amount;
              balanceAmount -= amount; // Reduce balance for partial payment
              changeAmount = 0.0; // No change for partial payment
            } else if (balanceAmount == 0 && amount > 0) {
              if (kDebugMode) {
                print("#### balanceAmount is 0");
              }
              // Case where balance is already 0, return the entire amount as change
              changeAmount += amount; // Change is the current payment
              tenderAmount += amount; // Reset tender to current payment
            }

            amountController.clear(); // Clear input textField
            setState(() {}); // Update UI

            if (kDebugMode) {
              print("Payment successful - Paid: $paidAmount, Balance: $balanceAmount, Change: $changeAmount, Tender: $tenderAmount");
            }

            // Show appropriate dialog based on payment amount
            if (isPartialPayment) {
              if (kDebugMode) {
                print("Showing partial payment dialog: Paid=$paidAmount, Remaining Balance=$balanceAmount");
              }
              _showPartialPaymentDialog(context, amount);
            } else if (isExactPayment || isOverPayment || (balanceAmount == 0 && amount > 0)) {
              if (kDebugMode) {
                print("Showing payment dialog: Paid=$paidAmount, Change=$changeAmount");
              }
              _showPaymentDialog(
                context,
                amount,
                changeAmount: changeAmount,
                showChange: changeAmount > 0,
              );
            }
          }
          subscription?.cancel(); // Cancel subscription after handling
        }
      }
    });
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
      height: MediaQuery.of(context).size.height * 0.09,
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
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
                height: MediaQuery.of(context).size.height * 0.5,
                margin: EdgeInsets.all(10.0),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.deepPurple,
                      child: Text( //Build 1.1.36: Fixed Issue:  RangeError (end): Invalid value: Only valid value is 0: 1
                        (userDisplayName != null && userDisplayName!.isNotEmpty)
                            ? userDisplayName!.substring(0, 1)
                            : "Unknown", // Fallback to "Unknown" if null or empty
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                           userDisplayName ?? "",//'A Raghav Kumar', /// use login user display name
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        Text(
                          userRole ?? "Unknown" ,//'I am Cashier', /// use user role
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
        height: MediaQuery.of(context).size.height * 0.0725,
        width: MediaQuery.of(context).size.width * 0.5,
        margin: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.grey[100],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            Container(
              padding: const EdgeInsets.all(5),
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
                mainAxisSize: MainAxisSize.min,
                //mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Icon(Icons.chevron_left, size: 20),
                  BackButton(
                    style: ButtonStyle(
                        alignment: Alignment.centerLeft,
                        iconSize: WidgetStatePropertyAll(16.0)
                    ),
                  ),
                  //const SizedBox(width: 8),
                  Text('Back', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Date and Time Container
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 14),
                const SizedBox(width: 4),
                Text(
                    DateFormat("EEE, MMM d' ${DateTime.now().year}'").format(DateTime.now()),//'Sunday, 16 March 2025',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Time
            Row(
              children: [
                Icon(Icons.access_time, size: 14),
                const SizedBox(width: 4),
                Text(
                  DateFormat('hh:mm a').format(DateTime.now()),//'11:41 A.M',
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
        //width: MediaQuery.of(context).size.width * 100,
        margin: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
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
              Container(
                height: MediaQuery.of(context).size.height * 0.34,
                margin: EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: EdgeInsets.only(left: 15, right: 15,top: 5),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    // Order calculations
                    _buildOrderCalculation(TextConstants.subTotalText, '\$${getSubTotal()}',
                        isTotal: true),
                    _buildOrderCalculation(TextConstants.taxText , '\$0.0'),
                    _buildOrderCalculation(TextConstants.discount, '-\$0.0',
                        isDiscount: true),
                    SizedBox(height: 3,),
                      DottedLine(),
                    SizedBox(height: 3,),
                    _buildOrderCalculation(TextConstants.total, '\$${getSubTotal()}', isTotal: true),
                    _buildOrderCalculation(TextConstants.payByCash, '\$0.0'),
                    _buildOrderCalculation(TextConstants.payByOther, '\$0.0'),
                    _buildOrderCalculation(TextConstants.tenderAmount, '\$0.0'),
                    _buildOrderCalculation(TextConstants.change, '\$0.0'),
                  ],
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
          orderDateTime = "${orderData.first[AppDBConst.orderDate]} ${orderData.first[AppDBConst.orderTime]}" ;
          if (kDebugMode) {
            print("Fetched orderServerId: $orderId for activeOrderId: ${orderHelper.activeOrderId}, Time: $orderDateTime");
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
        balanceAmount = total;
        tenderAmount = 0.0; // Reset for new order
        changeAmount = 0.0; // Reset for new order
        paidAmount = 0.0; // Reset for new order
      });
    } else {
      setState(() {
        orderItems.clear();
        balanceAmount = 0.0;
        tenderAmount = 0.0; // Reset
        changeAmount = 0.0; // Reset
        paidAmount = 0.0; // Reset
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
    // //Build #1.0.34: Update the amount based on the label
    if (label == TextConstants.tenderAmount) {
      amount = '\$${tenderAmount.toStringAsFixed(2)}';
    } else if (label == TextConstants.change) {
      amount = '\$${changeAmount.toStringAsFixed(2)}';
    } else if (label == TextConstants.total) {
      amount = '\$${getSubTotal().toStringAsFixed(2)}';
    } else if (label == TextConstants.payByCash) { //Build 1.1.36: added pay by cash data also
      amount = selectedPaymentMethod == TextConstants.cash
          ? '\$${paidAmount.toStringAsFixed(2)}'
          : '\$0.0';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                fontSize: isTotal ? 14 : 12,
                color: isTotal ? Colors.black87 : Colors.grey[700],
                //height: 1,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                fontSize: isTotal ? 14 : 12,
                color: isDiscount
                    ? Colors.green[600]
                    : (isTotal ? Colors.black87 : Colors.grey[800]),
                //height: 1,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,/// if not required remove it
                children: [
                  // Payment amount display row
                  // Update _buildAmountDisplay in _buildPaymentSection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12.0 , ///20.0
                    children: [
                      _buildAmountDisplay(
                        TextConstants.balanceAmount,
                        '\$${balanceAmount.toStringAsFixed(2)}',//'\$${getSubTotal()}',
                        amountColor: Colors.red,
                      ),
                      _buildAmountDisplay(
                        TextConstants.tenderAmount,
                        '\$${tenderAmount.toStringAsFixed(2)}', // Build #1.0.33
                      ),
                      _buildAmountDisplay(
                        TextConstants.change,
                        '\$${changeAmount.toStringAsFixed(2)}', // Build #1.0.33 :
                        amountColor: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Payment methods
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cash payment section
                            Container(
                             // width: MediaQuery.of(context).size.width * 0.75,
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
                                    height: MediaQuery.of(context).size.height * 0.05,
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(top: 7.0,left: 7.0),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      TextConstants.cashPayment,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Amount TextField
                                  Container(
                                    height: MediaQuery.of(context).size.height * 0.06,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: TextField(
                                      controller: amountController,//_paymentController,
                                      readOnly: true,
                                      // textAlignVertical: TextAlignVertical.center,
                                      textAlign: TextAlign.right,
                                      enabled: false, // Disables interaction with the TextField
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.only(right: 16),
                                        border: InputBorder.none,
                                        hintText: '\$0.00',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],///800
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
                                  const SizedBox(height: 8),

                                  // Quick amount buttons
                                  // Update the Row in _buildPaymentSection to use dynamic quick amounts
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildQuickAmountButton('\$${balanceAmount.toStringAsFixed(0)}'), // Match balance amount
                                      _buildQuickAmountButton('\$${(balanceAmount + 2).toStringAsFixed(0)}'), // Slightly above
                                      _buildQuickAmountButton('\$${(balanceAmount + 12).toStringAsFixed(0)}'), // More above
                                      _buildQuickAmountButton('\$${((balanceAmount ~/ 10 + 1) * 10).toStringAsFixed(0)}'), // Round up to next 10
                                      _buildQuickAmountButton('\$${((balanceAmount ~/ 50 + 1) * 50).toStringAsFixed(0)}'), // Round up to next 50
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Here you would use your custom numpad widget
                                  // CustomNumpad(useCashLayout: true),
                                  // Build #1.0.29:  Update CustomNumPad code
                                  // Update CustomNumPad usage in _buildPaymentSection
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
                                    onPayPressed: () { //Build #1.0.34: updated code
                                      String paidAmount = amountController.text;
                                      String cleanAmount = paidAmount.replaceAll('\$', '').trim();
                                      double amount = double.tryParse(cleanAmount) ?? 0.0;

                                      if (amount == 0.0) {
                                        if (kDebugMode) {
                                          print("Invalid amount entered");
                                        }
                                        return;
                                      }

                                      _callCreatePaymentAPI(); // create payment api call
                                    },
                                    isLoading: isLoading, // Pass isLoading
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
                        style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                      SizedBox(height: 10,),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.175,
                        height: MediaQuery.of(context).size.height * 0.425,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          children: [
                            _buildPaymentModeButton(TextConstants.cash, Icons.money,
                                isSelected:  selectedPaymentMethod == TextConstants.cash, onTap: () {
                              setState(() {
                                selectedPaymentMethod = TextConstants.cash;
                              });
                            }),
                            const SizedBox(height: 20),
                            _buildPaymentModeButton(TextConstants.card, Icons.credit_card, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.card;
                          });
                        }),
                            const SizedBox(height: 20),
                            _buildPaymentModeButton(TextConstants.wallet, Icons.account_balance_wallet, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.wallet;
                          });
                        }),
                            const SizedBox(height: 20),
                            _buildPaymentModeButton(TextConstants.ebtText , Icons.payment, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.ebtText;
                          });
                        }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        width: MediaQuery.of(context).size.width * 0.175,
                        height: MediaQuery.of(context).size.height * 0.28,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          children: [_buildPaymentOptionButton(TextConstants.redeemPoints, Icons.stars),
                            const SizedBox(height: 20),
                            _buildPaymentOptionButton(
                                TextConstants.manualDiscount, Icons.discount),
                            const SizedBox(height: 20),
                            _buildPaymentOptionButton(
                                TextConstants.giftReceipt, Icons.card_giftcard),
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
    var size  = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Container(
          width: size.width * 0.125,
          height: size.height * 0.06,
          padding: const EdgeInsets.all(5),
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
        height:  MediaQuery.of(context).size.height * 0.06,
        width: MediaQuery.of(context).size.width * 0.06,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          color: Color(0xFFBFF1C0),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentModeButton(String label, IconData icon,
      {bool isSelected = false, VoidCallback? onTap}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.1,
      height: MediaQuery.of(context).size.height * 0.075,
      padding: const EdgeInsets.symmetric(vertical: 10),
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
          Icon(icon, color: isSelected ? Colors.red : Colors.grey,size: 25,),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                color: isSelected ? Colors.red : Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 14,

              )),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionButton(String label, IconData icon) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.062,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey, size: 12,),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  //Build #1.0.34: moved Dialog's code from custom numpad
  void _showPartialPaymentDialog(BuildContext context, double amount) {
    if (kDebugMode) {
      print("Showing Partial Payment Dialog with amount: $amount, Remaining Balance: $balanceAmount");
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        status: PaymentStatus.partial,
        mode: PaymentMode.cash,
        amount: amount,
        onVoid: () {
          if (kDebugMode) {
            print("Void partial payment");
          }
          Navigator.of(context).pop();
        },
        onNextPayment: () {
          if (kDebugMode) {
            print("Proceeding to next payment");
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context,
      double amount, {
        double? changeAmount,
        required bool showChange,
      }) {
    if (kDebugMode) {
      print("Showing Payment Dialog: amount=$amount, showChange=$showChange, changeAmount=$changeAmount");
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        status: PaymentStatus.successful,
        mode: PaymentMode.cash,
        amount: amount,
        changeAmount: showChange ? changeAmount : null,
        onVoid: () {
          if (kDebugMode) {
            print("Void successful payment");
          }
          Navigator.of(context).pop();
        },
        onPrint: () {
          if (kDebugMode) {
            print("Print receipt for amount: $amount");
          }
          Navigator.of(context).pop();
          _showReceiptDialog(context, amount);
        },
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        status: PaymentStatus.receipt,
        mode: PaymentMode.cash,
        amount: amount,
        onPrint: () {},
        onEmail: (email) {},
        onSMS: (phone) {},
        onNoReceipt: () {
          Navigator.of(context).pop();
        },
        onDone: () {
          setState(() {
            changeAmount = 0.0; // Reset change after returning
            if (balanceAmount == 0) tenderAmount = 0.0; // Reset tender if order is fully paid
          });
          Navigator.of(context).pop();
        },
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
