import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomDialog {
  static Future<void> showInvalidCoupon(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: 'Invalid Coupon',
      description: 'The coupon code you entered is not valid. Please check the code and try again.', /// i will add them into Text constants file later
      buttonText: 'Let\'s, Try Again',
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<void> showDiscountNotApplied(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: 'Discount Not Applied',
      description: 'The discount couldn’t be applied. Please double-check the eligibility criteria.',
      buttonText: 'Let\'s, Try Again',
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<bool?> showRemoveDiscountConfirmation(BuildContext context) {
    return _showConfirmDialog(
      context,
      title: 'Remove applied discount\nOr coupon?',
      description: 'This action cannot be undone. The item will return to its original price.',
      confirmText: 'Remove',
      cancelText: 'Close',
      iconPath: 'assets/svg/check_broken_alert.svg',
    );
  }

  static Future<bool?> showAreYouSure(BuildContext context) {
    return _showConfirmDialog(
      context,
      title: 'Are you sure ?',
      description: 'Do you want to really delete the records? This process cannot be undone.',
      confirmText: 'Yes, Delete!',
      cancelText: 'No, Keep it.',
      iconPath: 'assets/svg/check_broken_alert.svg',
    );
  }

  static Future<void> showCustomItemAlert(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: 'Custom Item Alert',
      description: 'You\'re about to add a custom item. Make sure the item details are accurate before proceeding.',
      buttonText: 'Add Custom Item',
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<void> showCouponNotApplied(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: 'Coupon Not Applied',
      description: 'The coupon couldn’t be applied. Please double-check the eligibility criteria or try a different code.',
      buttonText: 'Let\'s, Try Again',
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<void> showInvalidDiscount(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: 'Invalid Discount',
      description: 'The discount entered is not valid. Please review the discount details.',
      buttonText: 'Let\'s, Try Again',
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<void> showCustomItemNotAdded(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: 'Custom item could not be added',
      description: 'Please check the items and try again. Contact your manager if the issue continues.',
      buttonText: 'Let\'s, Try Again',
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }


  // Internal - for simple alert dialogs
  static Future<void> _showSimpleDialog(
      BuildContext context, {
        required String title,
        required String description,
        required String buttonText,
        required String iconPath,
        bool showCloseIcon = false,
      }) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // Set a specific width constraint
        insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.35,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Stack(
              children: [
                if (showCloseIcon)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        radius: 20,
                        child: Icon(Icons.close, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: showCloseIcon ? 32 : 0),
                    SvgPicture.asset(iconPath, height: 50),
                    const SizedBox(height: 16),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(description,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFE6464),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(buttonText, style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Internal - for confirmation dialog
  static Future<bool?> _showConfirmDialog(
      BuildContext context, {
        required String title,
        required String description,
        required String confirmText,
        required String cancelText,
        required String iconPath,
      }) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // Set a specific width constraint
        insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.35,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(iconPath, height: 48),
                const SizedBox(height: 16),
                Text(title,
                    style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(description,
                    style: const TextStyle(fontSize: 14, color: Color(0xFFD0CCCC)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false), // user tap on cancel
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),),
                            backgroundColor: Color(0xFFF6F6F6)
                        ),
                        child: Text(cancelText,style: TextStyle(color: Color(0xFF4C5F7D)),),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),  // user tap on confirm
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFE6464),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(confirmText, style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
