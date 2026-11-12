import 'dart:convert';
import 'dart:developer';
import 'package:apni_factory/model/add_address_model.dart';
import 'package:apni_factory/model/check_availability_model.dart';
import 'package:apni_factory/model/city_list_model.dart';
import 'package:apni_factory/model/delete_address_model.dart';
import 'package:apni_factory/model/delete_cart_attribute_model.dart';
import 'package:apni_factory/model/delete_cart_model.dart';
import 'package:apni_factory/model/empty_cart_model.dart';
import 'package:apni_factory/model/get_address_detail_model.dart';
import 'package:apni_factory/model/get_address_list_model.dart';
import 'package:apni_factory/model/increase_cart_quantity_model.dart';
import 'package:apni_factory/model/order_model.dart';
import 'package:apni_factory/model/pincode_list_model.dart';
import 'package:apni_factory/model/related_product_model.dart';
import 'package:apni_factory/model/state_model.dart';
import 'package:apni_factory/model/update_address_model.dart';
import 'package:apni_factory/model/update_cart_address_model.dart';
import 'package:apni_factory/model/user_cart_model.dart';
import 'package:apni_factory/res/widgets/edit_address_widget.dart';
import 'package:apni_factory/screens/payment_successful_screen.dart';
import 'package:flutter/material.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:apni_factory/utils.dart';
import '../api_services/creator_api_services.dart';
import '../utils.dart';

class CartScreenProvider extends ChangeNotifier {
  bool loadingAddAddress = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController landmarkController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController phonenoController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController identitynameController = TextEditingController();
  TextEditingController editNameController = TextEditingController();
  TextEditingController editLandmarkController = TextEditingController();
  TextEditingController editAddressController = TextEditingController();
  TextEditingController editCountryController = TextEditingController();
  TextEditingController editStateController = TextEditingController();
  TextEditingController editCityController = TextEditingController();
  TextEditingController editPincodeController = TextEditingController();
  TextEditingController editPhonenoController = TextEditingController();
  TextEditingController editLocationController = TextEditingController();
  TextEditingController editIdentitynameController = TextEditingController();
  String? selectedAddressText;
  Future<void> addAddress({
    required BuildContext context,
    required double height,
    String? name,
    String? address,
    String? landmark,
    String? country,
    String? state,
    String? city,
    String? pincode,
    String? phoneno,
    String? identityname,
  }) async {
    try {
      if (name != null &&
          name.isNotEmpty &&
          address != null &&
          address.isNotEmpty &&
          landmark != null &&
          landmark.isNotEmpty &&
          country != null &&
          country.isNotEmpty &&
          state != null &&
          state.isNotEmpty &&
          city != null &&
          city.isNotEmpty &&
          pincode != null &&
          pincode.isNotEmpty &&
          phoneno != null &&
          phoneno.isNotEmpty &&
          identityname != null &&
          identityname.isNotEmpty) {
        loadingAddAddress = true;
        notifyListeners();

        AddAddressModel? addAddressModel =
            await CreatorApiServices.addAddressDetails(context,
                name: name,
                landmark1: address,
                landmark2: landmark,
                country: country,
                state: state,
                city: city,
                pincode: pincode,
                phoneno: phoneno,
                identityname: identityname,
                type: "transport");

        if (addAddressModel != null && addAddressModel.code == 100) {
          await updateCartAddress(
              context: context,
              height: height,
              addressId: addAddressModel.data?.id.toString() ?? "");
          await checkAddressAvailability(
              context: context,
              addressid: addAddressModel.data?.id.toString() ?? "",
              height: height);

          await getAddressList(context: context);
          selectedAddressId = addAddressModel.data?.id?.toString();
          selectedAddressText = "${addAddressModel.data?.landmark1 ?? ""}, "
              "${addAddressModel.data?.landmark2 ?? ""}, "
              "${addAddressModel.data?.city ?? ""}, "
              "${addAddressModel.data?.state ?? ""}, "
              "${addAddressModel.data?.pincode ?? ""}";

          nameController.clear();
          addressController.clear();
          landmarkController.clear();
          countryController.clear();
          stateDropDownValue = "State*";
          cityDropDownValue = "City*";
          pincodeDropDownValue = "Pincode*";

          phonenoController.clear();

          identitynameController.clear();
          loadingAddAddress = false;
          notifyListeners();

          Navigator.pop(context);
          Navigator.pop(context);

          Utils.commonSnackBar(context,
              height: height, message: addAddressModel.msg.toString());
        } else {
          loadingAddAddress = false;
          notifyListeners();
        }
      } else {
        Navigator.pop(context);
        Navigator.pop(context);
        Utils.commonSnackBar(context,
            height: height, message: "Enter all details");
      }
    } catch (e) {
      log("add address error: ${e.toString()}");
      loadingAddAddress = false;
      notifyListeners();
    }
  }

