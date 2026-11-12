import 'dart:convert';
import 'dart:io';
import 'package:apni_factory/api_services/api_client.dart';
import 'package:apni_factory/api_services/handle_dio.dart';

import 'package:apni_factory/model/about_us_model.dart';
import 'package:apni_factory/model/add_address_model.dart';
import 'package:apni_factory/model/add_to_cart_model.dart';
import 'package:apni_factory/model/add_to_wishlist_model.dart';
import 'package:apni_factory/model/admin_app_pages_model.dart';
import 'package:apni_factory/model/apply_coupon_model.dart';
import 'package:apni_factory/model/brand_detail_model.dart';
import 'package:apni_factory/model/brand_screen_model.dart';
import 'package:apni_factory/model/category_screen_model.dart';
import 'package:apni_factory/model/change_password_model.dart';
import 'package:apni_factory/model/check_availability_model.dart';
import 'package:apni_factory/model/city_list_model.dart';
import 'package:apni_factory/model/company_screen_model.dart';
import 'package:apni_factory/model/delete_address_model.dart';
import 'package:apni_factory/model/delete_cart_attribute_model.dart';
import 'package:apni_factory/model/delete_cart_model.dart';
import 'package:apni_factory/model/delete_wishlist_model.dart';
import 'package:apni_factory/model/empty_cart_model.dart';
import 'package:apni_factory/model/gst_error_verification_model.dart';
import 'package:apni_factory/model/gst_verification_model.dart';
import 'package:apni_factory/model/help_model.dart';
import 'package:apni_factory/model/help_no_for_app_model.dart';
import 'package:apni_factory/model/notification_model.dart';
import 'package:apni_factory/model/order_histort_model.dart';
import 'package:apni_factory/model/order_model.dart';
import 'package:apni_factory/model/pincode_list_model.dart';
import 'package:apni_factory/model/privacy_policy_model.dart';
import 'package:apni_factory/model/product_review_model.dart';
import 'package:apni_factory/model/related_product_model.dart';
import 'package:apni_factory/model/return_policy_model.dart';
import 'package:apni_factory/model/search_model.dart';
import 'package:apni_factory/model/single_order_detail_model.dart';
import 'package:apni_factory/model/state_model.dart';
import 'package:apni_factory/model/terms_condition_model.dart';
import 'package:apni_factory/model/update_address_model.dart';
import 'package:apni_factory/model/get_address_list_model.dart';
import 'package:apni_factory/model/get_coupon_list_model.dart';
import 'package:apni_factory/model/get_faq_model.dart';
import 'package:apni_factory/model/get_feedback_model.dart';
import 'package:apni_factory/model/get_address_detail_model.dart';
import 'package:apni_factory/model/get_otp_model.dart';
import 'package:apni_factory/model/get_pages_model.dart';
import 'package:apni_factory/model/get_profile_model.dart';
import 'package:apni_factory/model/home_screen_model.dart';
import 'package:apni_factory/model/increase_cart_quantity_model.dart';
import 'package:apni_factory/model/post_feedback_model.dart';
import 'package:apni_factory/model/product_category_list_model.dart';
import 'package:apni_factory/model/product_detail_model.dart';
import 'package:apni_factory/model/product_list_by_category_model.dart';
import 'package:apni_factory/model/reset_password_model.dart';
import 'package:apni_factory/model/sign_up_model.dart';
import 'package:apni_factory/model/update_cart_address_model.dart';
import 'package:apni_factory/model/update_profile_model.dart';
import 'package:apni_factory/model/user_cart_model.dart';
import 'package:apni_factory/model/user_wishlist_model.dart';
import 'package:apni_factory/model/verify_otp_model.dart';
import 'package:apni_factory/shared_pref.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../model/login_model.dart';
import 'api_end_point.dart';

class CreatorApiServices {
  static void _log(Object? message) {
    ApiClient.safeLog('CreatorApiServices', message);
  }

