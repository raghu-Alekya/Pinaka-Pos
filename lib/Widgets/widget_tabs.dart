import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../Helper/Extentions/nav_layout_manager.dart';

// Import your custom numpad
import '../Blocs/Assets/asset_bloc.dart';
import '../Blocs/Orders/order_bloc.dart';
import '../Blocs/Search/product_search_bloc.dart';
import '../Constants/text.dart';
import '../Database/assets_db_helper.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
import '../Helper/Extentions/theme_notifier.dart';
import '../Helper/api_response.dart';
import '../Models/Assets/asset_model.dart';
import '../Models/Orders/orders_model.dart';
import '../Models/Search/product_custom_item_model.dart' as model;
import '../Repositories/Assets/asset_repository.dart';
import '../Repositories/Orders/order_repository.dart';
import '../Repositories/Search/product_search_repository.dart';
import '../Utilities/svg_images_utility.dart';
import 'widget_custom_num_pad.dart';

class AppScreenTabWidget extends StatefulWidget {
  AppScreenTabWidget({this.selectedTabIndex = 0, this.barcode = "", this.refreshOrderList, required this.scaffoldMessengerContext, super.key});
  int selectedTabIndex = 0;
  String barcode = "";
  final BuildContext scaffoldMessengerContext;
  final VoidCallback? refreshOrderList; // Callback to refresh order panel

  @override
  State<AppScreenTabWidget> createState() => _AppScreenTabWidgetState();
}

class _AppScreenTabWidgetState extends State<AppScreenTabWidget> with LayoutSelectionMixin {
  // Tab selection
  bool _isPayoutLoading = false;
  bool _isCouponLoading = false;
  bool _isDiscountLoading = false;
  bool _isCustomItemLoading = false;
  final OrderHelper _orderHelper = OrderHelper(); // Add OrderHelper instance
  late OrderBloc orderBloc;
  late ProductBloc productBloc;
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
  late List<String> _taxSlabOptions = [];
  String _selectedTaxSlab = '';
  final AssetDBHelper _assetDBHelper = AssetDBHelper.instance;
  bool _isTaxAvailable = false;

  // Payout value
  String _payoutAmount = "";
  // Adding a separate state variable for selected tab
  late int _selectedTabIndex;

  // Text editing controllers
  final TextEditingController _customItemNameController = TextEditingController();
  final TextEditingController _customItemPriceController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();

  // Function to check if the item name is empty
  bool _isItemNameEmpty() {
    return _customItemNameController.text.trim().isEmpty;
  }

  @override
  void initState() {
    orderBloc = OrderBloc(OrderRepository()); // Build #1.0.53
    productBloc = ProductBloc(ProductRepository());
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
    _loadTaxSlabs();
    // Initialize the selected tab index from widget
    _selectedTabIndex = widget.selectedTabIndex;
    // Add a listener to _customItemNameController to track changes in the text field
    _customItemNameController.addListener(() {
      setState(() {});  // Trigger a rebuild when the text changes
    });
  }

