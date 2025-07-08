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
import 'package:provider/provider.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;


import '../../Blocs/Orders/order_bloc.dart';
import '../../Blocs/Payment/payment_bloc.dart';
import '../../Constants/text.dart';
import '../../Database/db_helper.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Helper/Extentions/theme_notifier.dart';
import '../../Helper/api_response.dart';
import '../../Models/Payment/payment_model.dart';
import '../../Models/Payment/void_payment_model.dart';
import '../../Repositories/Orders/order_repository.dart';
import '../../Repositories/Payment/payment_repository.dart';
import '../../Utilities/responsive_layout.dart';
import '../../Utilities/result_utility.dart';
import '../../Widgets/widget_custom_num_pad.dart';
import '../../Widgets/widget_payment_dialog.dart';
import 'Settings/image_utils.dart';
import 'Settings/printer_setup_screen.dart';
import 'edit_product_screen.dart';

import 'package:thermal_printer/thermal_printer.dart';

import 'fast_key_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  int? userId; // Build #1.0.29: To store user ID
  String? userDisplayName; // Build #1.0.29: To store user ID
  String? userRole;
  int? orderId; // server id from order table
  String? orderDateTime = "";
  int shiftId = 1; // Hardcoded as per requirement
  int vendorId = 1; // Hardcoded as per requirement
  String serviceType = "default"; // Hardcoded as per requirement
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
  StreamSubscription? _paymentListSubscription;
  bool isLoading = false; // Add this to track loading state
  bool isSummaryLoading = false;
  // final TextEditingController _paymentController = TextEditingController();
  var _printerSettings =  PrinterSettings();
  List<int> bytes = [];
  String? paymentId; // To store the transaction ID after wallet payment
  late OrderBloc orderBloc;
  bool _showFullSummary = false;

  @override
  void initState() {
    super.initState();
    orderBloc = OrderBloc(OrderRepository()); // Build #1.0.49
    fetchOrderItems();
    _fetchUserId();

  }

  @override
  void dispose() { //Build #1.0.99: Added Dispose
    _paymentListSubscription?.cancel();
    paymentBloc.dispose();
    _scrollController.dispose();
    amountController.dispose();
    super.dispose();
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

  //Build #1.0.99: getPaymentsByOrderId API call for payment by cash and payment by other details
  void _fetchPaymentsByOrderId() {
    if (kDebugMode) {
      print("###### _fetchPaymentsByOrderId");
    }
    if (orderId != null) {
      setState(() {
        isSummaryLoading = true; // Show loader
      });
      paymentBloc.getPaymentsByOrderId(orderId!);
      _paymentListSubscription = paymentBloc.paymentsListStream.listen((response) {
        if (response.status == Status.COMPLETED) {
          if (kDebugMode) {
            print("###### _fetchPaymentsByOrderId Api call COMPLETED");
          }
          _processPaymentList(response.data!);
        } else if (response.status == Status.ERROR) {
          if (kDebugMode) {
            print("Error fetching payments: ${response.message}");
          }
        }
        setState(() {
          isSummaryLoading = false; // Hide loader
        });
      });
    }else{
      if (kDebugMode) {
        print("###### orderId is null");
      }
    }
  }

  //Build #1.0.99: Added new method to process payment list
  void _processPaymentList(List<PaymentListModel> payments) {
    double cashTotal = 0.0;
    double otherTotal = 0.0;

    for (var payment in payments) {
      double amount = double.tryParse(payment.amount) ?? 0.0;
      if (payment.paymentMethod == 'Cash') {
        cashTotal += amount;
      } else {
        otherTotal += amount;
      }
    }

    if (kDebugMode) {
      print("###### _processPaymentList ->>> payByCash: $cashTotal, payByOther: $otherTotal");
    }
    setState(() {
      payByCash = cashTotal;
      payByOther = otherTotal;
    });
  }

  // void fetchOrderItems() async {
  //   // TODO: Implement actual data fetching from database
  //   setState(() {
  //     // Temporary sample data
  //     orderItems = [];
  //   });
  // }
  void _toggleSummary() {
    setState(() {
      _showFullSummary = !_showFullSummary;
    });
  }

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

    String cleanAmount = amountController.text.replaceAll('${TextConstants.currencySymbol}', '').trim();
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
            // Build #1.0.99: Call fetch payment details by order id API call
            _fetchPaymentsByOrderId(); // Refresh payments after successful payment

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
    final theme = Theme.of(context);
    final themeHelper = Provider.of<ThemeNotifier>(context);
    ResponsiveLayout.init(context);
    return Scaffold(
      backgroundColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
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
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      height: ResponsiveLayout.getHeight(60),
      color: themeHelper.themeMode == ThemeMode.dark ?ThemeNotifier.primaryBackground : Colors.grey[100],
      padding: ResponsiveLayout.getResponsivePadding(
        horizontal: 16,
        vertical: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Pinaka logo with triangle above it
          SvgPicture.asset(
            themeHelper.themeMode == ThemeMode.dark ? 'assets/svg/app_logo.svg' : 'assets/svg/app_icon.svg',
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
                  color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
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
                              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
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
                  color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
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
    final themeHelper = Provider.of<ThemeNotifier>(context);
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: ResponsiveLayout.getHeight(52),
        width: ResponsiveLayout.getWidth(640),
        margin: EdgeInsets.only(
          left: ResponsiveLayout.getPadding(20),
          right: ResponsiveLayout.getPadding(20),
          top: ResponsiveLayout.getPadding(20),
          bottom: ResponsiveLayout.getPadding(15),

        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.appBarBackground : Colors.grey[100],
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
                color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground :Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(8)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      spreadRadius: 1),
                ],
              ),
              child: Row(
                //mainAxisSize: MainAxisSize.min,
                //mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon(Icons.chevron_left, size: 20),
                  BackButton(
                    style: ButtonStyle(
                        alignment: Alignment.centerLeft,
                        iconSize: WidgetStatePropertyAll(ResponsiveLayout.getIconSize(20))
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
                  style: TextStyle(color: theme.secondaryHeaderColor,
                    fontSize: ResponsiveLayout.getFontSize(14),
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
                      color: theme.secondaryHeaderColor, fontWeight: FontWeight.bold, fontSize: ResponsiveLayout.getFontSize(14)),
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
    final themeHelper = Provider.of<ThemeNotifier>(context);
    final theme = Theme.of(context);
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
          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : Colors.grey[100],
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
          padding: EdgeInsets.only(
              left: ResponsiveLayout.getPadding(15),
            right: ResponsiveLayout.getPadding(15),
            bottom: ResponsiveLayout.getPadding(15),
            top: ResponsiveLayout.getPadding(10)
          ),
          child: isSummaryLoading //Build #1.0.99
          ? Center(child: CircularProgressIndicator())
              : Column(
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
                      color: themeHelper.themeMode == ThemeMode.dark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    TextConstants.paymentSummary,
                    style: TextStyle(
                      color:themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark :Colors.grey[600],
                      fontSize: ResponsiveLayout.getFontSize(12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveLayout.getHeight(8)),

              // Order items list
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
                    color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
                    border: Border.all(color:themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor : Colors.grey.shade200),
                  ),
                  child: Scrollbar(
                   controller: _scrollController,
                    scrollbarOrientation: ScrollbarOrientation.right,
                    thumbVisibility: true,
                    thickness: 8.0,
                    interactive: false,
                    radius: const Radius.circular(8),
                    trackVisibility: true,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: orderItems.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final orderItem = orderItems[index];
                        final itemType = orderItem[AppDBConst.itemType]?.toString().toLowerCase() ?? '';
                        final isPayout = itemType.contains(TextConstants.payoutText);
                        final isCoupon = itemType.contains(TextConstants.couponText);
                        final isCustomItem = itemType.contains(TextConstants.customItemText);
                        final isPayoutOrCouponOrCustomItem = isPayout || isCoupon || isCustomItem;
                        return _buildOrderItem(index);
                      },
                    ),
                  ),
                ),
              ),

              // Bottom summary container
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
                color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
                ),
                //padding: EdgeInsets.all(5),
                margin: EdgeInsets.only(top: ResponsiveLayout.getPadding(10)),
                child: AnimatedSize(
                   duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                    child: _showFullSummary
                        ? Container(
                      height: ResponsiveLayout.getHeight(205),
                      margin: EdgeInsets.all(ResponsiveLayout.getPadding(8)),  //ResponsiveLayout.getHeight(5)
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
                      color:themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : Colors.white,
                      border: Border.all(color:themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor : Colors.grey.shade200),
                    ),
                    padding:  EdgeInsets.only(
                        left: ResponsiveLayout.getPadding(8),
                        right: ResponsiveLayout.getPadding(8),
                        //top: ResponsiveLayout.getPadding(5)
                    ),
                    child: Column(
                        //mainAxisSize: MainAxisSize.min,
                      children: [
                        // Order calculations
                        _buildOrderCalculation(TextConstants.grossTotal, '${TextConstants.currencySymbol}${getSubTotal().toStringAsFixed(2)}',
                            isTotal: true),
                        _buildOrderCalculation(TextConstants.discount, '-${TextConstants.currencySymbol}${discount.toStringAsFixed(2)}',
                            isDiscount: true),
                        _buildOrderCalculation(TextConstants.merchantDiscount, '-${TextConstants.currencySymbol}${merchantDiscount.toStringAsFixed(2)}'),
                        _buildOrderCalculation(TextConstants.taxText, '${TextConstants.currencySymbol}${tax.toStringAsFixed(2)}'), // Build #1.0.80: updated tax dynamically
                        //SizedBox(height: ResponsiveLayout.getHeight(3)),
                        DottedLine(),
                        //SizedBox(height: ResponsiveLayout.getHeight(3)),
                        _buildOrderCalculation(TextConstants.netPayable, '${TextConstants.currencySymbol}${balanceAmount.toStringAsFixed(2)}', // Build #1.0.80: updated balance amount dynamically
                            isTotal: true),
                       _buildOrderCalculation(TextConstants.payByCash, '${TextConstants.currencySymbol}${payByCash.toStringAsFixed(2)}'), //Build #1.0.99: updated values from api
                      _buildOrderCalculation(TextConstants.payByOther, '${TextConstants.currencySymbol}${payByOther.toStringAsFixed(2)}'),
                     // _buildOrderCalculation(TextConstants.payByCash, selectedPaymentMethod == TextConstants.cash
                    //     ? '${TextConstants.currencySymbol}${paidAmount.toStringAsFixed(2)}' : '${TextConstants.currencySymbol}${0.0.toStringAsFixed(2)}'),
                     // _buildOrderCalculation(TextConstants.payByOther, selectedPaymentMethod != TextConstants.cash
                    //     ? '${TextConstants.currencySymbol}${paidAmount.toStringAsFixed(2)}' : '${TextConstants.currencySymbol}${0.0.toStringAsFixed(2)}'),
                        _buildOrderCalculation(TextConstants.tenderAmount, '${TextConstants.currencySymbol}${tenderAmount.toStringAsFixed(2)}'),
                        _buildOrderCalculation(TextConstants.change, '${TextConstants.currencySymbol}${changeAmount.toStringAsFixed(2)}'),
                      ],
                      ),
                  )
                  : SizedBox.shrink(),
                ),
              ),
              // Toggle Summary Button
              GestureDetector(
                onTap: _toggleSummary,
                child: Container(
                  margin: EdgeInsets.only(
                    top: _showFullSummary ? ResponsiveLayout.getPadding(2) : ResponsiveLayout.getPadding(8),
                    right: ResponsiveLayout.getPadding(8),
                    left: ResponsiveLayout.getPadding(8),
                    bottom: ResponsiveLayout.getPadding(8),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(ResponsiveLayout.getRadius(10)),
                      bottomLeft: Radius.circular(ResponsiveLayout.getRadius(10)),
                      topLeft: _showFullSummary ? Radius.zero : Radius.circular(ResponsiveLayout.getRadius(10)),
                      topRight: _showFullSummary ? Radius.zero : Radius.circular(ResponsiveLayout.getRadius(10)),
                    ),
                    color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.orderPanelSummary : Colors.grey.shade300,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveLayout.getPadding(8),
                    vertical: ResponsiveLayout.getPadding(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${TextConstants.totalItemsText}: ${orderItems.length}",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),

                      Row(
                        children: [
                          Text(
                            _showFullSummary
                                ? 'Net Payable : ${TextConstants.currencySymbol}${balanceAmount.toStringAsFixed(2)}'
                                : 'Net Payable : ${TextConstants.currencySymbol}${balanceAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                            ),
                          ),
                          SizedBox(width: ResponsiveLayout.getPadding(8)),
                          Icon(
                            _showFullSummary ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                          ),
                        ],
                      ),
                    ],
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
      var orderData = await orderHelper.getOrderById(orderHelper.activeOrderId!);
      List<Map<String, dynamic>> items = await orderHelper.getOrderItems(orderData.first[AppDBConst.orderServerId]);

      //Build #1.0.29:  Fetch the orderServerId from the database
      // final db = await DBHelper.instance.database;
      // final List<Map<String, dynamic>> orderData = await db.query(
      //   AppDBConst.orderTable,
      //   columns: [AppDBConst.orderServerId,
      //   AppDBConst.orderDiscount,
      //   AppDBConst.orderTax,
      //   AppDBConst.merchantDiscount // Build #1.0.80
      //   ],
      //   where: '${AppDBConst.orderId} = ?',
      //   whereArgs: [order.first[AppDBConst.orderServerId]],
      // );

      if (orderData.isNotEmpty) {
        setState(() {
          orderId = orderData.first[AppDBConst.orderServerId] as int? ?? 0;
          orderDateTime = "${orderData.first[AppDBConst.orderDate]} ${orderData.first[AppDBConst.orderTime]}" ;
          discount = (orderData.first[AppDBConst.orderDiscount] as num?)?.toDouble() ?? 0.0; // Fetch discount
          merchantDiscount = (orderData.first[AppDBConst.merchantDiscount] as num?)?.toDouble() ?? 0.0; // Build #1.0.80
          tax = (orderData.first[AppDBConst.orderTax] as num?)?.toDouble() ?? 0.0;
          if (kDebugMode) {
            print("Fetched orderServerId: $orderId, Discount: $discount for activeOrderId: ${orderHelper.activeOrderId}, Time: $orderDateTime");
          }
        });
      } else {
        if (kDebugMode) {
          print("No orderServerId found for activeOrderId: ${orderHelper.activeOrderId}");
        }
      }

      /// Call fetch payment details by order id API call after order id assigned here above, otherwise we get null order id
      _fetchPaymentsByOrderId();

     // Build #1.0.29: Calculate balance amount from order items
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
        balanceAmount = total - discount - merchantDiscount + tax; // Build #1.0.80: Update balance calculation
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
        discount = 0.0; // Reset discount
      });
    }
  }

  Widget _buildOrderItem(int index) {
    var orderItem = orderItems[index];
    final itemType = orderItem[AppDBConst.itemType]?.toString().toLowerCase() ?? '';
    final isPayout = itemType.contains(TextConstants.payoutText);
    final isCoupon = itemType.contains(TextConstants.couponText);
    final isCustomItem = itemType.contains(TextConstants.customItemText);
    final isPayoutOrCouponOrCustomItem = isPayout || isCoupon || isCustomItem;
    final themeHelper = Provider.of<ThemeNotifier>(context);

    final variationName = orderItem[AppDBConst.itemVariationCustomName]?.toString() ?? 'N/A';
    final variationCount = orderItem[AppDBConst.itemVariationCount] ?? 0;
    final combo = orderItem[AppDBConst.itemCombo] ?? '';
    if (kDebugMode) {
      print("#### itemType: $itemType, isPayoutOrCouponOrCustomItem: $isPayoutOrCouponOrCustomItem");
      print("#### variationName: $variationName, variationCount: $variationCount, combo: $combo");
    }
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
    //                             "${orderItem[AppDBConst.itemCount]} * ${TextConstants.currencySymbol}${orderItem[AppDBConst.itemPrice]}",
    //                             style: const TextStyle(color: Colors.black54),
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                     Column(
    //                       mainAxisAlignment: MainAxisAlignment.center,
    //                       children: [
    //                         Text(
    //                           "${TextConstants.currencySymbol}${(orderItem[AppDBConst.itemCount] * orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}",
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
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.08,
        child: Row(
          children: [
            // Product image
            Container(
              width: ResponsiveLayout.getWidth(50),
              height: ResponsiveLayout.getHeight(50),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(8)),
                color:  Colors.grey.shade200,
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
                              text: orderItem[AppDBConst.itemName],
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
                  if (!isPayoutOrCouponOrCustomItem)
                  Text(
                    "${orderItem[AppDBConst.itemCount]} * ${TextConstants.currencySymbol}${orderItem[AppDBConst.itemPrice].toStringAsFixed(2)}", // Build #1.0.12: now item count will update in order panel
                    style: TextStyle(
                      color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.black87,
                      fontSize: ResponsiveLayout.getFontSize(10),
                    ),
                  ),
                ],
              ),
            ),
            // Regular Price
            if (!isPayout)
              Text(
                "${TextConstants.currencySymbol}${orderItem[AppDBConst.itemPrice].toStringAsFixed(2)}",
                style: TextStyle(
                    color: themeHelper.themeMode == ThemeMode.dark
                        ? ThemeNotifier.textDark
                        : Colors.blueGrey,
                    fontSize: 14),
              ),
            SizedBox(width: 20,),
            //  Sale Price
            Text(
              "${TextConstants.currencySymbol}${(orderItem[AppDBConst.itemCount] * orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveLayout.getFontSize(16),
                color: isPayoutOrCouponOrCustomItem ? Colors.red : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight, // Added: Red color for Payout/Coupon
              ),
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildOrderCalculation(String label, String amount,
      {bool isTotal = false, bool isDiscount = false}) {
    // //Build #1.0.34: Update the amount based on the label
    final themeHelper = Provider.of<ThemeNotifier>(context);
    if (label == TextConstants.tenderAmount) {
      amount = '${TextConstants.currencySymbol}${tenderAmount.toStringAsFixed(2)}';
    } else if (label == TextConstants.change) {
      amount = '${TextConstants.currencySymbol}${changeAmount.toStringAsFixed(2)}';
    } else if (label == TextConstants.total) {
      amount = '${TextConstants.currencySymbol}${(getSubTotal() - discount).toStringAsFixed(2)}'; // Adjust total with discount
    } else if (label == TextConstants.payByCash) {
      amount = '${TextConstants.currencySymbol}${payByCash.toStringAsFixed(2)}'; //Build #1.0.99: updated from api
    }else if (label == TextConstants.payByOther) {
      amount = '${TextConstants.currencySymbol}${payByOther.toStringAsFixed(2)}';
    } else if (label == TextConstants.discount) {
      amount = '-${TextConstants.currencySymbol}${discount.toStringAsFixed(2)}'; // Display discount from DB
    }

    // Determine colors and icons based on label
    Color labelColor = themeHelper.themeMode == ThemeMode.dark
        ? ThemeNotifier.textDark
        : (isTotal ? Colors.black87 : Colors.grey[700]!);
    Color amountColor = themeHelper.themeMode == ThemeMode.dark
        ? ThemeNotifier.textDark
        : (isTotal ? Colors.black87 : Colors.grey[800]!);
    Widget? leadingIcon;

    if (isTotal) {
      amountColor = themeHelper.themeMode == ThemeMode.dark
          ? ThemeNotifier.textDark : Colors.black87;
    } else if (label == TextConstants.discount || isDiscount) {
      labelColor = Colors.green[600]!;
      amountColor = Colors.green[600]!;
      leadingIcon = SvgPicture.asset(
        'assets/svg/discount_star.svg',
        // width: ResponsiveLayout.getIconSize(16),
        // height: ResponsiveLayout.getIconSize(16),
        // color: Colors.green[600],
      );
    } else if (label == TextConstants.merchantDiscount) {
      labelColor = Colors.blue[600]!;
      amountColor = Colors.blue[600]!;
      leadingIcon = SvgPicture.asset(
        'assets/svg/discount_star.svg',
        // width: ResponsiveLayout.getIconSize(16),
        // height: ResponsiveLayout.getIconSize(16),
        // color: Colors.blue[600],
      );
    }


    return Container(
      margin: EdgeInsets.symmetric(vertical: ResponsiveLayout.getPadding(2)),  //ResponsiveLayout.getResponsiveMargin(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                leadingIcon,
                //SizedBox(width: ResponsiveLayout.getPadding(8)),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                  fontSize: ResponsiveLayout.getFontSize(isTotal ? 14 : 12),
                  color: labelColor
                  //height: 1,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              fontSize: ResponsiveLayout.getFontSize(isTotal ? 14 : 12),
              color: amountColor
              //height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveLayout.getPadding(20),
        right: ResponsiveLayout.getPadding(20),
        top: ResponsiveLayout.getPadding(20),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(10)),
        color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground :Colors.grey[100],
      ),
      child: Padding(
        padding: EdgeInsets.only(
            left: ResponsiveLayout.getPadding(20),
            right: ResponsiveLayout.getPadding(20),
            top: ResponsiveLayout.getPadding(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                //mainAxisAlignment: MainAxisAlignment.spaceEvenly,/// if not required remove it
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
                        '${TextConstants.currencySymbol}${balanceAmount.toStringAsFixed(2)}',//'${TextConstants.currencySymbol}${getSubTotal()}',
                        amountColor: Colors.red,
                      ),
                      _buildAmountDisplay(
                        TextConstants.tenderAmount,
                        '${TextConstants.currencySymbol}${tenderAmount.toStringAsFixed(2)}', // Build #1.0.33
                        amountColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : null
                      ),
                      _buildAmountDisplay(
                        TextConstants.change,
                        '${TextConstants.currencySymbol}${changeAmount.toStringAsFixed(2)}', // Build #1.0.33 :
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cash payment section
                          Container(
                           width: MediaQuery.of(context).size.width * 0.455,
                            height: MediaQuery.of(context).size.height * 0.675,
                            padding: EdgeInsets.only(
                                left: ResponsiveLayout.getPadding(16),
                              right: ResponsiveLayout.getPadding(16),
                              top: ResponsiveLayout.getPadding(16),
                              //bottom: ResponsiveLayout.getPadding(8),
                            ),
                            decoration: BoxDecoration(
                              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
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
                                    color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.tabsBackground : Colors.red[50],
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
                                      color:themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.paymentEntryContainerColor :  Colors.white,
                                      borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(6)),
                                      border: Border.all(color:themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor : Colors.grey.shade300),
                                    ),
                                    child: TextField(
                                      controller: amountController,//_paymentController,
                                      readOnly: true,
                                      textAlign: TextAlign.right,
                                      enabled: false, // Disables interaction with the TextField
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(right: ResponsiveLayout.getPadding(16)),
                                        border: InputBorder.none,
                                        hintText: '${TextConstants.currencySymbol}0.00',
                                        hintStyle: TextStyle(
                                          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark :Colors.grey[400],///800
                                          fontSize: ResponsiveLayout.getFontSize(20),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.grey[800],
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
                                    _buildQuickAmountButton('${TextConstants.currencySymbol}${balanceAmount.toStringAsFixed(0)}'), // Match balance amount
                                    _buildQuickAmountButton('${TextConstants.currencySymbol}${(balanceAmount + 2).toStringAsFixed(0)}'), // Slightly above
                                    _buildQuickAmountButton('${TextConstants.currencySymbol}${(balanceAmount + 12).toStringAsFixed(0)}'), // More above
                                    _buildQuickAmountButton('${TextConstants.currencySymbol}${((balanceAmount ~/ 10 + 1) * 10).toStringAsFixed(0)}'), // Round up to next 10
                                    _buildQuickAmountButton('${TextConstants.currencySymbol}${((balanceAmount ~/ 50 + 1) * 50).toStringAsFixed(0)}'), // Round up to next 50
                                  ],
                                ),

                                SizedBox(height: ResponsiveLayout.getHeight(12)),

                                // Here you would use your custom numpad widget
                                // CustomNumpad(useCashLayout: true),
                                // Build #1.0.29:  Update CustomNumPad code
                                // Update CustomNumPad usage in _buildPaymentSection
                                CustomNumPad(
                                  numPadType: NumPadType.payment,
                                  isDarkTheme: themeHelper.themeMode == ThemeMode.dark,
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
                                    String cleanAmount = paidAmount.replaceAll('${TextConstants.currencySymbol}', '').trim();
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        TextConstants.selectPaymentMode,
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getFontSize(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      //SizedBox(height: ResponsiveLayout.getHeight(10)),
                      Container(
                        width: ResponsiveLayout.getWidth(224),
                        height: ResponsiveLayout.getHeight(306),
                        padding: EdgeInsets.all(ResponsiveLayout.getPadding(8)),
                        decoration: BoxDecoration(
                          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
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
                            SizedBox(height: ResponsiveLayout.getHeight(10)),
                            _buildPaymentModeButton(TextConstants.card, Icons.credit_card, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.card;
                          });
                        }),
                            SizedBox(height: ResponsiveLayout.getHeight(10)),
                            _buildPaymentModeButton(TextConstants.wallet, Icons.account_balance_wallet, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.wallet;
                          });
                        }),
                            SizedBox(height: ResponsiveLayout.getHeight(10)),
                            _buildPaymentModeButton(TextConstants.ebtText, Icons.payment, onTap: () {
                          setState(() {
                            selectedPaymentMethod = TextConstants.ebtText;
                          });
                        }),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveLayout.getHeight(20)),

                      Container(
                        width: ResponsiveLayout.getWidth(224),
                        height: ResponsiveLayout.getHeight(210),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),//ResponsiveLayout.getResponsivePadding(all: 5),
                        decoration: BoxDecoration(
                          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
                          borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(5)),
                        ),
                        child: Column(
                          children: [_buildPaymentOptionButton(TextConstants.redeemPoints, Icons.stars),
                            SizedBox(height: ResponsiveLayout.getHeight(15)),
                            _buildPaymentOptionButton(
                                TextConstants.manualDiscount, Icons.discount),
                            SizedBox(height: ResponsiveLayout.getHeight(15)),
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
        Color? amountColor = Colors.black,
      }) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    var size  = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveLayout.getFontSize(12),
            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.black54
          ),
        ),
        SizedBox(height: ResponsiveLayout.getHeight(4)),
        Container(
          width: MediaQuery.of(context).size.width * 0.145,
          height: ResponsiveLayout.getHeight(43),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground :  Colors.white,
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
        String cleanAmount = amount.replaceAll('${TextConstants.currencySymbol}', '');
        amountController.text = cleanAmount;
        setState(() {});
      },
      child: Container(
        height: ResponsiveLayout.getHeight(43),
       width: ResponsiveLayout.getWidth(100),
        alignment: Alignment.center,
        padding: EdgeInsets.all(ResponsiveLayout.getPadding(5.0)),
        decoration: BoxDecoration(
          color: Color(0xFFE1F8DC),
          borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(5)),
        ),
        child: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveLayout.getFontSize(16),
            color: Color(0xFF518C3A)
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentModeButton(String label, IconData icon,
      {bool isSelected = false, VoidCallback? onTap}) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      width: ResponsiveLayout.getWidth(128),
      height: ResponsiveLayout.getHeight(54),
      padding: ResponsiveLayout.getResponsivePadding(vertical: 10),
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade100 : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(5)),
        border: isSelected ? Border.all(color: Colors.red.shade300) : Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor :Colors.grey.shade200),
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
            color: isSelected ? Colors.red : themeHelper.themeMode == ThemeMode.dark ? Color(0xFFE1E1E1) : Colors.grey,
            size: ResponsiveLayout.getIconSize(25),
          ),
          SizedBox(width: ResponsiveLayout.getWidth(8)),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.red :themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark :  Colors.grey,
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveLayout.getFontSize(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionButton(String label, IconData icon) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      height: ResponsiveLayout.getHeight(50),
      // padding: ResponsiveLayout.getResponsivePadding(
      //   vertical: 8,
      //   horizontal: 8,
      // ),
      decoration: BoxDecoration(
        color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(ResponsiveLayout.getRadius(8)),
        border: Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor :Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.grey,
            size: ResponsiveLayout.getIconSize(16),),
          SizedBox(width: ResponsiveLayout.getWidth(8)),
          Text(label, style: TextStyle(color: Colors.grey, fontSize: ResponsiveLayout.getFontSize(14))),
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
      PosColumn(text: TextConstants.discount, width: 10),
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
      PosColumn(text: TextConstants.netPayable, width: 8),
      PosColumn(text: balanceAmount.toStringAsFixed(2), width:4),
    ]);
    ///Todo: get pay by cash amount
    // bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: TextConstants.payByCash, width: 8),
      PosColumn(text: payByCash.toStringAsFixed(2), width:4),
    ]);
    ///Todo: get pay by other amount
    // bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: TextConstants.payByOther, width: 8),
      PosColumn(text: payByOther.toStringAsFixed(2), width:4),
    ]);
    // bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: TextConstants.tenderAmount, width: 8),
      PosColumn(text: tenderAmount.toStringAsFixed(2), width:4),
    ]);
    // bytes += ticket.feed(1);
    bytes += ticket.row([
      PosColumn(text: TextConstants.change, width: 10),
      PosColumn(text: changeAmount.toStringAsFixed(2), width:2),
    ]);
    bytes += ticket.feed(1);

    //Footer
    bytes += ticket.row([
      PosColumn(text: "Thank You, Visit Again", width: 12),
    ]);
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

              // Build #1.0.104:  Pop the receipt dialog
              Navigator.of(context).pop();
              // Build #1.0.104:  Pop back to the previous screen with a refresh signal
              Navigator.of(context).pop('refresh');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    TextConstants.orderCompleted,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green, // Build #1.0.104: updated to green
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
              Navigator.of(context).pop(); // Build #1.0.104: close dialog on error
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
            // Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/previousScreen'); // Adjust route condition as needed
            //   Navigator.of(context).pop(); // Close the dialog
            //   Navigator.of(context).pop(); // Go back to previous screen

              // Additional cleanup logic can be added here
            ///Todo:
            ///1. call the order status change to On-Hold
            ///2. Stop loading and dismiss dialog
            ///3. Navigator.push to fast key screen

            orderBloc.changeOrderStatus(orderId: orderId!, status: TextConstants.onhold);
            StreamSubscription? subscription;
            subscription = orderBloc.changeOrderStatusStream.listen((response) {
              if (response.status == Status.COMPLETED) {
                if (kDebugMode) {
                  print("OrderPanel - Order #@# $orderId, successfully changed to on hold");
                }

                Navigator.of(context).pop(); // dismiss dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      TextConstants.orderOnHold,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
                // On the second screen (Screen 2)
                // Build #1.0.104: Pop back to previous screen with refresh signal
                Navigator.of(context).pop('refresh');
                // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => FastKeyScreen()),ModalRoute.withName('/'),);

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
                Navigator.of(context).pop(); // Build #1.0.104:  close dialog on error
              }
              subscription?.cancel();
            });
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
