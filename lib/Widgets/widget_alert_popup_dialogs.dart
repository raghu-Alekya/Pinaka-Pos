import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pinaka_pos/Constants/text.dart';

class CustomDialog {
  // Reusable Button Styles
  static ButtonStyle get _primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFFE6464),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    minimumSize: const Size(double.infinity, 48),
  );

  static ButtonStyle get _secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFF6F6F6),
    foregroundColor: Color(0xFF4C5F7D),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    minimumSize: const Size(double.infinity, 48),
  );

  // Reusable Text Styles
  static const TextStyle _titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF4C5F7D),
  );

  static const TextStyle _descriptionStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle _lightDescriptionStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFFD0CCCC),
  );

  static const TextStyle _mutedDescriptionStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF9CA3AF),
  );

  // Public Methods
  static Future<void> showInvalidCoupon(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: TextConstants.invalidCoupon,
      description: TextConstants.invalidCouponDescription,
      buttonText: TextConstants.letsTryAgain,
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<void> showDiscountNotApplied(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: TextConstants.discountNotApplied,
      description: TextConstants.discountNotAppliedDescription,
      buttonText: TextConstants.letsTryAgain,
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<bool?> showRemoveDiscountConfirmation(BuildContext context) {
    return _showConfirmDialog(
      context,
      title: TextConstants.removeDiscountOrCoupon,
      description: TextConstants.removeDiscountOrCouponDescription,
      confirmText: TextConstants.remove,
      cancelText: TextConstants.close,
      iconPath: 'assets/svg/check_broken_alert.svg',
    );
  }

  static Future<bool?> showAreYouSure(BuildContext context) {
    return _showConfirmDialog(
      context,
      title: TextConstants.areYouSure,
      description: TextConstants.deleteTheRecordsDescription,
      confirmText: TextConstants.yesDelete,
      cancelText: TextConstants.noKeepIt,
      iconPath: 'assets/svg/check_broken_alert.svg',
    );
  }

  static Future<void> showCustomItemAlert(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: TextConstants.customItemAlert,
      description: TextConstants.customItemAlertDescription,
      buttonText: TextConstants.addCustomItem,
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<void> showCouponNotApplied(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: TextConstants.couponNotApplied,
      description: TextConstants.couponNotAppliedDescription,
      buttonText: TextConstants.letsTryAgain,
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<void> showInvalidDiscount(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: TextConstants.invalidDiscount,
      description: TextConstants.invalidDiscountDescription,
      buttonText: TextConstants.letsTryAgain,
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  static Future<void> showCustomItemNotAdded(BuildContext context) {
    return _showSimpleDialog(
      context,
      title: TextConstants.customItemCouldNotBeAdded,
      description: TextConstants.customItemCouldNotBeAddedDescription,
      buttonText: TextConstants.letsTryAgain,
      iconPath: 'assets/svg/check_broken_info.svg',
      showCloseIcon: true,
    );
  }

  // Cash Drawer Verification Methods
  static Future<bool?> showStartShiftVerification(
      BuildContext context, {
        required double totalAmount,
        //double? shortAmount,
        double? overAmount,
      }) {
    return _showCashVerificationDialog(
      context,
      totalAmount: totalAmount,
      //shortAmount: shortAmount,
      overAmount: overAmount,
      isShiftStarted: false,
    );
  }

  static Future<bool?> showCloseShiftVerification(
      BuildContext context, {
        required double totalAmount,
        double? shortAmount,
        //double? overAmount,
      }) {
    return _showCashVerificationDialog(
      context,
      totalAmount: totalAmount,
      shortAmount: shortAmount,
      //overAmount: overAmount,
      isShiftStarted: true,
    );
  }

  // Reusable Base Dialog Builder
  static Widget _buildBaseDialog(BuildContext context, Widget content) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.35,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      ),
    );
  }

  // Reusable Icon Builder
  static Widget _buildIcon(String iconPath, {double height = 50, Color? color}) {
    return SvgPicture.asset(
      iconPath,
      height: height,
      color: color,
    );
  }

  // // Reusable Circular Icon with Background
  // static Widget _buildCircularIcon(String iconPath, {Color? iconColor, Color? backgroundColor}) {
  //   return Container(
  //     width: 60,
  //     height: 60,
  //     decoration: BoxDecoration(
  //       color: backgroundColor ?? Color(0xFFFEE2E2),
  //       borderRadius: BorderRadius.circular(30),
  //     ),
  //     child: Center(
  //       child: _buildIcon(iconPath, height: 30, color: iconColor),
  //     ),
  //   );
  // }

  // Reusable Text Builders
  static Widget _buildTitle(String title) {
    return Text(
      title,
      style: _titleStyle,
      textAlign: TextAlign.center,
    );
  }

  static Widget _buildDescription(String description, {TextStyle? style}) {
    return Text(
      description,
      style: style ?? _descriptionStyle,
      textAlign: TextAlign.center,
    );
  }

  // Reusable Button Builders
  static Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: _primaryButtonStyle,
      onPressed: onPressed,
      child: Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  static Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: _secondaryButtonStyle,
      onPressed: onPressed,
      child: Text(text, style: TextStyle(color: Color(0xFF4C5F7D), fontWeight: FontWeight.bold)),
    );
  }

  // Reusable Close Icon
  static Widget _buildCloseIcon(BuildContext context) {
    return Positioned(
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
    );
  }

  // Reusable Amount Row Builder
  static Widget _buildAmountRow(String label, double amount, {Color? backgroundColor, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? Color(0xFF4C5F7D),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor ?? Color(0xFF4C5F7D),
            ),
          ),
        ],
      ),
    );
  }

  // Internal Methods - Refactored
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
      builder: (_) => _buildBaseDialog(
        context,
        Stack(
          children: [
            if (showCloseIcon) _buildCloseIcon(context),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: showCloseIcon ? 32 : 0),
                _buildIcon(iconPath),
                const SizedBox(height: 16),
                _buildTitle(title),
                const SizedBox(height: 8),
                _buildDescription(description),
                const SizedBox(height: 24),
                _buildPrimaryButton(
                  buttonText,
                      () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
      builder: (_) => _buildBaseDialog(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(iconPath, height: 48),
            const SizedBox(height: 16),
            _buildTitle(title),
            const SizedBox(height: 8),
            _buildDescription(description, style: _lightDescriptionStyle),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryButton(
                    cancelText,
                        () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPrimaryButton(
                    confirmText,
                        () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> _showCashVerificationDialog(
      BuildContext context, {
        required double totalAmount,
        double? shortAmount,
        double? overAmount,
        required bool isShiftStarted,
      }) {
    String actionButtonText = isShiftStarted
        ? TextConstants.closeShift
        : TextConstants.startShift;

    String descriptionText = isShiftStarted
        ? TextConstants.ShiftCloseDescription
        : TextConstants.ShiftStartDescription;

    return showDialog(
      context: context,
      builder: (_) => _buildBaseDialog(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with background
            _buildIcon(
              'assets/svg/check_broken_alert.svg',
            ),
            const SizedBox(height: 16),
            // Title
            _buildTitle(TextConstants.verifyDrawerAndSafeAmounts),
            const SizedBox(height: 24),
            // Total Amount
            _buildAmountRow(TextConstants.totalAmount, totalAmount),
            const SizedBox(height: 12),
            // Short Amount (RED) - only show if > 0
            if (shortAmount != null && shortAmount > 0)
              _buildAmountRow(
                TextConstants.shortAmount,
                shortAmount,
                backgroundColor: Color(0xFFFEE2E2),
                textColor: Color(0xFFFE6464),
              ),
            // Over Amount (GREEN) - only show if > 0
            if (overAmount != null && overAmount > 0)
              _buildAmountRow(
                TextConstants.overAmount,
                overAmount,
                backgroundColor: Color(0xFFE8F5E8),
                textColor: Color(0xFF22C55E),
              ),
            const SizedBox(height: 16),
            // Description
            _buildDescription(descriptionText, style: _mutedDescriptionStyle),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryButton(
                    TextConstants.back,
                        () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPrimaryButton(
                    actionButtonText,
                        () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// Reusable Components:
// 1. Button Styles (lines 7-19):
//
// _primaryButtonStyle - Red buttons
// _secondaryButtonStyle - Gray buttons
//
// 2. Text Styles (lines 21-41):
//
// _titleStyle - Dialog titles
// _descriptionStyle - Regular descriptions
// _lightDescriptionStyle - Light gray text
// _mutedDescriptionStyle - Muted gray text
//
// 3. Reusable Builders (lines 139-225):
//
// _buildBaseDialog() - Common dialog container
// _buildIcon() - SVG icon builder
// _buildCircularIcon() - Icon with circular background
// _buildTitle() - Title text
// _buildDescription() - Description text
// _buildPrimaryButton() - Red buttons
// _buildSecondaryButton() - Gray buttons
// _buildCloseIcon() - Close button
// _buildAmountRow() - Amount display rows
//
// Benefits of This Refactor:
// Eliminated Repetition:
//
// Before: Dialog container code repeated 3 times
// After: Single _buildBaseDialog() method
//
// Consistent Styling:
//
// All buttons use the same styles
// All text uses consistent styling
// Easy to change colors/fonts in one place
//
// Maintainable:
//
// Want to change button colors? Change _primaryButtonStyle
// Want to change text size? Change _titleStyle
// Need new dialog? Use existing builders
//
// Cleaner Methods:
//
// _showSimpleDialog() went from 50+ lines to ~25 lines
// _showConfirmDialog() is much cleaner
// _showCashVerificationDialog() focuses on layout, not styling
//
// Flexible:
//
// _buildAmountRow() handles different colors for short/over amounts
// _buildDescription() accepts custom styles
// _buildIcon() accepts custom colors and sizes
//