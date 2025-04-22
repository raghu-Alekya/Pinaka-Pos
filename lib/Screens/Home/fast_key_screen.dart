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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pinaka_pos/Blocs/FastKey/fastkey_bloc.dart';
import 'package:pinaka_pos/Repositories/FastKey/fastkey_repository.dart';
import 'dart:io';
import '../../Blocs/FastKey/fastkey_product_bloc.dart';
import '../../Database/order_panel_db_helper.dart';
import '../../Database/db_helper.dart';
import '../../Database/fast_key_db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Helper/file_helper.dart';
import '../../Models/FastKey/fastkey_model.dart';
import '../../Models/FastKey/fastkey_product_model.dart';
import '../../Repositories/FastKey/fastkey_product_repository.dart';
import '../../Utilities/shimmer_effect.dart';
import '../../Constants/text.dart';
import '../../Helper/api_response.dart';
import '../../Widgets/widget_category_list.dart';
import '../../Widgets/widget_nested_grid_layout.dart';
import '../../Widgets/widget_order_panel.dart';
import '../../Widgets/widget_topbar.dart';
import '../../Widgets/widget_navigation_bar.dart' as custom_widgets;

enum SidebarPosition { left, right, bottom }
enum OrderPanelPosition { left, right }

class FastKeyScreen extends StatefulWidget { // Build #1.0.21 - Updated code with complete business logic here
  final int? lastSelectedIndex;

  const FastKeyScreen({super.key, this.lastSelectedIndex});

  @override
  State<FastKeyScreen> createState() => _FastKeyScreenState();
}

class _FastKeyScreenState extends State<FastKeyScreen> {
  final List<String> items = List.generate(18, (index) => 'Bud Light');
  int _selectedSidebarIndex = 0;
  DateTime now = DateTime.now();
  List<int> quantities = [1, 1, 1, 1];
  SidebarPosition sidebarPosition = SidebarPosition.left;
  OrderPanelPosition orderPanelPosition = OrderPanelPosition.right;
  bool isLoading = true;
  final OrderHelper orderHelper = OrderHelper();

  // FastKey related state
  final ValueNotifier<int?> fastKeyTabIdNotifier = ValueNotifier<int?>(null);
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = true;
  int? _selectedIndex;
  int? _editingIndex;
  int? userId;
  int? _fastKeyTabId;
  final FastKeyDBHelper fastKeyDBHelper = FastKeyDBHelper();
  final DBHelper dbHelper = DBHelper.instance;

  late FastKeyBloc _fastKeyBloc;
  late FastKeyProductBloc _fastKeyProductBloc;

  List<FastKey> fastKeyTabs = [];
  Map<String, dynamic>? selectedProduct;
  List<Map<String, dynamic>> fastKeyProductItems = [];

  bool _isCategoryLoading = false;

