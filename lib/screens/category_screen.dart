import 'package:apni_factory/model/category_screen_model.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/category_screen_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/widgets/app_network_image.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:apni_factory/res/widgets/global_cart_container.dart';
import 'package:apni_factory/screens/brand_page_screen.dart';
import 'package:apni_factory/screens/company_page_screen.dart';
import 'package:apni_factory/screens/description_page_screen.dart';
import 'package:apni_factory/utils.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CategoryScreen extends StatefulWidget {
  final int mid;

  const CategoryScreen({
    super.key,
    required this.mid,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen>
    with SingleTickerProviderStateMixin {
  late CategoryScreenProvider _categoryProvider;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryScreenProvider>(context, listen: false).categoryScreen(
        context: context,
        mid: widget.mid,
      );
      Provider.of<CartScreenProvider>(context, listen: false).userCart(
        context: context,
      );
    });
  }

  @override
  void didChangeDependencies() {
    _categoryProvider = Provider.of<CategoryScreenProvider>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        _categoryProvider.clearSearch();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xffF1F3F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.secondaryColor,
                size: 20,
              ),
            ),
            onPressed: () {
              _categoryProvider.clearSearch();
              Navigator.pop(context);
            },
          ),
          title: Text(
            "Explore Categories",
            style: GoogleFonts.poppins(
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        body: Consumer<CategoryScreenProvider>(
          builder: (context, provider, child) {
            if (provider.loadingCategoryScreen) {
              return const CircularProgressIndicatorWidget();
            }

            final data = provider.categoryScreenModel?.data;
            final categories = data?.category ?? [];
            final companies = data?.company ?? [];
            final banners = (provider.slider != null && provider.slider!.isNotEmpty)
                ? provider.slider!
                : (provider.advertisement ?? []);

            final bool isSearching = (provider.searchModel != null);

            return Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 120),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // 1. Search Bar
                        _buildSearchBar(context, provider),

                        if (isSearching)
                          // Search Results List
                          _buildSearchResults(context, provider, height, width)
                        else ...[
                          // 2. Promotional Banners Slider
                          if (banners.isNotEmpty)
                            _buildHeroBanner(context, provider, banners),

                          // 3. Subcategories Grid Section ("We Deal Into" sub-items)
                          _buildCategoriesSection(context, categories, height, width),

                          // 3b. Popular Subcategories Strip
                          if (data?.subcategory != null && data!.subcategory!.isNotEmpty)
                            _buildSubcategoriesSection(context, data.subcategory!, width),

                          // 4. Verified Companies / Manufacturers Section
                          _buildCompaniesSection(context, companies, height, width),
                        ],
                      ],
                    ),
                  ),
                ),

                // Floating Cart Container
                if (!isSearching)
                  GlobalCartContainer(width: width, height: height),
              ],
            );
          },
        ),
      ),
    );
  }

  // 1. Modern Blinkit Search Bar
  Widget _buildSearchBar(BuildContext context, CategoryScreenProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xffF5F6F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffE5E7EB)),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
            Expanded(
              child: TextField(
                controller: provider.categorySearchController,
                onChanged: (val) => provider.onSearchChanged(
                  val,
                  MediaQuery.of(context).size.height,
                  context,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryColor,
                ),
                decoration: InputDecoration(
                  hintText: "Search categories, factories or products...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightText,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (provider.categorySearchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.lightText),
                onPressed: () {
                  provider.categorySearchController.clear();
                  provider.clearSearch();
                },
              ),
          ],
        ),
      ),
    );
  }

  // 2. Hero Promotional Banner
  Widget _buildHeroBanner(
    BuildContext context,
    CategoryScreenProvider provider,
    List banners,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          CarouselSlider(
            items: banners.map((item) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.network(
                    "${AppAssetImage.imageBaseUrl}storage/app/public/$item",
                    fit: BoxFit.cover,
                    width: double.infinity,
                    cacheWidth: 650,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xffEEEEEE),
                      child: const Center(
                        child: Icon(Icons.image_outlined, color: AppColors.greyColor, size: 36),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            carouselController: provider.carousalController,
            options: CarouselOptions(
              height: 135,
              viewportFraction: 0.92,
              enlargeCenterPage: true,
              enlargeFactor: 0.12,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              onPageChanged: (index, reason) {
                setState(() {
                  provider.current = index;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: banners.asMap().entries.map((entry) {
              final bool isActive = (provider.current == entry.key);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 18 : 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive ? AppColors.primaryColor : const Color(0xffD1D5DB),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 3. Sub-Categories Section (Visual Card Grid)
  Widget _buildCategoriesSection(
    BuildContext context,
    List categories,
    double height,
    double width,
  ) {
    if (categories.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            "No categories available under this section",
            style: GoogleFonts.poppins(color: AppColors.lightText),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffECEEF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 15,
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Browse Formulations & Types",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  "${categories.length} Types",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2-Column Category Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompanyPageScreen(cid: cat.cid ?? 0),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffECEEF1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Area
                      Expanded(
                        flex: 7,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(8),
                            child: cat.image != null && cat.image!.isNotEmpty
                                ? Image.network(
                                    "${AppAssetImage.imageBaseUrl}storage/app/public/${cat.image}",
                                    fit: BoxFit.contain,
                                    cacheWidth: 350,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      AppAssetImage.logo,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Image.asset(
                                    AppAssetImage.logo,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),
                      ),
                      // Title & Action
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cat.name ?? "",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondaryColor,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    "Explore Catalog",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 10,
                                    color: AppColors.primaryColor,
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoriesSection(
      BuildContext context, List<CategoryScreenSubcategory> subcategories, double width) {
    if (subcategories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 15,
                width: 3.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Popular Sub-Categories",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                final sub = subcategories[index];
                final String img = (sub.image ?? '').trim();
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyPageScreen(
                          cid: sub.cid ?? 0,
                          scid: sub.scid ?? 0,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 105,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(
                            imageUrl: (img.isNotEmpty && img != 'default.png')
                                ? '${AppAssetImage.imageBaseUrl}storage/app/public/$img'
                                : null,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.category_rounded,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sub.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 4. Verified Companies / Manufacturers Section
  Widget _buildCompaniesSection(
    BuildContext context,
    List companies,
    double height,
    double width,
  ) {
    if (companies.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffECEEF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 15,
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Verified Factory Partners",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  "${companies.length} Partners",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: companies.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final company = companies[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BrandPageScreen(
                        cmpid: company.cmpid ?? 0,
                        cid: 0,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffE5E7EB)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: company.image != null && company.image!.isNotEmpty
                              ? Image.network(
                                  "${AppAssetImage.imageBaseUrl}storage/app/public/${company.image}",
                                  fit: BoxFit.contain,
                                  cacheWidth: 150,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.factory_outlined,
                                    color: AppColors.primaryColor,
                                    size: 26,
                                  ),
                                )
                              : const Icon(
                                  Icons.factory_outlined,
                                  color: AppColors.primaryColor,
                                  size: 26,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "DIRECT FACTORY",
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF16A34A),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF16A34A)),
                              ],
                            ),
                            Text(
                              company.name ?? "",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (company.city != null && company.city!.isNotEmpty)
                              Text(
                                "Site: ${company.city} • ${company.count ?? 0} Categories",
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.lightText,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          "View >",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. Search Results View
  Widget _buildSearchResults(
    BuildContext context,
    CategoryScreenProvider provider,
    double height,
    double width,
  ) {
    if (provider.loadingSearch) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicatorWidget()),
      );
    }

    final results = provider.searchModel?.data ?? [];
    if (results.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: AppColors.greyColor),
              const SizedBox(height: 10),
              Text(
                "No matching results found",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryColor,
                ),
              ),
              Text(
                "Try searching for paints, primers, or factory brands",
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.lightText),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = results[index];
        return InkWell(
          onTap: () {
            if (item.screen == "category") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(mid: item.relatedid ?? 0),
                ),
              );
            } else if (item.screen == "company") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompanyPageScreen(cid: item.relatedid ?? 0),
                ),
              );
            } else if (item.screen == "product") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DescriptionPageScreen(
                    productId: item.id ?? 0,
                    colorId: item.relatedid?.toString() ?? "0",
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffE5E7EB)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 48,
                    width: 48,
                    color: const Color(0xffF3F4F6),
                    child: item.image != null && item.image!.isNotEmpty
                        ? Image.network(
                            "${AppAssetImage.imageBaseUrl}storage/app/public/${item.image}",
                            fit: BoxFit.cover,
                            cacheWidth: 150,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.category_outlined,
                              color: AppColors.primaryColor,
                            ),
                          )
                        : const Icon(
                            Icons.category_outlined,
                            color: AppColors.primaryColor,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? "",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                      Text(
                        item.screen?.toUpperCase() ?? "RESULT",
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.lightText,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
