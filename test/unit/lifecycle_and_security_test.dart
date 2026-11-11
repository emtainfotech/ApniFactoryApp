import 'package:apni_factory/api_services/hash_service';
import 'package:apni_factory/model/product_category_list_model.dart';
import 'package:apni_factory/provider/brand_screen_provider.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/category_screen_provider.dart';
import 'package:apni_factory/provider/change_password_provider.dart';
import 'package:apni_factory/provider/company_screen_provider.dart';
import 'package:apni_factory/provider/feedback_provider.dart';
import 'package:apni_factory/provider/forgot_password_provider.dart';
import 'package:apni_factory/provider/homeScreen_provider.dart';
import 'package:apni_factory/provider/login_provider.dart';
import 'package:apni_factory/provider/product_category_list_screen_provider.dart';
import 'package:apni_factory/provider/product_detail_provider.dart';
import 'package:apni_factory/provider/sign_up_provider.dart';
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
}

