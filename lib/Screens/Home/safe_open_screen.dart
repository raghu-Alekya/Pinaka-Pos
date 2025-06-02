import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Widgets/widget_alert_popup_dialogs.dart';
import '../../Widgets/widget_topbar.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;

// Enum for sidebar position
enum SidebarPosition { left, right, bottom }

// Enum for order panel position
enum OrderPanelPosition { left, right }

class SafeOpenScreen extends StatefulWidget {
  final int? lastSelectedIndex;
  const SafeOpenScreen({super.key, this.lastSelectedIndex});

  @override
  State<SafeOpenScreen> createState() => _SafeOpenScreenState();
}

class _SafeOpenScreenState extends State<SafeOpenScreen> {
  // List of denominations and their respective colors
  final List<Map<String, dynamic>> denominations = [
    {'value': '\$100', 'color': Color(0xFFAAD576), 'tubeCount': 0, 'amount': 0.0},
    {'value': '\$50', 'color': Color(0xFFA8D1B9), 'tubeCount': 0, 'amount': 0.0},
    {'value': '\$20', 'color': Color(0xFF5ECEC6), 'tubeCount': 0, 'amount': 0.0},
    {'value': '\$10', 'color': Color(0xFFBFE0D9), 'tubeCount': 0, 'amount': 0.0},
    {'value': '\$5', 'color': Color(0xFFCCE3C3), 'tubeCount': 0, 'amount': 0.0},
    {'value': '\$2', 'color': Color(0xFF9CC5A1), 'tubeCount': 0, 'amount': 0.0},
    {'value': '\$1', 'color': Color(0xFF5ECEC6), 'tubeCount': 0, 'amount': 0.0},
  ];

  double totalAmount = 0.0;
  double cashTubes = 0.0;
  double cashNotesCoin = 0.0; // Sample initial value as shown in the screenshot

  void updateAmounts() {
    double calculatedTotalAmount = 0.0;
    double calculatedCashTubes = 0.0;

    for (var denomination in denominations) {
      // Extract numeric value from denomination (removing '$' and converting to double)
      double value = double.parse(denomination['value'].substring(1));
      denomination['amount'] = value * denomination['tubeCount'];
      calculatedTotalAmount += denomination['amount'];
      calculatedCashTubes += denomination['amount'];
    }

    setState(() {
      totalAmount = calculatedTotalAmount;
      cashTubes = calculatedCashTubes;
    });
  }

  SidebarPosition sidebarPosition = SidebarPosition.left; // Default to bottom sidebar
  bool isLoading = true;
  int _selectedSidebarIndex = 4;

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 4; // Build #1.0.7: Restore previous selection

    // Simulate a loading delay
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isLoading = false; // Set loading to false after 3 seconds
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
          Expanded(
            child: Row(
              children: [
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

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                    child: Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16,right: 16,left: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Safe',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.06,
                                      width: MediaQuery.of(context).size.width * 0.1,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade300),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Back', style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.06,
                                      width: MediaQuery.of(context).size.width * 0.1,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // // bool? result =
                                          // CustomDialog.showStartShiftVerification(
                                          //   context,
                                          //   totalAmount: 370.00,
                                          //   overAmount: 10// optional
                                          // );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF6B6B),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Submit', style: TextStyle(fontSize: 16),),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      // Money columns
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: List.generate(
                                            denominations.length,
                                                (index) => MoneyColumn(
                                              denomination: denominations[index]['value'],
                                              color: denominations[index]['color'],
                                              tubeCount: denominations[index]['tubeCount'],
                                              onChanged: (value) {
                                                setState(() {
                                                  denominations[index]['tubeCount'] = value;
                                                });
                                                updateAmounts();
                                              },
                                              amount: denominations[index]['amount'],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Bottom labels section - shown only once
                                      // Bottom input section - labels in separate rows
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Left label column
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 35,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      'No Of Tubes',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey.shade700,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  height: 35,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                      'Amount',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey.shade700,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 16),
                                            // Right input columns
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Row of dropdowns
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                    children: List.generate(
                                                      denominations.length,
                                                      (index) => Container(
                                                        width: 70,
                                                        height: 35,
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Colors.grey.shade300),
                                                          borderRadius: BorderRadius.circular(5),
                                                        ),
                                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                                        child: DropdownButtonHideUnderline(
                                                          child: DropdownButton<int>(
                                                            value: denominations[index]['tubeCount'],
                                                            onChanged: (value) {
                                                              setState(() {
                                                                denominations[index]['tubeCount'] = value ?? 0;
                                                              });
                                                              updateAmounts();
                                                            },
                                                            items: List.generate(11, (i) => i).map((value) {
                                                              return DropdownMenuItem<int>(
                                                                value: value,
                                                                child: Text(
                                                                  value.toString().padLeft(2, '0'),
                                                                  style: TextStyle(fontWeight: FontWeight.w500),
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // Row of amount boxes
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                    children: List.generate(
                                                      denominations.length,
                                                      (index) => Container(
                                                        width: 70,
                                                        height: 35,
                                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Colors.grey.shade300),
                                                          borderRadius: BorderRadius.circular(5),
                                                        ),
                                                        child: Text(
                                                          '\$${denominations[index]['amount'].toStringAsFixed(0)}',
                                                          style: TextStyle(fontWeight: FontWeight.w500),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Right side summary section
                                Expanded(
                                  flex: 2,
                                  child: Column(spacing: 10,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Total Columns
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.3,
                                        padding: EdgeInsets.all(10),
                                        margin: EdgeInsets.all(20) ,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Total Columns',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '07',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Cash (Tubes)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Cash',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '(Tubes)',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    const Text(
                                                      ' : ',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        'Total Amount of money in the form of notes and coins from tubes.',
                                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            margin: EdgeInsets.all(8.0),
                                            width: MediaQuery.of(context).size.width * 0.125,
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '\$${cashTubes.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Cash (Notes/coins)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Cash',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '(Notes/coins)',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    const Text(
                                                      ' : ',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        'Total Amount of Physical money in the form of notes and coins',
                                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            margin: EdgeInsets.all(8.0),
                                            width: MediaQuery.of(context).size.width * 0.125,
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '\$${cashNotesCoin.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.blue.shade300,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Total Amount
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Total Amount',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Text(
                                                  ' : ',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            margin: EdgeInsets.all(8.0),
                                            width: MediaQuery.of(context).size.width * 0.125,
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '\$${totalAmount.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
}

class MoneyColumn extends StatelessWidget {
  final String denomination;
  final Color color;
  final int tubeCount;
  final Function(int) onChanged;
  final double amount;

  const MoneyColumn({
    Key? key,
    required this.denomination,
    required this.color,
    required this.tubeCount,
    required this.onChanged,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Denomination label
        Text(
          denomination,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Money tube container
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 50,
            height: 300,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Tube background
                Container(
                  width: 50,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300, width: 1),
                      right: BorderSide(color: Colors.grey.shade300, width: 1),
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                ),

                // Filled part of tube
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  child: Container(
                    width: 46, // Reduced width for padding effect
                    height: tubeCount > 0 ? (296 * (tubeCount / 10)).clamp(30.0, 296.0) : 0, // Reduced height for padding
                    color: color,
                    //margin: EdgeInsets.only(bottom: 2, left: 2, right: 2), // Add margin for padding effect
                  ),
                ),

                // Tube content - bills visualization
                if (tubeCount > 0)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 46,
                      height: (296 * (tubeCount / 10)).clamp(30.0, 296.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          tubeCount - 1,
                              (index) => Container(
                            height: 1,
                            width: 38, // Reduced width for padding
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}