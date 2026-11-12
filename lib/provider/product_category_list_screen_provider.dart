import 'dart:developer';

import 'package:apni_factory/api_services/creator_api_services.dart';
import 'package:apni_factory/model/product_category_list_model.dart';
import 'package:apni_factory/model/product_list_by_category_model.dart';
import 'package:flutter/material.dart';

class ProductCategoryListScreenProvider extends ChangeNotifier {
  static const int pageSize = 20;

  bool loadingProductCategoryListScreen = true;
  String? errorMessage;
  List? slider;
  ProductCategoryListScreenModel? productCategoryListScreenModel;
  String? selectedCategory;
  int? selectedBid;
  int? selectedSid;
  int? selectedScid;
  int? selectedCmpid;

  List? productDetails;
  List? subCategoryDetails;
  int _visibleProductCount = pageSize;

  /// Incrementally slices the loaded product list to avoid rendering hundreds
  /// of complex grid tiles at once while preserving instant filtering.
  List get paginatedProducts {
    final all = productDetails ?? [];
    if (all.length <= _visibleProductCount) return all;
    return all.sublist(0, _visibleProductCount);
  }

  bool get hasMoreProducts {
    final all = productDetails ?? [];
    return _visibleProductCount < all.length;
  }

  void loadMoreProducts() {
    final all = productDetails ?? [];
    if (_visibleProductCount >= all.length) return;
    _visibleProductCount =
        (_visibleProductCount + pageSize).clamp(0, all.length);
    notifyListeners();
  }

  Future<void> productCategoryListScreen({
    required BuildContext context,
    required int bid,
    required int cid,
    int scid = 0,
    int cmpid = 0,
  }) async {
    try {
      productCategoryListScreenModel = null;
      errorMessage = null;
      loadingProductCategoryListScreen = true;
      selectedCmpid = cmpid;
      _visibleProductCount = pageSize;
      notifyListeners();

      productCategoryListScreenModel =
          await CreatorApiServices.productCategoryListScreenDetails(context,
              bid: bid, cid: cid, scid: scid, cmpid: cmpid);

      if (productCategoryListScreenModel != null &&
          productCategoryListScreenModel!.code == 100) {
        loadingProductCategoryListScreen = false;
        errorMessage = null;
        final subcats = productCategoryListScreenModel?.data?.subcategory;
        final prods = productCategoryListScreenModel?.data?.product;

        if (subcats != null && subcats.isNotEmpty) {
          int matchedIdx = subcats.indexWhere((s) =>
              s.highlight == true ||
              (scid > 0
                  ? (s.scid ?? 0) == scid
                  : (s.cid == cid && (s.scid ?? 0) == 0)));
          if (matchedIdx < 0) matchedIdx = 0;
          selectedCategoryIndex = matchedIdx;
          selectedCategory = subcats[matchedIdx].name;
          selectedBid = subcats[matchedIdx].bid ?? 0;
          selectedSid = subcats[matchedIdx].cid ?? 0;
          selectedScid = subcats[matchedIdx].scid ?? 0;
          selectedCmpid = subcats[matchedIdx].cmpid ??
              productCategoryListScreenModel?.data?.companyId ??
              cmpid;
        } else if (prods != null && prods.isNotEmpty) {
          selectedCategoryIndex = 0;
          selectedCategory = prods[0].categoryname;
          selectedBid = bid;
          selectedSid = cid;
          selectedScid = scid;
          selectedCmpid = productCategoryListScreenModel?.data?.companyId ?? cmpid;
        } else {
          selectedCategoryIndex = 0;
          selectedCategory = "Products";
          selectedBid = bid;
          selectedSid = cid;
          selectedScid = scid;
          selectedCmpid = productCategoryListScreenModel?.data?.companyId ?? cmpid;
        }

        subCategoryDetails = subcats;
        productDetails = prods ?? [];
        notifyListeners();
      } else {
        loadingProductCategoryListScreen = false;
        errorMessage = productCategoryListScreenModel?.msg?.toString() ??
            'Unable to load products right now. Please retry.';
        notifyListeners();
      }
    } catch (e) {
      log("product category list error: ${e.toString()}");
      loadingProductCategoryListScreen = false;
      errorMessage = 'Unable to load products right now. Please retry.';
      notifyListeners();
    }
  }

