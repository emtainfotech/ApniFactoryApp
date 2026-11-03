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
import 'package:apni_factory/screens/product_category_page_screen.dart';
import 'package:apni_factory/model/home_screen_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

  bool _isStickyCategoryVisible = false;
  final Set<int> _addedProductIds = {};
  int _selectedTier1Tab = 0;
  bool _showGoToTop = false;
  bool _freeCashClaimed = false;
  String _activeQuickFilter = 'All';

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
      final currentScroll = _scrollController.position.pixels;
      final shouldShowSticky = currentScroll > 360;
      if (_isStickyCategoryVisible != shouldShowSticky) {
        setState(() {
          _isStickyCategoryVisible = shouldShowSticky;
        });
      }

      if (currentScroll < 250 && _showGoToTop) {
        setState(() {
          _showGoToTop = false;
        });
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
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
                      NotificationListener<UserScrollNotification>(
                        onNotification: (notification) {
                          if (_scrollController.hasClients) {
                            final currentScroll = _scrollController.position.pixels;
                            if (notification.direction == ScrollDirection.forward &&
                                currentScroll > 400) {
                              if (!_showGoToTop) {
                                setState(() {
                                  _showGoToTop = true;
                                });
                              }
                            } else if (notification.direction == ScrollDirection.reverse) {
                              if (_showGoToTop) {
                                setState(() {
                                  _showGoToTop = false;
                                });
                              }
                            }
                          }
                          return false;
                        },
                        child: RefreshIndicator(
                          color: AppColors.primaryColor,
                          onRefresh: () => provider.refreshHomeScreen(context),
                          child: ListView(
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            children: [
                              _buildTopHeader(context, provider, height, width),
                              _buildModernSearchBar(context, provider, height, width),
                              _buildSearchBarPromoPopup(context, provider, width),
                              if (provider.searchModel != null)
                                _buildSearchResults(context, provider, height, width)
                              else ...[
                                _buildHeroBannerSlider(context, provider, height, width),
                                const SizedBox(height: 12),
                                _buildWeDealIntoSection(context, provider, height, width),
                                if (provider.selectedMainCategoryId != 0)
                                  _buildCategoryFilteredSection(context, provider, height, width),
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
                      ),
                      if (_isStickyCategoryVisible && provider.searchModel == null)
                        _buildStickyCategoryBar(context, provider, width),
                      if (_showGoToTop)
                        _buildGoToTopButton(),
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

  // 2b. Promo Banner ("Use Your Free Cash: ₹30" - Swiggy Style from media_1793681481175_5ffac60c.jpg)
  Widget _buildSearchBarPromoPopup(BuildContext context, HomeScreenProvider provider, double width) {
    if (provider.searchModel != null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Scalloped / Crimson Free Cash Banner
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _freeCashClaimed = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF881337),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "₹30 Free Cash reward active on your account!",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF881337),
                    Color(0xFFBE123C),
                    Color(0xFF9F1239),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF881337).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left: Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _freeCashClaimed ? "REWARD ACTIVE" : "LIMITED OFFER",
                                style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFFE4E6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Use Your Free Cash: ₹30",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Valid till 9th Nov on orders above ₹149",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFFFE4E6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: 3D Gold Coin with ₹ symbol
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.25, -0.25),
                        radius: 0.85,
                        colors: [
                          Color(0xFFFFF7C2),
                          Color(0xFFFFD700),
                          Color(0xFFE5A910),
                          Color(0xFFB47806),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFFFFE082).withOpacity(0.6),
                          blurRadius: 6,
                          offset: const Offset(-2, -2),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFECB3),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC48603),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "₹",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF6A3805),
                              shadows: [
                                const Shadow(
                                  color: Color(0xFFFFF8E1),
                                  offset: Offset(0.8, 0.8),
                                  blurRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2. Swiggy-Style Quick Filter Chips Row (Filter, Sort By, 99 Store, Bolt 15 min)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickFilterChip(
                  icon: Icons.tune_rounded,
                  label: "Filter",
                  hasDropdown: false,
                  isSelected: _activeQuickFilter == 'Filter',
                  onTap: () {
                    setState(() {
                      _activeQuickFilter = _activeQuickFilter == 'Filter' ? 'All' : 'Filter';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  icon: null,
                  label: "Sort By",
                  hasDropdown: true,
                  isSelected: _activeQuickFilter.startsWith('Sort:'),
                  onTap: () {
                    _showSortBottomSheet(context, provider);
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  icon: Icons.storefront_rounded,
                  label: "99 Store",
                  hasDropdown: false,
                  badge: "HOT",
                  badgeColor: const Color(0xFFEA580C),
                  isSelected: _activeQuickFilter == '99 Store',
                  onTap: () {
                    setState(() {
                      _activeQuickFilter = _activeQuickFilter == '99 Store' ? 'All' : '99 Store';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFEA580C),
                  label: "Bolt 15 min",
                  hasDropdown: false,
                  isSelected: _activeQuickFilter == 'Bolt',
                  onTap: () {
                    setState(() {
                      _activeQuickFilter = _activeQuickFilter == 'Bolt' ? 'All' : 'Bolt';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickFilterChip(
                  icon: Icons.verified_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: "Factory Direct",
                  hasDropdown: false,
                  isSelected: _activeQuickFilter == 'Factory Direct',
                  onTap: () {
                    setState(() {
                      _activeQuickFilter = _activeQuickFilter == 'Factory Direct' ? 'All' : 'Factory Direct';
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip({
    IconData? icon,
    Color? iconColor,
    required String label,
    required bool hasDropdown,
    String? badge,
    Color? badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? (isSelected ? const Color(0xFFEA580C) : const Color(0xFF4B5563))),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF374151),
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 3),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF6B7280)),
            ],
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context, HomeScreenProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Sort Products By",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.star_rounded, color: Color(0xFFEA580C)),
                  title: Text("Relevance (Default)", style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () {
                    setState(() => _activeQuickFilter = 'Sort: Relevance');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF16A34A)),
                  title: Text("Price: Low to High", style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () {
                    setState(() => _activeQuickFilter = 'Sort: Price Low');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_downward_rounded, color: Color(0xFFDC2626)),
                  title: Text("Price: High to Low", style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () {
                    setState(() => _activeQuickFilter = 'Sort: Price High');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
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

    return Container(
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
          // Top Image Area (Clickable to open Description)
          Expanded(
            flex: 5,
            child: InkWell(
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
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
          ),
          // Product Details Area
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Title Area (Clickable to open Description)
                  InkWell(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.brandName != null && product.brandName!.isNotEmpty) ...[
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
                        ],
                        Text(
                          product.name ?? "",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryColor,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (product.packSize != null && product.packSize!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        product.packSize!,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Price and ADD Button Row (Completely decoupled from Description navigation)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              "\u20B9${oldPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.lightText,
                              ),
                            ),
                          Text(
                            "\u20B9${currentPrice?.toStringAsFixed(0) ?? "0"}",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      _buildQuickAddButton(context, product),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quick Animated Add To Cart Button (No Screen Redirect)
  Widget _buildQuickAddButton(BuildContext context, HomeProduct product) {
    final pId = product.id ?? 0;
    final bool isAdded = _addedProductIds.contains(pId);

    return InkWell(
      onTap: () async {
        if (isAdded) return;
        setState(() => _addedProductIds.add(pId));
        final cartProv = Provider.of<CartScreenProvider>(context, listen: false);
        await cartProv.quickAddToCart(
          context: context,
          productId: pId.toString(),
          brandId: product.brandId?.toString() ?? "0",
          attributeId: product.attributeId?.toString(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF16A34A),
              duration: const Duration(milliseconds: 1400),
              margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${product.name ?? 'Item'} added to wholesale cart!",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (mounted) {
              setState(() => _addedProductIds.remove(pId));
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isAdded ? const Color(0xFF16A34A) : AppColors.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isAdded ? const Color(0xFF16A34A) : AppColors.primaryColor.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: isAdded
              ? [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdded) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 12),
              const SizedBox(width: 3),
            ],
            Text(
              isAdded ? "ADDED" : "ADD",
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isAdded ? Colors.white : AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7. "We Deal Into" Section (Redesigned like Popular Paint Brands circular avatars)
  Widget _buildWeDealIntoSection(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    final categories = provider.homeScreenModel?.data?.maincategory ?? [];
    if (categories.isEmpty) return const SizedBox.shrink();

    final selectedId = provider.selectedMainCategoryId;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      height: 14,
                      width: 3.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "What's on your mind?",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
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
          const SizedBox(height: 8),

          // Swiggy-Style Tier 1 Horizontal Tabs
          Container(
            height: 38,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildTier1TabItem(
                  icon: Icons.grid_view_rounded,
                  label: "ALL",
                  isSelected: _selectedTier1Tab == 0,
                  onTap: () {
                    setState(() => _selectedTier1Tab = 0);
                    provider.selectCategory(0);
                  },
                ),
                _buildTier1TabItem(
                  icon: Icons.local_offer_outlined,
                  label: "UNDER \u20B9999",
                  badge: "HOT",
                  isSelected: _selectedTier1Tab == 1,
                  onTap: () {
                    setState(() => _selectedTier1Tab = 1);
                  },
                ),
                _buildTier1TabItem(
                  icon: Icons.verified_rounded,
                  label: "FACTORY DIRECT",
                  isSelected: _selectedTier1Tab == 2,
                  onTap: () {
                    setState(() => _selectedTier1Tab = 2);
                  },
                ),
                _buildTier1TabItem(
                  icon: Icons.inventory_2_outlined,
                  label: "BULK PACKS",
                  isSelected: _selectedTier1Tab == 3,
                  onTap: () {
                    setState(() => _selectedTier1Tab = 3);
                  },
                ),
                _buildTier1TabItem(
                  icon: Icons.local_shipping_outlined,
                  label: "FAST DISPATCH",
                  isSelected: _selectedTier1Tab == 4,
                  onTap: () {
                    setState(() => _selectedTier1Tab = 4);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Tier 2: Category Circular Avatars
          SizedBox(
            height: 88,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                final bool isAll = index == 0;
                final cat = isAll ? null : categories[index - 1];
                final catId = isAll ? 0 : (cat?.id ?? 0);
                final bool isSelected = selectedId == catId;

                return InkWell(
                  onTap: () {
                    provider.selectCategory(catId);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFFFFF7ED) : AppColors.whiteColor,
                            border: Border.all(
                              color: isSelected ? const Color(0xFFEA580C) : const Color(0xffE5E7EB),
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFFEA580C).withOpacity(0.25)
                                    : AppColors.blackColor.withOpacity(0.05),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: isAll
                                ? Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFFEF08A), Color(0xFFFBBF24)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.grid_view_rounded,
                                        size: 26,
                                        color: Color(0xFF854D0E),
                                      ),
                                    ),
                                  )
                                : (cat?.image != null && cat!.image!.isNotEmpty)
                                    ? Image.network(
                                        "${AppAssetImage.imageBaseUrl}storage/app/public/${cat.image}",
                                        fit: BoxFit.cover,
                                        cacheWidth: 140,
                                        cacheHeight: 140,
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Text(
                                            (cat.name?.isNotEmpty ?? false)
                                                ? cat.name![0].toUpperCase()
                                                : "C",
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFEA580C),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          (cat?.name?.isNotEmpty ?? false)
                                              ? cat!.name![0].toUpperCase()
                                              : "C",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFEA580C),
                                          ),
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isAll ? "All Items" : (cat?.name ?? ""),
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF4B5563),
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
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

  // Tier 1 Horizontal Tab Item with active bottom underline
  Widget _buildTier1TabItem({
    required IconData icon,
    required String label,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF4B5563),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Sticky Category Bar (Frozen at top on reach, matching media_1793681383364_d11e444b.jpg)
  Widget _buildStickyCategoryBar(
      BuildContext context, HomeScreenProvider provider, double width) {
    final categories = provider.homeScreenModel?.data?.maincategory ?? [];
    if (categories.isEmpty) return const SizedBox.shrink();

    final selectedId = provider.selectedMainCategoryId;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: topPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tier 1: Horizontal tabs (:: ALL, UNDER ₹299 NEW, 99 STORE, OFFERS)
            Container(
              height: 40,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildTier1TabItem(
                    icon: Icons.grid_view_rounded,
                    label: "ALL",
                    isSelected: _selectedTier1Tab == 0,
                    onTap: () {
                      setState(() => _selectedTier1Tab = 0);
                      provider.selectCategory(0);
                    },
                  ),
                  _buildTier1TabItem(
                    icon: Icons.local_offer_outlined,
                    label: "UNDER \u20B9999",
                    badge: "HOT",
                    isSelected: _selectedTier1Tab == 1,
                    onTap: () {
                      setState(() => _selectedTier1Tab = 1);
                    },
                  ),
                  _buildTier1TabItem(
                    icon: Icons.verified_rounded,
                    label: "FACTORY DIRECT",
                    isSelected: _selectedTier1Tab == 2,
                    onTap: () {
                      setState(() => _selectedTier1Tab = 2);
                    },
                  ),
                  _buildTier1TabItem(
                    icon: Icons.inventory_2_outlined,
                    label: "BULK PACKS",
                    isSelected: _selectedTier1Tab == 3,
                    onTap: () {
                      setState(() => _selectedTier1Tab = 3);
                    },
                  ),
                  _buildTier1TabItem(
                    icon: Icons.local_shipping_outlined,
                    label: "FAST DISPATCH",
                    isSelected: _selectedTier1Tab == 4,
                    onTap: () {
                      setState(() => _selectedTier1Tab = 4);
                    },
                  ),
                ],
              ),
            ),

            // Tier 2: Category Circular Avatars (Meals, Poha, Kachori, Paints, etc.)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  final bool isAll = index == 0;
                  final cat = isAll ? null : categories[index - 1];
                  final catId = isAll ? 0 : (cat?.id ?? 0);
                  final bool isSelected = selectedId == catId;

                  return InkWell(
                    onTap: () {
                      provider.selectCategory(catId);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 66,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFF9FAFB),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE5E7EB),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFEA580C).withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ClipOval(
                              child: isAll
                                  ? Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFFEF08A), Color(0xFFFBBF24)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.grid_view_rounded,
                                          size: 22,
                                          color: Color(0xFF854D0E),
                                        ),
                                      ),
                                    )
                                  : (cat?.image != null && cat!.image!.isNotEmpty)
                                      ? Image.network(
                                          "${AppAssetImage.imageBaseUrl}storage/app/public/${cat.image}",
                                          fit: BoxFit.cover,
                                          cacheWidth: 100,
                                          cacheHeight: 100,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Text(
                                              (cat.name?.isNotEmpty ?? false) ? cat.name![0].toUpperCase() : "C",
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFEA580C),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            (cat?.name?.isNotEmpty ?? false) ? cat!.name![0].toUpperCase() : "C",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFEA580C),
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAll ? "All Items" : (cat?.name ?? ""),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF4B5563),
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
      ),
    );
  }

  // Swiggy-Style Floating "Back to Top" Pill Button
  Widget _buildGoToTopButton() {
    return Positioned(
      bottom: 96,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              );
              setState(() {
                _showGoToTop = false;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA580C), // Swiggy Orange
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Back to top",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dynamic Swiggy-Style Category Section with Subcategories & Brand Sliders in between
  Widget _buildCategoryFilteredSection(
      BuildContext context, HomeScreenProvider provider, double height, double width) {
    final selectedId = provider.selectedMainCategoryId;
    final allProducts = [...provider.randomProducts, ...provider.moreProducts];
    final allSubcategories = provider.subcategories;
    final allBrands = provider.brands;
    final allCompanies = provider.companies;

    // Filter products matching this category
    List<HomeProduct> baseProducts = (selectedId == 0)
        ? allProducts
        : allProducts.where((p) => p.categoryId == selectedId).toList();
    if (baseProducts.isEmpty && selectedId != 0) {
      baseProducts = allProducts;
    }

    // Dynamic filtering based on active Tier 1 Tab (ALL, UNDER ₹999, FACTORY DIRECT, BULK PACKS, FAST DISPATCH)
    List<HomeProduct> tierFiltered = baseProducts;
    if (_selectedTier1Tab == 1) {
      // UNDER ₹999
      tierFiltered = baseProducts.where((p) {
        final price = p.price?.toDouble() ?? 0.0;
        return price > 0 && price <= 999;
      }).toList();
      if (tierFiltered.isEmpty) {
        tierFiltered = baseProducts.where((p) => (p.price?.toDouble() ?? 0.0) <= 1500).toList();
      }
    } else if (_selectedTier1Tab == 3) {
      // BULK PACKS
      tierFiltered = baseProducts.where((p) {
        final pack = (p.packSize ?? '').toLowerCase();
        return pack.contains('ltr') || pack.contains('kg') || (p.oldprice ?? 0) > (p.price ?? 0);
      }).toList();
    }

    final productsToShow = tierFiltered.isNotEmpty ? tierFiltered : baseProducts.take(12).toList();

    // Filter related subcategories
    final subcategoriesToShow = allSubcategories.where((s) {
      if (s.maincategoryId == selectedId) return true;
      return true; // fallback to active subcategories
    }).take(10).toList();

    final brandsToShow = allBrands.take(8).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Category Products",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryColor,
                ),
              ),
              InkWell(
                onTap: () => provider.selectCategory(0),
                child: Text(
                  "Show All",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // First 2 products
          if (productsToShow.isNotEmpty)
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: productsToShow.length > 2 ? 2 : productsToShow.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, idx) {
                return _buildBlinkitProductCard(context, productsToShow[idx], isGrid: true);
              },
            ),

          // IN-BETWEEN SLIDER 1: Subcategories Horizontal Slider
          if (subcategoriesToShow.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryColor),
                const SizedBox(width: 6),
                Text(
                  "Explore Sub-Categories",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 95,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: subcategoriesToShow.length,
                itemBuilder: (context, index) {
                  final sub = subcategoriesToShow[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductCategoryPageScreen(
                            bid: 0,
                            cid: sub.id ?? 0,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              child: (sub.image != null && sub.image!.isNotEmpty)
                                  ? Image.network(
                                      "${AppAssetImage.imageBaseUrl}storage/app/public/${sub.image}",
                                      fit: BoxFit.cover,
                                      cacheWidth: 100,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.category_outlined,
                                        color: AppColors.primaryColor,
                                        size: 22,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.category_outlined,
                                      color: AppColors.primaryColor,
                                      size: 22,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            sub.name ?? "",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryColor,
                            ),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Next 2 products (items 2 to 4)
          if (productsToShow.length > 2) ...[
            const SizedBox(height: 16),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: productsToShow.length > 4 ? 2 : (productsToShow.length - 2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, idx) {
                return _buildBlinkitProductCard(context, productsToShow[idx + 2], isGrid: true);
              },
            ),
          ],

          // IN-BETWEEN SLIDER 2: Brands & Verified Factory Companies with Warm Background
          if (brandsToShow.isNotEmpty || allCompanies.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFBF5), Color(0xFFFFF3E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE0C2), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFFEA580C)),
                          const SizedBox(width: 6),
                          Text(
                            "Verified Factory Direct",
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF9A3412),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "B2B BULK",
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Companies horizontal list
                  if (allCompanies.isNotEmpty)
                    SizedBox(
                      height: 78,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: allCompanies.length,
                        itemBuilder: (context, index) {
                          final comp = allCompanies[index];
                          return Container(
                            width: 170,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFED7AA)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.factory_outlined,
                                    color: Color(0xFFEA580C),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        comp.name ?? "Factory Direct",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.secondaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        comp.city != null ? "${comp.city}, ${comp.state ?? ''}" : "Verified Seller",
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          color: AppColors.lightText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Remaining products (items 4+)
          if (productsToShow.length > 4) ...[
            const SizedBox(height: 16),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: productsToShow.length - 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, idx) {
                return _buildBlinkitProductCard(context, productsToShow[idx + 4], isGrid: true);
              },
            ),
          ],
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
