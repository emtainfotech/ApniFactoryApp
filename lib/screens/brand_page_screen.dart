import 'package:apni_factory/model/brand_screen_model.dart';
import 'package:apni_factory/model/home_screen_model.dart';
import 'package:apni_factory/provider/brand_screen_provider.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/wishlist_screen_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/widgets/app_network_image.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:apni_factory/res/widgets/global_cart_container.dart';
import 'package:apni_factory/res/widgets/storefront_widgets.dart';
import 'package:apni_factory/res/widgets/swiggy_home_widgets.dart';
import 'package:apni_factory/screens/description_page_screen.dart';
import 'package:apni_factory/screens/product_category_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BrandPageScreen extends StatefulWidget {
  final int cmpid;
  final int cid;
  final int scid;
  final HomeProduct? highlightProduct;
  final int? highlightProductId;

  const BrandPageScreen({
    super.key,
    required this.cmpid,
    required this.cid,
    this.scid = 0,
    this.highlightProduct,
    this.highlightProductId,
  });

  @override
  State<BrandPageScreen> createState() => _BrandPageScreenState();
}

class _BrandPageScreenState extends State<BrandPageScreen> {
  late BrandScreenProvider _brandProvider;
  int _selectedBrandId = 0; // 0 = All Company Brands
  int _selectedCategoryId = 0; // 0 = All Company Categories
  final Set<String> _addedItemKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await Provider.of<BrandScreenProvider>(context, listen: false)
        .brandScreen(context: context, cmpid: widget.cmpid, cid: widget.cid);
    if (!mounted) return;
    await Provider.of<CartScreenProvider>(context, listen: false)
        .userCart(context: context, isSilent: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _brandProvider = Provider.of<BrandScreenProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _brandProvider.clearSearch();
      },
      child: Consumer<BrandScreenProvider>(
        builder: (context, provider, _) {
          final data = provider.brandScreenModel?.data;
          final String companyName =
              data?.companyname?.trim().isNotEmpty == true
                  ? data!.companyname!.trim()
                  : (data?.company?.name?.trim() ?? '');
          final String bannerImage = (data?.bannerimage ?? '').trim().isNotEmpty
              ? data!.bannerimage!.trim()
              : (data?.company?.photo ?? '').trim();
          final List<Brand> brands = (data?.allBrands != null &&
                  data!.allBrands!.isNotEmpty)
              ? data.allBrands!
              : (data?.brand ?? []);
          final List<BrandCategory> categories = data?.categories ?? [];
          final List<HomeProduct> allProducts = data?.products ?? [];

          final Set<int> brandCategoryIds = _selectedBrandId == 0
              ? categories.map((c) => c.id ?? 0).toSet()
              : allProducts
                  .where((p) => p.brandId == _selectedBrandId && (p.categoryId ?? 0) > 0)
                  .map((p) => p.categoryId!)
                  .toSet();

          final List<BrandCategory> visibleCategories = _selectedBrandId == 0
              ? categories
              : categories.where((c) => brandCategoryIds.contains(c.id)).toList();

          final HomeProduct? spotlightProduct = _resolveSpotlightProduct(
            allProducts: allProducts,
          );

          final List<HomeProduct> filteredProducts = allProducts.where((p) {
            final bool brandMatch =
                _selectedBrandId == 0 || p.brandId == _selectedBrandId;
            final bool catMatch =
                _selectedCategoryId == 0 || p.categoryId == _selectedCategoryId;
            return brandMatch && catMatch;
          }).toList();

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: StorefrontAppBar(
              title: companyName.isNotEmpty ? companyName : 'Company Factory',
              subtitle: 'All Brands, Categories & Products • Single Factory Order',
              onBack: () {
                _brandProvider.clearSearch();
                Navigator.pop(context);
              },
            ),
            body: provider.loadingBrandScreen
                ? const CircularProgressIndicatorWidget()
                : Stack(
                    children: [
                      RefreshIndicator(
                        color: AppColors.primaryColor,
                        onRefresh: _loadData,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(bottom: 120),
                          children: [
                            StorefrontSearchBar(
                              controller: provider.searchController,
                              hintText: 'Search in factories, brands or SKUs...',
                              onChanged: (value) =>
                                  provider.onSearchChanged(value, height, context),
                              onClear: provider.clearSearch,
                            ),
                            if (provider.searchModel != null)
                              StorefrontSearchResults(
                                searchModel: provider.searchModel!,
                                height: height,
                              )
                            else ...[
                              _buildStoreHeroCard(
                                companyName: companyName,
                                bannerImage: bannerImage,
                                company: data?.company,
                                brandCount: brands.length,
                                categoryCount: categories.length,
                                productCount: allProducts.length,
                              ),
                              if (spotlightProduct != null)
                                _buildSpotlightProductCard(
                                    context, spotlightProduct),
                              _buildBrandsStrip(context, companyName, brands, allProducts),
                              if (visibleCategories.isNotEmpty)
                                _buildCategoriesStrip(visibleCategories),
                              _buildCompanyProductsSection(
                                context: context,
                                companyName: companyName,
                                products: filteredProducts,
                                totalCount: allProducts.length,
                              ),
                              _buildBrowseAllBanner(context, brands),
                            ],
                          ],
                        ),
                      ),
                      if (provider.searchModel == null)
                        GlobalCartContainer(width: width, height: height),
                    ],
                  ),
          );
        },
      ),
    );
  }

  HomeProduct? _resolveSpotlightProduct({
    required List<HomeProduct> allProducts,
  }) {
    if (widget.highlightProduct != null) {
      final int targetId = widget.highlightProduct!.id ?? 0;
      for (final p in allProducts) {
        if (p.id == targetId) return p;
      }
      return widget.highlightProduct;
    }
    if (widget.highlightProductId != null && widget.highlightProductId! > 0) {
      for (final p in allProducts) {
        if (p.id == widget.highlightProductId) return p;
      }
    }
    return null;
  }

  Widget _buildStoreHeroCard({
    required String companyName,
    required String bannerImage,
    required BrandCompanyInfo? company,
    required int brandCount,
    required int categoryCount,
    required int productCount,
  }) {
    final String displayCompany =
        companyName.isNotEmpty ? companyName : 'Verified Manufacturer';
    final String cityLine = [
      if ((company?.city ?? '').trim().isNotEmpty) company!.city!.trim(),
      if ((company?.state ?? '').trim().isNotEmpty) company!.state!.trim(),
    ].join(', ');
    final num mov = company?.minordervalue ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      height: 162,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF374151)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bannerImage.isNotEmpty)
              AppNetworkImage(
                imageUrl:
                    '${AppAssetImage.imageBaseUrl}storage/app/public/$bannerImage',
                fit: BoxFit.cover,
                fallbackIcon: Icons.factory_outlined,
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black
                        .withOpacity(bannerImage.isNotEmpty ? 0.82 : 0.35),
                    Colors.black
                        .withOpacity(bannerImage.isNotEmpty ? 0.45 : 0.15),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'FACTORY DIRECT',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mov > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(
                            'MOV: ₹${mov.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayCompany,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (cityLine.isNotEmpty)
                        Text(
                          cityLine,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.88),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '$brandCount Brands • $categoryCount Categories • $productCount Products',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFDE68A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightProductCard(BuildContext context, HomeProduct product) {
    final String img = (product.image ?? '').trim();
    final num price = product.price ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded,
                  size: 15, color: Color(0xFFEA580C)),
              const SizedBox(width: 4),
              Text(
                'SELECTED PRODUCT FROM THIS FACTORY',
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFC2410C),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 66,
                  height: 66,
                  color: const Color(0xFFF9FAFB),
                  child: AppNetworkImage(
                    imageUrl: img.isNotEmpty && img != 'default.png'
                        ? '${AppAssetImage.imageBaseUrl}storage/app/public/$img'
                        : null,
                    width: 66,
                    height: 66,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.format_paint_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Factory Product',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        if ((product.brandName ?? '').isNotEmpty)
                          product.brandName!,
                        if ((product.packSize ?? '').isNotEmpty)
                          product.packSize!,
                      ].join(' • '),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      price > 0
                          ? '₹${price.toStringAsFixed(0)}'
                          : 'View Wholesale Price',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildMenuAddButton(context, product),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DescriptionPageScreen(
                            productId: product.id ?? 0,
                            colorId: product.colorId ?? '0',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Full Specs >',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsStrip(
      BuildContext context, String companyName, List<Brand> brands, List<HomeProduct> allProducts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionHeading(
              title: companyName.isNotEmpty
                  ? 'Brands by $companyName'
                  : 'Company Brands',
              badge: '${brands.length} ${brands.length == 1 ? 'Brand' : 'Brands'}',
            ),
          ),
          const SizedBox(height: 10),
          if (brands.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No separate brand filter listed for this company.',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
            )
          else
            SizedBox(
              height: 108,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: brands.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final bool isAll = _selectedBrandId == 0;
                    return _buildBrandFilterTile(
                      label: 'All Brands',
                      image: null,
                      isAll: true,
                      isSelected: isAll,
                      onTap: () => setState(() => _selectedBrandId = 0),
                    );
                  }
                  final Brand b = brands[index - 1];
                  final int bId = b.id ?? 0;
                  final bool isSelected = _selectedBrandId == bId;
                  return _buildBrandFilterTile(
                    label: b.name ?? 'Brand',
                    image: b.image,
                    isAll: false,
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _selectedBrandId = isSelected ? 0 : bId;
                      if (_selectedBrandId != 0) {
                        final brandCatIds = allProducts
                            .where((p) => p.brandId == _selectedBrandId && (p.categoryId ?? 0) > 0)
                            .map((p) => p.categoryId!)
                            .toSet();
                        if (!brandCatIds.contains(_selectedCategoryId)) {
                          _selectedCategoryId = 0;
                        }
                      }
                    }),
                    onOpenCatalog: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductCategoryPageScreen(
                            bid: bId,
                            cid: b.categoryId ?? widget.cid,
                            scid: widget.scid,
                            cmpid: widget.cmpid,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrandFilterTile({
    required String label,
    required String? image,
    required bool isAll,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onOpenCatalog,
  }) {
    final String img = (image ?? '').trim();
    return InkWell(
      onTap: onTap,
      onLongPress: onOpenCatalog,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 86,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFEA580C) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFFF9FAFB),
                child: isAll
                    ? const Icon(Icons.layers_rounded,
                        color: Color(0xFFEA580C), size: 24)
                    : AppNetworkImage(
                        imageUrl: img.isNotEmpty && img != 'default.png'
                            ? '${AppAssetImage.imageBaseUrl}storage/app/public/$img'
                            : null,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        fallbackIcon: Icons.loyalty_outlined,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFEA580C)
                    : AppColors.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesStrip(List<BrandCategory> categories) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSectionHeading(
              title: 'Company Categories',
              badge: '${categories.length} Categories',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return SwiggyCategoryPlatterChip(
                    label: 'All',
                    isAll: true,
                    isSelected: _selectedCategoryId == 0,
                    onTap: () => setState(() => _selectedCategoryId = 0),
                  );
                }
                final cat = categories[index - 1];
                final int catId = cat.id ?? 0;
                return SwiggyCategoryPlatterChip(
                  label: cat.name ?? 'Category',
                  imagePath: cat.image,
                  isSelected: _selectedCategoryId == catId,
                  onTap: () => setState(() {
                    _selectedCategoryId =
                        (_selectedCategoryId == catId) ? 0 : catId;
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyProductsSection({
    required BuildContext context,
    required String companyName,
    required List<HomeProduct> products,
    required int totalCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            title: 'Products Menu ($totalCount)',
            badge: _selectedBrandId > 0 || _selectedCategoryId > 0
                ? 'Filtered: ${products.length}'
                : 'All Factory SKUs',
          ),
          if (_selectedBrandId > 0 || _selectedCategoryId > 0) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() {
                _selectedBrandId = 0;
                _selectedCategoryId = 0;
              }),
              child: Text(
                'Clear active filters • Show all $totalCount products',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (products.isEmpty)
            const StorefrontEmptyView(
              icon: Icons.inventory_2_outlined,
              title: 'No products match this filter',
              subtitle: 'Tap "All Brands" or "All" category above to view all company products.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildCompanyProductMenuCard(context, products[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyProductMenuCard(
      BuildContext context, HomeProduct product) {
    final num price = product.price ?? 0;
    final num oldPrice = product.oldprice ?? 0;
    final bool hasDiscount = oldPrice > price && price > 0;
    final int discountPct =
        hasDiscount ? (((oldPrice - price) / oldPrice) * 100).round() : 0;
    final String img = (product.image ?? '').trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DescriptionPageScreen(
                productId: product.id ?? 0,
                colorId: product.colorId ?? '0',
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left menu metadata (Swiggy Store Menu Style)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if ((product.brandName ?? '').trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              product.brandName!.trim().toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEA580C),
                              ),
                            ),
                          ),
                        if (hasDiscount && discountPct > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '$discountPct% OFF',
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name ?? 'Product',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if ((product.categoryName ?? '').trim().isNotEmpty)
                          product.categoryName!.trim(),
                        if ((product.packSize ?? '').trim().isNotEmpty)
                          product.packSize!.trim(),
                      ].join(' • '),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          price > 0
                              ? '₹${price.toStringAsFixed(0)}'
                              : 'View Rate',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${oldPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right image + wishlist + ADD button (Swiggy menu layout)
              SizedBox(
                width: 100,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 100,
                            height: 92,
                            color: const Color(0xFFF9FAFB),
                            child: AppNetworkImage(
                              imageUrl: img.isNotEmpty && img != 'default.png'
                                  ? '${AppAssetImage.imageBaseUrl}storage/app/public/$img'
                                  : null,
                              width: 100,
                              height: 92,
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.format_paint_outlined,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Consumer<WishlistProvider>(
                            builder: (context, wishProv, _) {
                              final bool isWishlisted =
                                  wishProv.isWishlisted(product.id);
                              return InkWell(
                                onTap: () => toggleProductWishlist(
                                  context,
                                  productId: product.id ?? 0,
                                  colorId: product.colorId ?? '0',
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isWishlisted
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 14,
                                    color: isWishlisted
                                        ? const Color(0xFFEF4444)
                                        : Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildMenuAddButton(context, product),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuAddButton(BuildContext context, HomeProduct product) {
    final int pId = product.id ?? 0;
    final String itemKey = '${pId}_${product.attributeId ?? 0}';
    final bool isAdded = _addedItemKeys.contains(itemKey);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        if (isAdded || pId <= 0) return;
        HapticFeedback.mediumImpact();
        setState(() => _addedItemKeys.add(itemKey));
        final cartProv =
            Provider.of<CartScreenProvider>(context, listen: false);
        final bool added = await cartProv.quickAddToCart(
          context: context,
          productId: pId.toString(),
          brandId: (product.brandId ?? 0).toString(),
          attributeId: product.attributeId?.toString(),
        );
        if (!mounted) return;
        if (added) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF16A34A),
              duration: const Duration(milliseconds: 1400),
              margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              content: Text(
                '${product.name ?? 'Item'} added to cart',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          );
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) setState(() => _addedItemKeys.remove(itemKey));
          });
        } else {
          setState(() => _addedItemKeys.remove(itemKey));
        }
      },
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isAdded ? const Color(0xFF16A34A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF16A34A), width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAdded) ...[
              const Icon(Icons.check_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 3),
              Text(
                'ADDED',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ] else ...[
              Text(
                'ADD',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.add_rounded, size: 14, color: Color(0xFF16A34A)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseAllBanner(BuildContext context, List<Brand> brands) {
    final int fallbackCid = widget.cid > 0
        ? widget.cid
        : (brands.isNotEmpty ? (brands.first.categoryId ?? 0) : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductCategoryPageScreen(
                bid: _selectedBrandId,
                cid: _selectedCategoryId > 0 ? _selectedCategoryId : fallbackCid,
                scid: widget.scid,
                cmpid: widget.cmpid,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFFEA580C),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open Detailed Matrix Catalog',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    Text(
                      'Browse by brand tabs & full color shade variants',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFEA580C),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String badge,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFEA580C),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Text(
            badge,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D4ED8),
            ),
          ),
        ),
      ],
    );
  }
}
