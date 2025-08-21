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
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import '../Blocs/Orders/order_bloc.dart';
import '../Blocs/Search/product_search_bloc.dart';
import '../Constants/text.dart';
import '../Database/db_helper.dart';
import '../Database/order_panel_db_helper.dart';
import '../Database/user_db_helper.dart';
import '../Helper/Extentions/theme_notifier.dart';
import '../Helper/api_response.dart';
import '../Models/Orders/get_orders_model.dart' as model;
import '../Models/Orders/orders_model.dart';
import '../Models/Search/product_search_model.dart';
import '../Models/Search/product_variation_model.dart';
import '../Providers/Age/age_verification_provider.dart';
import '../Repositories/Orders/order_repository.dart';
import '../Repositories/Search/product_search_repository.dart';
import '../Utilities/responsive_layout.dart';
import 'package:pinaka_pos/Models/Search/product_by_sku_model.dart' as SKU;

import '../Utilities/svg_images_utility.dart';
enum Screen { FASTKEY, CATEGORY, ADD, ORDERS, APPS, SHIFT, SAFE, EDIT }
class TopBar extends StatefulWidget { // Build #1.0.13 : Updated top bar with search api integration
  final Function() onModeChanged;
  // final Function() onThemeChanged;
  final Function(ProductResponse)? onProductSelected;
  final Screen screen;

  const TopBar({
    required this.screen,
    required this.onModeChanged,
    // required this.onThemeChanged,
    this.onProductSelected,
    Key? key,
  }) : super(key: key);

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late BuildContext _context;
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
  String? _lastSearchQuery; // Build #1.0.120: Track last searched query to avoid redundant fetches

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
    _updateOrderSubscription?.cancel(); // Add this if missing
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

