import 'dart:async';
import 'dart:io';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:pinaka_pos/Helper/Extentions/extensions.dart';
import 'package:pinaka_pos/Utilities/printer_settings.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_column.dart';

import '../../Blocs/Orders/order_bloc.dart';
import '../../Blocs/Payment/payment_bloc.dart';
import '../../Constants/text.dart';
import '../../Database/db_helper.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Helper/api_response.dart';
import '../../Models/Payment/payment_model.dart';
import '../../Models/Payment/void_payment_model.dart';
import '../../Repositories/Orders/order_repository.dart';
import '../../Repositories/Payment/payment_repository.dart';
import '../../Utilities/responsive_layout.dart';
import '../../Utilities/result_utility.dart';
import '../../Widgets/widget_custom_num_pad.dart';
import '../../Widgets/widget_payment_dialog.dart';
import 'Settings/printer_setup_screen.dart';
import 'edit_product_screen.dart';

import 'package:thermal_printer/thermal_printer.dart';

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
  var _printerSettings =  PrinterSettings();
  List<int> bytes = [];
  String? paymentId; // To store the transaction ID after wallet payment
  late OrderBloc orderBloc;

  @override
  void initState() {
    super.initState();
    orderBloc = OrderBloc(OrderRepository()); // Build #1.0.49
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

            // Capture paymentId for wallet payments
            if (selectedPaymentMethod == TextConstants.wallet) {
            //  paymentId = paymentData.paymentId; // Assuming the API response includes paymentId
              paymentId = "TXT_123456789"; // For testing purpose added here
              if (kDebugMode) {
                print("Wallet payment successful. Transaction ID: $paymentId");
              }
            }

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
    ResponsiveLayout.init(context);
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
      height: ResponsiveLayout.getHeight(60),
      color: Colors.grey[100],
      padding: ResponsiveLayout.getResponsivePadding(
        horizontal: 16,
        vertical: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pinaka logo with triangle above it
          SvgPicture.asset(
            'assets/svg/app_icon.svg',
            height: ResponsiveLayout.getHeight(40),
            width: ResponsiveLayout.getWidth(40),
          ),

          // User profile section with container and notification bell
          Row(
            children: [
              Container(
                height: ResponsiveLayout.getHeight(45),  //45
                margin:  EdgeInsets.all(ResponsiveLayout.getPadding(10)),
                padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveLayout.getPadding(16),
                    vertical: 0
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(15)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: ResponsiveLayout.getRadius(18),
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                          (userDisplayName ?? "Unknown").substring(0,1),//"A", /// use initial for the login user
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveLayout.getFontSize(14)),
                      ),
                    ),
                    SizedBox(width: ResponsiveLayout.getWidth(12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                           userDisplayName ?? "",//'A Raghav Kumar', /// use login user display name
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: ResponsiveLayout.getFontSize(14)),
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
              SizedBox(width: ResponsiveLayout.getWidth(16)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(ResponsiveLayout.getPadding(10)),
                child: Icon(
                  Icons.notifications_outlined,
                  size: ResponsiveLayout.getIconSize(24),
                ),
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
        height: ResponsiveLayout.getHeight(52),
        width: ResponsiveLayout.getWidth(640),
        margin: EdgeInsets.all(ResponsiveLayout.getPadding(20)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
          color: Colors.grey[100],
        ),
        padding: EdgeInsets.symmetric(
            horizontal: ResponsiveLayout.getPadding(6),
            vertical: ResponsiveLayout.getPadding(6)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            Container(
              padding: EdgeInsets.all(ResponsiveLayout.getPadding(5)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(8)),
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
                        iconSize: WidgetStatePropertyAll(ResponsiveLayout.getIconSize(16))
                    ),
                    onPressed: () {
                      _showExitPaymentConfirmation(context);
                      },
                  ),
                  //const SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(fontSize: ResponsiveLayout.getFontSize(14)),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveLayout.getWidth(16)),

            // Date and Time Container
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: ResponsiveLayout.getIconSize(14),),
                SizedBox(width: ResponsiveLayout.getWidth(4)),
                Text(
                    DateFormat("EEE, MMM d' ${DateTime.now().year}'").format(DateTime.now()),//'Sunday, 16 March 2025',
                  style: TextStyle(color: Colors.grey[700],
                    fontSize: ResponsiveLayout.getFontSize(12),
                  ),

                ),
              ],
            ),
                SizedBox(width: ResponsiveLayout.getWidth(10)),
            // Time
            Row(
              children: [
                Icon(Icons.access_time, size: ResponsiveLayout.getIconSize(14),),
                SizedBox(width: ResponsiveLayout.getWidth(4)),
                Text(
                  DateFormat('hh:mm a').format(DateTime.now()),//'11:41 A.M',
                  style: TextStyle(
                      color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: ResponsiveLayout.getFontSize(12)),
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
        margin: EdgeInsets.only(
            left: ResponsiveLayout.getPadding(20),
            right: ResponsiveLayout.getPadding(20),
            bottom: ResponsiveLayout.getPadding(20)
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
          color: Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveLayout.getPadding(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Payment Summary header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${TextConstants.orderId} #$orderId', // Build #1.0.29: orderId(serverId) from db
                    style: TextStyle(
                      fontSize: ResponsiveLayout.getFontSize(16),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    TextConstants.paymentSummary,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: ResponsiveLayout.getFontSize(12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveLayout.getHeight(16)),

              // Order items list
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
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
                height: ResponsiveLayout.getHeight(240),
                margin: EdgeInsets.only(top: ResponsiveLayout.getPadding(5)),  //ResponsiveLayout.getHeight(5)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding:  EdgeInsets.only(
                    left: ResponsiveLayout.getPadding(15),
                    right: ResponsiveLayout.getPadding(15),
                    top: ResponsiveLayout.getPadding(5)
                ),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    // Order calculations
                    _buildOrderCalculation(TextConstants.subTotalText, '\$${getSubTotal()}',
                        isTotal: true),
                    _buildOrderCalculation(TextConstants.taxText , '\$0.0'),
                    _buildOrderCalculation(TextConstants.discount, '-\$0.0',
                        isDiscount: true),
                    SizedBox(height: ResponsiveLayout.getHeight(3)),
                    DottedLine(),
                    SizedBox(height: ResponsiveLayout.getHeight(3)),
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
      padding: ResponsiveLayout.getResponsivePadding(
        vertical: 10,
        horizontal: 12,
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: ResponsiveLayout.getWidth(50),
            height: ResponsiveLayout.getHeight(50),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(8)),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect( // Build #1.0.13 : updated images from db not static default images
              borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
              child: orderItem[AppDBConst.itemImage].toString().startsWith('http')
                  ? Image.network(
                orderItem[AppDBConst.itemImage],
                height: ResponsiveLayout.getHeight(30),
                width: ResponsiveLayout.getWidth(30),
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return SvgPicture.asset(
                    'assets/svg/password_placeholder.svg',
                    height: ResponsiveLayout.getHeight(30),
                    width: ResponsiveLayout.getWidth(30),
                    fit: BoxFit.cover,
                  );
                },
              )
                  : orderItem[AppDBConst.itemImage]
                  .toString()
                  .startsWith('assets/')
                  ? SvgPicture.asset(
                orderItem[AppDBConst.itemImage],
                height: ResponsiveLayout.getHeight(30),
                width: ResponsiveLayout.getWidth(30),
                fit: BoxFit.cover,
              )
                  : Image.file(
                File(orderItem[AppDBConst.itemImage]),
                height: ResponsiveLayout.getHeight(30),
                width: ResponsiveLayout.getWidth(30),
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return SvgPicture.asset(
                    'assets/svg/password_placeholder.svg',
                    height: ResponsiveLayout.getHeight(30),
                    width: ResponsiveLayout.getWidth(30),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: ResponsiveLayout.getWidth(12)),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderItem[AppDBConst.itemName],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveLayout.getFontSize(16),
                  ),
                ),
                // Text(
                //   '(350ml)',
                //   style: TextStyle(
                //     color: Colors.grey,
                //     fontSize: 14,
                //   ),
                // ),
                SizedBox(height: ResponsiveLayout.getHeight(4)),
                Text(
                  "${orderItem[AppDBConst.itemCount]} * \$${orderItem[AppDBConst.itemPrice]}", // Build #1.0.12: now item count will update in order panel
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: ResponsiveLayout.getFontSize(14),
                  ),
                ),
              ],
            ),
          ),

          // Price
          Text(
            "\$${(orderItem[AppDBConst.itemCount] * orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveLayout.getFontSize(16),
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
      margin: EdgeInsets.symmetric(vertical: ResponsiveLayout.getPadding(4)),  //ResponsiveLayout.getResponsiveMargin(vertical: 4),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.getPadding(4)), //EdgeInsets.symmetric(horizontal: ResponsiveLayout.getPadding(4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                fontSize: ResponsiveLayout.getFontSize(isTotal ? 14 : 12),
                color: isTotal ? Colors.black87 : Colors.grey[700],
                //height: 1,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                fontSize: ResponsiveLayout.getFontSize(isTotal ? 14 : 12),
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
      margin: EdgeInsets.only(
        bottom: ResponsiveLayout.getPadding(20),
        right: ResponsiveLayout.getPadding(20),
        top: ResponsiveLayout.getPadding(20),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
        color: Colors.grey[100],
      ),
      child: Padding(
        padding: EdgeInsets.only(
            left: ResponsiveLayout.getPadding(20),
            right: ResponsiveLayout.getPadding(20),
            top: ResponsiveLayout.getPadding(15),
            bottom: 0
        ),
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
                    spacing: ResponsiveLayout.getWidth(12), ///20.0
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

                  SizedBox(height: ResponsiveLayout.getHeight(12)),

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
                              padding: EdgeInsets.all(ResponsiveLayout.getPadding(16)),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(8)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Label container
                                  Container(
                                    height: ResponsiveLayout.getHeight(36),
                                    width: double.infinity,
                                    padding: EdgeInsets.only(
                                        top: ResponsiveLayout.getPadding(7),
                                        left: ResponsiveLayout.getPadding(7)
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(6)),
                                    ),
                                    child: Text(
                                      TextConstants.cashPayment,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                        fontSize: ResponsiveLayout.getFontSize(12),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveLayout.getHeight(8)),

                                  // Amount TextField
                                  Container(
                                    height: ResponsiveLayout.getHeight(43),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(6)),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: TextField(
                                      controller: amountController,//_paymentController,
                                      readOnly: true,
                                      // textAlignVertical: TextAlignVertical.center,
                                      textAlign: TextAlign.right,
                                      enabled: false, // Disables interaction with the TextField
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(right: ResponsiveLayout.getPadding(16)),
                                        border: InputBorder.none,
                                        hintText: '\$0.00',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],///800
                                          fontSize: ResponsiveLayout.getFontSize(20),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: ResponsiveLayout.getFontSize(20),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      keyboardType: TextInputType.none, // Hide default keypad
                                      onTap: () {
                                        FocusScope.of(context).unfocus(); // Hide keypad
                                      },
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveLayout.getHeight(8)),

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

                                  SizedBox(height: ResponsiveLayout.getHeight(12)),

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
                      SizedBox(width: ResponsiveLayout.getWidth(16)),

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
                      Text(
                        TextConstants.selectPaymentMode,
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveLayout.getHeight(10)),
                      Container(
                        width: ResponsiveLayout.getWidth(224),
                        height: ResponsiveLayout.getHeight(306),
                        padding: EdgeInsets.all(ResponsiveLayout.getPadding(5)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(5)),
                        ),
                        child: Column(
                          children: [
                            _buildPaymentModeButton(TextConstants.cash, Icons.money,
                                isSelected:  selectedPaymentMethod == TextConstants.cash, onTap: () {
                              setState(() {
                                selectedPaymentMethod = TextConstants.cash;
                              });
                            }),
                            SizedBox(height: ResponsiveLayout.getHeight(20)),
                            _buildPaymentModeButton(TextConstants.card, Icons.credit_card, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.card;
                          });
                        }),
                            SizedBox(height: ResponsiveLayout.getHeight(20)),
                            _buildPaymentModeButton(TextConstants.wallet, Icons.account_balance_wallet, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.wallet;
                          });
                        }),
                            SizedBox(height: ResponsiveLayout.getHeight(20)),
                            _buildPaymentModeButton(TextConstants.ebtText, Icons.payment, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.ebtText;
                          });
                        }),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveLayout.getHeight(15)),

                      Container(
                        width: ResponsiveLayout.getWidth(224),
                        height: ResponsiveLayout.getHeight(202),
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),//ResponsiveLayout.getResponsivePadding(all: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(5)),
                        ),
                        child: Column(
                          children: [_buildPaymentOptionButton(TextConstants.redeemPoints, Icons.stars),
                            SizedBox(height: ResponsiveLayout.getHeight(20)),
                            _buildPaymentOptionButton(
                                TextConstants.manualDiscount, Icons.discount),
                            SizedBox(height: ResponsiveLayout.getHeight(20)),
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
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveLayout.getFontSize(12),
            color: Colors.black54
          ),
        ),
        SizedBox(height: ResponsiveLayout.getHeight(4)),
        Container(
          width: ResponsiveLayout.getWidth(128),
          height: ResponsiveLayout.getHeight(43),
          padding: EdgeInsets.all(ResponsiveLayout.getPadding(5.0)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(8)),
          ),
          child: Text(
            amount,
            style: TextStyle(
              fontSize: ResponsiveLayout.getFontSize(18),
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
        height: ResponsiveLayout.getHeight(43),
        width: ResponsiveLayout.getWidth(64),
        alignment: Alignment.center,
        padding: EdgeInsets.all(ResponsiveLayout.getPadding(5.0)),
        decoration: BoxDecoration(
          color: Color(0xFFBFF1C0),
          borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(5)),
        ),
        child: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveLayout.getFontSize(14),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentModeButton(String label, IconData icon,
      {bool isSelected = false, VoidCallback? onTap}) {
    return Container(
      width: ResponsiveLayout.getWidth(128),
      height: ResponsiveLayout.getHeight(54),
      padding: ResponsiveLayout.getResponsivePadding(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(5)),
        border: isSelected ? Border.all(color: Colors.red.shade300) : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.red : Colors.grey,
            size: ResponsiveLayout.getIconSize(25),
          ),
          SizedBox(width: ResponsiveLayout.getWidth(8)),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.red : Colors.grey,
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveLayout.getFontSize(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionButton(String label, IconData icon) {
    return Container(
      height: ResponsiveLayout.getHeight(45),
      padding: ResponsiveLayout.getResponsivePadding(
        vertical: 5,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(8)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.grey,
            size: ResponsiveLayout.getIconSize(12),),
          SizedBox(width: ResponsiveLayout.getWidth(8)),
          Text(label, style: TextStyle(color: Colors.grey, fontSize: ResponsiveLayout.getFontSize(12))),
        ],
      ),
    );
  }

  // Build #1.0.49: Added _handleVoidPayment for void payment api call code
  void _handleVoidPayment(BuildContext context) {
    if (orderId == null || orderId == 0) {
      if (kDebugMode) {
        print("Invalid order ID: $orderId. Cannot void transaction.");
      }
      Navigator.of(context).pop(); // Close the dialog
      return;
    }

    if (kDebugMode) {
      print("Void payment for order ID: $orderId");
    }

    final request = VoidPaymentRequestModel(
      orderId: orderId!,
      paymentId: selectedPaymentMethod == TextConstants.wallet ? paymentId ?? "" : "",
    );

    paymentBloc.voidPayment(request);
    StreamSubscription? subscription;
    subscription = paymentBloc.voidPaymentStream.listen((response) {
      if (response.status == Status.COMPLETED) {
        if (kDebugMode) {
          print("Void successful: ${response.data!.message}");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data!.message ?? "",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/previousScreen');
      } else if (response.status == Status.ERROR) {

        if (kDebugMode) {
          print("Void failed: ${response.data!.message}");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data!.message ?? "",
              style: const TextStyle(color: Colors.red),
            ),
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(); // Close the dialog
      }
      subscription?.cancel();
    });
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
        onVoid: () => _showVoidExitConfirmation(context),
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
        onVoid: () => _showVoidExitConfirmation(context),
        onPrint: () {
          if (kDebugMode) {
            print("Print receipt for amount: $amount");
          }
          Navigator.of(context).pop();
          _showReceiptDialog(context, amount);
          _preparePrintTicket();
        },
      ),
    );
  }

  Future _preparePrintTicket() async{
    if (kDebugMode) {
      print("OrderSummaryScreen _preparePrintTicket call print receipt");
    }
    bytes = [];

    final ticket =  await _printerSettings.getTicket();
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

    for(int i = 0; i< orderItems.length; i++) {

      var orderItem = orderItems[i];
      if (kDebugMode) {
        print(" >>>>> Adding item ${orderItem[AppDBConst.itemName]} to print");
      }

      bytes += ticket.row([
        PosColumn(text: "${i+1}", width: 1),
        PosColumn(text: "${orderItem[AppDBConst.itemName]}", width:5),
        PosColumn(text: "${orderItem[AppDBConst.itemCount]}", width: 1),
        PosColumn(text: "${orderItem[AppDBConst.itemPrice]}", width:2),
        PosColumn(text: "0.0", width: 1),
        PosColumn(text: "${orderItem[AppDBConst.itemSumPrice]}", width: 2),
      ]);
      // bytes += ticket.feed(1);
    }
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
        });
        break;
    }
  }

  Future _printCustomTest() async {
    if (kDebugMode) {
      print("OrderSummaryScreen _printCustomTest call print reciept");
    }
    List<int> bytes = [];

    final ticket =  await _printerSettings.getTicket();
    bytes += ticket.row([
      PosColumn(text: "#", width: 1),
      PosColumn(text: "Description", width:5),
      PosColumn(text: "Qty", width: 1),
      PosColumn(text: "Rate", width: 2),
      PosColumn(text: "Dis", width: 1),
      PosColumn(text: "Amt", width: 2),
    ]);
    bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: "1", width: 1),
      PosColumn(text: "Shan Haleem Masala Mix", width:5),
      PosColumn(text: "1.0", width: 1),
      PosColumn(text: "420.0", width:2),
      PosColumn(text: "0.0", width: 1),
      PosColumn(text: "420.0", width: 2),
    ]);
    bytes += ticket.row([PosColumn(text: "sfgasa sdfasdfasdf asdfasdfasdfsdfasdfasdf adfasdfasdfasdf", width: 12),]);
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
        });
        break;
    }
  }

  void _showReceiptDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        status: PaymentStatus.receipt,
        mode: PaymentMode.cash,
        amount: amount,
        onPrint: () {
         /// radio button
        },
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
          // Navigator.of(context).pop();
          if (kDebugMode) {
            print("OrderSummaryScreen _showReceiptDialog Done call print reciept");
          }
          // _printCustomTest();
          _printTicket();
          ///ToDO: Change the status of order to 'completed' here
          // Build #1.0.49: Added Call Order Status Update API code
          orderBloc.changeOrderStatus(orderId: orderId!, status: TextConstants.completed);
          StreamSubscription? subscription;
          subscription = orderBloc.changeOrderStatusStream.listen((response) {
            if (response.status == Status.COMPLETED) {
              if (kDebugMode) {
                print("OrderPanel - Order #@# $orderId, successfully completed");
              }

              Navigator.of(context).pop(); // dismiss dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    TextConstants.orderCompleted,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.black,
                  duration: const Duration(seconds: 3),
                ),
              );
              // Optionally refresh UI or remove tab
             // fetchOrderItems();
            } else if (response.status == Status.ERROR) {
              if (kDebugMode) {
                print("OrderPanel - completed failed: ${response.message}");
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    response.message ?? "Failed to complete order",
                    style: const TextStyle(color: Colors.red),
                  ),
                  backgroundColor: Colors.black,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            subscription?.cancel();
          });
        },
      ),
    );
  }

  // Build #1.0.49: _showVoidExitConfirmation
  void _showVoidExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog.voidConfirmation(
        onVoidCancel: () {
          Navigator.of(context).pop(); // Dismiss the confirm dialog
          Navigator.of(context).pop(); // Dismiss the main dialog
        },
        onVoidConfirm: () {
          _handleVoidPayment(context); // Call void payment logic
        },
      ),
    );
  }

  void _showExitPaymentConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (context) => PaymentDialog(
           status: PaymentStatus.exitConfirmation,

          onExitCancel: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          onExitConfirm: () {
            // Delay navigation to avoid calling during build
/// below code is not required use it for testing only
              // Navigator.of(context).pop(); // Close the dialog
              // Future.delayed(Duration(milliseconds: 100));
              // Navigatorgator.of(context).pop(); // Go back to previous screen
/// issue with navigation is fixed using below
            // Build #1.0.49: issue fixed -> Use popUntil to dismiss both dialogs and go back
            Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/previousScreen'); // Adjust route condition as needed
            //   Navigator.of(context).pop(); // Close the dialog
            //   Navigator.of(context).pop(); // Go back to previous screen

              // Additional cleanup logic can be added here
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
