import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_pos/Blocs/Search/product_search_bloc.dart';
import 'package:pinaka_pos/Database/order_panel_db_helper.dart';
import 'package:pinaka_pos/Models/Search/product_by_sku_model.dart';
import 'package:pinaka_pos/Models/Search/product_search_model.dart';
import 'package:pinaka_pos/Repositories/Search/product_search_repository.dart';

import '../../Helper/api_response.dart';
import '../../Models/Search/product_variation_model.dart';
import '../../Widgets/widget_variants_dialog.dart';

class VariationPopup {

final ProductBloc _productBloc = ProductBloc(ProductRepository());
int productId;
String productName;
OrderHelper orderHelper;

final Future<void> Function()? onProductSelected;


VariationPopup( this.productId, this.productName, this.orderHelper, {this.onProductSelected}){
  _productBloc.fetchProductVariations(productId ?? 0);
}

  Future showVariantDialog({required BuildContext context}){
    return showDialog(
      context: context,
      builder: (context) => StreamBuilder<APIResponse<List<ProductVariation>>>(
        stream: _productBloc.variationStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.status == Status.LOADING) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.status == Status.COMPLETED) {
            final variations = snapshot.data!.data!;
            if (variations.isNotEmpty) {
              return VariantsDialog(
                title: productName ?? '',
                variations: variations.map((v) => {
                  "id": v.id,
                  "name": v.name,
                  "price": v.regularPrice,
                  "image": v.image.src,
                }).toList(),
                onAddVariant: (variant, quantity) async {
                  await orderHelper.addItemToOrder(
                    variant["name"],
                    variant["image"],
                    double.tryParse(variant["price"].toString()) ?? 0.0,
                    quantity,
                    'SKU${variant["name"]}',
                    onItemAdded: () {
                      ///Callback function to refresh order Panel
                      onProductSelected!();
                    },
                  );
                },
              );
            } else {
              ///Callback function to refresh order Panel
              onProductSelected!();
              return const SizedBox.shrink();
            }
          }
          onProductSelected!();
          return const SizedBox.shrink();
        },
      ),
    );
  }
}