  @override
  void initState() {
    super.initState();
    _fastKeyBloc = FastKeyBloc(FastKeyRepository());
    _fastKeyProductBloc = FastKeyProductBloc(FastKeyProductRepository());

    _selectedSidebarIndex = widget.lastSelectedIndex ?? 0;

    _scrollController.addListener(() {
      setState(() {
        _showLeftArrow = _scrollController.offset > 0;
        _showRightArrow = _scrollController.offset < _scrollController.position.maxScrollExtent;
      });
    });

    fastKeyTabIdNotifier.addListener(_onTabChanged);
    getUserIdFromDB();

    Future.delayed(const Duration(seconds: 3), () {
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  bool _doesContentOverflow(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = fastKeyTabs.length * 120;
    return contentWidth > screenWidth;
  }

  Future<void> getUserIdFromDB() async {
    try {
      final userData = await UserDbHelper().getUserData();
      if (userData != null && userData[AppDBConst.userId] != null) {
        userId = userData[AppDBConst.userId] as int;
        if (kDebugMode) {
          print("#### userId from DB: $userId");
        }
        _fastKeyBloc.fetchFastKeysByUser(userId ?? 0);
        await _fastKeyBloc.getFastKeysStream.listen((onData){
          if(onData.data != null && onData.status == Status.COMPLETED) {
            loadTabs();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Exception in getUserId: $e");
      }
    }
  }

  void loadTabs() async {
    await _loadFastKeysTabs();
    await _loadLastSelectedTab();
  }

  void _onTabChanged() {
    if (kDebugMode) {
      print("### _onTabChanged: New Tab ID: ${fastKeyTabIdNotifier.value}");
    }
    _loadFastKeysTabs().then((_) {
      if (mounted) {
        setState(() {
          _fastKeyTabId = fastKeyTabIdNotifier.value;
          fastKeyDBHelper.saveActiveFastKeyTab(_fastKeyTabId); // Save the active tab ID
          _loadFastKeyTabItems(); // Reload items when the tab changes
        });
      }
    });
  }

  Future<void> _loadLastSelectedTab() async {
    final lastSelectedTabId = await FastKeyDBHelper().getActiveFastKeyTab();
    if (kDebugMode) {
      print("#### fastKeyHelper.getFastKeyTabFromPref: $lastSelectedTabId");
    }
    if (lastSelectedTabId != null) {
      setState(() {
        _selectedIndex = fastKeyTabs.indexWhere((tab) => tab.fastkeyServerId == lastSelectedTabId);
      });
    }

    setState(() {
      _fastKeyTabId = lastSelectedTabId;
    });
    if (kDebugMode) {
      print("### _loadActiveFastKeyTabId: _fastKeyTabId set to $_fastKeyTabId");
    }
    _loadFastKeyTabItems();
  }

  Future<void> _loadFastKeysTabs() async {
    final fastKeyTabsData = await FastKeyDBHelper().getFastKeyTabsByUserId(userId ?? 1);
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

  Future<void> _addFastKeyTab(String title, String image) async {
    setState(() => _isCategoryLoading = true);
    final newTabId = await FastKeyDBHelper().addFastKeyTab(userId ?? 1, title, image, 0, 0, 0);
    _fastKeyBloc.createFastKey(title: title, index: fastKeyTabs.length+1, imageUrl: image, userId: userId ?? 0);

    setState(() {
      fastKeyTabs.add(FastKey(
        fastkeyServerId: newTabId,
        userId: userId ?? 1,
        fastkeyTitle: title,
        fastkeyImage: image,
        fastkeyIndex: (fastKeyTabs.length + 1).toString(),
        itemCount: 0,
      ));
      _selectedIndex = fastKeyTabs.length - 1;
    });

    _fastKeyBloc.createFastKeyStream.listen((response) async {
      if (response.status == Status.COMPLETED && response.data != null) {
        await FastKeyDBHelper().updateFastKeyTab(newTabId, {
          AppDBConst.fastKeyServerId: response.data!.fastkeyId,
        });
        await _loadFastKeysTabs();
        await FastKeyDBHelper().saveActiveFastKeyTab(response.data!.fastkeyId);
        fastKeyTabIdNotifier.value = response.data!.fastkeyId;
      }
      if (mounted) {
        setState(() => _isCategoryLoading = false);
      }
    });
  }

  Future<void> _deleteFastKeyTab(int fastKeyProductId) async {
    var tabs = await FastKeyDBHelper().getFastKeyTabsByTabId(fastKeyProductId);
    if(tabs.isEmpty) return;
    var fastKeyServerId = tabs.first[AppDBConst.fastKeyServerId];

    _fastKeyBloc.deleteFastKey(fastKeyServerId);
    setState(() {
      fastKeyTabs.removeWhere((tab) => tab.fastkeyServerId == fastKeyProductId);
      if (_selectedIndex != null) {
        if (_selectedIndex! >= fastKeyTabs.length) {
          _selectedIndex = fastKeyTabs.isNotEmpty ? fastKeyTabs.length - 1 : null;
        }
        fastKeyTabIdNotifier.value = _selectedIndex != null
            ? fastKeyTabs[_selectedIndex!].fastkeyServerId
            : null;
      }
    });

    await _fastKeyBloc.deleteFastKeyStream.firstWhere((response) =>
    response.status == Status.COMPLETED || response.status == Status.ERROR
    ).then((response) async {
      if (response.status == Status.COMPLETED && response.data?.status == "success") {
        await FastKeyDBHelper().deleteFastKeyTab(fastKeyProductId);
      } else {
        await _loadFastKeysTabs();
      }
    });
    await FastKeyDBHelper().updateFastKeyTabCount(fastKeyProductId, fastKeyTabs.length);
  }

  Future<void> _loadFastKeyTabItems() async {
    if (_fastKeyTabId == null) {
      if (kDebugMode) {
        print("### _fastKeyTabId is null, cannot load items");
      }
      return;
    }

    ///1. Get the active fastkey server id from _fastKeyTabId
    var tabs = await fastKeyDBHelper.getFastKeyTabsByTabId(_fastKeyTabId ?? 1);
    if(tabs.length == 0){
      return;
    }
    var fastKeyServerId = tabs.first[AppDBConst.fastKeyServerId];
    ///2. call 'Get Fast Key products by Fast Key ID' API

    await _fastKeyProductBloc.fetchProductsByFastKeyId(_fastKeyTabId ?? 1, fastKeyServerId).whenComplete(() async {
      ///3. load products from API into DB
      final items = await fastKeyDBHelper.getFastKeyItems(_fastKeyTabId!);
      setState(() {
        fastKeyProductItems = List<Map<String, dynamic>>.from(items);
       // reorderedIndices = List.filled(fastKeyProductItems.length, null); // Resize reorderedIndices
      });
    });

  }

Future<void> _addFastKeyTabItem(String name, String image, String price) async {
    if (_fastKeyTabId == null) {
      if (kDebugMode) {
        print("### _fastKeyTabId is null, cannot add item");
      }
      return;
    }
    if (kDebugMode) {
      print("### _addFastKeyTabItem _fastKeyTabId: $_fastKeyTabId");
    }
    ///Add a logic to add to API then push to DB and final load from DB
    ///1. get fastkey_server_id from DB and use for step 2
    var tabs = await fastKeyDBHelper.getFastKeyTabsByTabId(_fastKeyTabId ?? 1);
    if(tabs.length == 0){
      return;
    }
    var fastKeyServerId = tabs.first[AppDBConst.fastKeyServerId];

    ///2. get list of products in this tab from db
    var productsInFastKey = await fastKeyDBHelper.getFastKeyItems(_fastKeyTabId ?? 1);
    var countProductInFastKey = productsInFastKey.length;

    ///3. create a FastKeyProductItem and pass to add product
    FastKeyProductItem item = FastKeyProductItem(productId: selectedProduct!['id'], slNumber: countProductInFastKey+1);
    ///4. call add fast keys product API
    _fastKeyProductBloc.addProducts(fastKeyId: fastKeyServerId, products: [item]);

    if (kDebugMode) {
      print("save product $name in DB");
    }
    ///5. save to DB along with productid and index
    await fastKeyDBHelper.addFastKeyItem(
      _fastKeyTabId!,
      name,
      image,
      price,
      selectedProduct!['id'], // productId
      sku: selectedProduct!['sku'] ?? 'N/A',
      variantId: selectedProduct!['variantId'] ?? 'N/A',
      slNumber: countProductInFastKey + 1,
    );

    // Update count and reload
    await fastKeyDBHelper.updateFastKeyTabCount(_fastKeyTabId!, countProductInFastKey + 1);
    await _loadFastKeyTabItems();

    await _loadFastKeyTabItems(); // Reload items after adding
    // Call setState synchronously after all async operations
    if (mounted) {
      setState(() {});
    }
    fastKeyTabIdNotifier.notifyListeners(); // Notify listeners
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return SvgPicture.asset(
        imagePath,
        height: 40,
        width: 40,
        placeholderBuilder: (context) => Icon(Icons.image, size: 40),
      );
    } else {
      return Image.file(
        File(imagePath),
        height: 40,
        width: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.image, size: 40);
        },
      );
    }
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

  void _showCategoryDialog({required BuildContext context, int? index}) {
    bool isEditing = index != null;
    TextEditingController nameController = TextEditingController(
        text: isEditing ? fastKeyTabs[index!].fastkeyTitle : '');
    String imagePath = isEditing ? fastKeyTabs[index!].fastkeyImage : 'assets/default.png';
    bool showError = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? TextConstants.editCateText : TextConstants.addCateText),
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
                                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setStateDialog(() => imagePath = pickedFile.path);
                                  }
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
                          labelText: TextConstants.nameText,
                          errorText: (!isEditing && showError && nameController.text.isEmpty)
                              ? TextConstants.nameReqText
                              : null,
                        ),
                      ),
                      if (isEditing)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${TextConstants.itemCountText} ${fastKeyTabs[index].itemCount}',
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
                  child: const Text(TextConstants.cancelText),
                ),
                TextButton(
                  onPressed: () async {
                    if (!isEditing && nameController.text.isEmpty) {
                      setStateDialog(() => showError = true);
                      return;
                    }
                    if (isEditing) {
                      await FastKeyDBHelper().updateFastKeyTab(
                          fastKeyTabs[index!].fastkeyServerId,
                          {
                            AppDBConst.fastKeyTabTitle: nameController.text,
                            AppDBConst.fastKeyTabImage: imagePath,
                          }
                      );
                      setState(() {
                        _editingIndex = null;
                        fastKeyTabs[index] = fastKeyTabs[index].copyWith(
                          fastkeyTitle: nameController.text,
                          fastkeyImage: imagePath,
                        );
                      });
                    } else {
                      await _addFastKeyTab(nameController.text, imagePath);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(TextConstants.saveText),
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
      debugPrint("SVG Parsing Error: $e");
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
                  onPressed: isDeleting ? null : () async {
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

  void _refreshOrderList() {
    setState(() {
      if (kDebugMode) {
        print("###### FastKeyScreen _refreshOrderList");
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
          ),
          Divider(color: Colors.grey, thickness: 0.4, height: 1),
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
                      // Simplified CategoryList widget
                      _buildCategoryList(context),

                      ValueListenableBuilder<int?>(
                        valueListenable: fastKeyTabIdNotifier,
                        builder: (context, fastKeyTabId, child) {
                          return NestedGridWidget(
                            isHorizontal: true,
                            isLoading: isLoading,
                            onItemAdded: _refreshOrderList,
                            fastKeyTabIdNotifier: fastKeyTabIdNotifier,
                            items: fastKeyProductItems,
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

  Widget _buildCategoryList(BuildContext context) {
    if (_isCategoryLoading) {
      return ShimmerEffect.rectangular(height: 100);
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: isLoading
          ? ShimmerEffect.rectangular(height: 100)
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
            duration: Duration(milliseconds: 1000),
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
            }) : SizedBox.shrink(),
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
                    final item = fastKeyTabs.removeAt(oldIndex);
                    fastKeyTabs.insert(newIndex, item);
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
                children: List.generate(fastKeyTabs.length, (index) {
                  final product = fastKeyTabs[index];
                  bool isSelected = _selectedIndex == index;
                  bool showEditButton = _editingIndex == index;

                  return GestureDetector(
                    key: ValueKey('${product.fastkeyTitle}_$index'),
                    onTap: () async {
                      setState(() {
                        if (_editingIndex == index) {
                          _editingIndex = null;
                        } else if (_selectedIndex == index) {
                          return;
                        } else {
                          _selectedIndex = index;
                        }
                      });
                      if (_editingIndex == null) {
                        await FastKeyDBHelper().saveActiveFastKeyTab(product.fastkeyServerId);
                        fastKeyTabIdNotifier.value = product.fastkeyServerId;
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
                                    decoration: BoxDecoration(
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
                                _buildImage(product.fastkeyImage),
                                const SizedBox(height: 8),
                                Text(
                                  product.fastkeyTitle,
                                  maxLines: 1,
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  product.itemCount.toString(),
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
            duration: Duration(milliseconds: 1000),
            transitionBuilder: (widget, animation) {
              return FadeTransition(opacity: animation, child: widget);
            },
            child: _showLeftArrow && _doesContentOverflow(context)
                ? _buildScrollButton(Icons.arrow_forward_ios, () {
              _scrollController.animateTo(
                _scrollController.offset + size.width,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }) : SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          _buildScrollButton(Icons.add, () {
            _showCategoryDialog(context: context);
          }),
        ],
      ),
    );
  }
}


