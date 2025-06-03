import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_pos/Widgets/widget_payment_dialog.dart';

import '../Constants/text.dart';

enum ActionButtonType { delete, ok, add, pay }
enum NumPadType { payment, login, age }

class CustomNumPad extends StatelessWidget {
  final Function(String) onDigitPressed;
  final VoidCallback onClearPressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onConfirmPressed;
  final VoidCallback? onAddPressed;
  final VoidCallback? onPayPressed;
  final ActionButtonType actionButtonType;
  // final bool isPayment;
  // final bool isAgeVerification; // New parameter for age verification layout
  final String Function()? getPaidAmount; // Build #1.0.29: Change to a callback
  final double? balanceAmount; // Build #1.0.29 : Added to compare with paid amount
  final bool? isLoading; // Add isLoading
  final NumPadType numPadType;

  const CustomNumPad({
    super.key,
    required this.onDigitPressed,
    required this.onClearPressed,
    this.onDeletePressed,
    this.onConfirmPressed,
    this.onAddPressed,
    this.onPayPressed,
    this.actionButtonType = ActionButtonType.delete,
    // this.isPayment = false,
    // this.isAgeVerification = false, // Default to false
    this.getPaidAmount,
    this.balanceAmount,
    this.isLoading, // Require isLoading
    this.numPadType = NumPadType.login,
  });

  @override
  Widget build(BuildContext context) {
    bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    double paddingValue = isPortrait ? 16 : 30;

    switch (numPadType) {
      case NumPadType.age:
        return _buildAgeVerificationPad(context, paddingValue);
      case NumPadType.payment:
        return _buildPaymentPad(context, paddingValue);
      case NumPadType.login:
      default:
        return _buildLoginPad(context, paddingValue);
    }
  }


  Widget _buildPaymentPad(BuildContext context, double paddingValue) {
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

// Age Verification Layout
  Widget _buildAgeVerificationPad(BuildContext context, double paddingValue) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Numbers 1-9 in 3x3 grid
          Expanded(
            flex: 3,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2,
              children: [
                _buildKey("1"),
                _buildKey("2"),
                _buildKey("3"),
                _buildKey("4"),
                _buildKey("5"),
                _buildKey("6"),
                _buildKey("7"),
                _buildKey("8"),
                _buildKey("9"),
              ],
            ),
          ),
          // Bottom row with Clear and 0
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildClearKeyForAge(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKey("0"),
                ),
              ],
            ),
          ),
          // // Action buttons
          // Expanded(
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: _buildManualVerifyButton(),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: _buildVerifyAgeButton(),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // Original numpad layout remains unchanged
  Widget _buildLoginPad(BuildContext context, double paddingValue){
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
          isAddButton: false, // Build #1.0.53 : Explicitly mark as not Add button
        ),
        _buildKey("0"),
        _buildActionKey(
          text: _getActionButtonText(),
          onPressed: _getActionButtonCallback(),
          color: _getActionButtonColor(),
          textColor: _getActionButtonTextColor(),
          isAddButton: true, // Build #1.0.53 : Mark as Add button
        ),
      ],
    );
  }



  // Remove _buildPayButton, _showPartialPaymentDialog, _showPaymentDialog, _showReceiptDialog
 // Build #1.0.34: Update _buildPayButton to only call onPayPressed
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
        onPressed: onPayPressed, //Build #1.0.34
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading! //Build 1.1.36: loader for PAY button
            ? const SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
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

  // // New method for Manual Verify button
  // Widget _buildManualVerifyButton() {
  //   return Container(
  //     width: double.infinity,
  //     height: 50,
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF4A5568), // Dark blue-gray color
  //       borderRadius: BorderRadius.circular(8),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           blurRadius: 4,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: TextButton(
  //       onPressed: onManualVerifyPressed ?? () {},
  //       style: TextButton.styleFrom(
  //         padding: EdgeInsets.zero,
  //         backgroundColor: Colors.transparent,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //       ),
  //       child: const Text(
  //         'Manually Verified',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w500,
  //           color: Colors.white,
  //         ),
  //       ),
  //     ),
  //   );
  // }
  //
  // // New method for Verify Age button
  // Widget _buildVerifyAgeButton() {
  //   return Container(
  //     width: double.infinity,
  //     height: 50,
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFE2E8F0), // Light gray color
  //       borderRadius: BorderRadius.circular(8),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           blurRadius: 4,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: TextButton(
  //       onPressed: onVerifyPressed ?? () {},
  //       style: TextButton.styleFrom(
  //         padding: EdgeInsets.zero,
  //         backgroundColor: Colors.transparent,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //       ),
  //       child: const Text(
  //         'Verify Age',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w500,
  //           color: Color(0xFF4A5568),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // New method for Clear key in age verification (with orange border)
  Widget _buildClearKeyForAge() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF6B35), width: 2), // Orange border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 0),
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
          'Clear',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFFFF6B35), // Orange text
          ),
        ),
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
    bool isAddButton = false, // Add flag to identify Add button
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
      child: (isLoading ?? false) && isAddButton && actionButtonType == ActionButtonType.add
          ? const SizedBox( // Build #1.0.53 : updated condition
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : child ??
          Text(
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