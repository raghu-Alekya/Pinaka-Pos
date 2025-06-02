import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Screens/Home/safe_open_screen.dart';
import '../../Widgets/widget_custom_num_pad.dart';
import '../../Widgets/widget_topbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;


// Enum for sidebar position
enum SidebarPosition { left, right, bottom }

// Enum for order panel position
enum OrderPanelPosition { left, right }

class ShiftOpenCloseBalanceScreen extends StatefulWidget {
  final int? lastSelectedIndex;
  const ShiftOpenCloseBalanceScreen(
      {super.key, this.lastSelectedIndex});

  @override
  State<ShiftOpenCloseBalanceScreen> createState() => _ShiftOpenCloseBalanceScreenState();
}

class _ShiftOpenCloseBalanceScreenState extends State<ShiftOpenCloseBalanceScreen> {

  SidebarPosition sidebarPosition =
      SidebarPosition.left; // Default to bottom sidebar
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

    // Add listeners to update totals when text changes
    _note100Controller.addListener(() => _updateTotal('100', _note100Controller));
    _note50Controller.addListener(() => _updateTotal('50', _note50Controller));
    _note20Controller.addListener(() => _updateTotal('20', _note20Controller));
    _note10Controller.addListener(() => _updateTotal('10', _note10Controller));
    _note5Controller.addListener(() => _updateTotal('5', _note5Controller));
    _note2Controller.addListener(() => _updateTotal('2', _note2Controller));
    _note1Controller.addListener(() => _updateTotal('1', _note1Controller));

