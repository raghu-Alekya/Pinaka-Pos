import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class TextConstants { // Build #1.0.7 , Naveen - added TextConstants and SharedPreferenceTextConstants classes

  static String currencySymbol        = "\u{20B9}";
  static const String loginBtnText          = "Login";
  static const String settingsHeaderText    = "Settings";
  static const String saveChangesBtnText    = "Save Changes";
  static const String personalInfoText      = "Personal Information";
  static const String personalInfoSubText   = "Change your personal information";
  static const String userText              = "user";
  static const String administratorText     = "ADMINISTRATOR";
  static const String fullNameText          = "Full Name";
  static const String contactNoText         = "Contact No";
  static const String emailText             = "Email Address";
  static const String receiptText           = "Receipt Setting";
  static const String ownReceiptText        = "Customize your own receipt";
  static const String companyNameText       = "Company Name";
  static const String companyNameHintText   = "Company Name";
  static const String gstinText             = "GSTIN";
  static const String gstinHintText         = "GSTIN";
  static const String headerText            = "Header";
  static const String headerHintText        = "Header";
  static const String footerText            = "Footer";
  static const String footerHintText        = "Footer";
  static const String deviceDetailsText     = "Device Details";
  static const String idPOSText             = "You can give id to this POS.";
  static const String copyTokenBtnText      = "Copy Token";
  static const String deviceIdText          = "Device Id";
  static const String posNumberText         = "POS Number";
  static const String posNumberHintText     = "POS Number";
  static const String posForText            = "POS For";
  static const String taxesText             = "Taxes";
  static const String manageTaxesText       = "Manage taxes";
  static const String addBtnText            = "+ ADD";
  static const String enableGSTText         = "Enable GST";
  static const String languageText          = "Language";

  static const String chooseLanText         = "Choose language";
  static const String appearanceText        = "Appearance";
  static const String screenModeText        = "Select the screen mode";
  static const String lightText             = "Light";
  static const String darkText              = "Dark";
  static const String systemText            = "System";
  static const String selectKeyboardText    = "Select Keyboard Type";
  static const String virtualText           = "Virtual";
  static const String bothText              = "Both";
  static const String quickProAddText       = "Quick Product Add";
  static const String outOfStockMngText     = "Out Of Stock Manage";
  static const String layoutSelectionHeader      = "Layout selection for navigation bar and order panel";
  static const String layoutNavLeftOrderRight    = "Navigation at left & Orders at right";
  static const String layoutNavRightOrderLeft    = "Navigation at right & Orders at left";
  static const String layoutNavBottomOrderLeft   = "Navigation at bottom & Orders at left";

  static const String printerSettText       = "Printer Settings";
  static const String selectPrintText       = "Select a printer";
  static const String connectedPrintText       = "Connected printer";
  static const String noPrinterText         = "No Printers Found";
  static const String add3PrintersText      = "You can add up to 3 Printers";
  static const String cacheText             = "Cache";
  static const String manageCacheText       = "Manage caching";
  static const String clearCacheText        = "Clear Cache";
  static const String cacheDurationText     = "Cache Duration";
  static const String retailerText          = "Retailer";
  static const String distributorText       = "Distributor";

  static const String editCateText          = "Edit Category";
  static const String selectImageText          = "Select Image";
  static const String addCateText           = "Add Category";
  static const String imgRequiredText       = "Image is required";
  static const String addFastKeyNameText    = "Add Fast key Name";
  static const String editFastKeyNameText    = "Edit Fast key";
  static const String uploadImage           = "Upload Image";
  static const String nameText              = "Name";
  static const String nameReqText           = "Name is required";
  static const String categoryNameText      = "Enter the category name";
  static const String categoryNameReqText   = "Category name is required";
  static const String itemCountText         = "Item Count:";
  static const String cancelText            = "Cancel";
  static const String saveText              = "Save";
  static const String deleteText            = "Delete";

  static const String deleteTabText         = "Delete Tab";
  static const String deleteConfirmText     = "Do you want to delete this tab permanently?";
  static const String noText                = "No";
  static const String yesText               = "Yes";
  static const String retryText               = "Retry";

  static const String clearText             = "Clear";
  static const String okText                = "OK";
  static const String addText               = "Add";

  static const String filtersText           = "Filters";

  static const String fastKeyText           = "Fast Keys";
  static const String categoriesText        = "Categories";
  static const String ordersText            = "Orders";
  static const String appsText              = "Apps";
  static const String logoutText            = "Logout";

  static const String searchAddItemText     = "Search and Add Item";
  static const String searchItemText        = "Search Item";
  static const String typeSearchText        = "Type to search...";
  static const String backText              = "Back";
  static const String addItemText           = "Add Item";
  static const String editProductText       = "Edit Product";

  static const String ebtText               = "EBT";
  static const String payoutsText           = "Payouts";
  static const String subTotalText          = "Sub total";
  static const String grossTotal            = "Gross Total";
  static const String taxText               = "Tax";
  static const String netTotalText          = "Net Total"; //Build #1.0.67
  static const String totalItemsText        = "Total Items";
  static const String holdOrderText         = "Hold Order";
  static const String payText               = "Pay :";
  static const String enterQuanText         = "Enter Quantity for";

  static const String calculatorText        = "Calculator";
  static const String holdText              = "Hold";
  static const String modeText              = "Mode";

  static const String orderId              = "Order ID";
  static const String paymentSummary       = "Payment Summary";
  static const String discount             = "Discount";
  static const String merchantDiscount     = "Merchant Discount";
  static const String total                = "Total";
  static const String netPayable           = "Net Payable";
  static const String payByCash            = "Pay By cash";
  static const String payByOther           = "Pay By Other";
  static const String tenderAmount         = "Tender Amount.";
  static const String change               = "Change";
  static const String balanceAmount        = "Balance Amount.";
  static const String cashPayment          = "Cash Payment";
  static const String selectPaymentMode    = "Select Payment Mode";
  static const String cash                 = "Cash";
  static const String card                 = "Card";
  static const String wallet               = "Wallet";
  static const String redeemPoints         = "Redeem Points";
  static const String manualDiscount       = "Manual Discount";
  static const String giftReceipt          = "Gift Receipt";
  static const String partialPaymentText   = "Please pay the remaining amount in  the next transaction.";
  static const String successPaymentText   = "Please collect the remaining amount to complete the transaction.";
  static const String exitConfirmText   = "If you go back now, the current billing session may be lost. Please confirm before exiting.";
  static const String successPaymentTitle   = "Your transaction is successfully Done!";
  static const String partialPaymentTitle   = "Partial Payment Received!";
  static const String exitConfirmTitle   = "Exit Without Completing Payment?";
  static const String receiptTitle          = "Partial Payment Received!";
  static const String print                 = "Print";
  static const String email                 = "Email";
  static const String sms                   = "SMS";
  static const String mode                  = "mode:";
  static const String enterEmailOrPhone     = "Enter email or phone number";
  static const String noReceipt             = "No Receipt";
  static const String done                  = "Done";
  static const String continueText          = "Continue";
  static const String vOid                  = "VOID";
  static const String nextPayment           = "Next Payment";
  static const String cashier               = "Cashier";
  static const String safeDrop              = "Safe Drop";
  static const String invalidCoupon         = "Invalid Coupon";
  static const String invalidCouponDescription = "The coupon code you entered is not valid. Please check the code and try again.";
  static const String letsTryAgain          = "Let's, Try Again";
  static const String removePayoutFailed    = "Failed to remove payout";
  static const String removeCouponFailed    = "Failed to remove coupon";
  static const String removeDiscountFailed  = "Failed to remove discount";
  static const String discountNotApplied    = "Discount Not Applied";
  static const String discountNotAppliedDescription = "The discount couldn’t be applied. Please double-check the eligibility criteria.";
  static const String removeCoupon          = "Remove applied coupon?"; //Build #1.0.67
  static const String removeDiscount        = "Remove applied discount? ";
  static const String removePayout          = "Remove applied payout?";
  static const String itemRemoved           = "Item removed successfully";
  static const String removeCustomItemFailed = "Failed to remove custom item";
  static const String customItemText         = "custom item";
  static const String removeCustomItem       = "Remove custom item?";
  static const String removeSpecialOrderItemDescription = "This action cannot be undone. The item will return to its original price.";
  static const String remove                = "Remove";
  static const String close                 = "Close";
  static const String areYouSure            = "Are you sure ?";
  static const String deleteTheRecordsDescription = "Do you want to really delete the records? This process cannot be undone.";
  static const String yesDelete             = "Yes, Delete!";
  static const String noKeepIt              = "No, Keep it.";
  static const String customItemAlert       = "Custom Item Alert";
  static const String customItemAlertDescription = "You're about to add a custom item. Make sure the item details are accurate before proceeding.";
  static const String addCustomItem         = "Add Custom Item";
  static const String couponNotApplied      = "Coupon Not Applied";
  static const String couponNotAppliedDescription = "The coupon couldn’t be applied. Please double-check the eligibility criteria or try a different code.";
  static const String invalidDiscount       = "Invalid Discount";
  static const String invalidDiscountDescription = "The discount entered is not valid. Please review the discount details.";
  static const String customItemCouldNotBeAdded = "Custom item could not be added";
  static const String discounts             = "Discounts";
  static const String coupons               = "Coupons";
  static const String customItem            = "Custom Item";
  static const String customItemCouldNotBeAddedDescription = "Please check the items and try again. Contact your manager if the issue continues.";
  static const String applyDiscountToSale   = "Apply discount to sale";
  static const String enterCouponCode       = "Enter coupon code";
  static const String customItemName        = "Custom item name";
  static const String itemPrice             = "Item Price";
  static const String sku                   = "SKU";
  static const String generateTheSku        = "Generate the SKU";
  static const String generate              = "Generate";
  static const String enterThePrice         = "Enter the Price";
  static const String chooseTaxSlab         = "Choose TAX Slab";
  static const String addPaymentAmount      = "Add Payout Amount";
  static const String skuGeneratedSuccessfully = "SKU generated successfully";
  static const String chooseVariants        = "Choose Variants";
  static const String backToCategories      = "Back to Categories";

  static const String login                 = "LOGIN"; // Build #1.0.8
  static const String loading               = "loading";
  static const String jsonfileExtension     = ".json";
  static const String searchHint            = "Search category or menu"; // Build #1.0.13: updated to here
  static const String serverIdNotFound      = "Server Order ID not found"; // Build #1.0.13: updated to here
  static const String failedToUpdateOrder   = "Failed to update order"; // Build #1.0.13: updated to here
  static const String doYouWantTo           = "Do you want to?"; // Build #1.0.13: updated to here
  static const String swipeToCloseShift     = "Swipe to Close Shift"; // Build #1.0.13: updated to here
  static const String verifyDrawerAndSafeAmounts = "Verify Drawer & Safe Amounts";
  static const String totalAmount           = "Total Amount: ";
  static const String shortAmount           = "Short :";
  static const String overAmount            = "Over :";
  static const String startShift            = "Start Shift";
  static const String closeShift            = "Close Shift";
  static const String back                  = "Back";
  static const String ShiftStartDescription = "Once you've entered and verified the opening cash amounts, click start shift to begin transactions.";
  static const String ShiftCloseDescription = "Make sure all amounts are tallied accurately. Click close shift to logout and end your shift";

  static const String noPrinter             = "No printer selected";
  static const String voidConfirmTitle      = "Transaction Void Confirmation ?";  // Build #1.0.49
  static const String voidConfirmText       = "This will cancel all items and payments in the current sale. The transaction will be recorded as voided in your sales history.";
  static const String yesVoid               = "Yes, Void !";
  static const String cancelled             = "cancelled";
  static const String completed             = "completed";
  static const String onhold                = "on-hold";
  static const String orderCancelled        = "Order successfully cancelled";
  static const String orderCompleted        = "Order successfully completed";
  static const String orderOnHold           = "Order changed to \'On Hold\'";
  static const String payout                = "Payout"; // Build #1.0.53
  static const String discountText          = "Discount";
  static const String none                  = "none";
 // static const String customProductText     = "CustomProduct"; // Build #1.0.64
  static const String couponText            = "coupon"; //Build #1.0.68
  static const String payoutText            = "payout";
  static const String productText           = "Product";
  static const String alreadyExistTitle     = "Item already exists";
  static const String alreadyExistSubTitle  = "Item already present in fast key";
  static const String taxable               = "taxable";
  static const String simple                = "simple";

  // Build #1.0.70 - Added by Naveen
  static const String shiftOpen             = "Shift Open Balance Screen";
  static const String navLogout             = "NavigationBar_Logout";
  static const String shiftClose            = "Shift Closing Balance Screen";
  static const String navCashier            = "AppsDashboardScreen_Cashier";
  static const String navShiftHistory       = "ShiftHistoryDashboardScreen";  //Build #1.0.74
  static const String shiftBal              = "Shift Balance Screen";
  static const String shiftId               = "shiftId";
  static const String shiftSubTitle         = "Count and record drawer cash to begin / close your shift.";
  static const String shiftScreen           = "ShiftOpenCloseBalanceScreen";
  static const String nextText              = "Next";
  static const String notes                 = "Notes";
  static const String type                  = "Type";
  static const String noOfNotes             = "No. of Notes";
  static const String coins                 = "Coins";
  static const String noOfCoins             = "No. of Coins";
  static const String totalAmountText       = "Total Amount";
  static const String loginScreen           = "LoginScreen";
  static const String closed                = "closed";
  static const String update                = "update";
  static const String open                  = "open";
  static const String noOfTubes             = "No Of Tubes";
  static const String amount                = "Amount";
  static const String totalColumns          = "Total Columns";
  static const String tubes                 = "(Tubes)";
  static const String safeTotalAmount       = "Total Amount of money in the form of notes and coins from tubes.";
  static const String updateShift           = 'Update';
  static const String updateShiftDescription = 'Please verify the drawer and safe amounts to update.';

  static const String fastKeyId             = 'fastkey_id';  //Build #1.0.89
  static const String productId             = 'product_id';

  static const String userId                = 'user_id'; //Build #1.0.108
  static const String iconPath              = 'icon_path';
  static const String conHeaderText         = 'header_text';
  static const String conFooterText         = 'footer_text';
  static const String ageRestricted         = 'Age Restricted';


  //Build #1.0.54: added
  static const String allStatus             = "pending, processing, on-hold, completed, cancelled, refunded, failed";
  static const String processing            = "processing";
  static const String orderScreenStatus     = "pending, on-hold, completed, cancelled, refunded, failed";

}

class TextFontSize {
  static const double size_28 = 28;
}

class SharedPreferenceTextConstants {

  static const String themeModeKey = "theme_mode";
  static const String selectedPrinter = "selected_printer";
  static const String layoutSelection = 'layoutSelection';
  static const String navLeftOrderRight = 'NavLeftOrderRight'; //Build #1.0.54: added
  static const String navRightOrderLeft = 'NavRightOrderLeft';
  static const String navBottomOrderLeft = 'NavBottomOrderLeft';

}