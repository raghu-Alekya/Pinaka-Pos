import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_pos/Screens/Home/shift_history_dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../../Blocs/Auth/shift_bloc.dart';
import '../../Blocs/Auth/vendor_payment_bloc.dart';
import '../../Constants/text.dart';
import '../../Database/assets_db_helper.dart';
import '../../Database/db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Helper/Extentions/theme_notifier.dart';
import '../../Helper/Extentions/nav_layout_manager.dart';
import '../../Helper/api_response.dart';
import '../../Models/Assets/asset_model.dart';
import '../../Models/Auth/shift_summary_model.dart';
import '../../Preferences/pinaka_preferences.dart';
import '../../Repositories/Auth/shift_repository.dart';
import '../../Repositories/Auth/vendor_payment_repository.dart';
import '../../Widgets/widget_add_vendor_payout_dialog.dart';
import '../../Widgets/widget_alert_popup_dialogs.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;
import '../../Widgets/widget_topbar.dart';

class ShiftSummaryDashboardScreen extends StatefulWidget {
  final int? lastSelectedIndex;
  final int? shiftId;

  const ShiftSummaryDashboardScreen({
    super.key,
    this.lastSelectedIndex,
    this.shiftId,
  });

  @override
  State<ShiftSummaryDashboardScreen> createState() => _ShiftSummaryDashboardScreenState();
}