    // Add listeners to update totals when text changes - Coins
    _coin50Controller.addListener(() => _updateCoinTotal('0.50', _coin50Controller));
    _coin25Controller.addListener(() => _updateCoinTotal('0.25', _coin25Controller));
    _coin10Controller.addListener(() => _updateCoinTotal('0.10', _coin10Controller));
    _coin5Controller.addListener(() => _updateCoinTotal('0.05', _coin5Controller));

  }

  final TextEditingController _note100Controller = TextEditingController();
  final TextEditingController _note50Controller = TextEditingController();
  final TextEditingController _note20Controller = TextEditingController();
  final TextEditingController _note10Controller = TextEditingController();
  final TextEditingController _note5Controller = TextEditingController();
  final TextEditingController _note2Controller = TextEditingController();
  final TextEditingController _note1Controller = TextEditingController();

  // Coin Controllers
  final TextEditingController _coin50Controller = TextEditingController();
  final TextEditingController _coin25Controller = TextEditingController();
  final TextEditingController _coin10Controller = TextEditingController();
  final TextEditingController _coin5Controller = TextEditingController();


  // Maps to hold note values and their corresponding totals
  final Map<String, double> _noteDenominations = {
    '100': 100.0,
    '50': 50.0,
    '20': 20.0,
    '10': 10.0,
    '5': 5.0,
    '2': 2.0,
    '1': 1.0,
  };

  final Map<String, double> _noteTotals = {
    '100': 0.0,
    '50': 0.0,
    '20': 0.0,
    '10': 0.0,
    '5': 0.0,
    '2': 0.0,
    '1': 0.0,
  };

  // Maps to hold coin values and their corresponding totals
  final Map<String, double> _coinDenominations = {
    '0.50': 0.50,
    '0.25': 0.25,
    '0.10': 0.10,
    '0.05': 0.05,
  };

  final Map<String, double> _coinTotals = {
    '0.50': 0.0,
    '0.25': 0.0,
    '0.10': 0.0,
    '0.05': 0.0,
  };

  double _grandTotal = 0.0;

  void _updateTotal(String denomination, TextEditingController controller) {
    setState(() {
      int count = int.tryParse(controller.text) ?? 0;
      _noteTotals[denomination] = count * _noteDenominations[denomination]!;
      _calculateGrandTotal();
    });
  }

  void _updateCoinTotal(String denomination, TextEditingController controller) {
    setState(() {
      int count = int.tryParse(controller.text) ?? 0;
      _coinTotals[denomination] = count * _coinDenominations[denomination]!;
      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    double noteTotal = _noteTotals.values.reduce((a, b) => a + b);
    double coinTotal = _coinTotals.values.reduce((a, b) => a + b);
    _grandTotal = noteTotal + coinTotal;
    //_grandTotal = _noteTotals.values.reduce((a, b) => a + b);
  }

  void _clearCounts() {
    _note100Controller.clear();
    _note50Controller.clear();
    _note20Controller.clear();
    _note10Controller.clear();
    _note5Controller.clear();
    _note2Controller.clear();
    _note1Controller.clear();

    // Clear coin controllers
    _coin50Controller.clear();
    _coin25Controller.clear();
    _coin10Controller.clear();
    _coin5Controller.clear();

    setState(() {
      _noteTotals.updateAll((key, value) => 0.0);
      _coinTotals.updateAll((key, value) => 0.0);
      _grandTotal = 0.0;
    });
  }

  TextEditingController _getControllerForDenomination(String denomination) {
    switch(denomination) {
      case '100': return _note100Controller;
      case '50': return _note50Controller;
      case '20': return _note20Controller;
      case '10': return _note10Controller;
      case '5': return _note5Controller;
      case '2': return _note2Controller;
      case '1': return _note1Controller;
      default: throw Exception('Invalid denomination');
    }
  }

  TextEditingController _getControllerForCoinDenomination(String denomination) {
    switch(denomination) {
      case '0.50': return _coin50Controller;
      case '0.25': return _coin25Controller;
      case '0.10': return _coin10Controller;
      case '0.05': return _coin5Controller;
      default: throw Exception('Invalid coin denomination');
    }
  }

  String _getCoinAssetPath(String denomination) {
    switch(denomination) {
      case '0.50': return 'assets/svg/50_cents.svg';
      case '0.25': return 'assets/svg/25_cents.svg';
      case '0.10': return 'assets/svg/10_cents.svg';
      case '0.05': return 'assets/svg/5_cents.svg';
      default: return 'assets/svg/50_cents.svg';
    }
  }

  @override
  void dispose() {
    _note100Controller.dispose();
    _note50Controller.dispose();
    _note20Controller.dispose();
    _note10Controller.dispose();
    _note5Controller.dispose();
    _note2Controller.dispose();
    _note1Controller.dispose();
    super.dispose();
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
                      padding: EdgeInsets.fromLTRB(8, 12, 12, 12),
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16,right: 16,left: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Shift Opening/ Closing - Balance',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      // const SizedBox(height: 4),
                                      const Text(
                                        'Count and record drawer cash to begin / close your shift.',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  // Bottom buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.06,
                                        width: MediaQuery.of(context).size.width * 0.1,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            // Back button action
                                            Navigator.pop(context);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            side: BorderSide(color: Colors.grey.shade300),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Back', style: TextStyle(color: Colors.blueGrey, fontSize: 14),),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.06,
                                        width: MediaQuery.of(context).size.width * 0.1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Next button action
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => SafeOpenScreen(),));
                                            // Implement your next step logic here
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFFFF6B6B),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Next',style: TextStyle(fontSize: 16),),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(left: 16, right: 8),
                                  padding: EdgeInsets.all(8),
                                  width: MediaQuery.of(context).size.width * 0.425,
                                  height: MediaQuery.of(context).size.height * 0.7,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Colors.grey.shade100,
                                    boxShadow:[
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 2,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 0),
                                    ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Notes',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),

                                      // Table headers
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Type',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              'No. of Notes',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              'Total Amount',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        color: Colors.grey.shade300,
                                      ),

                                      // Note rows
                                      Expanded(
                                        child: ListView(
                                          children: _noteDenominations.keys.map((denomination) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 7.0),
                                              child: Row(
                                                children: [
                                                  // Denomination type
                                                  SvgPicture.asset(
                                                    'assets/svg/$denomination.svg',
                                                    height: 24,
                                                    width: 24,
                                                  ),
                                                  // Multiply symbol
                                                  const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                                                    child: Text(
                                                      '×',
                                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.grey),
                                                    ),
                                                  ),
                                                  // Note count input
                                                  Container(
                                                    height: MediaQuery.of(context).size.height * 0.06,
                                                    width: MediaQuery.of(context).size.width * 0.15,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.rectangle,
                                                        border: Border.all(color: Colors.grey.shade300),
                                                        borderRadius: BorderRadius.circular(5),
                                                        color: Colors.white
                                                    ),
                                                    child: TextField(
                                                      controller: _getControllerForDenomination(denomination),
                                                      keyboardType: TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.digitsOnly,
                                                      ],
                                                      decoration: const InputDecoration(
                                                        hintText: '0',hintStyle: TextStyle(color: Colors.grey),
                                                        border: InputBorder.none,
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 9.0),
                                                      ),
                                                    ),
                                                  ),
                                                  const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 12.0), // Equals symbol
                                                    child: Text(
                                                      '=',
                                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                                                    ),
                                                  ),
                                                  // Total amount
                                                  Container(
                                                    height: MediaQuery.of(context).size.height * 0.06,
                                                    width: MediaQuery.of(context).size.width * 0.15,
                                                    alignment: Alignment.centerRight,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.grey.shade400),
                                                      borderRadius: BorderRadius.circular(4),
                                                      color: Colors.grey.shade300,
                                                    ),
                                                    child: Text(
                                                      '\$${_noteTotals[denomination]!.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Coins Container and Total Section
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Coins Container
                                    Container(
                                      margin: EdgeInsets.only(left: 16, right: 8),
                                      padding: EdgeInsets.all(8),
                                      width: MediaQuery.of(context).size.width * 0.425,
                                      height: MediaQuery.of(context).size.height * 0.54,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: Colors.grey.shade100,
                                        boxShadow:[
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 2,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Coins',
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 5),

                                          // Table headers
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            // crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                flex:2,
                                                child: Text(
                                                  'Type',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  'No. of Coins',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  'Total Amount',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(
                                            color: Colors.grey.shade300,
                                          ),

                                          // Coin rows
                                          Expanded(
                                            child: ListView(
                                              children: _coinDenominations.keys.map((denomination) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 7.0),
                                                  child: Row(
                                                    children: [
                                                      // Denomination type
                                                      SvgPicture.asset(
                                                        _getCoinAssetPath(denomination),
                                                        // 'assets/svg/$denomination.svg',
                                                        height: 30,
                                                        width: 30,
                                                      ),
                                                      // Multiply symbol
                                                      const Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                                                        child: Text(
                                                          '×',
                                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.grey),
                                                        ),
                                                      ),
                                                      // Coin count input
                                                      Container(
                                                        height: MediaQuery.of(context).size.height * 0.06,
                                                        width: MediaQuery.of(context).size.width * 0.15,
                                                        decoration: BoxDecoration(
                                                            shape: BoxShape.rectangle,
                                                            border: Border.all(color: Colors.grey.shade300),
                                                            borderRadius: BorderRadius.circular(5),
                                                            color: Colors.white
                                                        ),
                                                        child: TextField(
                                                          controller: _getControllerForCoinDenomination(denomination),
                                                          keyboardType: TextInputType.none,
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter.digitsOnly,
                                                          ],
                                                          decoration: const InputDecoration(
                                                            hintText: '0', hintStyle: TextStyle(color: Colors.grey),
                                                            border: InputBorder.none,
                                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 9.0),
                                                          ),
                                                        ),
                                                      ),
                                                      const Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: 12.0), // Equals symbol
                                                        child: Text(
                                                          '=',
                                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                                                        ),
                                                      ),
                                                      // Total amount
                                                      Container(
                                                        height: MediaQuery.of(context).size.height * 0.06,
                                                        width: MediaQuery.of(context).size.width * 0.15,
                                                        alignment: Alignment.centerRight,
                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Colors.grey.shade400),
                                                          borderRadius: BorderRadius.circular(4),
                                                          color: Colors.grey.shade300,
                                                        ),
                                                        child: Text(
                                                          '\$${_coinTotals[denomination]!.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.grey,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    TextButton(
                                      onPressed: _clearCounts,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.grey), //  Border added
                                        // padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('CLEAR COUNTS'),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          'Total Amount: ',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          height: MediaQuery.of(context).size.height * 0.06,
                                          width: MediaQuery.of(context).size.width * 0.25,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '\$${_grandTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    )
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
