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
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../Blocs/Search/product_search_bloc.dart';
import '../Constants/text.dart';
import '../Helper/api_response.dart';
import '../Models/Search/product_search_model.dart';
import '../Repositories/Search/product_search_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    _productBloc.dispose();
    _removeOverlay();
    super.dispose();
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
      builder: (context) => Positioned(
        width: searchFieldSize.width,
        left: searchFieldOffset.dx,
        top: searchFieldOffset.dy + searchFieldSize.height,
        child: Material(
          elevation: 4,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
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
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ));
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
                            onTap: () {
                              widget.onProductSelected?.call(product);
                              _clearSearch();
                            },
                          );
                        },
                      );
                    case Status.ERROR:
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(snapshot.data!.message ?? 'Error loading products'),
                      );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/svg/app_icon.svg',
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
                ),
              ),
            ),
          ),
          const SizedBox(width: 140),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.calculate),
              ),
              const Text(
                TextConstants.calculatorText,
                style: TextStyle(fontSize: 8),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.pause),
              ),
              const Text(
                TextConstants.holdText,
                style: TextStyle(fontSize: 8),
              ),
            ],
          ),
          const SizedBox(width: 8),
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
        ],
      ),
    );
  }
}