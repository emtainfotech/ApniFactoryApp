import 'package:apni_factory/model/brand_screen_model.dart';
import 'package:apni_factory/model/home_screen_model.dart';
import 'package:apni_factory/model/user_cart_model.dart';
import 'package:apni_factory/provider/wishlist_screen_provider.dart';
import 'package:apni_factory/res/widgets/swiggy_home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('Single-company storefront model parsing', () {
    test('HomeProduct parses company metadata fields cleanly', () {
      final product = HomeProduct.fromJson({
        'id': 42,
        'name': 'Luxury Silk Emulsion',
        'image': 'prod.jpg',
        'category_id': 7,
        'category_name': 'Interior Emulsion',
        'brand_id': 9,
        'brand_name': 'MALAK',
        'company_id': 3,
        'company_name': 'MALAK PAINTS',
        'company_city': 'Indore',
        'company_photo': 'comp.jpg',
        'price': 999,
        'oldprice': 1299,
        'color_id': '14',
        'pack_size': '20 LTR',
        'attribute_id': 88,
      });

      expect(product.id, 42);
      expect(product.companyId, 3);
      expect(product.companyName, 'MALAK PAINTS');
      expect(product.companyCity, 'Indore');
      expect(product.price, 999);
      expect(product.oldprice, 1299);
    });

    test('BrandScreenModel parses company info, all_brands, categories, and products', () {
      final model = BrandScreenModel.fromJson({
        'status': true,
        'code': 100,
        'msg': 'Successfully Show',
        'data': {
          'cmpid': 3,
          'companyname': 'MALAK PAINTS',
          'bannerimage': 'banner.jpg',
          'company': {
            'id': 3,
            'name': 'MALAK PAINTS',
            'photo': 'banner.jpg',
            'city': 'Indore',
            'state': 'MP',
            'minordervalue': 5000,
          },
          'Brand': [
            {'id': 9, 'name': 'MALAK', 'company_id': 3, 'category_id': 7, 'status': 1},
          ],
          'all_brands': [
            {'id': 9, 'name': 'MALAK', 'company_id': 3, 'category_id': 7, 'status': 1},
            {'id': 10, 'name': 'ROYAL', 'company_id': 3, 'category_id': 8, 'status': 1},
          ],
          'categories': [
            {'id': 7, 'name': 'Interior Emulsion', 'image': 'cat7.jpg', 'maincategory_id': 1},
          ],
          'products': [
            {
              'id': 101,
              'name': 'Super Primer',
              'image': 'p101.jpg',
              'category_id': 7,
              'brand_id': 9,
              'company_id': 3,
              'company_name': 'MALAK PAINTS',
              'price': 450,
              'oldprice': 600,
            },
          ],
        },
      });

      expect(model.data?.company?.name, 'MALAK PAINTS');
      expect(model.data?.company?.minordervalue, 5000);
      expect(model.data?.allBrands?.length, 2);
      expect(model.data?.categories?.single.name, 'Interior Emulsion');
      expect(model.data?.products?.single.companyId, 3);
    });

    test('UserCartModel resolves activeCompanyId and activeCompanyName', () {
      final cart = UserCartModel.fromJson({
        'status': true,
        'code': 100,
        'msg': 'Successfully Show',
        'grandtotal': 1500,
        'netamount': 1271,
        'counter': 1,
        'cgst': 114.5,
        'sgst': 114.5,
        'igst': 0,
        'couponbyadmin': 0,
        'combinecoupon': '0',
        'company_id': 3,
        'company_name': 'MALAK PAINTS',
        'company_city': 'Indore',
        'seller_groups': [],
        'all_sellers_can_checkout': true,
        'data': <String, dynamic>{},
      });

      expect(cart.activeCompanyId, 3);
      expect(cart.activeCompanyName, 'MALAK PAINTS');
      expect(cart.companyCity, 'Indore');
    });
  });

  group('Swiggy Home widgets rendering', () {
    testWidgets('SwiggyHorizontalFeedCard shows offer price, company badge, and fires onTap',
        (WidgetTester tester) async {
      bool tapped = false;
      final product = HomeProduct(
        id: 55,
        name: 'Weather Shield Exterior',
        brandName: 'CHOUDHARY',
        categoryName: 'Exterior Paint',
        companyId: 12,
        companyName: 'CHOUDHARY CHEMICALS',
        companyCity: 'Jaipur',
        price: 750,
        oldprice: 1000,
        packSize: '10 LTR',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<WishlistProvider>(
          create: (_) => WishlistProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SwiggyHorizontalFeedCard(
                product: product,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Weather Shield Exterior'), findsOneWidget);
      expect(find.text('AT ₹750.00'), findsOneWidget);
      expect(find.text('CHOUDHARY CHEMICALS • Jaipur'), findsOneWidget);
      expect(find.text('Visit Factory'), findsOneWidget);

      await tester.tap(find.text('Weather Shield Exterior'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('SwiggyTopOfferCompanyCard displays company metadata and MOV',
        (WidgetTester tester) async {
      bool tapped = false;
      final comp = HomeCompany(
        id: 2,
        name: 'SKY PRODUCTS',
        city: 'Delhi',
        state: 'DL',
        minordervalue: 2500,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwiggyTopOfferCompanyCard(
              company: comp,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('SKY PRODUCTS'), findsOneWidget);
      expect(find.text('4.4 • MOV ₹2500'), findsOneWidget);
      await tester.tap(find.text('SKY PRODUCTS'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}

