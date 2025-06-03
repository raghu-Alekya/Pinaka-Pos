// import 'package:flutter/foundation.dart';
//
// import '../../Widgets/widget_category_list.dart';
// import '../../Widgets/widget_nested_grid_layout.dart';
// import '../../Widgets/widget_order_panel.dart';
// import '../../Widgets/widget_topbar.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;
//
// // Enum for sidebar position
// enum SidebarPosition { left, right, bottom }
// // Enum for order panel position
// enum OrderPanelPosition { left, right }
//
// class CategoriesScreen extends StatefulWidget { // Build #1.0.6 - Updated Horizontal & Vertical Scrolling
//   final int? lastSelectedIndex; // Make it nullable
//
//   const CategoriesScreen({super.key, this.lastSelectedIndex}); // Optional, no default value
//
//
//   @override
//   State<CategoriesScreen> createState() => _CategoriesScreenState();
// }
//
// class _CategoriesScreenState extends State<CategoriesScreen> {
//   final List<String> items = List.generate(18, (index) => 'Bud Light');
//   int _selectedSidebarIndex = 1; //Build #1.0.2 : By default fast key should be selected after login
//   DateTime now = DateTime.now();
//   List<int> quantities = [1, 1, 1, 1];
//   SidebarPosition sidebarPosition = SidebarPosition.left; // Default to bottom sidebar
//   OrderPanelPosition orderPanelPosition = OrderPanelPosition.right; // Default to right
//   bool isLoading = true; // Add a loading state
//   final ValueNotifier<int?> fastKeyTabIdNotifier = ValueNotifier<int?>(null); // Add this
//
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedSidebarIndex = widget.lastSelectedIndex ?? 1; // Build #1.0.7: Restore previous selection
//     // Simulate a loading delay
//     Future.delayed(const Duration(seconds: 3), () {
//       setState(() {
//         isLoading = false; // Set loading to false after 3 seconds
//       });
//     });
//   }
//
//   void _refreshOrderList() { // Build #1.0.10 - Naveen: This will trigger a rebuild of the RightOrderPanel (Callback)
//     setState(() {
//       if (kDebugMode) {
//         print("###### CategoriesScreen _refreshOrderList");
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     String formattedDate = DateFormat("EEE, MMM d' ${now.year}'").format(now);
//     String formattedTime = DateFormat('hh:mm a').format(now);
//
//     return Scaffold(
//       body: Column(
//         children: [
//           // Top Bar
//           TopBar(
//             onModeChanged: () {
//               setState(() {
//                 if (sidebarPosition == SidebarPosition.left) {
//                   sidebarPosition = SidebarPosition.right;
//                 } else if (sidebarPosition == SidebarPosition.right) {
//                   sidebarPosition = SidebarPosition.bottom;
//                 } else {
//                   sidebarPosition = SidebarPosition.left;
//                 }
//               });
//             },
//           ),
//           Divider(
//             color: Colors.grey, // Light grey color
//             thickness: 0.4, // Very thin line
//             height: 1, // Minimal height
//           ),
//           // Main Content
//           Expanded(
//             child: Row(
//               children: [
//                 // Left Sidebar (Conditional)
//                 if (sidebarPosition == SidebarPosition.left)
//                   custom_widgets.NavigationBar( //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
//                     selectedSidebarIndex: _selectedSidebarIndex,
//                     onSidebarItemSelected: (index) {
//                       setState(() {
//                         _selectedSidebarIndex = index;
//                       });
//                     },
//                     isVertical: true, // Vertical layout for left sidebar
//                   ),
//
//                 // Order Panel on the Left (Conditional: Only when sidebar is right or bottom with left order panel)
//                 if (sidebarPosition == SidebarPosition.right ||
//                     (sidebarPosition == SidebarPosition.bottom && orderPanelPosition == OrderPanelPosition.left))
//                   RightOrderPanel(
//                     formattedDate: formattedDate,
//                     formattedTime: formattedTime,
//                     quantities: quantities,
//                     refreshOrderList: _refreshOrderList, // Pass the callback
//                   ),
//
//                 // Main Content (Horizontal Scroll and Grid View)
//                 Expanded(
//                   child: Column(
//                     children: [
//                       CategoryList(isHorizontal: true, isLoading: isLoading, isAddButtonEnabled: false, fastKeyTabIdNotifier: fastKeyTabIdNotifier),
//                       // Grid Layout
//                       ValueListenableBuilder<int?>( // Build #1.0.11
//                         valueListenable: fastKeyTabIdNotifier,
//                         builder: (context, fastKeyTabId, child) {
//                           return NestedGridWidget(
//                             isHorizontal: true,
//                             isLoading: isLoading,
//                             onItemAdded: _refreshOrderList,
//                             fastKeyTabIdNotifier: fastKeyTabIdNotifier,
//                             showAddButton: false, // Build #1.0.12: This will hide the add button in CategoriesScreen
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Order Panel on the Right (Conditional: Only when sidebar is left or bottom with right order panel)
//                 if (sidebarPosition != SidebarPosition.right &&
//                     !(sidebarPosition == SidebarPosition.bottom && orderPanelPosition == OrderPanelPosition.left))
//                   RightOrderPanel(
//                     formattedDate: formattedDate,
//                     formattedTime: formattedTime,
//                     quantities: quantities,
//                     refreshOrderList: _refreshOrderList, // Pass the callback
//                   ),
//
//                 // Right Sidebar (Conditional)
//                 if (sidebarPosition == SidebarPosition.right)
//                   custom_widgets.NavigationBar( //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
//                     selectedSidebarIndex: _selectedSidebarIndex,
//                     onSidebarItemSelected: (index) {
//                       setState(() {
//                         _selectedSidebarIndex = index;
//                       });
//                     },
//                     isVertical: true, // Vertical layout for right sidebar
//                   ),
//               ],
//             ),
//           ),
//
//           // Bottom Sidebar (Conditional)
//           if (sidebarPosition == SidebarPosition.bottom)
//             custom_widgets.NavigationBar( //Build #1.0.4 : Updated class name LeftSidebar to NavigationBar
//               selectedSidebarIndex: _selectedSidebarIndex,
//               onSidebarItemSelected: (index) {
//                 setState(() {
//                   _selectedSidebarIndex = index;
//                 });
//               },
//               isVertical: false, // Horizontal layout for bottom sidebar
//             ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Blocs/Search/product_search_bloc.dart';
import '../../Helper/Extentions/nav_layout_manager.dart';
import '../../Preferences/pinaka_preferences.dart';
import '../../Repositories/Search/product_search_repository.dart';
import '../../Widgets/widget_category_list.dart';
import '../../Widgets/widget_nested_grid_layout.dart';
import '../../Widgets/widget_order_panel.dart';
import '../../Widgets/widget_sub_category.dart';
import '../../Widgets/widget_topbar.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;
import '../../Blocs/Category/category_bloc.dart';
import '../../Repositories/Category/category_repository.dart';
import '../../Helper/api_response.dart';
import '../../Models/Category/category_model.dart';
import '../../Models/Category/category_product_model.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Constants/text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesScreen extends StatefulWidget {
  final int? lastSelectedIndex;

  const CategoriesScreen({super.key, this.lastSelectedIndex});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with WidgetsBindingObserver, LayoutSelectionMixin{
  final List<String> items = List.generate(18, (index) => 'Bud Light');
  int _selectedSidebarIndex = 1;
  DateTime now = DateTime.now();
  List<int> quantities = [1, 1, 1, 1];
  // SidebarPosition sidebarPosition = SidebarPosition.left;
  // OrderPanelPosition orderPanelPosition = OrderPanelPosition.right;
  bool isLoading = true;
  bool isLoadingNestedContent = false; //Build #1.0.34: added for shimmer effect issue
  final ValueNotifier<int?> fastKeyTabIdNotifier = ValueNotifier<int?>(null);
  final OrderHelper orderHelper = OrderHelper();
  final productBloc = ProductBloc(ProductRepository());
  final PinakaPreferences _preferences = PinakaPreferences(); // Add this

  late CategoryBloc _categoryBloc;
  List<CategoryModel> categories = []; // Build #1.0.27 : Top-level categories only
  List<CategoryModel> subCategories = []; // Build #1.0.27 : Subcategories for the selected category
  int? _selectedCategoryIndex;
  int? _editingCategoryIndex;
  int? _selectedSubCategoryIndex;

  List<Map<String, dynamic>> categoryProducts = [];
  int? selectedItemIndex;
  List<int?> reorderedIndices = [];
  List<String> navigationPath = [];
  List<int> categoryHierarchy = [0];
  int currentCategoryLevel = 0;
  String? lastSelectedProduct;
  bool isShowingSubCategories = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 1;
    _categoryBloc = CategoryBloc(CategoryRepository());
    reorderedIndices = List.filled(categoryProducts.length, null);

    _loadTopLevelCategories(); // Build #1.0.27 : Load top-level categories once
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _loadLastSelectedCategory will be called after _loadTopLevelCategories
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadLastSelectedCategory();
    }
  }

  Future<void> _loadLastSelectedCategory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastSelectedIndex = prefs.getInt('lastSelectedCategoryIndex');

    if (lastSelectedIndex != null && lastSelectedIndex >= 0 && lastSelectedIndex < categories.length) {
      setState(() {
        _selectedCategoryIndex = lastSelectedIndex;
        // Start with just the category name
        navigationPath = [categories[_selectedCategoryIndex!].name];
        categoryHierarchy = [0, categories[_selectedCategoryIndex!].id];
        currentCategoryLevel = 1;
        isShowingSubCategories = true;
      });
      _loadSubCategories(categories[_selectedCategoryIndex!].id);
    } else if (categories.isNotEmpty) {
      setState(() {
        _selectedCategoryIndex = 0;
        // Start with just the category name
        navigationPath = [categories[0].name];
        categoryHierarchy = [0, categories[0].id];
        currentCategoryLevel = 1;
        isShowingSubCategories = true;
      });
      await prefs.setInt('lastSelectedCategoryIndex', 0);
      _loadSubCategories(categories[0].id);
    }
  }

  Future<void> _saveLastSelectedCategory(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSelectedCategoryIndex', index);
  }

  // Load top-level categories (parentId = 0) once
  Future<void> _loadTopLevelCategories() async { // Build #1.0.27
    _categoryBloc.fetchCategories(0);
    await for (var response in _categoryBloc.categoriesStream) {
      if (response.status == Status.COMPLETED && response.data != null) {
        setState(() {
          categories = response.data!.categories;
        });
        // After loading categories, apply the last selected category
        _loadLastSelectedCategory();
        break; // Break after loading top-level categories
      } else if (response.status == Status.ERROR) {
        if (kDebugMode) {
          print("CategoriesScreen: Error loading top-level categories: ${response.message}");
        }
      }
    }
  }

  // Load subcategories for a specific parent category
  Future<void> _loadSubCategories(int parentId) async {
    setState(() {
      isLoadingNestedContent = true; // Add this line to show shimmer
    });
    _categoryBloc.fetchCategories(parentId);
    await for (var response in _categoryBloc.categoriesStream) {
      if (response.status == Status.COMPLETED && response.data != null) {
        setState(() {
          subCategories = response.data!.categories;
          isShowingSubCategories = true;
          categoryProducts.clear();
          _selectedSubCategoryIndex = null;
          isLoadingNestedContent = false; // Hide shimmer when data is loaded
        });
        if (subCategories.isEmpty) {
          _loadProductsByCategory(parentId);
        }
        break; // Break after loading subcategories
      } else if (response.status == Status.ERROR) {
        setState(() {
          isLoadingNestedContent = false; // Hide shimmer on error
        });
        if (kDebugMode) {
          print("CategoriesScreen: Error loading subcategories: ${response.message}");
        }
      }
    }
  }

  Future<void> _loadProductsByCategory(int categoryId) async {
    setState(() {
      isLoadingNestedContent = true; // Add this line to show shimmer
    });

    _categoryBloc.fetchProductsByCategory(categoryId);
    await for (var response in _categoryBloc.productsStream) {
      if (response.status == Status.COMPLETED && response.data != null) {
        setState(() {
          categoryProducts = response.data!.products.map((product) {
            if (kDebugMode) {
              print("Category Product name: ${ product.name}, id: ${ product.id}");
            }
            return {
              'fast_key_product_id': product.id,
              'fast_key_item_name': product.name,
              'fast_key_item_image': product.images.isNotEmpty ? product.images.first : '',
              'fast_key_item_price': product.price,
            };
          }).toList();
          reorderedIndices = List.filled(categoryProducts.length, null);
          isShowingSubCategories = false;
          isLoadingNestedContent = false; // Hide shimmer when data is loaded
        });
        break;
      } else if (response.status == Status.ERROR) {
        setState(() {
          isLoadingNestedContent = false; // Hide shimmer on error
        });
        if (kDebugMode) {
          print("CategoriesScreen: Error loading products: ${response.message}");
        }
      }
    }
  }

  void _onCategoryTapped(int index) {
    if (index < 0 || index >= categories.length) return; // Prevent RangeError
    setState(() {
      _selectedCategoryIndex = index;
      // Always show the category name first
      navigationPath = [categories[index].name]; // Reset path with just category name
      subCategories.clear();
      categoryProducts.clear();
      isShowingSubCategories = true;
      categoryHierarchy = [0, categories[index].id]; // Reset hierarchy
      currentCategoryLevel = 1;
      _selectedSubCategoryIndex = null;
      _editingCategoryIndex = null;
      isLoadingNestedContent = true; // Add this line to show shimmer
    });

    _saveLastSelectedCategory(index);
    _loadSubCategories(categories[index].id);
  }

  void _onSubCategoryTapped(int index) { //Build #1.0.34: updated code for navigation path issues
    if (index < 0 || index >= subCategories.length) return;

    final selectedSubCategory = subCategories[index];

    setState(() {
      _selectedSubCategoryIndex = index;
      // Only add to navigation path if moving to a new subcategory level
      if (currentCategoryLevel < categoryHierarchy.length) {
        navigationPath = navigationPath.sublist(0, currentCategoryLevel);
        categoryHierarchy = categoryHierarchy.sublist(0, currentCategoryLevel + 1);
      }
      navigationPath.add(selectedSubCategory.name);
      categoryHierarchy.add(selectedSubCategory.id);
      currentCategoryLevel++;
      isShowingSubCategories = true;
      categoryProducts.clear();
      isLoadingNestedContent = true; // Add this line to show shimmer
    });

    _loadSubCategories(selectedSubCategory.id);
  }

  void _onBackToCategories() {
    if (currentCategoryLevel > 0) {
      setState(() {
        currentCategoryLevel--;
        navigationPath.removeLast();
        categoryHierarchy.removeLast();
        isShowingSubCategories = true;
        categoryProducts.clear();
        _selectedSubCategoryIndex = null;
      });

      if (currentCategoryLevel == 0) {
        _loadSubCategories(categories[_selectedCategoryIndex!].id);
      } else {
        _loadSubCategories(categoryHierarchy.last);
      }
    }
  }

  //Build 1.1.36: Update the products loading to not add to navigation path
  void _onItemSelected(int index, {bool variantAdded = false}) {
    if (index == 0 && showBackButton) {
      _onBackToCategories();
      return;
    }

    final adjustedIndex = index - (showBackButton ? 1 : 0);
    if (adjustedIndex < 0 || adjustedIndex >= categoryProducts.length) return;

    if (!variantAdded) { //Build 1.1.36
      // Only add the base product if no variant was added
      final selectedProduct = categoryProducts[adjustedIndex];
      if (kDebugMode) {
        print("CategoriesScreen - Adding base product to order: ${selectedProduct['fast_key_item_name']}");
      }
      orderHelper.addItemToOrder(
        selectedProduct["fast_key_item_name"],
        selectedProduct["fast_key_item_image"],
        double.tryParse(selectedProduct["fast_key_item_price"].toString()) ?? 0.0,
        1,
        'SKU${selectedProduct["fast_key_item_name"]}',
        onItemAdded: _refreshOrderList,
      );
    } else {
      // If a variant was added, just refresh the UI
      _refreshOrderList();
    }
  }

  void _onNavigationPathTapped(int index) { //Build #1.0.34: fixed code for navigation path issues
    if (index < 0 || index >= navigationPath.length) return;

    // Don't reload if tapping the currently active path item
    if (index == currentCategoryLevel - 1) return;

    setState(() {
      // Truncate path and hierarchy to clicked level
      navigationPath = navigationPath.sublist(0, index + 1);
      categoryHierarchy = categoryHierarchy.sublist(0, index + 2);
      currentCategoryLevel = index + 1;
      isShowingSubCategories = true;
      categoryProducts.clear();
      _selectedSubCategoryIndex = null;
    });

    // Load appropriate subcategories
    if (index == 0) {
      _loadSubCategories(categories[_selectedCategoryIndex!].id);
    } else {
      _loadSubCategories(categoryHierarchy.last);
    }
  }

  void _refreshOrderList() {
    setState(() {});
  }

  bool get showBackButton => categoryProducts.isNotEmpty;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _categoryBloc.dispose();
    fastKeyTabIdNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    String formattedDate = DateFormat("EEE, MMM d' ${now.year}'").format(now);
    String formattedTime = DateFormat('hh:mm a').format(now);

    final categoryListItems = categories.map((category) {
      return {
        'title': category.name,
        'image': category.image ?? 'assets/default.png',
        'itemCount': category.count,
      };
    }).toList();

    final subCategoryListItems = subCategories.map((subCategory) {
      return {
        'name': subCategory.name,
        'image': subCategory.image ?? 'assets/default.png',
        'count': subCategory.count,
      };
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          TopBar(
            onModeChanged: () {
              String newLayout;
              setState(() {
                if (sidebarPosition == SidebarPosition.left) {
                  newLayout = SharedPreferenceTextConstants.navRightOrderLeft;
                } else if (sidebarPosition == SidebarPosition.right) {
                  newLayout = SharedPreferenceTextConstants.navBottomOrderLeft;
                } else {
                  newLayout = SharedPreferenceTextConstants.navLeftOrderRight;
                }

                //Build #1.0.54: Update the notifier which will trigger _onLayoutChanged
                PinakaPreferences.layoutSelectionNotifier.value = newLayout;
                // No need to call saveLayoutSelection here as it's handled in the notifier
                _preferences.saveLayoutSelection(newLayout);
              });
            },
            onProductSelected: (product) {
              double price;
              try {
                price = double.tryParse(product.price ?? '0.00') ?? 0.00;
              } catch (e) {
                price = 0.00;
              }
              orderHelper.addItemToOrder(
                product.name ?? 'Unknown',
                product.images?.isNotEmpty == true ? product.images!.first : '',
                price,
                1,
                'SKU${product.name}',
                onItemAdded: _refreshOrderList,
              );
            },
          ),
          const Divider(
            color: Colors.grey,
            thickness: 0.4,
            height: 1,
          ),
          Expanded(
            child: Row(
              children: [
                if (sidebarPosition == SidebarPosition.left)
                  custom_widgets.NavigationBar(
                    selectedSidebarIndex: _selectedSidebarIndex,
                    onSidebarItemSelected: (index) {
                      setState(() {
                        _selectedSidebarIndex = index;
                      });
                    },
                    isVertical: true,
                  ),
                if (sidebarPosition == SidebarPosition.right ||
                    (sidebarPosition == SidebarPosition.bottom && orderPanelPosition == OrderPanelPosition.left))
                  RightOrderPanel(
                    formattedDate: formattedDate,
                    formattedTime: formattedTime,
                    quantities: quantities,
                    refreshOrderList: _refreshOrderList,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      // Always show the CategoryList
                      CategoryList(
                        isHorizontal: true,
                        isLoading: isLoading,
                        isAddButtonEnabled: false,
                        categories: categoryListItems,
                        selectedIndex: _selectedCategoryIndex,
                        editingIndex: _editingCategoryIndex,
                        onAddButtonPressed: null,
                        onCategoryTapped: _onCategoryTapped,
                        // In CategoriesScreen.dart, update the onReorder callback in the CategoryList widget
                        onReorder: (oldIndex, newIndex) { //Build 1.1.36: code updated
                          if (kDebugMode) {
                            print("### CategoriesScreen: Reordering category from index $oldIndex to $newIndex");
                          }
                          setState(() {
                            // Create a copy of categories to ensure proper reordering
                            final List<CategoryModel> tempCategories = List.from(categories);
                            // Remove the item from oldIndex
                            final item = tempCategories.removeAt(oldIndex);
                            // Insert the item at newIndex
                            tempCategories.insert(newIndex, item);
                            // Update the categories list
                            categories = tempCategories;

                            // Update selectedCategoryIndex to maintain selection
                            if (_selectedCategoryIndex == oldIndex) {
                              _selectedCategoryIndex = newIndex;
                            } else if (oldIndex < _selectedCategoryIndex! && newIndex >= _selectedCategoryIndex!) {
                              _selectedCategoryIndex = _selectedCategoryIndex! - 1;
                            } else if (oldIndex > _selectedCategoryIndex! && newIndex <= _selectedCategoryIndex!) {
                              _selectedCategoryIndex = _selectedCategoryIndex! + 1;
                            }

                            if (kDebugMode) {
                              print("### CategoriesScreen: Updated categories order: ${categories.map((c) => c.name).toList()}");
                              print("### CategoriesScreen: Updated selectedCategoryIndex: $_selectedCategoryIndex");
                            }
                          });
                        },
                      ),
                      if (currentCategoryLevel > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(navigationPath.length, (index) {
                                      return GestureDetector(
                                        onTap: () => _onNavigationPathTapped(index),
                                        child: Row(
                                          children: [
                                            Text(
                                              navigationPath[index],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            if (index < navigationPath.length - 1)
                                              const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                                child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.blue),
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: isShowingSubCategories && subCategories.isNotEmpty
                            ? SubCategoryGridWidget(
                          isLoading: isLoadingNestedContent,
                          subCategories: subCategoryListItems,
                          selectedSubCategoryIndex: _selectedSubCategoryIndex,
                          onSubCategoryTapped: _onSubCategoryTapped,
                        )
                            : NestedGridWidget(
                          productBloc: productBloc,
                          orderHelper: orderHelper,
                          isHorizontal: true,
                          isLoading: isLoadingNestedContent,
                          showAddButton: false,
                          showBackButton: showBackButton,
                          items: categoryProducts,
                          selectedItemIndex: selectedItemIndex,
                          reorderedIndices: reorderedIndices,
                          onAddButtonPressed: null,
                          onBackButtonPressed: _onBackToCategories,
                          onItemTapped: _onItemSelected, // Updated to match the new signature
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex == 0 || newIndex == 0) return;
                            final adjustedOldIndex = oldIndex - (showBackButton ? 1 : 0);
                            final adjustedNewIndex = newIndex - (showBackButton ? 1 : 0);
                            if (adjustedOldIndex < 0 ||
                                adjustedNewIndex < 0 ||
                                adjustedOldIndex >= categoryProducts.length ||
                                adjustedNewIndex >= categoryProducts.length) {
                              return;
                            }
                            setState(() {
                              categoryProducts = List<Map<String, dynamic>>.from(categoryProducts);
                              final item = categoryProducts.removeAt(adjustedOldIndex);
                              categoryProducts.insert(adjustedNewIndex, item);
                              reorderedIndices = List.filled(categoryProducts.length, null);
                              reorderedIndices[adjustedNewIndex] = adjustedNewIndex;
                              selectedItemIndex = adjustedNewIndex;
                            });
                          },
                          onDeleteItem: (index) {},
                          onCancelReorder: () {
                            setState(() {
                              reorderedIndices = List.filled(categoryProducts.length, null);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (sidebarPosition != SidebarPosition.right &&
                    !(sidebarPosition == SidebarPosition.bottom && orderPanelPosition == OrderPanelPosition.left))
                  RightOrderPanel(
                    formattedDate: formattedDate,
                    formattedTime: formattedTime,
                    quantities: quantities,
                    refreshOrderList: _refreshOrderList,
                  ),
                if (sidebarPosition == SidebarPosition.right)
                  custom_widgets.NavigationBar(
                    selectedSidebarIndex: _selectedSidebarIndex,
                    onSidebarItemSelected: (index) {
                      setState(() {
                        _selectedSidebarIndex = index;
                      });
                    },
                    isVertical: true,
                  ),
              ],
            ),
          ),
          if (sidebarPosition == SidebarPosition.bottom)
            custom_widgets.NavigationBar(
              selectedSidebarIndex: _selectedSidebarIndex,
              onSidebarItemSelected: (index) {
                setState(() {
                  _selectedSidebarIndex = index;
                });
              },
              isVertical: false,
            ),
        ],
      ),
    );
  }
}