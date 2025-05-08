import '../../Widgets/widget_filter_chip.dart';
import '../../Widgets/widget_order_panel.dart';
import '../../Widgets/widget_range_filter.dart';
import '../../Widgets/widget_topbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;

import 'package:quickalert/quickalert.dart';

// Enum for sidebar position
enum SidebarPosition { left, right, bottom }

// Enum for order panel position
enum OrderPanelPosition { left, right }

class OrdersScreen extends StatefulWidget { // Build #1.0.8, Surya added
  // Build #1.0.6 - Updated Horizontal & Vertical Scrolling
  final int? lastSelectedIndex; // Make it nullable

  const OrdersScreen(
      {super.key, this.lastSelectedIndex}); // Optional, no default value

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final List<String> items = List.generate(18, (index) => 'Bud Light');
  int _selectedSidebarIndex = 3; //Build #1.0.2 : By default fast key should be selected after login
  DateTime now = DateTime.now();
  List<int> quantities = [1, 1, 1, 1];
  SidebarPosition sidebarPosition =
      SidebarPosition.left; // Default to bottom sidebar
  OrderPanelPosition orderPanelPosition =
      OrderPanelPosition.right; // Default to right
  bool isLoading = true; // Add a loading state

  String _selectedStatusFilter = "All";
  String _selectedUserFilter = "User1";
  String _selectedCurrencyFilter = "All";
  late double _minSalesAmount;
  late double _maxSalesAmount;
  late RangeValues _salesAmountRange;

  String? _sortColumn;
  bool _isAscending = true;

  final List<Map<String, String>> allData = [
    {
      'date': '29/10/2024',
      'id': '11104',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'status': 'Failed',
      'sales_amount': '₹300',
      'over_short': '-₹60',
    },
    {
      'date': '25/10/2024',
      'duration': '8:00:00',
      'id': '11105',
      'status': 'Completed',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'sales_amount': '₹50',
      'over_short': '-₹60',
    },
    {
      'date': '26/10/2024',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'id': '11106',
      'status': 'Completed',
      'end_time': '08:00:00',
      'sales_amount': '₹3050',
      'over_short': '-₹1600',
    },
    {
      'date': '20/10/2024',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'id': '11107',
      'status': 'Processing',
      'end_time': '08:00:00',
      'sales_amount': '₹8850',
      'over_short': '-₹600',
    },
    {
      'date': '30/10/2024',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11108',
      'status': 'Processing',
      'sales_amount': '₹1150',
      'over_short': '-₹610',
    },
    {
      'date': '31/10/2024',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11109',
      'status': 'On hold',
      'sales_amount': '₹358',
      'over_short': '-₹67',
    },
    {
      'date': '01/11/2024',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11210',
      'status': 'Cancelled',
      'sales_amount': '₹38',
      'over_short': '-₹6',
    },
    {
      'date': '25/10/2024',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11211',
      'status': 'Refunded',
      'sales_amount': '₹340',
      'over_short': '-₹60',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'id': '11212',
      'status': 'Refunded',
      'end_time': '08:00:00',
      'sales_amount': '₹950',
      'over_short': '-₹90',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11213',
      'status': 'Completed',
      'sales_amount': '₹350',
      'over_short': '-₹60',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11214',
      'status': 'On hold',
      'sales_amount': '₹350',
      'over_short': '-₹60',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'id': '11215',
      'status': 'Completed',
      'end_time': '08:00:00',
      'sales_amount': '₹150',
      'over_short': '-₹20',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11216',
      'status': 'Processing',
      'sales_amount': '\$30',
      'over_short': '-\$10',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'sales_amount': '\$50',
      'id': '11217',
      'status': 'Refunded',
      'over_short': '-\$90',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11218',
      'status': 'Cancelled',
      'sales_amount': '\$530',
      'over_short': '-\$160',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11219',
      'status': 'Completed',
      'sales_amount': '\$150',
      'over_short': '-\$70',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'start_time': '12:00:00',
      'end_time': '08:00:00',
      'id': '11221',
      'status': 'On hold',
      'sales_amount': '\$450',
      'over_short': '-\$600',
    },
  ];

