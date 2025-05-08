// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:pinaka_pos/Blocs/FastKey/fastkey_bloc.dart';
// import 'package:pinaka_pos/Repositories/FastKey/fastkey_repository.dart';
// import 'dart:io';
// import '../Constants/text.dart';
// import '../Database/db_helper.dart';
// import '../Database/fast_key_db_helper.dart';
// import '../Database/user_db_helper.dart';
// import '../Helper/file_helper.dart';
// import '../Models/FastKey/fastkey_model.dart';
// import '../Utilities/shimmer_effect.dart';
// import '../Constants/text.dart';
// import '../Helper/api_response.dart';
//
// class CategoryList extends StatefulWidget {
//   final bool isHorizontal; // Build #1.0.6
//   final bool isLoading;// Add a loading state
//   final bool isAddButtonEnabled;
//   final ValueNotifier<int?> fastKeyTabIdNotifier; // Add this
//
//   const CategoryList({super.key, required this.isHorizontal, required this.isAddButtonEnabled, this.isLoading = false, required this.fastKeyTabIdNotifier});
//
//   @override
//   _CategoryListState createState() => _CategoryListState();
// }
//
// class _CategoryListState extends State<CategoryList> {
//   // Scroll controller to manage horizontal scrolling
//   final ScrollController _scrollController = ScrollController();
//   // Flags to show left and right scroll arrows
//   bool _showLeftArrow = false;
//   bool _showRightArrow = true;
//   int? _selectedIndex; // Changed to nullable for better handling
//   int? _editingIndex; // Track the item being reordered or edited
//   int? userId;
//
//   // FastKey helper instance
//   final FastKeyDBHelper fastKeyDBHelper = FastKeyDBHelper();
//   late FastKeyBloc _fastKeyBloc;
//   // List of FastKey tabs fetched from the database
//   // now using FastKey object model
//   List<FastKey> fastKeyTabs = []; // Build #1.0.19: Updated fastKeyProducts to fastKeyTabs for better understanding
//   var isLoading = false;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _fastKeyBloc = FastKeyBloc(FastKeyRepository());
//     _scrollController.addListener(() {
//       setState(() {
//         _showLeftArrow = _scrollController.offset > 0;
//         _showRightArrow = _scrollController.offset < _scrollController.position.maxScrollExtent;
//       });
//     });
//
//     getUserIdFromDB();
//     widget.fastKeyTabIdNotifier.addListener(_onTabChanged); // Listen to tab changes
//   }
//
//   void _onTabChanged() { // Build #1.0.12: fixed fast key tab related issue
//     if (kDebugMode) {
//       print("### _onTabChanged: New Tab ID: ${widget.fastKeyTabIdNotifier.value}");
//     }
//     // Perform asynchronous work first
//     _loadFastKeysTabs().then((_) {
//       // Update state synchronously
//       if (mounted) {
//         setState(() {});
//       }
//     });
//   }
//
//   Future<void> _loadLastSelectedTab() async { // Build #1.0.11
//     final lastSelectedTabId = await fastKeyDBHelper.getActiveFastKeyTab();
//     if (kDebugMode) {
//       print("#### fastKeyHelper.getFastKeyTabFromPref: $lastSelectedTabId");
//     }
//     if (lastSelectedTabId != null) {
//       setState(() {
//         _selectedIndex = fastKeyTabs.indexWhere((tab) => tab.fastkeyServerId == lastSelectedTabId);
//       });
//     }
//
//     if (kDebugMode) {
//       print("#### _selectedIndex: $_selectedIndex");
//     }
//   }
//
//   Future<void> getUserIdFromDB() async { // Build #1.0.13 : now user data loads from user table DB
//     try {
//       final userData = await UserDbHelper().getUserData();
//
//       if (userData != null && userData[AppDBConst.userId] != null) {
//         userId = userData[AppDBConst.userId] as int; // Fetching user ID from DB
//
//         if (kDebugMode) {
//           print("#### userId from DB: $userId");
//         }
//
//         ///Add a logic to load from API then push to DB and final load from DB
//         ///1. call get fast keys API
//         _fastKeyBloc.fetchFastKeysByUser(userId ?? 0);
//
//         ///2. save to DB
//
//         await _fastKeyBloc.getFastKeysStream.listen((onData){
//
//           if(onData.data != null){
//             if (onData.status == Status.ERROR) {
//               if (kDebugMode) {
//                 print('Widget Category List >> getUserIdFromDB >> fetchFastKeysByUser: fetch completed with ERROR');
//               }
//               _fastKeyBloc.getFastKeysSink.add(APIResponse.error(TextConstants.retryText));
//             } else if (onData.status == Status.COMPLETED) { // #Build 1.1.97: Fixed Issue -> subscription screen is coming every first time even user have byPassSubscription is true
//               final fastKeysResponse = onData.data!;
//               if(fastKeysResponse.status != "success"){
//                 _fastKeyBloc.getFastKeysSink.add(APIResponse.error(TextConstants.retryText));
//               }
//
//               ///3. call get fast key from DB
//               loadTabs();
//
//               // if (fastKeysResponse == null || fastKeysResponse.fastkeys.isNotEmpty || fastKeysResponse.fastkeys != []) {
//               //   fastKeysResponse.fastkeys
//               //
//               // }
//             }
//           }
//         });
//       } else {
//         if (kDebugMode) {
//           print("No user ID found in the database.");
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print("Exception in getUserId: $e");
//       }
//     }
//   }
//
//   void loadTabs() async{
//     // Load FastKey tabs from the database
//     await _loadFastKeysTabs(); // Wait for tabs to load
//     await _loadLastSelectedTab(); // Now load the last selected tab
//   }
//
//   // Add a method to check if content overflows
//   bool _doesContentOverflow() { // Build #1.0.11
//     final screenWidth = MediaQuery.of(context).size.width;
//     final contentWidth = fastKeyTabs.length * 120; // Adjust based on item width
//     return contentWidth > screenWidth;
//   }
//
//   Future<void> _loadFastKeysTabs() async { // Build #1.0.11
//     final fastKeyTabsData = await fastKeyDBHelper.getFastKeyTabsByUserId(userId ?? 1);
//     if (kDebugMode) {
//       print("#### fastKeyTabs : $fastKeyTabs");
//     }
//     // Convert the list of maps to a list of CategoryModel
//     if(mounted){
//       setState(() {
//         fastKeyTabs = fastKeyTabsData.map((product) {
//           return FastKey(
//             fastkeyServerId: product[AppDBConst.fastKeyId],
//             userId: userId ?? 1,
//             fastkeyTitle: product[AppDBConst.fastKeyTabTitle],
//             fastkeyImage: product[AppDBConst.fastKeyTabImage],
//             fastkeyIndex: product[AppDBConst.fastKeyTabIndex]?.toString() ?? '0',
//             itemCount: int.tryParse(product[AppDBConst.fastKeyTabItemCount]?.toString() ?? '0') ?? 0,
//           );
//         }).toList();
//       });
//     }
//   }
//
//   Future<void> _addFastKeyTab(String title, String image) async {
//     final newTabId = await fastKeyDBHelper.addFastKeyTab(userId ?? 1, title, image, 0, 0, 0);
//
//     /// call Create fast key API
//     _fastKeyBloc.createFastKey(title: title, index: fastKeyTabs.length+1, imageUrl: image, userId: userId ?? 0);
//     // Add the new tab to the local list
//     setState(() {
//       isLoading = true;
//       fastKeyTabs.add(FastKey(
//         fastkeyServerId: newTabId, // Temporary ID
//         userId: userId ?? 1,
//         fastkeyTitle: title,
//         fastkeyImage: image,
//         fastkeyIndex: (fastKeyTabs.length + 1).toString(),
//         itemCount: 0,
//       ));
//       _selectedIndex = fastKeyTabs.length - 1;
//     });
//
//     // Listen for API response to update with real server ID
//     _fastKeyBloc.createFastKeyStream.listen((response) async {
//       if (response.status == Status.COMPLETED && response.data != null) {
//         // Update DB with real server ID
//         await fastKeyDBHelper.updateFastKeyTab(newTabId, {
//           AppDBConst.fastKeyServerId: response.data!.fastkeyId,
//         });
//
//         // Reload tabs to get updated data
//         await _loadFastKeysTabs();
//
//         // Save as active tab
//         await fastKeyDBHelper.saveActiveFastKeyTab(response.data!.fastkeyId);
//         if (kDebugMode) {
//           print("### _addFastKeyTab: Setting ValueNotifier to ${response.data!.fastkeyId}");
//         }
//         widget.fastKeyTabIdNotifier.value = response.data!.fastkeyId;
//       }
//
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     });
//   }
//
//   Future<void> _deleteFastKeyTab(int fastKeyProductId) async {
//     if (kDebugMode) {
//       print("#### Deleting FastKey tab with ID: $fastKeyProductId");
//     }
//
//     /// Get the active fastkey server id from _fastKeyTabId
//     var tabs = await fastKeyDBHelper.getFastKeyTabsByTabId(fastKeyProductId);
//     if(tabs.isEmpty){
//       setState(() => isLoading = false);
//       return;
//     }
//     var fastKeyServerId = tabs.first[AppDBConst.fastKeyServerId];
//
//     // 1. First delete from API
//     _fastKeyBloc.deleteFastKey(fastKeyServerId);
//
//     // 2. Remove from local list immediately
//     setState(() {
//       fastKeyTabs.removeWhere((tab) => tab.fastkeyServerId == fastKeyProductId);
//
//       // Handle active tab selection after deletion
//       if (_selectedIndex != null) {
//         if (_selectedIndex! >= fastKeyTabs.length) {
//           _selectedIndex = fastKeyTabs.isNotEmpty ? fastKeyTabs.length - 1 : null;
//         }
//
//         // Update the notifier with new selected tab or null if no tabs left
//         widget.fastKeyTabIdNotifier.value = _selectedIndex != null
//             ? fastKeyTabs[_selectedIndex!].fastkeyServerId
//             : null;
//       }
//     });
//
//     // 3. Listen for API response
//     await _fastKeyBloc.deleteFastKeyStream.firstWhere((response) => response.status == Status.COMPLETED || response.status == Status.ERROR
//     ).then((response) async {
//       if (response.status == Status.COMPLETED && response.data?.status == "success") {
//         // Only delete from DB if API deletion succeeds
//         await fastKeyDBHelper.deleteFastKeyTab(fastKeyProductId);
//         if (kDebugMode) {
//           print("#### Successfully deleted tab from DB and API");
//         }
//       } else {
//         // If API deletion failed, reload from DB to restore the tab
//         if (kDebugMode) {
//           print("#### API deletion failed, reloading tabs from DB");
//         }
//         await _loadFastKeysTabs();
//       }
//     });
//
//     // Update the item count in the FastKey tab
//     await fastKeyDBHelper.updateFastKeyTabCount(fastKeyProductId, fastKeyTabs.length);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) { // Build #1.0.19: added for loading while adding deleting fastKeys
//       return ShimmerEffect.rectangular(
//         height: widget.isHorizontal ? 100 : 800,
//       );
//     }
//
//     // Your existing build code
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: widget.isLoading
//           ? ShimmerEffect.rectangular(
//         height: widget.isHorizontal ? 100 : 800, // Adjust height dynamically
//       )
//           : widget.isHorizontal
//           ? _buildHorizontalList()
//           : _buildVerticalList(),
//     );
//   }
//
//   Widget _buildImage(String imagePath) { // Build #1.0.11 :  load image
//     if (imagePath.startsWith('assets/')) {
//       return SvgPicture.asset(
//         imagePath,
//         height: 40,
//         width: 40,
//         placeholderBuilder: (context) => Icon(Icons.image, size: 40),
//       );
//     } else {
//       return Image.file(
//         File(imagePath),
//         height: 40,
//         width: 40,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) {
//           return Icon(Icons.image, size: 40);
//         },
//       );
//     }
//   }
//
//   Widget _buildHorizontalList() {
//     var size = MediaQuery.of(context).size; // Get screen size
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _editingIndex = null; // Build #1.0.7: Dismiss edit mode on tap outside
//         });
//       },
//       child: Row(
//         children: [
//           AnimatedSwitcher(
//             duration: Duration(milliseconds: 1000),
//             transitionBuilder: (widget, animation) {
//               return FadeTransition(opacity: animation, child: widget);
//             },
//             child: _showLeftArrow && _doesContentOverflow()
//                 ? _buildScrollButton(Icons.arrow_back_ios, () {
//               _scrollController.animateTo(
//                 _scrollController.offset - size.width,
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//               );
//             }) : SizedBox.shrink(),
//           ),
//           Expanded(
//             child: SizedBox(
//               height: 110,
//               child: ReorderableListView(
//                 scrollController: _scrollController,
//                 scrollDirection: Axis.horizontal,
//                 onReorderStart: (index) {
//                   if (kDebugMode) {
//                     print("##### onReorderStart $index");
//                   }
//                   setState(() {
//                     _editingIndex = index; // Show edit button when reorder starts
//                    });
//                 },
//                 onReorder: (oldIndex, newIndex) async {
//                   // Your existing code
//                   if (newIndex > oldIndex) newIndex--;
//
//                   setState(() {
//                     final item = fastKeyTabs.removeAt(oldIndex);
//                     fastKeyTabs.insert(newIndex, item);
//
//                     // Keep edit mode after reordering
//                     _editingIndex = newIndex;
//
//                     if (_selectedIndex != null) {
//                       if (_selectedIndex == oldIndex) {
//                         _selectedIndex = newIndex;
//                       } else if (oldIndex < _selectedIndex! && newIndex >= _selectedIndex!) {
//                         _selectedIndex = _selectedIndex! - 1;
//                       } else if (oldIndex > _selectedIndex! && newIndex <= _selectedIndex!) {
//                         _selectedIndex = _selectedIndex! + 1;
//                       }
//                     }
//                   });
//                 },
//                 proxyDecorator: (Widget child, int index, Animation<double> animation) {
//                   return Material(
//                     elevation: 0,
//                     color: Colors.transparent,
//                     child: child,
//                   );
//                 },
//                 children: List.generate(fastKeyTabs.length, (index) {
//                   final product = fastKeyTabs[index];
//                   bool isSelected = _selectedIndex == index;
//                   bool showEditButton = _editingIndex == index;
//
//                   return GestureDetector(
//                     key: ValueKey('${product.fastkeyTitle}_$index'),
//                     onTap: () async {
//                       setState(() {
//                         if (_editingIndex == index) {
//                           // If tapping the item being edited, just dismiss edit mode
//                           _editingIndex = null;
//                         } else if (_selectedIndex == index) {
//                           // If already selected, do nothing
//                           return;
//                         } else {
//                           // Select the item
//                           _selectedIndex = index;
//                         }
//                       });
//
//                       // Save the selected tab ID only if not in edit mode
//                       if (_editingIndex == null) {
//                         await fastKeyDBHelper.saveActiveFastKeyTab(product.fastkeyServerId);
//                         widget.fastKeyTabIdNotifier.value = product.fastkeyServerId;
//                       }
//                       _editingIndex = null;
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 5.0),
//                       child: AnimatedContainer(
//                         width: 90, // Fixed width for each item
//                         duration: const Duration(milliseconds: 300),
//                         padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
//                         decoration: BoxDecoration(
//                           color: isSelected ? Colors.red : Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: showEditButton ? Colors.blueAccent : Colors.black12,
//                             width: showEditButton ? 2 : 1,
//                           ),
//                         ),
//                         child: Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             Positioned(
//                               top: 0,
//                               right: -6,
//                               child: AnimatedOpacity(
//                                 duration: const Duration(milliseconds: 300),
//                                 opacity: showEditButton ? 1.0 : 0.0,
//                                 child: GestureDetector(
//                                   onTap: () => _showCategoryDialog(context: context, index: index),
//                                   child: Container(
//                                     padding: const EdgeInsets.all(4),
//                                     decoration: BoxDecoration(
//                                       color: Colors.transparent,
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(Icons.edit, size: 14, color: Colors.blueAccent),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 _buildImage(product.fastkeyImage),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   product.fastkeyTitle,
//                                   maxLines: 1,
//                                   style: TextStyle(
//                                     overflow: TextOverflow.ellipsis,
//                                     fontWeight: FontWeight.bold,
//                                     fontVariations: <FontVariation>[FontVariation('wght', 900.0)],
//                                     color: isSelected ? Colors.white : Colors.black,
//                                   ),
//                                 ),
//                                 Text(
//                                   product.itemCount.toString(),
//                                   style: TextStyle(
//                                     color: isSelected ? Colors.white : Colors.grey,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 }),
//               ),
//             ),
//           ),
//           AnimatedSwitcher(
//             duration: Duration(milliseconds: 1000),
//             transitionBuilder: (widget, animation) {
//               return FadeTransition(opacity: animation, child: widget);
//             },
//             child: _showLeftArrow && _doesContentOverflow()
//                 ? _buildScrollButton(Icons.arrow_forward_ios, () {
//               _scrollController.animateTo(
//                 _scrollController.offset + size.width,
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//               );
//             }) : SizedBox.shrink(),
//           ),
//           const SizedBox(width: 8),
//           widget.isAddButtonEnabled ?
//           _buildScrollButton(Icons.add, () {
//             _showCategoryDialog(context: context);
//           })
//           : SizedBox(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildVerticalList() {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _editingIndex = null; // Dismiss edit mode on tap outside
//         });
//       },
//       child: Column(
//         children: [
//           SizedBox(
//             height: MediaQuery.of(context).size.height * 0.7,
//             width: MediaQuery.of(context).size.width * 0.35,
//             child: ReorderableListView(
//               scrollDirection: Axis.vertical,
//               onReorderStart: (index) => setState(() => _editingIndex = index),
//               onReorder: (oldIndex, newIndex) async {
//                 if (newIndex > oldIndex) newIndex--;
//
//                 setState(() {
//                   final item = fastKeyTabs.removeAt(oldIndex);
//                   fastKeyTabs.insert(newIndex, item);
//                   _editingIndex = newIndex;
//
//                   if (_selectedIndex != null) {
//                     if (_selectedIndex == oldIndex) {
//                       _selectedIndex = newIndex;
//                     } else if (oldIndex < _selectedIndex! && newIndex >= _selectedIndex!) {
//                       _selectedIndex = _selectedIndex! - 1;
//                     } else if (oldIndex > _selectedIndex! && newIndex <= _selectedIndex!) {
//                       _selectedIndex = _selectedIndex! + 1;
//                     }
//                   }
//                 });
//
//                 // Update indices in DB
//                 for (int i = 0; i < fastKeyTabs.length; i++) {
//                   await fastKeyDBHelper.updateFastKeyTab(fastKeyTabs[i].fastkeyServerId, {
//                     AppDBConst.fastKeyTabIndex: i.toString(),
//                   });
//                 }
//               },
//               proxyDecorator: (child, index, animation) => Material(
//                 elevation: 0,
//                 color: Colors.transparent,
//                 child: child,
//               ),
//               children: List.generate(fastKeyTabs.length, (index) {
//                 final product = fastKeyTabs[index];
//                 bool isSelected = _selectedIndex == index;
//                 bool showEditButton = _editingIndex == index;
//
//                 return GestureDetector(
//                   key:  ValueKey('${product.fastkeyTitle}_$index'),
//                   onTap: () async {
//                     setState(() {
//                       if (_editingIndex == index) {
//                         // If item is in edit mode, just dismiss edit mode
//                         _editingIndex = null;
//                       } else if (_selectedIndex != index) {
//                         _selectedIndex = index;
//                         _editingIndex = null;
//                       }
//                     });
//
//                     await fastKeyDBHelper.saveActiveFastKeyTab(product.fastkeyServerId);
//                     widget.fastKeyTabIdNotifier.value = product.fastkeyServerId;
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
//                     child: AnimatedContainer(
//                       width: 120, // Fixed width for each item
//                       duration: const Duration(milliseconds: 300),
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: isSelected ? Colors.red : Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: showEditButton ? Colors.blueAccent : Colors.black12,
//                           width: showEditButton ? 2 : 1,
//                         ),
//                       ),
//                       child: Stack(
//                         children: [
//                           Positioned(
//                             top: widget.isHorizontal ? 0 : 0,
//                             right: widget.isHorizontal ? -6 : 0,
//                             child: AnimatedOpacity(
//                               duration: const Duration(milliseconds: 300),
//                               opacity: showEditButton ? 1.0 : 0.0,
//                               child: GestureDetector(
//                                 onTap: () => _showCategoryDialog(context: context, index: index),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.transparent,
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Icon(Icons.edit, size: 14, color: Colors.blueAccent),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           Row(
//                             children: [
//                               _buildImage(product.fastkeyImage),
//                               const SizedBox(width: 8),
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     product.fastkeyTitle,
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: isSelected ? Colors.white : Colors.black,
//                                     ),
//                                   ),
//                                   Text(
//                                     product.itemCount.toString(),
//                                     style: TextStyle(
//                                       color: isSelected ? Colors.white : Colors.grey,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               }),
//             ),
//           ),
//           const SizedBox(height: 50),
//           Container(
//             width: MediaQuery.of(context).size.width * 0.35,
//             padding: const EdgeInsets.all(5),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.black12),
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: SizedBox( // Build #1.0.13 : tried to fix render flex issue for "+" button in category screen
//               width: double.infinity, // Take full width of container
//               child: IconButton(
//                 icon: const Icon(Icons.add, color: Colors.redAccent),
//                 onPressed: () => _showCategoryDialog(context: context),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Helper method to build scroll buttons (left and right)
//   Widget _buildScrollButton(IconData icon, VoidCallback onPressed) {
//     return Container(
//       height: 110, // Set height of scroll button
//       padding: const EdgeInsets.all(1),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.black12),
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.redAccent),
//         onPressed: onPressed, // Trigger scroll action when pressed
//       ),
//     );
//   }
//
//   void _showCategoryDialog({required BuildContext context, int? index}) {
//     bool isEditing = index != null;
//     TextEditingController nameController = TextEditingController(
//         text: isEditing ? fastKeyTabs[index!].fastkeyTitle : '');
//     String imagePath = isEditing ? fastKeyTabs[index!].fastkeyImage : 'assets/default.png';
//     bool showError = false;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: Text(isEditing ? TextConstants.editCateText : TextConstants.addCateText),
//               content: SingleChildScrollView(
//                 child: SizedBox(
//                   width: MediaQuery.of(context).size.width * 0.2,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Align(
//                         alignment: Alignment.center,
//                         child: Stack(
//                           children: [
//                             _buildImageWidget(imagePath),
//                             Positioned(
//                               right: 0,
//                               bottom: 0,
//                               child: GestureDetector(
//                                 onTap: () async {
//                                   final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//                                   if (pickedFile != null) {
//                                     setStateDialog(() => imagePath = pickedFile.path);
//                                   }
//                                 },
//                                 child: const Icon(Icons.edit,
//                                     size: 18, color: Colors.red),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (!isEditing && showError && imagePath.isEmpty)
//                         const Padding(
//                           padding: EdgeInsets.only(top: 8.0),
//                           child: Text(
//                             TextConstants.imgRequiredText,
//                             style: TextStyle(color: Colors.red, fontSize: 12),
//                           ),
//                         ),
//                       TextField(
//                         controller: nameController,
//                         decoration: InputDecoration(
//                           labelText: TextConstants.nameText,
//                           errorText: (!isEditing && showError && nameController.text.isEmpty)
//                               ? TextConstants.nameReqText
//                               : null,
//                           errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
//                           suffixIcon: isEditing
//                               ? const Icon(Icons.edit, size: 18, color: Colors.red)
//                               : null,
//                         ),
//                       ),
//                       if (isEditing)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8.0),
//                           child: Text(
//                             '${TextConstants.itemCountText} ${fastKeyTabs[index].itemCount}',
//                             style: const TextStyle(color: Colors.grey),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text(TextConstants.cancelText),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     if (!isEditing && nameController.text.isEmpty) {
//                       setStateDialog(() => showError = true);
//                       return;
//                     }
//
//                     if (isEditing) {
//                       // Update existing tab
//                       await fastKeyDBHelper.updateFastKeyTab(
//                           fastKeyTabs[index!].fastkeyServerId,
//                           {
//                             AppDBConst.fastKeyTabTitle: nameController.text,
//                             AppDBConst.fastKeyTabImage: imagePath,
//                           }
//                       );
//
//                       // Update the local list
//                       setState(() {
//                         _editingIndex = null;
//                         fastKeyTabs[index] = fastKeyTabs[index].copyWith(
//                           fastkeyTitle: nameController.text,
//                           fastkeyImage: imagePath,
//                         );
//                       });
//                     } else {
//                       // Add new FastKey tab to the database
//                       await _addFastKeyTab(nameController.text, imagePath);
//                     }
//
//                     // Close the dialog
//                     Navigator.pop(context);
//                   },
//                   child: const Text(TextConstants.saveText),
//                 ),
//                 if (isEditing)
//                   TextButton(
//                     onPressed: () => _showDeleteConfirmationDialog(index!),
//                     child: const Text(TextConstants.deleteText, style: TextStyle(color: Colors.red)),
//                   ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildImageWidget(String imagePath) { // Build #1.0.19: added code for image fetching / updating errors
//     if (imagePath.isEmpty) return _safeSvgPicture('assets/password_placeholder.svg');
//
//     if (imagePath.startsWith('assets/') && imagePath.endsWith('.svg')) {
//       return _safeSvgPicture(imagePath);
//     } else if (imagePath.startsWith('assets/')) {
//       return Image.asset(imagePath, height: 80, width: 80, fit: BoxFit.cover);
//     } else {
//       return Image.file(
//         File(imagePath),
//         height: 80,
//         width: 80,
//         fit: BoxFit.cover,
//         errorBuilder: (context, error, stackTrace) => _safeSvgPicture('assets/password_placeholder.svg'),
//       );
//     }
//   }
//
//   Widget _safeSvgPicture(String assetPath) {
//     try {
//       return SvgPicture.asset(
//         assetPath,
//         height: 80,
//         width: 80,
//         placeholderBuilder: (context) => const Icon(Icons.image, size: 40),
//       );
//     } catch (e) {
//       debugPrint("SVG Parsing Error: $e");
//       return Image.asset('assets/default.png', height: 80, width: 80);
//     }
//   }
//
//   void _showDeleteConfirmationDialog(int index) {
//     bool isDeleting = false;
//     final product = fastKeyTabs[index];
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateDialog) {
//             return AlertDialog(
//               title: const Text(TextConstants.deleteTabText),
//               content: const Text(TextConstants.deleteConfirmText),
//               actions: [
//                 TextButton(
//                   onPressed: isDeleting ? null : () => Navigator.pop(context),
//                   child: const Text(TextConstants.noText),
//                 ),
//                 TextButton(
//                   onPressed: isDeleting ? null : () async {
//
//                     setStateDialog(() => isDeleting = true);
//                     await _deleteFastKeyTab(product.fastkeyServerId);
//
//                     if (mounted) {
//                       Navigator.pop(context);
//                       Navigator.pop(context);
//                     }
//                   },
//                   child: isDeleting
//                       ? const CircularProgressIndicator()
//                       : const Text(TextConstants.yesText, style: TextStyle(color: Colors.red)),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pinaka_pos/Helper/Extentions/theme_notifier.dart';
import '../Constants/text.dart';
import '../Utilities/shimmer_effect.dart';
import '../Utilities/responsive_layout.dart';

// Stateless CategoryList widget for reusable horizontal/vertical category list
class CategoryList extends StatelessWidget {
  final bool isHorizontal;
  final bool isLoading;
  final bool isAddButtonEnabled;
  final List<Map<String, dynamic>> categories;
  final int? selectedIndex;
  final int? editingIndex;
  final VoidCallback? onAddButtonPressed;
  final Function(int) onCategoryTapped;
  final Function(int, int) onReorder;
  final Function(int) onEditButtonPressed;
  final Function() onDismissEditMode;

  const CategoryList({
    super.key,
    required this.isHorizontal,
    required this.isLoading,
    required this.isAddButtonEnabled,
    required this.categories,
    this.selectedIndex,
    this.editingIndex,
    this.onAddButtonPressed,
    required this.onCategoryTapped,
    required this.onReorder,
    required this.onEditButtonPressed,
    required this.onDismissEditMode,
  });

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('assets/') && imagePath.endsWith('.svg')) {
      return SvgPicture.asset(
        imagePath,
        height: 40,
        width: 40,
        placeholderBuilder: (context) => const Icon(Icons.image, size: 40),
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: 40,
        width: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
      );
    } else {
      return Image.file(
        File(imagePath),
        height: 40,
        width: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
      );
    }
  }
  bool _doesContentOverflow(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = categories.length * 120;
    return contentWidth > screenWidth;
  }

  Widget _buildHorizontalList(BuildContext context, ScrollController scrollController) {
    var size = MediaQuery.of(context).size;
    ResponsiveLayout.init(context);
    return Container(
      height: ResponsiveLayout.getHeight(100),
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: Colors.white, // Background color for the whole list view
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main scrollable content
          Row(
            children: [
              // Add some padding on the left to make room for the left navigation button
              SizedBox(width:ResponsiveLayout.getWidth(30)),

              Expanded(
                child: SizedBox(
                  height: ResponsiveLayout.getHeight(100),
                  child: ReorderableListView(
                    scrollController: scrollController,
                    scrollDirection: Axis.horizontal,
                    onReorder: onReorder,
                    children: List.generate(categories.length, (index) {
                      final category = categories[index];
                      bool isSelected = selectedIndex == index;
                      bool showEditButton = editingIndex == index;

                      return GestureDetector(
                        key: ValueKey('${category['title']}_$index'),
                        onTap: () => onCategoryTapped(index),
                        onLongPress: () => onEditButtonPressed(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: AnimatedContainer(
                            width: 70,
                            duration: const Duration(milliseconds: 300),
                            //padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                            decoration: BoxDecoration(
                              color: isSelected ? ThemeNotifier.tabSelection : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: showEditButton ? Colors.blueAccent : isSelected ? Colors.red : Colors.black12,
                                width: showEditButton ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                                      onTap: () => onEditButtonPressed(index),
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildImage(category['image']),
                                    Text(
                                      category['title'],
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 12,
                                        overflow: TextOverflow.ellipsis,
                                        fontWeight: FontWeight.normal,
                                        fontVariations: const <FontVariation>[FontVariation('wght', 900.0)],
                                        color: Colors.black87,
                                      ),
                                    ),
                                    // Text(
                                    //   category['itemCount'].toString(),
                                    //   style: TextStyle(
                                    //     color: isSelected ? Colors.white : Colors.grey,
                                    //   ),
                                    // ),
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

              // Add some padding on the right to make room for the right navigation button and add button
              const SizedBox(width: 30),

              if (isAddButtonEnabled)
                _buildAddButton(onAddButtonPressed ?? () {}),
            ],
          ),

          // Positioned navigation buttons that overlay the list edges
          Positioned(
            left: 5,
            child: _buildCircularNavButton(Icons.arrow_back_ios, () {
              scrollController
                  .animateTo(
                scrollController.offset - size.width * 0.5,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }),
          ),

          Positioned(
            right: isAddButtonEnabled ? 105 : 5, // Position to leave room for add button
            child: _buildCircularNavButton(Icons.arrow_forward_ios, () {
              scrollController.animateTo(
                scrollController.offset + size.width * 0.5,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }),
          ),
        ],
      ),
    );
  }

// Updated circular navigation button
  Widget _buildCircularNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 24),
        color: Colors.black45,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

// Updated add button to match list item width
  Widget _buildAddButton(VoidCallback onPressed) {
    return Container(
      height: 110,
      width: 90, // Same width as list items
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFFF7F7),
            blurRadius: 5,
            spreadRadius: 5,
            offset: Offset(0,0),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.redAccent, size: 28,),
        onPressed: onPressed,
      ),
    );
  }


  Widget _buildVerticalList(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.35,
          child: ReorderableListView(
            scrollDirection: Axis.vertical,
            onReorder: onReorder,
            children: List.generate(categories.length, (index) {
              final category = categories[index];
              bool isSelected = selectedIndex == index;
              bool showEditButton = editingIndex == index;

              return GestureDetector(
                key: ValueKey('${category['title']}_$index'),
                onTap: () => onCategoryTapped(index),
                onLongPress: () => onEditButtonPressed(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                  child: AnimatedContainer(
                    width: 120,
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: showEditButton ? Colors.blueAccent : Colors.black12,
                        width: showEditButton ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          right: 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: showEditButton ? 1.0 : 0.0,
                            child: GestureDetector(
                              onTap: () => onEditButtonPressed(index),
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
                        Row(
                          children: [
                            _buildImage(category['image']),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  category['itemCount'].toString(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey,
                                  ),
                                ),
                              ],
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
        const SizedBox(height: 50),
        Container(
          width: MediaQuery.of(context).size.width * 0.35,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: double.infinity,
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.redAccent),
              onPressed: onAddButtonPressed,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    // bool showLeftArrow = false;
    // bool showRightArrow = true;

    // scrollController.addListener(() {
    //   showLeftArrow = scrollController.offset > 0;
    //   showRightArrow = scrollController.offset < scrollController.position.maxScrollExtent;
    // });

    return GestureDetector(
      onTap: onDismissEditMode,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isLoading
            ? ShimmerEffect.rectangular(
          height: isHorizontal ? 100 : 800,
        )
            : isHorizontal
            ? _buildHorizontalList(context, scrollController)
            : _buildVerticalList(context),
      ),
    );
  }
}
