import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../Constants/text.dart';
import '../../Preferences/pinaka_preferences.dart';

enum SidebarPosition { left, right, bottom }
enum OrderPanelPosition { left, right }

mixin LayoutSelectionMixin<T extends StatefulWidget> on State<T> { //Build #1.0.54: added
  final PinakaPreferences _preferences = PinakaPreferences();
  SidebarPosition sidebarPosition = SidebarPosition.left;
  OrderPanelPosition orderPanelPosition = OrderPanelPosition.right;
  bool _isInitialLoad = true; // Add this flag


  @override
  void initState() {
    super.initState();
    // Load layout first before adding listener
    _loadLayoutSelection().then((_) {
      PinakaPreferences.layoutSelectionNotifier.addListener(_onLayoutChanged);
      if (kDebugMode) {
        print("#### LayoutSelectionMixin: Added listener after initial load");
      }
    });
  }

  Future<void> _loadLayoutSelection() async {
    String? savedLayout = await _preferences.getSavedLayoutSelection();
    if (kDebugMode) {
      print("#### LayoutSelectionMixin: _loadLayoutSelection - Loaded layout: $savedLayout");
    }

    // Only update if we have a saved layout
    if (savedLayout != null && savedLayout.isNotEmpty) {
      _updateLayoutFromPreference(savedLayout);
    } else {
      // Set default only if nothing is saved
      String defaultLayout = SharedPreferenceTextConstants.navLeftOrderRight;
      await _preferences.saveLayoutSelection(defaultLayout);
      _updateLayoutFromPreference(defaultLayout);
    }
    _isInitialLoad = false;
  }

  void _onLayoutChanged() {
    if (_isInitialLoad) return; // Skip during initial load

    if (kDebugMode) {
      print("#### LayoutSelectionMixin: _onLayoutChanged with value: ${PinakaPreferences.layoutSelectionNotifier.value}");
    }
    _updateLayoutFromPreference(PinakaPreferences.layoutSelectionNotifier.value);
  }

  void _updateLayoutFromPreference(String savedLayout) {
    if (mounted) {
      setState(() {
        switch (savedLayout) {
          case SharedPreferenceTextConstants.navLeftOrderRight:
            sidebarPosition = SidebarPosition.left;
            orderPanelPosition = OrderPanelPosition.right;
            break;
          case SharedPreferenceTextConstants.navRightOrderLeft:
            sidebarPosition = SidebarPosition.right;
            orderPanelPosition = OrderPanelPosition.left;
            break;
          case SharedPreferenceTextConstants.navBottomOrderLeft:
            sidebarPosition = SidebarPosition.bottom;
            orderPanelPosition = OrderPanelPosition.left;
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    PinakaPreferences.layoutSelectionNotifier.removeListener(_onLayoutChanged);
    if (kDebugMode) {
      print("#### LayoutSelectionMixin: Removed listener for layoutSelectionNotifier in ${widget.runtimeType}");
    }
    super.dispose();
  }
}