  Future<void> _loadTaxSlabs() async {
    try {
      List<Tax> taxes = await _assetDBHelper.getTaxList();
      if (kDebugMode) print("#### _loadTaxSlabs: Loaded ${taxes.length} taxes: ${taxes.map((t) => t.toMap()).toList()}");
      setState(() {
        _taxSlabOptions = taxes.map((tax) => tax.name).toSet().toList();
        if (_taxSlabOptions.isNotEmpty) {
          _selectedTaxSlab = _taxSlabOptions.first;
          if (kDebugMode) print("#### _loadTaxSlabs: Set selected tax slab to: $_selectedTaxSlab");
        } else {
          if (kDebugMode) print("#### _loadTaxSlabs: Tax slabs are empty");
          _selectedTaxSlab = ''; // Ensure reset if no options
        }
      });
    } catch (e) {
      if (kDebugMode) print("#### _loadTaxSlabs: Error loading tax slabs: $e");
      setState(() {
        _taxSlabOptions = [];
        _selectedTaxSlab = '';
      });
    }
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
      if (kDebugMode) {
        print("####_loadOrderData, orderId: $orderId");
      }
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
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return
      //backgroundColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : Colors.white,
      // const Color(0xFFF1F5F9),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Container(
          decoration: BoxDecoration(
            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.grey.shade400),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
              )
            ],
          ),
          clipBehavior: Clip.antiAlias, // Ensures children conform to the rounded corners
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Top Tabs
              _buildTabs(),

              // Content based on selected tab
              Expanded(
                  child: ClipPath(
                    clipper: ContentSideClipper(selectedIndex: _selectedTabIndex),
                      child: _buildTabContent()
                  )
              ),
            ],
          ),
        ),
      );
  }

  //Build the top tabs
  Widget _buildTabs() {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return ClipPath(
      clipper: TabSideClipper(selectedIndex: _selectedTabIndex),
      child: Container(
          width: MediaQuery.of(context).size.width * 0.12,
        decoration: BoxDecoration(
          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.tabsBackground : Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16.0),
        ),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTab(0,SvgUtils.addDiscountIcon, TextConstants.discounts), // Build #1.0.168: Updated - Changed the icons to figma svg icons
            const SizedBox(width: 10),
            Divider(height: 1, thickness: 0.1, indent: 10, endIndent: 10),
            _buildTab(1, SvgUtils.addCouponIcon, TextConstants.coupons),
            const SizedBox(width: 10),
           Divider(height: 1, thickness: 0.1, indent: 10, endIndent: 10),
            _buildTab(2, SvgUtils.addCustomItemIcon, TextConstants.customItem),
            const SizedBox(width: 10),
            Divider(height: 1, thickness: 0.1, indent: 10, endIndent: 10),
            _buildTab(3, SvgUtils.addPayoutIcon, TextConstants.payoutsText),
          ],
        )
      ),
    );
  }

  // Build individual tab
  Widget _buildTab(int index, String svgPath, String text) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    if (kDebugMode) {
      print("Widget_tabs _buildTab index : $index");
    }
    // Use the state variable instead of widget property
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (kDebugMode) {
            print("Widget_tabs _buildTab onTap index : $index");
          }
          setState(() {
            // Update the state variable instead of widget property
            _selectedTabIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (themeHelper.themeMode == ThemeMode.dark
                ? ThemeNotifier.primaryBackground
                : Colors.white)
                : (themeHelper.themeMode == ThemeMode.dark
                ? ThemeNotifier.tabsBackground
                : const Color(0xFFF1F5F9)),  //Color(0xFF1E2745))
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset( // Build #1.0.168: Updated - Changed the icons to figma svg icons
                svgPath,
                height: 32,
                width: 32,
                colorFilter: ColorFilter.mode(
                  isSelected
                      ? (themeHelper.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black)
                      : (themeHelper.themeMode == ThemeMode.dark
                      ? Colors.white70
                      : Colors.grey),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  color: isSelected
                      ? (themeHelper.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black)
                      : (themeHelper.themeMode == ThemeMode.dark
                      ? Colors.white70
                      : Colors.grey.shade700),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
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
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          // Title
           Text(
            TextConstants.applyDiscountToSale,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Color(0xFF1E2745),
            ),
          ),

          const SizedBox(height: 10),

          // Discount Input Toggle
          _buildDiscountToggle(),

          const SizedBox(height: 10),

          // Discount Value Display
          _buildDiscountDisplay(),

          const SizedBox(height: 10),

          // Custom Numpad
          SizedBox(
            width: MediaQuery.of(context).size.width / 2.75,
            height: MediaQuery.of(context).size.height / 2.0,
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
              isDarkTheme: true,
              numPadType: NumPadType.payment,
              showAddInsteadOfPay: true,

            ),
          ),
        ],
      ),
    );
  }

  // COUPONS TAB
  Widget _buildCouponsTab() {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Column(
        children: [
          // Title
          Text(
            TextConstants.enterCouponCode,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Color(0xFF1E2745),
            ),
          ),

          const SizedBox(height: 20),

          // Coupon Code Display
          Container(
            width: MediaQuery.of(context).size.width / 2.75,
            height: MediaQuery.of(context).size.height / 12,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.paymentEntryContainerColor : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: Text(
              _couponCode.isEmpty ? "Ex: 123456789" : _couponCode, // Build #1.0.53 : updated code
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _couponCode.isEmpty ?  Colors.grey : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : const Color(0xFF1E2745),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Custom Numpad
          SizedBox(
            width: MediaQuery.of(context).size.width / 2.75,
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
              isDarkTheme: true,
              numPadType: NumPadType.payment,
              showAddInsteadOfPay: true,
            ),
          ),
        ],
      ),
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
    final themeHelper = Provider.of<ThemeNotifier>(context);

    return Container(
      width: screenWidth * 0.75,
      height: screenHeight * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      decoration: BoxDecoration(
          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : Colors.white,
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
        width: MediaQuery.of(context).size.width / 2.75,
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
            if (kDebugMode) {
              print("#### DEBUG 11@33 onAddPressed");
            }
            _handleAddCustomItem();
          },
          isLoading: _isCustomItemLoading,
          isDarkTheme: true,
          numPadType: NumPadType.payment,
          showAddInsteadOfPay: true,
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
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
      // mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(height: 5,),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Color(0xFF1E2745),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: MediaQuery.of(context).size.height / 17,
          width: MediaQuery.of(context).size.width * 0.2,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
          decoration: BoxDecoration(
            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.paymentEntryContainerColor : null,
            border: Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor :  Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkuField() {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 5,),
        Text(
          TextConstants.sku,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Color(0xFF1E2745),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: MediaQuery.of(context).size.height / 17,
          width: MediaQuery.of(context).size.width * 0.2,
          decoration: BoxDecoration(
            border: Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor : Colors.grey.shade300),
            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.paymentEntryContainerColor : Color(0xFFECE9E9), // Custom background color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skuController,
                  readOnly: true,
                  textAlign: TextAlign.start,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9) ,
                    hintText: TextConstants.generateTheSku,
                    hintStyle: TextStyle(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: ElevatedButton(
                  onPressed:  _isItemNameEmpty() ? null : _generateSku, // Disable functionality if item name is empty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isItemNameEmpty() ? Colors.grey : Colors.redAccent, // Change color based on button state
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    //minimumSize: const Size(60, 36),
                  ),
                  child: const Text(
                    TextConstants.generate,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaxDropdown() {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 5,),
        Text(
          TextConstants.taxText,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Color(0xFF1E2745),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          alignment: Alignment.topLeft,
          height: MediaQuery.of(context).size.height / 17,
          width: MediaQuery.of(context).size.width * 0.2,
          padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 0),
          decoration: BoxDecoration(
            border: Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.paymentEntryContainerColor : null
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedTaxSlab.isEmpty ? null : _selectedTaxSlab,
            isExpanded: true,
            alignment: Alignment.centerLeft,
            dropdownColor: themeHelper.themeMode == ThemeMode.dark
                ? ThemeNotifier.primaryBackground
                : null,
            //underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down),
            items: _taxSlabOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Color(0xFF1E2745),
                  ),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (kDebugMode) {
                print("##### _buildTaxDropdown onChanged: $newValue");
              }
              setState(() {
                _selectedTaxSlab = newValue!;
              });
            },
            decoration: InputDecoration(
             contentPadding: const EdgeInsets.only(top: 0, bottom: 10), // left + vertical center
              border: InputBorder.none, // No border at all
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            hint: Container(
                //color: Colors.blue,
                padding: EdgeInsets.only(bottom: 0),
                child: Text(TextConstants.chooseTaxSlab,
                  style: TextStyle(
                      color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.grey,fontSize: 14),)),
          ),
        ),
      ],
    );
  }




  // PAYOUTS TAB
  Widget _buildPayoutsTab() {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Column(
        children: [
          // Floating label input field
          SizedBox(
            height: 20,
          ),
          Container(
            width: MediaQuery.of(context).size.width / 2.75,
            height: MediaQuery.of(context).size.height / 12,
            margin: const EdgeInsets.only(top: 10),
            child: TextField(
              readOnly: true,
              controller: TextEditingController(
                text: _payoutAmount.isEmpty ? "${TextConstants.currencySymbol}0.00" : "${TextConstants.currencySymbol}$_payoutAmount",
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _payoutAmount.isEmpty
                    ? Colors.grey.shade400 : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark
                    : const Color(0xFF1E2745),
              ),
              decoration: InputDecoration(
                floatingLabelAlignment: FloatingLabelAlignment.center,
                labelText: TextConstants.addPaymentAmount,
                labelStyle: TextStyle(
                  fontSize: 20,
                  color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor:themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.paymentEntryContainerColor : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E2745),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E2745),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Custom Numpad
          SizedBox(
            width: MediaQuery.of(context).size.width / 2.75,
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
              onDeletePressed: () {
                setState(() {
                  _payoutAmount = _payoutAmount.isNotEmpty
                      ? _payoutAmount.substring(0, _payoutAmount.length - 1)
                      : "";
                });
              },
              actionButtonType: ActionButtonType.add,
              onAddPressed: _handleAddPayout,
              isLoading: _isPayoutLoading,
              numPadType: NumPadType.payment,
              showAddInsteadOfPay: true,
              isDarkTheme: themeHelper.themeMode == ThemeMode.dark,
            ),
          ),
        ],
      ),
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
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      width: MediaQuery.of(context).size.width / 2.75,
      height: MediaQuery.of(context).size.height / 14 ,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.grey.shade300),
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
                      : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.tabsBackground : Colors.white,
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
                    color: _isPercentageSelected ? Colors.white : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.black,
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
                  !_isPercentageSelected ? Colors.redAccent :themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.tabsBackground :  Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(9),
                    bottomRight: Radius.circular(9),
                    topLeft: Radius.circular(9),
                    bottomLeft: Radius.circular(9),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  TextConstants.currencySymbol,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: !_isPercentageSelected ? Colors.white : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.black,
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
    final themeHelper = Provider.of<ThemeNotifier>(context);
    String displayValue = _isPercentageSelected ? _discountValue : "${TextConstants.currencySymbol}$_discountValue";
    bool isPlaceholder = _discountValue == "0%" || _discountValue == "0";

    return Container(
      width: MediaQuery.of(context).size.width / 2.75,
      height: MediaQuery.of(context).size.height / 14,
      padding: const EdgeInsets.symmetric(vertical: 2), /// use this value for all inset paddings
      decoration: BoxDecoration(
        color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.paymentEntryContainerColor : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        displayValue,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isPlaceholder ?  Colors.grey : themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : const Color(0xFF1E2745),
        ),
      ),
    );
  }

  // Handle adding the discount
  //Build #1.0.78: Explanation!
  // Moved merchantDiscount update to OrderBloc.addPayout (already updated in OrderBloc to handle this).
  // Added dbOrderId parameter to addPayout call.
  // Kept local update for non-API orders (serverOrderId == null).
  // Added alert dialog with retry option for API failures.
  // Ensured _isDiscountLoading is shown during API calls and cleared afterward.
  // Preserved success toast and UI refresh logic.
  void _handleAddDiscount() async { // Build #1.0.53 : updated code with discount api call
    String discountValue = _discountValue.replaceAll('%', '').replaceAll('\$', '');
    if (discountValue.isEmpty || discountValue == "0" || double.tryParse(discountValue) == null) {
      if (kDebugMode) print("Invalid discount value: $discountValue");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid Discount"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final orderId = OrderHelper().activeOrderId;  //Build #1.0.134: get activeOrderId
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
      _isDiscountLoading = true;
    });

    try {
      // Fetch the current order total and serverOrderId from the database
      final db = await DBHelper.instance.database;
      final orderData = await db.query(
        AppDBConst.orderTable,
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );

      if (orderData.isEmpty) {
        if (kDebugMode) print("Order $orderId not found in database");
        setState(() => _isDiscountLoading = false);
        ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar( // Build #1.0.128:  updated missed condition
          const SnackBar(
            content: Text("Order not found"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final serverOrderId = orderData.first[AppDBConst.orderServerId] as int?;
      /// Build #1.0.131: Issue Fixed: now correctly calculates order total after adding percentage discounts in add screen.
      /// For example, a 2% discount on ₹137 is now shown as ₹134.26 instead of ₹134.15.
      double currentOrderTotalWithTax = orderData.first[AppDBConst.orderTotal] as double? ?? 0.0;
      double currentOrderTax = orderData.first[AppDBConst.orderTax] as double? ?? 0.0;
      double mainOrderTotal = currentOrderTotalWithTax - currentOrderTax;
      if (kDebugMode) print("Fetched order total for order $orderId: OrderTotalWithTax - $currentOrderTotalWithTax,  OrderTax - $currentOrderTax, MainOrderTotal WithOut Tax - $mainOrderTotal");

      // Calculate discount based on current order total
      double discountAmount = double.parse(discountValue);
      if (_isPercentageSelected) {
        discountAmount = (discountAmount / 100) * mainOrderTotal; // Build #1.0.131
        if (kDebugMode) print("Calculated discount amount from percentage: $discountAmount");
      }

      //Build #1.0.78: For non-API orders, update locally
      // if (serverOrderId == null) {
      //   await db.update(
      //     AppDBConst.orderTable,
      //     {
      //       AppDBConst.merchantDiscount: discountAmount,
      //     },
      //     where: '${AppDBConst.orderServerId} = ?',
      //     whereArgs: [orderId],
      //   );
      //   setState(() {
      //     _discountValue = _isPercentageSelected ? "0%" : "0";
      //     _isDiscountLoading = false;
      //   });
      //   ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
      //     SnackBar(
      //       content: Text("Discount of \$${discountAmount.toStringAsFixed(2)} applied"),
      //       backgroundColor: Colors.green,
      //       duration: const Duration(seconds: 2),
      //     ),
      //   );
      //   await _orderHelper.loadData();
      //   await _loadOrderData();
      //   widget.refreshOrderList?.call();
      //   return;
      // }

      if (serverOrderId == null) {

        ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
          SnackBar(
            content: Text("Discount of \$${discountAmount.toStringAsFixed(2)} not applied, order id $serverOrderId not found in DB"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      //Build #1.0.78: API-first approach for orders with serverOrderId
      StreamSubscription? subscription;

      subscription = orderBloc.addPayoutStream.listen((response) async {
        if (!mounted) {
          subscription?.cancel();
          return;
        }
        if (response.status == Status.COMPLETED) {
          if (kDebugMode) print("Discount confirmed via API for order $orderId");
          setState(() {
            _discountValue = _isPercentageSelected ? "0%" : "0";
          });
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text("Discount of \$${discountAmount.toStringAsFixed(2)} applied"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() => _isDiscountLoading = false); //Build #1.0.92: fixed loader issue
          await _orderHelper.loadData();
          await _loadOrderData();
          widget.refreshOrderList?.call();
          subscription?.cancel();
        } else if (response.status == Status.ERROR) {
          if (kDebugMode) print("Failed to confirm discount: ${response.message}");
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text(response.message ?? "Failed to apply discount"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );

          subscription?.cancel();
        }
      });

      await orderBloc.addPayout(orderId: serverOrderId, dbOrderId: orderId!, amount: discountAmount, isPayOut: false);
    } catch (e) {
      if (kDebugMode) print("Error processing discount: $e");
      setState(() => _isDiscountLoading = false);
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        SnackBar(
          content: Text("Error applying discount: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

// Handle adding the coupon
  void _handleAddCoupon() async {
    if (_couponCode.isEmpty || _couponCode == "0") {
      if (kDebugMode) print("### _couponCode is empty");
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid Coupon Code"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final orderId = OrderHelper().activeOrderId;  //Build #1.0.134: get activeOrderId
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

    try {

      final db = await DBHelper.instance.database;

      final orderData = await db.query( // Build #1.0.128: updated missed condition
        AppDBConst.orderTable,
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );

      if (orderData.isEmpty) {
        if (kDebugMode) print("Order $orderId not found in database");
        setState(() => _isCouponLoading = false);
        ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
          const SnackBar(
            content: Text("Order not found"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Check for existing coupon with the same couponCode
      final existingCoupons = await db.query(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemName} = ? AND ${AppDBConst.itemType} = ?',
        whereArgs: [orderId, _couponCode, ItemType.coupon.value],
      );

      if (existingCoupons.isNotEmpty) {
        if (kDebugMode) print("Coupon with code $_couponCode already exists for order $orderId");
        ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
          const SnackBar(
            content: Text("This coupon has already been applied"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isCouponLoading = false;
        });
        return;
      }

      StreamSubscription? subscription;
      if (kDebugMode) print("### Subscribing to applyCouponStream");
      subscription = orderBloc.applyCouponStream.listen((response) async {
        if (!mounted) {
          subscription?.cancel();
          return;
        }
        if (response.status == Status.COMPLETED) {
          // Insert coupons into DB, ensuring no duplicates
          for (var coupon in response.data?.couponLines ?? []) {
            if (coupon.code == null || coupon.id == null) {
              if (kDebugMode) print("Invalid coupon data: code or id is null");
              continue;
            }

            // Double-check for itemServerId to be extra safe
            final duplicateCheck = await db.query(
              AppDBConst.purchasedItemsTable,
              where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemServerId} = ?',
              whereArgs: [orderId, coupon.id],
            );

            if (duplicateCheck.isEmpty) {
              await db.insert(AppDBConst.purchasedItemsTable, {
                AppDBConst.orderIdForeignKey: orderId!,
                AppDBConst.itemServerId: coupon.id,
                AppDBConst.itemName: coupon.code!,
                AppDBConst.itemSKU: '',
                AppDBConst.itemPrice: coupon.nominalAmount?.toDouble() ?? 0.0,
                AppDBConst.itemCount: 1,
                AppDBConst.itemSumPrice: coupon.nominalAmount?.toDouble() ?? 0.0,
                AppDBConst.itemImage: 'assets/svg/coupon.svg',
                AppDBConst.itemType: ItemType.coupon.value,
              });
            }
          }

          setState(() {
            _couponCode = "";
            _isCouponLoading = false;
          });

          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text("Coupon '${_couponCode}' applied successfully"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Refresh UI
          await _orderHelper.loadData();
          await _loadOrderData();
          widget.refreshOrderList?.call();
          subscription?.cancel();
        } else if (response.status == Status.ERROR) {
          if (kDebugMode) print("Failed to apply coupon: ${response.message}");
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text(response.message ?? "Failed to apply coupon"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() {
            _isCouponLoading = false;
          });
          subscription?.cancel();
        }
      }, onError: (error) {
        if (kDebugMode) print("### applyCouponStream error: $error");
        setState(() {
          _isCouponLoading = false;
        });
        subscription?.cancel();
      });

      if (kDebugMode) print("### Calling orderBloc.applyCouponToOrder");
      await orderBloc.applyCouponToOrder(orderId: orderId!, couponCode: _couponCode);
    } catch (e) {
      if (kDebugMode) print("Error applying coupon: $e");
      setState(() {
        _isCouponLoading = false;
      });
    }
  }

  // Handle adding the custom item
  //Build #1.0.78: Explanation!
  // Moved custom item insertion and order total update to OrderBloc.updateOrderProducts.
  // Added sku to OrderLineItem for API calls.
  // Added dbOrderId parameter to updateOrderProducts.
  // Kept local insertion for non-API orders.
  // Added alert dialog with retry option for API failures.
  // Ensured _isCustomItemLoading is shown during API calls.
  // Preserved success toast, UI refresh, and field clearing logic.
  // Removed commented-out navigation code, as it’s marked as not working.
  void _handleAddCustomItem() async {
    if (kDebugMode) print("#### DEBUG 55@99 _handleAddCustomItem");

    // Validation
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
    /// COMMENT BELOW CODE -> If User want to create custom item without tax selection
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
    /// Build #1.0.128: No need to check this condition here
    // if (orderId == null) {
    //   if (kDebugMode) print("No active order selected");
    //   ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
    //     const SnackBar(
    //       content: Text("No active order selected"),
    //       backgroundColor: Colors.red,
    //       duration: Duration(seconds: 2),
    //     ),
    //   );
    //   return;
    // }

    setState(() => _isCustomItemLoading = true);

    try {
      // final db = await DBHelper.instance.database;
      // final orderData = await db.query(
      //   AppDBConst.orderTable,
      //   where: '${AppDBConst.orderServerId} = ?',
      //   whereArgs: [orderId],
      // );

      // if (orderData.isEmpty) {
      //   if (kDebugMode) print("Order $orderId not found in database");
      //   setState(() => _isCustomItemLoading = false);
      //   ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
      //     const SnackBar(
      //       content: Text("Order not found"),
      //       backgroundColor: Colors.red,
      //       duration: Duration(seconds: 2),
      //     ),
      //   );
      //   return;
      // }

    //  final serverOrderId = orderData.first[AppDBConst.orderServerId] as int?;
      final serverOrderId = OrderHelper().activeOrderId;
      //Build #1.0.78: Check for existing item with same SKU
      // final existingItems = await db.query(
      //   AppDBConst.purchasedItemsTable,
      //   where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemSKU} = ?',
      //   whereArgs: [orderId, _sku],
      // );
      //
      // ///Todo: do we neeed this condition to check?
      /// Build #1.0.128: We don't need this, why because - after api call we are clearing sku value, user cant add custom item with same sku
      // if (existingItems.isNotEmpty) {
      //   if (kDebugMode) print("Item with SKU $_sku already exists in order $orderId");
      //   setState(() => _isCustomItemLoading = false);
      //   ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
      //     const SnackBar(
      //       content: Text("Item with this SKU already added to the order"),
      //       backgroundColor: Colors.orange,
      //       duration: Duration(seconds: 2),
      //     ),
      //   );
      //   return;
      // }

      // if (serverOrderId == null) {  /// Build #1.0.128: No need to check this condition here
      //   /// For non-API orders, insert locally
      //   // await db.insert(AppDBConst.purchasedItemsTable, {
      //   //   AppDBConst.orderIdForeignKey: orderId!,
      //   //   AppDBConst.itemName: _customItemName,
      //   //   AppDBConst.itemSKU: _sku,
      //   //   AppDBConst.itemPrice: double.parse(_customItemPrice),
      //   //   AppDBConst.itemCount: 1,
      //   //   AppDBConst.itemSumPrice: double.parse(_customItemPrice),
      //   //   AppDBConst.itemImage: 'assets/svg/custom_item.svg',
      //   //   AppDBConst.itemType: ItemType.customProduct.value,
      //   // });
      //   // final items = await _orderHelper.getOrderItems(orderId!);
      //   // final orderTotal = items.fold(0.0, (sum, item) => sum + (item[AppDBConst.itemSumPrice] as num).toDouble());
      //   // await db.update(
      //   //   AppDBConst.orderTable,
      //   //   {AppDBConst.orderTotal: orderTotal},
      //   //   where: '${AppDBConst.orderServerId} = ?',
      //   //   whereArgs: [orderId],
      //   // );
      //   // setState(() {
      //   //   _customItemName = "";
      //   //   _customItemPrice = "";
      //   //   _sku = "";
      //   //   _selectedTaxSlab = _taxSlabOptions.isNotEmpty ? _taxSlabOptions.first : "";
      //   //   _customItemNameController.clear();
      //   //   _customItemPriceController.clear();
      //   //   _skuController.clear();
      //   //   _isCustomItemLoading = false;
      //   // });
      //   // ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
      //   //   SnackBar(
      //   //     content: Text("Custom item '$_customItemName' added at \$$_customItemPrice"),
      //   //     backgroundColor: Colors.green,
      //   //     duration: const Duration(seconds: 2),
      //   //   ),
      //   // );
      //   // await _orderHelper.loadData();
      //   // await _loadOrderData();
      //   // widget.refreshOrderList?.call();
      //   ///Show error instead adding to local DB and return
      //   ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
      //     SnackBar(
      //       content: Text("Custom item '$_customItemName' did not add to Order, as of Order id is not found."),
      //       backgroundColor: Colors.orange,
      //       duration: const Duration(seconds: 2),
      //     ),
      //   );
      //   return;
      // }

      // API-first approach
      List<Tax> taxes = await _assetDBHelper.getTaxList();
      String taxStatus = "";
      String taxClass = "";
      if (_selectedTaxSlab.isNotEmpty) {
        Tax? selectedTax = taxes.firstWhere(
              (tax) => tax.name == _selectedTaxSlab,
          orElse: () => taxes.isNotEmpty ? taxes.first : Tax(slug: 'none', name: _selectedTaxSlab), //Build #1.0.92
        );
        if (kDebugMode) print("selectedTax name: ${selectedTax.name}, ## slug: ${selectedTax.slug}");
        if (selectedTax.slug.isNotEmpty) {
          taxStatus = TextConstants.taxable;
          taxClass = selectedTax.slug;
        }
      }

      model.AddCustomItemRequest request = model.AddCustomItemRequest(
        name: _customItemName,
        type: TextConstants.simple,
        regularPrice: _customItemPrice,
        sku: _sku,
        taxStatus: taxStatus,
        taxClass: taxClass,
        tags: [model.Tag(name: TextConstants.customItem)],
      );

      final completer = Completer<void>();
      StreamSubscription? createSubscription;
      StreamSubscription? updateSubscription;

      createSubscription = productBloc.addCustomItemStream.listen((response) async {
        if (!mounted) {
          createSubscription?.cancel();
          completer.complete();
          return;
        }
        if (response.status == Status.COMPLETED) {
          if (kDebugMode) print("Custom item created successfully: ${response.data?.id}");

          updateSubscription = orderBloc.updateOrderStream.listen((updateResponse) async {
            if (!mounted) {
              updateSubscription?.cancel();
              createSubscription?.cancel();
              completer.complete();
              return;
            }

            if (response.status == Status.LOADING) { // Build #1.0.80
              const Center(child: CircularProgressIndicator());
            }else if (updateResponse.status == Status.COMPLETED) {
              setState(() => _isCustomItemLoading = false);
              if (kDebugMode) print("Order updated successfully for order $orderId");
              setState(() {
                _customItemName = "";
                _customItemPrice = "";
                _sku = "";
                _selectedTaxSlab = _taxSlabOptions.isNotEmpty ? _taxSlabOptions.first : "";
                _customItemNameController.clear();
                _customItemPriceController.clear();
                _skuController.clear();
              });
              ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
                SnackBar(
                  content: Text("Custom item '$_customItemName' added at \$$_customItemPrice"),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              await _orderHelper.loadData();
              await _loadOrderData();
              widget.refreshOrderList?.call();
              updateSubscription?.cancel();
              createSubscription?.cancel();
              completer.complete();
            } else if (updateResponse.status == Status.ERROR) {
              if (kDebugMode) print("Failed to update order: ${updateResponse.message}");
              ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
                SnackBar(
                  content: Text("Failed to update order"), //Build #1.0.92
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );

              updateSubscription?.cancel();
              createSubscription?.cancel();
              completer.complete();
            }
          });

          await orderBloc.updateOrderProducts(
            orderId: serverOrderId,
            dbOrderId: orderId,  // Build #1.0.128
            lineItems: [
              OrderLineItem(
                productId: response.data!.id,
                quantity: 1,
               // sku: _sku,
              ),
            ],
          );
        } else if (response.status == Status.ERROR) {
          if (kDebugMode) print("Failed to create custom item: ${response.message}");
          setState(() => _isCustomItemLoading = false);
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text("Failed to add custom item"), //Build #1.0.92
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );

          createSubscription?.cancel();
          completer.complete();
        }
      });

      await productBloc.addCustomItem(request);
      await completer.future;
    } catch (e) {
      if (kDebugMode) print("Exception in _handleAddCustomItem: $e");
      setState(() => _isCustomItemLoading = false);
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        SnackBar(
          content: Text("Error adding custom item: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Handle adding the payout
  //Build #1.0.78: Explanation!
  // Moved payout insertion to OrderBloc.addPayout.
  // Added dbOrderId parameter to addPayout.
  // Kept local insertion for non-API orders.
  // Added alert dialog with retry option for API failures.
  // Ensured _isPayoutLoading is shown during API calls.
  // Preserved success toast and UI refresh logic.
  void _handleAddPayout() async {
    if (_payoutAmount.isEmpty || _payoutAmount == "0" || double.tryParse(_payoutAmount) == null) {
      if (kDebugMode) print("Invalid payout amount: $_payoutAmount");
        ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid Payout Amount"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    final orderId = OrderHelper().activeOrderId; //Build #1.0.134: get activeOrderId
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

    setState(() => _isPayoutLoading = true);

    try {
      final db = await DBHelper.instance.database;
      final orderData = await db.query(
        AppDBConst.orderTable,
        where: '${AppDBConst.orderServerId} = ?',
        whereArgs: [orderId],
      );

      if (orderData.isEmpty) {
        if (kDebugMode) print("Order $orderId not found in database");
        setState(() => _isPayoutLoading = false);
        ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
          const SnackBar(
            content: Text("Order not found"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final serverOrderId = orderData.first[AppDBConst.orderServerId] as int?;
      double payoutAmount = double.parse(_payoutAmount);

      //Build #1.0.78: FIX - Check for existing payout for the order
      // DON'T ADD PAYOUT SAME ORDER IF ALREADY HAVE IT
      final existingPayouts = await db.query(
        AppDBConst.purchasedItemsTable,
        where: '${AppDBConst.orderIdForeignKey} = ? AND ${AppDBConst.itemType} = ?',
        whereArgs: [orderId, ItemType.payout.value],
      );

      if (existingPayouts.isNotEmpty) {
        if (kDebugMode) print("Payout already exists for order $orderId");
        setState(() => _isPayoutLoading = false);
        ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
          const SnackBar(
            content: Text("A payout has already been added for this order"),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }


      if (serverOrderId == null) {
        /// For non-API orders, insert locally
        // await db.insert(AppDBConst.purchasedItemsTable, {
        //   AppDBConst.orderIdForeignKey: orderId!,
        //   AppDBConst.itemName: TextConstants.payout,
        //   AppDBConst.itemSKU: '',
        //   AppDBConst.itemPrice: payoutAmount,
        //   AppDBConst.itemCount: 1,
        //   AppDBConst.itemSumPrice: payoutAmount,
        //   AppDBConst.itemImage: 'assets/svg/payout.svg',
        //   AppDBConst.itemType: ItemType.payout.value,
        // });
        // setState(() {
        //   _payoutAmount = "";
        //   _isPayoutLoading = false;
        // });
        // ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        //   SnackBar(
        //     content: Text("Payout of \$$payoutAmount added successfully"),
        //     backgroundColor: Colors.green,
        //     duration: const Duration(seconds: 2),
        //   ),
        // );
        // await _orderHelper.loadData();
        // await _loadOrderData();
        // widget.refreshOrderList?.call();
///Show error instead adding to local DB and return
        ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
          SnackBar(
            content: Text("Payout of \$$payoutAmount did not add, as of Order Id did not fount."),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // API-first approach
      StreamSubscription? subscription;

      subscription = orderBloc.addPayoutStream.listen((response) async {
        if (!mounted) {
          subscription?.cancel();
          return;
        }
        if (response.status == Status.COMPLETED) {
          if (kDebugMode) print("Payout added via API for order $orderId");
          setState(() {
            _payoutAmount = "";
            _isPayoutLoading = false; //Build #1.0.92: loader issue fixed
          });
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text("Payout of \$$payoutAmount added successfully"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          await _orderHelper.loadData();
          await _loadOrderData();
          widget.refreshOrderList?.call();
          subscription?.cancel();
        } else if (response.status == Status.ERROR) {
          if (kDebugMode) print("Failed to add payout: ${response.message}");
          ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
            SnackBar(
              content: Text("Failed to add payout"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );

          subscription?.cancel();
        }
      });

      await orderBloc.addPayout(orderId: serverOrderId, dbOrderId: orderId!, amount: payoutAmount, isPayOut: true);
    } catch (e) {
      if (kDebugMode) print("Error processing payout: $e");
      setState(() => _isPayoutLoading = false);
      ScaffoldMessenger.of(widget.scaffoldMessengerContext).showSnackBar(
        SnackBar(
          content: Text("Error adding payout: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Simple clipper for the tab side curves
class TabSideClipper extends CustomClipper<Path> {
  final int selectedIndex;

  TabSideClipper({required this.selectedIndex});

  @override
  Path getClip(Size size) {
    Path path = Path();
    double tabHeight = size.height / 4;
    double selectedTabTop = selectedIndex * tabHeight;
    double selectedTabBottom = selectedTabTop + tabHeight;
    double curveRadius = 16.0; // Your specified curve radius

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    // Top curve around selected tab
    if (selectedIndex > 0) {
      path.lineTo(size.width, selectedTabTop - curveRadius);
      // Smooth curve into the tab indent
      path.quadraticBezierTo(
          size.width, selectedTabTop,
          size.width - curveRadius, selectedTabTop
      );
      path.lineTo(size.width - curveRadius, selectedTabTop);
    } else {
      // If first tab is selected, start the indent from top
      path.lineTo(size.width - curveRadius, 0);
    }

    // Straight line along the tab indent
    path.lineTo(size.width - curveRadius, selectedTabBottom);

    // Bottom curve around selected tab
    if (selectedIndex < 3) {
      // Smooth curve out of the tab indent
      path.quadraticBezierTo(
          size.width, selectedTabBottom,
          size.width, selectedTabBottom + curveRadius
      );
      path.lineTo(size.width, size.height);
    } else {
      // If last tab is selected, end the indent at bottom
      path.lineTo(size.width, size.height);
    }

    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class ContentSideClipper extends CustomClipper<Path> {
  final int selectedIndex;

  ContentSideClipper({required this.selectedIndex});

  @override
  Path getClip(Size size) {
    Path path = Path();
    double tabHeight = size.height / 4;
    double selectedTabTop = selectedIndex * tabHeight;
    double selectedTabBottom = selectedTabTop + tabHeight;
    double cornerRadius = 16.0;
    double indentDepth = 16.0;

    // Start with rounded top-left corner
    path.moveTo(cornerRadius, 0);
    path.quadraticBezierTo(0, 0, 0, cornerRadius);

    // Top part before the selected tab indent
    if (selectedIndex > 0) {
      path.lineTo(0, selectedTabTop - cornerRadius);
      // Smooth curve into the indent (curves inward)
      path.quadraticBezierTo(0, selectedTabTop, cornerRadius, selectedTabTop);
      path.quadraticBezierTo(indentDepth, selectedTabTop + cornerRadius, indentDepth, selectedTabTop + cornerRadius * 2);
    } else {
      // If first tab is selected, start indent from top
      path.lineTo(0, cornerRadius);
      path.quadraticBezierTo(cornerRadius, cornerRadius, indentDepth, cornerRadius * 2);
    }

    // Middle of the indent (straight line)
    path.lineTo(indentDepth, selectedTabBottom - cornerRadius * 2);

    // Bottom part - curve out of the selected tab indent
    path.quadraticBezierTo(indentDepth, selectedTabBottom - cornerRadius, cornerRadius, selectedTabBottom);
    path.quadraticBezierTo(0, selectedTabBottom, 0, selectedTabBottom + cornerRadius);

    // Now add the outward bulge for the tab below the selected one
    if (selectedIndex < 3) {
      double nextTabTop = selectedTabBottom + cornerRadius;
      double nextTabBottom = nextTabTop + tabHeight - (cornerRadius * 2);

      // Go down a bit then curve outward (bulge)
      path.lineTo(0, nextTabTop);
      path.quadraticBezierTo(-cornerRadius, nextTabTop + cornerRadius, -cornerRadius, nextTabTop + cornerRadius * 2);
      path.lineTo(-cornerRadius, nextTabBottom - cornerRadius);
      path.quadraticBezierTo(-cornerRadius, nextTabBottom, 0, nextTabBottom + cornerRadius);

      if (selectedIndex < 2) {
        // Continue to bottom if not the second-to-last tab
        path.lineTo(0, size.height - cornerRadius);
      } else {
        // Go to bottom
        path.lineTo(0, size.height - cornerRadius);
      }
    } else {
      // Last tab selected, just go to bottom
      path.lineTo(0, size.height - cornerRadius);
    }

    // Rounded bottom-left corner
    path.quadraticBezierTo(0, size.height, cornerRadius, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}