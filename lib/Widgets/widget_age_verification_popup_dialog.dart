import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinaka_pos/Widgets/widget_custom_num_pad.dart';

class AgeVerificationPopup extends StatefulWidget {
  //final String productName;
  final int minimumAge;
  final VoidCallback onManualVerify;
  final VoidCallback onAgeVerified;
  final VoidCallback? onCancel;

  const AgeVerificationPopup({
    Key? key,
   // required this.productName,
    required this.minimumAge,
    required this.onManualVerify,
    required this.onAgeVerified,
    this.onCancel,
  }) : super(key: key);

  @override
  State<AgeVerificationPopup> createState() => _AgeVerificationPopupState();
}

class _AgeVerificationPopupState extends State<AgeVerificationPopup> {
  final TextEditingController _dobController = TextEditingController();
  String? _errorMessage;
  bool _isVerifyEnabled = false;

  @override
  void initState() {
    super.initState();
    _dobController.addListener(_onDobChanged);
  }

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  void _onDobChanged() {
    setState(() {
      _errorMessage = null;
      _isVerifyEnabled = _dobController.text.length == 10; // MM/dd/yyyy format
    });
  }

  void updateDob(String digit) {
    final currentText = _dobController.text;
    String newText = currentText + digit;

    // Auto-add slashes at positions 2 and 5
    if (newText.length == 2 || newText.length == 5) {
      newText += '/';
    }

    // Limit to MM/dd/yyyy format (10 characters)
    if (newText.length <= 10) {
      _dobController.text = newText;
      _dobController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
    }
  }
  void setDob(String dob) {
    _dobController.text = dob;
    _dobController.selection = TextSelection.fromPosition(
      TextPosition(offset: dob.length),
    );
  }

  void clearDob() {
    _dobController.clear();
    setState(() {
      _errorMessage = null;
    });
  }

  void _onVerifyAge() {
    final dob = _dobController.text;
    if (dob.length != 10) {
      setState(() {
        _errorMessage = 'Please enter a valid date of birth';
      });
      return;
    }

    try {
      final parts = dob.split('/');
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();
      final age = now.difference(birthDate).inDays ~/ 365;

      if (age >= widget.minimumAge) {
        widget.onAgeVerified();
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = 'Customer is not eligible for this product';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Please enter a valid date of birth';
      });
    }
  }

  void _onManualVerify() {
    widget.onManualVerify();
    Navigator.of(context).pop();
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.325,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                const Text(
                  'Age Verification Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'This product is age-restricted. Enter the customer\'s age to verify eligibility, or confirm visually',
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            const SizedBox(height: 12),

            // Date input section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter Customer Age',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Date input field
            TextField(
              controller: _dobController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'mm/dd/yyyy',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: CustomNumPad(
                numPadType: NumPadType.age, // Choose: login, payment, age
                onDigitPressed: updateDob,
                onClearPressed: clearDob,
                    ),
                  ),
            SizedBox(
              height: 10,
            ),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onManualVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Manually Verified',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isVerifyEnabled ? _onVerifyAge : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isVerifyEnabled ? Colors.red : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Verify Age',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

// Helper class to show the popup
class AgeVerificationHelper {
  static Future<void> showAgeVerification({
    required BuildContext context,
    //required String productName,
    required int minimumAge,
    required VoidCallback onManualVerify,
    required VoidCallback onAgeVerified,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AgeVerificationPopup(
       // productName: productName,
        minimumAge: minimumAge,
        onManualVerify: onManualVerify,
        onAgeVerified: onAgeVerified,
        onCancel: onCancel,
      ),
    );
  }
}

// Example usage:
/*
void _addProductToCart(Product product) {
  if (product.hasAgeRestriction) {
    AgeVerificationHelper.showAgeVerification(
      context: context,
      productName: product.name,
      minimumAge: product.minimumAge ?? 18,
      onManualVerify: () {
        // Add product to cart - manually verified
        _addToCart(product);
      },
      onAgeVerified: () {
        // Add product to cart - age verified
        _addToCart(product);
      },
      onCancel: () {
        // User cancelled - don't add to cart
      },
    );
  } else {
    // No age restriction - add directly
    _addToCart(product);
  }
}

AgeVerificationHelper.showAgeVerification(
                                            context: context,
                                            //productName: product.name,
                                            minimumAge: 18, // or product.minimumAge
                                            onManualVerify: () {
                                              // Staff manually verified - add to cart

                                            },
                                            onAgeVerified: () {
                                              // Age verified via DOB - add to cart
                                            },
                                            onCancel: () {
                                              // User cancelled - don't add product
                                            },
                                          );
*/