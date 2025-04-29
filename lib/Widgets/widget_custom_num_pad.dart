import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_pos/Widgets/widget_payment_dialog.dart';

import '../Constants/text.dart';

enum ActionButtonType { delete, ok, add, pay }

class CustomNumPad extends StatelessWidget {
  final Function(String) onDigitPressed;
  final VoidCallback onClearPressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onConfirmPressed;
  final VoidCallback? onAddPressed;
  final VoidCallback? onPayPressed;
  final ActionButtonType actionButtonType;
  final bool isPayment;
  final String Function()? getPaidAmount; // Build #1.0.29: Change to a callback
  final double? balanceAmount; // Build #1.0.29 : Added to compare with paid amount

  const CustomNumPad({
    super.key,
    required this.onDigitPressed,
    required this.onClearPressed,
    this.onDeletePressed,
    this.onConfirmPressed,
    this.onAddPressed,
    this.onPayPressed,
    this.actionButtonType = ActionButtonType.delete,
    this.isPayment = false,
    this.getPaidAmount,
    this.balanceAmount,
  });

  @override
  Widget build(BuildContext context) {
    bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    double paddingValue = isPortrait ? 16 : 30;

    if (isPayment) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: paddingValue),
        height: MediaQuery.of(context).size.height * 0.4125,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    double buttonHeight = (constraints.maxHeight - 24) / 4;
                    double buttonWidth = (constraints.maxWidth / 3) - 8;
                    double aspectRatio = buttonWidth / buttonHeight;
                    if (aspectRatio <= 0) aspectRatio = 1.0;

                    return Container(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: GridView.count(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: aspectRatio,
                        children: [
                          _buildKey("7"),
                          _buildKey("8"),
                          _buildKey("9"),
                          _buildKey("4"),
                          _buildKey("5"),
                          _buildKey("6"),
                          _buildKey("1"),
                          _buildKey("2"),
                          _buildKey("3"),
                          _buildKey("00"),
                          _buildKey("0"),
                          _buildKey("."),
                        ],
                      ),
                    );
                  }
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildBackspaceKey()),
                  const SizedBox(height: 12),
                  Expanded(child: _buildClearKey()),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 2,
                    child: _buildPayButton(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Original numpad layout remains unchanged
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      padding: EdgeInsets.symmetric(horizontal: paddingValue),
      children: [
        ...List.generate(9, (index) {
          return _buildKey((index + 1).toString());
        }),
        _buildActionKey(
          text: TextConstants.clearText,
          onPressed: onClearPressed,
          color: Colors.white,
          textColor: Colors.black,
        ),
        _buildKey("0"),
        _buildActionKey(
          text: _getActionButtonText(),
          onPressed: _getActionButtonCallback(),
          color: _getActionButtonColor(),
          textColor: _getActionButtonTextColor(),
        ),
      ],
    );
  }

  // Update _buildPayButton
  Widget _buildPayButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFF4444),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          String paidAmount = getPaidAmount!(); // Build #1.0.29 : check the conditions based show popUp dialogs
          String cleanAmount = paidAmount.replaceAll('\$', '').trim();
          double amount = double.tryParse(cleanAmount) ?? 0.0;
          if (amount == 0.0) {
            if (kDebugMode) {
              print("#### paidAmount: $paidAmount, cleanAmount: $cleanAmount, amount: $amount");
            }
            return;
          }
          if (onPayPressed != null) {
            onPayPressed!();
          }
          if (amount < balanceAmount!) {
            _showPartialPaymentDialog(context, amount);
          } else {
            _showPaymentDialog(context, amount);
          }
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'PAY',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Update dialog methods
  void _showPartialPaymentDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        status: PaymentStatus.partial,
        mode: PaymentMode.cash,
        amount: amount,
        onVoid: () {
          Navigator.of(context).pop();
          // Handle void logic
        },
        onNextPayment: () {
          Navigator.of(context).pop();
          // Show successful payment dialog
          // showDialog(
          //   context: context,
          //   barrierDismissible: false,
          //   builder: (context) => PaymentDialog(
          //     status: PaymentStatus.successful,
          //     mode: PaymentMode.cash,
          //     amount: 50.00,  // Total amount after all payments
          //     onVoid: () {
          //       Navigator.of(context).pop();
          //       // Handle void logic
          //     },
          //     onPrint: () {
          //       Navigator.of(context).pop();
          //       // Show receipt dialog
          //       _showReceiptDialog(context);
          //     },
          //   ),
          // );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        status: PaymentStatus.successful,
        mode: PaymentMode.cash,
        amount: amount,
        onVoid: () {
          Navigator.of(context).pop();
        },
        onPrint: () {
          Navigator.of(context).pop();
          _showReceiptDialog(context, amount);
        },
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        status: PaymentStatus.receipt,
        mode: PaymentMode.cash,
        amount: amount,
        onPrint: () {},
        onEmail: (email) {},
        onSMS: (phone) {},
        onNoReceipt: () {
          Navigator.of(context).pop();
        },
        onDone: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Get Action Button Text
  String _getActionButtonText() {
    switch (actionButtonType) {
      case ActionButtonType.ok:
        return TextConstants.okText;
      case ActionButtonType.add:
        return TextConstants.addText;
      default:
        return TextConstants.deleteText;
    }
  }

  // Get Action Button Callback
  VoidCallback _getActionButtonCallback() {
    switch (actionButtonType) {
      case ActionButtonType.ok:
        return onConfirmPressed ?? () {};
      case ActionButtonType.add:
        return onAddPressed ?? () {};
      default:
        return onDeletePressed ?? () {};
    }
  }

  // Get Action Button Color
  Color _getActionButtonColor() {
    return (actionButtonType == ActionButtonType.ok || actionButtonType == ActionButtonType.add)
        ? const Color(0xFF1E2745) // OK & Add use same color
        : Colors.white;
  }

  // Get Action Button Text Color
  Color _getActionButtonTextColor() {
    return (actionButtonType == ActionButtonType.ok || actionButtonType == ActionButtonType.add)
        ? Colors.white
        : Colors.black;
  }

  // Build Numeric Key
  Widget _buildKey(String value) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)), // Light grey border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () => onDigitPressed(value),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // Build Action Key (Clear, Delete/OK/Add)
  Widget _buildActionKey({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    required Color textColor,
    Widget? child,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: child ?? Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
      ),
    );
  }

  // New method for backspace key
  Widget _buildBackspaceKey() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)), // Light grey border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onDeletePressed ?? () {},
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Icon(Icons.backspace_outlined, color: Colors.black, size: 20),
      ),
    );
  }

  // New method for clear key
  Widget _buildClearKey() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)), // Light grey border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onClearPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'C',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}