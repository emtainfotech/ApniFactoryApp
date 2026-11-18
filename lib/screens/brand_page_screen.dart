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
import 'package:apni_factory/res/widgets/product_cart_stepper_button.dart';
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
  int _selectedViewTab = 0; // 0 = Factory Catalogue, 1 = Details Matrix
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
                              _buildViewSwitcher(),
                              if (_selectedViewTab == 0)
                                _buildFactoryCatalogueMatrixSection(
                                  context: context,
                                  companyName: companyName,
                                  products: filteredProducts,
                                  totalCount: allProducts.length,
                                  brandId: _selectedBrandId,
                                  categoryId: _selectedCategoryId,
                                )
                              else
                                _buildDetailedMatrixViewSection(
                                  context: context,
                                  companyName: companyName,
                                  products: filteredProducts,
                                  totalCount: allProducts.length,
                                  brandId: _selectedBrandId,
                                  categoryId: _selectedCategoryId,
                                  brands: brands,
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
                imageUrl: AppAssetImage.buildStorageImageUrl(bannerImage),
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
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFDE68A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    imageUrl: AppAssetImage.buildStorageImageUrl(img),
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
                          ? '₹${price.toStringAsFixed(2)}'
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
                  ProductCartStepperButton(
                    productId: product.id ?? 0,
                    brandId: (product.brandId ?? widget.cid).toString(),
                    attributeId: product.attributeId?.toString(),
                    isCompact: true,
                  ),
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
                        imageUrl: AppAssetImage.buildStorageImageUrl(img),
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

  Widget _buildViewSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedViewTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedViewTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _selectedViewTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 15,
                      color: _selectedViewTab == 0
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Factory Catalogue',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: _selectedViewTab == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _selectedViewTab == 0
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedViewTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedViewTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _selectedViewTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_agenda_rounded,
                      size: 15,
                      color: _selectedViewTab == 1
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Details Matrix',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: _selectedViewTab == 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _selectedViewTab == 1
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactoryCatalogueMatrixSection({
    required BuildContext context,
    required String companyName,
    required List<HomeProduct> products,
    required int totalCount,
    required int brandId,
    required int categoryId,
  }) {
    final String activeLabel = brandId > 0
        ? 'Filtered by Selected Brand'
        : (categoryId > 0 ? 'Filtered by Selected Category' : 'All Factory SKUs');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catalogue Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Factory Catalogue & Rate Matrix',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LIVE RATES',
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$activeLabel • ${products.length} SKUs',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (brandId > 0 || categoryId > 0)
                TextButton(
                  onPressed: () => setState(() {
                    _selectedBrandId = 0;
                    _selectedCategoryId = 0;
                  }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Reset',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (products.isEmpty)
            const StorefrontEmptyView(
              icon: Icons.inventory_2_outlined,
              title: 'No catalogue SKUs match this filter',
              subtitle: 'Tap "All Brands" or "All" category above to view all catalogue items.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.54,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) =>
                  _buildCatalogueCard(context, products[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildCatalogueCard(BuildContext context, HomeProduct product) {
    final num price = product.price ?? 0;
    final num oldPrice = product.oldprice ?? 0;
    final bool hasDiscount = oldPrice > price && price > 0;
    final String img = (product.image ?? '').trim();
    final int pId = product.id ?? 0;
    final String colorId = product.colorId ?? '0';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DescriptionPageScreen(
              productId: pId,
              colorId: colorId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEFEFEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image Area with Swatch & Wishlist
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Container(
                      color: const Color(0xFFFAFAFA),
                      child: (img.isNotEmpty && img != 'default.png')
                          ? AppNetworkImage(
                              imageUrl: AppAssetImage.buildStorageImageUrl(img),
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.format_paint_outlined,
                            )
                          : const Center(
                              child: Icon(
                                Icons.format_paint_outlined,
                                size: 28,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                    ),
                  ),
                  // Shade Swatch Dot Top Left (if hex exists)
                  if ((product.colorHex ?? '').trim().isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hexToColor(product.colorHex!),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Wishlist Heart Button Top Right
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishProv, _) {
                        final bool isWishlisted = wishProv.isWishlisted(product.id);
                        return InkWell(
                          onTap: () => toggleProductWishlist(
                            context,
                            productId: pId,
                            colorId: colorId,
                          ),
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.90),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 14,
                              color: isWishlisted ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Product Details Area - completely flex-safe without rigid Spacer
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((product.brandName ?? '').trim().isNotEmpty)
                          Text(
                            product.brandName!.trim().toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEA580C),
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          product.name ?? 'Catalogue Product',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((product.packSize ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Text(
                              product.packSize!.trim(),
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasDiscount)
                                Text(
                                  '₹${oldPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 8.5,
                                    decoration: TextDecoration.lineThrough,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                price > 0 ? '₹${price.toStringAsFixed(2)}' : 'Rates',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        ProductCartStepperButton(
                          productId: pId,
                          brandId: (product.brandId ?? widget.cid).toString(),
                          attributeId: product.attributeId?.toString(),
                          isCompact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.transparent;
    }
  }

  Widget _buildDetailedMatrixViewSection({
    required BuildContext context,
    required String companyName,
    required List<HomeProduct> products,
    required int totalCount,
    required int brandId,
    required int categoryId,
    required List<Brand> brands,
  }) {
    final String activeLabel = brandId > 0
        ? 'Filtered by Selected Brand'
        : (categoryId > 0 ? 'Filtered by Selected Category' : 'All Factory SKUs');
    final int fallbackCid = widget.cid > 0
        ? widget.cid
        : (brands.isNotEmpty ? (brands.first.categoryId ?? 0) : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Matrix Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Details Matrix & Specifications',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'MATRIX',
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$activeLabel • ${products.length} Products Available',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
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
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Full Screen',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: Color(0xFFEA580C),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (products.isEmpty)
            const StorefrontEmptyView(
              icon: Icons.inventory_2_outlined,
              title: 'No matrix products match this filter',
              subtitle: 'Tap "All Brands" or "All" category above to view all matrix items.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildDetailedMatrixCard(context, products[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedMatrixCard(BuildContext context, HomeProduct product) {
    final num price = product.price ?? 0;
    final num oldPrice = product.oldprice ?? 0;
    final bool hasDiscount = oldPrice > price && price > 0;
    final String img = (product.image ?? '').trim();
    final int pId = product.id ?? 0;
    final String colorId = product.colorId ?? '0';
    final Color swatchColor = _hexToColor(product.colorHex ?? '');
    final bool hasHex = (product.colorHex ?? '').trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DescriptionPageScreen(
                          productId: pId,
                          colorId: colorId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          (img.isNotEmpty && img != 'default.png')
                              ? AppNetworkImage(
                                  imageUrl: AppAssetImage.buildStorageImageUrl(img),
                                  fit: BoxFit.cover,
                                  fallbackIcon: Icons.format_paint_outlined,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.format_paint_outlined,
                                    size: 26,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                          if (hasHex)
                            Positioned(
                              top: 5,
                              left: 5,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: swatchColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Product Information & Specifications
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if ((product.brandName ?? '').trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(4),
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
                          if ((product.categoryName ?? '').trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.categoryName!.trim(),
                                style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DescriptionPageScreen(
                                productId: pId,
                                colorId: colorId,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          product.name ?? 'Catalogue Product',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Pack size and shade badge
                      Row(
                        children: [
                          if ((product.packSize ?? '').trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                'Size: ${product.packSize!.trim()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          if (hasHex) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: swatchColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.colorHex!.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          // Pricing & Stepper Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          price > 0 ? '₹${price.toStringAsFixed(2)}' : 'Rate on req.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${oldPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Least Price Variant',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DescriptionPageScreen(
                              productId: pId,
                              colorId: colorId,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Details & Shades >',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ProductCartStepperButton(
                      productId: pId,
                      brandId: (product.brandId ?? widget.cid).toString(),
                      attributeId: product.attributeId?.toString(),
                      isCompact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
