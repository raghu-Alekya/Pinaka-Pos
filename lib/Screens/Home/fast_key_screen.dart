// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../Database/order_panel_db_helper.dart';
// import '../../Widgets/widget_category_list.dart';
// import '../../Widgets/widget_nested_grid_layout.dart';
// import '../../Widgets/widget_order_panel.dart';
// import '../../Widgets/widget_topbar.dart';
// import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;
//
// // Enum for sidebar position
// enum SidebarPosition { left, right, bottom }
// // Enum for order panel position
// enum OrderPanelPosition { left, right }
//
// class FastKeyScreen extends StatefulWidget {
//   final int? lastSelectedIndex; //Build #1.0.7: Make it nullable
//
//   const FastKeyScreen({super.key, this.lastSelectedIndex}); // Optional, no default value
//
//   @override
//   State<FastKeyScreen> createState() => _FastKeyScreenState();
// }
//
// class _FastKeyScreenState extends State<FastKeyScreen> {
//   final List<String> items = List.generate(18, (index) => 'Bud Light');
//   int _selectedSidebarIndex = 0; //Build #1.0.2 : By default fast key should be selected after login
//   DateTime now = DateTime.now();
//   List<int> quantities = [1, 1, 1, 1];
//   SidebarPosition sidebarPosition = SidebarPosition.left; // Default to bottom sidebar
//   OrderPanelPosition orderPanelPosition = OrderPanelPosition.right; // Default to right
//   bool isLoading = true; // Add a loading state
//   final ValueNotifier<int?> fastKeyTabIdNotifier = ValueNotifier<int?>(null); // Add this
//   final OrderHelper orderHelper = OrderHelper();
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedSidebarIndex = widget.lastSelectedIndex ?? 0; // Build #1.0.7: Restore previous selection
//
//     // Simulate a loading delay
//     Future.delayed(const Duration(seconds: 3), () {
//       if(mounted) {
//         setState(() {
//           isLoading = false; // Set loading to false after 3 seconds
//         });
//       }
//     });
//   }
//
//   void _refreshOrderList() { // Build #1.0.10 - Naveen: This will trigger a rebuild of the RightOrderPanel (Callback)
//     setState(() {
//       if (kDebugMode) {
//         print("###### FastKeyScreen _refreshOrderList");
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
//             onProductSelected: (product) { // Build #1.0.13 : Added product search
//               // Convert price from String to double safely
//               double price;
//               try {
//                 price = double.tryParse(product.price ?? '0.00') ?? 0.00;
//               } catch (e) {
//                 price = 0.00;
//               }
//
//               orderHelper.addItemToOrder(
//                 product.name ?? 'Unknown',
//                 product.images?.isNotEmpty == true ? product.images!.first : '',
//                 price, // Now properly converted to double
//                 1, // quantity
//                 'SKU${product.name}', // SKU
//               );
//             },
//           ),
//           Divider( // Build #1.0.6
//             color: Colors.grey,
//             thickness: 0.4,
//             height: 1,
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
//                       // Add the CategoryScroll widget here
//                       CategoryList(isHorizontal: true, isLoading: isLoading,isAddButtonEnabled: true, fastKeyTabIdNotifier: fastKeyTabIdNotifier),// Build #1.0.7
//
//                       // Grid Layout
//                       ValueListenableBuilder<int?>( // Build #1.0.11 : Added Notifier for update list and counts
//                         valueListenable: fastKeyTabIdNotifier,
//                         builder: (context, fastKeyTabId, child) {
//                           return NestedGridWidget(
//                             isHorizontal: true,
//                             isLoading: isLoading,
//                             onItemAdded: _refreshOrderList,
//                             fastKeyTabIdNotifier: fastKeyTabIdNotifier,
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
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../Blocs/Orders/order_bloc.dart';
import '../../Blocs/Search/product_search_bloc.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Helper/auto_search.dart';
import '../../Models/FastKey/fastkey_product_model.dart';
import '../../Models/Orders/orders_model.dart';
import '../../Models/Search/product_search_model.dart';
import '../../Repositories/Orders/order_repository.dart';
import '../../Repositories/Search/product_search_repository.dart';
import '../../Utilities/textfield_search.dart';
import '../../Widgets/widget_category_list.dart';
import '../../Widgets/widget_nested_grid_layout.dart';
import '../../Widgets/widget_order_panel.dart';
import '../../Widgets/widget_topbar.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;
import '../../Blocs/FastKey/fastkey_bloc.dart';
import '../../Repositories/FastKey/fastkey_repository.dart';
import '../../Database/fast_key_db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Constants/text.dart';
import '../../Helper/api_response.dart';
import '../../Models/FastKey/fastkey_model.dart';
import '../../Blocs/FastKey/fastkey_product_bloc.dart';
import '../../Repositories/FastKey/fastkey_product_repository.dart';
import '../../Utilities/shimmer_effect.dart';
import '../../Database/db_helper.dart';

