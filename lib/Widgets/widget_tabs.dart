import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Import your custom numpad
import '../Blocs/Orders/order_bloc.dart';
import '../Constants/text.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
import '../Helper/api_response.dart';
import '../Models/Orders/orders_model.dart';
import '../Repositories/Orders/order_repository.dart';
import 'widget_custom_num_pad.dart';

class AppScreenTabWidget extends StatefulWidget {
  AppScreenTabWidget({this.selectedTabIndex = 0, this.barcode = "", required this.scaffoldMessengerContext, super.key});
  int selectedTabIndex = 0;
  String barcode = "";
  final BuildContext scaffoldMessengerContext;

  @override
  State<AppScreenTabWidget> createState() => _AppScreenTabWidgetState();
}

class _AppScreenTabWidgetState extends State<AppScreenTabWidget> {
  // Tab selection
  bool _isPayoutLoading = false;
  bool _isCouponLoading = false;
  bool _isDiscountLoading = false;
  final OrderHelper _orderHelper = OrderHelper(); // Add OrderHelper instance
  late OrderBloc orderBloc;
  int? orderId; // Store order ID
  double orderTotal = 0.0; // Store order total
  // Discount values
  String _discountValue = "0%";
  bool _isPercentageSelected = true;

  // Coupon value
  String _couponCode = "";

  // Custom item values
  String _customItemName = "";
  String _customItemPrice = "";
  String _sku = "";

  // Tax slab options
  final List<String> _taxSlabOptions = ['No Tax', 'GST 5%', 'GST 12%', 'GST 18%', 'GST 28%'];
  String _selectedTaxSlab = '';

  // Payout value
  String _payoutAmount = "";

  // Text editing controllers
  final TextEditingController _customItemNameController = TextEditingController();
  final TextEditingController _customItemPriceController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();

  @override
  void initState() {
    orderBloc = OrderBloc(OrderRepository()); // Build #1.0.53
    super.initState();
    _customItemNameController.addListener(() {
      _customItemName = _customItemNameController.text;
    });
    _customItemPriceController.addListener(() {
      _customItemPrice = _customItemPriceController.text;
    });
    _skuController.addListener(() {
      _sku = widget.barcode ?? "";
      _sku = _skuController.text;
    });
    _loadOrderData(); // Load order data on initialization
  }

