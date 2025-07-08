// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import '../Constants/text.dart';
// import '../Utilities/constants.dart';
//
// class TopBar extends StatelessWidget { // Old Code
//   final Function() onModeChanged;
//
//   const TopBar({required this.onModeChanged, Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context); // Build #1.0.6 - Added theme for top bar
//     return Container(
//       height: 60,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//      // color: theme.appBarTheme.backgroundColor,
//       child: Row(
//         children: [
//           SvgPicture.asset(
//             'assets/svg/app_logo.svg',
//             height: 40,
//             width: 40,
//           ),
//           const SizedBox(width: 140),
//            Expanded(
//             child: Container( // Build #1.0.6
//               height: 50,
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: AppConstants.searchHint,
//                   prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.all(Radius.circular(8)),
//                     borderSide: BorderSide.none,
//                   ),
//                   filled: true,
//                  // fillColor: theme.dividerColor,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 140),
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 onPressed: () {},
//                 icon: const Icon(Icons.calculate),
//               ),
//               const Text(
//                 TextConstants.calculatorText,
//                 style: TextStyle(fontSize: 8),
//               ),
//             ],
//           ),
//           const SizedBox(width: 8),
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 onPressed: () {},
//                 icon: const Icon(Icons.pause),
//               ),
//               const Text(
//                 TextConstants.holdText,
//                 style: TextStyle(fontSize: 8),
//               ),
//             ],
//           ),
//           const SizedBox(width: 8),
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 onPressed: onModeChanged,
//                 icon: const Icon(Icons.switch_right),
//               ),
//               const Text(
//                 TextConstants.modeText,
//                 style: TextStyle(fontSize: 8),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Widgets/widget_variants_dialog.dart';
import 'package:provider/provider.dart';
import '../Blocs/Orders/order_bloc.dart';
import '../Blocs/Search/product_search_bloc.dart';
import '../Constants/text.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
import '../Database/user_db_helper.dart';
import '../Helper/Extentions/theme_notifier.dart';
import '../Helper/api_response.dart';
import '../Models/Orders/orders_model.dart';
import '../Models/Search/product_search_model.dart';
import '../Models/Search/product_variation_model.dart';
import '../Repositories/Orders/order_repository.dart';
import '../Repositories/Search/product_search_repository.dart';
import '../Utilities/responsive_layout.dart';

class TopBar extends StatefulWidget { // Build #1.0.13 : Updated top bar with search api integration
  final Function() onModeChanged;
  final Function(ProductResponse)? onProductSelected;

  const TopBar({
    required this.onModeChanged,
    this.onProductSelected,
    Key? key,
  }) : super(key: key);

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  final ProductBloc _productBloc = ProductBloc(ProductRepository());
  OverlayEntry? _overlayEntry;
  final GlobalKey _searchFieldKey = GlobalKey();
  final OrderHelper orderHelper = OrderHelper();
  late OrderBloc _orderBloc;
  StreamSubscription? _updateOrderSubscription;
  bool isAddingItemLoading = false; // Loader for adding items to order
  int? userId;
  String? userRole;
  String? userDisplayName;

  @override
  void initState() {
    super.initState();
    _orderBloc = OrderBloc(OrderRepository());
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _fetchUserId();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    _productBloc.dispose();
    _orderBloc.dispose();
    _removeOverlay();
    super.dispose();
  }

