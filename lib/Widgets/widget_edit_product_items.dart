import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../Constants/text.dart';
import '../Database/db_helper.dart';
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
        text: quantity == 0 ? "" : quantity.toString()
    );
  }

  void updateQuantity(int newQuantity) {
    setState(() {
      quantity = newQuantity;
      controller.text = quantity == 0 ? "" : quantity.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      TextConstants.editProductText,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product information
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min, // This makes the Row take only needed width
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product Image
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
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
                      children: [
                        Text(
                          widget.orderItem[AppDBConst.itemName],
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Unit Price: \$${widget.orderItem[AppDBConst.itemPrice].toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Total: \$${(quantity * widget.orderItem[AppDBConst.itemCount] * widget.orderItem[AppDBConst.itemPrice]).toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Quantity controls
              Container(
                width: MediaQuery.of(context).size.width /3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  color: Colors.grey.shade100,
                ),
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Decrement Button
                    IconButton(
                      icon: Icon(Icons.remove_circle, size: 32, color: Colors.redAccent),
                      onPressed: () {
                        if (quantity > 0) updateQuantity(quantity - 1);
                      },
                    ),

                    // Quantity TextField
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        readOnly: true,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: controller.text.isEmpty ? FontWeight.normal : FontWeight.bold,
                          color: controller.text.isEmpty ? Colors.grey : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "00",
                          hintStyle: TextStyle(fontSize: 28, color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    // Increment Button
                    IconButton(
                      icon: Icon(Icons.add_circle, size: 32, color: Colors.green),
                      onPressed: () {
                        updateQuantity(quantity + 1);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30,),

              // NumPad
              Container(
                //color: Colors.red,
                //margin: EdgeInsets.all(5.0),
                //padding: EdgeInsets.all(2.0),
                height: MediaQuery.of(context).size.height * 0.45,
                width: MediaQuery.of(context).size.width /2.75,
                child: CustomNumPad(
                  onDigitPressed: (digit) {
                    setState(() {
                      int newQty = int.tryParse((controller.text.isEmpty ? "0" : controller.text) + digit) ?? quantity;
                      updateQuantity(newQty);
                    });
                  },
                  onClearPressed: () => updateQuantity(0),
                  onConfirmPressed: () {
                    widget.onQuantityUpdated(quantity);
                    Navigator.pop(context);
                  },
                  actionButtonType: ActionButtonType.ok,
                ),
              ),

              const SizedBox(height: 30,),

              // Action buttons
              Container(
                height: MediaQuery.of(context).size.height * 0.070,
                padding: EdgeInsets.all(5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',style: TextStyle(fontSize: 20.0),),
                      style:
                      TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        widget.onQuantityUpdated(quantity);
                        Navigator.pop(context);
                      },
                      child: Text('Update',style: TextStyle(fontSize: 20.0),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
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