  @override
  void dispose() {
    _customItemNameController.dispose();
    _customItemPriceController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  // Fetch order ID and total from OrderHelper
  Future<void> _loadOrderData() async {
    await _orderHelper.loadData();
    setState(() {
      orderId = _orderHelper.activeOrderId;
      if (orderId != null) {
        _orderHelper.getOrderById(orderId!).then((order) {
          if (order.isNotEmpty) {
            setState(() {
              orderTotal = order.first[AppDBConst.orderTotal] as double? ?? 0.0;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 10,),
        // Top Tabs
        _buildTabs(),

        const SizedBox(height: 10),

        // Content based on selected tab
        _buildTabContent(),
      ],
    );
  }

  // Build the top tabs
  Widget _buildTabs() {
    return Row(
      children: [
        _buildTab(0, Icons.percent, TextConstants.discounts),
        const SizedBox(width: 10),
        _buildTab(1, Icons.confirmation_num_outlined, TextConstants.coupons),
        const SizedBox(width: 10),
        _buildTab(2, Icons.shopping_bag_outlined, TextConstants.customItem),
        const SizedBox(width: 10),
        _buildTab(3, Icons.receipt_outlined, TextConstants.payoutsText),
      ],
    );
  }

  // Build individual tab
  Widget _buildTab(int index, IconData icon, String text) {
    if (kDebugMode) {
      print("Widget_tabs _buildTab index : $index");
    }
    bool isSelected = widget.selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (kDebugMode) {
            print("Widget_tabs _buildTab onTap index : $index");
          }
          setState(() {
            widget.selectedTabIndex = index;
          });
        },
        child: Container(height: MediaQuery.of(context).size.height * 0.065,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E2745) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build content based on selected tab
  Widget _buildTabContent() {
    switch (widget.selectedTabIndex) {
      case 0:
        return _buildDiscountsTab();
      case 1:
        return _buildCouponsTab();
      case 2:
        return _buildCustomItemTab(context);
      case 3:
        return _buildPayoutsTab();
      default:
        return const SizedBox();
    }
  }

  // DISCOUNTS TAB
  Widget _buildDiscountsTab() {
    return Column(
      children: [
        // Title
        const Text(
          TextConstants.applyDiscountToSale,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2745),
          ),
        ),

        const SizedBox(height: 20),

        // Discount Input Toggle
        _buildDiscountToggle(),

        const SizedBox(height: 15),

        // Discount Value Display
        _buildDiscountDisplay(),

        const SizedBox(height: 15),

        // Custom Numpad
        SizedBox(
          width: MediaQuery.of(context).size.width / 2.5,
          height: MediaQuery.of(context).size.height / 2.25,
          child: CustomNumPad(
            onDigitPressed: (digit) {
              setState(() { // Build #1.0.53 : updated code
                String currentValue = _discountValue.replaceAll('%', '').replaceAll('\$', '');
                if (currentValue == "0") {
                  currentValue = digit;
                } else {
                  currentValue += digit;
                }
                _discountValue = _isPercentageSelected ? "$currentValue%" : currentValue;
              });
            },
            onClearPressed: () {
              setState(() {
                _discountValue = _isPercentageSelected ? "0%" : "0";
              });
            },
            onDeletePressed: () { // Build #1.0.53 : updated code
              setState(() {
                String currentValue = _discountValue.replaceAll('%', '').replaceAll('\$', '');
                currentValue = currentValue.isNotEmpty ? currentValue.substring(0, currentValue.length - 1) : "0";
                _discountValue = _isPercentageSelected ? "$currentValue%" : currentValue;
              });
            },
            actionButtonType: ActionButtonType.add,
            onAddPressed: _handleAddDiscount,
            isLoading: _isDiscountLoading,
          ),
        ),
      ],
    );
  }

  // COUPONS TAB
  Widget _buildCouponsTab() {
    return Column(
      children: [
        // Title
        const Text(
          TextConstants.enterCouponCode,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2745),
          ),
        ),

        const SizedBox(height: 20),

        // Coupon Code Display
        Container(
          width: MediaQuery.of(context).size.width / 2.75,
          height: MediaQuery.of(context).size.height / 12,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            _couponCode.isEmpty ? "Ex: 123456789" : _couponCode, // Build #1.0.53 : updated code
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _couponCode.isEmpty ? Colors.grey : const Color(0xFF1E2745),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Custom Numpad
        SizedBox(
          width: MediaQuery.of(context).size.width / 2.5,
          height: MediaQuery.of(context).size.height / 2.0,
          child: CustomNumPad(
            onDigitPressed: (digit) {
              setState(() {
                _couponCode += digit;
              });
            },
            onClearPressed: () {
              setState(() {
                _couponCode = "";
              });
            },
            onDeletePressed: () { // Build #1.0.53 : updated code
              setState(() {
                _couponCode = _couponCode.isNotEmpty ? _couponCode.substring(0, _couponCode.length - 1) : "";
              });
            },
            actionButtonType: ActionButtonType.add,
            onAddPressed: _handleAddCoupon,
            isLoading: _isCouponLoading,
          ),
        ),
      ],
    );
  }

  // CUSTOM ITEM TAB
  // Widget _buildCustomItemTab() {
  //   return
  //     Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         // First Row: Name & SKU
  //         Row(
  //           children: [
  //             // Name Field
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     "Name",
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                       color: Color(0xFF1E2745),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 5),
  //                   Container(
  //                     height: MediaQuery.of(context).size.height / 15,
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(10),
  //                       border: Border.all(color: Colors.grey.shade300),
  //                     ),
  //                     child: TextField(
  //                       textAlign: TextAlign.left,
  //                       controller: _customItemNameController,
  //                       decoration: InputDecoration(
  //                         contentPadding: EdgeInsets.all(5),
  //                         border: InputBorder.none,
  //                         hintText: "Custom Item Name",
  //                         hintStyle: TextStyle(
  //                           color: Colors.grey,
  //                           fontSize: 14
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(width: 10),
  //             // SKU Field
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     "SKU",
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                       color: Color(0xFF1E2745),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 5),
  //                   Container(
  //                     height: MediaQuery.of(context).size.height /15,
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(10),
  //                       border: Border.all(color: Colors.grey.shade300),
  //                     ),
  //                     child: TextField(
  //                       controller: _skuController,
  //                       textAlign: TextAlign.center,
  //                       decoration: InputDecoration(
  //                         border: InputBorder.none,
  //                         hintText: "Generate the SKU",
  //                         hintStyle: TextStyle(
  //                             color: Colors.grey,
  //                             fontSize: 14
  //                         ),
  //                         contentPadding: const EdgeInsets.only(right: 5),
  //                         suffix: Container(
  //                           margin: const EdgeInsets.all(5.0),
  //                           child: ElevatedButton(
  //                             onPressed: _generateSku,
  //                             style: ElevatedButton.styleFrom(
  //                               backgroundColor: Colors.red.shade400,
  //                               foregroundColor: Colors.white,
  //                               elevation: 0,
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(8),
  //                               ),
  //                               minimumSize: const Size(70, 40),
  //                             ),
  //                             child: const Text(
  //                               "Generate",
  //                               style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //
  //         const SizedBox(height: 10),
  //
  //         // Second Row: Item Price & Tax
  //         Row(
  //           children: [
  //             // Item Price Field
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     "Item Price",
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                       color: Color(0xFF1E2745),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 5),
  //                   Container(
  //                     height: MediaQuery.of(context).size.height / 15,
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(10),
  //                       border: Border.all(color: Colors.grey.shade300),
  //                     ),
  //                     child: TextField(
  //                       controller: _customItemPriceController,
  //                       //keyboardType: TextInputType.number,
  //                       decoration: const InputDecoration(
  //                         hintText: "Enter the Price",
  //                         hintStyle: TextStyle(
  //                             color: Colors.grey,
  //                             fontSize: 14
  //                         ),
  //                         border: InputBorder.none,
  //                         prefixText: "\$",
  //                         prefixStyle: TextStyle(fontSize: 14),
  //                         contentPadding: EdgeInsets.all(5),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(width: 10),
  //             // Tax Dropdown
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   const Text(
  //                     "Tax",
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                       color: Color(0xFF1E2745),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 5),
  //                   Container(
  //                     height: MediaQuery.of(context).size.height /15,
  //                     padding: const EdgeInsets.symmetric(horizontal: 15),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(10),
  //                       border: Border.all(color: Colors.grey.shade300),
  //                     ),
  //                     child: DropdownButton<String>(
  //                       value: _selectedTaxSlab.isEmpty ? null : _selectedTaxSlab,
  //                       hint: const Text(
  //                         'Choose a Tax Slab',
  //                         style: TextStyle(color: Colors.grey, fontSize: 14),
  //                       ),
  //                       icon: const Icon(Icons.arrow_drop_down),
  //                       isExpanded: true,
  //                       underline: Container(),
  //                       items: _taxSlabOptions.map((String value) {
  //                         return DropdownMenuItem<String>(
  //                           value: value,
  //                           child: Text(value),
  //                         );
  //                       }).toList(),
  //                       onChanged: (newValue) {
  //                         setState(() {
  //                           _selectedTaxSlab = newValue!;
  //                         });
  //                       },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //
  //         const SizedBox(height: 20),
  //
  //         // Custom Numpad
  //         Center(
  //           child: SizedBox(
  //             width: MediaQuery.of(context).size.width / 2.5,
  //             height: MediaQuery.of(context).size.height / 2.275,
  //             child: CustomNumPad(
  //               onDigitPressed: (digit) {
  //                 setState(() {
  //                   if (_customItemPrice == "0.00") {
  //                     _customItemPrice = digit;
  //                     _customItemPriceController.text = digit;
  //                   } else {
  //                     _customItemPrice += digit;
  //                     _customItemPriceController.text = _customItemPrice;
  //                   }
  //                 });
  //               },
  //               onClearPressed: () {
  //                 setState(() {
  //                   _customItemPrice = "";
  //                   _customItemPriceController.text = "";
  //                 });
  //               },
  //               actionButtonType: ActionButtonType.add,
  //               onAddPressed: () {
  //                 _handleAddCustomItem();
  //               },
  //             ),
  //           ),
  //         ),
  //       ],
  //     );
  //
  // }

