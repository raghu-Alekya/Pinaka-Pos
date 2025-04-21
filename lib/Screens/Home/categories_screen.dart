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
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../Helper/api_response.dart';
import '../../Repositories/Category/category_repository.dart';
import '../../Widgets/widget_category_list.dart';
import '../../Widgets/widget_nested_grid_layout.dart';
import '../../Widgets/widget_order_panel.dart';
import '../../Widgets/widget_topbar.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;
import '../../Blocs/Category/category_bloc.dart';
import '../../Models/Category/category_model.dart';
import '../../Database/db_helper.dart';
import '../../Database/user_db_helper.dart';

// Enum for sidebar positioning options
enum SidebarPosition { left, right, bottom }

// Enum for order panel positioning options
enum OrderPanelPosition { left, right }

/// CategoriesScreen - Main screen for displaying product categories and navigation
class CategoriesScreen extends StatefulWidget { // Build #1.0.21 - Updated code with complete business logic here
  final int? lastSelectedIndex; // Last selected sidebar index for persistence

  const CategoriesScreen({super.key, this.lastSelectedIndex});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // UI state variables
  int _selectedSidebarIndex = 1; // Default to Fast Key selection
  DateTime now = DateTime.now(); // Current time for order panel
  List<int> quantities = [1, 1, 1, 1]; // Demo quantities
  SidebarPosition sidebarPosition = SidebarPosition.left; // Default sidebar position
  OrderPanelPosition orderPanelPosition = OrderPanelPosition.right; // Default panel position
  bool isLoading = true; // Loading state indicator

  // Category management state
  late CategoryBloc _categoryBloc; // Business logic controller for categories
  List<CategoryModel> categories = []; // Top-level categories
  List<CategoryModel> subCategories = []; // Subcategories of selected category
  List<CategoryModel> subSubCategories = []; // Sub-subcategories
  List<Map<String, dynamic>> categoryProducts = []; // Products for selected category
  int? selectedCategoryId; // Currently selected category ID
  int? selectedSubCategoryId; // Currently selected subcategory ID
  final ValueNotifier<int?> categoryIdNotifier = ValueNotifier<int?>(null); // Notifier for category changes
  final ValueNotifier<int?> subCategoryIdNotifier = ValueNotifier<int?>(null); // Notifier for subcategory changes
  StreamSubscription<APIResponse<CategoryListResponse>>? _categoriesSubscription;

