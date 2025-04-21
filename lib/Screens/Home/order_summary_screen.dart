import 'dart:io';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';

import '../../Constants/text.dart';
import '../../Database/db_helper.dart';
import '../../Widgets/widget_custom_num_pad.dart';
import 'edit_product_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  List<Map<String, dynamic>> orderItems = [];

  @override
  void initState() {
    super.initState();
    fetchOrderItems();
  }

  void fetchOrderItems() async {
    // TODO: Implement actual data fetching from database
    setState(() {
      // Temporary sample data
      orderItems = [];
    });
  }

  void deleteItemFromOrder(dynamic itemId) async {
    // TODO: Implement actual deletion logic
    setState(() {
      orderItems.removeWhere((item) => item[AppDBConst.itemId] == itemId);
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
                    flex: 3,
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
                  Icon(Icons.chevron_left, size: 20),
                  const SizedBox(width: 8),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Payment Summary header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order ID #05235',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      )),
                  Text('Payment Summary',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      )),
                ],
              ),
              const SizedBox(height: 16),

              // Order items list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: 4,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      return _buildOrderItem();
                    },
                  ),
                ),
              ),

              // Bottom summary container
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      // Order calculations
                      _buildOrderCalculation('Sub total', '\$36.0',
                          isTotal: true),
                      _buildOrderCalculation('Tax', '\$5.0'),
                      _buildOrderCalculation('Discount', '-\$3.0',
                          isDiscount: true),
                      SizedBox(height: 5,),
                        DottedLine(),
                      SizedBox(height: 5,),
                      _buildOrderCalculation('Total', '\$38.0', isTotal: true),
                      _buildOrderCalculation('Pay By cash', '\$0.0'),
                      _buildOrderCalculation('Pay By Other', '\$0.0'),
                      _buildOrderCalculation('Tender Amount.', '\$0.0'),
                      _buildOrderCalculation('Change', '\$0.0'),
                    ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem() {
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/king_fisher.png', // Replace with your actual asset path
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
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
                  'King fisher',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '(350ml)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$3.5 × ',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '4',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price
          Text(
            '\$14.0',
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
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment amount display row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 40.0 ,
                    children: [
                      _buildAmountDisplay(
                        'Balance Amount.',
                        '\$38.00',
                        amountColor: Colors.red,
                      ),
                      _buildAmountDisplay(
                        'Tender Amount.',
                        '\$50.00',
                      ),
                      _buildAmountDisplay(
                        'Change.',
                        '\$12.00',
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
                                      'Cash Payment',
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
                                      textAlign: TextAlign.right,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 18),
                                        border: InputBorder.none,
                                        hintText: '\$50.00',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Quick amount buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildQuickAmountButton('\$38.00',
                                          isHighlighted: true),
                                      _buildQuickAmountButton('\$40'),
                                      _buildQuickAmountButton('\$50'),
                                      _buildQuickAmountButton('\$100'),
                                      _buildQuickAmountButton('\$500'),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Here you would use your custom numpad widget
                                  // CustomNumpad(useCashLayout: true),
                                  CustomNumPad(
                                    isPayment: true,
                                    onDigitPressed: (value) { /* handle digit */ },
                                    onClearPressed: () { /* handle clear */ },
                                    onDeletePressed: () { /* handle delete */ },
                                    onPayPressed: () { /* handle pay */ },
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
                      Text('Select Payment Mode',
                        style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                      SizedBox(height: 10,),
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
                            _buildPaymentModeButton('Cash', Icons.money,
                                isSelected: true),
                            const SizedBox(height: 50),
                            _buildPaymentModeButton('Card', Icons.credit_card),
                            const SizedBox(height: 50),
                            _buildPaymentModeButton(
                                'Wallet', Icons.account_balance_wallet),
                            const SizedBox(height: 50),
                            _buildPaymentModeButton('EBT', Icons.payment),
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
                          children: [_buildPaymentOptionButton('Redeem Points', Icons.stars),
                            const SizedBox(height: 20),
                            _buildPaymentOptionButton(
                                'Manual Discount', Icons.discount),
                            const SizedBox(height: 20),
                            _buildPaymentOptionButton(
                                'Gift Receipt', Icons.card_giftcard),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,

      children: [
        Text(label, style: TextStyle(fontSize: 18, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          width: 220,
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

  Widget _buildQuickAmountButton(String amount, {bool isHighlighted = false}) {
    return Container(
      height: 60,
      width: 90 ,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xFFBFF1C0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green,fontSize: 18,)),
    );
  }

  Widget _buildPaymentModeButton(String label, IconData icon,
      {bool isSelected = false}) {
    return Container(
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
          Icon(icon, color: isSelected ? Colors.red : Colors.grey,size: 40,),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                color: isSelected ? Colors.red : Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 18,

              )),
        ],
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
}