  // CUSTOM ITEM TAB
  Widget _buildCustomItemTab(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth * 0.75,
      height: screenHeight * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLabeledTextField(
                title: TextConstants.nameText ,
                hintText: TextConstants.customItemName ,
                controller: _customItemNameController,
              ),
              const SizedBox(width: 20),
              _buildSkuField(),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            //mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLabeledTextField(
                title: TextConstants.itemPrice,
                hintText: TextConstants.enterThePrice,
                controller: _customItemPriceController,
                readOnly: true,
              ),
              const SizedBox(width: 20),
              _buildTaxDropdown(),
            ],
          ),
          const SizedBox(height: 10),
          _buildCustomNumpad(context),
        ],
      ),
    );
  }

  Widget _buildCustomNumpad(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 2.5,
        height: MediaQuery.of(context).size.height / 2.0,
        child: CustomNumPad(
          onDigitPressed: (digit) {
            setState(() {
              if (_customItemPrice == "0.00") {
                _customItemPrice = digit;
                _customItemPriceController.text = digit;
              } else {
                _customItemPrice += digit;
                _customItemPriceController.text = _customItemPrice;
              }
            });
          },
          onClearPressed: () {
            setState(() {
              _customItemPrice = "";
              _customItemPriceController.text = "";
            });
          },
          actionButtonType: ActionButtonType.add,
          onAddPressed: () {
            _handleAddCustomItem();
          },
        ),
      ),
    );
  }

  Widget _buildLabeledTextField({
    required String title,
    required String hintText,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
      // mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(height: 5,),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E2745),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: MediaQuery.of(context).size.height / 17,
          width: MediaQuery.of(context).size.width * 0.2,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkuField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 5,),
        const Text(
          TextConstants.sku,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E2745),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: MediaQuery.of(context).size.height / 17,
          width: MediaQuery.of(context).size.width * 0.2,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Color(0xFFECE9E9), // Custom background color,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skuController,
                  readOnly: true,
                  textAlign: TextAlign.start,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: TextConstants.generateTheSku,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _generateSku,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(60, 36),
                ),
                child: const Text(
                  'Generate',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaxDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 5,),
        const Text(
          TextConstants.taxText,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E2745),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          alignment: Alignment.centerLeft,
          height: MediaQuery.of(context).size.height / 17,
          width: MediaQuery.of(context).size.width * 0.2,
          // padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedTaxSlab.isEmpty ? null : _selectedTaxSlab,
            isExpanded: true,
            alignment: Alignment.centerLeft,
            //underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down),
            items: _taxSlabOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  textAlign: TextAlign.start,
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedTaxSlab = newValue!;
              });
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical:0), // left + vertical center
              border: InputBorder.none, // No border at all
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),

            hint: Container( color: Colors.blue, padding: EdgeInsets.only(bottom: 0), child: Text(TextConstants.chooseTaxSlab,style: TextStyle(color: Colors.grey,fontSize: 14), textAlign: TextAlign.center,)),
          ),
        ),
      ],
    );
  }




  // PAYOUTS TAB
  Widget _buildPayoutsTab() {
    return Column(
      children: [
        // Title with amount field
        Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width / 2.75,
              height: MediaQuery.of(context).size.height / 12,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Text(
                _payoutAmount.isEmpty ? "\$0" : "\$$_payoutAmount", // Build #1.0.53 : updated code
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _payoutAmount.isEmpty ? Colors.grey : const Color(0xFF1E2745),
                ),
              ),
            ),
            Positioned(
              top: -5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white,
                  child: const Text(
                    TextConstants.addPaymentAmount,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Custom Numpad
        SizedBox(
          width: MediaQuery.of(context).size.width / 2.5,
          height: MediaQuery.of(context).size.height / 2.0,
          child: CustomNumPad(
            onDigitPressed: (digit) {
              setState(() {
                if (_payoutAmount == "0.00" || _payoutAmount.isEmpty) {
                  _payoutAmount = digit;
                } else {
                  _payoutAmount += digit;
                }
              });
            },
            onClearPressed: () {
              setState(() {
                _payoutAmount = "";
              });
            },
            onDeletePressed: () { // Build #1.0.53 : updated code
              setState(() {
                _payoutAmount = _payoutAmount.isNotEmpty ? _payoutAmount.substring(0, _payoutAmount.length - 1) : "";
              });
            },
            actionButtonType: ActionButtonType.add,
            onAddPressed: _handleAddPayout,
            isLoading: _isPayoutLoading,
          ),
        ),
      ],
    );
  }

  // Generate SKU function
  void _generateSku() {
    // Simple SKU generation logic - prefix + timestamp
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(0,12);
    // String prefix = _customItemName.isNotEmpty
    //     ? _customItemName.substring(0, _customItemName.length > 3 ? 3 : _customItemName.length).toUpperCase()
    //     : "C";

    String prefix = 'C';
    setState(() {
      _sku = "$prefix-$timestamp";
      _skuController.text = _sku;
    });

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(TextConstants.skuGeneratedSuccessfully),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Build the percentage/amount toggle
  Widget _buildDiscountToggle() {
    return Container(
      width: MediaQuery.of(context).size.width / 2.75,
      height: MediaQuery.of(context).size.height / 14 ,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Percentage option
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (!_isPercentageSelected) {
                    _isPercentageSelected = true;
                    // Convert to percentage format
                    _discountValue = _discountValue.replaceAll('\$', '') + "%";
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isPercentageSelected
                      ? Colors.red.shade400
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(9),
                      bottomLeft: Radius.circular(9),
                      topRight: Radius.circular(9),
                      bottomRight: Radius.circular(9)),
                ),
                alignment: Alignment.center,
                child: Text(
                  "%",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isPercentageSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),

          // Dollar option
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_isPercentageSelected) {
                    _isPercentageSelected = false;
                    // Convert to dollar format
                    _discountValue = _discountValue.replaceAll('%', '');
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                  !_isPercentageSelected ? Colors.redAccent : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(9),
                    bottomRight: Radius.circular(9),
                    topLeft: Radius.circular(9),
                    bottomLeft: Radius.circular(9),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "\$",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: !_isPercentageSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build the discount value display
  Widget _buildDiscountDisplay() {
    // Build #1.0.53 : updated code
    String displayValue = _isPercentageSelected ? _discountValue : "\$${_discountValue}";
    bool isPlaceholder = _discountValue == "0%" || _discountValue == "0";

    return Container(
      width: MediaQuery.of(context).size.width / 2.75,
      height: MediaQuery.of(context).size.height / 14,
      padding: const EdgeInsets.symmetric(vertical: 2), /// use this value for all inset paddings
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        displayValue,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isPlaceholder ? Colors.grey : const Color(0xFF1E2745),
        ),
      ),
    );
  }

