import '../config/api_config.dart';

class ApiEndPoint {
  static String get baseUrl => ApiConfig.baseUrl;

  static String get signUpApi => '${baseUrl}register';
  static String get loginApi => '${baseUrl}login';
  static String get getOtpApi => '${baseUrl}sendotp';
  static String get verifyOtpApi => '${baseUrl}verifyotp';
  static String get resetPasswordApi => '${baseUrl}resetpassword';
  static String get homeScreenApi => '${baseUrl}homescreen';
  static String get randomProductsApi => '${baseUrl}randomproducts';
  static String get searchApi => '${baseUrl}search';
  static String get categoryScreenApi => '${baseUrl}categoryscreen?';
  static String get companyScreenApi => '${baseUrl}companyscreen?';
  static String get brandScreenApi => '${baseUrl}brandscreen?';
  static String get productCategoryListScreenApi => '${baseUrl}productlist?';
  static String get productListBySubCategoryScreenApi =>
      '${baseUrl}productlistbycategory?';
  static String get productDetailApi => '${baseUrl}productdetail';
  static String get getAddressListApi => '${baseUrl}address';
  static String get addAddressApi => '${baseUrl}addaddress';
  static String get getAddressDetailApi => '${baseUrl}address/';
  static String get updateAddressApi => '${baseUrl}address/';
  static String get deleteAddressApi => '${baseUrl}address/';
  static String get updateCartAddressApi => '${baseUrl}updatecartaddress';
  static String get productReviewApi => '${baseUrl}productreview';
  static String get addToCartApi => '${baseUrl}addtocart';
  static String get userCartApi => '${baseUrl}usercart';
  static String get deleteCartApi => '${baseUrl}deletecart';
  static String get deleteCartAttributeApi => '${baseUrl}deletecartattribute';
  static String get emptyCartApi => '${baseUrl}emptycart';
  static String get addToWishlistApi => '${baseUrl}addtowishlist';
  static String get userWishlistApi => '${baseUrl}userwishlist';
  static String get deleteWishlistApi => '${baseUrl}deletewishlist';
  static String get getProfileApi => '${baseUrl}viewprofile/';
  static String get updateProfileApi => '${baseUrl}updateprofile/';
  static String get getFaqApi => '${baseUrl}faq';
  static String get getFeedbackListApi => '${baseUrl}feedback/';
  static String get postFeedbackApi => '${baseUrl}feedback';
  static String get changePasswordApi => '${baseUrl}changepassword/';
  static String get increaseCartQuantityApi => '${baseUrl}increasecartqty';
  static String get orderApi => '${baseUrl}order';
  static String get orderHistoryApi => '${baseUrl}orderhistory';
  static String get getPagesApi => '${baseUrl}pages';
  static String get getCouponListApi => '${baseUrl}couponlist';
  static String get applyCouponApi => '${baseUrl}applycoupon';
  static String get stateCityPincodeApi => '${baseUrl}statecitypincode';
  static String get checkAvailabilityApi => '${baseUrl}checkavailability';
  static String get payuHashApi => '${baseUrl}payuhash';
  static String get singleOrderDetailApi => '${baseUrl}orderdetail';
  static String get brandDetailApi => '${baseUrl}branddetail';
  static String get notificationApi => '${baseUrl}notification?';
  static String get relatedProductApi => '${baseUrl}relatedproductincart';
  static String get adminAppPagesApi => '${baseUrl}adminapppages';
  static String get helpNoForAppApi => '${baseUrl}helpnoforapp';
  static String get gstVerificationApi => '${baseUrl}gstverification';

  // Phase 5.2 & Phase 7.2: Buyer Receipt Acknowledgement & Dispute Claims
  static String get acknowledgeReceiptApi =>
      '${baseUrl}v2/buyer/fulfilment/';
  static String get buyerClaimsApi => '${baseUrl}v2/buyer/claims';
  static String get lodgeClaimApi => '${baseUrl}v2/buyer/fulfilment/';

  // Phase 7.1 Authoritative v2 Catalog, Cart & Tracking Endpoints
  static String get v2ProductsApi => '${baseUrl}v2/products';
  static String get v2SearchApi => '${baseUrl}v2/catalogue/search';
  static String get v2CartApi => '${baseUrl}v2/cart';
  static String get v2OrderTrackingApi => '${baseUrl}v2/orders/track';
  static String get v2BuyerProgressApi => '${baseUrl}v2/buyer/progress';
}
