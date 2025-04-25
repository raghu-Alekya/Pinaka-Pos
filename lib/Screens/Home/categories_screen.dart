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

enum SidebarPosition { left, right, bottom }
enum OrderPanelPosition { left, right }

class CategoriesScreen extends StatefulWidget {
  final int? lastSelectedIndex;

  const CategoriesScreen({super.key, this.lastSelectedIndex});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with WidgetsBindingObserver {
  final List<String> items = List.generate(18, (index) => 'Bud Light');
  int _selectedSidebarIndex = 1;
  DateTime now = DateTime.now();
  List<int> quantities = [1, 1, 1, 1];
  SidebarPosition sidebarPosition = SidebarPosition.left;
  OrderPanelPosition orderPanelPosition = OrderPanelPosition.right;
  bool isLoading = true;
  final ValueNotifier<int?> fastKeyTabIdNotifier = ValueNotifier<int?>(null);
  final OrderHelper orderHelper = OrderHelper();

  late CategoryBloc _categoryBloc;
  List<CategoryModel> categories = [];
  int? _selectedCategoryIndex;
  int? _editingCategoryIndex;

  List<CategoryModel> subCategories = [];
  bool isShowingSubCategories = false;
  List<Map<String, dynamic>> categoryProducts = [];
  int? selectedItemIndex;
  List<int?> reorderedIndices = [];
  List<String> navigationPath = [];
  List<int> categoryHierarchy = [0];
  int currentCategoryLevel = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 1;
    _categoryBloc = CategoryBloc(CategoryRepository());
    reorderedIndices = List.filled(categoryProducts.length, null);

    _loadLastSelectedCategory();
    _loadCategories(0);

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLastSelectedCategory();
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
    if (lastSelectedIndex != null && lastSelectedIndex < categories.length) {
      setState(() {
        _selectedCategoryIndex = lastSelectedIndex;
        navigationPath = [categories[_selectedCategoryIndex!].name];
      });
      _loadCategories(categories[_selectedCategoryIndex!].id);
      categoryHierarchy.add(categories[_selectedCategoryIndex!].id);
      currentCategoryLevel++;
    } else if (categories.isNotEmpty) {
      setState(() {
        _selectedCategoryIndex = 0;
        navigationPath = [categories[0].name];
      });
      await prefs.setInt('lastSelectedCategoryIndex', 0);
      _loadCategories(categories[0].id);
      categoryHierarchy.add(categories[0].id);
      currentCategoryLevel++;
    }
  }

  Future<void> _saveLastSelectedCategory(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSelectedCategoryIndex', index);
  }

  Future<void> _loadCategories(int parentId) async {
    _categoryBloc.fetchCategories(parentId);
    _categoryBloc.categoriesStream.listen((response) {
      if (response.status == Status.COMPLETED && response.data != null) {
        setState(() {
          if (parentId == 0) {
            categories = response.data!.categories;
            if (_selectedCategoryIndex == null && categories.isNotEmpty) {
              _selectedCategoryIndex = 0;
              _saveLastSelectedCategory(0);
              navigationPath = [categories[0].name];
              _loadCategories(categories[0].id);
              categoryHierarchy.add(categories[0].id);
              currentCategoryLevel++;
            }
          } else {
            subCategories = response.data!.categories;
            isShowingSubCategories = true;
            categoryProducts.clear();
          }
        });
      } else if (response.status == Status.ERROR) {
        if (kDebugMode) {
          print("CategoriesScreen: Error loading categories: ${response.message}");
        }
      }
    });
  }

  Future<void> _loadProductsByCategory(int categoryId) async {
    _categoryBloc.fetchProductsByCategory(categoryId);
    _categoryBloc.productsStream.listen((response) {
      if (response.status == Status.COMPLETED && response.data != null) {
        setState(() {
          categoryProducts = response.data!.products.map((product) {
            return {
              'fast_key_item_id': product.id,
              'fast_key_item_name': product.name,
              'fast_key_item_image': product.images.isNotEmpty ? product.images.first : '',
              'fast_key_item_price': product.price,
            };
          }).toList();
          reorderedIndices = List.filled(categoryProducts.length, null);
          isShowingSubCategories = false;
        });
      } else if (response.status == Status.ERROR) {
        if (kDebugMode) {
          print("CategoriesScreen: Error loading products: ${response.message}");
        }
      }
    });
  }

