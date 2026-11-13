import 'package:apni_factory/model/company_screen_model.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/company_screen_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/widgets/app_network_image.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:apni_factory/res/widgets/global_cart_container.dart';
import 'package:apni_factory/res/widgets/storefront_widgets.dart';
import 'package:apni_factory/screens/brand_page_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CompanyPageScreen extends StatefulWidget {
  final int cid;
  final int scid;

  const CompanyPageScreen({
    super.key,
    required this.cid,
    this.scid = 0,
  });

  @override
  State<CompanyPageScreen> createState() => _CompanyPageScreenState();
}

class _CompanyPageScreenState extends State<CompanyPageScreen> {
  late CompanyScreenProvider _companyProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await Provider.of<CompanyScreenProvider>(context, listen: false)
        .companyScreen(context: context, cid: widget.cid, scid: widget.scid);
    if (!mounted) return;
    await Provider.of<CartScreenProvider>(context, listen: false)
        .userCart(context: context, isSilent: true);
  }

  @override
  void didChangeDependencies() {
    _companyProvider =
        Provider.of<CompanyScreenProvider>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _companyProvider.clearSearch();
      },
      child: Consumer<CompanyScreenProvider>(
        builder: (context, provider, _) {
          final String categoryName =
              provider.companyScreenModel?.data?.categoryname?.trim() ?? '';
          final String appBarTitle =
              categoryName.isNotEmpty ? categoryName : 'Choose a Factory';

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: StorefrontAppBar(
              title: appBarTitle,
              subtitle: 'Single-Company Factory • Pick a Factory',
              onBack: () {
                _companyProvider.clearSearch();
                Navigator.pop(context);
              },
            ),
            body: provider.loadingCompanyScreen
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
                              controller: provider.companySearchController,
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
                              _buildBannerCarousel(provider, width),
                              _buildCompanySection(provider, appBarTitle),
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

  Widget _buildBannerCarousel(CompanyScreenProvider provider, double width) {
    final List<String> banners = [
      ...(provider.slider ?? []).map((e) => e?.toString() ?? ''),
      ...(provider.advertisementImage ?? []).map((e) => e?.toString() ?? ''),
    ].where((s) => s.trim().isNotEmpty).toList();

    if (banners.isEmpty) {
      return const SizedBox(height: 6);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        children: [
          CarouselSlider(
            carouselController: provider.carousalController,
            items: banners.map((item) {
              return Container(
                width: width,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AppNetworkImage(
                    imageUrl: '${AppAssetImage.imageBaseUrl}storage/app/public/$item',
                    width: width,
                    height: 156,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.factory_outlined,
                  ),
                ),
              );
            }).toList(),
            options: CarouselOptions(
              height: 156,
              viewportFraction: 1,
              autoPlay: banners.length > 1,
              autoPlayInterval: const Duration(seconds: 4),
              onPageChanged: (index, _) {
                setState(() => provider.current = index);
              },
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (idx) {
                final bool active = provider.current == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: active ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: active
                        ? const Color(0xFFEA580C)
                        : const Color(0xFFD1D5DB),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanySection(
      CompanyScreenProvider provider, String categoryTitle) {
    final List<Company> companies =
        provider.companyScreenModel?.data?.company ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
                  'Manufacturers in $categoryTitle',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  '${companies.length} ${companies.length == 1 ? 'Factory' : 'Factories'}',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Orders are fulfilled directly by one company at a time.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          if (companies.isEmpty)
            StorefrontEmptyView(
              icon: Icons.factory_outlined,
              title: 'No Factories Listed Yet',
              subtitle:
                  'There are currently no active manufacturers in $categoryTitle.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: companies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildCompanyCard(context, companies[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(BuildContext context, Company company) {
    final String location = [company.city, company.state]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
    final int mov = company.minordervalue ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BrandPageScreen(
              cmpid: company.id ?? 0,
              cid: widget.cid,
              scid: widget.scid,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFECEEF1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: (company.photo != null && company.photo!.trim().isNotEmpty)
                    ? AppNetworkImage(
                        imageUrl:
                            '${AppAssetImage.imageBaseUrl}storage/app/public/${company.photo}',
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.factory_outlined,
                      )
                    : const Icon(
                        Icons.factory_outlined,
                        color: Color(0xFFEA580C),
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'VERIFIED FACTORY',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: Color(0xFF16A34A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    company.name ?? 'Company Factory',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (mov > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Min Order Rs. $mov',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Shop',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFFEA580C),
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