// Handle adding the discount
  void _handleAddDiscount() async { // Build #1.0.53 : updated code with discount api call
    String discountValue = _discountValue.replaceAll('%', '').replaceAll('\$', '');
    if (discountValue.isEmpty || discountValue == "0" || double.tryParse(discountValue) == null) {
      if (kDebugMode) print("Invalid discount value: $discountValue");
      return;
    }

    if (orderId == null) {
      if (kDebugMode) print("No active order selected");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("No active order selected"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    double discountAmount = double.parse(discountValue);
    if (_isPercentageSelected) {
      discountAmount = (discountAmount / 100) * orderTotal;
      if (kDebugMode) print("Calculated discount amount from percentage: $discountAmount");
    }

    setState(() {
      _isDiscountLoading = true;
    });

    StreamSubscription? subscription;
      if (kDebugMode) print("Subscribing to addPayoutStream for discount");
      subscription = orderBloc.addPayoutStream.listen((response) {
        if (!mounted) {
          subscription?.cancel(); // Cancel subscription if widget is not mounted
          if (kDebugMode) print("Widget not mounted, skipping discount UI update");
          return;
        }
        if (response.status == Status.COMPLETED) {
          if (kDebugMode) print("Discount added successfully for order $orderId");
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text("Discount of \$${discountAmount.toStringAsFixed(2)} added successfully"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          if (mounted) {
            setState(() {
              _discountValue = _isPercentageSelected ? "0%" : "0";
              _isDiscountLoading = false;
            });
          };
          subscription?.cancel(); // Cancel subscription after successful operation
        } else if (response.status == Status.ERROR) {
          if (kDebugMode) print("Failed to add discount: ${response.message}");
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text(response.message ?? "Failed to add discount"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          if (mounted) {
            setState(() {
              _isDiscountLoading = false;
            });
          };
          subscription?.cancel(); // Cancel subscription after error
        }
      }, onError: (error) {
        if (kDebugMode) print("addPayoutStream error: $error");
        subscription?.cancel(); // Cancel subscription on stream error
      });

      await orderBloc.addPayout(orderId: orderId!, amount: discountAmount, isPayOut: false);
  }

// Handle adding the coupon
  void _handleAddCoupon() async { // Build #1.0.53 : updated code with add coupon api call
    if (kDebugMode) print("### _handleAddCoupon - Coupon Code: $_couponCode");
    if (_couponCode.isEmpty) {
      if (kDebugMode) print("### _couponCode is empty");
      return;
    }

    if (orderId == null) {
      if (kDebugMode) print("No active order selected");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("No active order selected"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isCouponLoading = true;
    });

    StreamSubscription? subscription;
      if (kDebugMode) print("### Subscribing to applyCouponStream");
      subscription = orderBloc.applyCouponStream.listen((response) {
        if (!mounted) {
          if (kDebugMode) print("### Widget not mounted, skipping coupon UI update");
          subscription?.cancel(); // Cancel subscription if widget is not mounted
          return;
        }
        if (response.status == Status.COMPLETED) {
          if (kDebugMode) print("Coupon applied successfully for order $orderId");
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text("Coupon '$_couponCode' applied successfully"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          if (mounted) {
            setState(() {
              _couponCode = "";
              _isCouponLoading = false;
            });
          };
          subscription?.cancel(); // Cancel subscription after successful operation
        } else if (response.status == Status.ERROR) {
          if (kDebugMode) print("Failed to apply coupon: ${response.message}");
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text(response.message ?? "Failed to apply coupon"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          if (mounted) {
            setState(() {
              _isCouponLoading = false;
            });
          };
          subscription?.cancel(); // Cancel subscription after error
        }
      }, onError: (error) {
        if (kDebugMode) print("### applyCouponStream error: $error");
        subscription?.cancel(); // Cancel subscription on stream error
      });

      if (kDebugMode) print("### Calling orderBloc.applyCouponToOrder");
      await orderBloc.applyCouponToOrder(orderId: orderId!, couponCode: _couponCode);
  }

// Handle adding the custom item
  void _handleAddCustomItem() async { // Build #1.0.53 : updated code
    if (_customItemName.isEmpty) {
      if (kDebugMode) print("Custom item name is empty");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("Please enter item name"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_customItemPrice.isEmpty || double.tryParse(_customItemPrice) == null || double.parse(_customItemPrice) == 0) {
      if (kDebugMode) print("Invalid custom item price: $_customItemPrice");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid price"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_selectedTaxSlab.isEmpty) {
      if (kDebugMode) print("No tax slab selected");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("Please select a tax slab"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_sku.isEmpty) {
      if (kDebugMode) print("SKU is empty");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("Please generate SKU"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (orderId == null) {
      if (kDebugMode) print("No active order selected");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("No active order selected"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _customItemName = _customItemNameController.text;
      _customItemPrice = _customItemPriceController.text;
    });

    try {
      // Placeholder for API call to add custom item (implement as needed)
      if (kDebugMode) print("Adding custom item: $_customItemName, Price: $_customItemPrice, Tax: $_selectedTaxSlab, SKU: $_sku");

      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        SnackBar(
          content: Text("Custom item '$_customItemName' added at \$$_customItemPrice"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Clear fields after success
      setState(() {
        _customItemName = "";
        _customItemPrice = "";
        _sku = "";
        _selectedTaxSlab = "";
        _customItemNameController.clear();
        _customItemPriceController.clear();
        _skuController.clear();
      });
    } catch (e) {
      if (kDebugMode) print("Exception in _handleAddCustomItem: $e");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        SnackBar(
          content: Text("Failed to add custom item: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

// Handle adding the payout
  void _handleAddPayout() async { // Build #1.0.53 : updated code with add payout api call
    if (_payoutAmount.isEmpty || _payoutAmount == "0" || double.tryParse(_payoutAmount) == null) {
      if (kDebugMode) print("Invalid payout amount: $_payoutAmount");
      return;
    }

    if (orderId == null) {
      if (kDebugMode) print("No active order selected");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("No active order selected"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isPayoutLoading = true;
    });

    StreamSubscription? subscription;
      if (kDebugMode) print("Subscribing to addPayoutStream for payout");
      subscription = orderBloc.addPayoutStream.listen((response) {
        if (!mounted) {
          if (kDebugMode) print("Widget not mounted, skipping payout UI update");
          subscription?.cancel(); // Cancel subscription if widget is not mounted
          return;
        }
        if (response.status == Status.COMPLETED) {
          if (kDebugMode) print("Payout added successfully for order $orderId");
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text("Payout of \$$_payoutAmount added successfully"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          if (mounted) {
          setState(() {
            _payoutAmount = "";
            _isPayoutLoading = false;
          });
          };
          subscription?.cancel(); // Cancel subscription after successful operation
        } else if (response.status == Status.ERROR) {
          if (kDebugMode) print("Failed to add payout: ${response.message}");
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text(response.message ?? "Failed to add payout"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          if (mounted) {
            setState(() {
              _isPayoutLoading = false;
            });
          };
          subscription?.cancel(); // Cancel subscription after error
        }
      }, onError: (error) {
        if (kDebugMode) print("addPayoutStream error: $error");
        subscription?.cancel(); // Cancel subscription on stream error
      });

      await orderBloc.addPayout(
        orderId: orderId!,
        amount: double.parse(_payoutAmount),
        isPayOut: true,
      );
  }
}