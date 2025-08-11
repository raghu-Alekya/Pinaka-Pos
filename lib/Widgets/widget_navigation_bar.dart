import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
import '../Database/user_db_helper.dart';
import '../Helper/Extentions/theme_notifier.dart';

import '../Constants/text.dart';
import '../Blocs/Auth/logout_bloc.dart';
import '../Helper/api_response.dart';
import '../Repositories/Auth/logout_repository.dart';
import '../Screens/Home/add_screen.dart';
import '../Screens/Home/Settings/settings_screen.dart';
import '../Screens/Home/shift_open_close_balance.dart';
import '../Screens/Home/total_orders_screen.dart';
import '../Utilities/svg_images_utility.dart';

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
    final logoutBloc = LogoutBloc(LogoutRepository());  // Build #1.0.163: Initialize LogoutBloc with repository
    return Container(
      width: isVertical ? MediaQuery.of(context).size.width * 0.07 : null,
      height: isVertical ? null : MediaQuery.of(context).size.height * 0.125,
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
                  ? _buildVerticalLayout(context, shiftId, logoutBloc)  // Build #1.0.163
                  : _buildHorizontalLayout(context, shiftId, logoutBloc);
            },
          ),
        ),
      ),
    );
  }

  Future<String?> _getShiftId() async { //Build #1.0.78
    if (kDebugMode) {
      print("### Getting shiftId from database");
    }
    int? shiftId = await UserDbHelper().getUserShiftId(); // Build #1.0.161: added debug prints
    if (kDebugMode) {
      print("### Retrieved shiftId: $shiftId");
    }
    return shiftId.toString();
  }

  Widget _buildVerticalLayout(BuildContext context, String? shiftId, LogoutBloc logoutBloc) {
    int lastSelectedIndex = 0;
    final themeHelper = Provider.of<ThemeNotifier>(context);
    // Build #1.0.161: Fixed Issue - navigation bar icons are not disabled before create shift
    bool isShiftInvalid = shiftId == null || shiftId == "null" || shiftId.isEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
           if (kDebugMode) {
              print("#### _buildVerticalLayout constraints: $constraints");
           }
        // Dynamic items (scrollable if needed)
        List<Widget> dynamicItems = [
          SidebarButton(
            svgAsset: selectedSidebarIndex == 0 ? SvgUtils.fastKeySelectedIcon : SvgUtils.fastKeyIcon, // Build #1.0.148: Fixed Issue: Menu Bar Icons not matching with latest Figma Design , now using from assets/svg/navigation/
            label: TextConstants.fastKeyText,
            isSelected: selectedSidebarIndex == 0,
            onTap: isShiftInvalid
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
            isDisabled: isShiftInvalid,
          ),
          const SizedBox(height: 10),
          SidebarButton(
            svgAsset: SvgUtils.categoriesIcon,
            label: TextConstants.categoriesText,
            isSelected: selectedSidebarIndex == 1,
            onTap: isShiftInvalid
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
            isDisabled: isShiftInvalid,
          ),
          const SizedBox(height: 10),
          SidebarButton(
            svgAsset: SvgUtils.addIcon,
            label: TextConstants.addText,
            isSelected: selectedSidebarIndex == 2,
            onTap: isShiftInvalid
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
            isDisabled: isShiftInvalid,
          ),
          const SizedBox(height: 10),
          SidebarButton(
            svgAsset: SvgUtils.ordersIcon,
            label: TextConstants.ordersText,
            isSelected: selectedSidebarIndex == 3,
            onTap: isShiftInvalid
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
            isDisabled: isShiftInvalid,
          ),
          const SizedBox(height: 10),
          SidebarButton(
            svgAsset: SvgUtils.appsIcon,
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
              svgAsset: SvgUtils.settingsIcon,
              label: TextConstants.settingsHeaderText,
              isSelected: selectedSidebarIndex == 5,
              onTap: isShiftInvalid
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
              isDisabled: isShiftInvalid,
            ),
            const SizedBox(height: 10),
            SidebarButton(
              svgAsset: SvgUtils.logoutIcon,
              label: TextConstants.logoutText,
              isSelected: selectedSidebarIndex == 6,
              onTap: isShiftInvalid
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
                  onConfirmBtnTap: () async {
                    if (kDebugMode) {
                      print("Logout confirmed, initiating logout process");
                    }

                    // Build #1.0.163: call Logout API
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        bool isLoading = true; // Initial loading state
                        logoutBloc.logoutStream.listen((response) {
                          if (response.status == Status.COMPLETED) {
                            if (kDebugMode) {
                              print("Logout successful, navigating to LoginScreen");
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(response.message ?? TextConstants.successfullyLogout),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            // Update loading state and navigate
                            isLoading = false;
                            Navigator.of(context).pop(); // Close loader dialog
                            Navigator.of(context).pop(); // Close QuickAlert dialog
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          } else if (response.status == Status.ERROR) {
                            if (kDebugMode) {
                              print("Logout failed: ${response.message}");
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(response.message ?? TextConstants.failedToLogout),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            // Update loading state
                            isLoading = false;
                            Navigator.of(context).pop(); // Close loader dialog
                          }
                        });

                        // Trigger logout API call
                        logoutBloc.performLogout();

                        // Show circular loader
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );
                      },
                    );
                  },
                  onCancelBtnTap: () {
                    /// cancel
                    Navigator.of(context).pop();
                  },
                );
              },
              isVertical: isVertical,
              isDisabled: isShiftInvalid,
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

  Widget _buildHorizontalLayout(BuildContext context, String? shiftId, LogoutBloc logoutBloc) {
    int lastSelectedIndex = 0;
    final themeHelper = Provider.of<ThemeNotifier>(context);
    // Build #1.0.161: Fixed Issue - navigation bar icons are not disabled before create shift
    bool isShiftInvalid = shiftId == null || shiftId == "null" || shiftId.isEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kDebugMode) {
          print("#### _buildHorizontalLayout constraints: $constraints");
        }
        // Dynamic items (scrollable horizontally if needed)
        List<Widget> dynamicItems = [
          SidebarButton(
            svgAsset: selectedSidebarIndex == 0 ? SvgUtils.fastKeySelectedIcon : SvgUtils.fastKeyIcon, // Build #1.0.148: Fixed Issue: Menu Bar Icons not matching with latest Figma Design , now using from assets/svg/navigation/
            label: TextConstants.fastKeyText,
            isSelected: selectedSidebarIndex == 0,
            onTap: isShiftInvalid
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
            isDisabled: isShiftInvalid,
          ),
          const SizedBox(height: 10),
          SidebarButton(
            svgAsset: SvgUtils.categoriesIcon,
            label: TextConstants.categoriesText,
            isSelected: selectedSidebarIndex == 1,
            onTap: isShiftInvalid
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
            isDisabled: isShiftInvalid,
          ),
          const SizedBox(height: 10),
          SidebarButton(
            svgAsset: SvgUtils.addIcon,
            label: TextConstants.addText,
            isSelected: selectedSidebarIndex == 2,
            onTap: isShiftInvalid
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
            isDisabled: isShiftInvalid,
          ),
          const SizedBox(height: 10),
          SidebarButton(
            svgAsset: SvgUtils.ordersIcon,
            label: TextConstants.ordersText,
            isSelected: selectedSidebarIndex == 3,
            onTap: isShiftInvalid
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
            isDisabled: isShiftInvalid,
          ),
          const SizedBox(height: 10),
          SidebarButton(
            svgAsset: SvgUtils.appsIcon,
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
            svgAsset: SvgUtils.settingsIcon,
            label: TextConstants.settingsHeaderText,
            isSelected: selectedSidebarIndex == 5,
            onTap: isShiftInvalid
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
            isDisabled: isShiftInvalid,
          ),
          const SizedBox(width: 10),
          SidebarButton(
            svgAsset: SvgUtils.logoutIcon,
            label: TextConstants.logoutText,
            isSelected: selectedSidebarIndex == 6,
            onTap: isShiftInvalid
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
                onConfirmBtnTap: () async {
                  // Trigger logout through BLoC
                  if (kDebugMode) {
                    print("Logout confirmed, initiating logout process");
                  }

                  // Build #1.0.163: call Logout API
                  // Use StatefulBuilder to manage loading state
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      bool isLoading = true; // Initial loading state
                      logoutBloc.logoutStream.listen((response) {
                        if (response.status == Status.COMPLETED) {
                          if (kDebugMode) {
                            print("Logout successful, navigating to LoginScreen");
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response.message ?? TextConstants.successfullyLogout),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          // Update loading state and navigate
                          isLoading = false;
                          Navigator.of(context).pop(); // Close loader dialog
                          Navigator.of(context).pop(); // Close QuickAlert dialog
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        } else if (response.status == Status.ERROR) {
                          if (kDebugMode) {
                            print("Logout failed: ${response.message}");
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response.message ?? TextConstants.failedToLogout),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          // Update loading state
                          isLoading = false;
                          Navigator.of(context).pop(); // Close loader dialog
                        }
                      });

                      // Trigger logout API call
                      logoutBloc.performLogout();

                      // Show circular loader
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );
                    },
                  );
                },
                onCancelBtnTap: () {
                  /// cancel
                  Navigator.of(context).pop();
                },
              );
            },
            isVertical: false,
            isDisabled: isShiftInvalid,
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
  final String? svgAsset;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isVertical;
  final bool isDisabled;

  const SidebarButton({
    this.icon,
    this.svgAsset,
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
          padding: const EdgeInsets.only(top: 10.0,bottom: 10, left: 2,right: 2),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: isSelected ? Colors.red : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              svgAsset != null
                  ? SvgPicture.asset( // Build #1.0.148: Fixed Issue: Menu Bar Icons not matching with latest Figma Design , now using from assets/svg/navigation/
                svgAsset!,
                colorFilter: ColorFilter.mode(
                  isSelected
                      ? Colors.white
                      : isDisabled
                      ? Colors.grey.shade800
                      : Colors.white70,
                  BlendMode.srcIn,
                ),
                height: 20,
              )
                  : Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : isDisabled
                    ? Colors.grey.shade800
                    : Colors.white70,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isDisabled
                      ? Colors.grey.shade800
                      : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
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
          child: Row(
            children: [
              svgAsset != null
                  ? SvgPicture.asset( // Build #1.0.148: Fixed Issue: Menu Bar Icons not matching with latest Figma Design , now using from assets/svg/navigation/
                svgAsset!,
                colorFilter: ColorFilter.mode(
                  isSelected
                      ? Colors.white
                      : isDisabled
                      ? Colors.grey.shade800
                      : Colors.white70,
                  BlendMode.srcIn,
                ),
                height: 28,
              )
                  : Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : isDisabled
                    ? Colors.grey.shade800
                    : Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white // Build #1.0.161: issue - updated red colour to white
                      : isDisabled
                      ? Colors.grey.shade800
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}