  void _onCategoryTapped(int index) {
    setState(() {
      if (_editingCategoryIndex == index) {
        _editingCategoryIndex = null;
      } else {
        _selectedCategoryIndex = index;
        navigationPath = [categories[index].name];
        subCategories.clear();
        categoryProducts.clear();
        isShowingSubCategories = false;
        categoryHierarchy = [0, categories[index].id];
        currentCategoryLevel = 1;
      }
    });
    _saveLastSelectedCategory(index);
    _loadCategories(categories[index].id);
  }

  void _onSubCategoryTapped(int index) {
    final selectedSubCategory = subCategories[index];
    setState(() {
      navigationPath.add(selectedSubCategory.name);
      categoryHierarchy.add(selectedSubCategory.id);
      currentCategoryLevel++;
    });
    _loadCategories(selectedSubCategory.id);

    _categoryBloc.categoriesStream.listen((response) {
      if (response.status == Status.COMPLETED && response.data != null) {
        if (response.data!.categories.isEmpty) {
          _loadProductsByCategory(selectedSubCategory.id);
        }
      }
    });
  }

  void _onBackToCategories() {
    if (currentCategoryLevel > 0) {
      setState(() {
        currentCategoryLevel--;
        categoryHierarchy.removeLast();
        navigationPath.removeLast();
        isShowingSubCategories = currentCategoryLevel > 0;
        categoryProducts.clear();
        if (currentCategoryLevel == 0) {
          _loadCategories(0);
        } else {
          _loadCategories(categoryHierarchy.last);
        }
      });
    }
  }

  void _onItemSelected(int index) async {
    if (index == 0 && categoryProducts.isNotEmpty) {
      _onBackToCategories();
      return;
    }
    final adjustedIndex = index - 1;
    if (adjustedIndex < 0 || adjustedIndex >= categoryProducts.length) return;

    setState(() {
      navigationPath.add(categoryProducts[adjustedIndex]["fast_key_item_name"]);
    });

    final selectedProduct = categoryProducts[adjustedIndex];
    await orderHelper.addItemToOrder(
      selectedProduct["fast_key_item_name"],
      selectedProduct["fast_key_item_image"],
      double.tryParse(selectedProduct["fast_key_item_price"].toString()) ?? 0.0,
      1,
      'SKU${selectedProduct["fast_key_item_name"]}',
      onItemAdded: _refreshOrderList,
    );
  }

  void _onNavigationPathTapped(int index) {
    if (index < navigationPath.length - 1) {
      setState(() {
        navigationPath = navigationPath.sublist(0, index + 1);
        categoryHierarchy = categoryHierarchy.sublist(0, index + 1);
        currentCategoryLevel = index;
        isShowingSubCategories = currentCategoryLevel > 0;
        categoryProducts.clear();
        _loadCategories(categoryHierarchy.last);
      });
    }
  }

  void _refreshOrderList() {
    setState(() {});
  }

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
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          setState(() {
                            final item = categories.removeAt(oldIndex);
                            categories.insert(newIndex, item);
                            if (_selectedCategoryIndex == oldIndex) {
                              _selectedCategoryIndex = newIndex;
                            } else if (oldIndex < _selectedCategoryIndex! && newIndex >= _selectedCategoryIndex!) {
                              _selectedCategoryIndex = _selectedCategoryIndex! - 1;
                            } else if (oldIndex > _selectedCategoryIndex! && newIndex <= _selectedCategoryIndex!) {
                              _selectedCategoryIndex = _selectedCategoryIndex! + 1;
                            }
                          });
                        },
                        onEditButtonPressed: (index) {
                          setState(() {
                            _editingCategoryIndex = index;
                          });
                        },
                        onDismissEditMode: () {
                          setState(() {
                            _editingCategoryIndex = null;
                          });
                        },
                      ),
                      // Navigation Path (without "Back to Categories" button)
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
                                                child: Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
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
                      // Subcategories or Products Grid
                      Expanded(
                        child: isShowingSubCategories
                            ? SubCategoryGridWidget(
                          isLoading: isLoading,
                          subCategories: subCategoryListItems,
                          onSubCategoryTapped: _onSubCategoryTapped,
                        )
                            : NestedGridWidget(
                          isHorizontal: true,
                          isLoading: isLoading,
                          showAddButton: false,
                          showBackButton: categoryProducts.isNotEmpty, // Show "Back to Categories" button if products are displayed
                          items: categoryProducts,
                          selectedItemIndex: selectedItemIndex,
                          reorderedIndices: reorderedIndices,
                          onAddButtonPressed: null,
                          onBackButtonPressed: _onBackToCategories, // Pass the back functionality
                          onItemTapped: _onItemSelected,
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex == 0 || newIndex == 0) return;
                            final adjustedOldIndex = oldIndex - 1;
                            final adjustedNewIndex = newIndex - 1;
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