import 'package:apni_factory/model/brand_screen_model.dart';
import 'package:apni_factory/provider/brand_screen_provider.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/widgets/app_network_image.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:apni_factory/res/widgets/global_cart_container.dart';
import 'package:apni_factory/res/widgets/storefront_widgets.dart';
import 'package:apni_factory/screens/product_category_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BrandPageScreen extends StatefulWidget {
  final int cmpid;
  final int cid;
  final int scid;

  const BrandPageScreen({
    super.key,
    required this.cmpid,
    required this.cid,
    this.scid = 0,
  });

  @override
  State<BrandPageScreen> createState() => _BrandPageScreenState();
}

class _BrandPageScreenState extends State<BrandPageScreen> {
  late BrandScreenProvider _brandProvider;

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
          final String companyName =
              provider.brandScreenModel?.data?.companyname?.trim() ?? '';
          final String bannerImage =
              provider.brandScreenModel?.data?.bannerimage?.trim() ?? '';
          final List<Brand> brands =
              provider.brandScreenModel?.data?.brand ?? [];

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: StorefrontAppBar(
              title: companyName.isNotEmpty ? companyName : 'Company Store',
              subtitle: '100% Single-Company Storefront',
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
                          padding: const EdgeInsets.only(bottom: 110),
                          children: [
                            StorefrontSearchBar(
                              controller: provider.searchController,
                              hintText: 'Search factories, brands or products...',
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
                                  companyName, bannerImage, brands.length),
                              _buildBrowseAllBanner(context, brands),
                              _buildBrandsGrid(context, companyName, brands),
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

  Widget _buildStoreHeroCard(
      String companyName, String bannerImage, int brandCount) {
    final String displayCompany =
        companyName.isNotEmpty ? companyName : 'Verified Manufacturer';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      height: 152,
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
                    Colors.black.withOpacity(bannerImage.isNotEmpty ? 0.78 : 0.35),
                    Colors.black.withOpacity(bannerImage.isNotEmpty ? 0.40 : 0.15),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          'FACTORY DIRECT STORE',
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
                      const SizedBox(height: 2),
                      Text(
                        '$brandCount ${brandCount == 1 ? 'Brand' : 'Brands'} • Exclusively from this company',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
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

  Widget _buildBrowseAllBanner(BuildContext context, List<Brand> brands) {
    final int fallbackCid = widget.cid > 0
        ? widget.cid
        : (brands.isNotEmpty ? (brands.first.categoryId ?? 0) : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductCategoryPageScreen(
                bid: 0,
                cid: fallbackCid,
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
                      'Browse Complete Store Catalog',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    Text(
                      'View all categories & SKUs from this factory',
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

  Widget _buildBrandsGrid(
      BuildContext context, String companyName, List<Brand> brands) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  companyName.isNotEmpty
                      ? 'Brands by $companyName'
                      : 'Company Brands',
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
                  '${brands.length} ${brands.length == 1 ? 'Brand' : 'Brands'}',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (brands.isEmpty)
            const StorefrontEmptyView(
              icon: Icons.loyalty_outlined,
              title: 'No Brands Listed',
              subtitle:
                  'Tap "Browse Complete Store Catalog" above to see available items.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: brands.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.84,
              ),
              itemBuilder: (context, index) => _buildBrandCard(context, brands[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildBrandCard(BuildContext context, Brand brand) {
    final String statusLabel = brand.type == 'Processing'
        ? 'Processing'
        : (brand.type == 'Unregistred' ? 'Direct' : 'Registered');
    final Color badgeBg = brand.type == 'Processing'
        ? const Color(0xFFFEF3C7)
        : (brand.type == 'Unregistred'
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFDCFCE7));
    final Color badgeText = brand.type == 'Processing'
        ? const Color(0xFF92400E)
        : (brand.type == 'Unregistred'
            ? const Color(0xFF1D4ED8)
            : const Color(0xFF166534));

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductCategoryPageScreen(
              bid: brand.id ?? 0,
              cid: brand.categoryId ?? widget.cid,
              scid: widget.scid,
              cmpid: widget.cmpid,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEEF1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: Container(
                        color: const Color(0xFFFAFAFA),
                        padding: const EdgeInsets.all(10),
                        child: AppNetworkImage(
                          imageUrl:
                              '${AppAssetImage.imageBaseUrl}storage/app/public/${brand.image ?? ''}',
                          fit: BoxFit.contain,
                          fallbackIcon: Icons.local_offer_outlined,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'View Products',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: Color(0xFFEA580C),
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
}
