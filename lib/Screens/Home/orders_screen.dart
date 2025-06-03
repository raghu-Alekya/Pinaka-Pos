// import '../../Widgets/widget_alert_popup_dialogs.dart';
// import '../../Widgets/widget_filter_chip.dart';
// import '../../Widgets/widget_order_panel.dart';
// import '../../Widgets/widget_range_filter.dart';
// import '../../Widgets/widget_topbar.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;
//
// // Enum for sidebar position
// enum SidebarPosition { left, right, bottom }
//
// // Enum for order panel position
// enum OrderPanelPosition { left, right }
//
// class OrdersScreen extends StatefulWidget { // Build #1.0.8, Surya added
//   // Build #1.0.6 - Updated Horizontal & Vertical Scrolling
//   final int? lastSelectedIndex; // Make it nullable
//
//   const OrdersScreen(
//       {super.key, this.lastSelectedIndex}); // Optional, no default value
//
//   @override
//   State<OrdersScreen> createState() => _OrdersScreenState();
// }
//
// class _OrdersScreenState extends State<OrdersScreen> {
//   final List<String> items = List.generate(18, (index) => 'Bud Light');
//   int _selectedSidebarIndex = 3; //Build #1.0.2 : By default fast key should be selected after login
//   DateTime now = DateTime.now();
//   List<int> quantities = [1, 1, 1, 1];
//   SidebarPosition sidebarPosition =
//       SidebarPosition.left; // Default to bottom sidebar
//   OrderPanelPosition orderPanelPosition =
//       OrderPanelPosition.right; // Default to right
//   bool isLoading = true; // Add a loading state
//
//   String _selectedStatusFilter = "All";
//   String _selectedUserFilter = "User1";
//   String _selectedCurrencyFilter = "All";
//   late double _minSalesAmount;
//   late double _maxSalesAmount;
//   late RangeValues _salesAmountRange;
//
//   String? _sortColumn;
//   bool _isAscending = true;
//
//   final List<Map<String, String>> allData = [
//     {
//       'date': '29/10/2024',
//       'id': '11104',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'status': 'Failed',
//       'sales_amount': '₹300',
//       'over_short': '-₹60',
//     },
//     {
//       'date': '25/10/2024',
//       'duration': '8:00:00',
//       'id': '11105',
//       'status': 'Completed',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'sales_amount': '₹50',
//       'over_short': '-₹60',
//     },
//     {
//       'date': '26/10/2024',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'id': '11106',
//       'status': 'Completed',
//       'end_time': '08:00:00',
//       'sales_amount': '₹3050',
//       'over_short': '-₹1600',
//     },
//     {
//       'date': '20/10/2024',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'id': '11107',
//       'status': 'Processing',
//       'end_time': '08:00:00',
//       'sales_amount': '₹8850',
//       'over_short': '-₹600',
//     },
//     {
//       'date': '30/10/2024',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11108',
//       'status': 'Processing',
//       'sales_amount': '₹1150',
//       'over_short': '-₹610',
//     },
//     {
//       'date': '31/10/2024',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11109',
//       'status': 'On hold',
//       'sales_amount': '₹358',
//       'over_short': '-₹67',
//     },
//     {
//       'date': '01/11/2024',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11210',
//       'status': 'Cancelled',
//       'sales_amount': '₹38',
//       'over_short': '-₹6',
//     },
//     {
//       'date': '25/10/2024',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11211',
//       'status': 'Refunded',
//       'sales_amount': '₹340',
//       'over_short': '-₹60',
//     },
//     {
//       'date': '28/10/2023',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'id': '11212',
//       'status': 'Refunded',
//       'end_time': '08:00:00',
//       'sales_amount': '₹950',
//       'over_short': '-₹90',
//     },
//     {
//       'date': '28/10/2023',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11213',
//       'status': 'Completed',
//       'sales_amount': '₹350',
//       'over_short': '-₹60',
//     },
//     {
//       'date': '28/10/2023',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11214',
//       'status': 'On hold',
//       'sales_amount': '₹350',
//       'over_short': '-₹60',
//     },
//     {
//       'date': '28/10/2023',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'id': '11215',
//       'status': 'Completed',
//       'end_time': '08:00:00',
//       'sales_amount': '₹150',
//       'over_short': '-₹20',
//     },
//     {
//       'date': '28/10/2023',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11216',
//       'status': 'Processing',
//       'sales_amount': '\$30',
//       'over_short': '-\$10',
//     },
//     {
//       'date': '28/10/2023',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'sales_amount': '\$50',
//       'id': '11217',
//       'status': 'Refunded',
//       'over_short': '-\$90',
//     },
//     {
//       'date': '28/10/2023',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11218',
//       'status': 'Cancelled',
//       'sales_amount': '\$530',
//       'over_short': '-\$160',
//     },
//     {
//       'date': '28/10/2023',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11219',
//       'status': 'Completed',
//       'sales_amount': '\$150',
//       'over_short': '-\$70',
//     },
//     {
//       'date': '28/10/2023',
//       'duration': '8:00:00',
//       'start_time': '12:00:00',
//       'end_time': '08:00:00',
//       'id': '11221',
//       'status': 'On hold',
//       'sales_amount': '\$450',
//       'over_short': '-\$600',
//     },
//   ];
//
//   void _sortData(String column) {
//     setState(() {
//       if (_sortColumn == column) {
//         if (_isAscending) {
//           _isAscending = false; // Second tap: Descending
//         } else {
//           _sortColumn = null; // Third tap: Reset sorting
//         }
//       } else {
//         _sortColumn = column;
//         _isAscending = true; // First tap: Ascending
//       }
//
//       if (_sortColumn != null) {
//         // Reset data to its original order
//         allData
//             .sort((a, b) => int.parse(a['id']!).compareTo(int.parse(b['id']!)));
//         allData.sort((a, b) {
//           var aValue = a[column] ?? '';
//           var bValue = b[column] ?? '';
//
//           if (column == 'id' || column == 'sales_amount') {
//             // Remove currency symbols before parsing numbers
//             aValue = aValue.replaceAll(RegExp(r'[^\d.-]'),
//                 ''); // Keep only numbers, dots, and minus signs
//             bValue = bValue.replaceAll(RegExp(r'[^\d.-]'), '');
//             return _isAscending
//                 ? double.parse(aValue).compareTo(double.parse(bValue))
//                 : double.parse(bValue).compareTo(double.parse(aValue));
//           } else {
//             return _isAscending
//                 ? aValue.compareTo(bValue)
//                 : bValue.compareTo(aValue);
//           }
//         });
//       }
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedSidebarIndex = widget.lastSelectedIndex ?? 3; // Build #1.0.7: Restore previous selection
//
//     List<double> salesValues = allData
//         .map((entry) => _extractSalesAmount(entry['sales_amount'] ?? '0'))
//         .toList();
//     _minSalesAmount = salesValues.reduce((a, b) => a < b ? a : b);
//     _maxSalesAmount = salesValues.reduce((a, b) => a > b ? a : b);
//     _salesAmountRange = RangeValues(_minSalesAmount, _maxSalesAmount);
//     // Simulate a loading delay
//     Future.delayed(const Duration(seconds: 3), () {
//       setState(() {
//         isLoading = false; // Set loading to false after 3 seconds
//       });
//     });
//   }
//
//   double _extractSalesAmount(String sales) {
//     return double.tryParse(sales.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
//   }
//
//   void _openRangeFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text("Select Sales Amount Range"),
//           content: SingleChildScrollView(
//             child: Container(
//               //width: double.maxFinite,
//               child: RangeFilter(
//                 label: "Sales Amount",
//                 minValue: _minSalesAmount,
//                 maxValue: _maxSalesAmount,
//                 initialRange: _salesAmountRange,
//                 onRangeChanged: (range) {
//                   setState(() {
//                     _salesAmountRange = range;
//                   });
//                 },
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text("Close"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _clearFilters() {
//     setState(() {
//       _selectedStatusFilter = "All";
//       _selectedCurrencyFilter = "All";
//       _selectedUserFilter = "User1";
//       _salesAmountRange = RangeValues(_minSalesAmount, _maxSalesAmount);
//       // _minController.text = _minSalesAmount.toString();
//       // _maxController.text = _maxSalesAmount.toString();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     String formattedDate = DateFormat("EEE, MMM d' ${now.year}'").format(now);
//     String formattedTime = DateFormat('hh:mm a').format(now);
//
//     List<Map<String, String>> filteredData = allData.where((entry) {
//       bool statusMatches = _selectedStatusFilter == "All" ||
//           entry['status'] == _selectedStatusFilter;
//       bool currencyMatches = _selectedCurrencyFilter == "All" ||
//           entry['sales_amount']!.contains(_selectedCurrencyFilter);
//       double salesAmount = _extractSalesAmount(entry['sales_amount']!);
//       bool salesAmountMatches = salesAmount >= _salesAmountRange.start &&
//           salesAmount <= _salesAmountRange.end;
//       return statusMatches && currencyMatches && salesAmountMatches;
//     }).toList();
//
//     bool isFilterApplied = _selectedStatusFilter != "All" ||
//         _selectedCurrencyFilter != "All";
//
//     bool isRangeFilterApplied = _salesAmountRange.start > _minSalesAmount ||
//         _salesAmountRange.end < _maxSalesAmount;
//
//     return Scaffold(
//       body: Column(
//         children: [
//           // Top Bar
//           TopBar(
//             onModeChanged: () {
//               setState(() {
//                 if (sidebarPosition == SidebarPosition.left) {
//                   sidebarPosition = SidebarPosition.right;
//                 } else if (sidebarPosition == SidebarPosition.right) {
//                   sidebarPosition = SidebarPosition.bottom;
//                 } else {
//                   sidebarPosition = SidebarPosition.left;
//                 }
//               });
//             },
//           ),
//           Divider(
//             color: Colors.grey, // Light grey color
//             thickness: 0.4, // Very thin line
//             height: 1, // Minimal height
//           ),
//
//           // SizedBox(
//           //   height: 10,
//           // ),
//
//           // Main Content
//           Expanded(
//             child: Row(
//               children: [
//                 // Left Sidebar (Conditional)
//                 if (sidebarPosition == SidebarPosition.left)
//                   custom_widgets.NavigationBar(
//                     //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
//                     selectedSidebarIndex: _selectedSidebarIndex,
//                     onSidebarItemSelected: (index) {
//                       setState(() {
//                         _selectedSidebarIndex = index;
//                       });
//                     },
//                     isVertical: true, // Vertical layout for left sidebar
//                   ),
//
//                 // Order Panel on the Left (Conditional: Only when sidebar is right or bottom with left order panel)
//                 if (sidebarPosition == SidebarPosition.right ||
//                     (sidebarPosition == SidebarPosition.bottom &&
//                         orderPanelPosition == OrderPanelPosition.left))
//                   RightOrderPanel(
//                     formattedDate: formattedDate,
//                     formattedTime: formattedTime,
//                     quantities: quantities,
//                   ),
//
//
//                 // Main Content (Table layout View)
//                 Expanded(
//                     child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Stack(children: [
//                       Wrap(
//                         spacing: 8.0,
//                         children: [
//                           FilterChipWidget(
//                             label: "Status: $_selectedUserFilter",
//                             options: const [
//                               "User1",
//                               "User2",
//                               "User3",
//                             ],
//                             selectedValue: _selectedUserFilter,
//                             onSelected: (value) {
//                               setState(() {
//                                 _selectedUserFilter = value;
//                               });
//                             },
//                           ),
//                           FilterChipWidget(
//                             label: "Status: $_selectedStatusFilter",
//                             options: const [
//                               "All",
//                               "Processing",
//                               "Completed",
//                               "On Hold",
//                               "Failed",
//                               "Pending",
//                               "Refunded",
//                               "Cancelled"
//                             ],
//                             selectedValue: _selectedStatusFilter,
//                             onSelected: (value) {
//                               setState(() {
//                                 _selectedStatusFilter = value;
//                               });
//                             },
//                           ),
//                           // FilterChip(
//                           //   label: Text("Sales Amount"),
//                           //   onSelected: (selected) {
//                           //     showMenu(
//                           //       context: context,
//                           //       position: RelativeRect.fromLTRB(100, 100, 0, 0),
//                           //       items: ["All", "₹", "\$"]
//                           //           .map((currency) => PopupMenuItem<String>(
//                           //         value: currency,
//                           //         child: Text(currency),
//                           //       ))
//                           //           .toList(),
//                           //     ).then((value) {
//                           //       if (value != null) {
//                           //         setState(() {
//                           //           _selectedCurrencyFilter = value;
//                           //         });
//                           //       }
//                           //     });
//                           //   },
//                           // ),
//                           FilterChipWidget(
//                             label: "Currency: $_selectedCurrencyFilter",
//                             options: ["All", "₹", "\$"],
//                             selectedValue: _selectedCurrencyFilter,
//                             onSelected: (value) {
//                               setState(() {
//                                 _selectedCurrencyFilter = value;
//                               });
//                             },
//                           ),
//                           Container(
//                             height: 40,
//                             padding: EdgeInsets.symmetric(horizontal: 4),
//                             //alignment: Alignment.center,
//                             child: ChoiceChip(
//                               shape:RoundedRectangleBorder(side: BorderSide(color: Colors.black),borderRadius: BorderRadius.all(Radius.circular(10.0))),
//                               visualDensity: VisualDensity.compact, // Reduces unwanted padding
//                               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//                               label: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Text(
//                                     "Select Range",
//                                     style: TextStyle(
//                                         color: isRangeFilterApplied
//                                             ? Colors.white
//                                             : Colors.black),
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Icon(
//                                     Icons.filter_list,
//                                     size: 18,
//                                     color: isRangeFilterApplied || isRangeFilterApplied
//                                         ? Colors.white
//                                         : Colors.black,
//                                   ),
//                                 ],
//                               ),
//                               showCheckmark: false,
//                               selected: isRangeFilterApplied,
//                               selectedColor: Colors.redAccent,
//                               backgroundColor: Colors.grey[200],
//                               onSelected: (selected) {
//                                 _openRangeFilterDialog();
//                               },
//                             ),
//                           ),
//                           // RangeFilter(
//                           //   label: "Sales Amount",
//                           //   minValue: _minSalesAmount,
//                           //   maxValue: _maxSalesAmount,
//                           //   initialRange: _salesAmountRange,
//                           //   onRangeChanged: _updateRange, // Use the reusable RangeFilter
//                           // ),
//                           if (_selectedStatusFilter != "All" ||
//                               _selectedCurrencyFilter != "All" ||
//                               _salesAmountRange.start > _minSalesAmount ||
//                               _salesAmountRange.end < _maxSalesAmount)
//                             IconButton(
//                               icon: Icon(Icons.clear,
//                                   color: isFilterApplied || isRangeFilterApplied
//                                       ? Colors.redAccent
//                                       : Colors.black),
//                               onPressed: _clearFilters,
//                             ),
//                         ],
//                       ),
//                     ]),
//                     const SizedBox(height: 16),
//                     Expanded(
//                       child: SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         physics: BouncingScrollPhysics(),
//                         child: SingleChildScrollView(
//                           scrollDirection: Axis.vertical,
//                           physics: BouncingScrollPhysics(),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Table Header
//                               Container(
//                                 padding: EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
//                                 decoration: BoxDecoration(
//                                   // color: Colors.blue.shade700,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   children: [
//                                     _buildSortableColumn("ID", 'id'),
//                                     _buildSortableColumn("Date", 'date'),
//                                     _buildHeaderCell("Duration"),
//                                     _buildHeaderCell("Start Time"),
//                                     _buildHeaderCell("End Time"),
//                                     _buildSortableColumn("Sales Amount", 'sales_amount' ),
//                                     _buildHeaderCell("Over/Short"),
//                                     _buildSortableColumn("Status", 'status'),
//                                     _buildHeaderCell(""),
//                                   ],
//                                 ),
//                               ),
//                               SizedBox(height: 10),
//
//                               // Data Rows
//                               ...filteredData.map((entry) => Padding(
//                                 padding: EdgeInsets.only(bottom: 8),
//                                 child: Container(
//                                   padding: EdgeInsets.symmetric(vertical: 8.0),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(12),
//                                     border: Border.all(color: Colors.grey.shade300),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.grey.withOpacity(0.2),
//                                         blurRadius: 4,
//                                         offset: Offset(0, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.start,
//                                     children: [
//                                       _buildDataCell(entry['id']!),
//                                       _buildDataCell(entry['date']!),
//                                       _buildDataCell(entry['duration']!),
//                                       _buildDataCell(entry['start_time']!),
//                                       _buildDataCell(entry['end_time']!),
//                                       _buildDataCell(entry['sales_amount']!),
//                                       _buildDataCell(entry['over_short']!),
//                                       _buildDataCell(entry['status']!),
//
//                                       // Action Buttons
//                                       // Row(
//                                       //   children: [
//                                       //     IconButton(
//                                       //       icon: Icon(Icons.edit, color: Colors.blue),
//                                       //       onPressed: () {},
//                                       //     ),
//                                       //     IconButton(
//                                       //       icon: Icon(Icons.delete, color: Colors.red),
//                                       //       onPressed: () {
//                                       //         QuickAlert.show(
//                                       //           width: 350,
//                                       //           context: context,
//                                       //           type: QuickAlertType.confirm,
//                                       //           title: "Are you sure?",
//                                       //           text: 'This action cannot be undone.',
//                                       //           confirmBtnText: 'Yes, Delete',
//                                       //           cancelBtnText: 'Cancel',
//                                       //           barrierDismissible: false,
//                                       //           confirmBtnColor: Colors.red,
//                                       //           confirmBtnTextStyle: TextStyle(fontSize: 14, color: Colors.white),
//                                       //           onConfirmBtnTap: () {
//                                       //             Navigator.of(context).pop();
//                                       //             ScaffoldMessenger.of(context).showSnackBar(
//                                       //               SnackBar(content: Text("Item deleted successfully")),
//                                       //             );
//                                       //             // CustomDialog.showInvalidCoupon(context);
//                                       //             // // bool? confirmed = await
//                                       //             // //CustomDialog.showRemoveDiscountConfirmation(context);
//                                       //             //   // if (confirmed == true) {
//                                       //             //   //   // Handle removal // remove discount
//                                       //             //   // }
//                                       //             //   // else{
//                                       //             //   //   // user cancelled.
//                                       //             //   // }
//                                       //           },
//                                       //           onCancelBtnTap: () {
//                                       //             Navigator.of(context).pop();
//                                       //           },
//                                       //         );
//                                       //       },
//                                       //     ),
//                                       //   ],
//                                       // ),
//                                     ],
//                                   ),
//                                 ),
//                               )),
//                             ],
//                           ),
//                           // DataTable(
//                           //   headingRowColor: WidgetStateColor.resolveWith(
//                           //       (states) => Colors.grey.shade200),
//                           //   columns: <DataColumn>[
//                           //     //DataColumn(label: Text('ID')),
//                           //     _buildSortableColumn('ID', 'id'),
//                           //     //DataColumn(label: Text('Date')),
//                           //     _buildSortableColumn('Date', 'date'),
//                           //     DataColumn(label: Text('Duration')),
//                           //     DataColumn(label: Text('Start Time')),
//                           //     DataColumn(label: Text('End Time')),
//                           //     //DataColumn(label: Text('Sales Amount')),
//                           //     _buildSortableColumn('Sales Amount', 'sales_amount' ),
//                           //     DataColumn(label: Text('Over/Short')),
//                           //     //DataColumn(label: Text('Status')),
//                           //     _buildSortableColumn('Status', 'status'),
//                           //     DataColumn(label: Text('')),
//                           //   ],
//                           //     Column(
//                           //       children: filteredData.map((entry) {
//                           //         return Container(
//                           //           margin: EdgeInsets.symmetric(vertical: 4), // Spacing between rows
//                           //           padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Inner padding
//                           //           decoration: BoxDecoration(
//                           //             color: Colors.white, // Row background color
//                           //             borderRadius: BorderRadius.circular(12), // Rounded corners
//                           //             border: Border.all(color: Colors.grey.shade300, width: 1), // Border styling
//                           //             boxShadow: [
//                           //               BoxShadow(
//                           //                 color: Colors.grey.shade200,
//                           //                 blurRadius: 4,
//                           //                 offset: Offset(0, 2), // Soft shadow
//                           //               ),
//                           //             ],
//                           //           ),
//                           //           child: Row(
//                           //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           //             children: [
//                           //               Expanded(child: Text(entry['id']!, textAlign: TextAlign.center)),
//                           //               Expanded(child: Text(entry['date']!, textAlign: TextAlign.center)),
//                           //               Expanded(child: Text(entry['duration']!, textAlign: TextAlign.center)),
//                           //               Expanded(child: Text(entry['start_time']!, textAlign: TextAlign.center)),
//                           //               Expanded(child: Text(entry['end_time']!, textAlign: TextAlign.center)),
//                           //               Expanded(child: Text(entry['sales_amount']!, textAlign: TextAlign.center)),
//                           //               Expanded(child: Text(entry['over_short']!, textAlign: TextAlign.center)),
//                           //               Expanded(child: Text(entry['status']!, textAlign: TextAlign.center)),
//                           //               Expanded(
//                           //                 child: Row(
//                           //                   mainAxisAlignment: MainAxisAlignment.center,
//                           //                   children: [
//                           //                     IconButton(
//                           //                       icon: Icon(Icons.edit, color: Colors.blue),
//                           //                       onPressed: () {},
//                           //                     ),
//                           //                     IconButton(
//                           //                       icon: Icon(Icons.delete, color: Colors.red),
//                           //                       onPressed: () {
//                           //                         QuickAlert.show(
//                           //                           context: context,
//                           //                           type: QuickAlertType.confirm,
//                           //                           title: "Are you sure?",
//                           //                           text: 'This action cannot be undone.',
//                           //                           confirmBtnText: 'Yes, Delete',
//                           //                           cancelBtnText: 'Cancel',
//                           //                           barrierDismissible: false,
//                           //                           confirmBtnColor: Colors.red,
//                           //                           confirmBtnTextStyle: TextStyle(fontSize: 14, color: Colors.white),
//                           //                           onConfirmBtnTap: () {
//                           //                             Navigator.of(context).pop();
//                           //                             ScaffoldMessenger.of(context).showSnackBar(
//                           //                               SnackBar(content: Text("Item deleted successfully")),
//                           //                             );
//                           //                           },
//                           //                           onCancelBtnTap: () {
//                           //                             Navigator.of(context).pop();
//                           //                           },
//                           //                         );
//                           //                       },
//                           //                     ),
//                           //                   ],
//                           //                 ),
//                           //               ),
//                           //             ],
//                           //           ),
//                           //         );
//                           //       }).toList(),
//                           //     ),
//                           // ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 )),
//
//                 // Order Panel on the Right (Conditional: Only when sidebar is left or bottom with right order panel)
//                 if (sidebarPosition != SidebarPosition.right &&
//                     !(sidebarPosition == SidebarPosition.bottom &&
//                         orderPanelPosition == OrderPanelPosition.left))
//                   RightOrderPanel(
//                     formattedDate: formattedDate,
//                     formattedTime: formattedTime,
//                     quantities: quantities,
//                   ),
//
//                 // Right Sidebar (Conditional)
//                 if (sidebarPosition == SidebarPosition.right)
//                   custom_widgets.NavigationBar(
//                     //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
//                     selectedSidebarIndex: _selectedSidebarIndex,
//                     onSidebarItemSelected: (index) {
//                       setState(() {
//                         _selectedSidebarIndex = index;
//                       });
//                     },
//                     isVertical: true, // Vertical layout for right sidebar
//                   ),
//               ],
//             ),
//           ),
//
//           // Bottom Sidebar (Conditional)
//           if (sidebarPosition == SidebarPosition.bottom)
//             custom_widgets.NavigationBar(
//               //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
//               selectedSidebarIndex: _selectedSidebarIndex,
//               onSidebarItemSelected: (index) {
//                 setState(() {
//                   _selectedSidebarIndex = index;
//                 });
//               },
//               isVertical: false, // Horizontal layout for bottom sidebar
//             ),
//         ],
//       ),
//     );
//   }
//
//   // DataColumn _buildSortableColumn(String label, String columnKey) {
//   //   return DataColumn(
//   //       label: GestureDetector(
//   //     onTap: () {
//   //       _sortData(columnKey);
//   //     },
//   //     child: Row(
//   //       mainAxisSize: MainAxisSize.min,
//   //       children: [
//   //         Text(label),
//   //         if (_sortColumn == columnKey)
//   //           Icon(
//   //             _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
//   //             color: Colors.blue, // Highlight active sorting
//   //             size: 16,
//   //           )
//   //         else
//   //           Icon(
//   //             Icons.unfold_more, // Default inactive state
//   //             color: Colors.grey,
//   //             size: 16,
//   //           )
//   //       ],
//   //     ),
//   //   ));
//   // }
//
//   _buildSortableColumn(String label, String columnKey) {
//     return SizedBox(
//       width: 120,
//       child: Padding(padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0), child: InkWell(
//         onTap: () {
//           _sortData(columnKey);
//         },
//         child: Row(
//           //mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(label,
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,),
//             if(_sortColumn == columnKey)
//               Icon(
//                 _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
//                 color: Colors.blue, // Highlight active sorting
//                 size: 16,
//               )
//             else
//               Icon(
//                 Icons.unfold_more, // Default inactive state
//                 color: Colors.grey,
//                 size: 16,
//               )
//           ],
//         ),
//       )),
//     );
//   }
//
// // Helper Functions
//   Widget _buildHeaderCell(String text) {
//     return SizedBox(
//       width: 120, // Fixed width to avoid flex issues
//       //padding: EdgeInsets.all(8),
//       //alignment: Alignment.center,
//       child: Text(
//         text,
//         style: TextStyle(
//           color: Colors.grey,
//           fontWeight: FontWeight.bold,
//           fontSize: 14,
//         ),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }
//
//   Widget _buildDataCell(String text) {
//     return SizedBox(
//         width: 120,
//         child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
//           child: Text(
//             text,
//             style: TextStyle(
//               color: Colors.black87,
//               fontSize: 14,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         )
//
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Blocs/Orders/order_bloc.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Widgets/widget_filter_chip.dart';
import '../../Widgets/widget_order_panel.dart';
import '../../Widgets/widget_range_filter.dart';
import '../../Widgets/widget_topbar.dart';
import '../../Models/Orders/get_orders_model.dart' as model; // Added prefix
import '../../Repositories/Orders/order_repository.dart';
import '../../Helper/api_response.dart';
import '../../Constants/text.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;

import 'package:quickalert/quickalert.dart';

// Enum for sidebar position
enum SidebarPosition { left, right, bottom }

// Enum for order panel position
enum OrderPanelPosition { left, right }

class OrdersScreen extends StatefulWidget { //Build #1.0.54: updated
  final int? lastSelectedIndex;

  const OrdersScreen({super.key, this.lastSelectedIndex});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late OrderBloc _orderBloc;
  List<model.OrderModel> _orders = []; // Use model.OrderModel
  int _selectedSidebarIndex = 3;
  DateTime now = DateTime.now();
  List<int> quantities = [1, 1, 1, 1];
  SidebarPosition sidebarPosition = SidebarPosition.left;
  OrderPanelPosition orderPanelPosition = OrderPanelPosition.right;
  bool isLoading = true;
  String _selectedStatusFilter = "All";
  String _selectedUserFilter = "User1";
  String _selectedOrderTypeFilter = "All";
  String _selectedPaymentMethodFilter = "All";
  late double _minSalesAmount;
  late double _maxSalesAmount;
  late RangeValues _salesAmountRange;
  String? _sortColumn;
  bool _isAscending = true;
  StreamSubscription? _fetchOrdersSubscription;
  List<String> _availableStatuses = ["All"];
  Map<String, dynamic>? _selectedOrder;
  int? _selectedOrderId;
  final OrderHelper orderHelper = OrderHelper(); // Helper instance to manage orders

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 3;
    _orderBloc = OrderBloc(OrderRepository());
    _minSalesAmount = 0.0;
    _maxSalesAmount = 10000.0; // Default max, will be updated from API
    _salesAmountRange = RangeValues(_minSalesAmount, _maxSalesAmount);

    // Initialize order fetching
    _fetchOrders();
  }

  //Build #1.0.54: added Fetch orders from API
  void _fetchOrders() {
    debugPrint("OrdersScreen: Initiating fetch orders");
    _fetchOrdersSubscription = _orderBloc.fetchOrdersStream.listen((response) {
      if (!mounted) return;

      if (response.status == Status.COMPLETED) {
        debugPrint("OrdersScreen: Successfully fetched ${response.data!.orders.length} orders");
        setState(() {
          _orders = response.data!.orders;
          isLoading = false;

          // Extract unique statuses from orders for filter
          _availableStatuses = ["All"] + _orders
              .map((order) => order.status)
              .toSet()
              .toList();

          // Update sales amount range based on API data
          if (_orders.isNotEmpty) {
            final salesValues = _orders
                .map((order) => double.tryParse(order.total) ?? 0.0)
                .toList();
            _minSalesAmount = salesValues.reduce((a, b) => a < b ? a : b);
            _maxSalesAmount = salesValues.reduce((a, b) => a > b ? a : b);
            _salesAmountRange = RangeValues(_minSalesAmount, _maxSalesAmount);
          }
        });
      } else if (response.status == Status.ERROR) {
        debugPrint("OrdersScreen: Error fetching orders - ${response.message}");
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? "Failed to fetch orders")),
        );
      }
    });

    _orderBloc.fetchOrders(allStatuses: false);
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

  // Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedStatusFilter = "All";
      _selectedUserFilter = "User1";
      _selectedPaymentMethodFilter = "All";
      _salesAmountRange = RangeValues(_minSalesAmount, _maxSalesAmount);
      debugPrint("OrdersScreen: Filters cleared");
    });
  }

  @override
  void dispose() {
    _fetchOrdersSubscription?.cancel();
    _orderBloc.dispose();
    debugPrint("OrdersScreen: Disposed");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    String formattedDate = DateFormat("EEE, MMM d' ${now.year}'").format(now);
    String formattedTime = DateFormat('hh:mm a').format(now);

    // Update filteredData where clause
    List<model.OrderModel> filteredData = _orders.where((order) {
      bool statusMatches = _selectedStatusFilter == "All" ||
          order.status == _selectedStatusFilter;
      bool paymentMethodMatches = _selectedPaymentMethodFilter == "All" ||
          order.paymentMethodTitle == _selectedPaymentMethodFilter;
      double salesAmount = _extractSalesAmount(order.total);
      bool salesAmountMatches = salesAmount >= _salesAmountRange.start &&
          salesAmount <= _salesAmountRange.end;
      return statusMatches && paymentMethodMatches && salesAmountMatches;
    }).toList();

    // Update isFilterApplied check
    bool isFilterApplied = _selectedStatusFilter != "All" ||
        _selectedPaymentMethodFilter != "All";
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
                debugPrint("OrdersScreen: Sidebar position changed to $sidebarPosition");
              });
            },
          ),
          const Divider(
            color: Colors.grey,
            thickness: 0.4,
            height: 1,
          ),

          // SizedBox(
          //   height: 10,
          // ),

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
                      // Filters
                      Wrap(
                        spacing: 8.0,
                        children: [
                          // User Filter
                          FilterChipWidget(
                            label: "User: $_selectedUserFilter",
                            options: const ["User1", "User2", "User3"],
                            selectedValue: _selectedUserFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedUserFilter = value;
                                debugPrint("OrdersScreen: User filter changed to $value");
                              });
                            },
                          ),
                          // Status Filter
                          FilterChipWidget(
                            label: "Status: $_selectedStatusFilter",
                            options: _availableStatuses,
                            selectedValue: _selectedStatusFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedStatusFilter = value;
                                debugPrint("OrdersScreen: Status filter changed to $value");
                              });
                            },
                          ),
                          // Order Type Filter
                          FilterChipWidget(
                            label: "Payment: $_selectedPaymentMethodFilter",
                            options: [
                              "All",
                              ..._orders
                                  .map((order) => order.paymentMethodTitle)
                                  .toSet()
                                  .toList()
                            ],
                            selectedValue: _selectedPaymentMethodFilter,
                            onSelected: (value) {
                              setState(() {
                                _selectedPaymentMethodFilter = value;
                                debugPrint("OrdersScreen: Payment method filter changed to $value");
                              });
                            },
                          ),
                          // Range Filter
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              shape: const RoundedRectangleBorder(
                                side: BorderSide(color: Colors.black),
                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Select Range",
                                    style: TextStyle(
                                      color: isRangeFilterApplied
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: isRangeFilterApplied
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
                          // Clear Filters
                          if (isFilterApplied || isRangeFilterApplied)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: isFilterApplied || isRangeFilterApplied
                                    ? Colors.redAccent
                                    : Colors.black,
                              ),
                              onPressed: _clearFilters,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Data Table
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
                                // Table Header
                                Container(
                                  padding: const EdgeInsets.only(left: 0.0, top: 8.0, bottom: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      _buildSortableColumn("ID", 'id'),
                                      _buildSortableColumn("Date", 'date'),
                                     // _buildHeaderCell("Duration"),
                                     //  _buildHeaderCell("Start Time"),
                                     //  _buildHeaderCell("End Time"),
                                      _buildSortableColumn("Sales Amount", 'sales_amount'),
                                    //  _buildHeaderCell("Over/Short"),
                                      _buildSortableColumn("Status", 'status'),
                                      _buildHeaderCell(""),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Data Rows
                                ...filteredData.map((order) {
                                  final date = DateTime.tryParse(order.dateCreated)?.toLocal();
                                  final formattedDate = date != null
                                      ? DateFormat('dd/MM/yyyy').format(date)
                                      : '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: GestureDetector( // Add GestureDetector for row click
                                      onTap: () => _onOrderRowSelected(order.id),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            _buildDataCell(order.id.toString()),
                                            _buildDataCell(formattedDate),
                                            // _buildDataCell('N/A'), // Duration not in API response
                                            // _buildDataCell('N/A'), // Start time not in API response
                                            // _buildDataCell('N/A'), // End time not in API response
                                            _buildDataCell('${order.currencySymbol}${order.total}'),
                                          //  _buildDataCell('N/A'), // Over/short not in API response
                                            _buildDataCell(order.status),
                                            // Add action buttons if needed
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Order Panel on the Right
                if (sidebarPosition != SidebarPosition.right &&
                    !(sidebarPosition == SidebarPosition.bottom &&
                        orderPanelPosition == OrderPanelPosition.left))
                  RightOrderPanel(
                    formattedDate: formattedDate,
                    formattedTime: formattedTime,
                    quantities: quantities,
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

  // In _OrdersScreenState, add a method to handle row selection
  void _onOrderRowSelected(int orderId) async {
    if (orderHelper.activeOrderId != orderId) {
      // Create or switch to order tab in RightOrderPanel
      await orderHelper.setActiveOrder(orderId);
      // Notify RightOrderPanel to refresh
      setState(() {});
      debugPrint("OrdersScreen: Selected order ID $orderId");
    }
  }

  // Build sortable column header
  Widget _buildSortableColumn(String label, String columnKey) {
    return SizedBox(
      width: 120,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        child: InkWell(
          onTap: () {
            _sortData(columnKey);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (_sortColumn == columnKey)
                Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.blue,
                  size: 16,
                )
              else
                const Icon(
                  Icons.unfold_more,
                  color: Colors.grey,
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
      width: 120,
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
  Widget _buildDataCell(String text) {
    return SizedBox(
      width: 120,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}