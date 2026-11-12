import 'package:apni_factory/model/home_screen_model.dart';
import 'package:apni_factory/provider/wishlist_screen_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/widgets/app_network_image.dart';
import 'package:apni_factory/screens/brand_page_screen.dart';
import 'package:apni_factory/screens/description_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Navigates from a product tap to the product's Company Store storefront
/// when [product.companyId] is available, falling back to details if absent.
void openCompanyStoreFromProduct(BuildContext context, HomeProduct product) {
  final int companyId = product.companyId ?? 0;
  if (companyId > 0) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrandPageScreen(
          cmpid: companyId,
          cid: 0,
          scid: 0,
          highlightProduct: product,
        ),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DescriptionPageScreen(
        productId: product.id ?? 0,
        colorId: product.colorId ?? '0',
      ),
    ),
  );
}

/// Shared wishlist toggle action with haptic and floating snackbar feedback.
Future<void> toggleProductWishlist(
  BuildContext context, {
  required int productId,
  required String colorId,
}) async {
  if (productId <= 0) return;
  HapticFeedback.lightImpact();
  final wishProv = Provider.of<WishlistProvider>(context, listen: false);
  final bool nowWishlisted = await wishProv.toggleWishlist(
    context: context,
    productId: productId,
    color: colorId,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1100),
      margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor:
          nowWishlisted ? const Color(0xFFE11D48) : const Color(0xFF1E293B),
      content: Row(
        children: [
          Icon(
            nowWishlisted
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            nowWishlisted ? 'Saved to Wishlist' : 'Removed from Wishlist',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Swiggy-style circular platter category tile with active orange ring and check badge.
class SwiggyCategoryPlatterChip extends StatelessWidget {
  final String label;
  final String? imagePath;
  final bool isSelected;
  final bool isAll;
  final VoidCallback onTap;

  const SwiggyCategoryPlatterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.imagePath,
    this.isAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final String img = (imagePath ?? '').trim();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEA580C)
                          : const Color(0xFFE5E7EB),
                      width: isSelected ? 2.2 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFFEA580C).withOpacity(0.18)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: isAll
                        ? Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFEF08A), Color(0xFFF59E0B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.apps_rounded,
                              size: 26,
                              color: Color(0xFF78350F),
                            ),
                          )
                        : AppNetworkImage(
                            imageUrl: img.isNotEmpty && img != 'default.png'
                                ? '${AppAssetImage.imageBaseUrl}storage/app/public/$img'
                                : null,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.category_outlined,
                          ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swiggy "Top Offers" portrait card showcasing verified factories with photo and promo scrim.
class SwiggyTopOfferCompanyCard extends StatelessWidget {
  final HomeCompany company;
  final String? fallbackImage;
  final String offerHeadline;
  final String offerSubline;
  final VoidCallback onTap;

  const SwiggyTopOfferCompanyCard({
    super.key,
    required this.company,
    required this.onTap,
    this.fallbackImage,
    this.offerHeadline = 'FACTORY DIRECT',
    this.offerSubline = 'WHOLESALE RATES',
  });

  @override
  Widget build(BuildContext context) {
    final String rawPhoto = (company.photo ?? '').trim().isNotEmpty
        ? company.photo!.trim()
        : (fallbackImage ?? '').trim();
    final String imgUrl = rawPhoto.isNotEmpty && rawPhoto != 'default.png'
        ? '${AppAssetImage.imageBaseUrl}storage/app/public/$rawPhoto'
        : '';
    final String city = (company.city ?? '').trim().isNotEmpty
        ? company.city!.trim()
        : 'India';
    final num mov = company.minordervalue ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 146,
                width: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
                      width: 150,
                      height: 146,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.factory_outlined,
                    ),
                    // Dark bottom scrim matching Swiggy Top Offers portrait cards
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.12),
                              Colors.transparent,
                              Colors.black.withOpacity(0.84),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Top promo pill
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFB7185), Color(0xFFEA580C)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              'FACTORY',
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom bold promo copy over scrim
                    Positioned(
                      bottom: 8,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            offerHeadline,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.05,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            offerSubline,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.92),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              company.name ?? 'Verified Factory',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    color: Color(0xFF15803D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded,
                      size: 9, color: Colors.white),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mov > 0
                        ? '4.4 • MOV ₹${mov.toStringAsFixed(0)}'
                        : '4.4 • Direct Dispatch',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '$city${(company.state ?? '').trim().isNotEmpty ? ', ${company.state}' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: const Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Swiggy horizontal-split feed card matching the reference feed screenshots.
/// Tapping opens the product's Company Storefront ([BrandPageScreen]).
class SwiggyHorizontalFeedCard extends StatelessWidget {
  final HomeProduct product;
  final VoidCallback onTap;

  const SwiggyHorizontalFeedCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final num price = product.price ?? 0;
    final num oldPrice = product.oldprice ?? 0;
    final bool hasDiscount = oldPrice > price && price > 0;
    final int discountPct =
        hasDiscount ? (((oldPrice - price) / oldPrice) * 100).round() : 0;

    final String img = (product.image ?? '').trim();
    final String imgUrl = img.isNotEmpty && img != 'default.png'
        ? '${AppAssetImage.imageBaseUrl}storage/app/public/$img'
        : '';

    final String companyLabel = (product.companyName ?? '').trim().isNotEmpty
        ? product.companyName!.trim()
        : 'Factory Direct';
    final String cityLabel = (product.companyCity ?? '').trim().isNotEmpty
        ? product.companyCity!.trim()
        : 'India';
    final String subtitleLine = [
      if ((product.categoryName ?? '').trim().isNotEmpty)
        product.categoryName!.trim(),
      if ((product.brandName ?? '').trim().isNotEmpty) product.brandName!.trim(),
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left portrait image with bottom scrim ("ITEMS AT ₹...") & heart
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 118,
                  height: 134,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
                        width: 118,
                        height: 134,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.format_paint_outlined,
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.10),
                                Colors.transparent,
                                Colors.black.withOpacity(0.82),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Wishlist Heart Icon Top Right
                      Positioned(
                        top: 6,
                        right: 6,
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
                              customBorder: const CircleBorder(),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isWishlisted
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 16,
                                  color: isWishlisted
                                      ? const Color(0xFFEF4444)
                                      : Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Bottom scrim label ("ITEMS / AT ₹...")
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasDiscount && discountPct > 0
                                  ? 'UP TO $discountPct% OFF'
                                  : 'ITEMS',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.92),
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              price > 0
                                  ? 'AT ₹${price.toStringAsFixed(0)}'
                                  : 'FACTORY RATE',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.05,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Right details column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  size: 11, color: Color(0xFFEA580C)),
                              Text(
                                'FACTORY DIRECT',
                                style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFC2410C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if ((product.packSize ?? '').trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.packSize!.trim(),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name ?? 'Factory Product',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF15803D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded,
                              size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '4.2 • Bulk Dispatch',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (subtitleLine.isNotEmpty)
                      Text(
                        subtitleLine,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '$companyLabel • $cityLabel',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Swiggy Footer Pill ("FREE / WHOLESALE" + "Visit Store")
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF5F5), Color(0xFFFFFFFF)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              hasDiscount && (oldPrice - price) > 0
                                  ? 'SAVE ₹${(oldPrice - price).toStringAsFixed(0)} DIRECT'
                                  : 'FACTORY WHOLESALE',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFDC2626),
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Visit Store',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
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
            ],
          ),
        ),
      ),
    );
  }
}
