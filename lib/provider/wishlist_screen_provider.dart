import 'dart:developer';
import 'package:apni_factory/api_services/creator_api_services.dart';
import 'package:apni_factory/model/add_to_wishlist_model.dart';
import 'package:apni_factory/model/delete_wishlist_model.dart';
import 'package:apni_factory/model/user_wishlist_model.dart';
import 'package:apni_factory/utils.dart';
import 'package:flutter/material.dart';

class WishlistProvider extends ChangeNotifier {
  bool loadingUserWishlist = false;
  bool loadingDeleteWishlist = false;
  UserWishlistModel? userWishlistModel;
  final Set<int> wishlistedProductIds = {};

  bool isWishlisted(int? productId) {
    if (productId == null) return false;
    return wishlistedProductIds.contains(productId);
  }

  Future<void> userWishList({
    required BuildContext context,
    bool isSilent = false,
  }) async {
    try {
      if (!isSilent) {
        loadingUserWishlist = true;
        notifyListeners();
      }

      userWishlistModel = await CreatorApiServices.userWishlistDetails(context);

      wishlistedProductIds.clear();
      if (userWishlistModel?.data != null) {
        for (final item in userWishlistModel!.data!) {
          if (item.productid != null) {
            wishlistedProductIds.add(item.productid!);
          }
        }
      }

      loadingUserWishlist = false;
      notifyListeners();
    } catch (e) {
      log("user wishlist error: ${e.toString()}");
      loadingUserWishlist = false;
      notifyListeners();
    }
  }

  // Instant 1-tap Toggle Wishlist (Used directly on product cards across app)
  Future<bool> toggleWishlist({
    required BuildContext context,
    required int productId,
    String color = "0",
  }) async {
    final bool currentlyWishlisted = wishlistedProductIds.contains(productId);

    if (currentlyWishlisted) {
      // Optimistic remove
      wishlistedProductIds.remove(productId);
      notifyListeners();

      // Find item wishlist id if in current model
      String? wId;
      if (userWishlistModel?.data != null) {
        for (final element in userWishlistModel!.data!) {
          if (element.productid == productId && element.id != null) {
            wId = element.id.toString();
            break;
          }
        }
      }

      if (wId != null) {
        await CreatorApiServices.deleteWishlistDetails(context, wishlistid: wId);
      } else {
        await CreatorApiServices.deleteWishlistDetails(context, wishlistid: productId.toString());
      }
      await userWishList(context: context, isSilent: true);
      return false;
    } else {
      // Optimistic add
      wishlistedProductIds.add(productId);
      notifyListeners();

      final AddToWishlistModel? res = await CreatorApiServices.addToWishlistDetails(
        context,
        productid: productId.toString(),
        color: color,
      );

      await userWishList(context: context, isSilent: true);
      return res?.code == 100;
    }
  }

  // Quick Remove directly from Wishlist Screen
  Future<bool> quickRemoveWishlist({
    required BuildContext context,
    required String wishlistId,
    required int productId,
  }) async {
    try {
      wishlistedProductIds.remove(productId);
      if (userWishlistModel?.data != null) {
        userWishlistModel!.data!.removeWhere((item) => item.id.toString() == wishlistId || item.productid == productId);
      }
      notifyListeners();

      final DeleteWishlistModel? res = await CreatorApiServices.deleteWishlistDetails(
        context,
        wishlistid: wishlistId,
      );

      return res?.code == 100;
    } catch (e) {
      log("quick remove wishlist error: $e");
      return false;
    }
  }

  Future<void> deleteWishList({
    required BuildContext context,
    required BuildContext dialogContext,
    required double height,
    required String wishlistid,
  }) async {
    try {
      loadingDeleteWishlist = true;
      notifyListeners();

      DeleteWishlistModel? deleteWishlistModel =
          await CreatorApiServices.deleteWishlistDetails(context, wishlistid: wishlistid);

      if (deleteWishlistModel != null && deleteWishlistModel.code == 100) {
        if (context.mounted) {
          Utils.commonSnackBar(context, height: height, message: deleteWishlistModel.msg.toString());
        }

        await userWishList(context: context, isSilent: true);

        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }
      }
    } catch (e) {
      log("delete wishlist error: ${e.toString()}");
    } finally {
      loadingDeleteWishlist = false;
      notifyListeners();
    }
  }
}
