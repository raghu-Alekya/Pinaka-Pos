// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:pinaka_pos/Models/FastKey/fastkey_product_model.dart';
// import 'package:pinaka_pos/Utilities/textfield_search.dart';
// import 'package:reorderable_grid_view/reorderable_grid_view.dart';
//
// import '../Blocs/Search/product_search_bloc.dart';
// import '../Constants/text.dart';
// import '../Database/db_helper.dart';
// import '../Database/fast_key_db_helper.dart';
// import '../Database/order_panel_db_helper.dart';
// import '../Helper/auto_search.dart';
// import '../Helper/api_response.dart';
// import '../Models/Search/product_search_model.dart';
// import '../Repositories/Search/product_search_repository.dart';
// import '../Utilities/shimmer_effect.dart';
// import 'package:pinaka_pos/Blocs/FastKey/fastkey_product_bloc.dart';
// import 'package:pinaka_pos/Repositories/FastKey/fastkey_product_repository.dart';
//
// class NestedGridWidget extends StatefulWidget {
//   final bool isHorizontal;
//   final bool isLoading;
//   final VoidCallback? onItemAdded;
//   final ValueNotifier<int?> fastKeyTabIdNotifier;
//   final bool showAddButton; // Build #1.0.12: New parameter to control add button visibility in category screen
//
//   const NestedGridWidget({
//     super.key,
//     required this.isHorizontal,
//     this.isLoading = false,
//     this.onItemAdded,
//     required this.fastKeyTabIdNotifier,
//     this.showAddButton = true, // Default to true for backward compatibility
//   });
//
//   @override
//   _NestedGridWidgetState createState() => _NestedGridWidgetState();
// }
//
// class _NestedGridWidgetState extends State<NestedGridWidget> {
//   List<List<Map<String, dynamic>>> nestedItems = [
//     [
//       {"id": 101, "title": "Apple", "icon": Icons.apple, "price": "\$0.99", "image": "https://via.placeholder.com/50"},
//       {"id": 102, "title": "Banana", "icon": Icons.local_grocery_store, "price": "\$1.99", "image": "https://via.placeholder.com/50"},
//       {"id": 103, "title": "Carrot", "icon": Icons.eco, "price": "\$2.99", "image": "https://via.placeholder.com/50"},
//     ],
//     [
//       {"id": 104, "title": "Milk", "icon": Icons.local_drink, "price": "\$3.99", "image": "https://via.placeholder.com/50"},
//       {"id": 105, "title": "Bread", "icon": Icons.bakery_dining, "price": "\$4.99", "image": "https://via.placeholder.com/50"},
//       {"id": 106, "title": "Cheese", "icon": Icons.lunch_dining, "price": "\$5.99", "image": "https://via.placeholder.com/50"},
//     ],
//   ];
//
//   int currentLevel = 0;
//   List<String> navigationPath = ["Home"];
//   bool isLoading = false;
//   List<int?> reorderedIndices = [];
//   int? selectedItemIndex;
//   int? _fastKeyTabId;
//
//   File? _pickedImage;
//   final ImagePicker _picker = ImagePicker();
//   final OrderHelper orderHelper = OrderHelper();
//   final FastKeyDBHelper fastKeyDBHelper = FastKeyDBHelper();
//   final DBHelper dbHelper = DBHelper.instance;
//
//   List<Map<String, dynamic>> fastKeyProductItems = [];
//   final TextEditingController searchController = TextEditingController();
//   List<Map<String, dynamic>> searchResults = [];
//   Map<String, dynamic>? selectedProduct;
//
//   TextEditingController _productSearchController = TextEditingController();
//   final _searchTextGridKey = GlobalKey<TextFieldSearchState>();
//   late SearchProduct _autoSuggest;
//   late FastKeyProductBloc _fastKeyProductBloc;
//
//   @override
//   void initState() {
//     super.initState();
//     _fastKeyProductBloc = FastKeyProductBloc(FastKeyProductRepository());
//     reorderedIndices = List.filled(fastKeyProductItems.length, null);
//     _loadActiveFastKeyTabId().then((_) { // Build #1.0.12: fixed fast key tab related issues
//       widget.fastKeyTabIdNotifier.addListener(_onTabChanged);
//     });
//     _autoSuggest= SearchProduct();
//     _productSearchController.addListener(_listenProductItemSearch);
//   }
//
//   _listenProductItemSearch(){
//     if(_productSearchController.text.isEmpty) {
//       _searchTextGridKey.currentState?.resetList();
//     }
//     _autoSuggest.listentextchange(_productSearchController.text ?? "");
//   }
//
//
//   void _onTabChanged() { // Build #1.0.12: fixed fast key tab related issues
//     if (kDebugMode) {
//       print("### _onTabChanged: New Tab ID: ${widget.fastKeyTabIdNotifier.value}");
//     }
//     if (widget.fastKeyTabIdNotifier.value == null) {
//       if (kDebugMode) {
//         print("### _onTabChanged: Tab ID is null, skipping update");
//       }
//       return;
//     }
//     setState(() {
//       _fastKeyTabId = widget.fastKeyTabIdNotifier.value;
//     });
//     fastKeyDBHelper.saveActiveFastKeyTab(_fastKeyTabId); // Save the active tab ID
//     _loadFastKeyTabItems(); // Reload items when the tab changes
//   }
//
//   @override
//   void dispose() {
//     widget.fastKeyTabIdNotifier.removeListener(_onTabChanged);
//     super.dispose();
//   }
//
//   Future<void> _loadActiveFastKeyTabId() async {
//     final lastSelectedTabId = await fastKeyDBHelper.getActiveFastKeyTab();
//     if (kDebugMode) {
//       print("### _loadActiveFastKeyTabId: Last Selected Tab ID: $lastSelectedTabId");
//     }
//     setState(() {
//       _fastKeyTabId = lastSelectedTabId;
//     });
//     if (kDebugMode) {
//       print("### _loadActiveFastKeyTabId: _fastKeyTabId set to $_fastKeyTabId");
//     }
//     _loadFastKeyTabItems();
//   }
//
//   Future<void> _loadFastKeyTabItems() async {
//     if (_fastKeyTabId == null) {
//       if (kDebugMode) {
//         print("### _fastKeyTabId is null, cannot load items");
//       }
//       return;
//     }
//
//     ///1. Get the active fastkey server id from _fastKeyTabId
//     var tabs = await fastKeyDBHelper.getFastKeyTabsByTabId(_fastKeyTabId ?? 1);
//     if(tabs.length == 0){
//       return;
//     }
//     var fastKeyServerId = tabs.first[AppDBConst.fastKeyServerId];
//     ///2. call 'Get Fast Key products by Fast Key ID' API
//
//     await _fastKeyProductBloc.fetchProductsByFastKeyId(_fastKeyTabId ?? 1, fastKeyServerId).whenComplete(() async {
//       ///3. load products from API into DB
//       final items = await fastKeyDBHelper.getFastKeyItems(_fastKeyTabId!);
//       setState(() {
//         fastKeyProductItems = List<Map<String, dynamic>>.from(items);
//         reorderedIndices = List.filled(fastKeyProductItems.length, null); // Resize reorderedIndices
//       });
//     });
//
//   }
//
//   Future<void> _addFastKeyTabItem(String name, String image, String price) async {
//     if (_fastKeyTabId == null) {
//       if (kDebugMode) {
//         print("### _fastKeyTabId is null, cannot add item");
//       }
//       return;
//     }
//     if (kDebugMode) {
//       print("### _addFastKeyTabItem _fastKeyTabId: $_fastKeyTabId");
//     }
//     ///Add a logic to add to API then push to DB and final load from DB
//     ///1. get fastkey_server_id from DB and use for step 2
//     var tabs = await fastKeyDBHelper.getFastKeyTabsByTabId(_fastKeyTabId ?? 1);
//     if(tabs.length == 0){
//       return;
//     }
//     var fastKeyServerId = tabs.first[AppDBConst.fastKeyServerId];
//
//     ///2. get list of products in this tab from db
//     var productsInFastKey = await fastKeyDBHelper.getFastKeyItems(_fastKeyTabId ?? 1);
//     var countProductInFastKey = productsInFastKey.length;
//
//     ///3. create a FastKeyProductItem and pass to add product
//     FastKeyProductItem item = FastKeyProductItem(productId: selectedProduct!['id'], slNumber: countProductInFastKey+1);
//     ///4. call add fast keys product API
//     _fastKeyProductBloc.addProducts(fastKeyId: fastKeyServerId, products: [item]);
//
//     if (kDebugMode) {
//       print("save product $name in DB");
//     }
//     ///5. save to DB along with productid and index
//     await fastKeyDBHelper.addFastKeyItem(
//       _fastKeyTabId!,
//       name,
//       image,
//       price,
//       selectedProduct!['id'], // productId
//       sku: selectedProduct!['sku'] ?? 'N/A',
//       variantId: selectedProduct!['variantId'] ?? 'N/A',
//       slNumber: countProductInFastKey + 1,
//     );
//
//     // Update count and reload
//     await fastKeyDBHelper.updateFastKeyTabCount(_fastKeyTabId!, countProductInFastKey + 1);
//     await _loadFastKeyTabItems();
//
//     await _loadFastKeyTabItems(); // Reload items after adding
//     // Call setState synchronously after all async operations
//     if (mounted) {
//       setState(() {});
//     }
//     widget.fastKeyTabIdNotifier.notifyListeners(); // Notify listeners
//   }
//
//   Future<void> _deleteFastKeyTabItem(int fastKeyTabItemId) async { // Build #1.0.11
//     if (_fastKeyTabId == null) return;
//
//     await fastKeyDBHelper.deleteFastKeyItem(fastKeyTabItemId);
//     await _loadFastKeyTabItems(); // Reload items after deleting
//     await fastKeyDBHelper.updateFastKeyTabCount(_fastKeyTabId!, fastKeyProductItems.length);
//
//     // Call setState synchronously after all async operations
//     if (mounted) {
//       setState(() {});
//     }
//
//     widget.fastKeyTabIdNotifier.notifyListeners(); // Notify listeners
//   }
//
//   Future<void> _pickImage() async {
//     final XFile? imageFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (imageFile != null) {
//       setState(() {
//         _pickedImage = File(imageFile.path);
//       });
//     }
//   }
//
//   void _onItemSelected(int index) async {
//     if (kDebugMode) {
//       print("Item selected: $index");
//     }
//     if (currentLevel + 1 < navigationPath.length) {
//       setState(() {
//         currentLevel++;
//         navigationPath.add(fastKeyProductItems[index]["fast_key_item_name"]);
//       });
//     } else {
//       final selectedProduct = fastKeyProductItems[index];
//       if (kDebugMode) {
//         print("Selected Product: $selectedProduct");
//       }
//
//       // Generate a unique key for each item to prevent merging
//     //  final uniqueKey = DateTime.now().millisecondsSinceEpoch.toString();
//
//       await orderHelper.addItemToOrder(
//         selectedProduct["fast_key_item_name"],
//         selectedProduct["fast_key_item_image"],
//         selectedProduct["fast_key_item_price"],
//         1, // Default quantity
//         'SKU${selectedProduct["fast_key_item_name"]}', // Build #1.0.13 : Fix - Fast key tab item issue
//         onItemAdded: widget.onItemAdded,
//       );
//
//       if (kDebugMode) {
//         print("Item added to order successfully!");
//       }
//     }
//   }
//
//   void _onBackPressed() {
//     if (currentLevel > 0) {
//       setState(() {
//         currentLevel--;
//         navigationPath.removeLast();
//       });
//     }
//   }
//
//   void _onNavigationPathTapped(int index) {
//     if (index < currentLevel) {
//       setState(() {
//         currentLevel = index;
//         navigationPath = navigationPath.sublist(0, index + 1);
//       });
//     }
//   }
//
//   Future<void> _deleteItem(int itemIndex) async {
//     final itemId = fastKeyProductItems[itemIndex]["fast_key_item_id"];
//     await _deleteFastKeyTabItem(itemId);
//   }
//
//   // Replace the existing searchProducts method with this:
//   Future<void> searchProducts(String query, StateSetter setStateDialog) async {
//     if (query.isEmpty) {
//       setStateDialog(() {
//         searchResults.clear();
//       });
//       return;
//     }
//     // This is now handled by the ProductBloc in the StreamBuilder
//     // So we don't need to manually set searchResults here
//   }
//
//   // Update the _showAddItemDialog method in NestedGridWidget
//   Future<void> _showAddItemDialog(int listIndex) async {
//     searchController.clear(); // Clear the search text
//     selectedProduct = null; // Reset the selected product
//     searchResults.clear(); // Clear previous search results
//
//     // Initialize ProductBloc
//     final productBloc = ProductBloc(ProductRepository());
//
//     return showDialog<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(builder: (context, setStateDialog) {
//           return AlertDialog(
//             title: const Text(TextConstants.searchAddItemText),
//             content: SingleChildScrollView(
//               child: SizedBox(
//                 width: 300,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: searchController,
//                       decoration: const InputDecoration(
//                         labelText: TextConstants.searchItemText,
//                         hintText: TextConstants.typeSearchText,
//                       ),
//                       onChanged: (value) {
//                         // Call fetchProducts with search query
//                         productBloc.fetchProducts(searchQuery: value);
//                       },
//                     ),
//                     TextFieldSearch(
//                       label: "Search Product",
//                       controller: _productSearchController,
//                       key: _searchTextGridKey,
//                       minStringLength: 0,
//                       itemsInView: 5,
//                       future: () { return _autoSuggest.getProductResults();},
//                       getSelectedValue: (item) async {
//                         if (item is ProductItem) {
//                           _productSearchController.text = item.label;
//                           var product = item.value;
//                           // Update where selectedProduct is set to include all required fields
//                           setStateDialog(() {
//                             selectedProduct = {
//                               'title': product.name ?? 'Unknown',
//                               'image': product.images?.isNotEmpty == true ? product.images!.first : '',
//                               'price': product.regularPrice ?? '0.00',
//                               'id': product.id,
//                               'sku': product.sku ?? 'N/A',
//                               'variantId': product.variantId ?? 'N/A',
//                             };
//                           });
//
//                           FocusManager.instance.primaryFocus?.unfocus();
//                         }
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     StreamBuilder<APIResponse<List<ProductResponse>>>( // Build #1.0.13 : auto search for product item in alert when tap on add item in grid
//                       stream: productBloc.productStream,
//                       builder: (context, snapshot) {
//                         if (snapshot.hasData) {
//                           switch (snapshot.data!.status) {
//                             case Status.LOADING:
//                               return const Center(child: CircularProgressIndicator());
//                             case Status.COMPLETED:
//                               final products = snapshot.data!.data;
//                               if (products == null || products.isEmpty) {
//                                 return const Center(child: Text("No products found"));
//                               }
//
//                               return SizedBox(
//                                 height: 200,
//                                 child: ListView.builder(
//                                   shrinkWrap: true,
//                                   physics: const BouncingScrollPhysics(),
//                                   itemCount: products.length,
//                                   itemBuilder: (context, index) {
//                                     final product = products[index];
//                                     return ListTile(
//                                       leading: product.images != null && product.images!.isNotEmpty
//                                           ? Image.network(
//                                         product.images!.first,
//                                         width: 50,
//                                         height: 50,
//                                         fit: BoxFit.cover,
//                                         errorBuilder: (context, error, stackTrace) =>
//                                         const Icon(Icons.broken_image),
//                                       )
//                                           : const Icon(Icons.image),
//                                       title: Text(product.name ?? 'No Name'),
//                                       subtitle: Text('\$${product.price ?? '0.00'}'),
//                                       onTap: () {
//                                         setStateDialog(() {
//                                           selectedProduct = {
//                                             'title': product.name ?? 'Unknown',
//                                             'image': product.images?.isNotEmpty == true
//                                                 ? product.images!.first
//                                                 : '',
//                                             'price': product.regularPrice ?? '0.00',
//                                             'id': product.id,
//                                             'sku': product.sku ?? 'N/A',
//                                           };
//                                         });
//                                       },
//                                       selected: selectedProduct != null &&
//                                           selectedProduct!['id'] == product.id,
//                                       selectedTileColor: Colors.grey[300],
//                                     );
//                                   },
//                                 ),
//                               );
//                             case Status.ERROR:
//                               print("BIG ERROR");
//                               return Center(
//                                 child: Text(snapshot.data!.message ?? "Error loading products"),
//                               );
//                           }
//                         }
//                         return const SizedBox.shrink();
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             actions: <Widget>[
//               TextButton(
//                 onPressed: () {
//                   productBloc.dispose();
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text(TextConstants.cancelText),
//               ),
//               TextButton(
//                 onPressed: selectedProduct != null ? () async {
//                   if (kDebugMode) {
//                     print("Adding product: $selectedProduct");
//                   }
//                   if (_fastKeyTabId != null) {
//                     await _addFastKeyTabItem(
//                       selectedProduct!['title'],
//                       selectedProduct!['image'],
//                       selectedProduct!['price'],
//                     );
//
//                     await fastKeyDBHelper.updateFastKeyTabCount(
//                       _fastKeyTabId!,
//                       fastKeyProductItems.length,
//                     );
//
//                     await _loadFastKeyTabItems();
//
//                     if (mounted) {
//                       setState(() {});
//                     }
//
//                     widget.fastKeyTabIdNotifier?.notifyListeners();
//                   }
//
//                   _productSearchController.text = "";
//                   productBloc.dispose();
//                   Navigator.of(context).pop();
//                 } : null,
//                 child: const Text(TextConstants.addText),
//               ),
//             ],
//           );
//         });
//       },
//     ).then((_) {
//       productBloc.dispose();
//     });
//   }
//
//   Widget _buildImage(String imagePath) {
//     if (imagePath.startsWith("http")) {
//       return Image.network(
//         imagePath,
//         width: 50,
//         height: 50,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Container(
//             width: 50,
//             height: 50,
//             color: Colors.grey.shade300,
//             child: const Icon(Icons.broken_image, color: Colors.grey),
//           );
//         },
//       );
//     } else {
//       return Image.file(
//         File(imagePath),
//         width: 50,
//         height: 50,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Container(
//             width: 50,
//             height: 50,
//             color: Colors.grey.shade300,
//             child: const Icon(Icons.broken_image, color: Colors.grey),
//           );
//         },
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final totalCount = fastKeyProductItems.length +
//         (_fastKeyTabId != null && widget.showAddButton ? 1 : 0); // Build #1.0.12: Modified condition
//     final theme = Theme.of(context);
//
//     return Expanded(
//       child: Column(
//         children: [
//           if (currentLevel > 0)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//               child: Row(
//                 children: [
//                   ElevatedButton(
//                     onPressed: _onBackPressed,
//                     style: ElevatedButton.styleFrom(
//                       side: BorderSide(color: theme.secondaryHeaderColor),
//                     ),
//                     child: Text(TextConstants.backText, style: TextStyle(color: theme.secondaryHeaderColor)),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: List.generate(navigationPath.length, (index) {
//                           return GestureDetector(
//                             onTap: () => _onNavigationPathTapped(index),
//                             child: Row(
//                               children: [
//                                 Text(
//                                   navigationPath[index],
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue,
//                                     decoration: TextDecoration.underline,
//                                   ),
//                                 ),
//                                 if (index < navigationPath.length - 1)
//                                   Padding(
//                                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                                     child: Icon(Icons.arrow_forward, size: 16, color: theme.secondaryHeaderColor),
//                                   ),
//                               ],
//                             ),
//                           );
//                         }),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           Expanded(
//             child: Container(
//               color: Colors.transparent,
//               child: widget.isLoading
//                   ? ShimmerEffect.rectangular(height: 200)
//                   : Material(
//                 color: Colors.transparent,
//                 child: ReorderableGridView.builder(
//                   padding: const EdgeInsets.all(16),
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     mainAxisSpacing: 20,
//                     crossAxisSpacing: 10,
//                     childAspectRatio: widget.isHorizontal ? 2.2 : 1.8,
//                   ),
//                   itemCount: totalCount,
//                   onReorder: (oldIndex, newIndex) {
//                     if (oldIndex == 0 || newIndex == 0) return;
//
//                     final adjustedOldIndex = oldIndex - (widget.showAddButton ? 1 : 0); // Build #1.0.12:
//                     final adjustedNewIndex = newIndex - (widget.showAddButton ? 1 : 0);
//
//                     if (adjustedOldIndex < 0 || adjustedNewIndex < 0 || adjustedOldIndex >= fastKeyProductItems.length || adjustedNewIndex >= fastKeyProductItems.length) {
//                       return;
//                     }
//
//                     setState(() {
//                       fastKeyProductItems = List<Map<String, dynamic>>.from(fastKeyProductItems); // Make mutable
//                       final item = fastKeyProductItems.removeAt(adjustedOldIndex);
//                       fastKeyProductItems.insert(adjustedNewIndex, item);
//
//                       reorderedIndices = List.filled(fastKeyProductItems.length, null);
//                       reorderedIndices[adjustedNewIndex] = adjustedNewIndex;  // Mark as reordered
//                       selectedItemIndex = adjustedNewIndex;
//                     });
//                   },
//                   itemBuilder: (context, index) {
//                     // Show add button only if showAddButton is true and it's the first item
//                     if (widget.showAddButton && _fastKeyTabId != null && index == 0) { // Build #1.0.12:
//                       return Container(
//                         key: const ValueKey('add_button'),
//                         child: GestureDetector(
//                           onTap: () => _showAddItemDialog(currentLevel),
//                           child: Card(
//                             color: Colors.white,
//                             elevation: 4,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: const [
//                                 Icon(Icons.add, size: 50, color: Colors.green),
//                                 SizedBox(height: 8),
//                                 Text(TextConstants.addItemText, style: TextStyle(color: Colors.green)),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     } else {
//                       final itemIndex = widget.showAddButton && _fastKeyTabId != null ? index - 1 : index; // Build #1.0.12
//                       if (itemIndex >= fastKeyProductItems.length) {
//                         return SizedBox.shrink(); // Handle out-of-bounds index
//                       }
//                       final isReordered = reorderedIndices.isNotEmpty && reorderedIndices.contains(itemIndex);
//                       final item = fastKeyProductItems[itemIndex];
//                       if (kDebugMode) {
//                         print(">>>>>>>>>>>>>>>> Grid Layout key: grid_item_${currentLevel}_${itemIndex}_${item["fast_key_item_name"]}");
//                       }
//                       return AnimatedContainer(
//                         duration: const Duration(milliseconds: 300),
//                         decoration: BoxDecoration(
//                           border: isReordered ? Border.all(color: Colors.blue, width: 3) : null,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         key: ValueKey('grid_item_${currentLevel}_${itemIndex}_${item["fast_key_item_name"]}'),
//                         child: Stack(
//                           clipBehavior: Clip.none,
//                           children: [
//                             GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   if (selectedItemIndex == itemIndex) {
//                                     selectedItemIndex = null;
//                                   } else {
//                                     selectedItemIndex = itemIndex;
//                                     reorderedIndices = List.filled(fastKeyProductItems.length, null); // Reset reorderedIndices
//                                   }
//                                   _onItemSelected(itemIndex);
//                                 });
//                               },
//                               child: Card(
//                                 color: Colors.white,
//                                 elevation: 4,
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: Row(
//                                     children: [
//                                       _buildImage(item["fast_key_item_image"]),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             Text(
//                                               item["fast_key_item_name"],
//                                               style: TextStyle(
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.bold,
//                                                 color: Colors.black,
//                                               ),
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                             Text(
//                                               '\$${item["fast_key_item_price"]}',
//                                               style: TextStyle(
//                                                 fontSize: 12,
//                                                 color: Colors.black,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             if (isReordered)
//                               Positioned(
//                                 top: widget.isHorizontal ? -5 : -9,
//                                 right: widget.isHorizontal ? -2 : -4,
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.delete, color: Colors.red, size: 20),
//                                       onPressed: () {
//                                         _deleteItem(itemIndex);
//                                       },
//                                     ),
//                                     const SizedBox(width: 0),
//                                     IconButton(
//                                       icon: const Icon(Icons.close, color: Colors.grey, size: 20),
//                                       onPressed: () {
//                                         setState(() {
//                                           reorderedIndices = List.filled(fastKeyProductItems.length, null); // Reset reorderedIndices
//                                         });
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                           ],
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Helper/auto_search.dart';
import 'package:pinaka_pos/Widgets/widget_age_verification_popup_dialog.dart';
import 'package:pinaka_pos/Widgets/widget_variants_dialog.dart';
import 'package:provider/provider.dart';
import '../Blocs/Orders/order_bloc.dart';
import '../Blocs/Search/product_search_bloc.dart';
import '../Constants/text.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
import '../Helper/Extentions/theme_notifier.dart';
import '../Helper/api_response.dart';
import '../Models/Search/product_variation_model.dart';
import '../Providers/Age/age_verification_provider.dart';
import '../Providers/Auth/product_variation_provider.dart';
import '../Utilities/shimmer_effect.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../Utilities/svg_images_utility.dart';

class NestedGridWidget extends StatelessWidget {
  final bool isHorizontal;
  final bool isLoading;
  final bool showAddButton;
  final bool showBackButton; // New property to show "Back to Categories" button
  final List<Map<String, dynamic>> items;
  final int? selectedItemIndex;
  final List<int?> reorderedIndices;
  final VoidCallback? onAddButtonPressed;
  final VoidCallback? onBackButtonPressed; // Callback for "Back to Categories"
  final Function(int, {bool variantAdded}) onItemTapped; // Update the callback to accept a named parameter
  final Function(int, int) onReorder;
  final Function(int) onDeleteItem;
  final bool showDeleteButton;
  final Function() onCancelReorder;
  final ProductBloc? productBloc; //Build 1.1.36
  final OrderBloc? orderBloc;
  final OrderHelper? orderHelper;

  const NestedGridWidget({
    super.key,
    required this.isHorizontal,
    required this.isLoading,
    required this.showAddButton,
    required this.showBackButton,
    required this.items,
    this.selectedItemIndex,
    required this.reorderedIndices,
    this.onAddButtonPressed,
    this.onBackButtonPressed,
    required this.onItemTapped,
    required this.onReorder,
    required this.onDeleteItem,
    this.showDeleteButton = true,
    required this.onCancelReorder,
    this.productBloc,
    this.orderBloc,
    this.orderHelper,
  });

  Widget _buildImage(String imagePath) {
    final imageWidget = imagePath.startsWith("http")
      ? SizedBox(
           width: 75,
           height: 75,
        child: Image.network(
          imagePath,
          width: 75,
          height: 75,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 75,
              height: 75,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      )
      : Platform.isWindows
        ? Image.asset(
      'assets/default.png',
      height: 75,
      width: 75,
    )
        : Image.file(
        File(imagePath),
        width: 75,
        height: 75,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 75,
            height: 75,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = (showAddButton ? 1 : 0) + (showBackButton ? 1 : 0) + items.length;
    final themeHelper = Provider.of<ThemeNotifier>(context);

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        height: MediaQuery.of(context).size.height /2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : Colors.white,
        ),
        child: isLoading
            ? ShimmerEffect.rectangular(height: 200)
            : Material(
          color: Colors.transparent,
            child: ReorderableGridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemCount: totalCount,
              onReorder: onReorder,
              itemBuilder: (context, index) {
                // Handle "Add" button if enabled
                if (showAddButton && index == 0) {
                  return Container(
                    key: const ValueKey('add_button'),
                    child: GestureDetector(
                      onTap: onAddButtonPressed ?? () {},
                      child: Card(
                        color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground :Colors.white,
                        elevation: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, size: 40, color: Color(0xFFFE6464)),
                            //SizedBox(height: 2),
                            Text(TextConstants.addProductText, style: TextStyle(color: Color(0xFFFE6464))),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            
                // Handle "Back to Categories" button if enabled
                if (showBackButton && index == (showAddButton ? 1 : 0)) {
                  return Container(
                    key: const ValueKey('back_button'),
                    child: GestureDetector(
                      onTap: onBackButtonPressed ?? () {},
                      child: Card(
                        color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
                        elevation: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.arrow_back, size: 50, color: Colors.blue),
                            SizedBox(height: 5),
                            Text(TextConstants.backToCategories, style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            
                // Adjust the index based on the presence of "Add" and "Back" buttons
                final itemIndex = index - (showAddButton ? 1 : 0) - (showBackButton ? 1 : 0);
                if (itemIndex < 0 || itemIndex >= items.length) {
                  return const SizedBox.shrink();
                }
            
                final isReordered = reorderedIndices.isNotEmpty && reorderedIndices[itemIndex] != null;
                final item = items[itemIndex];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    border: isReordered ? Border.all(color: Colors.blue, width: 3) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  key: ValueKey('grid_item_${itemIndex}_${item["fast_key_item_name"]}'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector( //Build 1.1.36: updated code for variations dialog conditions
                        onTap: () async {
                          if (productBloc == null) {
                            if (kDebugMode) {
                              print("NestedGridWidget - productBloc is null, cannot fetch variations");
                            }
                            onItemTapped(index);
                            return;
                          }

                          final productId = int.tryParse(item["fast_key_product_id"].toString()) ?? -1; //Build #1.0.54: fixed variant dialog issue
                          if (kDebugMode) {
                            print("NestedGridWidget - Product tapped: ${item['fast_key_item_name']}, ID: $productId, (${item["fast_key_product_id"]})");
                            print("NestedGridWidget - minAge ${item[AppDBConst.fastKeyItemMinAge] ?? 0}");
                            print("TEST 11 - fast_key_item_has_variant ${item[AppDBConst.fastKeyItemHasVariant]}");
                          }
                          /// use product id:22, sku:woo-fashion-socks
                          //var isVerified = await _ageRestrictedProduct(context, minAge: item[AppDBConst.fastKeyItemMinAge] ?? 0);
                          /// Verify Age and proceed else return
                          final ageVerificationProvider = AgeVerificationProvider();
                          var isVerified = await ageVerificationProvider.verifyAge(context, minAge: item[AppDBConst.fastKeyItemMinAge] ?? 0);
                          if(!isVerified){
                            return;
                          }
                          /// Build #1.0.157: Added to check before calling variation API for saving loading time issue
                         //  if (item['type'] == 'variable' || item['fast_key_item_has_variant'] == 1) {
                         //    if (kDebugMode) {
                         //      print("##### NestedGridWidget - Item Type: ${item['type']}, productId: $productId");
                         //    }
                         //    VariationPopup(productId, item['fast_key_item_name'], orderHelper!, onProductSelected: ({required bool isVariant}) {
                         //
                         //      onItemTapped(index, variantAdded: isVariant);
                         //      if (kDebugMode) {
                         //        print("##### NestedGridWidget - Variant $isVariant");
                         //      }
                         //    }).showVariantDialog(context: context);
                         //  } else {
                         //    if (kDebugMode) {
                         //      print("##### NestedGridWidget - NO Variant, productId: $productId");
                         //    }
                         // //   Center(child: CircularProgressIndicator());
                         //    onItemTapped(index, variantAdded: false);
                         //  }

                          VariationPopup(productId, item['fast_key_item_name'], orderHelper!,onProductSelected: ({required bool isVariant}) {
                            // Navigator.pop(context); // Build #1.0.148: loader/dialog popping after product adds into order panel in _onItemSelected in fastKey/categories screen
                            onItemTapped(index, variantAdded: isVariant); //Build #1.0.78: Pass isVariant to onItemTapped
                          },
                          ).showVariantDialog(context: context);
                          // // Fetch variations for the product
                          // productBloc!.fetchProductVariations(productId);
                          //
                          // // Show dialog and listen to the variation stream
                          // if (context.mounted) {
                          //   showDialog(
                          //     context: context,
                          //     builder: (context) => StreamBuilder<APIResponse<List<ProductVariation>>>(
                          //       stream: productBloc!.variationStream,
                          //       builder: (context, snapshot) {
                          //         if (!snapshot.hasData) {
                          //           if (kDebugMode) {
                          //             print("NestedGridWidget - No data in stream, waiting...");
                          //           }
                          //           return const Center(child: CircularProgressIndicator());
                          //         }
                          //
                          //         final response = snapshot.data!;
                          //         if (response.status == Status.LOADING) {
                          //           return const Center(child: CircularProgressIndicator());
                          //         } else if (response.status == Status.COMPLETED) {
                          //           final variations = response.data!;
                          //           if (variations.isNotEmpty) {
                          //             if (kDebugMode) {
                          //               print("NestedGridWidget - Variations found: ${variations.length}");
                          //             }
                          //             return VariantsDialog(
                          //               title: item["fast_key_item_name"],
                          //               variations: variations
                          //                   .map((v) => {
                          //                 "id": v.id,
                          //                 "name": v.name,
                          //                 "price": v.regularPrice,
                          //                 "image": v.image.src,
                          //               }).toList(),
                          //               onAddVariant: (variant, quantity) {
                          //                 if (kDebugMode) {
                          //                   print("NestedGridWidget - Adding variant to order: ID=${variant['id']}, Name=${variant['name']}, Quantity=$quantity");
                          //                 }
                          //                 orderHelper?.addItemToOrder(
                          //                   variant["name"],
                          //                   variant["image"],
                          //                   double.tryParse(variant["price"].toString()) ?? 0.0,
                          //                   quantity,
                          //                   'SKU${variant["name"]}',
                          //                   onItemAdded: () {
                          //                     Navigator.pop(context);
                          //                     onItemTapped(index, variantAdded: true);
                          //                   },
                          //                 );
                          //               },
                          //             );
                          //           } else {
                          //             if (kDebugMode) {
                          //               print("NestedGridWidget - No variations found, proceeding with product");
                          //             }
                          //             Navigator.pop(context);
                          //             onItemTapped(index);
                          //             return const SizedBox.shrink();
                          //           }
                          //         } else {
                          //           if (kDebugMode) {
                          //             print("NestedGridWidget - Error fetching variations: ${response.message}");
                          //           }
                          //           Navigator.pop(context);
                          //           onItemTapped(index);
                          //           return const SizedBox.shrink();
                          //         }
                          //       },
                          //     ),
                          //   );
                          // }
                        },
                        child: Card(
                          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground :Colors.white,
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                _buildImage(item["fast_key_item_image"]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        item["fast_key_item_name"],
                                        style: TextStyle(
                                          fontSize: 12,
                                          //fontWeight: FontWeight.bold,
                                          color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '${TextConstants.currencySymbol}${double.tryParse(item["fast_key_item_price"].toString())?.toStringAsFixed(2) ?? "0.00"}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                                            ),
                                          ),
                                          const SizedBox(width: 22), // Space between price and variations
                                          if (item['variations'] != null && item['variations'].isNotEmpty) // Build #1.0.157: show variationIcon with count
                                            Row(
                                              children: [
                                                SvgPicture.asset(SvgUtils.variationIcon, height: 10, width: 10),
                                                // SizedBox(width: 4),
                                                // Text(
                                                //   '${item["variations"].length}',
                                                //   style: TextStyle(
                                                //     fontSize: 12,
                                                //     color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                                                //   ),
                                                // ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isReordered)
                        Positioned(
                          top: -5,
                          right: -2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDeleteButton)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => onDeleteItem(itemIndex),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                onPressed: onCancelReorder,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

        ),
      ),
    );
  }

  Future<void> updateOrderPanel(int index) async{
    // Navigator.pop(context);
    onItemTapped(index, variantAdded: true);
  }

//   Future<bool> _ageRestrictedProduct(BuildContext context, {int minAge = 0}) async {
//     ///@
// //
// // ANSI 636026100102DL00410277ZA03180012DLDAQD05848559 DCSBELE SHRAVAN DDEN DACKUMAR DDFNvDADNONEaDDGNrDCAD DCBNONEtDCDNONEaDBD02052025gDBB07181978gDBA09032030 DBC1=DAU070 in DAYBROpDAG233 W FELLARS DRrDAIPHOENIXoDAJAZdDAK850237501  uDCF003402EB0B124005cDCGUSAtDCK48102972534.DDAFtDDB02282023aDDD1gDAZBLKsDAW196?DDK1
// //     ZAZAAN.ZACN
//
//     var isVerified = false;
//     if (kDebugMode) {
//       print("Fast Key _ageRestrictedProduct hasAgeRestriction = $minAge");
//     }
//     var hasAgeRestriction = minAge != 0;
//     if (hasAgeRestriction) {
//       await AgeVerificationHelper.showAgeVerification(
//         context: context,
//         // productName: product.name,
//         minimumAge: minAge,
//         onManualVerify: () {
//           // Add product to cart - manually verified
//           // _addToCart(product);
//           isVerified = true;
//         },
//         onAgeVerified: () {
//           // Add product to cart - age verified
//           // _addToCart(product);
//           isVerified = true;
//         },
//         onCancel: () {
//           // User cancelled - don't add to cart
//           isVerified = false;
//           Navigator.pop(context);
//         },
//       );
//     } else {
//       isVerified = true;
//     }
//     return isVerified;
//   }
}