  bool loadingGetAddressList = true;
  GetAddressListModel? getAddressListModel;
  List? addressList = [];
  Future<void> getAddressList({
    required BuildContext context,
  }) async {
    try {
      loadingGetAddressList = true;
      notifyListeners();

      getAddressListModel =
          await CreatorApiServices.getAddressListDetails(context);

      if (getAddressListModel != null && getAddressListModel!.code == 100) {
        loadingGetAddressList = false;
        notifyListeners();
      } else {
        loadingGetAddressList = false;
        notifyListeners();
      }
    } catch (e) {
      log("get address list error: ${e.toString()}");
      loadingGetAddressList = false;
      notifyListeners();
    }
  }

  String? selectedAddressId;

  void selectAddress(
    value, {
    required BuildContext context,
    required double height,
    required String addressId,
    required String addressText,
  }) async {
    selectedAddressId = addressId;
    selectedAddressText = addressText;
    // selectedId = addressId.split(" ").last;
    notifyListeners(); // UI ONLY
    await updateCartAddress(
      context: context,
      height: height,
      addressId: addressId,
    );
    Navigator.pop(context);
  }

  bool loadingGetAddressDetail = false;
  GetAddressDetailModel? getAddressDetailModel;
  Future<void> getIdAddress(
      {required BuildContext context, required String addressId}) async {
    try {
      loadingGetAddressDetail = true;
      getAddressDetailModel = await CreatorApiServices.getIdAddressDetails(
          context,
          addressId: addressId);
      notifyListeners();
      if (getAddressDetailModel != null && getAddressDetailModel!.code == 100) {
        loadingGetAddressDetail = false;
        editNameController.text = getAddressDetailModel?.data?.name ?? "";
        editLandmarkController.text =
            getAddressDetailModel?.data?.landmark2 ?? "";
        editAddressController.text =
            getAddressDetailModel?.data?.landmark1 ?? "";
        editCountryController.text = getAddressDetailModel?.data?.country ?? "";
        editStateController.text = getAddressDetailModel?.data?.state ?? "";
        editCityController.text = getAddressDetailModel?.data?.city ?? "";
        editPincodeController.text = getAddressDetailModel?.data?.pincode ?? "";
        editPhonenoController.text = getAddressDetailModel?.data?.phoneno ?? "";
        editLocationController.text =
            getAddressDetailModel?.data?.location ?? "";
        editIdentitynameController.text =
            getAddressDetailModel?.data?.identityname ?? "";
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return EditAddressWidget(
              addressId: addressId,
            );
          },
        );

        notifyListeners();
      } else {
        loadingGetAddressDetail = false;
        notifyListeners();
      }
    } catch (e) {
      loadingGetAddressDetail = false;
      log("get id address error: ${e.toString()}");
    }
    notifyListeners();
  }

  bool loadingUpdateAddress = false;
  Future<void> updateAddress(
      {required BuildContext context,
      required double height,
      String? name,
      String? landmark,
      String? address,
      String? country,
      String? state,
      String? city,
      String? pincode,
      String? phoneno,
      String? identityname,
      required String addressId}) async {
    try {
      if (name != null &&
          name.isNotEmpty &&
          landmark != null &&
          landmark.isNotEmpty &&
          address != null &&
          address.isNotEmpty &&
          country != null &&
          country.isNotEmpty &&
          state != null &&
          state.isNotEmpty &&
          city != null &&
          city.isNotEmpty &&
          pincode != null &&
          pincode.isNotEmpty &&
          phoneno != null &&
          phoneno.isNotEmpty &&
          identityname != null &&
          identityname.isNotEmpty) {
        loadingUpdateAddress = true;
        UpdateAddressModel? updateAddressModel =
            await CreatorApiServices.updateAddressDetails(context,
                name: name,
                landmark: landmark,
                address: address,
                country: country,
                state: state,
                city: city,
                pincode: pincode,
                phoneno: phoneno,
                identityname: identityname,
                addressId: addressId,
                type: "transport");
        notifyListeners();
        if (updateAddressModel != null && updateAddressModel.code == 100) {
          await updateCartAddress(
              context: context, height: height, addressId: addressId);
          await getAddressList(context: context);
          if (selectedAddressId == addressId) {
            selectedAddressText = "${editAddressController.text}, "
                "${editLandmarkController.text}, "
                "${editCityController.text}, "
                "${editStateController.text} "
                "${editPincodeController.text} $addressId";
            // selectedAddress = newAddress;
            // selectedId = addressId;
          }

          Navigator.pop(context);
          Navigator.pop(context);
          loadingUpdateAddress = false;
          Utils.commonSnackBar(context,
              height: height, message: updateAddressModel.msg.toString());

          editNameController.clear();
          editLandmarkController.clear();
          editAddressController.clear();
          editCountryController.clear();
          editStateController.clear();
          editCityController.clear();
          editPincodeController.clear();
          editPhonenoController.clear();

          editIdentitynameController.clear();

          notifyListeners();
        } else {
          loadingUpdateAddress = false;
          notifyListeners();
        }
      } else {
        Navigator.pop(context);
        Utils.commonSnackBar(context,
            height: height, message: "Enter all details");
      }
    } catch (e) {
      loadingUpdateAddress = false;
      log("update address error: ${e.toString()}");
    }
    notifyListeners();
  }

  bool loadingDeleteAddress = false;
  Future<void> deleteAddress(
      {required BuildContext context,
      required BuildContext dialogContext,
      required double height,
      required String addressid}) async {
    try {
      loadingDeleteAddress = true;
      notifyListeners();

      DeleteAddressModel? deleteAddressModel =
          await CreatorApiServices.deleteAddressDetails(context,
              addressid: addressid);
      notifyListeners();

      if (deleteAddressModel != null && deleteAddressModel.code == 100) {
        if (selectedAddressId == addressid) {
          selectedAddressId = null;
          selectedAddressText = null;
        }
        Navigator.pop(dialogContext);

        Navigator.pop(context);
        Navigator.pop(context);

        await getAddressList(context: context);
        loadingDeleteAddress = false;
        Utils.commonSnackBar(context,
            height: height, message: deleteAddressModel.msg.toString());
        notifyListeners();
      } else {
        loadingDeleteAddress = false;
        notifyListeners();
      }
    } catch (e) {
      loadingDeleteAddress = false;
      log("delete address error: ${e.toString()}");
    }
    notifyListeners();
  }

  bool loadingUpdateCartAddress = false;
  Future<void> updateCartAddress(
      {required BuildContext context,
      required double height,
      required String addressId}) async {
    try {
      if (addressId != null && addressId.isNotEmpty) {
        loadingUpdateCartAddress = true;
        UpdateCartAddressModel? updateCartAddressModel =
            await CreatorApiServices.updateCartAddressDetail(context,
                addressid: addressId);
        notifyListeners();
        if (updateCartAddressModel != null &&
            updateCartAddressModel.code == 100) {
          await userCart(context: context);

          loadingUpdateCartAddress = false;

          if (context.mounted) {
            Utils.commonSnackBar(context,
                height: height, message: updateCartAddressModel.msg.toString());
          }

          notifyListeners();
        } else {
          loadingUpdateCartAddress = false;
          notifyListeners();
        }
      } else {
        if (context.mounted) {
          Utils.commonSnackBar(context,
              height: height, message: "Select Address");
        }
      }
    } catch (e) {
      loadingUpdateCartAddress = false;
      log("update cart address error: ${e.toString()}");
    }
    notifyListeners();
  }

  bool loadingStateDropDown = true;
  StateModel? stateModel;
  List<String> stateList = [];
  String stateDropDownValue = "State*";
  Future<void> stateDropDown({required BuildContext context}) async {
    try {
      stateList = [];
      loadingStateDropDown = true;
      notifyListeners();
      stateModel = await CreatorApiServices.stateModelDetails(context);

      if (stateModel != null && stateModel!.code == 100) {
        List? dataList = stateModel!.data;
        if (dataList != null) {
          for (var item in dataList) {
            stateList.add(item ?? "");

            loadingStateDropDown = false;
            notifyListeners();
          }
        }
        stateList.insert(0, "State*");
        notifyListeners();
      }
    } catch (e) {
      log("state drop down error: ${e.toString()}");
    }
    notifyListeners();
  }

  bool loadingCityDropDown = false;
  CityListModel? cityListModel;
  List<String> cityList = ["City*"];
  String cityDropDownValue = "City*";

  Future<void> cityDropDown(
      {required BuildContext context, required String state}) async {
    try {
      cityList = [];

      cityDropDownValue = "City*";
      loadingCityDropDown = true;
      notifyListeners();
      cityListModel =
          await CreatorApiServices.cityModelDetails(context, state: state);

      if (cityListModel != null && cityListModel!.code == 100) {
        List? dataList = cityListModel!.data;
        if (dataList != null) {
          // cityList.removeRange(0, cityList.length-1);
          for (var item in dataList) {
            cityList.add(item ?? "");

            loadingCityDropDown = false;
            notifyListeners();
          }
        }
        cityList.insert(0, "City*");

        notifyListeners();
      }
    } catch (e) {
      log("city drop down error: ${e.toString()}");
    }
    notifyListeners();
  }

  bool loadingPincodeDropDown = false;
  PincodeListModel? pincodeListModel;
  List<String> pincodeList = ["Pincode*"];
  String pincodeDropDownValue = "Pincode*";

  Future<void> pincodeDropDown(
      {required BuildContext context, required String city}) async {
    try {
      pincodeList = [];

      pincodeDropDownValue = "Pincode*";
      loadingPincodeDropDown = true;
      notifyListeners();
      pincodeListModel =
          await CreatorApiServices.pincodeModelDetails(context, city: city);

      if (pincodeListModel != null && pincodeListModel!.code == 100) {
        List? dataList = pincodeListModel!.data;
        if (dataList != null) {
          // cityList.removeRange(0, cityList.length-1);
          for (var item in dataList) {
            pincodeList.add(item ?? "");

            loadingPincodeDropDown = false;
            notifyListeners();
          }
        }
        pincodeList.insert(0, "Pincode*");

        notifyListeners();
      }
    } catch (e) {
      log("pincode drop down error: ${e.toString()}");
    }
    notifyListeners();
  }

  bool loadingCheckAvailability = false;
  CheckAddressAvailabilityModel? checkAddressAvailabilityModel;

  Future<void> checkAddressAvailability(
      {required BuildContext context,
      required String addressid,
      required double height}) async {
    try {
      loadingCheckAvailability = true;
      notifyListeners();
      checkAddressAvailabilityModel =
          await CreatorApiServices.checkAddressAvailabilityDetails(
              context: context, addressid: addressid);

      if (checkAddressAvailabilityModel != null &&
          checkAddressAvailabilityModel!.code == 100) {
        loadingCheckAvailability = false;
        // updateCartAddress(
        //     context: context, height: height, addressId: addressid);
        Utils.commonSnackBar(context,
            height: height,
            message: checkAddressAvailabilityModel!.msg.toString());
        notifyListeners();
      } else {
        loadingCheckAvailability = false;
        Utils.commonSnackBar(context,
            height: height,
            message: checkAddressAvailabilityModel!.msg.toString());
      }
    } catch (e) {
      log("check availability drop down error: ${e.toString()}");
    }
    notifyListeners();
  }

  bool loadingUserCart = true;
  UserCartModel? userCartModel;
  final Set<String> updatingAttributeIds = {};

  bool isAttributeUpdating(String id) => updatingAttributeIds.contains(id);

  void recalculateLocalTotals() {
    if (userCartModel == null) return;
    num newNet = 0;
    int totalCount = 0;
    for (var catLists in userCartModel!.data.values) {
      for (var group in catLists) {
        for (var prod in group) {
          for (var a in prod.attributeData) {
            final int q = a.qty ?? 1;
            totalCount += q;
            final num u = (a.unitprice != null && a.unitprice! > 0)
                ? a.unitprice!
                : (a.prprice ?? 0);
            a.totalPrice = u * q;
            newNet += a.totalPrice!;
          }
        }
      }
    }
    userCartModel!.netamount = newNet;
    userCartModel!.counter = totalCount;
    if (userCartModel!.igst != 0) {
      userCartModel!.igst = (newNet * 0.18);
      userCartModel!.grandTotal = newNet + userCartModel!.igst;
    } else {
      userCartModel!.cgst = (newNet * 0.09);
      userCartModel!.sgst = (newNet * 0.09);
      userCartModel!.grandTotal = newNet + userCartModel!.cgst + userCartModel!.sgst;
    }
  }

  void _applyLocalAttributeQty(String cartAttributeId, int newQty) {
    if (userCartModel == null) return;
    for (var catLists in userCartModel!.data.values) {
      for (var group in catLists) {
        for (var prod in group) {
          for (var attr in prod.attributeData) {
            if (attr.attributeid.toString() == cartAttributeId) {
              attr.qty = newQty;
              final num u = (attr.unitprice != null && attr.unitprice! > 0)
                  ? attr.unitprice!
                  : (attr.prprice ?? 0);
              attr.totalPrice = u * newQty;
              return;
            }
          }
        }
      }
    }
  }

  Future<bool> quickAddToCart({
    required BuildContext context,
    required String productId,
    required String brandId,
    String? attributeId,
    bool replaceCart = false,
  }) async {
    try {
      List attrs = [];
      if (attributeId != null && attributeId.isNotEmpty && attributeId != "0") {
        attrs = [
          {"id": attributeId, "qty": "1"}
        ];
      } else {
        final prodDetail = await CreatorApiServices.producDetailsDetails(
          context,
          productid: productId,
          colorid: "0",
        );
        if (prodDetail != null &&
            prodDetail.data?.attributes != null &&
            prodDetail.data!.attributes!.isNotEmpty) {
          final firstAttr = prodDetail.data!.attributes!.first;
          attrs = [
            {"id": firstAttr.attributeid.toString(), "qty": "1"}
          ];
        }
      }

      if (attrs.isEmpty) return false;

      final res = await CreatorApiServices.addToCartDetails(
        context,
        productid: productId,
        brandid: (brandId.isNotEmpty && brandId != "0") ? brandId : "1",
        attributes: attrs,
        replaceCart: replaceCart,
      );

      if (res != null && res.code == 100) {
        await userCart(context: context, isSilent: true);
        return true;
      }

      if (res != null && res.code == 409 && context.mounted) {
        final confirmed = await Utils.showReplaceCartDialog(
          context,
          existingCompanyName: res.existingCompanyName ?? '',
          newCompanyName: res.newCompanyName ?? '',
          message: res.msg,
        );
        if (confirmed && context.mounted) {
          return await quickAddToCart(
            context: context,
            productId: productId,
            brandId: brandId,
            attributeId: attributeId,
            replaceCart: true,
          );
        }
      }
    } catch (e) {
      log("quickAddToCart error: $e");
    }
    return false;
  }

  Future<void> userCart({
    required BuildContext context,
    bool isSilent = false,
  }) async {
    try {
      if (!isSilent) {
        loadingUserCart = true;
        notifyListeners();
      }

      final freshModel = await CreatorApiServices.userCartDetails(context);

      if (freshModel != null && freshModel.code == 100) {
        userCartModel = freshModel;
      }
    } catch (e) {
      log("user cart error: ${e.toString()}");
    } finally {
      loadingUserCart = false;
      notifyListeners();
    }
  }

  bool loadingDeleteCart = false;

  Future<void> deleteCart(
      {required BuildContext context,
      required BuildContext globalcontext,
      required double height,
      required String cartid}) async {
    try {
      loadingDeleteCart = true;
      notifyListeners();

      DeleteCartModel? deleteCartModel =
          await CreatorApiServices.deleteCartDetails(context, cartid: cartid);

      if (deleteCartModel != null && deleteCartModel.code == 100) {
        await userCart(context: context, isSilent: true);
        loadingDeleteCart = false;

        Utils.commonSnackBar(globalcontext,
            height: height, message: deleteCartModel.msg.toString());

        notifyListeners();
      } else {
        loadingDeleteCart = false;
        notifyListeners();
      }
    } catch (e) {
      log("delete cart error: ${e.toString()}");
      loadingDeleteCart = false;
      notifyListeners();
    }
  }

  bool loadingDeleteCartAttribute = false;

  Future<void> deleteCartAttribute(
      {required BuildContext context,
      required BuildContext globalcontext,
      required double height,
      required String cartattributeid}) async {
    try {
      updatingAttributeIds.add(cartattributeid);
      notifyListeners();

      DeleteCartAttributeModel? deleteCartAttributeModel =
          await CreatorApiServices.deleteCartAttributeDetails(context,
              cartattributeid: cartattributeid);

      if (deleteCartAttributeModel != null &&
          deleteCartAttributeModel.code == 100) {
        await userCart(context: context, isSilent: true);
        loadingDeleteCartAttribute = false;

        Utils.commonSnackBar(globalcontext,
            height: height, message: deleteCartAttributeModel.msg.toString());

        notifyListeners();
      } else {
        loadingDeleteCartAttribute = false;
        notifyListeners();
      }
    } catch (e) {
      log("delete cart attribute error: ${e.toString()}");
      loadingDeleteCartAttribute = false;
      notifyListeners();
    } finally {
      updatingAttributeIds.remove(cartattributeid);
      notifyListeners();
    }
  }

  bool loadingEmptyCart = false;

  Future<void> emptyCart({
    required BuildContext context,
    required BuildContext globalcontext,
    required double height,
  }) async {
    try {
      loadingEmptyCart = true;
      notifyListeners();

      EmptyCartModel? emptyCartModel =
          await CreatorApiServices.emptyCartDetails(
        context,
      );
      notifyListeners();

      if (emptyCartModel != null && emptyCartModel.code == 100) {
        userCart(context: context);
        notifyListeners();
        loadingEmptyCart = false;

        notifyListeners();
        Utils.commonSnackBar(globalcontext,
            height: height, message: emptyCartModel.msg.toString());

        notifyListeners();
      } else {
        loadingEmptyCart = false;
        notifyListeners();
      }
    } catch (e) {
      loadingEmptyCart = false;
      log("empty cart error: ${e.toString()}");
    }
    notifyListeners();
  }

  RelatedProductModel? relatedProductModel;
  bool loadingRelatedProduct = true;
  Future<void> relatedProduct({
    required BuildContext context,
  }) async {
    try {
      loadingRelatedProduct = true;
      notifyListeners();

      relatedProductModel =
          await CreatorApiServices.relatedProductDetails(context);
      notifyListeners();

      if (relatedProductModel != null && relatedProductModel!.code == 100) {
        loadingRelatedProduct = false;

        notifyListeners();
      } else {
        loadingRelatedProduct = false;
        notifyListeners();
      }
    } catch (e) {
      loadingRelatedProduct = false;
      log("related product error: ${e.toString()}");
    }
    notifyListeners();
  }

  // void increaseQty(int tqy) {
  //   qty = ++tqy;
  //   log(qty.toString());
  //   notifyListeners();
  // }

  bool loadingIncreaseCartQuantity = false;

  Future<void> increaseCartQuantity(
      {required BuildContext context,
      required double height,
      required String cartid,
      required String qty}) async {
    final int currentQty = int.tryParse(qty) ?? 1;
    final int targetQty = currentQty + 1;

    // 1. Optimistic Local Update (0ms latency, zero reload)
    updatingAttributeIds.add(cartid);
    _applyLocalAttributeQty(cartid, targetQty);
    recalculateLocalTotals();
    notifyListeners();

    try {
      IncreaseCartQtyModel? increaseCartQtyModel =
          await CreatorApiServices.increaseCartQuantityDetails(context,
              cartattributeid: cartid, qty: targetQty.toString());

      if (increaseCartQtyModel != null && increaseCartQtyModel.code == 100) {
        // Silently sync authoritative server figures
        await userCart(context: context, isSilent: true);
      } else {
        // Revert on failure
        _applyLocalAttributeQty(cartid, currentQty);
        recalculateLocalTotals();
        if (context.mounted) {
          Utils.commonSnackBar(context,
              height: height,
              message: increaseCartQtyModel?.msg ?? "Could not update quantity");
        }
      }
    } catch (e) {
      log("increase cart quantity error: ${e.toString()}");
      _applyLocalAttributeQty(cartid, currentQty);
      recalculateLocalTotals();
    } finally {
      updatingAttributeIds.remove(cartid);
      notifyListeners();
    }
  }

  Future<void> decreaseCartQuantity(
      {required BuildContext context,
      required double height,
      required String cartid,
      required String qty,
      BuildContext? globalcontext}) async {
    final int currentQty = int.tryParse(qty) ?? 1;
    if (currentQty <= 1) {
      // Remove item if quantity goes below 1
      await deleteCartAttribute(
        context: context,
        globalcontext: globalcontext ?? context,
        height: height,
        cartattributeid: cartid,
      );
      return;
    }

    final int targetQty = currentQty - 1;

    // 1. Optimistic Local Update (0ms latency, zero reload)
    updatingAttributeIds.add(cartid);
    _applyLocalAttributeQty(cartid, targetQty);
    recalculateLocalTotals();
    notifyListeners();

    try {
      IncreaseCartQtyModel? increaseCartQtyModel =
          await CreatorApiServices.increaseCartQuantityDetails(context,
              cartattributeid: cartid, qty: targetQty.toString());

      if (increaseCartQtyModel != null && increaseCartQtyModel.code == 100) {
        await userCart(context: context, isSilent: true);
      } else {
        _applyLocalAttributeQty(cartid, currentQty);
        recalculateLocalTotals();
        if (context.mounted) {
          Utils.commonSnackBar(context,
              height: height,
              message: increaseCartQtyModel?.msg ?? "Could not update quantity");
        }
      }
    } catch (e) {
      log("decrease cart quantity error: ${e.toString()}");
      _applyLocalAttributeQty(cartid, currentQty);
      recalculateLocalTotals();
    } finally {
      updatingAttributeIds.remove(cartid);
      notifyListeners();
    }
  }

  String selectedPayment = "PayU Money";
  List paymentList = [
    "PayU Money",
  ];
  void selectPayment(value, {required BuildContext context}) {
    selectedPayment = value;

    notifyListeners();
  }

  bool loadingorder = false;
  OrderModel? orderModel;
  late PayUCheckoutProFlutter checkoutPro;
  Future<void> order({
    required BuildContext context,
    required double height,
    required String addressId,
  }) async {
    try {
      if (addressId.isNotEmpty) {
        loadingorder = true;
        notifyListeners();
        orderModel = await CreatorApiServices.orderDetails(
          context,
          addressid: addressId,
        );
        if (orderModel != null && orderModel!.code == 100) {
          loadingorder = false;
          Utils.commonSnackBar(context,
              height: height, message: orderModel!.msg.toString());
          notifyListeners();
        } else {
          loadingorder = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      orderModel?.msg?.toString() ?? "Order creation failed")),
            );
          }
          notifyListeners();
        }
      } else {
        Utils.commonSnackBar(context,
            height: height, message: "Please select a delivery address");
      }
    } catch (e) {
      loadingorder = false;
      log("order error: ${e.toString()}");
    } finally {
      loadingorder = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    landmarkController.dispose();
    countryController.dispose();
    phonenoController.dispose();
    locationController.dispose();
    identitynameController.dispose();
    editNameController.dispose();
    editLandmarkController.dispose();
    editAddressController.dispose();
    editCountryController.dispose();
    editStateController.dispose();
    editCityController.dispose();
    editPincodeController.dispose();
    editPhonenoController.dispose();
    editLocationController.dispose();
    editIdentitynameController.dispose();
    super.dispose();
  }
}