  ProductListByCategoryScreenModel? productListBySubCategoryScreenModel;
  bool loadingProductListBySubcategory = false;
  Future<void> productListBySubCategoryScreen({
    required BuildContext context,
    required int bid,
    required int sid,
    int scid = 0,
    int cmpid = 0,
  }) async {
    try {
      loadingProductListBySubcategory = true;
      errorMessage = null;
      _visibleProductCount = pageSize;
      notifyListeners();

      productListBySubCategoryScreenModel =
          await CreatorApiServices.productListByCategoryScreenDetails(context,
              sid: sid, bid: bid, scid: scid, cmpid: cmpid);
      if (productListBySubCategoryScreenModel != null &&
          productListBySubCategoryScreenModel!.code == 100) {
        loadingProductListBySubcategory = false;
        productDetails = productListBySubCategoryScreenModel?.data?.product ?? [];
        // Preserve existing subCategoryDetails if new response has null or empty subcategories
        if (productListBySubCategoryScreenModel?.data?.subcategory != null &&
            productListBySubCategoryScreenModel!.data!.subcategory!.isNotEmpty) {
          final updatedList = productListBySubCategoryScreenModel!.data!.subcategory!;
          subCategoryDetails = updatedList;
          final newIdx = updatedList.indexWhere((s) =>
              s.highlight == true ||
              (scid > 0 ? (s.scid ?? 0) == scid : (s.cid == sid && (s.scid ?? 0) == 0)));
          if (newIdx >= 0) {
            selectedCategoryIndex = newIdx;
          }
        }
        notifyListeners();
      } else {
        loadingProductListBySubcategory = false;
        productDetails = [];
        notifyListeners();
      }
    } catch (e) {
      log("product list by sub category error: ${e.toString()}");
      loadingProductListBySubcategory = false;
      productDetails = [];
      notifyListeners();
    }
  }

  // final List<String> categories = ['Electronics', 'Clothing', 'Groceries'];

  int selectedCategoryIndex = 0;

  // Initially selected category
  void selectedSubCategory({
    required int index,
    required BuildContext context,
  }) {
    selectedCategoryIndex = index;

    final subcat = (subCategoryDetails != null && index < subCategoryDetails!.length)
        ? subCategoryDetails![index]
        : (productCategoryListScreenModel?.data?.subcategory != null &&
                index < productCategoryListScreenModel!.data!.subcategory!.length)
            ? productCategoryListScreenModel!.data!.subcategory![index]
            : null;

    selectedCategory = subcat?.name ?? "Products";
    selectedBid = subcat?.bid ?? 0;
    selectedSid = subcat?.cid ?? 0;
    selectedScid = subcat?.scid ?? 0;
    final int cmpid = subcat?.cmpid ??
        selectedCmpid ??
        productCategoryListScreenModel?.data?.companyId ??
        0;
    selectedCmpid = cmpid;

    productListBySubCategoryScreen(
      context: context,
      bid: selectedBid ?? 0,
      sid: selectedSid ?? 0,
      scid: selectedScid ?? 0,
      cmpid: cmpid,
    );

    notifyListeners();
  }

  void resetState() {
    selectedCategoryIndex = 0;
    selectedCategory = null;
    selectedScid = 0;
    selectedCmpid = 0;
    errorMessage = null;
    _visibleProductCount = pageSize;
    productDetails = null;
    subCategoryDetails = null;
    productCategoryListScreenModel = null;
    loadingProductCategoryListScreen = true;
    loadingProductListBySubcategory = false;
    notifyListeners();
  }
}
