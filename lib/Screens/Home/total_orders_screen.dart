import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_pos/Database/db_helper.dart';
import 'package:pinaka_pos/Models/Assets/asset_model.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../Blocs/Orders/order_bloc.dart';
import '../../Database/assets_db_helper.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Helper/Extentions/nav_layout_manager.dart';
import '../../Helper/Extentions/theme_notifier.dart';
import '../../Preferences/pinaka_preferences.dart';
import '../../Widgets/widget_order_screen_panel.dart';
import '../../Widgets/widget_order_status.dart';
import '../../Widgets/widget_filter_chip.dart';
import '../../Widgets/widget_order_panel.dart';
import '../../Widgets/widget_pagination.dart';
import '../../Widgets/widget_range_filter.dart';
import '../../Widgets/widget_topbar.dart';
import '../../Models/Orders/get_orders_model.dart' as model; // Added prefix
import '../../Repositories/Orders/order_repository.dart';
import '../../Helper/api_response.dart';
import '../../Constants/text.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;

import 'package:quickalert/quickalert.dart';

class OrdersScreen extends StatefulWidget { //Build #1.0.54: updated
  final int? lastSelectedIndex;

  const OrdersScreen({super.key, this.lastSelectedIndex});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with LayoutSelectionMixin {
  late OrderBloc _orderBloc;
  List<model.OrderModel> _orders = []; // Use model.OrderModel
  int _selectedSidebarIndex = 3;
  DateTime now = DateTime.now();
  List<int> quantities = [1, 1, 1, 1];
  bool isLoading = false; // Build #1.0.104
  String _selectedStatusFilter = "All";
  String _selectedUserFilter = "All";
  String _selectedOrderTypeFilter = "All";
  String _selectedPaymentMethodFilter = "All";
  late double _minSalesAmount;
  late double _maxSalesAmount;
  late RangeValues _salesAmountRange;
  String? _sortColumn;
  bool _isAscending = true;
  StreamSubscription? _fetchOrdersSubscription;
  int _totalOrdersCount = 0;
  late OrderScreenPanel _orderScreenPanel;

  ///Filters
  // List<String> _availableStatuses = ["All"];
  final List<OrderStatus> _filterStatuses = [OrderStatus(slug: "", name: "All")];
  final List<Employees> _filterUsers = [Employees(iD: "",displayName: "All")];
  final List<OrderType> _filterOrderType = [OrderType(slug: "",name: "All")];

  Map<String, dynamic>? _selectedOrder;
  int? _selectedOrderId;
  final OrderHelper orderHelper = OrderHelper(); // Helper instance to manage orders
  final PinakaPreferences _preferences = PinakaPreferences(); // Added this
  // Date range filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDateRangeApplied = false;

  // Add these variables for pagination
  int _currentPage = 1;
  int _rowsPerPage = 10;
  final List<int> _rowsPerPageOptions = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 3;
    _orderBloc = OrderBloc(OrderRepository());
    _minSalesAmount = 0.0;
    _maxSalesAmount = 10000.0; // Default max, will be updated from API
    _salesAmountRange = RangeValues(_minSalesAmount, _maxSalesAmount);
    initFilters();
    // Initialize order fetching
    //_fetchOrders();
    _orderScreenPanel = OrderScreenPanel(
      key: ValueKey(orderHelper.activeOrderId ?? 0),
      formattedDate: '',
      formattedTime: '',
      quantities: quantities,
      activeOrderId: orderHelper.activeOrderId, // Pass activeOrderId
      fetchOrders: false, // Show shimmer initially
    );
  }


  Future<void> initFilters() async {
    var filterStatuses = await AssetDBHelper.instance.getOrderStatusList();
    filterStatuses.removeWhere((e) => e.slug == 'processing');
    _filterStatuses.addAll(filterStatuses);

    var filterUsers = await AssetDBHelper.instance.getEmployeeList();
    _filterUsers.addAll(filterUsers);

    var filterOrderType = await AssetDBHelper.instance.getOrderTypeList();
    _filterOrderType.addAll(filterOrderType);
  }