  // This method creates a semi-transparent overlay with a centered CircularProgressIndicator to indicate loading during API calls.
  // It reuses _overlayEntry to manage the overlay, ensuring only one overlay is shown at a time.
  void _showLoaderOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _showSearchResultsOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _productBloc.fetchProducts(searchQuery: _searchController.text);
        if (_searchFocusNode.hasFocus) {
          _showSearchResultsOverlay();
        }
      } else {
        _removeOverlay();
      }
      setState(() {}); // Rebuild to update clear button visibility
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _removeOverlay();
    _searchFocusNode.unfocus();
    setState(() {}); // Rebuild to hide clear button
  }

  void _showSearchResultsOverlay() {
    _removeOverlay();

    final searchFieldBox = _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (searchFieldBox == null) return;

    final searchFieldOffset = searchFieldBox.localToGlobal(Offset.zero);
    final searchFieldSize = searchFieldBox.size;

    _overlayEntry = OverlayEntry(
        builder: (context) {
          final themeHelper = Provider.of<ThemeNotifier>(context);
          return Positioned(
          width: searchFieldSize.width,
          left: searchFieldOffset.dx,
          top: searchFieldOffset.dy + searchFieldSize.height,
          child: Material(
            elevation: 4,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color:themeHelper.themeMode == ThemeMode.dark
                      ? ThemeNotifier.secondaryBackground
                      : Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: StreamBuilder<APIResponse<List<ProductResponse>>>(
                stream: _productBloc.productStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    switch (snapshot.data!.status) {
                      case Status.LOADING:
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      case Status.COMPLETED:
                        final products = snapshot.data!.data;
                        if (products == null || products.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No products found'),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ListTile(
                              leading: product.images != null && product.images!.isNotEmpty
                                  ? Image.network(
                                product.images!.first,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                                  : const Icon(Icons.image),
                              title: Text(product.name ?? ''),
                              subtitle: Text('\$${product.price ?? '0.00'}'),
                                onTap: () async {
                                ///Comment below code not we are using only server order id as to check orders, skip checking db order id
                                  // final order = orderHelper.orders.firstWhere(
                                  //       (order) => order[AppDBConst.orderId] == orderHelper.activeOrderId,
                                  //   orElse: () => {},
                                  // );
                                  final serverOrderId = orderHelper.activeOrderId;//order[AppDBConst.orderServerId] as int?;
                                  final dbOrderId = orderHelper.activeOrderId;

                                  if (dbOrderId == null) {
                                    if (kDebugMode) print("No active order selected");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("No active order selected"),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }

                                  _productBloc.fetchProductVariations(product.id!);
                                  await showDialog(
                                    context: context,
                                    builder: (context) => StreamBuilder<APIResponse<List<ProductVariation>>>(
                                      stream: _productBloc.variationStream,
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData || snapshot.data!.status == Status.LOADING) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        if (snapshot.data!.status == Status.COMPLETED) {
                                          final variations = snapshot.data!.data!;
                                          if (variations.isNotEmpty) {
                                            return VariantsDialog(
                                              title: product.name ?? '',
                                              variations: variations.map((v) => {
                                                "id": v.id,
                                                "name": v.name,
                                                "price": v.regularPrice,
                                                "image": v.image.src,
                                                "sku": v.sku ?? 'SKU${v.name}',
                                              }).toList(),
                                              onAddVariant: (variant, quantity) async {
                                                setState(() => isAddingItemLoading = true);
                                                _showLoaderOverlay();
                                                try {
                                                  if (serverOrderId != null) {
                                                    _updateOrderSubscription?.cancel();
                                                    _updateOrderSubscription = _orderBloc.updateOrderStream.listen(
                                                          (response) async {
                                                        if (!mounted) {
                                                          _updateOrderSubscription?.cancel();
                                                          return;
                                                        }
                                                        setState(() => isAddingItemLoading = false);
                                                        _removeOverlay();
                                                        if (response.status == Status.LOADING) { // Build #1.0.80
                                                          const Center(child: CircularProgressIndicator());
                                                        }else if (response.status == Status.COMPLETED) {
                                                          if (kDebugMode) print("Variant added to order $dbOrderId via API");
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text("Variant '${variant['name']}' added to order"),
                                                              backgroundColor: Colors.green,
                                                              duration: const Duration(seconds: 2),
                                                            ),
                                                          );
                                                          Navigator.pop(context);
                                                          _clearSearch();
                                                          widget.onProductSelected?.call(ProductResponse(
                                                            id: variant["id"],
                                                            name: variant["name"],
                                                            price: variant["price"].toString(),
                                                            images: [variant["image"]],
                                                            sku: variant["sku"],
                                                          ));
                                                          _updateOrderSubscription?.cancel();
                                                        } else if (response.status == Status.ERROR) {
                                                          if (kDebugMode) print("Error adding variant: ${response.message}");
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(response.message ?? 'Failed to add variant'),
                                                              backgroundColor: Colors.red,
                                                              duration: const Duration(seconds: 2),
                                                            ),
                                                          );
                                                          _updateOrderSubscription?.cancel();
                                                        }
                                                      },
                                                    );
                                                    /// API CALL
                                                    await _orderBloc.updateOrderProducts(
                                                      orderId: serverOrderId,
                                                      dbOrderId: dbOrderId,
                                                      lineItems: [
                                                        OrderLineItem(
                                                          productId: variant["id"],
                                                          quantity: quantity,
                                                        //  sku: variant["sku"],
                                                        ),
                                                      ],
                                                    );
                                                  } else {
                                                    // await orderHelper.addItemToOrder(
                                                    //   variant["id"],
                                                    //   variant["name"],
                                                    //   variant["image"],
                                                    //   double.tryParse(variant["price"].toString()) ?? 0.0,
                                                    //   quantity,
                                                    //   variant["sku"],
                                                    //   onItemAdded: () {
                                                    //     Navigator.pop(context);
                                                    //     _clearSearch();
                                                    //     widget.onProductSelected?.call(ProductResponse(
                                                    //       id: variant["id"],
                                                    //       name: variant["name"],
                                                    //       price: variant["price"].toString(),
                                                    //       images: [variant["image"]],
                                                    //       sku: variant["sku"],
                                                    //     ));
                                                    //   },
                                                    // );
                                                    setState(() => isAddingItemLoading = false);
                                                    _removeOverlay();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("Variant '${variant['name']}' did not added to order. OrderId not found."),
                                                        backgroundColor: Colors.green,
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                } catch (e,s) {
                                                  if (kDebugMode) print("Exception adding variant: $e, Stack: $s");
                                                  setState(() => isAddingItemLoading = false);
                                                  _removeOverlay();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text("Error adding variant."),
                                                      backgroundColor: Colors.red,
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                            );
                                          } else {
                                            // Add parent product only if no variants
                                            setState(() => isAddingItemLoading = true);
                                            _showLoaderOverlay();
                                            try {
                                              if (serverOrderId != null) {
                                                _updateOrderSubscription?.cancel();

                                                _updateOrderSubscription = _orderBloc.updateOrderStream.listen(
                                                      (response) async {
                                                    if (!mounted) {
                                                      _updateOrderSubscription?.cancel();
                                                      return;
                                                    }
                                                    setState(() => isAddingItemLoading = false);
                                                    _removeOverlay();
                                                    if (response.status == Status.LOADING) { // Build #1.0.80
                                                      const Center(child: CircularProgressIndicator());
                                                    }else if (response.status == Status.COMPLETED) {
                                                      if (kDebugMode) print("Product added to order $dbOrderId via API");
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text("Product '${product.name}' added to order"),
                                                          backgroundColor: Colors.green,
                                                          duration: const Duration(seconds: 2),
                                                        ),
                                                      );
                                                      Navigator.pop(context);
                                                      _clearSearch();
                                                      widget.onProductSelected?.call(product);
                                                      _updateOrderSubscription?.cancel();
                                                    } else if (response.status == Status.ERROR) {
                                                      if (kDebugMode) print("Error adding product: ${response.message}");
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(response.message ?? 'Failed to add product'),
                                                          backgroundColor: Colors.red,
                                                          duration: const Duration(seconds: 2),
                                                        ),
                                                      );
                                                      _updateOrderSubscription?.cancel();
                                                    }
                                                  },
                                                );

                                                 _orderBloc.updateOrderProducts(
                                                  orderId: serverOrderId,
                                                  dbOrderId: dbOrderId,
                                                  lineItems: [
                                                    OrderLineItem(
                                                      productId: product.id!,
                                                      quantity: 1,
                                                     // sku: product.sku ?? 'SKU${product.name}',
                                                    ),
                                                  ],
                                                );
                                              } else {
                                                //  orderHelper.addItemToOrder(
                                                //   product.id!,
                                                //   product.name ?? 'Unknown',
                                                //   product.images?.isNotEmpty == true ? product.images!.first : '',
                                                //   double.tryParse(product.price ?? '0.00') ?? 0.0,
                                                //   1,
                                                //   product.sku ?? 'SKU${product.name}',
                                                //   onItemAdded: () {
                                                //     Navigator.pop(context);
                                                //     _clearSearch();
                                                //     widget.onProductSelected?.call(product);
                                                //   },
                                                // );
                                                setState(() => isAddingItemLoading = false);
                                                _removeOverlay();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Product '${product.name}' did not added to order. OrderId not found."),
                                                    backgroundColor: Colors.green,
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } catch (e,s) {
                                              if (kDebugMode) print("Exception adding product: $e, Stack: $s");
                                              setState(() => isAddingItemLoading = false);
                                              _removeOverlay();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("Error adding product"),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  );
                                }
                            );
                          },
                        );
                      case Status.ERROR:
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(snapshot.data!.message ?? 'Error loading products',
                          style: TextStyle(
                                color: themeHelper.themeMode == ThemeMode.dark
                                    ? ThemeNotifier.textDark
                                    : ThemeNotifier.textLight,
                              ),
                            ),
                        );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        }

    );

        Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _fetchUserId() async { // Build #1.0.29: get the userId from db
    final userData = await UserDbHelper().getUserData();
    if (userData != null && userData[AppDBConst.userId] != null) {
      setState(() {
        userId = userData[AppDBConst.userId] as int;
        userDisplayName = userData[AppDBConst.userDisplayName];
        userRole = userData[AppDBConst.userRole];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : ThemeNotifier.lightBackground,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            themeHelper.themeMode == ThemeMode.dark ? 'assets/svg/app_logo.svg' : 'assets/svg/app_icon.svg',
            height: 40,
            width: 40,
          ),
          const SizedBox(width: 140),
          Expanded(
            child: Container(
              height: 50,
              key: _searchFieldKey,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: TextConstants.searchHint,
                  prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: theme.iconTheme.color),
                    onPressed: _clearSearch,
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.searchBarBackground : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 140),
          // Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     IconButton(
          //       onPressed: () {},
          //       icon: const Icon(Icons.calculate),
          //     ),
          //     const Text(
          //       TextConstants.calculatorText,
          //       style: TextStyle(fontSize: 8),
          //     ),
          //   ],
          // ),
          // const SizedBox(width: 8),
          // Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     IconButton(
          //       onPressed: () {},
          //       icon: const Icon(Icons.pause),
          //     ),
          //     const Text(
          //       TextConstants.holdText,
          //       style: TextStyle(fontSize: 8),
          //     ),
          //   ],
          // ),
          // const SizedBox(width: 8),
          Row(
            children: [
              Container(
                height: 45,
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0
                ),
                decoration: BoxDecoration(
                  color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        (userDisplayName ?? "Unknown").substring(0,1), // "A", /// use initial for the login user
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userDisplayName ?? "", // 'A Raghav Kumar', /// use login user display name
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.textDark : ThemeNotifier.textLight,
                              fontSize: 14),
                        ),
                        Text(
                          userRole ?? "Unknown", // 'I am Cashier', /// use user role
                          style: TextStyle(
                              color: themeHelper.themeMode == ThemeMode.dark ? Colors.grey[400] : Colors.grey,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.secondaryBackground : Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 24,
                  color: themeHelper.themeMode == ThemeMode.dark ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: widget.onModeChanged,
                icon: const Icon(Icons.switch_right),
              ),
              const Text(
                TextConstants.modeText,
                style: TextStyle(fontSize: 8),
              ),
            ],
          ),
          // User profile section with container and notification bell

        ],
      ),
    );
  }
}