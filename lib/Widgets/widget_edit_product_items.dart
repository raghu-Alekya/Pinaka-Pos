import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Widgets/widget_quantity_input_control.dart';
import 'package:provider/provider.dart';
import '../Constants/text.dart';
import '../Database/db_helper.dart';
import '../Helper/Extentions/theme_notifier.dart';
import '../Widgets/widget_custom_num_pad.dart';

class ProductEditScreen extends StatefulWidget {
  final Map<String, dynamic> orderItem;
  final Function(int) onQuantityUpdated;

  const ProductEditScreen({
    Key? key,
    required this.orderItem,
    required this.onQuantityUpdated,
  }) : super(key: key);

  @override
  _ProductEditScreenState createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  late TextEditingController controller;
  late int quantity;
  late var _regularPrice;
  @override
  void initState() {
    super.initState();
    quantity = widget.orderItem[AppDBConst.itemCount];
    var orderItem = widget.orderItem;

    _regularPrice =  (orderItem[AppDBConst.itemRegularPrice] == null || (orderItem[AppDBConst.itemRegularPrice]?.toDouble() ?? 0.0) == 0.0)
        ? orderItem[AppDBConst.itemUnitPrice]?.toDouble() ?? 0.0
        : orderItem[AppDBConst.itemRegularPrice]!.toDouble();
    controller = TextEditingController(
        text: quantity == 0 ? "0" : quantity.toString()
    );
  }

  void updateQuantity(int newQuantity) {
    // if(newQuantity == 0 )
    //   return;
    setState(() {
      quantity = newQuantity;
      controller.text = quantity == 0 ? "0" : quantity.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Center(
      child: Card(
        elevation: 8,
        margin: EdgeInsets.only(top: 10),
        color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.65,
          height: MediaQuery.of(context).size.height * 0.9, // Reduced from 0.9 to 0.85
          padding: const EdgeInsets.all(5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 1,
                  child: SizedBox()),
              Column(
                children: [
                  // Title with close button
                  // Text(
                  //   TextConstants.editProductText,
                  //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  //   textAlign: TextAlign.center,
                  // ),
                  const SizedBox(height: 10),

                  // Product information
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3,
                      height: MediaQuery.of(context).size.height * 0.16, // Reduced from 0.16 to 0.14
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              spreadRadius: 5,
                              blurRadius: 5,
                              offset: Offset(0, 0),
                            )
                          ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Product Image
                          Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.borderColor : Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _buildProductImage(),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Product details
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.23,
                                child: Text(
                                  widget.orderItem[AppDBConst.itemName],
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Unit Price: ${TextConstants.currencySymbol}${(_regularPrice).toStringAsFixed(2)}",
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Total: ${TextConstants.currencySymbol}${(quantity * _regularPrice).toStringAsFixed(2)}",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10), // Reduced from 15 to 10

                  // Quantity controls
                  QuantityControl(
                    controller: controller,
                    quantity: quantity,
                    onDecrement: updateQuantity,
                    onIncrement: updateQuantity,
                  ),
                  const SizedBox(height: 10), // Reduced from 10 to 8

                  // NumPad - Make it flexible to take remaining space
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width / 2.65,
                      child: CustomNumPad(
                        isDarkTheme: themeHelper.themeMode == ThemeMode.dark,
                        onDigitPressed: (digit) {
                          setState(() {
                            int newQty = int.tryParse((controller.text.isEmpty ? "0" : controller.text) + digit) ?? quantity;
                            updateQuantity(newQty);
                          });
                        },
                        onClearPressed: () => updateQuantity(0),
                        onAddPressed: () {
                          widget.onQuantityUpdated(quantity);
                          Navigator.pop(context);
                        },
                        actionButtonType: ActionButtonType.add,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(
                flex: 1,
              ),
              Container(
                width: 50.0,
                height: 40.0,
                margin: EdgeInsets.only(top: 15, right: 15),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
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
  Widget _buildProductImage() {
    if (widget.orderItem[AppDBConst.itemImage].toString().startsWith('http')) {
      return SizedBox(
        child: Image.network(
          widget.orderItem[AppDBConst.itemImage],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return SvgPicture.asset(
              'assets/svg/password_placeholder.svg',
              fit: BoxFit.cover,
            );
          },
        ),
      );
    } else if (widget.orderItem[AppDBConst.itemImage].toString().startsWith('assets/')) {
      return SvgPicture.asset(
        widget.orderItem[AppDBConst.itemImage],
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(widget.orderItem[AppDBConst.itemImage]),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SvgPicture.asset(
            'assets/svg/password_placeholder.svg',
            fit: BoxFit.cover,
          );
        },
      );
    }
  }
}