  //Build #1.0.54: added Fetch orders from API
  void _fetchOrders() {
    debugPrint("OrdersScreen: Initiating fetch orders");
    _fetchOrdersSubscription?.cancel();
    _fetchOrdersSubscription = _orderBloc.fetchTotalOrdersStream.listen((response) {
      if (!mounted) return;

      if (response.status == Status.COMPLETED) {
        debugPrint("OrdersScreen: Successfully fetched ${response.data!.ordersData.length} orders, Total Count: ${response.data!.orderTotalCount}");
        setState(() {
          _orders = response.data!.ordersData; //Build #1.0.134
          _totalOrdersCount = response.data!.orderTotalCount;
          isLoading = false;

          if (_orders.isEmpty) {
            _selectedOrderId = null; // Reset only if no orders
            return;
          }

          // Only set _selectedOrderId if it's null or not in the new _orders list
          if (_selectedOrderId == null || !_orders.any((order) => order.id == _selectedOrderId)) {
            _selectedOrderId = _orders.first.id;
            _onOrderRowSelected(_selectedOrderId!);
          }
        });
      } else if (response.status == Status.ERROR) {
        debugPrint("OrdersScreen: Error fetching orders - ${response.message}");
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TextConstants.failedToFetchOrders), // Build #1.0.149 : added to constant & added background to red
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (response.status == Status.LOADING) {
        setState(() => isLoading = true);
      }
    });

    var selectedStatus = _filterStatuses.firstWhere((element) => element.name == _selectedStatusFilter).slug;
    var selectedUserId = _filterUsers.firstWhere((element) => element.displayName == _selectedUserFilter).iD ?? "";
    var selectedOrderType = _filterOrderType.firstWhere((element) => element.name == _selectedOrderTypeFilter).slug ?? "";

    //Build #1.0.134: Format dates without milliseconds
    DateFormat format = DateFormat('yyyy-MM-ddThh:mm:ss');
    String? startDateFormatted = '';//_startDate?.toString().split('.')[0];
    String? endDateFormatted = '';//_endDate?.toString().split('.')[0];
    if(_startDate != null){
      startDateFormatted = format.format(_startDate!);
      endDateFormatted = format.format(_endDate!);
    }

    _orderBloc.fetchTotalOrdersCount(
      allStatuses: true,
      pageNumber: _currentPage,
      pageLimit: _rowsPerPage,
      status: selectedStatus,
      orderType: selectedOrderType,
      userId: selectedUserId,
      startDate: startDateFormatted ?? '', //after=2025-07-22 01:08:35&  != 2025-07-1T17:28:09
      endDate: endDateFormatted ?? '', //before=2025-07-20 01:08:35&  != 2025-07-22T17:28:09
    );
  }

  // Sort orders based on column
  void _sortData(String column) {
    setState(() {
      if (_sortColumn == column) {
        _isAscending = !_isAscending;
      } else {
        _sortColumn = column;
        _isAscending = true;
      }

      if (_sortColumn != null) {
        _orders.sort((a, b) {
          switch (column) {
            case 'id':
              return _isAscending
                  ? a.id.compareTo(b.id)
                  : b.id.compareTo(a.id);
            case 'date':
              return _isAscending
                  ? a.dateCreated.compareTo(b.dateCreated)
                  : b.dateCreated.compareTo(a.dateCreated);
            case 'time':
              return _isAscending
                  ? a.dateCreated.compareTo(b.dateCreated)
                  : b.dateCreated.compareTo(a.dateCreated);
            case 'sales_amount':
              final aValue = double.tryParse(a.total) ?? 0.0;
              final bValue = double.tryParse(b.total) ?? 0.0;
              return _isAscending
                  ? aValue.compareTo(bValue)
                  : bValue.compareTo(aValue);
            case 'status':
              return _isAscending
                  ? a.status.compareTo(b.status)
                  : b.status.compareTo(a.status);
            default:
              return 0;
          }
        });
      }
    });
    debugPrint("OrdersScreen: Sorted data by $column, ascending: $_isAscending");
  }