enum SidebarPosition { left, right, bottom }
enum OrderPanelPosition { left, right }

class FastKeyScreen extends StatefulWidget {
  final int? lastSelectedIndex;

  const FastKeyScreen({super.key, this.lastSelectedIndex});

  @override
  State<FastKeyScreen> createState() => _FastKeyScreenState();
}

class _FastKeyScreenState extends State<FastKeyScreen> with WidgetsBindingObserver {
  final List<String> items = List.generate(18, (index) => 'Bud Light');
  int _selectedSidebarIndex = 0;
  DateTime now = DateTime.now();
  List<int> quantities = [1, 1, 1, 1];
  SidebarPosition sidebarPosition = SidebarPosition.left;
  OrderPanelPosition orderPanelPosition = OrderPanelPosition.right;
  bool isLoading = true;

  final ValueNotifier<int?> fastKeyTabIdNotifier = ValueNotifier<int?>(null);
  final FastKeyDBHelper fastKeyDBHelper = FastKeyDBHelper();
  late FastKeyBloc _fastKeyBloc;
  List<FastKey> fastKeyTabs = [];
  int? _selectedCategoryIndex;
  int? _editingCategoryIndex;
  int? userId;

  late FastKeyProductBloc _fastKeyProductBloc;
  List<Map<String, dynamic>> fastKeyProductItems = [];
  int? _fastKeyTabId;
  List<int?> reorderedIndices = [];
  int? selectedItemIndex;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  final OrderHelper orderHelper = OrderHelper();
  final DBHelper dbHelper = DBHelper.instance;

  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  Map<String, dynamic>? selectedProduct;
  TextEditingController _productSearchController = TextEditingController();
  final _searchTextGridKey = GlobalKey<TextFieldSearchState>();
  late SearchProduct _autoSuggest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedSidebarIndex = widget.lastSelectedIndex ?? 0;
    _fastKeyBloc = FastKeyBloc(FastKeyRepository());
    _fastKeyProductBloc = FastKeyProductBloc(FastKeyProductRepository());
    _autoSuggest = SearchProduct();
    _productSearchController.addListener(_listenProductItemSearch);

