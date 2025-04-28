import 'dart:ui'; // Required for ImageFilter.blur
import 'package:flutter/material.dart';
import 'widget_quantity_input_control.dart'; // Adjust path if needed

class VariantsDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> variants;

  const VariantsDialog({
    Key? key,
    required this.title,
    required this.variants,
  }) : super(key: key);

  @override
  State<VariantsDialog> createState() => _VariantsDialogState();
}

class _VariantsDialogState extends State<VariantsDialog> with SingleTickerProviderStateMixin {
  int? selectedVariantIndex;
  TextEditingController quantityController = TextEditingController(text: "1");
  int quantity = 1;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> closeDialog() async {
    await _animationController.reverse();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Blur
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.2),
          ),
        ),

        // Dialog Center
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.grey.shade200, // Light grey background
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800, minHeight: 500),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),

                      // Row ➔ Column (left) + Close button (right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Choose Variants",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: closeDialog,
                            child: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              radius: 20,
                              child: Icon(Icons.close, size: 24, color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Variant List
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Row(
                            children: List.generate(widget.variants.length, (index) {
                              final variant = widget.variants[index];
                              bool isSelected = selectedVariantIndex == index;
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      spreadRadius: 2,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        variant["image"],
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      variant["name"],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "\$${variant["price"]}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    isSelected
                                        ? QuantityControl(
                                      controller: quantityController,
                                      quantity: quantity,
                                      onDecrement: (newQuantity) {
                                        setState(() {
                                          quantity = newQuantity;
                                          quantityController.text = quantity.toString();
                                          if (quantity == 0) {
                                            selectedVariantIndex = null; // Reset to Add
                                          }
                                        });
                                      },
                                      onIncrement: (newQuantity) {
                                        setState(() {
                                          quantity = newQuantity;
                                          quantityController.text = quantity.toString();
                                        });
                                      },
                                    )
                                        : SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedVariantIndex = index;
                                            quantity = 1;
                                            quantityController.text = "1";
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 50),
                                          side: const BorderSide(color: Color(0xFF1BA672)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          "Add",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1BA672),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Done Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: closeDialog,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFF1BA672),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Done",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