class _ShiftSummaryDashboardScreenState extends State<ShiftSummaryDashboardScreen> with LayoutSelectionMixin {
  int _selectedSidebarIndex = 4;
  late ShiftBloc shiftBloc;
  late VendorPaymentBloc vendorPaymentBloc;
  List<Vendor> _vendors = []; //Build #1.0.74
  List<String> _paymentTypes = [];
  List<String> _purposes = [];
  final PinakaPreferences _preferences = PinakaPreferences(); // Added this

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 4;
    shiftBloc = ShiftBloc(ShiftRepository());
    vendorPaymentBloc = VendorPaymentBloc(VendorPaymentRepository()); //Build #1.0.74
    if (widget.shiftId != null) {
      shiftBloc.getShiftById(widget.shiftId!);
      _loadVendorData(); // Load vendor data from AssetDBHelper
      if (kDebugMode) print("ShiftSummaryDashboardScreen: Initialized with shiftId ${widget.shiftId}");
    }
  }

  //Build #1.0.74
  Future<void> _loadVendorData() async {
    final assetDBHelper = AssetDBHelper.instance;
    try {
      final vendors = await assetDBHelper.getVendorList();
      final paymentTypes = await assetDBHelper.getVendorPaymentTypesList();
      final purposes = await assetDBHelper.getVendorPaymentPurposeList();
      setState(() {
        _vendors = vendors;
        _paymentTypes = paymentTypes;
        _purposes = purposes;
      });
      if (kDebugMode) {
        print("ShiftSummaryDashboardScreen: Loaded ${_vendors.length} vendors, ${_paymentTypes.length} payment types, ${_purposes.length} purposes");
      }
    } catch (e) {
      if (kDebugMode) print("ShiftSummaryDashboardScreen: Error loading vendor data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load vendor data'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    shiftBloc.dispose();
    vendorPaymentBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            screen: Screen.SHIFT,
            onModeChanged: () { //Build #1.0.84: Issue fixed: nav mode re-setting
              String newLayout;
              setState(() async {
                if (sidebarPosition == SidebarPosition.left) {
                  newLayout = SharedPreferenceTextConstants.navRightOrderLeft;
                } else if (sidebarPosition == SidebarPosition.right) {
                  newLayout = SharedPreferenceTextConstants.navBottomOrderLeft;
                } else {
                  newLayout = SharedPreferenceTextConstants.navLeftOrderRight;
                }

                // Update the notifier which will trigger _onLayoutChanged
                PinakaPreferences.layoutSelectionNotifier.value = newLayout;
                // No need to call saveLayoutSelection here as it's handled in the notifier
                // _preferences.saveLayoutSelection(newLayout);
                //Build #1.0.122: update layout mode change selection to DB
                await UserDbHelper().saveUserSettings({AppDBConst.layoutSelection: newLayout}, modeChange: true);
              });
            },
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.4,
            height: 1,
          ),
          Expanded(
            child: Row(
              children: [
                if (sidebarPosition == SidebarPosition.left)
                  custom_widgets.NavigationBar(
                    selectedSidebarIndex: _selectedSidebarIndex,
                    onSidebarItemSelected: (index) {
                      setState(() {
                        _selectedSidebarIndex = index;
                      });
                    },
                    isVertical: true,
                  ),
                Expanded(
                  child: _buildShiftSummaryContent(),
                ),
                if (sidebarPosition == SidebarPosition.right)
                  custom_widgets.NavigationBar(
                    selectedSidebarIndex: _selectedSidebarIndex,
                    onSidebarItemSelected: (index) {
                      setState(() {
                        _selectedSidebarIndex = index;
                      });
                    },
                    isVertical: true,
                  ),
              ],
            ),
          ),
          if (sidebarPosition == SidebarPosition.bottom)
            custom_widgets.NavigationBar(
              selectedSidebarIndex: _selectedSidebarIndex,
              onSidebarItemSelected: (index) {
                setState(() {
                  _selectedSidebarIndex = index;
                });
              },
              isVertical: false,
            ),
        ],
      ),
    );
  }

  Widget _buildShiftSummaryContent() {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: StreamBuilder<APIResponse<ShiftByIdResponse>>( //Build #1.0.74
          stream: shiftBloc.shiftByIdStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              switch (snapshot.data!.status) {
                case Status.LOADING:
                  return Center(child: CircularProgressIndicator());
                case Status.COMPLETED:
                  final shift = snapshot.data!.data!.shift;
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(),
                                  _buildTimeTrackingSection(shift),
                                ],
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              _buildFinancialSummaryCards(shift),
                            ],
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSafeDropSection(shift),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                              _buildVendorPayoutsSection(shift),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                case Status.ERROR:
                  return Center(child: Text('Error: ${snapshot.data!.message}'));
                default:
                  return SizedBox();
              }
            }
            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: themeHelper.themeMode == ThemeMode.dark
                ? ThemeNotifier.textDark : Colors.black87,
            size: MediaQuery.of(context).size.width * 0.02,
          ),
        ),
        Text(
          TextConstants.back,
          style: TextStyle(
            color: themeHelper.themeMode == ThemeMode.dark
                ? ThemeNotifier.textDark : Colors.black87,
            fontSize: MediaQuery.of(context).size.width * 0.012,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeTrackingSection(Shift shift) {
    return Row(
      children: [
        _buildTimeCard(TextConstants.startTime, DateTimeHelper.extractTime(shift.startTime)),
        SizedBox(width: MediaQuery.of(context).size.width * 0.0075),
        _buildTimeCard(TextConstants.duration, DateTimeHelper.calculateDuration(shift.startTime, shift.endTime)),
        SizedBox(width: MediaQuery.of(context).size.width * 0.0075),
        _buildTimeCard(TextConstants.endTime, shift.endTime.isEmpty ? '' : DateTimeHelper.extractTime(shift.endTime)),
      ],
    );
  }

  Widget _buildTimeCard(String title, String value) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color:  themeHelper.themeMode == ThemeMode.dark
                  ? Colors.white70 : Colors.grey,
              fontSize: MediaQuery.of(context).size.width * 0.01,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.008),
          Container(
            width: MediaQuery.of(context).size.width * 0.095,
            height: MediaQuery.of(context).size.height * 0.075,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:  themeHelper.themeMode == ThemeMode.dark
                  ? ThemeNotifier.tabsBackground : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color:  themeHelper.themeMode == ThemeMode.dark
                  ? ThemeNotifier.borderColor : Colors.grey, width: 1),
            ),
            child: Text(
              textAlign: TextAlign.center,
              value,
              style: TextStyle(
                color:  themeHelper.themeMode == ThemeMode.dark
                    ? ThemeNotifier.textDark : Colors.black87,
                fontSize: MediaQuery.of(context).size.width * 0.011,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildFinancialSummaryCards(Shift shift) {
    return Row(
      children: [
        _buildSummaryCard(TextConstants.openingAmount, '${TextConstants.currencySymbol}${shift.openingBalance}', Color(0xFF8BB6E8)),
        SizedBox(width: MediaQuery.of(context).size.width * 0.015),
        _buildSummaryCard(TextConstants.totalTransactions, '${shift.totalSales}', Color(0xFF9BC5E8)),
        SizedBox(width: MediaQuery.of(context).size.width * 0.015),
        _buildSummaryCard(TextConstants.saleAmount, '${TextConstants.currencySymbol}${shift.totalSaleAmount}', Color(0xFF7BC4A4)),
        SizedBox(width: MediaQuery.of(context).size.width * 0.015),
        _buildSummaryCard(TextConstants.closingAmount, '${TextConstants.currencySymbol}${shift.closingBalance}', Color(0xFFB8D4B8)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.175,
      width: MediaQuery.of(context).size.width * 0.12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.012),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.01,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.02,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeDropSection(Shift shift) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      width: MediaQuery.of(context).size.width * 0.3,
      height: MediaQuery.of(context).size.height * 0.625,
      decoration: BoxDecoration(
        color: themeHelper.themeMode == ThemeMode.dark
            ? ThemeNotifier.primaryBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeHelper.themeMode == ThemeMode.dark
            ? ThemeNotifier.borderColor : Colors.black ),
        boxShadow: [
          BoxShadow(
            color: themeHelper.themeMode == ThemeMode.dark
                ? ThemeNotifier.shadow_F7 : Colors.black.withOpacity(0.05),
            blurRadius: 2,
            //spreadRadius: 2,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.015),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TextConstants.safeDrop,
                  style: TextStyle(
                    color: themeHelper.themeMode == ThemeMode.dark
                        ? ThemeNotifier.textDark : Colors.black87,
                    fontSize: MediaQuery.of(context).size.width * 0.012,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${TextConstants.currencySymbol}${shift.safeDropTotal}',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: MediaQuery.of(context).size.width * 0.012,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Safe Drop List
          Expanded(
            child: shift.safeDrops.isEmpty
                ? Center(child: Text(TextConstants.safeDropNotFound))
                : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: shift.safeDrops.length,
              itemBuilder: (context, index) {
                final item = shift.safeDrops[index];
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.015,
                    vertical: MediaQuery.of(context).size.height * 0.012,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${TextConstants.currencySymbol}${item.total}',
                            style: TextStyle(
                              color: themeHelper.themeMode == ThemeMode.dark
                                  ? ThemeNotifier.textDark : Colors.black87,
                              fontSize: MediaQuery.of(context).size.width * 0.011,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.004),
                          Text(
                            TextConstants.amount,
                            style: TextStyle(
                              color: themeHelper.themeMode == ThemeMode.dark
                                  ? Colors.white70 : Colors.grey.shade600,
                              fontSize: MediaQuery.of(context).size.width * 0.008,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateTimeHelper.extractTime(item.time),
                            style: TextStyle(
                              color: themeHelper.themeMode == ThemeMode.dark
                                  ? ThemeNotifier.textDark : Colors.black87,
                              fontSize: MediaQuery.of(context).size.width * 0.011,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.004),
                          Text(
                            TextConstants.time,
                            style: TextStyle(
                              color: themeHelper.themeMode == ThemeMode.dark
                                  ? Colors.white70 : Colors.grey.shade600,
                              fontSize: MediaQuery.of(context).size.width * 0.008,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorPayoutsSection(Shift shift) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      width: MediaQuery.of(context).size.width * 0.59,
      height: MediaQuery.of(context).size.height * 0.625,
      decoration: BoxDecoration(
        color: themeHelper.themeMode == ThemeMode.dark
            ? ThemeNotifier.primaryBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: themeHelper.themeMode == ThemeMode.dark
                ? ThemeNotifier.shadow_F7 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            //spreadRadius: 2,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.015),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      TextConstants.vendorPayouts,
                      style: TextStyle(
                        color: themeHelper.themeMode == ThemeMode.dark
                            ? ThemeNotifier.textDark : Colors.black,
                        fontSize: MediaQuery.of(context).size.width * 0.015,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                    Text(
                      '${TextConstants.currencySymbol}${shift.totalVendorPayments}',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: MediaQuery.of(context).size.width * 0.012,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Disable Add button if shift is closed
                InkWell(
                  onTap: shift.shiftStatus == 'closed'
                      ? null
                      : () {
                    if (kDebugMode) print("ShiftSummaryDashboardScreen: Showing add vendor payout dialog");
                    _showAddVendorPayoutDialog();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.01,
                      vertical: MediaQuery.of(context).size.height * 0.005,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: shift.shiftStatus == 'closed' ? Colors.grey : themeHelper.themeMode == ThemeMode.dark
                            ? ThemeNotifier.borderColor : Colors.black54,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: shift.shiftStatus == 'closed' ? Colors.grey.shade200 :themeHelper.themeMode == ThemeMode.dark
                          ? ThemeNotifier.tabsBackground : Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: MediaQuery.of(context).size.width * 0.01,
                          color: shift.shiftStatus == 'closed' ? Colors.grey : themeHelper.themeMode == ThemeMode.dark
                              ? ThemeNotifier.textDark : Colors.black87,
                          weight: 2.0,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.003),
                        Text(
                          TextConstants.addText,
                          style: TextStyle(
                            color: shift.shiftStatus == 'closed' ? Colors.grey : themeHelper.themeMode == ThemeMode.dark
                                ? ThemeNotifier.textDark : Colors.black87,
                            fontSize: MediaQuery.of(context).size.width * 0.01,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: shift.vendorPayouts.isEmpty
                ? Center(child: Text(TextConstants.vendorPayoutNotFound))
                : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 30,
                horizontalMargin: MediaQuery.of(context).size.width * 0.015,
                headingRowHeight: MediaQuery.of(context).size.height * 0.085,
                headingRowColor: WidgetStateProperty.all(
                  themeHelper.themeMode == ThemeMode.dark
                      ? ThemeNotifier.secondaryBackground
                      : Colors.white,
                ),
                dividerThickness: 0.5,

                columns: [
                  DataColumn(
                    label: Text(
                      TextConstants.amount,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      TextConstants.vendor,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      TextConstants.note,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                     TextConstants.purpose,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      '',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows: shift.vendorPayouts.asMap().entries.map((entry) {
                  int index = entry.key;
                  VendorPayout item = entry.value;
                  return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) => themeHelper.themeMode == ThemeMode.dark
                      ? ThemeNotifier.tabsBackground  // Your dark theme color
                      : Colors.white
                      ),
                  cells: [
                      DataCell(
                        Text(
                          '${TextConstants.currencySymbol}${item.amount}',
                          style: TextStyle(
                            color:themeHelper.themeMode == ThemeMode.dark
                                ? ThemeNotifier.textDark : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.vendorName,
                          style: TextStyle(
                            color: themeHelper.themeMode == ThemeMode.dark
                                ? ThemeNotifier.textDark : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    DataCell(
                      ConstrainedBox(
                      constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.25,
                  ),
                        child: Tooltip(
                          message: item.note.isEmpty ? 'No note' : item.note,
                          decoration: BoxDecoration(
                            color: themeHelper.themeMode == ThemeMode.dark
                                ? ThemeNotifier.searchBarBackground
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.all(8),
                          child: Text(
                            item.note.isEmpty ? 'No note' : item.note,
                            style: TextStyle(
                              color: themeHelper.themeMode == ThemeMode.dark
                                  ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                      ),
                    ),
                      DataCell(
                        Text(
                          item.serviceType,
                          style: TextStyle(
                            color: themeHelper.themeMode == ThemeMode.dark
                                ? ThemeNotifier.textDark :  Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: shift.shiftStatus == 'closed'
                                  ? null
                                  : () {
                                if (kDebugMode) print('ShiftSummaryDashboardScreen: Delete vendor payout at index $index with ID ${item.id}');
                                _showDeleteConfirmation(index, item.id);
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.004),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: shift.shiftStatus == 'closed' ? Colors.grey : Colors.red.shade400,
                                  size: 18,
                                ),
                              ),
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.005),
                            InkWell(
                              onTap: shift.shiftStatus == 'closed'
                                  ? null
                                  : () {
                                if (kDebugMode) print('ShiftSummaryDashboardScreen: Edit vendor payout at index $index with ID ${item.id}');
                                _showAddVendorPayoutDialog(payment: item);
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.004),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: shift.shiftStatus == 'closed' ? Colors.grey : Colors.blue.shade400,
                                  size: 18,
                                ),
                              ),
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.005),
                            InkWell(
                              onTap: () {
                                if (kDebugMode) print('ShiftSummaryDashboardScreen: Print vendor payout at index $index');
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.004),
                                child: Icon(
                                  Icons.print_outlined,
                                  color: Colors.grey.shade600,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int index, int paymentId) {
    bool _isDeleting = false; // Track delete button loading state
    CustomDialog.showAreYouSure(
      context,
      confirm: () async {
        if (kDebugMode) print('ShiftSummaryDashboardScreen: Initiating delete for payment ID $paymentId');
        setState(() {
          _isDeleting = true; // Show loader on Yes button
        });
        vendorPaymentBloc.deleteVendorPayment(paymentId);
        await for (var response in vendorPaymentBloc.deleteVendorPaymentStream) {
          if (response.status == Status.COMPLETED) {
            setState(() {
              _isDeleting = false; // Hide loader
            });
           // Navigator.of(context).pop(); // Dismiss confirmation dialog

            shiftBloc.getShiftById(widget.shiftId!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response.message ?? 'Vendor payout deleted successfully',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (response.status == Status.ERROR) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response.message ?? 'Failed to delete vendor payout',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
          break;
        }
      },
      isDeleting: _isDeleting, // Pass loading state
    );
  }

  void _showAddVendorPayoutDialog({VendorPayout? payment}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddVendorPayoutDialog( //Build #1.0.74: updated code
          shiftId: widget.shiftId!,
          vendors: _vendors,
          paymentTypes: _paymentTypes,
          purposes: _purposes,
          vendorPaymentBloc: vendorPaymentBloc,
          onAdd: (request) async {
            if (kDebugMode) print('ShiftSummaryDashboardScreen: Adding/Editing vendor payout: ${request.toJson()}');
            // Handle create or update
            if (payment != null && request.vendorPaymentId != null) {
              vendorPaymentBloc.updateVendorPayment(request, request.vendorPaymentId!);
              // Listen to update stream
              await for (var response in vendorPaymentBloc.updateVendorPaymentStream) {
                if (response.status == Status.COMPLETED) {

                  shiftBloc.getShiftById(widget.shiftId!); // Refresh shift data

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.message ?? 'Vendor payout updated successfully',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (response.status == Status.ERROR) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.message ?? 'Failed to update vendor payout',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                break; // Exit after handling the response
              }
            } else {
              vendorPaymentBloc.createVendorPayment(request);
              // Listen to create stream
              await for (var response in vendorPaymentBloc.createVendorPaymentStream) {
                if (response.status == Status.COMPLETED) {
                  shiftBloc.getShiftById(widget.shiftId!); // Refresh shift data
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.message ?? 'Vendor payout added successfully',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (response.status == Status.ERROR) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.message ?? 'Failed to add vendor payout',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                break; // Exit after handling the response
              }
            }
          },
          payment: payment,
        );
      },
    );
  }
}