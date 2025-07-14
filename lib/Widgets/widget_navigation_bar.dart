import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_pos/Screens/Auth/login_screen.dart';
import 'package:pinaka_pos/Screens/Home/apps_dashboard_screen.dart';
import 'package:pinaka_pos/Screens/Home/categories_screen.dart';
import 'package:pinaka_pos/Screens/Home/fast_key_screen.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_animtype.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Helper/Extentions/theme_notifier.dart';

import '../Constants/text.dart';
import '../Screens/Home/add_screen.dart';
import '../Screens/Home/Settings/settings_screen.dart';
import '../Screens/Home/shift_open_close_balance.dart';
import '../Screens/Home/total_orders_screen.dart';

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
    final themeHelper = Provider.of<ThemeNotifier>(context);
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
          child: FutureBuilder<String?>( //Build #1.0.78: restrict user don't select any other nav buttons first login
            future: _getShiftId(),
            builder: (context, snapshot) {
              // if (snapshot.connectionState == ConnectionState.waiting) {
              //   return Center(child: CircularProgressIndicator());
              // }
              final shiftId = snapshot.data;
              return isVertical
                  ? _buildVerticalLayout(context, shiftId)
                  : _buildHorizontalLayout(context, shiftId);
            },
          ),
        ),
      ),
    );
  }

  Future<String?> _getShiftId() async { //Build #1.0.78
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TextConstants.shiftId);
  }

  Widget _buildVerticalLayout(BuildContext context, String? shiftId) {
    int lastSelectedIndex = 0;
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return LayoutBuilder(
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
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
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
            isDisabled: shiftId == null || shiftId.isEmpty,
          ),
          SidebarButton(
            icon: Icons.category,
            label: TextConstants.categoriesText,
            isSelected: selectedSidebarIndex == 1,
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
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
            isDisabled: shiftId == null || shiftId.isEmpty,
          ),
          SidebarButton(
            icon: Icons.add,
            label: TextConstants.addText,
            isSelected: selectedSidebarIndex == 2,
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
              if (kDebugMode) {
                print("##### AddScreen button tapped");
              }
              lastSelectedIndex = 2;
              onSidebarItemSelected(2);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AddScreen(lastSelectedIndex: lastSelectedIndex)),
              );
            },
            isVertical: isVertical,
            isDisabled: shiftId == null || shiftId.isEmpty,
          ),
          SidebarButton(
            icon: Icons.shopping_basket,
            label: TextConstants.ordersText,
            isSelected: selectedSidebarIndex == 3,
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
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
            isDisabled: shiftId == null || shiftId.isEmpty,
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
              onTap: shiftId == null || shiftId.isEmpty
                  ? () {}
                  : () {
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
              isDisabled: shiftId == null || shiftId.isEmpty,
            ),
            SidebarButton(
              icon: Icons.logout,
              label: TextConstants.logoutText,
              isSelected: selectedSidebarIndex == 6,
              onTap: () {
                onSidebarItemSelected(6);
                if (kDebugMode) {
                  print("nav logout called");
                }
                QuickAlert.show(
                  backgroundColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white ,
                  context: context,
                  type: QuickAlertType.custom,
                  showCancelBtn: true,
                  showConfirmBtn: true,
                  title: TextConstants.logoutText,
                  titleColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                  width: 450,
                  text: TextConstants.doYouWantTo,
                  textColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                  confirmBtnText: TextConstants.logoutText,
                  cancelBtnText: TextConstants.cancelText,
                  headerBackgroundColor: const Color(0xFF2CD9C5),
                  confirmBtnColor: Colors.blue,
                  confirmBtnTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                  cancelBtnTextStyle: TextStyle(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.grey, fontSize: 16),

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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShiftOpenCloseBalanceScreen(),
                            settings: RouteSettings(arguments: TextConstants.navLogout),  // Build #1.0.70
                          ),
                        );
                      },
                      child: Text(
                        TextConstants.swipeToCloseShift,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  onConfirmBtnTap: () {
                    /// logout function
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
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
                ),
              ),
              fixedItems,
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, String? shiftId) {
    int lastSelectedIndex = 0;
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return LayoutBuilder(
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
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
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
            isVertical: false, //Build #1.0.54: updated
          ),
          SidebarButton(
            icon: Icons.category,
            label: TextConstants.categoriesText,
            isSelected: selectedSidebarIndex == 1,
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
              if (kDebugMode) {
                print("##### Categories button tapped");
              }
              lastSelectedIndex = 1; // Store last selection
              onSidebarItemSelected(1);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        CategoriesScreen(lastSelectedIndex: lastSelectedIndex)),
              );
            },
            isVertical: false,
          ),
          SidebarButton(
            icon: Icons.add,
            label: TextConstants.addText,
            isSelected: selectedSidebarIndex == 2,
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
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
            isVertical: false,
          ),
          SidebarButton(
            icon: Icons.shopping_basket,
            label: TextConstants.ordersText,
            isSelected: selectedSidebarIndex == 3,
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
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
            isVertical: false,
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
                MaterialPageRoute(builder: (context) => AppsDashboardScreen()),
              );
            },
            isVertical: false,
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
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
              if (kDebugMode) {
                print("##### Settings button tapped");
              }
              lastSelectedIndex = selectedSidebarIndex; // Store before navigating

              onSidebarItemSelected(5); // Highlight settings

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              ).then((_) {
                // Restore the sidebar selection when coming back
                onSidebarItemSelected(lastSelectedIndex);
              });
            },
            isVertical: false,
          ),
          SidebarButton(
            icon: Icons.logout,
            label: TextConstants.logoutText,
            isSelected: selectedSidebarIndex == 6,
            onTap: shiftId == null || shiftId.isEmpty
                ? () {}
                : () {
              onSidebarItemSelected(6);
              if (kDebugMode) {
                print("nav logout called");
              }
              QuickAlert.show(
                backgroundColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white ,
                context: context,
                type: QuickAlertType.custom,
                showCancelBtn: true,
                showConfirmBtn: true,
                title: TextConstants.logoutText,
                titleColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                width: 450,
                text: TextConstants.doYouWantTo,
                textColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                confirmBtnText: TextConstants.logoutText,
                cancelBtnText: TextConstants.cancelText,
                headerBackgroundColor: const Color(0xFF2CD9C5),
                confirmBtnColor: Colors.blue,
                confirmBtnTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                cancelBtnTextStyle: TextStyle(color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : Colors.grey, fontSize: 16),

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShiftOpenCloseBalanceScreen(),
                          settings: RouteSettings(arguments: TextConstants.navLogout),  // Build #1.0.70
                        ),
                      );
                    },
                    child: Text(
                      TextConstants.swipeToCloseShift,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                onConfirmBtnTap: () {
                  /// logout function
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
                },
                onCancelBtnTap: () {
                  /// cancel
                  Navigator.of(context).pop();
                },
              );
            },
            isVertical: false,
          ),
          const SizedBox(width: 10),
        ];

        // Dynamic part: scrollable if small, evenly spaced if not.
        Widget dynamicRow = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: dynamicItems,
          ),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), // Adjust padding as needed
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
  final bool isDisabled;

  const SidebarButton({
    this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isVertical = true,
     this.isDisabled = false,
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
                color: isSelected
                    ? Colors.white
                    : isDisabled // Check if onTap is disabled
                    ? Colors.grey.shade800 // Disabled color
                    : Colors.white70, // Enabled color
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isDisabled
                      ? Colors.grey.shade800
                      : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
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
            color: isSelected
                ? Colors.white
                : isDisabled
                ? Colors.grey.shade800
                : Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.red
                : isDisabled
                ? Colors.grey.shade800
                : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}