import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/product_detail_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:apni_factory/res/widgets/frequently_brought_together_widget.dart';
import 'package:apni_factory/res/widgets/global_cart_container.dart';
import 'package:apni_factory/res/widgets/rating_review_widget.dart';
import 'package:apni_factory/utils.dart';
import 'package:apni_factory/model/user_cart_model.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DescriptionPageScreen extends StatefulWidget {
  final int productId;
  final String colorId;
  const DescriptionPageScreen({
    super.key,
    required this.productId,
    required this.colorId,
  });

  @override
  State<DescriptionPageScreen> createState() => _DescriptionPageScreenState();
}

class _DescriptionPageScreenState extends State<DescriptionPageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedAttributeIndex = 0;
  bool _isDescriptionExpanded = true;
  bool _isSpecsExpanded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductDetailProvider>(context, listen: false).productDetail(
        context: context,
        productid: widget.productId.toString(),
        colorid: widget.colorId.toString(),
      );

      Provider.of<CartScreenProvider>(context, listen: false).userCart(
        context: context,
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  AttributeData? _findCartAttribute(CartScreenProvider cartProvider, int? attributeId) {
    if (cartProvider.userCartModel?.data == null || attributeId == null) return null;
    for (var categoryList in cartProvider.userCartModel!.data.values) {
      for (var productList in categoryList) {
        for (var product in productList) {
          for (var attr in product.attributeData) {
            if (attr.productattributeid == attributeId) {
              return attr;
            }
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext globalContext) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Product Details",
          style: GoogleFonts.poppins(
            color: AppColors.secondaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          Consumer<ProductDetailProvider>(
            builder: (context, provider, child) {
              final bool isWishlisted =
                  provider.productDetailModel?.data?.wishlist ?? false;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: isWishlisted ? 1.2 : 1.0),
                duration: const Duration(milliseconds: 250),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: IconButton(
                      icon: Icon(
                        isWishlisted ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: isWishlisted ? const Color(0xffEF4444) : AppColors.secondaryColor,
                        size: 24,
                      ),
                      onPressed: () {
                        provider.addToWishList(
                          context: context,
                          height: height,
                          width: width,
                          productid: provider.productDetailModel?.data?.productId.toString() ?? "",
                          color: provider.productDetailModel?.data?.attributes?[0].color,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Consumer<ProductDetailProvider>(
        builder: (context, provider, child) {
          if (provider.loadingproductDetail ||
              provider.loadingAddToCart ||
              provider.loadingAddToWishlist ||
              Provider.of<CartScreenProvider>(context).loadingUserCart) {
            return const CircularProgressIndicatorWidget();
          }

          final productData = provider.productDetailModel?.data;
          if (productData == null) {
            return Center(
              child: Text(
                "Product information is currently unavailable",
                style: GoogleFonts.poppins(color: AppColors.lightText),
              ),
            );
          }

          final attributes = productData.attributes ?? [];
          final bool hasAttributes = attributes.isNotEmpty;
          final currentAttr = hasAttributes
              ? (_selectedAttributeIndex < attributes.length
                  ? attributes[_selectedAttributeIndex]
                  : attributes[0])
              : null;

          final num? oldPrice = currentAttr?.oldprice;
          final num? currentPrice = currentAttr?.price;
          final bool hasDiscount =
              (oldPrice != null && currentPrice != null && oldPrice > currentPrice);
          final int discountPercent = hasDiscount
              ? (((oldPrice - currentPrice) / oldPrice) * 100).round()
              : 0;

          final cartProvider = Provider.of<CartScreenProvider>(context);
          final selectedCartAttr =
              hasAttributes ? _findCartAttribute(cartProvider, currentAttr?.attributeid) : null;
          final bool isSelectedInCart = (selectedCartAttr != null);

          final List<String> images = provider.imageList.isNotEmpty
              ? provider.imageList
              : (productData.image != null && productData.image!.isNotEmpty
                  ? [productData.image!]
                  : []);

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
                      // 1. Hero Image Showcase with dynamic indicators
                      _buildImageGalleryCard(context, provider, images, height, width, discountPercent),

                      // 2. Product Name, Brand & Price Hero Card
                      _buildProductTitleAndPriceCard(
                        context,
                        productData,
                        currentAttr,
                        oldPrice,
                        currentPrice,
                        hasDiscount,
                        discountPercent,
                      ),

                      // 3. Pack Size / Box Packing Selector (Interactive)
                      if (hasAttributes)
                        _buildPackSizeSelector(
                          context,
                          provider,
                          cartProvider,
                          attributes,
                          height,
                          width,
                          globalContext,
                        ),

                      // 4. B2B Wholesale Trust Pills (Factory Direct, GST, Transport)
                      _buildB2BTrustBanner(context),

                      // 5. Expandable Description Card
                      _buildDescriptionCard(context, productData.description ?? ""),

                      // 6. Technical Specifications & Details
                      _buildTechnicalSpecsCard(context, productData, currentAttr),

                      // 7. Seller / Manufacturer Profile Card
                      if (productData.sellerdetail != null)
                        _buildSellerInfoCard(context, productData.sellerdetail!, height, width),

                      // 8. Frequently Bought Together
                      if (productData.relatedproductlist != null &&
                          productData.relatedproductlist!.isNotEmpty)
                        FrequentlyBroughtTogetherWidget(
                          width: width,
                          height: height,
                          provider: provider,
                        ),

                      // 9. Ratings & Reviews
                      RatingReviewWidget(
                        width: width,
                        height: height,
                        provider: provider,
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed Floating Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomActionBar(
                  context,
                  provider,
                  cartProvider,
                  productData,
                  currentAttr,
                  currentPrice,
                  isSelectedInCart,
                  selectedCartAttr,
                  height,
                  width,
                  globalContext,
                ),
              ),

              // Floating Cart Container
              GlobalCartContainer(width: width, height: height),
            ],
          );
        },
      ),
    );
  }

  // 1. Hero Image Showcase Card
  Widget _buildImageGalleryCard(
    BuildContext context,
    ProductDetailProvider provider,
    List<String> images,
    double height,
    double width,
    int discountPercent,
  ) {
    return Container(
      width: width,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffECEEF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Floating Badges on top of image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEA580C).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        "FACTORY DIRECT",
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
                if (discountPercent > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$discountPercent% OFF",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Image Carousel or Single Image
          if (images.isEmpty)
            SizedBox(
              height: 240,
              child: Center(
                child: Image.asset(AppAssetImage.logo, height: 120, fit: BoxFit.contain),
              ),
            )
          else if (images.length == 1)
            SizedBox(
              height: 250,
              child: Image.network(
                "${AppAssetImage.imageBaseUrl}storage/app/public/${images[0]}",
                fit: BoxFit.contain,
                cacheWidth: 800,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  AppAssetImage.logo,
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            CarouselSlider(
              items: images.map((img) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Image.network(
                    "${AppAssetImage.imageBaseUrl}storage/app/public/$img",
                    fit: BoxFit.contain,
                    cacheWidth: 800,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      AppAssetImage.logo,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }).toList(),
              carouselController: provider.carouselSliderController,
              options: CarouselOptions(
                height: 250,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                enlargeCenterPage: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    provider.current = index;
                  });
                },
              ),
            ),
          const SizedBox(height: 12),

          // Dynamic Active Pill Indicator & Counter
          if (images.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: images.asMap().entries.map((entry) {
                      final bool isActive = (provider.current == entry.key);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isActive ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isActive ? AppColors.primaryColor : const Color(0xffD1D5DB),
                        ),
                      );
                    }).toList(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xffF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${provider.current + 1}/${images.length}",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 2. Product Name, Brand & Price Hero Card
  Widget _buildProductTitleAndPriceCard(
    BuildContext context,
    dynamic productData,
    dynamic currentAttr,
    num? oldPrice,
    num? currentPrice,
    bool hasDiscount,
    int discountPercent,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
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
          // Brand pill & Shade pill with Wrap to prevent overflow
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  productData.title ?? "GENUINE FACTORY FORMULATION",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D4ED8),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (currentAttr?.color != null && currentAttr!.color!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Shade: ${currentAttr.color}",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Product Name
          Text(
            productData.name ?? "",
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Price & Savings Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "₹${currentPrice?.toStringAsFixed(0) ?? "0"}",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "/ Pcs",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 8),
                            Text(
                              "₹${oldPrice?.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "+ GST extra as applicable • Bulk Factory Rates",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasDiscount)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "$discountPercent% OFF",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "WHOLESALE",
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Pack Size / Box Packing Selector (Interactive)
  Widget _buildPackSizeSelector(
    BuildContext context,
    ProductDetailProvider provider,
    CartScreenProvider cartProvider,
    List attributes,
    double height,
    double width,
    BuildContext globalContext,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
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
              Text(
                "Select Pack Size & Quantity",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryColor,
                ),
              ),
              Text(
                "${attributes.length} Options",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attributes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final attr = attributes[index];
              final bool isSelected = (_selectedAttributeIndex == index);
              final cartAttr = _findCartAttribute(cartProvider, attr.attributeid);
              final bool isInCart = (cartAttr != null);

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedAttributeIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xffFAFAFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFEA580C) : const Color(0xffE5E7EB),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFEA580C) : const Color(0xff9CA3AF),
                            width: 2,
                          ),
                          color: isSelected ? const Color(0xFFEA580C) : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(Icons.check, size: 12, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attr.boxpacking?.toString() ?? "Standard Pack",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryColor,
                              ),
                            ),
                            Text(
                              "Box Contains: ${attr.quantity?.toString() ?? "1"} pcs",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${attr.price ?? "0"}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? const Color(0xFFEA580C) : AppColors.secondaryColor,
                            ),
                          ),
                          Text(
                            "/ pcs",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lightText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Direct Quantity Stepper or Mini Add
                      if (isInCart)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  cartProvider.decreaseCartQuantity(
                                    context: context,
                                    height: height,
                                    cartid: cartAttr.attributeid.toString(),
                                    qty: cartAttr.qty.toString(),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text("-", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  "${cartAttr.qty}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  cartProvider.increaseCartQuantity(
                                    context: context,
                                    height: height,
                                    cartid: cartAttr.attributeid.toString(),
                                    qty: cartAttr.qty.toString(),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text("+", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        InkWell(
                          onTap: () {
                            provider.addToCart(
                              context: context,
                              globalContext: globalContext,
                              height: height,
                              width: width,
                              productid: provider.productDetailModel?.data?.id.toString() ?? "",
                              attributes: provider.getAttributesList(id: attr.attributeid ?? 0),
                              brandid: provider.productDetailModel?.data?.brandId ?? 0,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              "ADD",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                              ),
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

  // 4. B2B Wholesale Trust Pills Banner
  Widget _buildB2BTrustBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustItem(Icons.local_shipping_outlined, "Fast Dispatch", "24-48 Hours"),
          Container(height: 28, width: 1, color: const Color(0xFF86EFAC)),
          _buildTrustItem(Icons.shield_outlined, "Tested Quality", "100% Genuine"),
          Container(height: 28, width: 1, color: const Color(0xFF86EFAC)),
          _buildTrustItem(Icons.receipt_long_outlined, "GST Invoice", "Input Credit"),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF15803D)),
        const SizedBox(height: 3),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF166534),
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 8.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF15803D).withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // 5. Expandable Description Card
  Widget _buildDescriptionCard(BuildContext context, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
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
          InkWell(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.article_outlined, size: 18, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Product Description",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isDescriptionExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.secondaryColor,
                ),
              ],
            ),
          ),
          if (_isDescriptionExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xffF1F3F5)),
            const SizedBox(height: 12),
            HtmlWidget(
              Utils.htmlDocument(description).outerHtml,
              textStyle: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xff4B5563),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 6. Technical Specifications & Details
  Widget _buildTechnicalSpecsCard(BuildContext context, dynamic productData, dynamic currentAttr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
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
          InkWell(
            onTap: () {
              setState(() {
                _isSpecsExpanded = !_isSpecsExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 18, color: Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    Text(
                      "Specifications & Details",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _isSpecsExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.secondaryColor,
                ),
              ],
            ),
          ),
          if (_isSpecsExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xffF1F3F5)),
            const SizedBox(height: 10),
            _buildSpecRow("Brand Code", productData.brandId?.toString() ?? "OEM Direct"),
            _buildSpecRow("HSN Code", productData.hsncode?.toString() ?? "320890"),
            _buildSpecRow("Applicable GST", "${productData.tax ?? 18}%"),
            _buildSpecRow("Packing Type", currentAttr?.boxpacking?.toString() ?? "Factory Standard"),
            _buildSpecRow("Units per Box", "${currentAttr?.quantity?.toString() ?? 1} Units"),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.lightText,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // 7. Seller / Manufacturer Profile Card
  Widget _buildSellerInfoCard(
    BuildContext context,
    dynamic seller,
    double height,
    double width,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: seller.photo != null && seller.photo.isNotEmpty
                  ? Image.network(
                      "${AppAssetImage.imageBaseUrl}storage/app/public/${seller.photo}",
                      fit: BoxFit.cover,
                      cacheWidth: 150,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.factory_outlined,
                        color: Color(0xFFEA580C),
                        size: 26,
                      ),
                    )
                  : const Icon(
                      Icons.factory_outlined,
                      color: Color(0xFFEA580C),
                      size: 26,
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
                      "VERIFIED MANUFACTURER",
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                  ],
                ),
                Text(
                  seller.name ?? "Apni Factory Verified Seller",
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (seller.city != null && seller.city.isNotEmpty)
                  Text(
                    "Factory Site: ${seller.city}",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightText,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Fixed Floating Bottom Action Bar
  Widget _buildBottomActionBar(
    BuildContext context,
    ProductDetailProvider provider,
    CartScreenProvider cartProvider,
    dynamic productData,
    dynamic currentAttr,
    num? currentPrice,
    bool isSelectedInCart,
    AttributeData? selectedCartAttr,
    double height,
    double width,
    BuildContext globalContext,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price summary on left
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOTAL PRICE",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightText,
                    letterSpacing: 0.4,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "₹${currentPrice?.toStringAsFixed(0) ?? "0"}",
                      style: GoogleFonts.poppins(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "/ unit",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Add to Cart / Quantity Stepper on right
          Expanded(
            flex: 6,
            child: isSelectedInCart && selectedCartAttr != null
                ? Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                          onPressed: () {
                            cartProvider.decreaseCartQuantity(
                              context: context,
                              height: height,
                              cartid: selectedCartAttr.attributeid.toString(),
                              qty: selectedCartAttr.qty.toString(),
                            );
                          },
                        ),
                        Text(
                          "${selectedCartAttr.qty} in Cart",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                          onPressed: () {
                            cartProvider.increaseCartQuantity(
                              context: context,
                              height: height,
                              cartid: selectedCartAttr.attributeid.toString(),
                              qty: selectedCartAttr.qty.toString(),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      if (currentAttr != null) {
                        provider.addToCart(
                          context: context,
                          globalContext: globalContext,
                          height: height,
                          width: width,
                          productid: productData.id.toString(),
                          attributes: provider.getAttributesList(id: currentAttr.attributeid ?? 0),
                          brandid: productData.brandId ?? 0,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      elevation: 4,
                      shadowColor: AppColors.primaryColor.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "ADD TO CART",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
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
}
