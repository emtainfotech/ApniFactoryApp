import 'package:apni_factory/model/user_wishlist_model.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/wishlist_screen_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:apni_factory/screens/description_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Set<int> _addedToCartPids = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WishlistProvider>(context, listen: false).userWishList(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Consumer<WishlistProvider>(
          builder: (context, prov, _) {
            final count = prov.userWishlistModel?.data?.length ?? 0;
            return Row(
              children: [
                Text(
                  "My Wishlist",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Text(
                      "$count items",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE11D48),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Wishlist",
            icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF64748B)),
            onPressed: () {
              HapticFeedback.lightImpact();
              Provider.of<WishlistProvider>(context, listen: false).userWishList(context: context);
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, child) {
          if (provider.loadingUserWishlist) {
            return const Center(child: CircularProgressIndicatorWidget());
          }

          final items = provider.userWishlistModel?.data ?? [];

          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () => provider.userWishList(context: context),
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildWishlistCard(context, item, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWishlistCard(BuildContext context, Data item, WishlistProvider wishProv) {
    final int pId = item.productid ?? 0;
    final int wId = item.id ?? 0;
    final bool isAdded = _addedToCartPids.contains(pId);

    // Get lowest price and oldprice from attributes
    num price = 0;
    num oldPrice = 0;
    String packSize = "";
    int? attrId;

    if (item.attribute != null && item.attribute!.isNotEmpty) {
      final validAttrs = item.attribute!.where((a) => (a.price ?? 0) > 0).toList();
      if (validAttrs.isNotEmpty) {
        validAttrs.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        price = validAttrs.first.price ?? 0;
        oldPrice = validAttrs.first.oldprice ?? 0;
        packSize = validAttrs.first.quantity ?? "";
        attrId = validAttrs.first.id;
      }
    }

    final bool hasDiscount = oldPrice > price && oldPrice > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (pId > 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DescriptionPageScreen(productId: pId, colorId: "0"),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with Remove Heart Button
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      color: const Color(0xFFF8FAFC),
                      child: (item.image != null && item.image!.isNotEmpty)
                          ? Image.network(
                              "${AppAssetImage.imageBaseUrl}storage/app/public/${item.image}",
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFFCBD5E1)),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFFCBD5E1)),
                            ),
                    ),
                  ),

                  // Heart / Remove from Wishlist icon
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await wishProv.quickRemoveWishlist(
                            context: context,
                            wishlistId: wId.toString(),
                            productId: pId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Removed from Wishlist", style: GoogleFonts.poppins(fontSize: 12)),
                                duration: const Duration(milliseconds: 1000),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          }
                        },
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 17,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.brand != null && item.brand!.isNotEmpty) ...[
                        Text(
                          item.brand!.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],

                      Text(
                        item.name ?? "Factory Product",
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Pack size badge
                      if (packSize.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            packSize,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Price Row + Quick ADD Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDiscount)
                                Text(
                                  "\u20B9${oldPrice.toStringAsFixed(0)}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.5,
                                    decoration: TextDecoration.lineThrough,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              Text(
                                "\u20B9${price.toStringAsFixed(0)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),

                          // Add To Cart button
                          InkWell(
                            onTap: () async {
                              if (isAdded) return;
                              HapticFeedback.lightImpact();
                              setState(() => _addedToCartPids.add(pId));

                              final cartProv = Provider.of<CartScreenProvider>(context, listen: false);
                              await cartProv.quickAddToCart(
                                context: context,
                                productId: pId.toString(),
                                brandId: item.brandid?.toString() ?? "0",
                                attributeId: attrId?.toString(),
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF16A34A),
                                    duration: const Duration(milliseconds: 1400),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Added to Cart!",
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isAdded ? const Color(0xFF16A34A) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isAdded ? const Color(0xFF16A34A) : AppColors.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAdded ? Icons.check_rounded : Icons.add_rounded,
                                    size: 13,
                                    color: isAdded ? Colors.white : AppColors.primaryColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    isAdded ? "ADDED" : "ADD",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isAdded ? Colors.white : AppColors.primaryColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 44,
                color: Color(0xFFE11D48),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Wishlist is Empty",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Save your favorite factory direct paints, primers, fabrics and hardware items by tapping the heart icon on any product card.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                "Explore Factory Products",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
