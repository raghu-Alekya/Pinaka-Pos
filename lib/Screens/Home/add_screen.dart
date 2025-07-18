import 'package:flutter/foundation.dart';
import 'package:pinaka_pos/Widgets/widget_tabs.dart';

import '../../Constants/text.dart';
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
      body: Column(
        children: [
          // Top Bar
          TopBar(
            screen: Screen.ADD,
            onModeChanged: () { //Build #1.0.84: Issue fixed: nav mode re-setting
              String newLayout;
              setState(() {
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
                _preferences.saveLayoutSelection(newLayout);
              });
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
    );
  }

}

