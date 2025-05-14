import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';
import '../../Widgets/widget_custom_num_pad.dart';
import '../../Widgets/widget_topbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;

// Enum for sidebar position
enum SidebarPosition { left, right, bottom }

// Enum for order panel position
enum OrderPanelPosition { left, right }

class NotesManagerScreen extends StatefulWidget {
  final int? lastSelectedIndex;
  const NotesManagerScreen(
      {super.key, this.lastSelectedIndex});

  @override
  State<NotesManagerScreen> createState() => _NotesManagerScreenState();
}

class _NotesManagerScreenState extends State<NotesManagerScreen> {

  SidebarPosition sidebarPosition =
      SidebarPosition.left; // Default to bottom sidebar
  bool isLoading = true;
  int _selectedSidebarIndex = 4;

  final TextEditingController _totalNotesController = TextEditingController();
  final TextEditingController _totalCashController = TextEditingController();

  // Controllers for each denomination
  final TextEditingController _fiftyCountController = TextEditingController();
  final TextEditingController _twentyCountController = TextEditingController();
  final TextEditingController _tenCountController = TextEditingController();
  final TextEditingController _fiveCountController = TextEditingController();
  final TextEditingController _twoCountController = TextEditingController();
  final TextEditingController _oneCountController = TextEditingController();

  // Track the currently selected text field
  TextEditingController? _activeController;

  // To track totals
  int totalNotes = 0;
  double totalCash = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.lastSelectedIndex ??
        4; // Build #1.0.7: Restore previous selection

    // Simulate a loading delay
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isLoading = false; // Set loading to false after 3 seconds
      });
    });

    // Initialize controllers with zeros
    _fiftyCountController.text = "0";
    _twentyCountController.text = "0";
    _tenCountController.text = "0";
    _fiveCountController.text = "0";
    _twoCountController.text = "0";
    _oneCountController.text = "0";
    _totalNotesController.text = "0";
    _totalCashController.text = "\$0.00";
  }

  @override
  void dispose() {
    // Dispose of controllers to prevent memory leaks
    _fiftyCountController.dispose();
    _twentyCountController.dispose();
    _tenCountController.dispose();
    _fiveCountController.dispose();
    _twoCountController.dispose();
    _oneCountController.dispose();
    _totalNotesController.dispose();
    _totalCashController.dispose();
    super.dispose();
  }

  // Calculate totals based on current values
  void _calculateTotals() {
    double fiftyCount = double.tryParse(_fiftyCountController.text) ?? 0;
    double twentyCount = double.tryParse(_twentyCountController.text) ?? 0;
    double tenCount = double.tryParse(_tenCountController.text) ?? 0;
    double fiveCount = double.tryParse(_fiveCountController.text) ?? 0;
    double twoCount = double.tryParse(_twoCountController.text) ?? 0;
    double oneCount = double.tryParse(_oneCountController.text) ?? 0;

    // Handle potential decimal inputs by rounding when calculating total notes
    totalNotes = fiftyCount.round() + twentyCount.round() + tenCount.round() +
        fiveCount.round() + twoCount.round() + oneCount.round();

    totalCash = (fiftyCount * 50) + (twentyCount * 20) + (tenCount * 10) +
        (fiveCount * 5) + (twoCount * 2) + (oneCount * 1.0);

    setState(() {
      _totalNotesController.text = totalNotes.toString();
      _totalCashController.text = "\${totalCash.toStringAsFixed(2)}";
    });
  }

  // Handle numeric input
  void _handleNumberPress(String value) {
    if (_activeController != null) {
      String currentText = _activeController!.text;
      // Handle special cases for the CustomNumPad
      if (value == "." && currentText.contains(".")) {
        // Don't allow multiple decimal points
        return;
      } else if (value == "00") {
        // Special case for "00"
        if (currentText == "0") {
          _activeController!.text = "0";
        } else {
          _activeController!.text = currentText + "00";
        }
      } else if (currentText == "0" && value != ".") {
        // Replace leading zero, unless adding decimal
        _activeController!.text = value;
      } else {
        // Normal case: append the value
        _activeController!.text = currentText + value;
      }
      _calculateTotals();
    }
  }

  // Clear the active field
  void _handleClear() {
    if (_activeController != null) {
      _activeController!.text = "0";
      _calculateTotals();
    }
  }

  // Handle add button press
  void _handleAdd() {
    // You can implement save functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cash count saved')),
    );
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
          SizedBox(
            height: 10,
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const Text("back", style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            Row(
                              children: [
                                _buildDenominationField(50, _fiftyCountController),
                                _buildDenominationField(5, _fiveCountController),
                              ],
                            ),
                            Row(
                              children: [
                                _buildDenominationField(20, _twentyCountController),
                                _buildDenominationField(2, _twoCountController),
                              ],
                            ),
                            Row(
                              children: [
                                _buildDenominationField(10, _tenCountController),
                                _buildDenominationField(1, _oneCountController),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Total Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _totalNotesController,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                  //const SizedBox(height: 20),
                                  const Text("Total Cash", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _totalCashController,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: CustomNumPad(
                              onDigitPressed: _handleNumberPress,
                              onClearPressed: _handleClear,
                              onAddPressed: _handleAdd,
                              actionButtonType: ActionButtonType.add,
                            ),
                          ),
                        ],
                      ),
                    ],
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


  Widget _buildDenominationField(int denominationValue, TextEditingController controller, {bool isResult = false}) {
    // int denominationValue = int.tryParse(denomination.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            //Container(
              // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              // decoration: BoxDecoration(
              //   color: const Color(0xFFD8E8DE),
              //   borderRadius: const BorderRadius.only(
              //     topLeft: Radius.circular(7),
              //     bottomLeft: Radius.circular(7),
              //   ),
              // ),
              //child:
              SvgPicture.asset(
                'assets/icons/$denominationValue.svg',
                width: 24,
                height: 24,
                // color: const Color(0xFF64A67C), // Optional: applies tint
              ),
            //),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('×', style: TextStyle(fontSize: 18)),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.none,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                readOnly: isResult,
                onTap: isResult
                    ? null
                    : () {
                  setState(() {
                    _activeController = controller;
                  });
                },
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('=', style: TextStyle(fontSize: 18)),
            ),
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isResult
                    ? controller.text
                    : '\$${((double.tryParse(controller.text) ?? 0) * denominationValue).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}