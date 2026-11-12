import 'dart:typed_data';

import 'package:apni_factory/api_services/api_client.dart';
import 'package:apni_factory/api_services/hash_service';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apni_factory/model/home_screen_model.dart';
import 'package:apni_factory/model/order_histort_model.dart';
import 'package:apni_factory/model/product_category_list_model.dart';
import 'package:apni_factory/model/single_order_detail_model.dart';
import 'package:apni_factory/provider/brand_screen_provider.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/category_screen_provider.dart';
import 'package:apni_factory/provider/change_password_provider.dart';
import 'package:apni_factory/provider/company_screen_provider.dart';
import 'package:apni_factory/provider/feedback_provider.dart';
import 'package:apni_factory/provider/forgot_password_provider.dart';
import 'package:apni_factory/provider/homeScreen_provider.dart';
import 'package:apni_factory/provider/login_provider.dart';
import 'package:apni_factory/provider/order_history_provider.dart';
import 'package:apni_factory/provider/product_category_list_screen_provider.dart';
import 'package:apni_factory/provider/product_detail_provider.dart';
import 'package:apni_factory/provider/sign_up_provider.dart';
import 'package:apni_factory/provider/single_order_detail_provider.dart';
import 'package:apni_factory/provider/ticket_provider.dart';
import 'package:apni_factory/provider/your_profile_screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _expectDisposedController(TextEditingController controller) {
  expect(() => controller.addListener(() {}), throwsFlutterError);
}

