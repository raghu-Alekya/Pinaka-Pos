import 'package:flutter/material.dart';

class QuantityControl extends StatelessWidget {
  final TextEditingController controller;
  final int quantity;
  final Function(int) onDecrement;
  final Function(int) onIncrement;

  const QuantityControl({
    Key? key,
    required this.controller,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.05 ,
      width: MediaQuery.of(context).size.width /3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0xFF1BA672),
      ),
      child: Row(
        children: [
          // Minus button
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () {
                if (quantity > 0) onDecrement(quantity - 1);
              },
              child: Container(
                alignment: Alignment.center,
                height: double.infinity,
                child: const Text(
                  "−",  // Using minus sign, not hyphen
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Quantity display
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              height: double.infinity,
              color: Colors.white,
              child: Text(
                controller.text.isEmpty ? "0" : controller.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Plus button
          Expanded(
            flex: 1,
            child: InkWell(
              onTap: () {
                onIncrement(quantity + 1);
              },
              child: Container(
                alignment: Alignment.center,
                height: double.infinity,
                child: const Text(
                  "+",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}