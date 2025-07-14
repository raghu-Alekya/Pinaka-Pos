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

  @override
  void initState() {
    super.initState();
    quantity = widget.orderItem[AppDBConst.itemCount];
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
        color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(5.0),
          child: Column(
            //mainAxisSize: MainAxisSize.min,
            children: [
              // Title with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      TextConstants.editProductText,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 50.0,
                    height: 40.0,
                    margin: EdgeInsets.only(top: 10, right: 15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close,color: Colors.white,size: 20,),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Product information
              Center(
                child: Container(
                  //width: MediaQuery.of(context).size.width * 0.2,
                  width: MediaQuery.of(context).size.width /3,
                  height: MediaQuery.of(context).size.height * 0.16,
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
                    mainAxisSize: MainAxisSize.min, // This makes the Row take only needed width
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
                          Container(
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
                            "Unit Price: ${TextConstants.currencySymbol}${widget.orderItem[AppDBConst.itemPrice].toStringAsFixed(2)}",
                            style: TextStyle(fontSize: 12,
                                //color: Colors.grey.shade700
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                          //  "Total: \$${(quantity * widget.orderItem[AppDBConst.itemCount] * widget.orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}",
                            "Total: ${TextConstants.currencySymbol}${(quantity * widget.orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}", //Build 1.1.36
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
              const SizedBox(height: 15),

              // Quantity controls -- Using our new stateless widget
              QuantityControl(
                controller: controller,
                quantity: quantity,
                onDecrement: updateQuantity,
                onIncrement: updateQuantity,
              ),
              const SizedBox(height: 15,),

              // NumPad
              SizedBox(
                //color: Colors.red,
                //margin: EdgeInsets.all(5.0),
                //padding: EdgeInsets.all(2.0),
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width /2.65,
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
              // Action buttons
              // Container(
              //   height: MediaQuery.of(context).size.height * 0.070,
              //   padding: EdgeInsets.all(5.0),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     //crossAxisAlignment: CrossAxisAlignment.center,
              //     children: [
              //       TextButton(
              //         onPressed: () => Navigator.pop(context),
              //         child: Text('Cancel',style: TextStyle(fontSize: 20.0,color: Colors.redAccent),),
              //         style:
              //         TextButton.styleFrom(
              //           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              //         ),
              //       ),
              //       const SizedBox(width: 10),
              //       ElevatedButton(
              //         onPressed: () {
              //           widget.onQuantityUpdated(quantity);
              //           Navigator.pop(context);
              //         },
              //         child: Text('Update',style: TextStyle(fontSize: 20.0,color: Colors.white),),
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: Colors.green,
              //           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (widget.orderItem[AppDBConst.itemImage].toString().startsWith('http')) {
      return Image.network(
        widget.orderItem[AppDBConst.itemImage],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SvgPicture.asset(
            'assets/svg/password_placeholder.svg',
            fit: BoxFit.cover,
          );
        },
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