  // For editing and reordering
  int? _editingIndex;
  int? _selectedIndex; // Track selected index in the horizontal list
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = true;
  bool _isCategoryLoading = false;
  bool _showBackButton = false; // Controls visibility of back button in product grid

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("Initializing CategoriesScreen state");
    }

    // Restore last selected sidebar index or use default
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 1;

    // Initialize category business logic controller
    _categoryBloc = CategoryBloc(CategoryRepository());

    // Set up the listener once when the widget initializes
    _categoriesSubscription = _categoryBloc.categoriesStream.listen((response) {
      if (response.status == Status.COMPLETED && response.data != null && mounted) {
        setState(() {
          if (selectedSubCategoryId == null) {
            // Loading top-level categories
            categories = response.data!.categories;
            if (categories.isNotEmpty && selectedCategoryId == null) {
              selectedCategoryId = categories.first.id;
              categoryIdNotifier.value = selectedCategoryId;
            }
          } else {
            // Loading subcategories or products
            if (_showBackButton) {
              // We're at sub-subcategory level
              subSubCategories = response.data!.categories;
              if (subSubCategories.isEmpty) {
                // No more subcategories, load products
                _loadCategoryProducts(selectedSubCategoryId!);
              }
            } else {
              // We're at subcategory level
              subCategories = response.data!.categories;
              if (subCategories.isEmpty) {
                // No subcategories, load products directly
                _loadCategoryProducts(selectedCategoryId!);
              }
            }
          }
        });
      }
    });

    _scrollController.addListener(_updateScrollArrows);

    // Load initial category data
    _loadCategories();

    // Simulate loading delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isLoading = false;
          if (kDebugMode) {
            print("Loading completed, updating UI");
          }
        });
      }
    });
  }

  void _updateScrollArrows() {
    setState(() {
      _showLeftArrow = _scrollController.offset > 0;
      _showRightArrow = _scrollController.offset < _scrollController.position.maxScrollExtent;
    });
  }

  /// Loads top-level categories from API/database
  Future<void> _loadCategories() async {
    if (kDebugMode) {
      print("Loading top-level categories...");
    }

    setState(() {
      _isCategoryLoading = false;
    });

    try {
      // Fetch top-level categories (parentId = 0)
      await _categoryBloc.fetchCategories(0);
    } catch (e) {
      if (kDebugMode) {
        print("Exception in _loadCategories: $e");
      }
      if (mounted) {
        setState(() {
          _isCategoryLoading = false;
        });
      }
    }
  }

  /// Loads subcategories for a given parent category ID
  Future<void> _loadSubCategories(int parentId) async {
    if (kDebugMode) {
      print("Loading subcategories for parent ID: $parentId");
    }

    setState(() {
      _isCategoryLoading = true;
      _showBackButton = false;
      subSubCategories = [];
      categoryProducts = [];
    });

    try {
      await _categoryBloc.fetchCategories(parentId);
    } catch (e) {
      if (kDebugMode) {
        print("Exception in _loadSubCategories: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCategoryLoading = false;
        });
      }
    }
  }

  /// Loads products for a given category ID
  Future<void> _loadCategoryProducts(int categoryId) async {
    if (kDebugMode) {
      print("Loading products for category ID: $categoryId");
    }

    setState(() {
      _isCategoryLoading = true;
      categoryProducts = [];
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with actual API call to get products
    // For now, we'll use mock data
    List<Map<String, dynamic>> mockProducts = List.generate(10, (index) {
      return {
        'id': index,
        'title': 'Product ${index + 1}',
        'image': 'https://via.placeholder.com/150',
        'price': (index + 1) * 10.0,
      };
    });

    if (mounted) {
      setState(() {
        categoryProducts = mockProducts;
        _isCategoryLoading = false;
      });
    }
  }

  /// Handles category selection from the horizontal list
  void _handleCategorySelection(int categoryId) {
    if (kDebugMode) {
      print("User selected category with ID: $categoryId");
      print("Previous selected category ID: $selectedCategoryId");
    }

    // Only proceed if this is a new selection
    //  if (selectedCategoryId != categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      selectedSubCategoryId = null;
      categoryIdNotifier.value = categoryId;
      subCategoryIdNotifier.value = null;
      _editingIndex = null;
      _showBackButton = false;

      if (kDebugMode) {
        print("Updating selected category to ID: $categoryId");
      }
    });

    // Load subcategories for the newly selected category
    _loadSubCategories(categoryId);
    // } else {
    //   if (kDebugMode) {
    //     print("Category already selected, no action needed");
    //   }
    // }
  }

  /// Handles subcategory selection from the grid
  void _handleSubCategorySelection(int subCategoryId) {
    if (kDebugMode) {
      print("User selected subcategory with ID: $subCategoryId");
      print("Previous selected subcategory ID: $selectedSubCategoryId");
    }

    // Only proceed if this is a new selection
    if (selectedSubCategoryId != subCategoryId) {
      setState(() {
        selectedSubCategoryId = subCategoryId;
        subCategoryIdNotifier.value = subCategoryId;
        _showBackButton = true;

        if (kDebugMode) {
          print("Updating selected subcategory to ID: $subCategoryId");
        }
      });

      // Load sub-subcategories or products
      _loadSubCategories(subCategoryId);
    } else {
      if (kDebugMode) {
        print("Subcategory already selected, no action needed");
      }
    }
  }

  /// Handles back button press in product grid
  void _handleBackPress() {
    if (kDebugMode) {
      print("User pressed back button");
    }

    setState(() {
      _showBackButton = false;
      selectedSubCategoryId = null;
      subCategoryIdNotifier.value = null;
      subSubCategories = [];
      categoryProducts = [];
    });

    // Reload subcategories for the main category
    if (selectedCategoryId != null) {
      _loadSubCategories(selectedCategoryId!);
    }
  }

  /// Refreshes the order list (callback for order panel)
  void _refreshOrderList() {
    if (kDebugMode) {
      print("Refreshing order list...");
    }
    setState(() {
      // This triggers a rebuild which will refresh the order panel
      if (kDebugMode) {
        print("Order list refresh triggered");
      }
    });
  }

  Widget _buildScrollButton(IconData icon, VoidCallback onPressed) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.redAccent),
        onPressed: onPressed,
      ),
    );
  }

  bool _doesContentOverflow(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = categories.length * 120;
    return contentWidth > screenWidth;
  }

  Widget _buildCategoryImage(CategoryModel category) {
    if (category.image?.startsWith('http') ?? false) {
      return Image.network(
        category.image!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.category, size: 40);
        },
      );
    } else {
      return const Icon(Icons.category, size: 40);
    }
  }

  void _showCategoryDialog({required BuildContext context, int? index}) {
    bool isEditing = index != null;
    TextEditingController nameController = TextEditingController(
        text: isEditing ? categories[index!].name : '');
    String imagePath = isEditing ? categories[index!].image ?? 'assets/default.png' : 'assets/default.png';
    bool showError = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Category' : 'Add Category'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Stack(
                          children: [
                            _buildImageWidget(imagePath),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  // TODO: Implement image picker
                                  // final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                                  // if (pickedFile != null) {
                                  //   setStateDialog(() => imagePath = pickedFile.path);
                                  // }
                                },
                                child: const Icon(Icons.edit,
                                    size: 18, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          errorText: (!isEditing && showError && nameController.text.isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                      ),
                      if (isEditing)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Item Count: ${categories[index].count}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (!isEditing && nameController.text.isEmpty) {
                      setStateDialog(() => showError = true);
                      return;
                    }
                    if (isEditing) {
                      // TODO: Update category in database
                      setState(() {
                        _editingIndex = null;
                        categories[index] = categories[index].copyWith(
                          name: nameController.text,
                          image: imagePath,
                        );
                      });
                    } else {
                      // TODO: Add new category
                      // await _addCategory(nameController.text, imagePath);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
                if (isEditing)
                  TextButton(
                    onPressed: () => _showDeleteConfirmationDialog(index!),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.isEmpty) return _safeSvgPicture('assets/default.png');
    if (imagePath.startsWith('assets/') && imagePath.endsWith('.svg')) {
      return _safeSvgPicture(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, height: 80, width: 80, fit: BoxFit.cover);
    } else {
      return Image.network(
        imagePath,
        height: 80,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _safeSvgPicture('assets/default.png'),
      );
    }
  }

  Widget _safeSvgPicture(String assetPath) {
    try {
      return Image.asset(
        assetPath,
        height: 80,
        width: 80,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
      );
    } catch (e) {
      debugPrint("Image Error: $e");
      return Image.asset('assets/default.png', height: 80, width: 80);
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    bool isDeleting = false;
    final category = categories[index];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Delete Category'),
              content: const Text('Are you sure you want to delete this category?'),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: isDeleting ? null : () async {
                    setStateDialog(() => isDeleting = true);
                    // TODO: Delete category from database
                    setState(() {
                      categories.removeAt(index);
                      if (_selectedIndex != null) {
                        if (_selectedIndex! >= categories.length) {
                          _selectedIndex = categories.isNotEmpty ? categories.length - 1 : null;
                        }
                        categoryIdNotifier.value = _selectedIndex != null
                            ? categories[_selectedIndex!].id
                            : null;
                      }
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                  child: isDeleting
                      ? const CircularProgressIndicator()
                      : const Text('Yes', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("Building CategoriesScreen UI");
    }

    final screenWidth = MediaQuery.of(context).size.width;
    String formattedDate = DateFormat("EEE, MMM d' ${now.year}'").format(now);
    String formattedTime = DateFormat('hh:mm a').format(now);

    return Scaffold(
      body: Column(
        children: [
          // Top app bar
          TopBar(
            onModeChanged: () {
              if (kDebugMode) {
                print("User toggled sidebar position");
                print("Current position: $sidebarPosition");
              }

              setState(() {
                // Cycle through sidebar positions
                if (sidebarPosition == SidebarPosition.left) {
                  sidebarPosition = SidebarPosition.right;
                } else if (sidebarPosition == SidebarPosition.right) {
                  sidebarPosition = SidebarPosition.bottom;
                } else {
                  sidebarPosition = SidebarPosition.left;
                }

                if (kDebugMode) {
                  print("New sidebar position: $sidebarPosition");
                }
              });
            },
          ),

          // Divider between top bar and main content
          const Divider(color: Colors.grey, thickness: 0.4, height: 1),

          // Main content area
          Expanded(
            child: Row(
              children: [
                // Left sidebar (conditional)
                if (sidebarPosition == SidebarPosition.left)
                  custom_widgets.NavigationBar(
                    selectedSidebarIndex: _selectedSidebarIndex,
                    onSidebarItemSelected: (index) {
                      if (kDebugMode) {
                        print("User selected sidebar item at index: $index");
                      }
                      setState(() {
                        _selectedSidebarIndex = index;
                      });
                    },
                    isVertical: true,
                  ),

                // Left order panel (conditional)
                if (sidebarPosition == SidebarPosition.right ||
                    (sidebarPosition == SidebarPosition.bottom &&
                        orderPanelPosition == OrderPanelPosition.left))
                  RightOrderPanel(
                    formattedDate: formattedDate,
                    formattedTime: formattedTime,
                    quantities: quantities,
                    refreshOrderList: _refreshOrderList,
                  ),

                // Main content area
                Expanded(
                  child: Column(
                    children: [
                      // Horizontal category list
                      _buildCategoryList(context),

                      // Grid for subcategories or products
                      ValueListenableBuilder<int?>(
                        valueListenable: categoryIdNotifier,
                        builder: (context, categoryId, child) {
                          if (kDebugMode) {
                            print("Rebuilding grid for category ID: $categoryId");
                          }

                          // Show products if we have them
                          if (categoryProducts.isNotEmpty) {
                            return NestedGridWidget(
                              isHorizontal: true,
                              isLoading: isLoading,
                              items: categoryProducts,
                              onItemSelected: (index) {
                                // Handle product selection
                                if (kDebugMode) {
                                  print("Product selected: ${categoryProducts[index]}");
                                }
                                // TODO: Add product to order
                              },
                              showAddButton: false,
                              showBackButton: _showBackButton,
                              onBackPressed: _handleBackPress,
                            );
                          }

                          // Show sub-subcategories if we have them
                          if (subSubCategories.isNotEmpty) {
                            return NestedGridWidget(
                              isHorizontal: true,
                              isLoading: isLoading,
                              items: subSubCategories.map((cat) => {
                                'id': cat.id,
                                'title': cat.name,
                                'image': cat.image ?? 'assets/default.png',
                                'price': '',
                              }).toList(),
                              onItemSelected: (index) {
                                // Handle sub-subcategory selection
                                final subSubCatId = subSubCategories[index].id;
                                if (kDebugMode) {
                                  print("Sub-subcategory selected: $subSubCatId");
                                }
                                // Load products for this sub-subcategory
                                _loadCategoryProducts(subSubCatId);
                              },
                              showAddButton: false,
                              showBackButton: _showBackButton,
                              onBackPressed: _handleBackPress,
                            );
                          }

                          // Show subcategories by default
                          return NestedGridWidget(
                            isHorizontal: true,
                            isLoading: isLoading,
                            items: subCategories.map((cat) => {
                              'id': cat.id,
                              'title': cat.name,
                              'image': cat.image ?? 'assets/default.png',
                              'price': '',
                            }).toList(),
                            onItemSelected: _handleSubCategorySelection,
                            showAddButton: false,
                            showBackButton: _showBackButton,
                            onBackPressed: _handleBackPress,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Right order panel (conditional)
                if (sidebarPosition != SidebarPosition.right &&
                    !(sidebarPosition == SidebarPosition.bottom &&
                        orderPanelPosition == OrderPanelPosition.left))
                  RightOrderPanel(
                    formattedDate: formattedDate,
                    formattedTime: formattedTime,
                    quantities: quantities,
                    refreshOrderList: _refreshOrderList,
                  ),

                // Right sidebar (conditional)
                if (sidebarPosition == SidebarPosition.right)
                  custom_widgets.NavigationBar(
                    selectedSidebarIndex: _selectedSidebarIndex,
                    onSidebarItemSelected: (index) {
                      if (kDebugMode) {
                        print("User selected sidebar item at index: $index");
                      }
                      setState(() {
                        _selectedSidebarIndex = index;
                      });
                    },
                    isVertical: true,
                  ),
              ],
            ),
          ),

          // Bottom sidebar (conditional)
          if (sidebarPosition == SidebarPosition.bottom)
            custom_widgets.NavigationBar(
              selectedSidebarIndex: _selectedSidebarIndex,
              onSidebarItemSelected: (index) {
                if (kDebugMode) {
                  print("User selected sidebar item at index: $index");
                }
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

  Widget _buildCategoryList(BuildContext context) {
    if (_isCategoryLoading) {
      return Container(
        height: 100,
        color: Colors.grey[200],
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: isLoading
          ? Container(
        height: 100,
        color: Colors.grey[200],
      )
          : _buildHorizontalList(context),
    );
  }

  Widget _buildHorizontalList(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        setState(() {
          _editingIndex = null;
        });
      },
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (widget, animation) {
              return FadeTransition(opacity: animation, child: widget);
            },
            child: _showLeftArrow && _doesContentOverflow(context)
                ? _buildScrollButton(Icons.arrow_back_ios, () {
              _scrollController.animateTo(
                _scrollController.offset - size.width,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            })
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: SizedBox(
              height: 110,
              child: ReorderableListView(
                scrollController: _scrollController,
                scrollDirection: Axis.horizontal,
                onReorderStart: (index) {
                  setState(() {
                    _editingIndex = index;
                  });
                },
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  setState(() {
                    final item = categories.removeAt(oldIndex);
                    categories.insert(newIndex, item);
                    _editingIndex = newIndex;
                    if (_selectedIndex != null) {
                      if (_selectedIndex == oldIndex) {
                        _selectedIndex = newIndex;
                      } else if (oldIndex < _selectedIndex! && newIndex >= _selectedIndex!) {
                        _selectedIndex = _selectedIndex! - 1;
                      } else if (oldIndex > _selectedIndex! && newIndex <= _selectedIndex!) {
                        _selectedIndex = _selectedIndex! + 1;
                      }
                    }
                  });
                },
                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                  return Material(
                    elevation: 0,
                    color: Colors.transparent,
                    child: child,
                  );
                },
                children: List.generate(categories.length, (index) {
                  final category = categories[index];
                  bool isSelected = selectedCategoryId == category.id;
                  bool showEditButton = _editingIndex == index;

                  return GestureDetector(
                    key: ValueKey('${category.name}_$index'),
                    onTap: () async {
                      setState(() {
                        if (_editingIndex == index) {
                          _editingIndex = null;
                        } else if (selectedCategoryId == category.id) {
                          return;
                        } else {
                          selectedCategoryId = category.id;
                          _selectedIndex = index;
                        }
                      });
                      if (_editingIndex == null) {
                        categoryIdNotifier.value = category.id;
                        _handleCategorySelection(category.id);
                      }
                      _editingIndex = null;
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: AnimatedContainer(
                        width: 90,
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: showEditButton ? Colors.blueAccent : Colors.black12,
                            width: showEditButton ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 0,
                              right: -6,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: showEditButton ? 1.0 : 0.0,
                                child: GestureDetector(
                                  onTap: () => _showCategoryDialog(context: context, index: index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, size: 14, color: Colors.blueAccent),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCategoryImage(category),
                                const SizedBox(height: 8),
                                Text(
                                  category.name,
                                  maxLines: 1,
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  category.count.toString(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (widget, animation) {
              return FadeTransition(opacity: animation, child: widget);
            },
            child: _showRightArrow && _doesContentOverflow(context)
                ? _buildScrollButton(Icons.arrow_forward_ios, () {
              _scrollController.animateTo(
                _scrollController.offset + size.width,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            })
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print("Disposing CategoriesScreen resources");
    }

    // Clean up resources
    _categoriesSubscription?.cancel();
    _categoryBloc.dispose();
    categoryIdNotifier.dispose();
    subCategoryIdNotifier.dispose();
    _scrollController.dispose();

    super.dispose();
  }
}
