import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_pos/Screens/Home/apps_dashboard_screen.dart';
import 'package:pinaka_pos/Screens/Home/categories_screen.dart';
import 'package:pinaka_pos/Screens/Home/fast_key_screen.dart';
import 'package:pinaka_pos/Screens/Home/orders_screen.dart';
import 'package:quickalert/models/quickalert_animtype.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

import '../Constants/text.dart';
import '../Screens/Home/add_screen.dart';
import '../Screens/Home/Settings/settings_screen.dart';

class NavigationBar extends StatelessWidget {
  final int selectedSidebarIndex;
  final Function(int) onSidebarItemSelected;
  final bool isVertical;

  const NavigationBar({
    required this.selectedSidebarIndex,
    required this.onSidebarItemSelected,
    this.isVertical = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Build #1.0.6 - Added theme for navigation bar
    return Container(
      width: isVertical ? MediaQuery.of(context).size.width * 0.07 : null,
      height: isVertical ? null : 100,
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: isVertical ? _buildVerticalLayout() : _buildHorizontalLayout(),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    int lastSelectedIndex = 0; // Store last selected index before opening Settings

    return LayoutBuilder( //Build #1.0.2 : updated the code for this fix - RenderFlex overflowed by 42 pixels on the bottom
      builder: (context, constraints) {
           if (kDebugMode) {
              print("#### _buildVerticalLayout constraints: $constraints");
           }
        // Dynamic items (scrollable if needed)
        List<Widget> dynamicItems = [
          SidebarButton(
            icon: Icons.flash_on,
            label: TextConstants.fastKeyText,
            isSelected: selectedSidebarIndex == 0,
            onTap: () { // Build #1.0.6
              if (kDebugMode) {
                print("##### Fast Keys button tapped");
              }
              lastSelectedIndex = 0; // Store last selection
              onSidebarItemSelected(0);

              /// FastKeyScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FastKeyScreen(lastSelectedIndex: lastSelectedIndex)),
              );
            },
            isVertical: isVertical,
          ),
          SidebarButton(
            icon: Icons.category,
            label: TextConstants.categoriesText,
            isSelected: selectedSidebarIndex == 1,
            onTap: () { // Build #1.0.6
              if (kDebugMode) {
                print("##### Categories button tapped");
              }
              lastSelectedIndex = 1; //Build #1.0.7: Store last selection
              onSidebarItemSelected(1);

              /// CategoriesScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CategoriesScreen( lastSelectedIndex: lastSelectedIndex)),
              );
            },
            isVertical: isVertical,
          ),
          SidebarButton(
            icon: Icons.add,
            label: TextConstants.addText,
            isSelected: selectedSidebarIndex == 2,
            onTap: () {
              if (kDebugMode) {
                print("##### AddScreen button tapped");
              }
              lastSelectedIndex = 2;
              onSidebarItemSelected(2);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AddScreen(lastSelectedIndex: lastSelectedIndex)),
              );
            },
            isVertical: isVertical,
          ),
          SidebarButton(
            icon: Icons.shopping_basket,
            label: TextConstants.ordersText,
            isSelected: selectedSidebarIndex == 3,
            onTap: () { // Build #1.0.8, Naveen added
              if (kDebugMode) {
                print("##### OrdersScreen button tapped");
              }
              lastSelectedIndex = 3;
              onSidebarItemSelected(3);

              /// OrdersScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => OrdersScreen(lastSelectedIndex: lastSelectedIndex)),
              );
            },
            isVertical: isVertical,
          ),
          SidebarButton(
            icon: Icons.apps,
            label: TextConstants.appsText,
            isSelected: selectedSidebarIndex == 4,
            onTap: () {
              if (kDebugMode) {
                print("##### AppsScreen button tapped");
              }
              lastSelectedIndex = 4;
              onSidebarItemSelected(4);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AppsDashboardScreen()),
              );
            },
            isVertical: isVertical,
          ),
          // You can add more dynamic items here in the future.
        ];

        // Fixed items (always visible at the bottom)
        Widget fixedItems = Column(
          children: [
            const Divider(color: Colors.black54),
            SidebarButton(
              icon: Icons.settings,
              label: TextConstants.settingsHeaderText,
              isSelected: selectedSidebarIndex == 5,
              onTap: () {
                if (kDebugMode) {
                  print("##### Settings button tapped");
                }
                lastSelectedIndex = selectedSidebarIndex; // Build #1.0.7: Store before navigating

                onSidebarItemSelected(5); // Highlight settings

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(),
                  ),
                ).then((_) {
                  // Restore the sidebar selection when coming back
                  onSidebarItemSelected(lastSelectedIndex);
                });
              },
              isVertical: isVertical,
            ),
            SidebarButton(
              icon: Icons.logout,
              label: TextConstants.logoutText,
              isSelected: selectedSidebarIndex == 6,
              onTap: () {
                onSidebarItemSelected(6);
                ///add a stateless widget to show logout popup dialog
                print("nav logout called");

                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.custom,
                  showCancelBtn: true,
                  showConfirmBtn: true,
                  title: TextConstants.logoutText,
                  width: 450,
                  text: TextConstants.doYouWantTo,
                  confirmBtnText: TextConstants.logoutText,
                  cancelBtnText: TextConstants.cancelText,
                  headerBackgroundColor: const Color(0xFF2CD9C5),
                  confirmBtnColor: Colors.blue,
                  confirmBtnTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                  cancelBtnTextStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                  customAsset: null,
                  animType: QuickAlertAnimType.scale,
                  barrierDismissible: false,

                  // Widget for the Close Shift button
                  widget: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: SwipeButton(
                      thumb: const Icon(
                        Icons.double_arrow_rounded,
                        color: Colors.white,
                      ),
                      child: Text(
                        TextConstants.swipeToCloseShift,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      borderRadius: BorderRadius.circular(25),
                      activeThumbColor: Colors.orangeAccent,
                      activeTrackColor: Colors.orange,
                      onSwipe: () {
                        // Close shift functionality
                        if (kDebugMode) {
                          print("Shift closed");
                        }
                        ///Todo: call shift-open-close-balance screen and set the title to "Shift close balanse"
                        ///
                        Navigator.of(context).pop();
                        // Add your close shift logic here
                      },
                    ),
                  ),
                  onConfirmBtnTap: () {
                    /// logout function
                    Navigator.of(context).pop();
                  },
                  onCancelBtnTap: () {
                    /// cancel
                    Navigator.of(context).pop();
                  },
                );
              },
              isVertical: isVertical,
            ),
            const SizedBox(height: 10),
          ],
        );

        return Padding(
          padding: const EdgeInsets.only(top: 10.0), // Adjust padding as needed
          child: Column(
            children: [
              // Dynamic part: scrollable on small screens, fixed layout on larger screens.
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(top: 0),
                  children: dynamicItems,
                )
              ),
              // Fixed items at the bottom.
              fixedItems,
            ],
          ),
        );
      },
    );
  }



  Widget _buildHorizontalLayout() {
    int lastSelectedIndex = 0; // Store last selected index before opening Settings
    return LayoutBuilder( //Build #1.0.2 : updated the code for this fix - RenderFlex overflowed by 42 pixels
      builder: (context, constraints) {
        if (kDebugMode) {
          print("#### _buildHorizontalLayout constraints: $constraints");
        }
        // Dynamic items (scrollable horizontally if needed)
        List<Widget> dynamicItems = [
          SidebarButton(
            icon: Icons.flash_on,
            label: TextConstants.fastKeyText,
            isSelected: selectedSidebarIndex == 0,
            onTap: () { // Build #1.0.6
              if (kDebugMode) {
                print("##### Fast Keys button tapped");
              }
              lastSelectedIndex = 0; // Store last selection
              onSidebarItemSelected(0);

              /// FastKeyScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FastKeyScreen(lastSelectedIndex: lastSelectedIndex)),
              );
            },
            isVertical: isVertical,
          ),
          SidebarButton(
            icon: Icons.category,
            label: TextConstants.categoriesText,
            isSelected: selectedSidebarIndex == 1,
            onTap: () { // Build #1.0.6
              if (kDebugMode) {
                print("##### Categories button tapped");
              }
              lastSelectedIndex = 1; // Store last selection
              onSidebarItemSelected(1);

              /// CategoriesScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CategoriesScreen(lastSelectedIndex: lastSelectedIndex)),
              );
            },
            isVertical: isVertical,
          ),
          SidebarButton(
            icon: Icons.add_box_outlined,
            label: TextConstants.addText,
            isSelected: selectedSidebarIndex == 2,
            onTap: () {
              if (kDebugMode) {
                print("##### AddScreen button tapped");
              }
              lastSelectedIndex = 2;
              onSidebarItemSelected(2);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AddScreen()),
              );
            },
            isVertical: isVertical,
          ),
          SidebarButton(
            icon: Icons.shopping_basket,
            label: TextConstants.ordersText,
            isSelected: selectedSidebarIndex == 3,
            onTap: () { // Build #1.0.8, Naveen added
              if (kDebugMode) {
                print("##### OrdersScreen button tapped");
              }
              lastSelectedIndex = 3;
              onSidebarItemSelected(3);

              /// OrdersScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => OrdersScreen(lastSelectedIndex: lastSelectedIndex)),
              );
            },
            isVertical: isVertical,
          ),
          SidebarButton(
            icon: Icons.apps,
            label: TextConstants.appsText,
            isSelected: selectedSidebarIndex == 4,
            onTap: () {
              if (kDebugMode) {
                print("##### AppsScreen button tapped");
              }
              lastSelectedIndex = 4;
              onSidebarItemSelected(4);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AppsDashboardScreen()),
              );
            },
            isVertical: isVertical,
          ),
          // Additional dynamic items can be added here.
        ];

        // Fixed items that remain visible (on the right)
        List<Widget> fixedItems = [
          const VerticalDivider(color: Colors.black54),
          SidebarButton(
            icon: Icons.settings,
            label: TextConstants.settingsHeaderText,
            isSelected: selectedSidebarIndex == 5,
            onTap: () {
              if (kDebugMode) {
                print("##### Settings button tapped");
              }
              lastSelectedIndex = selectedSidebarIndex; // Store before navigating

              onSidebarItemSelected(5); // Highlight settings

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              ).then((_) {
                // Restore the sidebar selection when coming back
                onSidebarItemSelected(lastSelectedIndex);
              });
            },
            isVertical: isVertical,
          ),
          SidebarButton(
            icon: Icons.logout,
            label: TextConstants.logoutText,
            isSelected: selectedSidebarIndex == 6,
            onTap: () => onSidebarItemSelected(6),
            isVertical: isVertical,
          ),
          const SizedBox(width: 10),
        ];

        // Dynamic part: scrollable if small, evenly spaced if not.
        Widget dynamicRow = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dynamicItems,
          )
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), // Adjust padding as needed
          child: Row(
            children: [
              // Dynamic part takes the available space.
              Expanded(child: dynamicRow),
              // Fixed items remain at the end.
              Row(
                children: fixedItems,
              ),
            ],
          ),
        );
      },
    );
  }
}

class SidebarButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isVertical;

  const SidebarButton({
    this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isVertical = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
      child: GestureDetector(
        onTap: onTap,
        child: isVertical ? _buildVerticalLayout(context) : _buildHorizontalLayout(),
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.05,
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: isSelected ? Colors.red : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 8
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: isSelected ? Colors.red : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.red : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}