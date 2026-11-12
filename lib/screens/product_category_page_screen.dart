import 'dart:developer';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/product_category_list_screen_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/widgets/app_network_image.dart';
import 'package:apni_factory/res/widgets/app_state_views.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:apni_factory/res/widgets/global_cart_container.dart';
import 'package:apni_factory/screens/cart_screen.dart';
import 'package:apni_factory/screens/description_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProductCategoryPageScreen extends StatefulWidget {
  final int bid;
  final int cid;
  final int scid;
  final int cmpid;
  const ProductCategoryPageScreen({
    super.key,
    required this.bid,
    required this.cid,
    this.scid = 0,
    this.cmpid = 0,
  });

  @override
  State<ProductCategoryPageScreen> createState() =>
      _ProductCategoryPageScreenState();
}

class _ProductCategoryPageScreenState extends State<ProductCategoryPageScreen> {
  final Set<int> _addedProductIds = {};
  final ScrollController _gridScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _gridScrollController.addListener(_onGridScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _onGridScroll() {
    if (!_gridScrollController.hasClients || !mounted) return;
    final pos = _gridScrollController.position;
    if (pos.maxScrollExtent - pos.pixels <= 250) {
      Provider.of<ProductCategoryListScreenProvider>(context, listen: false)
          .loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _gridScrollController.removeListener(_onGridScroll);
    _gridScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider =
        Provider.of<ProductCategoryListScreenProvider>(context, listen: false);
    final cartProvider =
        Provider.of<CartScreenProvider>(context, listen: false);

    provider.resetState();
    await provider.productCategoryListScreen(
      context: context,
      bid: widget.bid,
      cid: widget.cid,
      scid: widget.scid,
      cmpid: widget.cmpid,
    );
    await cartProvider.userCart(context: context, isSilent: true);
  }

  void _handleQuickAdd(
    BuildContext context,
    int productId,
    String brandId,
    String productName,
  ) async {
    final cartProvider = Provider.of<CartScreenProvider>(context, listen: false);
    setState(() {
      _addedProductIds.add(productId);
    });

    final success = await cartProvider.quickAddToCart(
      context: context,
      productId: productId.toString(),
      brandId: brandId,
    );

    if (mounted) {
      if (!success) {
        setState(() {
          _addedProductIds.remove(productId);
        });
      }
      if (success) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "$productName added to cart",
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
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: "VIEW CART",
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
          ),
        );
      }
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _addedProductIds.remove(productId);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 18, color: AppColors.secondaryColor),
          ),
          onPressed: () {
            Provider.of<ProductCategoryListScreenProvider>(context, listen: false)
                .resetState();
            Navigator.pop(context);
          },
        ),
        title: Consumer<ProductCategoryListScreenProvider>(
          builder: (context, provider, child) {
            final String companyName =
                provider.productListBySubCategoryScreenModel?.data?.companyName ??
                    provider.productCategoryListScreenModel?.data?.companyName ??
                    "";
            final String brandName =
                provider.productCategoryListScreenModel?.data?.brandname ?? "";
            final String title = companyName.isNotEmpty
                ? companyName
                : (brandName.isNotEmpty
                    ? brandName
                    : (provider.selectedCategory ?? "Products"));
            final String subtitle = companyName.isNotEmpty && brandName.isNotEmpty
                ? "$brandName • Single Company Store"
                : (companyName.isNotEmpty
                    ? "Verified Company Store"
                    : "Wholesale Factory Direct");
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF16A34A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<CartScreenProvider>(
            builder: (context, cartProvider, child) {
              final int count = cartProvider.userCartModel?.counter ?? 0;
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 18, color: Color(0xFFEA580C)),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            count.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
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
            },
          ),
        ],
      ),
      body: Consumer<ProductCategoryListScreenProvider>(
        builder: (context, provider, child) {
          if (provider.loadingProductCategoryListScreen) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          if (provider.errorMessage != null) {
            return AppErrorRetryView(
              message: provider.errorMessage!,
              onRetry: _loadData,
            );
          }

          final subcategories = (provider.subCategoryDetails != null &&
                  provider.subCategoryDetails!.isNotEmpty)
              ? provider.subCategoryDetails!
              : (provider.productCategoryListScreenModel?.data?.subcategory ??
                  []);
          final products = provider.productDetails ?? [];
          final visibleProducts = provider.paginatedProducts;

          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Subcategories Sidebar
                  if (subcategories.isNotEmpty)
                    Container(
                      width: 90,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: subcategories.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final subcat = subcategories[index];
                          final bool isSelected =
                              provider.selectedCategoryIndex == index;

                          return InkWell(
                            onTap: () {
                              provider.selectedSubCategory(
                                index: index,
                                context: context,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFF7ED)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFFEA580C)
                                        : Colors.transparent,
                                    width: 3.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFFFEDD5)
                                            : const Color(0xFFE5E7EB),
                                        width: 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFEA580C)
                                                    .withOpacity(0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: (subcat.image != null &&
                                              subcat.image.isNotEmpty &&
                                              subcat.image != "default.png")
                                          ? AppNetworkImage(
                                              imageUrl:
                                                  "${AppAssetImage.imageBaseUrl}storage/app/public/${subcat.image}",
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              fallbackIcon:
                                                  Icons.category_outlined,
                                            )
                                          : const Icon(
                                              Icons.category_outlined,
                                              size: 22,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subcat.name ?? "",
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFEA580C)
                                          : const Color(0xFF4B5563),
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Right: Products List / Grid
                  Expanded(
                    child: provider.loadingProductListBySubcategory
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          )
                        : products.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 40,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No Products Available",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Select another subcategory from the left",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.lightText,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Subcategory Header Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      border: Border(
                                        bottom: BorderSide(
                                            color: Color(0xFFEEEEEE), width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          provider.hasMoreProducts
                                              ? "Showing ${visibleProducts.length} of ${products.length}"
                                              : "${products.length} Products Found",
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            "FACTORY RATES",
                                            style: GoogleFonts.poppins(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF166534),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Products Grid
                                  Expanded(
                                    child: GridView.builder(
                                      controller: _gridScrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 10, 10, 80),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.58,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                      itemCount: visibleProducts.length,
                                      physics: const BouncingScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final prod = visibleProducts[index];
                                        final int pId = prod.pid ?? 0;
                                        final bool isAdded =
                                            _addedProductIds.contains(pId);

                                        return _buildProductCard(
                                          context,
                                          prod,
                                          isAdded,
                                        );
                                      },
                                    ),
                                  ),
                                  if (provider.hasMoreProducts)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Center(
                                        child: TextButton(
                                          onPressed: provider.loadMoreProducts,
                                          child: Text(
                                            'Load more products',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                  ),
                ],
              ),

              // Floating Global Cart Pill
              GlobalCartContainer(width: width, height: height),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    dynamic prod,
    bool isAdded,
  ) {
    final int pId = prod.pid ?? 0;
    final String colorId = prod.colorid?.toString() ?? "0";
    final num price = prod.price ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DescriptionPageScreen(
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
            // Thumbnail Image Area
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFAFA),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      child: (prod.image != null &&
                              prod.image.isNotEmpty &&
                              prod.image != "default.png")
                          ? AppNetworkImage(
                              imageUrl:
                                  "${AppAssetImage.imageBaseUrl}storage/app/public/${prod.image}",
                              fit: BoxFit.cover,
                              width: 160,
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

                  // Shade Dot / Swatch if available
                  if (prod.hexcode != null &&
                      prod.hexcode.toString().isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hexToColor(prod.hexcode.toString()),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Details Area (Tight spacing!)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod.name ?? "",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryColor,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "₹${price is int ? price.toString() : (price.toDouble() == price.toInt() ? price.toInt().toString() : price.toStringAsFixed(1))}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryColor,
                          ),
                        ),

                        // Quick Add Button with Animation (Zero Navigation!)
                        InkWell(
                          onTap: () {
                            _handleQuickAdd(
                              context,
                              pId,
                              widget.bid.toString(),
                              prod.name ?? "Product",
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAdded
                                  ? const Color(0xFF16A34A)
                                  : AppColors.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAdded
                                    ? const Color(0xFF16A34A)
                                    : AppColors.primaryColor.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAdded) ...[
                                  const Icon(Icons.check_rounded,
                                      size: 11, color: Colors.white),
                                  const SizedBox(width: 2),
                                ],
                                Text(
                                  isAdded ? "ADDED" : "ADD",
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isAdded
                                        ? Colors.white
                                        : AppColors.primaryColor,
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
}