    getUserIdFromDB();
    fastKeyTabIdNotifier.addListener(_onTabChanged);
    _loadActiveFastKeyTabId();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadActiveFastKeyTabId();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadActiveFastKeyTabId();
    }
  }

  void _listenProductItemSearch() {
    if (_productSearchController.text.isEmpty) {
      _searchTextGridKey.currentState?.resetList();
    }
    _autoSuggest.listentextchange(_productSearchController.text ?? "");
  }

  void _onTabChanged() {
    if (kDebugMode) {
      print("### FastKeyScreen: _onTabChanged: New Tab ID: ${fastKeyTabIdNotifier.value}");
    }
    setState(() {
      _fastKeyTabId = fastKeyTabIdNotifier.value;
      fastKeyProductItems.clear();
    });
    _loadFastKeyTabItems();
  }

  Future<void> getUserIdFromDB() async {
    try {
      final userData = await UserDbHelper().getUserData();
      if (userData != null && userData[AppDBConst.userId] != null) {
        userId = userData[AppDBConst.userId] as int;
        _fastKeyBloc.fetchFastKeysByUser(userId ?? 0);
        await _fastKeyBloc.getFastKeysStream.listen((onData) {
          if (onData.data != null) {
            if (onData.status == Status.ERROR) {
              _fastKeyBloc.getFastKeysSink.add(APIResponse.error(TextConstants.retryText));
            } else if (onData.status == Status.COMPLETED) {
              final fastKeysResponse = onData.data!;
              if (fastKeysResponse.status != "success") {
                _fastKeyBloc.getFastKeysSink.add(APIResponse.error(TextConstants.retryText));
              }
              loadTabs();
            }
          }
        });
      } else {
        if (kDebugMode) {
          print("FastKeyScreen: No user ID found in the database.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("FastKeyScreen: Exception in getUserId: $e");
      }
    }
  }

  void loadTabs() async {
    await _loadFastKeysTabs();
    await _loadLastSelectedTab();
  }

  Future<void> _loadLastSelectedTab() async {
    final lastSelectedTabId = await fastKeyDBHelper.getActiveFastKeyTab();
    if (lastSelectedTabId != null) {
      setState(() {
        _selectedCategoryIndex = fastKeyTabs.indexWhere((tab) => tab.fastkeyServerId == lastSelectedTabId);
        if (_selectedCategoryIndex != -1) {
          _fastKeyTabId = lastSelectedTabId;
          fastKeyTabIdNotifier.value = _fastKeyTabId;
        }
      });
    }
  }

  Future<void> _loadFastKeysTabs() async {
    final fastKeyTabsData = await fastKeyDBHelper.getFastKeyTabsByUserId(userId ?? 1);
    if (mounted) {
      setState(() {
        fastKeyTabs = fastKeyTabsData.map((product) {
          return FastKey(
            fastkeyServerId: product[AppDBConst.fastKeyId],
            userId: userId ?? 1,
            fastkeyTitle: product[AppDBConst.fastKeyTabTitle],
            fastkeyImage: product[AppDBConst.fastKeyTabImage],
            fastkeyIndex: product[AppDBConst.fastKeyTabIndex]?.toString() ?? '0',
            itemCount: int.tryParse(product[AppDBConst.fastKeyTabItemCount]?.toString() ?? '0') ?? 0,
          );
        }).toList();
      });
    }
  }

  Future<void> _addFastKeyTab(String title, String image) async {
    final newTabId = await fastKeyDBHelper.addFastKeyTab(userId ?? 1, title, image, 0, 0, 0);
    _fastKeyBloc.createFastKey(title: title, index: fastKeyTabs.length + 1, imageUrl: image, userId: userId ?? 0);
    setState(() {
      fastKeyTabs.add(FastKey(
        fastkeyServerId: newTabId,
        userId: userId ?? 1,
        fastkeyTitle: title,
        fastkeyImage: image,
        fastkeyIndex: (fastKeyTabs.length + 1).toString(),
        itemCount: 0,
      ));
      _selectedCategoryIndex = fastKeyTabs.length - 1;
      _fastKeyTabId = newTabId;
      fastKeyTabIdNotifier.value = newTabId;
    });

    _fastKeyBloc.createFastKeyStream.listen((response) async {
      if (response.status == Status.COMPLETED && response.data != null) {
        await fastKeyDBHelper.updateFastKeyTab(newTabId, {
          AppDBConst.fastKeyServerId: response.data!.fastkeyId,
        });
        await _loadFastKeysTabs();
        await fastKeyDBHelper.saveActiveFastKeyTab(response.data!.fastkeyId);
        fastKeyTabIdNotifier.value = response.data!.fastkeyId;
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _deleteFastKeyTab(int fastKeyProductId) async {
    var tabs = await fastKeyDBHelper.getFastKeyTabsByTabId(fastKeyProductId);
    if (tabs.isEmpty) {
      return;
    }
    var fastKeyServerId = tabs.first[AppDBConst.fastKeyServerId];
    _fastKeyBloc.deleteFastKey(fastKeyServerId);

    setState(() {
      fastKeyTabs.removeWhere((tab) => tab.fastkeyServerId == fastKeyProductId);
      if (_selectedCategoryIndex != null) {
        if (_selectedCategoryIndex! >= fastKeyTabs.length) {
          _selectedCategoryIndex = fastKeyTabs.isNotEmpty ? fastKeyTabs.length - 1 : null;
          _fastKeyTabId = _selectedCategoryIndex != null ? fastKeyTabs[_selectedCategoryIndex!].fastkeyServerId : null;
          fastKeyTabIdNotifier.value = _fastKeyTabId;
        }
      }
      _editingCategoryIndex = null; //Build 1.1.36: Clear edit mode
      if (kDebugMode) {
        print("### FastKeyScreen: Updated UI after tab deletion, new tab count: ${fastKeyTabs.length}");
      }
    });

    await _fastKeyBloc.deleteFastKeyStream.firstWhere((response) => response.status == Status.COMPLETED || response.status == Status.ERROR).then((response) async {
      if (response.status == Status.COMPLETED && response.data?.status == "success") {
        await fastKeyDBHelper.deleteFastKeyTab(fastKeyProductId);
      } else {
        await _loadFastKeysTabs();
      }
    });

    await fastKeyDBHelper.updateFastKeyTabCount(fastKeyProductId, fastKeyTabs.length);
  }

  Future<void> _loadActiveFastKeyTabId() async {
    final lastSelectedTabId = await fastKeyDBHelper.getActiveFastKeyTab();
    if (lastSelectedTabId != null) {
      setState(() {
        _fastKeyTabId = lastSelectedTabId;
        fastKeyTabIdNotifier.value = lastSelectedTabId;
        _selectedCategoryIndex = lastSelectedTabId;
      });
      _loadFastKeyTabItems();
    } else if (fastKeyTabs.isNotEmpty) {
      setState(() {
        _fastKeyTabId = fastKeyTabs[0].fastkeyServerId;
        _selectedCategoryIndex = 0;
        fastKeyTabIdNotifier.value = _fastKeyTabId;
        if (kDebugMode) {
          print("### FastKeyScreen: No active tab found, defaulting to first tab ID: $_fastKeyTabId");
        }
      });
      await fastKeyDBHelper.saveActiveFastKeyTab(_fastKeyTabId);
      await _loadFastKeyTabItems();
    } else {
      _selectedCategoryIndex = 0;
    }
  }

  Future<void> _loadFastKeyTabItems() async {
    if (_fastKeyTabId == null) {
      return;
    }

    var tabs = await fastKeyDBHelper.getFastKeyTabsByTabId(_fastKeyTabId ?? 1);
    if (tabs.isEmpty) {
      setState(() {
        fastKeyProductItems = [];
      });
      return;
    }
    var fastKeyServerId = tabs.first[AppDBConst.fastKeyServerId];
    await _fastKeyProductBloc.fetchProductsByFastKeyId(_fastKeyTabId ?? 1, fastKeyServerId).whenComplete(() async {
      final items = await fastKeyDBHelper.getFastKeyItems(_fastKeyTabId!);
      if (mounted) {
        setState(() {
          fastKeyProductItems = List<Map<String, dynamic>>.from(items);
          reorderedIndices = List.filled(fastKeyProductItems.length, null);
        });
      }
    });
  }

  Future<void> _addFastKeyTabItem(String name, String image, String price) async {
    if (_fastKeyTabId == null) {
      return;
    }
    var tabs = await fastKeyDBHelper.getFastKeyTabsByTabId(_fastKeyTabId ?? 1);
    if (tabs.isEmpty) {
      return;
    }
    var fastKeyServerId = tabs.first[AppDBConst.fastKeyServerId];
    var productsInFastKey = await fastKeyDBHelper.getFastKeyItems(_fastKeyTabId ?? 1);
    var countProductInFastKey = productsInFastKey.length;
    FastKeyProductItem item = FastKeyProductItem(productId: selectedProduct!['id'], slNumber: countProductInFastKey + 1);
    _fastKeyProductBloc.addProducts(fastKeyId: fastKeyServerId, products: [item]);

    await fastKeyDBHelper.addFastKeyItem(
      _fastKeyTabId!,
      name,
      image,
      price,
      selectedProduct!['id'],
      sku: selectedProduct!['sku'] ?? 'N/A',
      variantId: selectedProduct!['variantId'] ?? 'N/A',
      slNumber: countProductInFastKey + 1,
    );

    await fastKeyDBHelper.updateFastKeyTabCount(_fastKeyTabId!, countProductInFastKey + 1);
    await _loadFastKeyTabItems();
  }

  Future<void> _deleteFastKeyTabItem(int fastKeyTabItemId) async {
    if (_fastKeyTabId == null) return;

    await fastKeyDBHelper.deleteFastKeyItem(fastKeyTabItemId);
    await _loadFastKeyTabItems();
    await fastKeyDBHelper.updateFastKeyTabCount(_fastKeyTabId!, fastKeyProductItems.length);

    if (mounted) {
      setState(() {
        _editingCategoryIndex = null; //Build 1.1.36: Reset editing index to prevent edit button persistence
        if (kDebugMode) {
          print("### FastKeyScreen: Cleared _editingCategoryIndex after item deletion");
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? imageFile = await _picker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() {
        _pickedImage = File(imageFile.path);
      });
    }
  }

  void _onItemSelected(int index, bool showAddButton) async {
    final adjustedIndex = index - (showAddButton ? 1 : 0);
    if (adjustedIndex < 0 || adjustedIndex >= fastKeyProductItems.length) return;

    final selectedProduct = fastKeyProductItems[adjustedIndex];
    await orderHelper.addItemToOrder(
      selectedProduct["fast_key_item_name"],
      selectedProduct["fast_key_item_image"],
      selectedProduct["fast_key_item_price"],
      1,
      'SKU${selectedProduct["fast_key_item_name"]}',
      onItemAdded: _createOrder,
    );
  }

  Future<void> _createOrder() async {

    ///check if any active orders before creating new
    var orders = await orderHelper.getOrderById(orderHelper.activeOrderId ?? 0 );
    if (kDebugMode) {
      print("Fast Key screen createOrder - Orders in DB $orders");
    }
    if(orders.first[AppDBConst.orderServerId] != null){
      _refreshOrderList();
      return;
    }

    OrderBloc orderBloc = OrderBloc(OrderRepository());
    ///Create metadata for the order
    OrderMetaData device = OrderMetaData(key: OrderMetaData.posDeviceId, value: "b31b723b92047f4b"); /// need to add code for device id later
    OrderMetaData placedBy = OrderMetaData(key: OrderMetaData.posPlacedBy, value: '${userId ?? 1}');
    List<OrderMetaData> metaData = [device,placedBy];
    ///call create order API
    await orderBloc.createOrder(metaData).whenComplete(() async {
      if (kDebugMode) {
        print('createOrderStream completed');
      }
      _refreshOrderList();
    });

    // orderBloc.createOrderStream.listen((event) async {
    //   if (kDebugMode) {
    //     print('createOrderStream status: ${event.status}');
    //   }
    //   if (event.status == Status.ERROR) {
    //     if (kDebugMode) {
    //       print(
    //           'OrderPanelDBHelper createOrder: completed with ERROR');
    //     }
    //     orderBloc.createOrderSink.add(APIResponse.error(TextConstants.retryText));
    //     orderBloc.dispose();
    //   } else if (event.status == Status.COMPLETED) {
    //     final order = event.data!;
    //     // orderServerId = order.id;
    //     // orderStatus = order.status;
    //     ///update orderServerId to DB
    //     orderHelper.updateServerOrderIDInDB(order.id);
    //     if (kDebugMode) {
    //       print('>>>>>>>>>>> OrderPanelDBHelper Order updated with server order id: ${order.id}');
    //     }
    //     _refreshOrderList();
    //   }
    // });
  }

  void _refreshOrderList() {
    setState(() {});
  }

  Future<void> _showAddItemDialog() async {
    searchController.clear();
    selectedProduct = null;
    searchResults.clear();

    final productBloc = ProductBloc(ProductRepository());

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text(TextConstants.searchAddItemText),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 700,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: TextConstants.searchItemText,
                          hintText: TextConstants.typeSearchText,
                        ),
                        onChanged: (value) {
                          productBloc.fetchProducts(searchQuery: value);
                        },
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<APIResponse<List<ProductResponse>>>(
                        stream: productBloc.productStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            switch (snapshot.data!.status) {
                              case Status.LOADING:
                                return const Center(child: CircularProgressIndicator());
                              case Status.COMPLETED:
                                final products = snapshot.data!.data;
                                if (products == null || products.isEmpty) {
                                  return const Center(child: Text("No products found"));
                                }

                                return SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return ListTile(
                                        leading: product.images != null && product.images!.isNotEmpty
                                            ? Image.network(
                                          product.images!.first,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                        )
                                            : const Icon(Icons.image),
                                        title: Text(product.name ?? 'No Name'),
                                        subtitle: Text('\$${product.price ?? '0.00'}'),
                                        onTap: () {
                                          setStateDialog(() {
                                            selectedProduct = {
                                              'title': product.name ?? 'Unknown',
                                              'image': product.images?.isNotEmpty == true ? product.images!.first : '',
                                              'price': product.regularPrice ?? '0.00',
                                              'id': product.id,
                                              'sku': product.sku ?? 'N/A',
                                            };
                                          });
                                        },
                                        selected: selectedProduct != null && selectedProduct!['id'] == product.id,
                                        selectedTileColor: Colors.grey[300],
                                      );
                                    },
                                  ),
                                );
                              case Status.ERROR:
                                return Center(
                                  child: Text(snapshot.data!.message ?? "Error loading products"),
                                );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  productBloc.dispose();
                  Navigator.of(context).pop();
                },
                child: const Text(TextConstants.cancelText),
              ),
              TextButton(
                onPressed: selectedProduct != null
                    ? () async {
                  if (_fastKeyTabId != null) {
                    await _addFastKeyTabItem(
                      selectedProduct!['title'],
                      selectedProduct!['image'],
                      selectedProduct!['price'],
                    );
                    await fastKeyDBHelper.updateFastKeyTabCount(_fastKeyTabId!, fastKeyProductItems.length);
                    await _loadFastKeyTabItems();
                    if (mounted) {
                      setState(() {});
                    }
                    fastKeyTabIdNotifier?.notifyListeners();
                  }
                  _productSearchController.text = "";
                  productBloc.dispose();
                  Navigator.of(context).pop();
                }
                    : null,
                child: const Text(TextConstants.addText),
              ),
            ],
          );
        });
      },
    ).then((_) {
      productBloc.dispose();
    });
  }

  void _showCategoryDialog({required BuildContext context, int? index}) {
    bool isEditing = index != null;
    TextEditingController nameController = TextEditingController(text: isEditing ? fastKeyTabs[index!].fastkeyTitle : '');
    String imagePath = isEditing ? fastKeyTabs[index!].fastkeyImage : 'assets/default.png';
    bool showError = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return
              AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 0),
                // titlePadding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
                actionsPadding: EdgeInsets.only(right: 24, top: 10),
                // insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing
                          ? TextConstants.editCateText
                          : TextConstants.addFastKeyNameText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                      width: 175,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFFFFF7F7),
                                            blurRadius: 3,
                                            spreadRadius: 3,
                                            offset: Offset(0,0),
                                          ),
                                        ],
                                      ),
                                      child: _buildImageWidget(imagePath)),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      margin: EdgeInsets.all(10.0),
                                      padding: EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 3,
                                            spreadRadius: 3,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          final pickedFile = await ImagePicker()
                                              .pickImage(
                                              source: ImageSource.gallery);
                                          if (pickedFile != null) {
                                            setStateDialog(() =>
                                            imagePath = pickedFile.path);
                                          }
                                        },
                                        child: Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: Colors.red[400],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Upload Image",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // if (!isEditing && showError && imagePath.isEmpty)
                        //   const Padding(
                        //     padding: EdgeInsets.only(top: 8.0),
                        //     child: Text(
                        //       TextConstants.imgRequiredText,
                        //       style: TextStyle(color: Colors.red, fontSize: 12),
                        //     ),
                        //   ),
                        SizedBox(height: 20),
                        Text(
                          "Name",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: TextConstants.categoryNameText,
                              hintStyle: TextStyle(color: Colors.grey[400],fontWeight: FontWeight.bold),
                              errorText: (!isEditing &&
                                  showError &&
                                  nameController.text.isEmpty)
                                  ? TextConstants.categoryNameReqText
                                  : null,
                              errorStyle:
                              const TextStyle(color: Colors.red, fontSize: 12),
                              // suffixIcon: isEditing
                              //     ? const Icon(Icons.edit, size: 18, color: Colors.red)
                              //     : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[400]!),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 16, right: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 50, // Increased button height
                          width: 120, // Added fixed width
                          child: TextButton(
                            onPressed: () {
                              nameController.clear();
                              // setStateDialog(() {
                              //   imagePath = "";
                              //   showError = false;
                              // });
                            },
                            // => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              TextConstants.clearText,
                              style: TextStyle(
                                  color: Colors.red[400],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          height: 50, // Increased button height
                          width: 120, // Added fixed width
                          child: TextButton(
                            onPressed: () async {
                              if (!isEditing && nameController.text.isEmpty) {
                                setStateDialog(() => showError = true);
                                return;
                              }

                              if (isEditing) {
                                // Update existing tab
                                await fastKeyDBHelper.updateFastKeyTab(
                                    fastKeyTabs[index!].fastkeyServerId, {
                                  AppDBConst.fastKeyTabTitle: nameController.text,
                                  AppDBConst.fastKeyTabImage: imagePath,
                                });

                                // Update the local list
                                setState(() {
                                  _editingCategoryIndex = null;
                                  fastKeyTabs[index] = fastKeyTabs[index].copyWith(
                                    fastkeyTitle: nameController.text,
                                    fastkeyImage: imagePath,
                                  );
                                });
                              } else {
                                // Add new FastKey tab to the database
                                await _addFastKeyTab(nameController.text, imagePath);
                              }

                              // Close the dialog
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              isEditing ? TextConstants.saveText : TextConstants.addText,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    TextButton(
                      onPressed: () => _showDeleteConfirmationDialog(index!),
                      child: const Text(TextConstants.deleteText, style: TextStyle(color: Colors.red)),
                    ),
                ],
              );
          },
        );
      },
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.isEmpty) return _safeSvgPicture('assets/password_placeholder.svg');
    if (imagePath.startsWith('assets/') && imagePath.endsWith('.svg')) {
      return _safeSvgPicture(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, height: 80, width: 80, fit: BoxFit.cover);
    } else {
      return Image.file(
        File(imagePath),
        height: 80,
        width: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _safeSvgPicture('assets/password_placeholder.svg'),
      );
    }
  }

  Widget _safeSvgPicture(String assetPath) {
    try {
      return SvgPicture.asset(
        assetPath,
        height: 80,
        width: 80,
        placeholderBuilder: (context) => const Icon(Icons.image, size: 40),
      );
    } catch (e) {
      debugPrint("FastKeyScreen: SVG Parsing Error: $e");
      return Image.asset('assets/default.png', height: 80, width: 80);
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    bool isDeleting = false;
    final product = fastKeyTabs[index];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(TextConstants.deleteTabText),
              content: const Text(TextConstants.deleteConfirmText),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text(TextConstants.noText),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                    setStateDialog(() => isDeleting = true);
                    await _deleteFastKeyTab(product.fastkeyServerId);
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
                  child: isDeleting
                      ? const CircularProgressIndicator()
                      : const Text(TextConstants.yesText, style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fastKeyBloc.dispose();
    _fastKeyProductBloc.dispose();
    _productSearchController.dispose();
    fastKeyTabIdNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    String formattedDate = DateFormat("EEE, MMM d' ${now.year}'").format(now);
    String formattedTime = DateFormat('hh:mm a').format(now);

    final categories = fastKeyTabs.map((tab) {
      return {
        'title': tab.fastkeyTitle,
        'image': tab.fastkeyImage,
        'itemCount': tab.itemCount,
      };
    }).toList();

    // Define showAddButton here to match the value passed to NestedGridWidget
    const bool showAddButton = true;

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
                onItemAdded: _createOrder
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
                      CategoryList(
                        isHorizontal: true,
                        isLoading: isLoading,///Need to handle this from fastKey bloc, add a code to show loading.
                        isAddButtonEnabled: true,
                        categories: categories,
                        selectedIndex: _selectedCategoryIndex,
                        editingIndex: _editingCategoryIndex,
                        onAddButtonPressed: () => _showCategoryDialog(context: context),
                        onCategoryTapped: (index) async {
                          if (kDebugMode) {
                            print("### FastKeyScreen: onCategoryTapped called for index: $index, ID : ${fastKeyTabs[index].fastkeyServerId}");
                          }
                          setState(() {
                            if (_editingCategoryIndex == index) {
                              if (kDebugMode) {
                                print("### FastKeyScreen: Dismissing edit mode for index: $index");
                              }
                              _editingCategoryIndex = null; // Dismiss edit mode if tapping the same index
                            } else {
                              _selectedCategoryIndex = index; // Select new category
                              _editingCategoryIndex = null; // Ensure edit mode is cleared
                            }
                          });
                          await fastKeyDBHelper.saveActiveFastKeyTab(fastKeyTabs[index].fastkeyServerId);
                          fastKeyTabIdNotifier.value = fastKeyTabs[index].fastkeyServerId;
                        },
                        onReorder: (oldIndex, newIndex) async {
                          if (kDebugMode) {
                            print("### FastKeyScreen: onReorder called from $oldIndex to $newIndex");
                          }
                          setState(() {
                            final item = fastKeyTabs.removeAt(oldIndex);
                            fastKeyTabs.insert(newIndex, item);
                            if (_selectedCategoryIndex == oldIndex) {
                              _selectedCategoryIndex = newIndex;
                            } else if (oldIndex < _selectedCategoryIndex! && newIndex >= _selectedCategoryIndex!) {
                              _selectedCategoryIndex = _selectedCategoryIndex! - 1;
                            } else if (oldIndex > _selectedCategoryIndex! && newIndex <= _selectedCategoryIndex!) {
                              _selectedCategoryIndex = _selectedCategoryIndex! + 1;
                            }
                            //Build 1.1.36: Update editingIndex to the new position
                            if (_editingCategoryIndex == oldIndex) {
                              _editingCategoryIndex = newIndex;
                            }
                          });
                          // Update indices in the database
                          for (int i = 0; i < fastKeyTabs.length; i++) {
                            await fastKeyDBHelper.updateFastKeyTab(fastKeyTabs[i].fastkeyServerId, {
                              AppDBConst.fastKeyTabIndex: i.toString(),
                            });
                          }
                        },
                        onReorderStarted: (index) {
                          if (kDebugMode) {
                            print("### FastKeyScreen: onReorderStarted called for index: $index");
                          }
                          setState(() {
                            _editingCategoryIndex = index; // Set editing index for the item being reordered
                          });
                        },
                        onEditButtonPressed: (index) {
                          if (kDebugMode) {
                            print("### FastKeyScreen: onEditButtonPressed called for index: $index");
                          }
                          setState(() {
                            _editingCategoryIndex = index; // Set editing index for the item
                          });
                          _showCategoryDialog(context: context, index: index);
                        },
                        onDismissEditMode: () {
                          if (kDebugMode) {
                            print("### FastKeyScreen: onDismissEditMode called");
                          }
                          setState(() {
                            _editingCategoryIndex = null; // Clear editing index
                          });
                        },
                      ),
                      ValueListenableBuilder<int?>(
                        valueListenable: fastKeyTabIdNotifier,
                        builder: (context, fastKeyTabId, child) {
                          return NestedGridWidget(
                            isHorizontal: true,
                            isLoading: isLoading,
                            showAddButton: showAddButton,
                            items: fastKeyProductItems,
                            selectedItemIndex: selectedItemIndex,
                            reorderedIndices: reorderedIndices,
                            onAddButtonPressed: () => _showAddItemDialog(),
                            onItemTapped: (index, {bool variantAdded = false}) => _onItemSelected(index, showAddButton),                            onReorder: (oldIndex, newIndex) {
                              if (oldIndex == 0 || newIndex == 0) return;
                              final adjustedOldIndex = oldIndex - 1;
                              final adjustedNewIndex = newIndex - 1;
                              if (adjustedOldIndex < 0 ||
                                  adjustedNewIndex < 0 ||
                                  adjustedOldIndex >= fastKeyProductItems.length ||
                                  adjustedNewIndex >= fastKeyProductItems.length) {
                                return;
                              }
                              setState(() {
                                fastKeyProductItems = List<Map<String, dynamic>>.from(fastKeyProductItems);
                                final item = fastKeyProductItems.removeAt(adjustedOldIndex);
                                fastKeyProductItems.insert(adjustedNewIndex, item);
                                reorderedIndices = List.filled(fastKeyProductItems.length, null);
                                reorderedIndices[adjustedNewIndex] = adjustedNewIndex;
                                selectedItemIndex = adjustedNewIndex;
                              });
                            },
                            onDeleteItem: (index) {
                              final itemId = fastKeyProductItems[index]["fast_key_item_id"];
                              _deleteFastKeyTabItem(itemId);
                            },
                            onCancelReorder: () {
                              setState(() {
                                reorderedIndices = List.filled(fastKeyProductItems.length, null);
                              });
                            }, showBackButton: false,
                          );
                        },
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
