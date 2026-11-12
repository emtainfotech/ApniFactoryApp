import 'package:apni_factory/model/user_cart_model.dart';
import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/widgets/add_address_widget.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:apni_factory/screens/Coupon_offer_screen.dart';
import 'package:apni_factory/screens/description_page_screen.dart';
import 'package:apni_factory/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CartScreenProvider>(context, listen: false);
      provider.getAddressList(context: context);
      provider.relatedProduct(context: context);
      provider.userCart(context: context);
      provider.stateDropDown(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
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
        title: Consumer<CartScreenProvider>(
          builder: (context, provider, child) {
            final int itemCount = provider.userCartModel?.counter ?? 0;
            return Row(
              children: [
                Text(
                  "Wholesale Cart",
                  style: GoogleFonts.poppins(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                if (itemCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$itemCount items",
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          Consumer<CartScreenProvider>(
            builder: (context, provider, child) {
              final bool hasItems = provider.userCartModel?.data != null &&
                  provider.userCartModel!.data.isNotEmpty;
              if (!hasItems) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: const Color(0xFFFEE2E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _confirmClearCart(context, provider, height),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: Text(
                      "Clear",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartScreenProvider>(
        builder: (context, provider, child) {
          // Only show full-screen spinner on INITIAL load
          if (provider.loadingUserCart && provider.userCartModel == null) {
            return const CircularProgressIndicatorWidget();
          }

          final cartData = provider.userCartModel?.data;
          final bool isCartEmpty = (cartData == null || cartData.isEmpty);

          if (isCartEmpty) {
            return _buildEmptyCartView(context, width, height);
          }

          return Stack(
            children: [
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 140),
                children: [
                  // 1. Delivery Destination Address Card
                  _buildDeliveryAddressBanner(context, provider, width),

                  // 1b. Seller Minimum Order Value (MOV) & Multi-Seller Compliance
                  if (provider.userCartModel?.sellerGroups != null &&
                      provider.userCartModel!.sellerGroups!.isNotEmpty)
                    _buildSellerMovSection(context, provider.userCartModel!.sellerGroups!, width),

                  // 2. Cart Items Grouped by Category/Manufacturer
                  _buildCartItemsSection(context, provider, cartData, width, height),

                  // 3. Last Minute Add-ons / Related Factory Products
                  if (provider.relatedProductModel?.data != null &&
                      provider.relatedProductModel!.data!.isNotEmpty)
                    _buildRelatedProductsSection(context, provider, width, height),

                  // 4. Coupons & Savings Corner
                  _buildSavingsCorner(context, provider, width),

                  // 5. Bill Details Breakdown Card
                  _buildBillDetailsCard(context, provider, width),

                  // 6. B2B Wholesale Trust Pills
                  _buildB2BTrustBanner(),

                  const SizedBox(height: 20),
                ],
              ),

              // Fixed Bottom Checkout Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomCheckoutBar(context, provider, width, height),
              ),
            ],
          );
        },
      ),
    );
  }

  // 1. Delivery Address Banner
  Widget _buildDeliveryAddressBanner(
      BuildContext context, CartScreenProvider provider, double width) {
    final String currentAddress =
        provider.selectedAddressText ?? "Select Factory / Transport Site";

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffECEEF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showAddressBottomSheet(context, provider),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Color(0xFFEA580C),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        "Dispatch Destination",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9A3412),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "GST Transport",
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    currentAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xffF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Change",
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
  }

  // 1b. Seller Minimum Order Value (MOV) Status Cards
  Widget _buildSellerMovSection(
    BuildContext context,
    List<SellerGroupModel> sellerGroups,
    double width,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text(
                "Manufacturer Minimum Order Value (MOV)",
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...sellerGroups.map((group) {
            final bool hasMov = group.configuredMov > 0;
            final bool isMet = group.isMovSatisfied || !hasMov;
            final double progressFraction = (group.movProgressPercentage / 100.0).clamp(0.0, 1.0).toDouble();

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMet ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMet ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          group.companyName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isMet ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isMet ? "✓ MOV MET" : "SHORTFALL: ₹${group.movShortfall.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (hasMov) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "Subtotal: ₹${group.sellerSubtotal.toStringAsFixed(2)}",
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "Target MOV: ₹${group.configuredMov.toStringAsFixed(2)}",
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        minHeight: 6,
                        backgroundColor: isMet ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMet ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMet
                          ? "Order threshold met for factory direct dispatch."
                          : "Add ₹${group.movShortfall.toStringAsFixed(2)} more of ${group.companyName} products to qualify for checkout.",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isMet ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ] else ...[
                    Text(
                      "No Minimum Order Value required by this manufacturer.",
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF15803D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.local_shipping_outlined,
                            size: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Freight calculated & payable separately before final dispatch.",
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 2. Cart Items Grouped by Category/Manufacturer
  Widget _buildCartItemsSection(
    BuildContext context,
    CartScreenProvider provider,
    Map<String, List<List<ProductCategory>>> cartData,
    double width,
    double height,
  ) {
    return Column(
      children: cartData.entries.map((categoryEntry) {
        final String categoryName = categoryEntry.key;
        final List<List<ProductCategory>> productGroupList = categoryEntry.value;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffECEEF1)),
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
              // Category Header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        categoryName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                    ),
                    Text(
                      "Direct Factory",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),

              // Products in this Category
              ...productGroupList.expand((productList) {
                return productList.map((product) {
                  return _buildProductCartCard(
                    context,
                    provider,
                    product,
                    width,
                    height,
                  );
                });
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Individual Product Card in Cart
  Widget _buildProductCartCard(
    BuildContext context,
    CartScreenProvider provider,
    ProductCategory product,
    double width,
    double height,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF9FAFB), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: (product.productImage.isNotEmpty &&
                          product.productImage != "default.png")
                      ? Image.network(
                          "${AppAssetImage.imageBaseUrl}storage/app/public/${product.productImage}",
                          fit: BoxFit.cover,
                          cacheWidth: 150,
                          cacheHeight: 150,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImageFallback(),
                        )
                      : _buildImageFallback(),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Delete Entire Product
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Factory Pack: ${product.attributeData.length} Variant${product.attributeData.length > 1 ? "s" : ""}",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Delete entire product button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFF9CA3AF), size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  provider.deleteCart(
                    context: context,
                    globalcontext: context,
                    height: height,
                    cartid: product.cartid.toString(),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Variants / Boxpackings list
          Column(
            children: product.attributeData.map((attribute) {
              return _buildAttributeRow(
                context,
                provider,
                product,
                attribute,
                height,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Variant / Attribute Row with IN-PLACE quantity stepper (NO screen reload!)
  Widget _buildAttributeRow(
    BuildContext context,
    CartScreenProvider provider,
    ProductCategory product,
    AttributeData attribute,
    double height,
  ) {
    final String attrId = attribute.attributeid.toString();
    final bool isUpdating = provider.isAttributeUpdating(attrId);
    final int qty = attribute.qty ?? 1;
    final num unitPrice = (attribute.unitprice != null && attribute.unitprice! > 0)
        ? attribute.unitprice!
        : (attribute.prprice ?? 0);
    final num rowTotal = attribute.totalPrice ?? (unitPrice * qty);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          // Pack Size & Shade Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Text(
                        "${attribute.boxPacking} (${attribute.boxpcs ?? 1} pcs/box)",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC2410C),
                        ),
                      ),
                    ),
                    if (attribute.color.isNotEmpty && attribute.color != "null")
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          attribute.color,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${unitPrice is int ? unitPrice.toString() : (unitPrice.toDouble() == unitPrice.toInt() ? unitPrice.toInt().toString() : unitPrice.toStringAsFixed(2))} / pcs",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),

          // In-Place Quantity Stepper (Zero Screen Reload!)
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUpdating
                    ? AppColors.primaryColor.withOpacity(0.5)
                    : const Color(0xFFD1D5DB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrement Button
                InkWell(
                  onTap: isUpdating
                      ? null
                      : () {
                          provider.decreaseCartQuantity(
                            context: context,
                            height: height,
                            cartid: attrId,
                            qty: qty.toString(),
                            globalcontext: context,
                          );
                        },
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: Container(
                    width: 30,
                    height: 34,
                    alignment: Alignment.center,
                    child: Icon(
                      qty == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                      size: 16,
                      color: qty == 1
                          ? const Color(0xFFEF4444)
                          : AppColors.secondaryColor,
                    ),
                  ),
                ),

                // Quantity Number
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    qty.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isUpdating
                          ? AppColors.primaryColor
                          : AppColors.secondaryColor,
                    ),
                  ),
                ),

                // Increment Button
                InkWell(
                  onTap: isUpdating
                      ? null
                      : () {
                          provider.increaseCartQuantity(
                            context: context,
                            height: height,
                            cartid: attrId,
                            qty: qty.toString(),
                          );
                        },
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: Container(
                    width: 30,
                    height: 34,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Total Row Price
          Expanded(
            child: Text(
              "₹${rowTotal is int ? rowTotal.toString() : (rowTotal.toDouble() == rowTotal.toInt() ? rowTotal.toInt().toString() : rowTotal.toStringAsFixed(2))}",
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Related Products Section
  Widget _buildRelatedProductsSection(
    BuildContext context,
    CartScreenProvider provider,
    double width,
    double height,
  ) {
    final relatedList = provider.relatedProductModel?.data ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffECEEF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Color(0xFFEA580C), size: 18),
              const SizedBox(width: 6),
              Text(
                "Frequently Added Together",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: relatedList.length,
              itemBuilder: (context, index) {
                final item = relatedList[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DescriptionPageScreen(
                          productId: item.id ?? 0,
                          colorId: item.colorid ?? "",
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (item.image != null && item.image!.isNotEmpty)
                              ? Image.network(
                                  "${AppAssetImage.imageBaseUrl}storage/app/public/${item.image}",
                                  height: 55,
                                  width: 55,
                                  fit: BoxFit.cover,
                                  cacheWidth: 100,
                                  cacheHeight: 100,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildImageFallback(),
                                )
                              : _buildImageFallback(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.name ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        Text(
                          "₹${item.price ?? ""}",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF92400E),
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

  // 4. Coupons & Savings Corner
  Widget _buildSavingsCorner(
      BuildContext context, CartScreenProvider provider, double width) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffECEEF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_rounded,
                  color: AppColors.primaryColor, size: 18),
              const SizedBox(width: 6),
              Text(
                "Wholesale Discounts & Coupons",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Admin / Factory Coupon
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CouponOfferScreen(couponof: "admin"),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.percent_rounded,
                        color: AppColors.primaryColor, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Apply Factory Coupon",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        Text(
                          "Direct discounts on volume billing",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF), size: 20),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Seller / Brand Coupon
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CouponOfferScreen(couponof: "seller"),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sell_rounded,
                        color: Color(0xFF16A34A), size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Apply Seller Coupon",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        Text(
                          "Exclusive manufacturer promotions",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF), size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Bill Details Breakdown Card
  Widget _buildBillDetailsCard(
      BuildContext context, CartScreenProvider provider, double width) {
    final cart = provider.userCartModel;
    final num netAmount = cart?.netamount ?? 0;
    final num cgst = cart?.cgst ?? 0;
    final num sgst = cart?.sgst ?? 0;
    final num igst = cart?.igst ?? 0;
    final num grandTotal = cart?.grandTotal ?? 0;
    final String couponDiscount = cart?.combinecoupon ?? "0";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffECEEF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  color: AppColors.secondaryColor, size: 18),
              const SizedBox(width: 6),
              Text(
                "Bill Summary",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildBillRow("Subtotal (Excl. Taxes)", "₹$netAmount"),

          if (igst > 0)
            _buildBillRow("IGST (18%)", "+ ₹${igst.toStringAsFixed(2)}")
          else ...[
            _buildBillRow("CGST (9%)", "+ ₹${cgst.toStringAsFixed(2)}"),
            _buildBillRow("SGST (9%)", "+ ₹${sgst.toStringAsFixed(2)}"),
          ],

          if (couponDiscount != "0" && couponDiscount.isNotEmpty)
            _buildBillRow("Coupon Discount", "- ₹$couponDiscount",
                isGreen: true),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFE5E7EB)),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Amount",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  Text(
                    "Inclusive of all GST taxes",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Text(
                "₹${grandTotal.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isGreen ? const Color(0xFF16A34A) : AppColors.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // 6. B2B Wholesale Trust Pills
  Widget _buildB2BTrustBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustPill(Icons.verified_rounded, "GST Invoice"),
          _buildTrustPill(Icons.local_shipping_rounded, "Factory Dispatch"),
          _buildTrustPill(Icons.security_rounded, "Secure Escrow"),
        ],
      ),
    );
  }

  Widget _buildTrustPill(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFD97706)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF92400E),
          ),
        ),
      ],
    );
  }

  // Fixed Floating Bottom Checkout Action Bar
  Widget _buildBottomCheckoutBar(
    BuildContext context,
    CartScreenProvider provider,
    double width,
    double height,
  ) {
    final num grandTotal = provider.userCartModel?.grandTotal ?? 0;
    final int count = provider.userCartModel?.counter ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Amount Summary
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹${grandTotal.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  Text(
                    "$count Items • Incl. GST",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),

            // Checkout Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                final List<SellerGroupModel> shortfalls = provider.userCartModel?.sellerGroups
                        ?.where((g) => !g.isMovSatisfied && g.configuredMov > 0)
                        .toList() ??
                    [];

                if (shortfalls.isNotEmpty) {
                  _showMovShortfallDialog(context, shortfalls);
                  return;
                }

                if (provider.selectedAddressId == null) {
                  Utils.commonSnackBar(
                    context,
                    height: height,
                    message: "Please select delivery address first",
                  );
                  _showAddressBottomSheet(context, provider);
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckOutScreen()),
                );
              },
              child: Row(
                children: [
                  Text(
                    "PROCEED TO PAY",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMovShortfallDialog(BuildContext context, List<SellerGroupModel> shortfalls) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Minimum Order Value Shortfall",
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "One or more manufacturers require a Minimum Order Value before factory direct dispatch:",
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              ...shortfalls.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "• ${s.companyName}: Shortfall of ₹${s.movShortfall.toStringAsFixed(2)} (Target MOV: ₹${s.configuredMov.toStringAsFixed(2)})",
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "ADD MORE ITEMS",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  // Empty Cart State
  Widget _buildEmptyCartView(BuildContext context, double width, double height) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Wholesale Cart is Empty",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Explore factory-direct paints and materials at contractor wholesale prices.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
              label: Text(
                "Explore Factory Products",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Center(
      child: Image.asset(
        AppAssetImage.logo,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
      ),
    );
  }

  // Address Selection Bottom Sheet
  void _showAddressBottomSheet(BuildContext context, CartScreenProvider provider) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return Container(
          height: height * 0.72,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Choose Dispatch Destination",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Add New Address Button
              InkWell(
                onTap: () {
                  Navigator.pop(sheetContext);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => AddAddressWidget(provider: provider),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_location_alt_rounded,
                          color: Color(0xFF1D4ED8), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        "Add New Transport / Site Address",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Existing Addresses List
              Expanded(
                child: ListView.builder(
                  itemCount: provider.getAddressListModel?.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    final address = provider.getAddressListModel!.data![index];
                    if (address.type != "transport") return const SizedBox.shrink();

                    final isSelected =
                        (provider.selectedAddressId == address.id.toString());

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEA580C)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        value: address.id.toString(),
                        groupValue: provider.selectedAddressId,
                        activeColor: const Color(0xFFEA580C),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        onChanged: (val) {
                          if (val != null) {
                            final String addrText =
                                "${address.landmark1 ?? ""}, ${address.landmark2 ?? ""}, "
                                "${address.city ?? ""}, ${address.state ?? ""}, "
                                "${address.pincode ?? ""}";
                            provider.selectAddress(
                              val,
                              context: context,
                              height: height,
                              addressId: val,
                              addressText: addrText,
                            );
                            Navigator.pop(sheetContext);
                          }
                        },
                        title: Text(
                          address.identityname ?? "Site Location",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.name ?? "",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                            Text(
                              "${address.landmark1 ?? ""} ${address.landmark2 ?? ""}, ${address.city ?? ""}, ${address.state ?? ""} - ${address.pincode ?? ""}",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
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
      },
    );
  }

  // Clear Cart Confirmation Dialog
  void _confirmClearCart(
      BuildContext context, CartScreenProvider provider, double height) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Clear Wholesale Cart?",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Text(
            "Are you sure you want to remove all items from your cart?",
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF4B5563)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                provider.emptyCart(
                  context: context,
                  globalcontext: context,
                  height: height,
                );
              },
              child: Text(
                "Clear Cart",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
