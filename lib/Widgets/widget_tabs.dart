import 'package:flutter/material.dart';

// Import your custom numpad
import 'widget_custom_num_pad.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  // Tab selection
  int _selectedTabIndex = 0;

  // Discount values
  String _discountValue = "0%";
  bool _isPercentageSelected = true;

  // Coupon value
  String _couponCode = "123456789";

  // Custom item values
  String _customItemName = "Custom Item";
  String _customItemPrice = "0.00";
  String _sku = "Generate the SKU";

  // Tax slab options
  final List<String> _taxSlabOptions = ['No Tax', 'GST 5%', 'GST 12%', 'GST 18%', 'GST 28%'];
  String _selectedTaxSlab = 'No Tax';

  // Payout value
  String _payoutAmount = "0.00";

  // Text editing controllers
  final TextEditingController _customItemNameController = TextEditingController(text: "Custom Item");
  final TextEditingController _customItemPriceController = TextEditingController(text: "0.00");
  final TextEditingController _skuController = TextEditingController(text: "Generate the SKU");

  @override
  void initState() {
    super.initState();
    _customItemNameController.text = _customItemName;
    _customItemPriceController.text = _customItemPrice;
    _skuController.text = _sku;
  }

  @override
  void dispose() {
    _customItemNameController.dispose();
    _customItemPriceController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10.0),
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade50,),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Tabs
            _buildTabs(),

            const SizedBox(height: 20),

            // Content based on selected tab
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  // Build the top tabs
  Widget _buildTabs() {
    return Row(
      children: [
        _buildTab(0, Icons.percent, "Discounts"),
        const SizedBox(width: 10),
        _buildTab(1, Icons.confirmation_num_outlined, "Coupons"),
        const SizedBox(width: 10),
        _buildTab(2, Icons.shopping_bag_outlined, "Custom Item"),
        const SizedBox(width: 10),
        _buildTab(3, Icons.receipt_outlined, "Payouts"),
      ],
    );
  }

  // Build individual tab
  Widget _buildTab(int index, IconData icon, String text) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
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
    switch (_selectedTabIndex) {
      case 0:
        return _buildDiscountsTab();
      case 1:
        return _buildCouponsTab();
      case 2:
        return _buildCustomItemTab();
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
          "Apply discount to sale",
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
              setState(() {
                if (_discountValue == "0%" || _discountValue == "\$0") {
                  _discountValue = digit + (_isPercentageSelected ? "%" : "");
                } else {
                  // Remove % or $ if present
                  String currentValue =
                  _discountValue.replaceAll('%', '').replaceAll('\$', '');
                  // Add digit
                  currentValue += digit;
                  // Re-add % if needed
                  _discountValue =
                      currentValue + (_isPercentageSelected ? "%" : "");
                }
              });
            },
            onClearPressed: () {
              setState(() {
                _discountValue = _isPercentageSelected ? "0%" : "\$0";
              });
            },
            actionButtonType: ActionButtonType.add,
            onAddPressed: () {
              // Handle adding the discount
              _handleAddDiscount();
            },
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
          "Enter coupon code",
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
            _couponCode.isEmpty ? "1234567890" : _couponCode,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2745),
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
            actionButtonType: ActionButtonType.add,
            onAddPressed: () {
              // Handle adding the coupon
              _handleAddCoupon();
            },
          ),
        ),
      ],
    );
  }

  // CUSTOM ITEM TAB
  Widget _buildCustomItemTab() {
    return
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Row: Name & SKU
          Row(
            children: [
              // Name Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Name",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E2745),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: MediaQuery.of(context).size.height / 15,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        textAlign: TextAlign.left,
                        controller: _customItemNameController,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: "Custom Item Name",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // SKU Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SKU",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E2745),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: MediaQuery.of(context).size.height /15,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _skuController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Generate the SKU",
                          contentPadding: const EdgeInsets.only(left: 15, right: 15),
                          suffix: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: _generateSku,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(70, 40),
                              ),
                              child: const Text(
                                "Generate",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Second Row: Item Price & Tax
          Row(
            children: [
              // Item Price Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Item Price",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E2745),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: MediaQuery.of(context).size.height / 15,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _customItemPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixText: "\$",
                          contentPadding: EdgeInsets.symmetric(horizontal: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Tax Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tax",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E2745),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: MediaQuery.of(context).size.height /15,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedTaxSlab,
                        icon: const Icon(Icons.arrow_drop_down),
                        isExpanded: true,
                        underline: Container(),
                        items: _taxSlabOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedTaxSlab = newValue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Custom Numpad
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2.5,
              height: MediaQuery.of(context).size.height / 2.275,
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
                    _customItemPrice = "0.00";
                    _customItemPriceController.text = "0.00";
                  });
                },
                actionButtonType: ActionButtonType.add,
                onAddPressed: () {
                  _handleAddCustomItem();
                },
              ),
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
                "\$${_payoutAmount}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2745),
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
                    "Add Payout Amount",
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
                if (_payoutAmount == "0.00") {
                  _payoutAmount = digit;
                } else {
                  _payoutAmount += digit;
                }
              });
            },
            onClearPressed: () {
              setState(() {
                _payoutAmount = "0.00";
              });
            },
            actionButtonType: ActionButtonType.add,
            onAddPressed: () {
              // Handle adding the payout
              _handleAddPayout();
            },
          ),
        ),
      ],
    );
  }

  // Generate SKU function
  void _generateSku() {
    // Simple SKU generation logic - prefix + timestamp
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    String prefix = _customItemName.isNotEmpty
        ? _customItemName.substring(0, _customItemName.length > 3 ? 3 : _customItemName.length).toUpperCase()
        : "ITM";

    setState(() {
      _sku = "$prefix-$timestamp";
      _skuController.text = _sku;
    });

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("SKU generated successfully"),
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
    return Container(
      width: MediaQuery.of(context).size.width / 2.75,
      height: MediaQuery.of(context).size.height / 14,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        _isPercentageSelected ? _discountValue : "\$${_discountValue}",
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E2745),
        ),
      ),
    );
  }

  // Handle adding the discount
  void _handleAddDiscount() {
    // Here you would add the logic to apply the discount
    // This is where you'd connect to your state management solution
    String discountAmount = _discountValue;
    print("Applied discount: $discountAmount");

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Discount of $discountAmount applied successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Handle adding the coupon
  void _handleAddCoupon() {
    // Here you would add the logic to apply the coupon
    print("Applied coupon: $_couponCode");

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Coupon '$_couponCode' applied successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Handle adding the custom item
  void _handleAddCustomItem() {
    // Here you would add the logic to add a custom item
    print("Added custom item: $_customItemName at \$$_customItemPrice with tax: $_selectedTaxSlab, SKU: $_sku");

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text("Custom item '$_customItemName' added at \$$_customItemPrice with $_selectedTaxSlab"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Handle adding the payout
  void _handleAddPayout() {
    // Here you would add the logic to add a payout
    print("Added payout amount: \$$_payoutAmount");

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payout of \$$_payoutAmount added successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }
}