import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_pos/Screens/Home/shift_open_close_balance.dart';

import '../../Widgets/widget_topbar.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;

enum SidebarPosition { left, right, bottom }

// Enum for order panel position
enum OrderPanelPosition { left, right }

class ShiftHistoryDashboardScreen extends StatefulWidget {
  final int? lastSelectedIndex; // Make it nullable
  const ShiftHistoryDashboardScreen({super.key, this.lastSelectedIndex});

  @override
  State<ShiftHistoryDashboardScreen> createState() => _ShiftHistoryDashboardScreenState();
}

class _ShiftHistoryDashboardScreenState extends State<ShiftHistoryDashboardScreen> {
  int _selectedSidebarIndex = 4;
  SidebarPosition sidebarPosition = SidebarPosition.left; // Default to bottom sidebar

  // Sample data for shift history
  final List<Map<String, dynamic>> shiftHistoryData = [
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'startTime': '12:00:00',
      'endTime': '08:00:00',
      'salesAmount': '\$350',
      'overShort': '-\$60',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'startTime': '12:00:00',
      'endTime': '08:00:00',
      'salesAmount': '\$350',
      'overShort': '-\$60',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'startTime': '12:00:00',
      'endTime': '08:00:00',
      'salesAmount': '\$350',
      'overShort': '-\$60',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'startTime': '12:00:00',
      'endTime': '08:00:00',
      'salesAmount': '\$350',
      'overShort': '-\$60',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'startTime': '12:00:00',
      'endTime': '08:00:00',
      'salesAmount': '\$350',
      'overShort': '-\$60',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'startTime': '12:00:00',
      'endTime': '08:00:00',
      'salesAmount': '\$350',
      'overShort': '-\$60',
    },
    {
      'date': '28/10/2023',
      'duration': '8:00:00',
      'startTime': '12:00:00',
      'endTime': '08:00:00',
      'salesAmount': '\$350',
      'overShort': '-\$60',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 4;
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
                    child: _buildShiftHistoryContent(),
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
          ]
        // Top Bar
      ),
    );
  }

  Widget _buildShiftHistoryContent() {
    return Column(
      children: [
        // Header with back button and Add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            Container(
              margin: EdgeInsets.only(left: 10.0),
              width: MediaQuery.of(context).size.width * 0.025,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 15,
                ),
              ),
            ),
            // Spacer(),
            // Add button
            Container(
              margin: EdgeInsets.only(right: 16.0),
              width: MediaQuery.of(context).size.width * 0.075,
              height: MediaQuery.of(context).size.height * 0.05,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.black),
              ),
              child: TextButton.icon(
                onPressed: () {
                  // Handle add shift action
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (context) => ShiftOpenCloseBalanceScreen()
                  )
                  );
                },
                icon: Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 14,
                  weight: 10,
                ),
                label: Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 5),
                ),
              ),
            ),
          ],
        ),

        // Data table
        Expanded(
          child: Container(
            margin: EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 4,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Duration',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Start Time',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'End Time',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Sales Amount',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Over/Short',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: SizedBox(), // For action buttons space
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  height: 1,
                  color: Colors.grey.shade300,
                ),

                // Table rows
                Expanded(
                  child: ListView.builder(
                    itemCount: shiftHistoryData.length,
                    itemBuilder: (context, index) {
                      final shift = shiftHistoryData[index];
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,style: BorderStyle.solid

                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                shift['date'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                shift['duration'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                shift['startTime'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                shift['endTime'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                shift['salesAmount'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                shift['overShort'],
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit button
                                  InkWell(
                                    onTap: () {
                                      // Handle edit action
                                      print('Edit shift at index $index');
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // Delete button
                                  InkWell(
                                    onTap: () {
                                      // Handle delete action
                                      _showDeleteConfirmation(index);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Shift'),
          content: Text('Are you sure you want to delete this shift record?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  shiftHistoryData.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}