  void _onFocusChanged() { // Build #1.0.120: Fixed : result are reloading after dismissal of keypad
    if (kDebugMode) {
      print("TopBar - _onFocusChanged: hasFocus=${_searchFocusNode.hasFocus}, text='${_searchController.text}', overlayExists=${_overlayEntry != null}");
    }
    // Show overlay only if text field has focus, text is not empty, and no overlay exists
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty && _overlayEntry == null) {
      _showSearchResultsOverlay();
    } else if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () { // Build #1.0.120: Fixed : result are reloading after dismissal of keypad
      if (kDebugMode) {
        print("TopBar - _onSearchChanged: Debounce timer completed, processing search for '${_searchController.text}'");
      }

      //Build #1.0.134: fixed - shoes getting overlapped with age verification dialog
      // Only proceed if we have focus and text has actually changed
      if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty && _searchController.text != _lastSearchQuery) {
        if (kDebugMode) {
          print("TopBar - _onSearchChanged: Fetching products for new query '${_searchController.text}'");
        }
        _lastSearchQuery = _searchController.text;
        _productBloc.fetchProducts(searchQuery: _searchController.text);

        if (_overlayEntry == null) { // Show overlay only if text field has focus and no overlay exists
          _showSearchResultsOverlay();
        }
      } else if (_searchController.text.isEmpty) {
        _lastSearchQuery = null;
        _removeOverlay();
      }
      setState(() {}); // Rebuild to update clear button visibility
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _lastSearchQuery = null;
    _removeOverlay();
    _searchFocusNode.unfocus();
    setState(() {}); // Rebuild to hide clear button
  }

  void _showSearchResultsOverlay() {
    if (_overlayEntry != null) return; // Prevent duplicate overlays

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
                        if (kDebugMode) print("#### 2222 Status is LOADING");
                        // return const Center( //
                        //   child: Padding(
                        //     padding: EdgeInsets.all(16),
                        //     child: CircularProgressIndicator(),
                        //   ),
                        // );
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
                                  ? SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Image.network(
                                        product.images!.first,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.image, size: 40);
                                          },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.image, size: 40,),
                              title: Text(product.name ?? ''),
                              subtitle: Text('${TextConstants.currencySymbol}${double.tryParse(product.price.toString())?.toStringAsFixed(2) ?? "0.00"}'),
                                onTap: () async {
                                  //Build #1.0.134: fixed - shoes getting overlapped with age verification dialog
                                  // Immediately remove focus and overlay when an item is tapped
                                  _searchFocusNode.unfocus();
                                  _removeOverlay();
                                var screen = this.widget.screen;
                                 if(screen != Screen.FASTKEY && screen != Screen.CATEGORY && screen != Screen.ADD ) {
                                   if (kDebugMode) {
                                     print("TopBar - return from product selection onTap line #286");
                                   }
                                  return;
                                }

                                ///Comment below code not we are using only server order id as to check orders, skip checking db order id
                                  // final order = orderHelper.orders.firstWhere(
                                  //       (order) => order[AppDBConst.orderId] == orderHelper.activeOrderId,
                                  //   orElse: () => {},
                                  // );
                                  final serverOrderId = orderHelper.activeOrderId;//order[AppDBConst.orderServerId] as int?;
                                  final dbOrderId = orderHelper.activeOrderId;
                                /// Build #1.0.128: No need to check this condition here
                                  // if (dbOrderId == null) {
                                  //   if (kDebugMode) print("No active order selected");
                                  //   ScaffoldMessenger.of(_context).showSnackBar(
                                  //     const SnackBar(
                                  //       content: Text("No active order selected"),
                                  //       backgroundColor: Colors.red,
                                  //       duration: Duration(seconds: 2),
                                  //     ),
                                  //   );
                                  //   return;
                                  // }
                                  // Build #1.0.108: Fixed Issue: Verify Age and proceed else return
                                  final ageVerificationProvider = AgeVerificationProvider();
                                  final ageRestrictedTag = product.tags?.firstWhere(
                                        (element) => element.name == TextConstants.ageRestricted,
                                    orElse: () => SKU.Tags(),
                                  );
                                  // Check if product has age restriction
                                  final hasAgeRestriction = ageRestrictedTag?.name?.contains(TextConstants.ageRestricted) ?? false;
                                  if (kDebugMode) {
                                    print("TopBar - AgeVerification: Product has age restriction: $hasAgeRestriction, product.variations : ${product.variations!.isNotEmpty}");
                                  }

                                  if(product.variations!.isNotEmpty) {
                                    _clearSearch();
                                  }
                                  if (hasAgeRestriction) {
                                    final minimumAgeSlug = ageRestrictedTag?.slug;
                                    final isVerified = await ageVerificationProvider.verifyAge(context, minAge: int.tryParse(minimumAgeSlug!) ?? 0);
                                    if (!isVerified) {
                                      if (kDebugMode) {
                                        print("TopBar - AgeVerification: Age verification failed or cancelled: $isVerified");
                                      }
                                      return;
                                    }
                                  }

                                if (kDebugMode) {
                                  print("TopBar - product.variations : ${product.variations!.isNotEmpty}");
                                }
                                  if(product.variations!.isNotEmpty) {
                                  // _clearSearch();
                                  _productBloc.fetchProductVariations(product.id!);
                                  await showDialog(
                                    context: _context,
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
                                              variations: variations
                                                  .map((v) => {
                                                        "id": v.id,
                                                        "name": v.name,
                                                        "price": v.regularPrice,
                                                        "image": v.image.src,
                                                        "sku": v.sku ??
                                                            'SKU${v.name}',
                                                      })
                                                  .toList(),
                                              onAddVariant:
                                                  (variant, quantity) async {
                                                setState(() =>
                                                    isAddingItemLoading = true);
                                                _showLoaderOverlay();
                                                try {
                                                //  if (serverOrderId != null) { /// Build #1.0.128: No need to check this condition here
                                                    _updateOrderSubscription
                                                        ?.cancel();
                                                    _updateOrderSubscription =
                                                        _orderBloc
                                                            .updateOrderStream
                                                            .listen(
                                                      (response) async {
                                                        if (!mounted) {
                                                          _updateOrderSubscription
                                                              ?.cancel();
                                                          return;
                                                        }
                                                        setState(() =>
                                                            isAddingItemLoading =
                                                                false);
                                                        _removeOverlay();
                                                        if (response.status ==
                                                            Status.LOADING) {
                                                          // Build #1.0.80
                                                          const Center(
                                                              child:
                                                                  CircularProgressIndicator());
                                                        } else if (response
                                                                .status ==
                                                            Status.COMPLETED) {
                                                          if (kDebugMode)
                                                            print(
                                                                "Variant added to order $dbOrderId via API");
                                                          ScaffoldMessenger.of(
                                                                  _context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  "Variant '${variant['name']}' added to order"),
                                                              backgroundColor:
                                                                  Colors.green,
                                                              duration:
                                                                  const Duration(
                                                                      seconds:
                                                                          2),
                                                            ),
                                                          );
                                                          Navigator.pop(
                                                              context);
                                                          _clearSearch();
                                                          widget
                                                              .onProductSelected
                                                              ?.call(
                                                                  ProductResponse(
                                                            id: variant["id"],
                                                            name:
                                                                variant["name"],
                                                            price:
                                                                variant["price"]
                                                                    .toString(),
                                                            images: [
                                                              variant["image"]
                                                            ],
                                                            sku: variant["sku"],
                                                          ));
                                                          _updateOrderSubscription
                                                              ?.cancel();
                                                        } else if (response
                                                                .status ==
                                                            Status.ERROR) {
                                                          if (kDebugMode)
                                                            print(
                                                                "Error adding variant: ${response.message}");
                                                          ScaffoldMessenger.of(
                                                                  _context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(response
                                                                      .message ??
                                                                  'Failed to add variant'),
                                                              backgroundColor:
                                                                  Colors.red,
                                                              duration:
                                                                  const Duration(
                                                                      seconds:
                                                                          2),
                                                            ),
                                                          );
                                                          _updateOrderSubscription
                                                              ?.cancel();
                                                        }
                                                      },
                                                    );

                                                    /// API CALL
                                                    await _orderBloc
                                                        .updateOrderProducts(
                                                      orderId: serverOrderId,
                                                      dbOrderId: dbOrderId,
                                                      lineItems: [
                                                        OrderLineItem(
                                                          productId:
                                                              variant["id"],
                                                          quantity: quantity,
                                                          //  sku: variant["sku"],
                                                        ),
                                                      ],
                                                    );
                                                  // } else { /// Build #1.0.128: No need to check this condition here
                                                  //   // await orderHelper.addItemToOrder(
                                                  //   //   variant["id"],
                                                  //   //   variant["name"],
                                                  //   //   variant["image"],
                                                  //   //   double.tryParse(variant["price"].toString()) ?? 0.0,
                                                  //   //   quantity,
                                                  //   //   variant["sku"],
                                                  //   //   onItemAdded: () {
                                                  //   //     Navigator.pop(context);
                                                  //   //     _clearSearch();
                                                  //   //     widget.onProductSelected?.call(ProductResponse(
                                                  //   //       id: variant["id"],
                                                  //   //       name: variant["name"],
                                                  //   //       price: variant["price"].toString(),
                                                  //   //       images: [variant["image"]],
                                                  //   //       sku: variant["sku"],
                                                  //   //     ));
                                                  //   //   },
                                                  //   // );
                                                  //   setState(() =>
                                                  //       isAddingItemLoading =
                                                  //           false);
                                                  //   _removeOverlay();
                                                  //   ScaffoldMessenger.of(
                                                  //           _context)
                                                  //       .showSnackBar(
                                                  //     SnackBar(
                                                  //       content: Text(
                                                  //           "Variant '${variant['name']}' did not added to order. OrderId not found."),
                                                  //       backgroundColor:
                                                  //           Colors.green,
                                                  //       duration:
                                                  //           const Duration(
                                                  //               seconds: 2),
                                                  //     ),
                                                  //   );
                                                  // }
                                                } catch (e, s) {
                                                  if (kDebugMode)
                                                    print(
                                                        "Exception adding variant: $e, Stack: $s");
                                                  setState(() =>
                                                      isAddingItemLoading =
                                                          false);
                                                  _removeOverlay();
                                                  ScaffoldMessenger.of(_context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          "Error adding variant."),
                                                      backgroundColor:
                                                          Colors.red,
                                                      duration: const Duration(
                                                          seconds: 2),
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
                                             // if (serverOrderId != null) { /// Build #1.0.128: No need to check this condition here
                                                _updateOrderSubscription?.cancel();
                                                _updateOrderSubscription = _orderBloc.updateOrderStream.listen((response) async {
                                                    if (!mounted) {
                                                      _updateOrderSubscription?.cancel();
                                                      return;
                                                    }
                                                    setState(() => isAddingItemLoading = false);
                                                    _removeOverlay();
                                                    if (response.status == Status.LOADING) {
                                                      // Build #1.0.80
                                                      const Center(child: CircularProgressIndicator());
                                                    } else if (response.status == Status.COMPLETED) {
                                                      if (kDebugMode)
                                                        print("Product added to order $dbOrderId via API");
                                                      ScaffoldMessenger.of(_context).showSnackBar(
                                                        SnackBar(
                                                          content: Text("Product '${product.name}' added to order"),
                                                          backgroundColor: Colors.green,
                                                          duration: const Duration(seconds: 2),
                                                        ),
                                                      );
                                                      Navigator.pop(context);
                                                      _clearSearch();
                                                      widget.onProductSelected
                                                          ?.call(product);
                                                      _updateOrderSubscription
                                                          ?.cancel();
                                                    } else if (response
                                                            .status ==
                                                        Status.ERROR) {
                                                      if (kDebugMode)
                                                        print(
                                                            "Error adding product: ${response.message}");
                                                      ScaffoldMessenger.of(
                                                              _context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(response
                                                                  .message ??
                                                              'Failed to add product'),
                                                          backgroundColor:
                                                              Colors.red,
                                                          duration:
                                                              const Duration(
                                                                  seconds: 2),
                                                        ),
                                                      );
                                                      _updateOrderSubscription
                                                          ?.cancel();
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
                                              // } else { /// Build #1.0.128: No need to check this condition here
                                              //   //  orderHelper.addItemToOrder(
                                              //   //   product.id!,
                                              //   //   product.name ?? 'Unknown',
                                              //   //   product.images?.isNotEmpty == true ? product.images!.first : '',
                                              //   //   double.tryParse(product.price ?? '0.00') ?? 0.0,
                                              //   //   1,
                                              //   //   product.sku ?? 'SKU${product.name}',
                                              //   //   onItemAdded: () {
                                              //   //     Navigator.pop(context);
                                              //   //     _clearSearch();
                                              //   //     widget.onProductSelected?.call(product);
                                              //   //   },
                                              //   // );
                                              //   setState(() =>
                                              //       isAddingItemLoading =
                                              //           false);
                                              //   _removeOverlay();
                                              //   ScaffoldMessenger.of(_context)
                                              //       .showSnackBar(
                                              //     SnackBar(
                                              //       content: Text(
                                              //           "Product '${product.name}' did not added to order. OrderId not found."),
                                              //       backgroundColor:
                                              //           Colors.green,
                                              //       duration: const Duration(
                                              //           seconds: 2),
                                              //     ),
                                              //   );
                                              // }
                                            } catch (e, s) {
                                              if (kDebugMode)
                                                print(
                                                    "Exception adding product: $e, Stack: $s");
                                              setState(() =>
                                                  isAddingItemLoading = false);
                                              _removeOverlay();
                                              ScaffoldMessenger.of(_context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      "Error adding product"),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(
                                                      seconds: 2),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  );
                                } else {

                                    // Add parent product only if no variants
                                    // setState(() => isAddingItemLoading = true);
                                    // _showLoaderOverlay();
                                    // _orderBloc.updateOrderProducts(
                                    //   orderId: serverOrderId ?? 0,
                                    //   dbOrderId: dbOrderId,
                                    //   lineItems: [
                                    //     OrderLineItem(
                                    //       productId: product.id!,
                                    //       quantity: 1,
                                    //       // sku: product.sku ?? 'SKU${product.name}',
                                    //     ),
                                    //   ],
                                    // );
                                    //
                                    // await showDialog(
                                    //     context: context,
                                    //     builder: (context) => StreamBuilder<APIResponse<model.OrderModel>>(
                                    //     stream: _orderBloc.updateOrderStream,
                                    //     builder: (context, snapshot) {
                                    //       if(snapshot.data == null || !snapshot.hasData || snapshot.data!.status == Status.LOADING)
                                    //         {
                                    //           return const Center(child: CircularProgressIndicator());
                                    //         }
                                    //       var response = snapshot.data!;
                                    //       if (kDebugMode) {
                                    //         print("TopBar updateOrderStream with response: $response via API");
                                    //       }
                                    //       if (response.status == Status.LOADING) {
                                    //         // Build #1.0.80
                                    //         const Center(child: CircularProgressIndicator());
                                    //       } else if (response.status == Status.COMPLETED) {
                                    //         if (kDebugMode) {
                                    //           print("Product added to order $dbOrderId via API");
                                    //         }
                                    //         WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                    //           ScaffoldMessenger.of(context).showSnackBar(
                                    //             SnackBar(
                                    //               content: Text("Product '${product.name}' added to order"),
                                    //               backgroundColor:
                                    //               Colors.green,
                                    //               duration:
                                    //               const Duration(seconds: 2),
                                    //             ),
                                    //           );
                                    //         });
                                    //         Navigator.pop(context);
                                    //         // _clearSearch();
                                    //         widget.onProductSelected?.call(product);
                                    //       } else if (response.status == Status.ERROR) {
                                    //         if (kDebugMode)
                                    //           print("Error adding product: ${response.message}");
                                    //         WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                    //           ScaffoldMessenger.of(context).showSnackBar(
                                    //             SnackBar(content: Text(response
                                    //                 .message ??
                                    //                 'Failed to add product'),
                                    //               backgroundColor:
                                    //               Colors.red,
                                    //               duration:
                                    //               const Duration(
                                    //                   seconds: 2),
                                    //             ),
                                    //           );
                                    //         });
                                    //       }
                                    //       return const SizedBox.shrink();
                                    //     }, ),);
                                    /// Use FutureBuilder instead below code

                                    // Add parent product only if no variants
                                    setState(() => isAddingItemLoading = true);
                                    _showLoaderOverlay();
                                    try {
                                     // if (serverOrderId != null) { /// Build #1.0.128: No need to check this condition here
                                        _updateOrderSubscription?.cancel();
                                        _updateOrderSubscription = _orderBloc.updateOrderStream.listen((response) async {
                                                if (!mounted) {
                                                  _updateOrderSubscription?.cancel();
                                                  return;
                                                }
                                                //setState(() => isAddingItemLoading = false);
                                                // _removeOverlay();
                                                if (response.status == Status.LOADING) {
                                                  // Build #1.0.80
                                                  const Center(child: CircularProgressIndicator());
                                                } else if (response.status == Status.COMPLETED) {
                                                  if (kDebugMode)
                                                    print("Product added to order $dbOrderId via API");
                                                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                                    ScaffoldMessenger.of(_context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("Product '${product.name}' added to order"),
                                                        backgroundColor:
                                                        Colors.green,
                                                        duration:
                                                        const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  });
                                                  // Navigator.pop(context);
                                                  _clearSearch();
                                                  widget.onProductSelected?.call(product);
                                                  _updateOrderSubscription?.cancel();
                                                } else if (response.status == Status.ERROR) {
                                                  if (kDebugMode)
                                                    print("Error adding product: ${response.message}");
                                                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                                    ScaffoldMessenger.of(_context).showSnackBar(
                                                      SnackBar(content: Text(response
                                                          .message ??
                                                          'Failed to add product'),
                                                        backgroundColor:
                                                        Colors.red,
                                                        duration:
                                                        const Duration(
                                                            seconds: 2),
                                                      ),
                                                    );
                                                  });
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
                                      // } else { /// Build #1.0.128: No need to check this condition here
                                      //   //  orderHelper.addItemToOrder(
                                      //   //   product.id!,
                                      //   //   product.name ?? 'Unknown',
                                      //   //   product.images?.isNotEmpty == true ? product.images!.first : '',
                                      //   //   double.tryParse(product.price ?? '0.00') ?? 0.0,
                                      //   //   1,
                                      //   //   product.sku ?? 'SKU${product.name}',
                                      //   //   onItemAdded: () {
                                      //   //     Navigator.pop(context);
                                      //   //     _clearSearch();
                                      //   //     widget.onProductSelected?.call(product);
                                      //   //   },
                                      //   // );
                                      //   setState(() =>
                                      //   isAddingItemLoading =
                                      //   false);
                                      //   _removeOverlay();
                                      //   ScaffoldMessenger.of(_context)
                                      //       .showSnackBar(
                                      //     SnackBar(
                                      //       content: Text(
                                      //           "Product '${product.name}' did not added to order. OrderId not found."),
                                      //       backgroundColor:
                                      //       Colors.green,
                                      //       duration: const Duration(
                                      //           seconds: 2),
                                      //     ),
                                      //   );
                                      // }
                                    } catch (e, s) {
                                      if (kDebugMode)
                                        print(
                                            "Exception adding product: $e, Stack: $s");
                                      setState(() =>
                                      isAddingItemLoading = false);
                                      _removeOverlay();
                                      ScaffoldMessenger.of(_context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              "Error adding product"),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(
                                              seconds: 2),
                                        ),
                                      );
                                    }
                                  }
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
        if (kDebugMode) { // Build #1.0.148: tested using debug prints
          print("##### userId 00000 : $userId");
          print("##### userDisplayName 55555 : $userDisplayName");
        }
        userRole = userData[AppDBConst.userRole];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    final theme = Theme.of(context);
    final themeHelper = Provider.of<ThemeNotifier>(context);
    return Container(
      color: themeHelper.themeMode == ThemeMode.dark ? ThemeNotifier.primaryBackground : Colors.white,
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: themeHelper.themeMode == ThemeMode.dark
                        ? ThemeNotifier.shadow_F7 : Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 2,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              height: 50,
              key: _searchFieldKey,
              child: TextField(
                enabled: widget.screen != Screen.ORDERS,
                controller: _searchController,
                onSubmitted: (value) {
                  if (kDebugMode) {
                    print("TopBar - TextField onSubmitted: Value='$value', overlayExists=${_overlayEntry != null}, lastQuery='$_lastSearchQuery'");
                  }
                  // Build #1.0.120: Fixed : result are reloading after dismissal of keypad
                  // Do not re-show overlay if it already exists or query hasn't changed
                  if (value.isNotEmpty && _overlayEntry == null && value != _lastSearchQuery) {
                    if (kDebugMode) {
                      print("TopBar - TextField onSubmitted: Showing search results overlay for new query");
                    }
                    _lastSearchQuery = value;
                    _productBloc.fetchProducts(searchQuery: value);
                    _showSearchResultsOverlay();
                  }
                },
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: TextConstants.searchHint,
                  prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                  // Build #1.0.108: added loader for auto search items loading instead of (x)
                  suffixIcon: StreamBuilder<APIResponse<List<ProductResponse>>>(
                    stream: _productBloc.productStream,
                    builder: (context, snapshot) {
                      // Show loader when loading
                      if (snapshot.hasData && snapshot.data!.status == Status.LOADING && _searchController.text == _lastSearchQuery) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      // Show clear button when there's text
                      if (_searchController.text.isNotEmpty) {
                        return IconButton(
                          icon: Icon(Icons.clear, color: theme.iconTheme.color),
                          onPressed: _clearSearch,
                        );
                      }
                      // Return empty container when no icon needed
                      return const SizedBox.shrink();
                    },
                  ),
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
              //cash drawer
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    // onTap: widget.onThemeChanged,
                    onTap: () async {
                      final profile = await CapabilityProfile.load(name: 'XP-N160I');
                      var bytes = Generator(PaperSize.mm80, profile).drawer(); /// open drawer
                      if (kDebugMode) {
                        print("TopBar onTap of cash drawer open tapped with profile: ${profile.name} and bytes return $bytes");
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(TextConstants.cashDrawerIsOpening),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      SvgUtils.cashDrawerIcon,
                      width: 26,
                      height: 26,
                      colorFilter: ColorFilter.mode(
                        themeHelper.themeMode == ThemeMode.dark
                            ? ThemeNotifier.lightBackground
                            : Colors.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),

                  const Text(
                    TextConstants.lightText,
                    style: TextStyle(fontSize: 8),
                  ),
                ],
              ),
              SizedBox(width: 20),
              // mode button
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: widget.onModeChanged,
                    child: SvgPicture.asset(
                      SvgUtils.changeModeIcon,
                      width: 26,
                      height: 26,
                      colorFilter: ColorFilter.mode(
                        themeHelper.themeMode == ThemeMode.dark
                            ? ThemeNotifier.lightBackground
                            : Colors.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const Text(
                    TextConstants.modeText,
                    style: TextStyle(fontSize: 8),
                  ),
                ],
              ),
              SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // GestureDetector(
                  //   // FIX: Makes the entire area of the widget tappable, not just the visible parts.
                  //   behavior: HitTestBehavior.opaque,
                  //   onTap: () async {
                  //     if (kDebugMode) {
                  //       print("Theme icon tapped!");
                  //     }
                  //     final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
                  //     final newTheme = themeNotifier.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                  //     themeNotifier.setThemeMode(newTheme);
                  //     // Save the new theme setting to the database
                  //     await UserDbHelper().saveUserSettings({
                  //       AppDBConst.themeMode: newTheme.toString(),
                  //     });
                  //   },
                  GestureDetector(
                    // onTap: widget.onThemeChanged,
                    onTap: (){
                      if (kDebugMode) {
                        print("TopBar onTap of thememode change ${themeHelper.getThemeMode()}");
                      }

                      themeHelper.setThemeMode( //Build #1.0.54: updated
                          themeHelper.getThemeMode() == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark
                      );
                    },
                    child: SvgPicture.asset(
                      SvgUtils.themeIcon,
                      width: 26,
                      height: 26,
                      colorFilter: ColorFilter.mode(
                        themeHelper.themeMode == ThemeMode.dark
                            ? ThemeNotifier.lightBackground
                            : Colors.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),

                  Text(
                    themeHelper.themeMode == ThemeMode.dark
                        ? TextConstants.darkText
                        : TextConstants.lightText,
                    style: const TextStyle(fontSize: 8),
                  ),
                ],
              ),
              SizedBox(width: 20),
              // User profile section with container and notification bell
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
                  boxShadow: [
                    BoxShadow(
                      color: themeHelper.themeMode == ThemeMode.dark
                          ? ThemeNotifier.shadow_F7 : Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 2,
                      spreadRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        (userDisplayName ?? "Unknown").substring(0,1), // "A", /// use initial for the login user
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                    SizedBox(width: 15),
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
                  boxShadow: [
                    BoxShadow(
                      color: themeHelper.themeMode == ThemeMode.dark
                          ? ThemeNotifier.shadow_F7 : Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 2,
                      spreadRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ],
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


        ],
      ),
    );
  }
}