  // Extract sales amount from string
  double _extractSalesAmount(String sales) {
    return double.tryParse(sales.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }

  // Open range filter dialog
  void _openRangeFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Sales Amount Range"),
          content: SingleChildScrollView(
            child: RangeFilter(
              label: "Sales Amount",
              minValue: _minSalesAmount,
              maxValue: _maxSalesAmount,
              initialRange: _salesAmountRange,
              onRangeChanged: (range) {
                setState(() {
                  _salesAmountRange = range;
                  debugPrint("OrdersScreen: Sales amount range updated to ${_salesAmountRange.start} - ${_salesAmountRange.end}");
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // Open date range picker dialog
  void _openDateRangePickerDialog() {
    final themeHelper = Provider.of<ThemeNotifier>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeHelper.themeMode == ThemeMode.dark
              ? ThemeNotifier.secondaryBackground : null,
          title: const Text("Select Date Range"),
          content: SizedBox(
            height: 400,
            width: 350,
            child: SfDateRangePicker(
              onSelectionChanged: _onDateRangeSelectionChanged,
              selectionMode: DateRangePickerSelectionMode.range,
              initialSelectedRange: _startDate != null && _endDate != null
                  ? PickerDateRange(_startDate, _endDate)
                  : null,
              showActionButtons: true,
              onSubmit: (Object? value) {
                Navigator.pop(context);
              },
              onCancel: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  // Handle date range selection
  void _onDateRangeSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is PickerDateRange) {
      final PickerDateRange range = args.value;
      final currentTime = DateTime.now(); // Get current time
      setState(() { //Build #1.0.134: integrated date filter
        _startDate = range.startDate != null
            ? DateTime(range.startDate!.year, range.startDate!.month, range.startDate!.day, currentTime.hour, currentTime.minute, currentTime.second)
            : null;
        _endDate = range.endDate != null
            ? DateTime(range.endDate!.year, range.endDate!.month, range.endDate!.day, currentTime.hour, currentTime.minute, currentTime.second)
            : range.startDate != null
            ? DateTime(range.startDate!.year, range.startDate!.month, range.startDate!.day, currentTime.hour, currentTime.minute, currentTime.second)
            : null;
        _isDateRangeApplied = _startDate != null && _endDate != null;
        _currentPage = 1;

      //  if(_isDateRangeApplied) {
          debugPrint("#### _isDateRangeApplied: $_isDateRangeApplied");
          debugPrint("Start Date: $_startDate");
          debugPrint("End Date: $_endDate");
          // Fetch new data with updated date range
          _fetchOrders();
     //   }
        debugPrint("OrdersScreen: Date range selected from $_startDate to $_endDate");
      });
    }
  }

  // Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedStatusFilter = "All";
      _selectedUserFilter = "All"; // Changed from "User 1" to match initialization
      _selectedPaymentMethodFilter = "All";
      _selectedOrderTypeFilter = "All";
      _salesAmountRange = RangeValues(_minSalesAmount, _maxSalesAmount);
      _startDate = null;
      _endDate = null;
      _isDateRangeApplied = false;
      _currentPage = 1;
      _fetchOrders(); // Fetch new data with cleared filters
      debugPrint("OrdersScreen: Filters cleared");
    });
  }

  // Check if order date falls within selected range
  bool _isDateInRange(String dateCreated) {
    if (!_isDateRangeApplied || _startDate == null || _endDate == null) {
      return true;
    }

    final orderDate = DateTime.tryParse(dateCreated);
    if (orderDate == null) return true;

    final orderDateOnly = DateTime(orderDate.year, orderDate.month, orderDate.day);
    final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    return orderDateOnly.isAfter(startDateOnly.subtract(const Duration(days: 1))) &&
        orderDateOnly.isBefore(endDateOnly.add(const Duration(days: 1)));
  }

  @override
  void dispose() {
    _fetchOrdersSubscription?.cancel();
    _orderBloc.dispose();
    debugPrint("OrdersScreen: Disposed");
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint("????? OrdersScreen: didChangeDependencies");
    _fetchOrders();
    _onOrderRowSelected(-1);///initialise order panel
  }
 // Build #1.0.143: Fixed Issue : After return from order summary screen , total order screen not refreshing with updated response
 void _refreshOrderList() {
   if (kDebugMode) print("_refreshOrderList called");
  //  setState(() {
   _fetchOrders();
  //  });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // String formattedDate = DateFormat("EEE, MMM d' ${now.year}'").format(now);
    // String formattedTime = DateFormat('hh:mm a').format(now);
    final themeHelper = Provider.of<ThemeNotifier>(context);
    // Update filteredData where clause
    List<model.OrderModel> filteredData = _orders;

    // Pagination Logic
    final int totalItems = _totalOrdersCount; // Use API-provided total count
    final int totalPages = (totalItems / _rowsPerPage).ceil();
    final List<model.OrderModel> paginatedData = _orders; // Use _orders directly

    // Update isFilterApplied check
    bool isFilterApplied = _selectedStatusFilter != "All" || _selectedUserFilter != "All" ||
        _selectedOrderTypeFilter != "All";
    bool isRangeFilterApplied = _salesAmountRange.start > _minSalesAmount ||
        _salesAmountRange.end < _maxSalesAmount;
    return Scaffold(
      body: Column(
        children: [
          // Top Bar
          TopBar(
            screen: Screen.ORDERS,
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
                //_preferences.saveLayoutSelection(newLayout);
                //Build #1.0.122: update layout mode change selection to DB
                await UserDbHelper().saveUserSettings({AppDBConst.layoutSelection: newLayout}, modeChange: true);
              });
            },
          ),
          const Divider(
            color: Colors.grey,
            thickness: 0.4,
            height: 1,
          ),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Left Sidebar (Conditional)
                if (sidebarPosition == SidebarPosition.left)
                  custom_widgets.NavigationBar(
                    //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
                    selectedSidebarIndex: _selectedSidebarIndex,
                    onSidebarItemSelected: (index) {
                      setState(() {
                        _selectedSidebarIndex = index;
                        debugPrint("OrdersScreen: Sidebar index changed to $index");
                      });
                    },
                    isVertical: true, // Vertical layout for left sidebar
                  ),

                // Order Panel on the Left (Conditional: Only when sidebar is right or bottom with left order panel)
                if (sidebarPosition == SidebarPosition.right ||
                    (sidebarPosition == SidebarPosition.bottom &&
                        orderPanelPosition == OrderPanelPosition.left))
                // Replace your OrderScreenPanel instances with:
                  OrderScreenPanel(
                    fetchOrders: !isLoading, // Sync with parent's loading state
                    key: ValueKey(orderHelper.activeOrderId ?? 0),
                    formattedDate: '',
                    formattedTime: '',
                    quantities: quantities,
                    activeOrderId: orderHelper.activeOrderId,
                    refreshOrderList: _refreshOrderList, // Build #1.0.143: Fixed Issue : After return from order summary screen , total order screen not refreshing with updated response
                  ),


                // Main Content (Table layout View)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Filters
                      Wrap(
                        spacing: 8.0,
                        children: [
                          // User Filter
                          FilterChipWidget(
                            label: "User",
                            options: _filterUsers.map((filter) => filter.displayName ?? "").toList(),
                            selectedValue: _selectedUserFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedUserFilter = value;
                                _currentPage = 1;
                                _fetchOrders();
                                debugPrint("OrdersScreen: User filter changed to $value");
                              });
                            },
                          ),
                          // Status Filter
                          FilterChipWidget(
                            label: "Status",
                            options: _filterStatuses.map((filter) => filter.name).toList(),
                            selectedValue: _selectedStatusFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedStatusFilter = value;
                                _currentPage = 1;
                                _fetchOrders();
                                debugPrint("OrdersScreen: Status filter changed to $value");
                              });
                            },
                          ),
                          // Order Type Filter
                          FilterChipWidget(
                            label: "OrderType",
                            options: _filterOrderType.map((e) => e.name).toList(),
                            selectedValue: _selectedOrderTypeFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedOrderTypeFilter = value;
                                _currentPage = 1;
                                _fetchOrders();
                                debugPrint("OrdersScreen: Order type filter changed to $value");
                              });
                            },
                          ),
                          // Range Filter
                          // Container(
                          //   height: MediaQuery.of(context).size.height * 0.06,
                          //   margin: EdgeInsets.symmetric(vertical: 10),
                          //   padding: const EdgeInsets.symmetric(horizontal: 4),
                          //   child: ChoiceChip(
                          //     shape: const RoundedRectangleBorder(
                          //       side: BorderSide(color: Colors.black),
                          //       borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          //     ),
                          //     visualDensity: VisualDensity.compact,
                          //     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          //     label: Row(
                          //       mainAxisSize: MainAxisSize.min,
                          //       children: [
                          //         Text(
                          //           "Select Range",
                          //           style: TextStyle(
                          //             color: isRangeFilterApplied
                          //                 ? Colors.white
                          //                 : Colors.black,
                          //           ),
                          //         ),
                          //         const SizedBox(width: 4),
                          //         Icon(
                          //           Icons.filter_list,
                          //           size: 18,
                          //           color: isRangeFilterApplied
                          //               ? Colors.white
                          //               : Colors.black,
                          //         ),
                          //       ],
                          //     ),
                          //     showCheckmark: false,
                          //     selected: isRangeFilterApplied,
                          //     selectedColor: Colors.redAccent,
                          //     backgroundColor: Colors.grey[200],
                          //     onSelected: (selected) {
                          //       _openRangeFilterDialog();
                          //       _currentPage = 1;
                          //     },
                          //   ),
                          // ),
                          // Date Range Filter
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: GestureDetector(
                              onTap: _openDateRangePickerDialog,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // if (_isDateRangeApplied) ...[
                                  //   Text(
                                  //     "${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}",
                                  //     style: TextStyle(
                                  //       color: _isDateRangeApplied ? Colors.white : Colors.black,
                                  //       fontSize: 14,
                                  //     ),
                                  //   ),
                                  //   const SizedBox(width: 8),
                                  // ],
                                  SvgPicture.asset(
                                    'assets/svg/filter_calendar.svg',
                                    width: MediaQuery.of(context).size.width * 0.1,
                                    height: MediaQuery.of(context).size.height * 0.06,
                                    colorFilter: ColorFilter.mode(
                                      _isDateRangeApplied ? Colors.redAccent :themeHelper.themeMode == ThemeMode.dark
                                          ? ThemeNotifier.textDark : Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                    //color: _isDateRangeApplied ? Colors.white : Colors.black,
                                  ),
                                  // if (!_isDateRangeApplied) ...[
                                  //   const SizedBox(width: 8),
                                  //   Text(
                                  //     "Date Range",
                                  //     style: TextStyle(
                                  //       color: Colors.black,
                                  //       fontSize: 14,
                                  //     ),
                                  //   ),
                                  // ],
                                ],
                              ),
                            ),
                          ),
                          // Clear Filters
                          if (isFilterApplied || isRangeFilterApplied || _isDateRangeApplied)
                            Container(
                              margin:EdgeInsets.symmetric(vertical: 5),
                              child: IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isFilterApplied || isRangeFilterApplied || _isDateRangeApplied
                                      ? Colors.redAccent
                                      : Colors.black,
                                ),
                                onPressed: _clearFilters,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Data Table and Pagination controls
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Table Header with colored container
                                Container(
                                  padding: const EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
                                  decoration: BoxDecoration(
                                    color: themeHelper.themeMode == ThemeMode.dark
                                        ? ThemeNotifier.primaryBackground : Colors.grey[100], // Light grey background
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color:themeHelper.themeMode == ThemeMode.dark
                                        ? ThemeNotifier.borderColor : Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      _buildSortableColumn("ID", 'id'),
                                      _buildSortableColumn("Order Type", 'orderType'),
                                      _buildSortableColumn("Date", 'date'),
                                      _buildSortableColumn("Time", 'time'),
                                      _buildSortableColumn("Total", 'sales_amount'), //Build #1.0.134: changed to "Total"
                                      _buildSortableColumn("Status", 'status'),
                                      //_buildHeaderCell(""),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Data Rows
                                //...filteredData.map((order)
                                ...paginatedData.map((order){
                                  final date = DateTime.tryParse(order.dateCreated)?.toLocal();
                                  final formattedDate = date != null
                                      ? DateFormat("EEE, MMM d' '${now.year}'").format(date)
                                      : '';
                                  final formattedTime = date != null
                                      ? DateFormat('HH:mm:ss').format(date)
                                      : '';
                                  final isSelected = orderHelper.activeOrderId == order.id; // Check if the row is selected

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: GestureDetector( // Add GestureDetector for row click
                                      onTap: () => _onOrderRowSelected(order.id),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 8.0),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (themeHelper.themeMode == ThemeMode.dark
                                              ? Color(0xFF334756)  // Dark selection color for dark mode
                                              : Color(0xFFF3ECEC)) // Light selection color for light mode
                                              : (themeHelper.themeMode == ThemeMode.dark
                                              ? ThemeNotifier.primaryBackground
                                              : Colors.white),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: themeHelper.themeMode == ThemeMode.dark
                                              ? ThemeNotifier.borderColor : Colors.grey.shade300),
                                          boxShadow: [
                                            BoxShadow(
                                              color: themeHelper.themeMode == ThemeMode.dark
                                                  ? ThemeNotifier.shadow_F7 : Colors.grey.withValues(alpha: 0.2),
                                              blurRadius: 2,
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            _buildDataCell(order.id.toString()),
                                            _buildDataCell(_filterOrderType.firstWhere((e) => e.slug == order.createdVia.toString()).name), //AppDBConst.orderType
                                            _buildDataCell(formattedDate),
                                            _buildDataCell(formattedTime),
                                            _buildDataCell('${order.currencySymbol}${order.total}'),
                                            //  _buildDataCell('N/A'), // Over/short not in API response
                                            _buildDataCell(order.status, isStatus: true),
                                            // Add action buttons if needed
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                // Show message when no data available
                                if (paginatedData.isEmpty && filteredData.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: Text(
                                        'No orders found',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: themeHelper.themeMode == ThemeMode.dark
                                              ? ThemeNotifier.textDark : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Show message when filters result in no data
                                if (paginatedData.isEmpty && filteredData.isEmpty && _orders.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: Text(
                                        'No orders match the selected filters',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: themeHelper.themeMode == ThemeMode.dark
                                              ? ThemeNotifier.textDark : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ADDED: Pagination Controls
                      //if (!isLoading && totalItems > 0)
                      if (!isLoading && _totalOrdersCount > _rowsPerPage)
                        _buildPaginationControls(totalItems, totalPages),
                      // REUSABLE PAGINATION WIDGET
                      // PaginationWidget(
                      //   currentPage: _currentPage,
                      //   totalItems: filteredData.length,
                      //   rowsPerPage: _rowsPerPage,
                      //   rowsPerPageOptions: _rowsPerPageOptions,
                      //   onPageChanged: (page) {
                      //     setState(() {
                      //       _currentPage = page;
                      //     });
                      //     debugPrint("OrdersScreen: Page changed to $page");
                      //   },
                      //   onRowsPerPageChanged: (rowsPerPage) {
                      //     setState(() {
                      //       _rowsPerPage = rowsPerPage;
                      //       _currentPage = 1; // Reset to first page
                      //     });
                      //     debugPrint("OrdersScreen: Rows per page changed to $rowsPerPage");
                      //   },
                      //   showFirstLastButtons: true,
                      //   showPageNumbers: true,
                      //   emptyMessage: "No orders found",
                      //   // Optional customization
                      //   backgroundColor: Colors.grey[50],
                      //   textStyle: const TextStyle(fontSize: 14, color: Colors.black87),
                      //   buttonColor: Colors.blue,
                      //   disabledButtonColor: Colors.grey,
                      // ),
                    ],
                  ),
                ),

                // Order Panel on the Right
                if (sidebarPosition != SidebarPosition.right &&
                    !(sidebarPosition == SidebarPosition.bottom &&
                        orderPanelPosition == OrderPanelPosition.left))
                // Replace your OrderScreenPanel instances with:
                  OrderScreenPanel(
                    fetchOrders: !isLoading, // Sync with parent's loading state
                    key: ValueKey(orderHelper.activeOrderId ?? 0),
                    formattedDate: '',
                    formattedTime: '',
                    quantities: quantities,
                    activeOrderId: orderHelper.activeOrderId,
                    refreshOrderList: _refreshOrderList, // Build #1.0.143: Fixed Issue : After return from order summary screen , total order screen not refreshing with updated response
                  ),


                // Right Sidebar
                if (sidebarPosition == SidebarPosition.right)
                  custom_widgets.NavigationBar(
                    selectedSidebarIndex: _selectedSidebarIndex,
                    onSidebarItemSelected: (index) {
                      setState(() {
                        _selectedSidebarIndex = index;
                        debugPrint("OrdersScreen: Sidebar index changed to $index");
                      });
                    },
                    isVertical: true,
                  ),
              ],
            ),
          ),

          // Bottom Sidebar
          if (sidebarPosition == SidebarPosition.bottom)
            custom_widgets.NavigationBar(
              selectedSidebarIndex: _selectedSidebarIndex,
              onSidebarItemSelected: (index) {
                setState(() {
                  _selectedSidebarIndex = index;
                  debugPrint("OrdersScreen: Sidebar index changed to $index");
                });
              },
              isVertical: false,
            ),
        ],
      ),
    );
  }

  // method to handle row selection
  void _onOrderRowSelected(int orderId) async {
    debugPrint("OrdersScreen: _onOrderRowSelected id $orderId");
    // Explicitly declare selectedOrder as a nullable OrderModel
    model.OrderModel? selectedOrder;
    // ADD this logic to determine the date and time for the panel
    String panelDate;
    String panelTime;

    if(orderId == -1){
      orderId = _orders.first.id; //Build #1.0.165: to fix issue in windows, not able to save lastActiveOrderID
    }

    if (_selectedOrderId != null) {
      // Use indexWhere to safely find the index of the selected order.
      // It returns -1 if no element is found, preventing errors.
      final index = _orders.indexWhere((order) => order.id == _selectedOrderId);

      if (index != -1) {
        // If the index is valid, get the order from the list.
        selectedOrder = _orders[index];
      }
    }

    if (selectedOrder != null) {
      // If an order is selected, parse and format its date and time
      final date = DateTime.tryParse(selectedOrder.dateCreated)?.toLocal();
      if (date != null) {
        panelDate = DateFormat("EEE, MMM d, yyyy").format(date);
        panelTime = DateFormat('hh:mm a').format(date);
      } else {
        // Fallback if the date string is invalid
        panelDate = 'Invalid Date';
        panelTime = 'Invalid Time';
      }
    } else {
      // If no order is selected, default to the current date and time
      final now = DateTime.now();
      panelDate = DateFormat("EEE, MMM d, yyyy").format(now);
      panelTime = DateFormat('hh:mm a').format(now);
    }

    if (orderHelper.activeOrderId != orderId) {
      // Create or switch to order tab in RightOrderPanel
      await orderHelper.setActiveOrder(orderId);
      // Notify RightOrderPanel to refresh
      // Set the state with the selected order's ID
      setState(() {
        // If the user taps the same row, you might want to deselect it
        if (_selectedOrderId == orderId) {
          _selectedOrderId = null;
          // Consider clearing the helper as well if needed
          // orderHelper.clearActiveOrder();
        } else {
          _selectedOrderId = orderId;
        }
      });
      debugPrint("OrdersScreen: Selected order ID $_selectedOrderId");
    }
    _orderScreenPanel = OrderScreenPanel(
      key: ValueKey(orderId), // Use orderId as key
      formattedDate: panelDate,
      formattedTime: panelTime,
      quantities: quantities,
      activeOrderId: orderId, // Pass activeOrderId
      fetchOrders: !isLoading,
    );
    // _orderScreenPanel.setFormattedDate = panelDate;
    // _orderScreenPanel.setFormattedTime = panelTime;

  }

  Widget _buildPaginationControls(int totalItems, int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text("Rows per page:"),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: DropdownButton<int>(
              value: _rowsPerPage,
              underline: const SizedBox.shrink(),
              items: _rowsPerPageOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _rowsPerPage = newValue;
                    _currentPage = 1; // Reset to first page
                    _fetchOrders(); // Fetch new data
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 24),
          Text(
            totalItems == 0
                ? '0-0 of 0'
                : '${(_currentPage - 1) * _rowsPerPage + 1}-${(_currentPage * _rowsPerPage) > totalItems ? totalItems : (_currentPage * _rowsPerPage)} of $totalItems',
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage == 1 || totalItems == 0
                ? null
                : () {
              setState(() {
                _currentPage = 1;
                _fetchOrders(); // Fetch new data
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage == 1 || totalItems == 0
                ? null
                : () {
              setState(() {
                _currentPage--;
                _fetchOrders(); // Fetch new data
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage == totalPages || totalItems == 0
                ? null
                : () {
              setState(() {
                _currentPage++;
                _fetchOrders(); // Fetch new data
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage == totalPages || totalItems == 0
                ? null
                : () {
              setState(() {
                _currentPage = totalPages;
                _fetchOrders(); // Fetch new data
              });
            },
          ),
        ],
      ),
    );
  }

  // Build sortable column header
  Widget _buildSortableColumn(String label, String columnKey) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.105,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        child: InkWell(
          onTap: () {
            _sortData(columnKey);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: themeHelper.themeMode == ThemeMode.dark
                        ? ThemeNotifier.textDark : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              if (_sortColumn == columnKey)
                Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color:  Colors.blue,
                  size: 16,
                )
              else
                Icon(
                  Icons.unfold_more,
                  color: themeHelper.themeMode == ThemeMode.dark
                      ? ThemeNotifier.textDark : Colors.grey,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Build header cell
  Widget _buildHeaderCell(String text) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.105,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Build data cell
  Widget _buildDataCell(String text, {bool isStatus = false}) {
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.105,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: isStatus
            ? StatusWidget(
          status: text,
          dotSize: 8.0,
          fontSize: 14.0,
        )
            : Text(
          text,
          style: TextStyle(
            color: themeHelper.themeMode == ThemeMode.dark
                ? ThemeNotifier.textDark : Colors.black87,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}