void main() {
  group('Security hardening - HashService', () {
    test('fails closed without hardcoded salt when PAYU_MERCHANT_SALT is unset',
        () {
      if (!HashService.hasLocalHashConfig) {
        expect(
          () => HashService.generateHash({
            'hashName': 'payment_hash',
            'hashString': 'key|txnid|100|info|name|a@b.com|||||||||||',
          }),
          throwsStateError,
        );
      }
      expect(HashService.getSHA512Hash('abc').length, 128);
      expect(HashService.getHmacSHA256Hash('abc', 'key'), isNotEmpty);
      expect(HashService.getHmacSHA1Hash('abc', 'key'), isNotEmpty);
    });
  });

  group('Provider lifecycle and TextEditingController disposal', () {
    test('BrandScreenProvider disposes searchController', () {
      final p = BrandScreenProvider();
      p.dispose();
      _expectDisposedController(p.searchController);
    });

    test('CategoryScreenProvider disposes categorySearchController', () {
      final p = CategoryScreenProvider();
      p.dispose();
      _expectDisposedController(p.categorySearchController);
    });

    test('CompanyScreenProvider disposes companySearchController', () {
      final p = CompanyScreenProvider();
      p.dispose();
      _expectDisposedController(p.companySearchController);
    });

    test('ChangePasswordProvider disposes password controllers', () {
      final p = ChangePasswordProvider();
      p.dispose();
      _expectDisposedController(p.currentPasswordController);
      _expectDisposedController(p.newPasswordController);
    });

    test('FeedbackProvider disposes feedbackController', () {
      final p = FeedbackProvider();
      p.dispose();
      _expectDisposedController(p.feedbackController);
    });

    test('ForgotPasswordProvider cancels timer and disposes controllers', () {
      final p = ForgotPasswordProvider();
      p.showOtpTimer();
      p.dispose();
      _expectDisposedController(p.emailController);
      _expectDisposedController(p.passwordController);
      _expectDisposedController(p.otpController);
    });

    test('ProductDetailProvider disposes review controller', () {
      final p = ProductDetailProvider();
      p.dispose();
      _expectDisposedController(p.revierController);
    });

    test('SignUpProvider disposes all 7 registration controllers', () {
      final p = SignUpProvider();
      p.dispose();
      _expectDisposedController(p.emailController);
      _expectDisposedController(p.passwordController);
      _expectDisposedController(p.mobileNumberController);
      _expectDisposedController(p.confirmPasswordController);
      _expectDisposedController(p.nameController);
      _expectDisposedController(p.emailOtpController);
      _expectDisposedController(p.mobileOtpController);
    });

    test('YourProfileScreenProvider disposes all 6 profile controllers', () {
      final p = YourProfileScreenProvider();
      p.dispose();
      _expectDisposedController(p.emailController);
      _expectDisposedController(p.nameController);
      _expectDisposedController(p.mobileController);
      _expectDisposedController(p.locationController);
      _expectDisposedController(p.whatsappnoController);
      _expectDisposedController(p.gstorpanController);
    });

    test('CartScreenProvider disposes address controllers', () {
      final p = CartScreenProvider();
      p.dispose();
      _expectDisposedController(p.nameController);
      _expectDisposedController(p.editNameController);
      _expectDisposedController(p.editPincodeController);
    });

    test('HomeScreenProvider disposes search and address controllers', () {
      final p = HomeScreenProvider();
      p.dispose();
      _expectDisposedController(p.searchController);
      _expectDisposedController(p.nameController);
      _expectDisposedController(p.editPincodeController);
    });

    test('LoginProvider safely operates without Firebase and disposes cleanly',
        () async {
      final p = LoginProvider();
      expect(p.auth, isNull);
      expect(p.messaging, isNull);
      p.authChange();
      expect(await p.getDeviceToken(), '');
      p.dispose();
      _expectDisposedController(p.emailController);
      _expectDisposedController(p.passwordController);
    });
  });

  group('ProductCategoryListScreenProvider pagination', () {
    test('slices products in pageSize batches and advances on loadMoreProducts',
        () {
      final p = ProductCategoryListScreenProvider();
      p.productDetails = List.generate(
        45,
        (i) => Product(pid: i + 1, name: 'Product ${i + 1}'),
      );

      expect(p.paginatedProducts.length, 20);
      expect(p.hasMoreProducts, isTrue);

      p.loadMoreProducts();
      expect(p.paginatedProducts.length, 40);
      expect(p.hasMoreProducts, isTrue);

      p.loadMoreProducts();
      expect(p.paginatedProducts.length, 45);
      expect(p.hasMoreProducts, isFalse);

      p.resetState();
      expect(p.productDetails, isNull);
      expect(p.errorMessage, isNull);
      p.dispose();
    });
  });

  group('Order decimal JSON parsing & spinner termination', () {
    test('OrderHistoryModel parses stringified MySQL decimals cleanly', () {
      final model = OrderHistoryModel.fromJson({
        'status': true,
        'code': 100,
        'msg': 'Orders fetched',
        'data': [
          {
            'id': 1,
            'orderno': 'ORD-2026-IND-0105',
            'sellercouponamount': '0.00',
            'admincouponamount': '100.50',
            'netamount': '38000.00',
            'taxamount': '6840.00',
            'grandtotal': '44840.00',
          }
        ],
      });

      expect(model.code, 100);
      expect(model.data, hasLength(1));
      expect(model.data!.first.netamount, 38000.0);
      expect(model.data!.first.taxamount, 6840.0);
      expect(model.data!.first.grandtotal, 44840.0);
      expect(model.data!.first.admincouponamount, 100.5);
    });

    test('SingleOrderDetailModel parses stringified decimals and attribute ints',
        () {
      final model = SingleOrderDetailModel.fromJson({
        'status': true,
        'code': 100,
        'msg': 'OK',
        'data': {
          'id': 5,
          'orderno': 'ORD-2026-IND-0105',
          'sellercouponamount': '0',
          'admincouponamount': '',
          'netamount': '38000.00',
          'taxamount': '6840.00',
          'grandtotal': '44840.00',
          'orderdetail': [
            {
              'id': 10,
              'prname': 'Industrial Enamel',
              'attribute': [
                {
                  'boxpacking': '20L Drum',
                  'color': 'White',
                  'qty': '2',
                  'boxpcs': '1',
                  'prprice': '19000.00',
                  'coupon': '0.00',
                  'amntaftrcoupn': '38000.00',
                  'unitprice': '19000.00',
                  'totalprice': '38000.00',
                  'tax': '18%',
                  'taxamount': '6840.00',
                }
              ],
            }
          ],
          'track': {'id': 1, 'status': 1, 'creditamnt': '250.25'},
        },
      });

      expect(model.data!.grandtotal, 44840.0);
      expect(model.data!.admincouponamount, isNull);
      final attr = model.data!.orderdetail!.first.attribute!.first;
      expect(attr.qty, 2);
      expect(attr.boxpcs, 1);
      expect(attr.prprice, 19000.0);
      expect(attr.totalprice, 38000.0);
      expect(model.data!.track!.creditamnt, 250.25);
    });

    testWidgets(
        'Providers clear loading flags when backend fails instead of spinning forever',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'userLoginId': '31'});
      final previousAdapter = ApiClient.instance.dio.httpClientAdapter;
      ApiClient.instance.dio.httpClientAdapter = _FailingAdapter();
      try {
        late BuildContext capturedContext;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        await tester.runAsync(() async {
          final orderProvider = OrderHistoryProvider();
          await orderProvider.orderHistory(context: capturedContext);
          expect(orderProvider.loadingOrderHistory, isFalse);

          final detailProvider = SingleOrderDetailProvider();
          await detailProvider.singleOrderDetail(
            context: capturedContext,
            orderno: 'ORD-INVALID',
          );
          expect(detailProvider.loadingSingleOrderDetail, isFalse);

          final feedbackProvider = FeedbackProvider();
          await feedbackProvider.getFeedbackList(context: capturedContext);
          expect(feedbackProvider.loadingGetFeedbackList, isFalse);
          feedbackProvider.dispose();

          final ticketProvider = TicketProvider();
          await ticketProvider.helpNoForAppDetails(context: capturedContext);
          expect(ticketProvider.loadingHelpNoForApp, isFalse);
        });
      } finally {
        ApiClient.instance.dio.httpClientAdapter = previousAdapter;
      }
    });

    test('HomeSubcategory and Subcategory preserve scid for 4th-tier filtering',
        () {
      final homeSub = HomeSubcategory.fromJson({
        'id': 113,
        'scid': 4,
        'name': 'N. C. Paints',
        'image': 'sub.png',
        'maincategory_id': 2,
      });
      expect(homeSub.id, 113);
      expect(homeSub.scid, 4);

      final catSub = Subcategory.fromJson({
        'highlight': true,
        'name': 'N. C. Paints',
        'image': 'sub.png',
        'cid': 113,
        'scid': 4,
        'bid': 0,
      });
      expect(catSub.cid, 113);
      expect(catSub.scid, 4);
      expect(catSub.highlight, isTrue);
    });
  });
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"status":false,"code":500,"msg":"Simulated server error"}',
      500,
      headers: {
        Headers.contentTypeHeader: ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

