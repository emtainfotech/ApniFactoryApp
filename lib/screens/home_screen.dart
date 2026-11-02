import 'dart:async';
import 'package:apni_factory/api_services/notification_services.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/homeScreen_provider.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/textstyle.dart';
import 'package:apni_factory/res/widgets/global_cart_container.dart';
import 'package:apni_factory/res/widgets/personal_add_address_widget.dart';
import 'package:apni_factory/screens/category_screen.dart';
import 'package:apni_factory/screens/company_page_screen.dart';
import 'package:apni_factory/screens/description_page_screen.dart';
import 'package:apni_factory/screens/notification_screen.dart';
import 'package:apni_factory/screens/brand_page_screen.dart';
import 'package:apni_factory/model/home_screen_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../res/asset_image.dart';
import '../utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  NotificationServices notificationServices = NotificationServices();
  late HomeScreenProvider _homeProvider;
  final ScrollController _scrollController = ScrollController();

  int _heroSliderIndex = 0;
  int _adSlider1Index = 0;
  int _adSlider2Index = 0;

  int _hintIndex = 0;
  Timer? _hintTimer;
  final List<String> _searchHints = [
    "Search 'Wall Primer'...",
    "Search 'PU Clear Coat'...",
    "Search 'Luxury Silk Emulsion'...",
    "Search 'Synthetic Enamel'...",
    "Search 'Floor Epoxy Coating'...",
    "Search 'Distemper & Base'...",
  ];

  @override
  void initState() {
    super.initState();

    _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _hintIndex = (_hintIndex + 1) % _searchHints.length;
        });
      }
    });

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final homeProv = Provider.of<HomeScreenProvider>(context, listen: false);
      final cartProv = Provider.of<CartScreenProvider>(context, listen: false);

      homeProv.homeScreen(context: context);
      homeProv.getAddressList(context: context);
      cartProv.userCart(context: context);
      homeProv.stateDropDown(context: context);
      homeProv.adminAppPages(context: context);
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll - currentScroll <= 350) {
        if (!_homeProvider.loadingMoreProducts && _homeProvider.hasMoreProducts) {
          _homeProvider.loadMoreProducts(context);
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeProvider = Provider.of<HomeScreenProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Consumer<HomeScreenProvider>(
      builder: (context, provider, child) {
        return WillPopScope(
          onWillPop: () async {
            provider.clearSearch();
            return true;
          },
          child: Scaffold(
            key: provider.key,
            backgroundColor: const Color(0xffF8F9FA),
            drawer: Utils.drawer(
              height: height,
              width: width,
              context: context,
              provider: provider,
            ),
            body: provider.loadingHomeScreen && provider.homeScreenModel == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  )
                : Stack(
                    children: [
                      RefreshIndicator(
                        color: AppColors.primaryColor,
                        onRefresh: () => provider.refreshHomeScreen(context),
                        child: ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          children: [
                            _buildTopHeader(context, provider, height, width),
                            _buildModernSearchBar(context, provider, height, width),
                            if (provider.searchModel != null)
                              _buildSearchResults(context, provider, height, width)
                            else ...[
                              _buildHeroBannerSlider(context, provider, height, width),
                              const SizedBox(height: 12),
                              if (provider.categoryCarousels.isNotEmpty)
                                _buildCategoryCarousel(
                                  context: context,
                                  carousel: provider.categoryCarousels[0],
                                  height: height,
                                  width: width,
                                  shelfIndex: 0,
                                ),
                              _buildAdSlider(
                                context: context,
                                items: provider.advertisement ?? [],
                                currentIndex: _adSlider1Index,
                                onPageChanged: (idx) => setState(() => _adSlider1Index = idx),
                                height: height,
                                width: width,
                                title: "Bulk Factory Deals",
                                backgroundGradient: const LinearGradient(
                                  colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5), Color(0xFFFEE2E2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderColor: const Color(0xFFFED7AA),
                                accentColor: const Color(0xFFEA580C),
                                badgeText: "FACTORY DIRECT • 20% OFF",
                              ),
                              if (provider.categoryCarousels.length > 1)
                                _buildCategoryCarousel(
                                  context: context,
                                  carousel: provider.categoryCarousels[1],
                                  height: height,
                                  width: width,
                                  shelfIndex: 1,
                                ),
                              _buildWeDealIntoSection(context, provider, height, width),
                              if (provider.categoryCarousels.length > 2)
                                _buildCategoryCarousel(
                                  context: context,
                                  carousel: provider.categoryCarousels[2],
                                  height: height,
                                  width: width,
                                  shelfIndex: 2,
                                ),
                              if ((provider.advertisement?.length ?? 0) > 1)
                                _buildAdSlider(
                                  context: context,
                                  items: (provider.advertisement ?? []).reversed.toList(),
                                  currentIndex: _adSlider2Index,
                                  onPageChanged: (idx) => setState(() => _adSlider2Index = idx),
                                  height: height,
                                  width: width,
                                  title: "Commercial Specials",
                                  backgroundGradient: const LinearGradient(
                                    colors: [Color(0xFFFEFCE8), Color(0xFFFEF9C3), Color(0xFFFEF08A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderColor: const Color(0xFFFDE047),
                                  accentColor: const Color(0xFFCA8A04),
                                  badgeText: "CONTRACTOR BULK DEALS",
                                ),
                              if (provider.categoryCarousels.length > 3)
                                _buildCategoryCarousel(
                                  context: context,
                                  carousel: provider.categoryCarousels[3],
                                  height: height,
                                  width: width,
                                  shelfIndex: 3,
                                ),
                              if (provider.categoryCarousels.length > 4)
                                _buildCategoryCarousel(
                                  context: context,
                                  carousel: provider.categoryCarousels[4],
                                  height: height,
                                  width: width,
                                  shelfIndex: 4,
                                ),
                              _buildPopularBrandsSection(context, provider, height, width),
                              _buildExploreAllProductsGrid(context, provider, height, width),
                              SizedBox(height: height / 8),
                            ],
                          ],
                        ),
                      ),
                      if (provider.searchModel == null)
                        GlobalCartContainer(width: width, height: height),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // 1. Top Location & Notification Header
  Widget _buildTopHeader(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 14,
        right: 14,
        bottom: 6,
      ),
      color: AppColors.whiteColor,
      child: Row(
        children: [
          InkWell(
            onTap: () => provider.key.currentState!.openDrawer(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xffF1F3F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: AppColors.secondaryColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _openAddressSelector(context, provider, height, width),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Delivering to Factory/Site",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primaryColor,
                        size: 18,
                      ),
                    ],
                  ),
                  Text(
                    provider.selectedAddressText ?? "Tap to select delivery location",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xffF1F3F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.secondaryColor,
                    size: 22,
                  ),
                  if ((provider.homeScreenModel?.data?.notification ?? 0) > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          "${provider.homeScreenModel?.data?.notification}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: AppColors.whiteColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Modern Blinkit-Style Floating Search Bar
  Widget _buildModernSearchBar(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    return Container(
      color: AppColors.whiteColor,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xffF5F6F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.primaryColor,
                size: 22,
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (provider.searchController.text.isEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _searchHints[_hintIndex],
                        key: ValueKey<String>(_searchHints[_hintIndex]),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.lightText,
                        ),
                      ),
                    ),
                  TextField(
                    controller: provider.searchController,
                    onChanged: (val) => provider.onSearchChanged(val, height, context),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryColor,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (provider.searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.lightText),
                onPressed: () {
                  provider.searchController.clear();
                  provider.clearSearch();
                },
              ),
          ],
        ),
      ),
    );
  }

  // 3. Blinkit / Swiggy Hero Banner Slider
  Widget _buildHeroBannerSlider(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    final banners = provider.slider ?? [];
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 12),
        CarouselSlider(
          items: banners.map((item) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blackColor.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                      child: Icon(Icons.image_outlined, size: 40, color: AppColors.greyColor),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 145,
            viewportFraction: 0.90,
            enlargeCenterPage: true,
            enlargeFactor: 0.16,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 700),
            onPageChanged: (index, reason) {
              setState(() {
                _heroSliderIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: banners.asMap().entries.map((entry) {
            final bool isActive = _heroSliderIndex == entry.key;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isActive ? 22 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive ? AppColors.primaryColor : const Color(0xffD1D5DB),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Shelf warm themes:
  // Each shelf gets a distinctive warm gradient background, warm border, and accent badge color
  static const List<Map<String, dynamic>> _warmShelfThemes = [
    // Shelf 0: Wall Primers & Undercoats -> Warm Saffron / Amber Cream
    {
      'gradient': LinearGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'borderColor': Color(0xFFFDE68A),
      'accentColor': Color(0xFFD97706),
      'badgeBg': Color(0xFFFEF3C7),
      'badgeText': Color(0xFFB45309),
    },
    // Shelf 1: Industrial & PU Protective Finishes -> Warm Coral / Terracotta Rose
    {
      'gradient': LinearGradient(
        colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'borderColor': Color(0xFFFECDD3),
      'accentColor': Color(0xFFE11D48),
      'badgeBg': Color(0xFFFFE4E6),
      'badgeText': Color(0xFFBE123C),
    },
    // Shelf 2: High Gloss & Silk Emulsions -> Warm Peach / Apricot Silk
    {
      'gradient': LinearGradient(
        colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'borderColor': Color(0xFFFED7AA),
      'accentColor': Color(0xFFEA580C),
      'badgeBg': Color(0xFFFFEDD5),
      'badgeText': Color(0xFFC2410C),
    },
    // Shelf 3: Enamel & Automotive Coatings -> Warm Sunset Caramel
    {
      'gradient': LinearGradient(
        colors: [Color(0xFFFEFCE8), Color(0xFFFEF08A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'borderColor': Color(0xFFFDE047),
      'accentColor': Color(0xFFCA8A04),
      'badgeBg': Color(0xFFFEF08A),
      'badgeText': Color(0xFF854D0E),
    },
    // Shelf 4: Formulation Bases & Distemper -> Warm Almond / Honey Glow
    {
      'gradient': LinearGradient(
        colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'borderColor': Color(0xFFE9D5FF),
      'accentColor': Color(0xFF9333EA),
      'badgeBg': Color(0xFFF3E8FF),
      'badgeText': Color(0xFF7E22CE),
    },
  ];

  // 4. Interleaved Mid-Page Advertisement Slider (Blinkit style with rich warm gradient card)
  Widget _buildAdSlider({
    required BuildContext context,
    required List items,
    required int currentIndex,
    required Function(int) onPageChanged,
    required double height,
    required double width,
    required String title,
    Gradient? backgroundGradient,
    Color? borderColor,
    Color? accentColor,
    String? badgeText,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final Gradient gradient = backgroundGradient ??
        const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5), Color(0xFFFEE2E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    final Color border = borderColor ?? const Color(0xFFFED7AA);
    final Color accent = accentColor ?? const Color(0xFFEA580C);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_offer_rounded,
                        color: accent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CarouselSlider(
            items: items.map((item) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blackColor.withOpacity(0.08),
                        blurRadius: 8,
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
                        child: Icon(Icons.broken_image_outlined, color: AppColors.greyColor),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            options: CarouselOptions(
              height: 125,
              viewportFraction: 0.90,
              enlargeCenterPage: true,
              enlargeFactor: 0.14,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (index, reason) => onPageChanged(index),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.asMap().entries.map((entry) {
              final bool isActive = currentIndex == entry.key;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 18 : 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive ? accent : accent.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 5. Categorized Product Carousel (Blinkit style horizontal shelf with distinct warm theme)
  Widget _buildCategoryCarousel({
    required BuildContext context,
    required CategoryCarousel carousel,
    required double height,
    required double width,
    int shelfIndex = 0,
  }) {
    final products = carousel.products ?? [];
    if (products.isEmpty) return const SizedBox.shrink();

    final theme = _warmShelfThemes[shelfIndex % _warmShelfThemes.length];
    final Gradient bgGradient = theme['gradient'];
    final Color borderColor = theme['borderColor'];
    final Color accentColor = theme['accentColor'];
    final Color badgeBg = theme['badgeBg'];
    final Color badgeText = theme['badgeText'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 15,
                            width: 3.5,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              carousel.title ?? "Featured Category",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (carousel.subtitle != null && carousel.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(left: 11),
                          child: Text(
                            carousel.subtitle!,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: accentColor.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (carousel.badge != null && carousel.badge!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      carousel.badge!,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 245,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildBlinkitProductCard(context, products[index], isGrid: false);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 6. Modern Blinkit / Swiggy Product Card
  Widget _buildBlinkitProductCard(BuildContext context, HomeProduct product,
      {bool isGrid = false}) {
    final num? oldPrice = product.oldprice;
    final num? currentPrice = product.price;
    final bool hasDiscount = (oldPrice != null && currentPrice != null && oldPrice > currentPrice);
    final int discountPercent = hasDiscount
        ? (((oldPrice - currentPrice) / oldPrice) * 100).round()
        : 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DescriptionPageScreen(
              productId: product.id ?? 0,
              colorId: product.colorId ?? "0",
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: isGrid ? null : 155,
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffEFEFEF)),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Area
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xffFAFAFA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Image.network(
                        "${AppAssetImage.imageBaseUrl}storage/app/public/${product.image}",
                        fit: BoxFit.cover,
                        cacheWidth: 380,
                        cacheHeight: 380,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.format_paint_outlined,
                            size: 36,
                            color: AppColors.greyColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasDiscount && discountPercent > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xff16A34A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "$discountPercent% OFF",
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product Details Area
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.brandName != null && product.brandName!.isNotEmpty)
                          Text(
                            product.brandName!.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 1),
                        Text(
                          product.name ?? "",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryColor,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount)
                              Text(
                                "₹${oldPrice.toStringAsFixed(0)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.lightText,
                                ),
                              ),
                            Text(
                              "₹${currentPrice?.toStringAsFixed(0) ?? "0"}",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "ADD",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
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

  // 7. "We Deal Into" Category Grid (Warm Styled Card)
  Widget _buildWeDealIntoSection(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    final categories = provider.homeScreenModel?.data?.maincategory ?? [];
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBF5), Color(0xFFFFF3E8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE0C2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      "We Deal Into",
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
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Text(
                    "Direct Factory Rates",
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryScreen(mid: cat.id ?? 0),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFE0C2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blackColor.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: cat.image != null && cat.image!.isNotEmpty
                              ? Image.network(
                                  "${AppAssetImage.imageBaseUrl}storage/app/public/${cat.image}",
                                  fit: BoxFit.contain,
                                  cacheWidth: 160,
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
                      const SizedBox(width: 8),
                      Expanded(
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
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              cat.title ?? "Explore >",
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.lightText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFEA580C),
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

  // 8. Popular Brands Section
  Widget _buildPopularBrandsSection(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    final brands = provider.brands;
    if (brands.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  height: 14,
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Popular Paint Brands",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 105,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BrandPageScreen(
                          cmpid: brand.companyId ?? 0,
                          cid: brand.categoryId ?? 0,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 85,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.whiteColor,
                            border: Border.all(
                              color: const Color(0xffE5E7EB),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blackColor.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: (brand.image != null &&
                                    brand.image!.isNotEmpty &&
                                    brand.image != "default.png")
                                ? Image.network(
                                    "${AppAssetImage.imageBaseUrl}storage/app/public/${brand.image}",
                                    fit: BoxFit.cover,
                                    cacheWidth: 150,
                                    cacheHeight: 150,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        (brand.name?.isNotEmpty ?? false)
                                            ? brand.name![0].toUpperCase()
                                            : "B",
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      (brand.name?.isNotEmpty ?? false)
                                          ? brand.name![0].toUpperCase()
                                          : "B",
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          brand.name ?? "",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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

  // 9. Infinite Scroll Grid ("Explore All Products" with scroll-based paginator)
  Widget _buildExploreAllProductsGrid(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    final products = provider.moreProducts;
    if (products.isEmpty && !provider.loadingMoreProducts) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      height: 14,
                      width: 3.5,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Explore All Products",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${products.length} Products",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shrinkWrap: true,
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return _buildBlinkitProductCard(context, products[index], isGrid: true);
            },
          ),
          const SizedBox(height: 16),
          // Scroll-based Paginator State Indicator
          if (provider.loadingMoreProducts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Loading more products...",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.lightText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!provider.hasMoreProducts && products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xffEEEEEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 15,
                        color: Color(0xff16A34A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "You've viewed all available products",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryColor,
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

  // 10. Search Results View (preserved from existing implementation)
  Widget _buildSearchResults(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    if (provider.loadingSearch) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    final results = provider.searchModel?.data ?? [];
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            "No matching products or categories found",
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: width / 16.2, vertical: height / 60),
          child: InkWell(
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
                      colorId: item.relatedid?.toString() ?? "",
                    ),
                  ),
                );
              } else {
                Utils.commonSnackBar(
                  context,
                  height: height,
                  message: "Search category, company and product",
                );
              }
            },
            child: Row(
              children: [
                Container(
                  height: height / 20,
                  width: height / 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 60),
                    image: DecorationImage(
                      image: NetworkImage(
                        "${AppAssetImage.imageBaseUrl}storage/app/public/${item.image ?? ""}",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: width / 20),
                Expanded(
                  child: Text(
                    item.name ?? "",
                    style: AppTextStyle.poppinsMedium15(
                      context: context,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 11. Address Bottom Sheet Modal (Preserved behavior)
  void _openAddressSelector(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    final personalAddresses = provider.getAddressListModel?.data
            ?.where((e) => e.type == "personal")
            .toList() ??
        [];
    final personalAddress = personalAddresses.isNotEmpty ? personalAddresses.first : null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: width,
                height: height / 12,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: AppColors.stroke,
                ),
                padding: EdgeInsets.symmetric(horizontal: width / 29),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Choose Communication Address",
                    style: AppTextStyle.poppinsRegular16(
                      context: context,
                      color: AppColors.secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 16),
                    if (personalAddress == null)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: width / 29),
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => PersonalAddAddressWidget(provider: provider),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline, color: AppColors.primaryColor),
                              const SizedBox(width: 10),
                              Text(
                                "Add New Communication Address",
                                style: AppTextStyle.poppinsRegular16(
                                  context: context,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (personalAddress != null)
                      ListTile(
                        leading: const Icon(Icons.location_on, color: AppColors.primaryColor),
                        title: Text(
                          personalAddress.identityname ?? "",
                          style: AppTextStyle.poppinsBold17(
                            context: context,
                            color: AppColors.blackColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(personalAddress.name ?? ""),
                            Text(
                              "${personalAddress.landmark1 ?? ""}, "
                              "${personalAddress.landmark2 ?? ""}, "
                              "${personalAddress.city ?? ""}, "
                              "${personalAddress.state ?? ""}, "
                              "${personalAddress.pincode ?? ""}",
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await provider.getIdAddress(
                              context: context,
                              addressId: personalAddress.id.toString(),
                            );
                          },
                        ),
                        onTap: () {
                          provider.selectAddress(
                            personalAddress.id.toString(),
                            context: context,
                            height: height,
                            addressId: personalAddress.id.toString(),
                            addressText:
                                "${personalAddress.landmark1 ?? ""}, "
                                "${personalAddress.landmark2 ?? ""}, "
                                "${personalAddress.city ?? ""}, "
                                "${personalAddress.state ?? ""}, "
                                "${personalAddress.pincode ?? ""}",
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