  void _sortData(String column) {
    setState(() {
      if (_sortColumn == column) {
        if (_isAscending) {
          _isAscending = false; // Second tap: Descending
        } else {
          _sortColumn = null; // Third tap: Reset sorting
        }
      } else {
        _sortColumn = column;
        _isAscending = true; // First tap: Ascending
      }

      if (_sortColumn != null) {
        // Reset data to its original order
        allData
            .sort((a, b) => int.parse(a['id']!).compareTo(int.parse(b['id']!)));
        allData.sort((a, b) {
          var aValue = a[column] ?? '';
          var bValue = b[column] ?? '';

          if (column == 'id' || column == 'sales_amount') {
            // Remove currency symbols before parsing numbers
            aValue = aValue.replaceAll(RegExp(r'[^\d.-]'),
                ''); // Keep only numbers, dots, and minus signs
            bValue = bValue.replaceAll(RegExp(r'[^\d.-]'), '');
            return _isAscending
                ? double.parse(aValue).compareTo(double.parse(bValue))
                : double.parse(bValue).compareTo(double.parse(aValue));
          } else {
            return _isAscending
                ? aValue.compareTo(bValue)
                : bValue.compareTo(aValue);
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 3; // Build #1.0.7: Restore previous selection

    List<double> salesValues = allData
        .map((entry) => _extractSalesAmount(entry['sales_amount'] ?? '0'))
        .toList();
    _minSalesAmount = salesValues.reduce((a, b) => a < b ? a : b);
    _maxSalesAmount = salesValues.reduce((a, b) => a > b ? a : b);
    _salesAmountRange = RangeValues(_minSalesAmount, _maxSalesAmount);
    // Simulate a loading delay
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isLoading = false; // Set loading to false after 3 seconds
      });
    });
  }

  double _extractSalesAmount(String sales) {
    return double.tryParse(sales.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
  }

  void _openRangeFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Sales Amount Range"),
          content: SingleChildScrollView(
            child: Container(
              //width: double.maxFinite,
              child: RangeFilter(
                label: "Sales Amount",
                minValue: _minSalesAmount,
                maxValue: _maxSalesAmount,
                initialRange: _salesAmountRange,
                onRangeChanged: (range) {
                  setState(() {
                    _salesAmountRange = range;
                  });
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedStatusFilter = "All";
      _selectedCurrencyFilter = "All";
      _selectedUserFilter = "User1";
      _salesAmountRange = RangeValues(_minSalesAmount, _maxSalesAmount);
      // _minController.text = _minSalesAmount.toString();
      // _maxController.text = _maxSalesAmount.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    String formattedDate = DateFormat("EEE, MMM d' ${now.year}'").format(now);
    String formattedTime = DateFormat('hh:mm a').format(now);

    List<Map<String, String>> filteredData = allData.where((entry) {
      bool statusMatches = _selectedStatusFilter == "All" ||
          entry['status'] == _selectedStatusFilter;
      bool currencyMatches = _selectedCurrencyFilter == "All" ||
          entry['sales_amount']!.contains(_selectedCurrencyFilter);
      double salesAmount = _extractSalesAmount(entry['sales_amount']!);
      bool salesAmountMatches = salesAmount >= _salesAmountRange.start &&
          salesAmount <= _salesAmountRange.end;
      return statusMatches && currencyMatches && salesAmountMatches;
    }).toList();

    bool isFilterApplied = _selectedStatusFilter != "All" ||
        _selectedCurrencyFilter != "All";

    bool isRangeFilterApplied = _salesAmountRange.start > _minSalesAmount ||
        _salesAmountRange.end < _maxSalesAmount;

    return Scaffold(
      body: Column(
        children: [
          // Top Bar
          TopBar(
            onModeChanged: () {
              setState(() {
                if (sidebarPosition == SidebarPosition.left) {
                  sidebarPosition = SidebarPosition.right;
                } else if (sidebarPosition == SidebarPosition.right) {
                  sidebarPosition = SidebarPosition.bottom;
                } else {
                  sidebarPosition = SidebarPosition.left;
                }
              });
            },
          ),
          Divider(
            color: Colors.grey, // Light grey color
            thickness: 0.4, // Very thin line
            height: 1, // Minimal height
          ),

          SizedBox(
            height: 10,
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
                      });
                    },
                    isVertical: true, // Vertical layout for left sidebar
                  ),

                // Order Panel on the Left (Conditional: Only when sidebar is right or bottom with left order panel)
                if (sidebarPosition == SidebarPosition.right ||
                    (sidebarPosition == SidebarPosition.bottom &&
                        orderPanelPosition == OrderPanelPosition.left))
                  RightOrderPanel(
                    formattedDate: formattedDate,
                    formattedTime: formattedTime,
                    quantities: quantities,
                  ),


                // Main Content (Table layout View)
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(children: [
                      Wrap(
                        spacing: 8.0,
                        children: [
                          FilterChipWidget(
                            label: "Status: $_selectedUserFilter",
                            options: const [
                              "User1",
                              "User2",
                              "User3",
                            ],
                            selectedValue: _selectedUserFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedUserFilter = value;
                              });
                            },
                          ),
                          FilterChipWidget(
                            label: "Status: $_selectedStatusFilter",
                            options: const [
                              "All",
                              "Processing",
                              "Completed",
                              "On Hold",
                              "Failed",
                              "Pending",
                              "Refunded",
                              "Cancelled"
                            ],
                            selectedValue: _selectedStatusFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedStatusFilter = value;
                              });
                            },
                          ),
                          // FilterChip(
                          //   label: Text("Sales Amount"),
                          //   onSelected: (selected) {
                          //     showMenu(
                          //       context: context,
                          //       position: RelativeRect.fromLTRB(100, 100, 0, 0),
                          //       items: ["All", "₹", "\$"]
                          //           .map((currency) => PopupMenuItem<String>(
                          //         value: currency,
                          //         child: Text(currency),
                          //       ))
                          //           .toList(),
                          //     ).then((value) {
                          //       if (value != null) {
                          //         setState(() {
                          //           _selectedCurrencyFilter = value;
                          //         });
                          //       }
                          //     });
                          //   },
                          // ),
                          FilterChipWidget(
                            label: "Currency: $_selectedCurrencyFilter",
                            options: ["All", "₹", "\$"],
                            selectedValue: _selectedCurrencyFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedCurrencyFilter = value;
                              });
                            },
                          ),
                          Container(
                            height: 40,
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            //alignment: Alignment.center,
                            child: ChoiceChip(
                              shape:RoundedRectangleBorder(side: BorderSide(color: Colors.black),borderRadius: BorderRadius.all(Radius.circular(10.0))),
                              visualDensity: VisualDensity.compact, // Reduces unwanted padding
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Select Range",
                                    style: TextStyle(
                                        color: isRangeFilterApplied
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: isRangeFilterApplied || isRangeFilterApplied
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ],
                              ),
                              showCheckmark: false,
                              selected: isRangeFilterApplied,
                              selectedColor: Colors.redAccent,
                              backgroundColor: Colors.grey[200],
                              onSelected: (selected) {
                                _openRangeFilterDialog();
                              },
                            ),
                          ),
                          // RangeFilter(
                          //   label: "Sales Amount",
                          //   minValue: _minSalesAmount,
                          //   maxValue: _maxSalesAmount,
                          //   initialRange: _salesAmountRange,
                          //   onRangeChanged: _updateRange, // Use the reusable RangeFilter
                          // ),
                          if (_selectedStatusFilter != "All" ||
                              _selectedCurrencyFilter != "All" ||
                              _salesAmountRange.start > _minSalesAmount ||
                              _salesAmountRange.end < _maxSalesAmount)
                            IconButton(
                              icon: Icon(Icons.clear,
                                  color: isFilterApplied || isRangeFilterApplied
                                      ? Colors.redAccent
                                      : Colors.black),
                              onPressed: _clearFilters,
                            ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          physics: BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Table Header
                              Container(
                                padding: EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
                                decoration: BoxDecoration(
                                  // color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _buildSortableColumn("ID", 'id'),
                                    _buildSortableColumn("Date", 'date'),
                                    _buildHeaderCell("Duration"),
                                    _buildHeaderCell("Start Time"),
                                    _buildHeaderCell("End Time"),
                                    _buildSortableColumn("Sales Amount", 'sales_amount' ),
                                    _buildHeaderCell("Over/Short"),
                                    _buildSortableColumn("Status", 'status'),
                                    _buildHeaderCell(""),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),

                              // Data Rows
                              ...filteredData.map((entry) => Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      _buildDataCell(entry['id']!),
                                      _buildDataCell(entry['date']!),
                                      _buildDataCell(entry['duration']!),
                                      _buildDataCell(entry['start_time']!),
                                      _buildDataCell(entry['end_time']!),
                                      _buildDataCell(entry['sales_amount']!),
                                      _buildDataCell(entry['over_short']!),
                                      _buildDataCell(entry['status']!),

                                      // Action Buttons
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () {},
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              QuickAlert.show(
                                                width: 350,
                                                context: context,
                                                type: QuickAlertType.confirm,
                                                title: "Are you sure?",
                                                text: 'This action cannot be undone.',
                                                confirmBtnText: 'Yes, Delete',
                                                cancelBtnText: 'Cancel',
                                                barrierDismissible: false,
                                                confirmBtnColor: Colors.red,
                                                confirmBtnTextStyle: TextStyle(fontSize: 14, color: Colors.white),
                                                onConfirmBtnTap: () {
                                                  Navigator.of(context).pop();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text("Item deleted successfully")),
                                                  );
                                                },
                                                onCancelBtnTap: () {
                                                  Navigator.of(context).pop();
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                            ],
                          ),
                          // DataTable(
                          //   headingRowColor: WidgetStateColor.resolveWith(
                          //       (states) => Colors.grey.shade200),
                          //   columns: <DataColumn>[
                          //     //DataColumn(label: Text('ID')),
                          //     _buildSortableColumn('ID', 'id'),
                          //     //DataColumn(label: Text('Date')),
                          //     _buildSortableColumn('Date', 'date'),
                          //     DataColumn(label: Text('Duration')),
                          //     DataColumn(label: Text('Start Time')),
                          //     DataColumn(label: Text('End Time')),
                          //     //DataColumn(label: Text('Sales Amount')),
                          //     _buildSortableColumn('Sales Amount', 'sales_amount' ),
                          //     DataColumn(label: Text('Over/Short')),
                          //     //DataColumn(label: Text('Status')),
                          //     _buildSortableColumn('Status', 'status'),
                          //     DataColumn(label: Text('')),
                          //   ],
                          //     Column(
                          //       children: filteredData.map((entry) {
                          //         return Container(
                          //           margin: EdgeInsets.symmetric(vertical: 4), // Spacing between rows
                          //           padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Inner padding
                          //           decoration: BoxDecoration(
                          //             color: Colors.white, // Row background color
                          //             borderRadius: BorderRadius.circular(12), // Rounded corners
                          //             border: Border.all(color: Colors.grey.shade300, width: 1), // Border styling
                          //             boxShadow: [
                          //               BoxShadow(
                          //                 color: Colors.grey.shade200,
                          //                 blurRadius: 4,
                          //                 offset: Offset(0, 2), // Soft shadow
                          //               ),
                          //             ],
                          //           ),
                          //           child: Row(
                          //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //             children: [
                          //               Expanded(child: Text(entry['id']!, textAlign: TextAlign.center)),
                          //               Expanded(child: Text(entry['date']!, textAlign: TextAlign.center)),
                          //               Expanded(child: Text(entry['duration']!, textAlign: TextAlign.center)),
                          //               Expanded(child: Text(entry['start_time']!, textAlign: TextAlign.center)),
                          //               Expanded(child: Text(entry['end_time']!, textAlign: TextAlign.center)),
                          //               Expanded(child: Text(entry['sales_amount']!, textAlign: TextAlign.center)),
                          //               Expanded(child: Text(entry['over_short']!, textAlign: TextAlign.center)),
                          //               Expanded(child: Text(entry['status']!, textAlign: TextAlign.center)),
                          //               Expanded(
                          //                 child: Row(
                          //                   mainAxisAlignment: MainAxisAlignment.center,
                          //                   children: [
                          //                     IconButton(
                          //                       icon: Icon(Icons.edit, color: Colors.blue),
                          //                       onPressed: () {},
                          //                     ),
                          //                     IconButton(
                          //                       icon: Icon(Icons.delete, color: Colors.red),
                          //                       onPressed: () {
                          //                         QuickAlert.show(
                          //                           context: context,
                          //                           type: QuickAlertType.confirm,
                          //                           title: "Are you sure?",
                          //                           text: 'This action cannot be undone.',
                          //                           confirmBtnText: 'Yes, Delete',
                          //                           cancelBtnText: 'Cancel',
                          //                           barrierDismissible: false,
                          //                           confirmBtnColor: Colors.red,
                          //                           confirmBtnTextStyle: TextStyle(fontSize: 14, color: Colors.white),
                          //                           onConfirmBtnTap: () {
                          //                             Navigator.of(context).pop();
                          //                             ScaffoldMessenger.of(context).showSnackBar(
                          //                               SnackBar(content: Text("Item deleted successfully")),
                          //                             );
                          //                           },
                          //                           onCancelBtnTap: () {
                          //                             Navigator.of(context).pop();
                          //                           },
                          //                         );
                          //                       },
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ],
                          //           ),
                          //         );
                          //       }).toList(),
                          //     ),
                          // ),
                        ),
                      ),
                    ),
                  ],
                )),

                // Order Panel on the Right (Conditional: Only when sidebar is left or bottom with right order panel)
                if (sidebarPosition != SidebarPosition.right &&
                    !(sidebarPosition == SidebarPosition.bottom &&
                        orderPanelPosition == OrderPanelPosition.left))
                  RightOrderPanel(
                    formattedDate: formattedDate,
                    formattedTime: formattedTime,
                    quantities: quantities,
                  ),

                // Right Sidebar (Conditional)
                if (sidebarPosition == SidebarPosition.right)
                  custom_widgets.NavigationBar(
                    //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
                    selectedSidebarIndex: _selectedSidebarIndex,
                    onSidebarItemSelected: (index) {
                      setState(() {
                        _selectedSidebarIndex = index;
                      });
                    },
                    isVertical: true, // Vertical layout for right sidebar
                  ),
              ],
            ),
          ),

          // Bottom Sidebar (Conditional)
          if (sidebarPosition == SidebarPosition.bottom)
            custom_widgets.NavigationBar(
              //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
              selectedSidebarIndex: _selectedSidebarIndex,
              onSidebarItemSelected: (index) {
                setState(() {
                  _selectedSidebarIndex = index;
                });
              },
              isVertical: false, // Horizontal layout for bottom sidebar
            ),
        ],
      ),
    );
  }

  // DataColumn _buildSortableColumn(String label, String columnKey) {
  //   return DataColumn(
  //       label: GestureDetector(
  //     onTap: () {
  //       _sortData(columnKey);
  //     },
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Text(label),
  //         if (_sortColumn == columnKey)
  //           Icon(
  //             _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
  //             color: Colors.blue, // Highlight active sorting
  //             size: 16,
  //           )
  //         else
  //           Icon(
  //             Icons.unfold_more, // Default inactive state
  //             color: Colors.grey,
  //             size: 16,
  //           )
  //       ],
  //     ),
  //   ));
  // }

  _buildSortableColumn(String label, String columnKey) {
    return SizedBox(
      width: 120,
      child: Padding(padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0), child: InkWell(
        onTap: () {
          _sortData(columnKey);
        },
        child: Row(
          //mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,),
            if(_sortColumn == columnKey)
              Icon(
                _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.blue, // Highlight active sorting
                size: 16,
              )
            else
              Icon(
                Icons.unfold_more, // Default inactive state
                color: Colors.grey,
                size: 16,
              )
          ],
        ),
      )),
    );
  }

// Helper Functions
  Widget _buildHeaderCell(String text) {
    return SizedBox(
      width: 120, // Fixed width to avoid flex issues
      //padding: EdgeInsets.all(8),
      //alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return SizedBox(
        width: 120,
        child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        )

    );
  }
}