  static dynamic _decodeBody(dynamic raw) {
    if (raw is String) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty) return <String, dynamic>{};
      return json.decode(trimmed);
    }
    return raw;
  }

  static Future<LoginModel?> loginDetails(BuildContext context,
      {required String email,
      String? password,
      String? deviceid,
      CancelToken? cancelToken}) async {
    final Dio dio = ApiClient.instance.dio;
    final FormData formData = FormData.fromMap(
        {"email": email, "password": password, "deviceid": deviceid});
    try {
      Response response = await dio.post(
        ApiEndPoint.loginApi,
        data: formData,
        cancelToken: cancelToken,
      );

      _log("login status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic payload = response.data is String
            ? json.decode(response.data)
            : response.data;
        if (payload is Map<String, dynamic>) {
          final String? token = payload['token']?.toString() ??
              payload['access_token']?.toString() ??
              (payload['data'] is Map
                  ? payload['data']['token']?.toString()
                  : null);
          if (token != null && token.isNotEmpty) {
            await SharedPref.setAuthToken(token);
          }
          return LoginModel.fromJson(payload);
        }
        return LoginModel.fromJson(_decodeBody(response.data));
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<SignUpModel?> signUpDetails(BuildContext context,
      {required String name,
      required String email,
      required mobileNo,
      required password,
      required String regby}) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData = FormData.fromMap({
      "email": email,
      "name": name,
      "regby": regby,
      "password": password,
      "mobile": mobileNo,
    });

    // Map<String, dynamic>  formData;
    //   if (regby == "app") {
    //    formData = {
    //       "email": email,
    //       "password": password,
    //       "name": name,
    //       "regby": regby,
    //       "mobile": mobileNo,
    //       "whatsappno": whatsappNumber,

    //     };
    //   } else {
    //     formData = {
    //       "email": email,
    //       "password": null,
    //       "name": name,
    //       "regby": regby,
    //       "mobile": mobileNo
    //     };
    //   }
    try {
      Response response = await dio.post(
        ApiEndPoint.signUpApi,
        data: formData,
      );

      _log("Sign Up response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        SignUpModel signUpModel = SignUpModel.fromJson(_decodeBody(response.data));

        return signUpModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }


  static Future<ChangePasswordModel?> changePasswordDetails(
      BuildContext context,
      {required String currentPassword,
      required String newPassword}) async {
    final Dio dio = ApiClient.instance.dio;
    FormData formData;
    formData = FormData.fromMap({
      "currentpassword": currentPassword,
      "newpassword": newPassword,
    });
    String userId = await SharedPref.getUserLoginId();
    try {
      Response response = await dio.post(ApiEndPoint.changePasswordApi + userId,
          data: formData);

      _log("change password response is ${response.data.toString()}");
      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        ChangePasswordModel changePasswordModel =
            ChangePasswordModel.fromJson(data);

        return changePasswordModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<GetOtpModel?> getOtpDetails(BuildContext context,
      {required String email, required String sendon}) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData =
        FormData.fromMap({"emailmobile": email, "sendon": sendon});
    try {
      Response response = await dio.post(ApiEndPoint.getOtpApi, data: formData);

      _log("Get Otp response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        GetOtpModel getOtpModel = GetOtpModel.fromJson(data);
        _log(getOtpModel.toString());
        return getOtpModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<VerifyOtpModel?> verifyOtpDetails(BuildContext context,
      {required String email, required String otp}) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData =
        FormData.fromMap({"emailmobile": email, "otp": int.parse(otp)});
    try {
      Response response =
          await dio.post(ApiEndPoint.verifyOtpApi, data: formData);

      _log("Verify Otp response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        VerifyOtpModel verifyOtpModel = VerifyOtpModel.fromJson(data);
        _log(verifyOtpModel.toString());
        return verifyOtpModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<ResetPasswordModel?> resetPasswordDetails(BuildContext context,
      {required String id,
      required String password,
      required String emailmobile}) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData = FormData.fromMap(
        {"id": id, "password": password, "emailmobile": emailmobile});
    try {
      Response response =
          await dio.post(ApiEndPoint.resetPasswordApi, data: formData);

      _log("Reset Password response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        ResetPasswordModel resetPasswordModel =
            ResetPasswordModel.fromJson(data);
        _log(resetPasswordModel.toString());
        return resetPasswordModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<HomescreenModel?> homeScreenDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String userId = await SharedPref.getUserLoginId();
    try {
      Response response = await dio.get(
        "${ApiEndPoint.homeScreenApi}?userid=${userId}",
      );

      _log("HomeScreen response is ${response.data.toString()}");

      var data = (response.data is String)
          ? json.decode(response.data)
          : response.data;

      if (response.statusCode == 200) {
        HomescreenModel homeScreenModel = HomescreenModel.fromJson(data);
        _log(homeScreenModel.toString());
        return homeScreenModel;
      } else {
        return null;
      }
    } catch (error) {
      _log("homeScreenDetails error: $error");
      return null;
    }
  }

  static Future<List<HomeProduct>?> getRandomProducts(
    BuildContext context, {
    int limit = 10,
    int page = 1,
    List<int>? excludeIds,
  }) async {
    final Dio dio = ApiClient.instance.dio;
    try {
      String url = "${ApiEndPoint.randomProductsApi}?limit=$limit&page=$page";
      if (excludeIds != null && excludeIds.isNotEmpty) {
        url += "&exclude=${excludeIds.join(',')}";
      }
      Response response = await dio.get(url);
      var data = (response.data is String)
          ? json.decode(response.data)
          : response.data;
      if (response.statusCode == 200 && data != null && data['data'] != null) {
        List<HomeProduct> products = [];
        data['data'].forEach((v) {
          products.add(HomeProduct.fromJson(v));
        });
        return products;
      }
      return null;
    } catch (error) {
      _log("getRandomProducts error: $error");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRandomProductsPaginated(
    BuildContext context, {
    int page = 1,
    int limit = 8,
    List<int>? excludeIds,
  }) async {
    final Dio dio = ApiClient.instance.dio;
    try {
      String url = "${ApiEndPoint.randomProductsApi}?page=$page&limit=$limit";
      if (excludeIds != null && excludeIds.isNotEmpty) {
        url += "&exclude=${excludeIds.join(',')}";
      }
      Response response = await dio.get(url);
      var data = (response.data is String)
          ? json.decode(response.data)
          : response.data;
      if (response.statusCode == 200 && data != null && data['data'] != null) {
        List<HomeProduct> products = [];
        data['data'].forEach((v) {
          products.add(HomeProduct.fromJson(v));
        });
        return {
          'products': products,
          'has_more': data['has_more'] ?? false,
          'total': data['total'] ?? products.length,
          'current_page': data['current_page'] ?? page,
        };
      }
      return null;
    } catch (error) {
      _log("getRandomProductsPaginated error: $error");
      return null;
    }
  }

  static Future<SearchModel?> searchDetails(
    BuildContext context, {
    required String word,
  }) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData = FormData.fromMap({
      "word": word,
    });

    try {
      Response response = await dio.post(ApiEndPoint.searchApi, data: formData);

      _log("Search response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        SearchModel searchModel = SearchModel.fromJson(data);

        _log(searchModel.toString());
        return searchModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<GetProfileModel?> getProfileDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String userLoginId = await SharedPref.getUserLoginId();

    try {
      Response response = await dio.get(
        ApiEndPoint.getProfileApi + "${int.parse(userLoginId)}",
      );

      _log("Get Profile response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        GetProfileModel getProfileModel = GetProfileModel.fromJson(data);
        _log(getProfileModel.toString());
        return getProfileModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<UpdateProfileModel?> updateProfileDetails(
    BuildContext context, {
    required String name,
    required String email,
    required String mobile,
    // String? location,
    required String whatsappNo,
    required String gstorpan,
    File? image,
  }) async {
    final Dio dio = ApiClient.instance.dio;
    String userLoginId = await SharedPref.getUserLoginId();
    String imageFileName = image?.path.split('/').last ?? "";
    FormData formData;
    if (image != null) {
      formData = FormData.fromMap({
        "email": email,
        "name": name,
        "mobile": mobile,
        "location": "Na",
        "image":
            await MultipartFile.fromFile(image.path, filename: imageFileName),
        "whatsappno": whatsappNo,
        "gstorpan": gstorpan
      });
    } else {
      formData = FormData.fromMap({
        "email": email,
        "name": name,
        "mobile": mobile,
        "location": "Na",
        "image": null,
        "whatsappno": whatsappNo,
        "gstorpan": gstorpan
      });
    }

    try {
      Response response = await dio.post(
          ApiEndPoint.updateProfileApi + "${int.parse(userLoginId)}",
          data: formData);

      _log("Update Profile response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        UpdateProfileModel updateProfileModel =
            UpdateProfileModel.fromJson(data);
        _log(updateProfileModel.toString());
        return updateProfileModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<GetFeedbackListModel?> getFeedbackListDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String userLoginId = await SharedPref.getUserLoginId();
    // FormData formData = FormData.fromMap({
    //   "userid": userLoginId,
    // });
    _log(ApiEndPoint.getFeedbackListApi + userLoginId);
    try {
      Response response = await dio.get(
        ApiEndPoint.getFeedbackListApi + userLoginId,
      );

      _log("Get Feedback response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        GetFeedbackListModel getFeedbackListModel =
            GetFeedbackListModel.fromJson(data);
        _log(getFeedbackListModel.toString());
        return getFeedbackListModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<PostFeedbackModel?> postFeedbackDetails(BuildContext context,
      {required String feedback}) async {
    final Dio dio = ApiClient.instance.dio;
    String id = await SharedPref.getUserLoginId();
    String name = await SharedPref.getUserName();
    String email = await SharedPref.getUserEmailId();
    FormData formData = FormData.fromMap(
        {"userid": id, "name": name, "email": email, "feedback": feedback});
    try {
      Response response =
          await dio.post(ApiEndPoint.postFeedbackApi, data: formData);

      _log("Post feedback response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        PostFeedbackModel postFeedbackModel = PostFeedbackModel.fromJson(data);
        _log(postFeedbackModel.toString());
        return postFeedbackModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<GetPagesModel?> getPagesDetails(BuildContext context,
      {required String slug}) async {
    final Dio dio = ApiClient.instance.dio;

    try {
      Response response = await dio.get(
        ApiEndPoint.getPagesApi + "?name=${slug}",
      );

      _log("Get Page response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        GetPagesModel getPagesModel = GetPagesModel.fromJson(data);
        _log(getPagesModel.toString());
        return getPagesModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<HelpNoForAppModel?> helpNoForAppDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;

    try {
      Response response = await dio.get(
        ApiEndPoint.helpNoForAppApi,
      );

      _log("Help No For App response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        HelpNoForAppModel helpNoForAppModel = HelpNoForAppModel.fromJson(data);
        _log(helpNoForAppModel.toString());
        return helpNoForAppModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<CategoryScreenModel?> categoryScreenDetails(
    BuildContext context, {
    required int mid,
  }) async {
    _log(mid.toString());
    final Dio dio = ApiClient.instance.dio;
    // FormData formData = FormData.fromMap({
    //   "mid": mid,
    // });
    try {
      _log(ApiEndPoint.categoryScreenApi + "mid=${mid}");
      Response response = await dio.get(
        ApiEndPoint.categoryScreenApi + "mid=${mid}",
        // data: formData
      );

      _log("Category response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        CategoryScreenModel categoryScreenModel =
            CategoryScreenModel.fromJson(data);
        _log(categoryScreenModel.toString());
        return categoryScreenModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<CompanyScreenModel?> companyScreenDetails(
    BuildContext context, {
    required int cid,
    int scid = 0,
  }) async {
    _log(cid.toString());
    final Dio dio = ApiClient.instance.dio;
    FormData formData = FormData.fromMap({
      "cid": cid,
      "scid": scid,
    });

    try {
      Response response = await dio.get(
        ApiEndPoint.companyScreenApi + "cid=${cid}&scid=${scid}",
      );

      _log("Company response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        CompanyScreenModel comapnyScreenModel =
            CompanyScreenModel.fromJson(data);
        _log(comapnyScreenModel.toString());
        return comapnyScreenModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<BrandScreenModel?> brandScreenDetails(
    BuildContext context, {
    required int cmpid,
    required int cid,
  }) async {
    _log(cmpid.toString());
    _log(cid.toString());
    final Dio dio = ApiClient.instance.dio;
    FormData formData = FormData.fromMap({"cmpid": cmpid, "category_id": cid});
    try {
      Response response = await dio.get(
        ApiEndPoint.brandScreenApi + "cmpid=${cmpid}&cid=${cid}",
      );

      _log("Brand response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        BrandScreenModel brandScreenModel = BrandScreenModel.fromJson(data);
        _log(brandScreenModel.toString());
        return brandScreenModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<ProductCategoryListScreenModel?>
      productCategoryListScreenDetails(BuildContext context,
          {required int bid, required int cid, int scid = 0, int cmpid = 0}) async {
    _log(bid.toString());
    _log(cid.toString());
    final Dio dio = ApiClient.instance.dio;
    FormData formData = FormData.fromMap({"bid": bid, "cid": cid, "scid": scid, "cmpid": cmpid});
    try {
      _log(ApiEndPoint.productCategoryListScreenApi + "bid=${bid}&cid=${cid}&scid=${scid}&cmpid=${cmpid}");
      Response response = await dio.get(
        ApiEndPoint.productCategoryListScreenApi + "bid=${bid}&cid=${cid}&scid=${scid}&cmpid=${cmpid}",
      );

      _log("Product Category List response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        ProductCategoryListScreenModel productCategoryListScreenModel =
            ProductCategoryListScreenModel.fromJson(data);
        _log(productCategoryListScreenModel.toString());
        return productCategoryListScreenModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<ProductListByCategoryScreenModel?>
      productListByCategoryScreenDetails(
    BuildContext context, {
    required int sid,
    required int bid,
    int scid = 0,
    int cmpid = 0,
  }) async {
    final Dio dio = ApiClient.instance.dio;
    FormData formData = FormData.fromMap({"bid": bid, "sid": sid, "scid": scid, "cmpid": cmpid});

    try {
      _log("sid is ${sid}");
      _log("bid is ${bid}");
      Response response = await dio.get(
        ApiEndPoint.productListBySubCategoryScreenApi + "sid=${sid}&bid=${bid}&scid=${scid}&cmpid=${cmpid}",
      );

      _log("Product List By Subcategory response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        ProductListByCategoryScreenModel productListBySubCategoryScreenModel =
            ProductListByCategoryScreenModel.fromJson(data);
        _log(productListBySubCategoryScreenModel.toString());
        return productListBySubCategoryScreenModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<ProductDetailModel?> producDetailsDetails(
    BuildContext context, {
    required String productid,
    required String colorid,
  }) async {
    String userid = await SharedPref.getUserLoginId();
    final Dio dio = ApiClient.instance.dio;
    FormData formData = FormData.fromMap(
        {"productid": productid, "colorid": colorid, "userid": userid});
    try {
      Response response =
          await dio.post(ApiEndPoint.productDetailApi, data: formData);

      _log("Product Detail Screen response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        ProductDetailModel productDetailModel =
            ProductDetailModel.fromJson(_decodeBody(response.data));
        _log(productDetailModel.toString());
        return productDetailModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<ProductReviewModel?> producReviewDetails(
    BuildContext context, {
    required String productid,
    required String rating,
    required String review,
  }) async {
    String userid = await SharedPref.getUserLoginId();
    final Dio dio = ApiClient.instance.dio;
    FormData formData = FormData.fromMap({
      "productid": productid,
      "userid": userid,
      "rating": rating,
      "review": review
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.productReviewApi, data: formData);

      _log("Product Review Screen response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        ProductReviewModel productReviewModel =
            ProductReviewModel.fromJson(data);
        _log(productReviewModel.toString());
        return productReviewModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<UserWishlistModel?> userWishlistDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String userid = await SharedPref.getUserLoginId();

    FormData formData = FormData.fromMap({
      "userid": userid,
    });

    try {
      Response response =
          await dio.post(ApiEndPoint.userWishlistApi, data: formData);

      _log("User Wishlist response is ${response.data.toString()}");

      final dynamic rawData = response.data;
      final Map<String, dynamic> data = (rawData is String)
          ? json.decode(rawData)
          : Map<String, dynamic>.from(rawData as Map);

      if (response.statusCode == 200) {
        UserWishlistModel userWishlistModel =
            UserWishlistModel.fromJson(data);

        _log(userWishlistModel.toString());
        return userWishlistModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<DeleteWishlistModel?> deleteWishlistDetails(
      BuildContext context,
      {required String wishlistid}) async {
    final Dio dio = ApiClient.instance.dio;
    String userid = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "wishlistid": wishlistid,
      "userid": userid,
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.deleteWishlistApi, data: formData);

      _log("Delete Wishlist response is ${response.data.toString()}");

      final dynamic rawData = response.data;
      final Map<String, dynamic> data = (rawData is String)
          ? json.decode(rawData)
          : Map<String, dynamic>.from(rawData as Map);

      if (response.statusCode == 200) {
        DeleteWishlistModel deleteWishlistModel =
            DeleteWishlistModel.fromJson(data);
        _log(deleteWishlistModel.toString());
        return deleteWishlistModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<AddToWishlistModel?> addToWishlistDetails(BuildContext context,
      {required String productid, required String color}) async {
    final Dio dio = ApiClient.instance.dio;
    String userid = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap(
        {"productid": productid, "userid": userid, "color": color});

    try {
      Response response =
          await dio.post(ApiEndPoint.addToWishlistApi, data: formData);

      _log("Add To Wishlist response is ${response.data.toString()}");

      final dynamic rawData = response.data;
      final Map<String, dynamic> data = (rawData is String)
          ? json.decode(rawData)
          : Map<String, dynamic>.from(rawData as Map);

      if (response.statusCode == 200) {
        AddToWishlistModel addToWishlistModel =
            AddToWishlistModel.fromJson(data);
        _log(addToWishlistModel.toString());
        return addToWishlistModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<UserCartModel?> userCartDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String userid = await SharedPref.getUserLoginId();

    FormData formData = FormData.fromMap({
      "userid": userid,
    });
    _log(userid.toString());
    try {
      Response response =
          await dio.post(ApiEndPoint.userCartApi, data: formData);

      _log("User Cart response is ${response.data.toString()}");

      if (response.statusCode == 200) {
        UserCartModel userCartModel = UserCartModel.fromJson(_decodeBody(response.data));

        _log(userCartModel.toString());
        return userCartModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<DeleteCartModel?> deleteCartDetails(BuildContext context,
      {required String cartid}) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData = FormData.fromMap({
      "cartid": cartid,
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.deleteCartApi, data: formData);

      _log("Delete Cart response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        DeleteCartModel deleteCartModel =
            DeleteCartModel.fromJson(_decodeBody(response.data));
        _log(deleteCartModel.toString());
        return deleteCartModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<DeleteCartAttributeModel?> deleteCartAttributeDetails(
      BuildContext context,
      {required String cartattributeid}) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData = FormData.fromMap({
      "cartattributeid": cartattributeid,
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.deleteCartAttributeApi, data: formData);

      _log("Delete Cart Attribute response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        DeleteCartAttributeModel deleteCartAttributeModel =
            DeleteCartAttributeModel.fromJson(_decodeBody(response.data));
        _log(deleteCartAttributeModel.toString());
        return deleteCartAttributeModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<EmptyCartModel?> emptyCartDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String customerid = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "customer_id": customerid,
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.emptyCartApi, data: formData);

      _log("Empty Cart response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        EmptyCartModel emptyCartModel = EmptyCartModel.fromJson(_decodeBody(response.data));
        _log(emptyCartModel.toString());
        return emptyCartModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<AddToCartModel?> addToCartDetails(BuildContext context,
      {required String productid,
      required String brandid,
      required List attributes,
      bool replaceCart = false}) async {
    final Dio dio = ApiClient.instance.dio;
    String userid = await SharedPref.getUserLoginId();
    final Map<String, dynamic> body = {
      "productid": productid,
      "userid": userid,
      "brandid": brandid,
      "attributes": attributes,
      "replace_cart": replaceCart
    };

    // FormData formData = FormData.fromMap(
    //     {"productid": productid, "userid": userid, "brandid": qty});
    try {
      Response response = await dio.post(ApiEndPoint.addToCartApi, data: body);

      _log("Add To Cart response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        AddToCartModel addToCartModel = AddToCartModel.fromJson(_decodeBody(response.data));
        _log(addToCartModel.toString());
        return addToCartModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<IncreaseCartQtyModel?> increaseCartQuantityDetails(
      BuildContext context,
      {required String cartattributeid,
      required String qty}) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData =
        FormData.fromMap({"cartattributeid": cartattributeid, "qty": qty});
    try {
      Response response =
          await dio.post(ApiEndPoint.increaseCartQuantityApi, data: formData);

      _log("Increase Cart Quantity response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        IncreaseCartQtyModel increaseCartQtyModel =
            IncreaseCartQtyModel.fromJson(_decodeBody(response.data));
        _log(increaseCartQtyModel.toString());
        return increaseCartQtyModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<GetFaqModel?> getFaqDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;

    try {
      Response response = await dio.get(
        ApiEndPoint.getFaqApi,
      );

      _log("Get Faq response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        GetFaqModel getFaqModel = GetFaqModel.fromJson(data);
        _log(getFaqModel.toString());
        return getFaqModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<GetCouponListModel?> getCouponListDetails(BuildContext context,
      {required String couponof}) async {
    final Dio dio = ApiClient.instance.dio;
    String userid = await SharedPref.getUserLoginId();
    FormData formData =
        FormData.fromMap({"userid": userid, "couponof": couponof});
    try {
      Response response =
          await dio.post(ApiEndPoint.getCouponListApi, data: formData);

      _log("Get Coupon List response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        GetCouponListModel getCouponListModel =
            GetCouponListModel.fromJson(_decodeBody(response.data));
        _log(getCouponListModel.toString());
        return getCouponListModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<ApplyCouponModel?> applyCouponDetails(
    BuildContext context, {
    required String couponid,
  }) async {
    final Dio dio = ApiClient.instance.dio;
    String userid = await SharedPref.getUserLoginId();
    FormData formData =
        FormData.fromMap({"userid": userid, "couponid": couponid});
    try {
      Response response =
          await dio.post(ApiEndPoint.applyCouponApi, data: formData);

      _log("Apply Coupon response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        ApplyCouponModel applyCouponModel =
            ApplyCouponModel.fromJson(_decodeBody(response.data));
        _log(applyCouponModel.toString());
        return applyCouponModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<GetAddressListModel?> getAddressListDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String customerId = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "customer_id": customerId,
    });
    try {
      _log(customerId);
      Response response =
          await dio.post(ApiEndPoint.getAddressListApi, data: formData);

      _log("Get Address List response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        GetAddressListModel getAddressListModel =
            GetAddressListModel.fromJson(_decodeBody(response.data));

        return getAddressListModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<AddAddressModel?> addAddressDetails(BuildContext context,
      {required String name,
      required String landmark1,
      required String landmark2,
      required String type,
      required String country,
      required String state,
      required String city,
      required String pincode,
      required String phoneno,
      required String identityname}) async {
    final Dio dio = ApiClient.instance.dio;
    String customerId = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "customer_id": customerId,
      "name": name,
      "landmark1": landmark1,
      "landmark2": landmark2,
      "country": country,
      "state": state,
      "city": city,
      "pincode": pincode,
      "phoneno": phoneno,
      "location": "NA",
      "identityname": identityname,
      "type": type
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.addAddressApi, data: formData);

      _log("Add Address response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        AddAddressModel addAddressModel =
            AddAddressModel.fromJson(_decodeBody(response.data));

        return addAddressModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<UpdateAddressModel?> updateAddressDetails(BuildContext context,
      {required String name,
      required String landmark,
      required String address,
      required String country,
      required String state,
      required String city,
      required String pincode,
      required String phoneno,
      required String identityname,
      required String addressId,
      required String type}) async {
    final Dio dio = ApiClient.instance.dio;
    String customerId = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "customer_id": customerId,
      "name": name,
      "landmark1": address,
      "landmark2": landmark,
      "country": country,
      "state": state,
      "city": city,
      "pincode": pincode,
      "phoneno": phoneno,
      "location": "NA",
      "identityname": identityname,
      "type": type
    });
    try {
      Response response = await dio
          .post(ApiEndPoint.updateAddressApi + addressId, data: formData);

      _log("Update Address response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        UpdateAddressModel updateAddressModel =
            UpdateAddressModel.fromJson(_decodeBody(response.data));

        return updateAddressModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<GetAddressDetailModel?> getIdAddressDetails(
      BuildContext context,
      {required String addressId}) async {
    final Dio dio = ApiClient.instance.dio;

    try {
      Response response =
          await dio.get(ApiEndPoint.getAddressDetailApi + addressId);

      _log("Get Id Address response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        GetAddressDetailModel getAddressDetailModel =
            GetAddressDetailModel.fromJson(_decodeBody(response.data));

        return getAddressDetailModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<DeleteAddressModel?> deleteAddressDetails(BuildContext context,
      {required String addressid}) async {
    final Dio dio = ApiClient.instance.dio;

    try {
      Response response =
          await dio.delete(ApiEndPoint.deleteAddressApi + addressid);

      _log("Delete Address response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        DeleteAddressModel deleteAddressModel =
            DeleteAddressModel.fromJson(_decodeBody(response.data));

        return deleteAddressModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<UpdateCartAddressModel?> updateCartAddressDetail(
    BuildContext context, {
    required String addressid,
  }) async {
    final Dio dio = ApiClient.instance.dio;
    String customerId = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "userid": customerId,
      "addressid": addressid,
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.updateCartAddressApi, data: formData);

      _log("Update Cart Address response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        UpdateCartAddressModel updateCartAddressModel =
            UpdateCartAddressModel.fromJson(_decodeBody(response.data));

        return updateCartAddressModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<StateModel?> stateModelDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    // String customerId = await SharedPref.getUserLoginId();
    // FormData formData = FormData.fromMap({
    //   "customer_id": customerId,
    // });
    try {
      Response response = await dio.get(
        "${ApiEndPoint.stateCityPincodeApi}?listof=state&name=",
      );

      _log("Get State List is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        StateModel stateModel = StateModel.fromJson(data);

        return stateModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<CityListModel?> cityModelDetails(BuildContext context,
      {required String state}) async {
    final Dio dio = ApiClient.instance.dio;

    try {
      Response response = await dio.get(
        "${ApiEndPoint.stateCityPincodeApi}?listof=city&name=${state}",
      );

      _log("Get City List is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        CityListModel cityListModel = CityListModel.fromJson(data);

        return cityListModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<PincodeListModel?> pincodeModelDetails(BuildContext context,
      {required String city}) async {
    final Dio dio = ApiClient.instance.dio;

    try {
      Response response = await dio.get(
        "${ApiEndPoint.stateCityPincodeApi}?listof=pincode&name=${city}",
      );

      _log("Get Pincode List is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        PincodeListModel pincodeListModel = PincodeListModel.fromJson(data);

        return pincodeListModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<CheckAddressAvailabilityModel?> checkAddressAvailabilityDetails(
      {required BuildContext context, required String addressid}) async {
    final Dio dio = ApiClient.instance.dio;
    String userId = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "userid": userId,
      "addressid": addressid,
    });
    try {
      Response response =
          await dio.post("${ApiEndPoint.checkAvailabilityApi}", data: formData);

      _log("Check Address Availability is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        CheckAddressAvailabilityModel checkAddressAvailabilityModel =
            CheckAddressAvailabilityModel.fromJson(_decodeBody(response.data));

        return checkAddressAvailabilityModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<OrderModel?> orderDetails(
    BuildContext context, {
    required String addressid,
  }) async {
    final Dio dio = ApiClient.instance.dio;
    String userId = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "userid": userId,
      "addressid": addressid,
    });
    try {
      Response response = await dio.post(ApiEndPoint.orderApi, data: formData);

      _log("Order response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        OrderModel orderModel = OrderModel.fromJson(_decodeBody(response.data));

        return orderModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<Map<String, dynamic>?> generatePayuHash(
    Map hashParams,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    try {
      final body = <String, dynamic>{};
      hashParams.forEach((k, v) {
        body[k.toString()] = v;
      });
      final Response response = await dio.post(
        ApiEndPoint.payuHashApi,
        data: body,
      );
      if (response.statusCode == 200) {
        final data = _decodeBody(response.data);
        final String hashName =
            (hashParams['hashName'] ?? 'payment_hash').toString();
        final String? hash =
            (data[hashName] ?? data['hash'])?.toString();
        if (hash != null && hash.isNotEmpty) {
          return {hashName: hash};
        }
      }
    } catch (e) {
      _log('generatePayuHash error: $e');
    }
    return null;
  }

  static Future<void> recordPayuCallback({
    required bool success,
    required Map<String, dynamic> payload,
  }) async {
    final Dio dio = ApiClient.instance.dio;
    try {
      await dio.post(
        success
            ? ApiEndPoint.orderTransectionSuccessApi
            : ApiEndPoint.orderTransectionFailedApi,
        data: payload,
      );
    } catch (e) {
      _log('recordPayuCallback error: $e');
    }
  }

  static Future<SingleOrderDetailModel?> singleOrderDetail(
    BuildContext context, {
    required String orderno,
  }) async {
    final Dio dio = ApiClient.instance.dio;
_log("message");
    FormData formData = FormData.fromMap({
      "orderno": orderno,
    });
    _log(orderno);
    try {
      Response response =
          await dio.post(ApiEndPoint.singleOrderDetailApi, data: formData);

      _log("Single Order Detail response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        SingleOrderDetailModel singleOrderDetailModel =
            SingleOrderDetailModel.fromJson(_decodeBody(response.data));

        return singleOrderDetailModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<BrandDetailModel?> brandDetail(
    BuildContext context, {
    required String brandid,
  }) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData = FormData.fromMap({
      "brandid": brandid,
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.brandDetailApi, data: formData);

      _log("Brand Detail response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        BrandDetailModel brandDetailModel = BrandDetailModel.fromJson(data);

        return brandDetailModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<OrderHistoryModel?> orderHistoryDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String userId = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "userid": userId,
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.orderHistoryApi, data: formData);

      _log("Order History response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        OrderHistoryModel orderHistoryModel =
            OrderHistoryModel.fromJson(_decodeBody(response.data));

        return orderHistoryModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<NotificationModel?> notificationDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String userId = await SharedPref.getUserLoginId();

    try {
      Response response = await dio.get(
        ApiEndPoint.notificationApi + "userid=${userId}",
      );

      _log("Notification response is ${response.data.toString()}");

      final dynamic rawData = response.data;
      final Map<String, dynamic> data = (rawData is String)
          ? json.decode(rawData)
          : Map<String, dynamic>.from(rawData as Map);

      if (response.statusCode == 200) {
        NotificationModel notificationModel = NotificationModel.fromJson(data);
        _log(notificationModel.toString());
        return notificationModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<RelatedProductModel?> relatedProductDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;
    String userId = await SharedPref.getUserLoginId();
    FormData formData = FormData.fromMap({
      "userid": userId,
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.relatedProductApi, data: formData);

      _log("Related Product response is ${response.data.toString()}");

      // var data = json.decode(response.data);

      if (response.statusCode == 200) {
        RelatedProductModel relatedProductModel =
            RelatedProductModel.fromJson(_decodeBody(response.data));
        _log(relatedProductModel.toString());
        return relatedProductModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<AdminAppPagesModel?> adminAppPagesDetails(
    BuildContext context,
  ) async {
    final Dio dio = ApiClient.instance.dio;

    try {
      Response response = await dio.get(
        ApiEndPoint.adminAppPagesApi,
      );

      _log("Admin app pages response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        AdminAppPagesModel adminAppPagesModel =
            AdminAppPagesModel.fromJson(data);
        _log(adminAppPagesModel.toString());
        return adminAppPagesModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  static Future<GstVerificationModel?> gstVerificationDetails(
    BuildContext context, {
    required String gstNumber,
  }) async {
    final Dio dio = ApiClient.instance.dio;

    FormData formData = FormData.fromMap({
      "gst": gstNumber,
    });
    try {
      Response response =
          await dio.post(ApiEndPoint.gstVerificationApi, data: formData);

      _log("Gst Verification response is ${response.data.toString()}");

      var data = _decodeBody(response.data);

      if (response.statusCode == 200) {
        GstVerificationModel gstVerificationModel =
            GstVerificationModel.fromJson(data);
        _log(gstVerificationModel.toString());
        return gstVerificationModel;
      } else {
        return null;
      }
    } on DioException catch (error) {
      return await HandleDio.handleDioError(error: error, context: context);
    }
  }

  /// Phase 7.2: Fetch buyer multi-seller order tracking details (/v2/buyer/orders/{orderId}/tracking).
  static Future<Map<String, dynamic>> fetchOrderTracking({
    required int orderId,
    int? customerId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.instance.dio.get(
        '${ApiEndPoint.baseUrl}v2/buyer/orders/$orderId/tracking',
        queryParameters:
            customerId != null ? {'customer_id': customerId} : null,
        cancelToken: cancelToken,
      );
      final dynamic body =
          response.data is String ? json.decode(response.data) : response.data;
      if (body is Map<String, dynamic> && body['status'] == true) {
        return {
          'ok': true,
          'statusCode': response.statusCode,
          'data': body['data'],
          'message': 'Tracking summary loaded.',
        };
      }
      return {
        'ok': false,
        'statusCode': response.statusCode,
        'message': (body is Map ? body['message']?.toString() : null) ??
            'Unable to load fulfilment tracking.',
      };
    } on DioException catch (error) {
      final apiError = ApiClient.mapError(error);
      return {
        'ok': false,
        'statusCode': apiError.statusCode,
        'message': apiError.message,
      };
    }
  }

  /// Phase 7.2: Submit buyer receipt acknowledgement to /v2/buyer/fulfilment/{fulfilmentId}/acknowledge.
  static Future<Map<String, dynamic>> acknowledgeConsignmentReceipt({
    required int fulfilmentId,
    int? customerId,
    String? notes,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.instance.dio.post(
        '${ApiEndPoint.acknowledgeReceiptApi}$fulfilmentId/acknowledge',
        data: {
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          if (customerId != null && customerId > 0) 'customer_id': customerId,
        },
        cancelToken: cancelToken,
      );
      final dynamic body =
          response.data is String ? json.decode(response.data) : response.data;
      if (body is Map<String, dynamic> && body['status'] == true) {
        return {
          'ok': true,
          'statusCode': response.statusCode,
          'message': body['message']?.toString() ??
              'Consignment receipt acknowledged.',
          'data': body['data'],
        };
      }
      return {
        'ok': false,
        'statusCode': response.statusCode,
        'message': (body is Map ? body['message']?.toString() : null) ??
            'Could not acknowledge consignment receipt.',
      };
    } on DioException catch (error) {
      final apiError = ApiClient.mapError(error);
      return {
        'ok': false,
        'statusCode': apiError.statusCode,
        'message': apiError.message,
      };
    }
  }

  /// Phase 7.2: Submit buyer shortage/damage claim to /v2/buyer/fulfilment/{fulfilmentId}/claim.
  static Future<Map<String, dynamic>> submitConsignmentClaim({
    required int fulfilmentId,
    required String claimType,
    required String description,
    int? customerId,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.instance.dio.post(
        '${ApiEndPoint.lodgeClaimApi}$fulfilmentId/claim',
        data: {
          'claim_type': claimType,
          'description': description.trim(),
          if (customerId != null && customerId > 0) 'customer_id': customerId,
          if (idempotencyKey != null && idempotencyKey.isNotEmpty)
            'idempotency_key': idempotencyKey,
        },
        cancelToken: cancelToken,
      );
      final dynamic body =
          response.data is String ? json.decode(response.data) : response.data;
      if (body is Map<String, dynamic> && body['status'] == true) {
        return {
          'ok': true,
          'statusCode': response.statusCode,
          'message': body['message']?.toString() ??
              'Dispute claim submitted successfully.',
          'data': body['data'],
        };
      }
      return {
        'ok': false,
        'statusCode': response.statusCode,
        'message': (body is Map ? body['message']?.toString() : null) ??
            'Could not submit dispute claim.',
      };
    } on DioException catch (error) {
      final apiError = ApiClient.mapError(error);
      return {
        'ok': false,
        'statusCode': apiError.statusCode,
        'message': apiError.message,
      };
    }
  }
}
