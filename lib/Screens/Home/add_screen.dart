import 'package:flutter/foundation.dart';
import 'package:pinaka_pos/Widgets/widget_tabs.dart';

import '../../Constants/text.dart';
import '../../Database/db_helper.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Helper/Extentions/nav_layout_manager.dart';
import '../../Preferences/pinaka_preferences.dart';
import '../../Widgets/widget_category_list.dart';
import '../../Widgets/widget_nested_grid_layout.dart';
import '../../Widgets/widget_order_panel.dart';
import '../../Widgets/widget_topbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;
import '../../Widgets/widget_custom_num_pad.dart';

class AddScreen extends StatefulWidget { // Build #1.0.6 - Updated Horizontal & Vertical Scrolling
  final int? lastSelectedIndex; // Make it nullable
  int selectedTabIndex = 0;
  String barcode = "";
  AddScreen({super.key, this.lastSelectedIndex, this.selectedTabIndex = 0, this.barcode = "",}); // Optional, no default value


  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> with LayoutSelectionMixin {
  final List<String> items = List.generate(18, (index) => 'Bud Light');
  int _selectedSidebarIndex = 2; //Build #1.0.2 : By default fast key should be selected after login
  DateTime now = DateTime.now();
  List<int> quantities = [1, 1, 1, 1];
  final ValueNotifier<int?> fastKeyTabIdNotifier = ValueNotifier<int?>(null); // Add this
  final PinakaPreferences _preferences = PinakaPreferences(); //Build #1.0.84: Added this
  final OrderHelper orderHelper = OrderHelper();

  @override
  void initState() {
    super.initState();
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 2; // Build #1.0.7: Restore previous selection
  }

  void _refreshOrderList() { // Build #1.0.10 - Naveen: This will trigger a rebuild of the RightOrderPanel (Callback)
    setState(() {
      if (kDebugMode) {
        print("###### CategoriesScreen _refreshOrderList");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    String formattedDate = DateFormat("EEE, MMM d' ${now.year}'").format(now);
    String formattedTime = DateFormat('hh:mm a').format(now);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            TopBar(
              screen: Screen.ADD,
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

                //Update the notifier which will trigger _onLayoutChanged
                PinakaPreferences.layoutSelectionNotifier.value = newLayout;
                // No need to call saveLayoutSelection here as it's handled in the notifier
               // _preferences.saveLayoutSelection(newLayout);
                //Build #1.0.122: update layout mode change selection to DB
                await UserDbHelper().saveUserSettings({AppDBConst.layoutSelection: newLayout}, modeChange: true);
              });
            },
            onProductSelected: (product) async { //Build #1.0.126: Missed code added
                if (kDebugMode) print("#### AddScreen onProductSelected");
                double price;
                try {
                  price = double.tryParse(product.price ?? '0.00') ?? 0.00;
                } catch (e) {
                  price = 0.00;
                }

                final serverOrderId = orderHelper.activeOrderId;
                final dbOrderId = orderHelper.activeOrderId;
                ///Build #1.0.128: No need to check this condition
                // if (dbOrderId == null) {
                //   if (kDebugMode) print("No active order selected");
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     const SnackBar(
                //       content: Text("No active order selected"),
                //       backgroundColor: Colors.red,
                //       duration: Duration(seconds: 2),
                //     ),
                //   );
                //   return;
                // }

                try {
                //  if (serverOrderId != null) { ///Build #1.0.128: No need to check this condition
                    if (kDebugMode) print("#### AddScreen serverOrderId");
                    _refreshOrderList();
                  // } else {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(
                  //       content: Text("Item '${product.name}' did not added to order. OrderId not found."),
                  //       backgroundColor: Colors.green,
                  //       duration: const Duration(seconds: 2),
                  //     ),
                  //   );
                  //   _refreshOrderList();
                  // }
                } catch (e, s) {
                  if (kDebugMode) print("Exception in onProductSelected: $e, Stack: $s");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error adding item"),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
          ),
          Divider(
            color: Colors.grey, // Light grey color
            thickness: 0.4, // Very thin line
            height: 1, // Minimal height
          ),
          // Main Content
          Expanded(
            child: Row(
              children: [
                // Left Sidebar (Conditional)
                if (sidebarPosition == SidebarPosition.left)
                  custom_widgets.NavigationBar( //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
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
                      (sidebarPosition == SidebarPosition.bottom && orderPanelPosition == OrderPanelPosition.left))
                    RightOrderPanel(
                      formattedDate: formattedDate,
                      formattedTime: formattedTime,
                      quantities: quantities,
                      refreshOrderList: _refreshOrderList, // Pass the callback
                    ),

                  Expanded(child: AppScreenTabWidget(selectedTabIndex: widget.selectedTabIndex,barcode: widget.barcode, scaffoldMessengerContext: context, refreshOrderList: _refreshOrderList)), // Build #1.0.53

                  // Order Panel on the Right (Conditional: Only when sidebar is left or bottom with right order panel)
                  if (sidebarPosition != SidebarPosition.right &&
                      !(sidebarPosition == SidebarPosition.bottom && orderPanelPosition == OrderPanelPosition.left))
                    RightOrderPanel(
                      formattedDate: formattedDate,
                      formattedTime: formattedTime,
                      quantities: quantities,
                      refreshOrderList: _refreshOrderList, // Pass the callback
                    ),

                  // Right Sidebar (Conditional)
                  if (sidebarPosition == SidebarPosition.right)
                    custom_widgets.NavigationBar( //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
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
              custom_widgets.NavigationBar( //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
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
      ),
    );
  }

}

