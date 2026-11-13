import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Interactive, reactive Cart Stepper button matching Swiggy / Blinkit design.
/// - Shows 'ADD +' when quantity in cart is 0.
/// - Transforms into solid green '[-] [qty] [+]' stepper when quantity > 0.
/// - Tapping '+' increments quantity directly with zero-reload optimistic update.
/// - Tapping '-' decrements quantity; at 1, removes from cart and reverts to 'ADD +'.
class ProductCartStepperButton extends StatelessWidget {
  final int productId;
  final String brandId;
  final String? attributeId;
  final bool isCompact;
  final bool isFullWidth;
  final VoidCallback? onAdded;

  const ProductCartStepperButton({
    super.key,
    required this.productId,
    required this.brandId,
    this.attributeId,
    this.isCompact = false,
    this.isFullWidth = false,
    this.onAdded,
  });

  @override
  Widget build(BuildContext context) {
    if (productId <= 0) return const SizedBox.shrink();

    return Consumer<CartScreenProvider>(
      builder: (context, cartProv, _) {
        final int qty = cartProv.getProductCartQty(productId);
        final int? cartAttrId = cartProv.getProductFirstCartAttributeId(productId);
        final bool isUpdating = cartAttrId != null &&
            cartProv.updatingAttributeIds.contains(cartAttrId.toString());
        final bool isAdding = cartProv.isProductAdding(productId);

        if (qty <= 0) {
          if (isAdding) {
            return Container(
              height: isCompact ? 28 : 32,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 20,
                vertical: isCompact ? 4 : 5.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF16A34A),
                  width: 1.3,
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            );
          }
          // ADD + Button
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final success = await cartProv.quickAddToCart(
                  context: context,
                  productId: productId.toString(),
                  brandId: (brandId.isNotEmpty && brandId != '0') ? brandId : '1',
                  attributeId: attributeId,
                );
                if (success && onAdded != null) {
                  onAdded!();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isFullWidth ? double.infinity : null,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 14,
                  vertical: isCompact ? 4 : 5.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF16A34A),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withOpacity(0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ADD',
                      style: GoogleFonts.poppins(
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.add_rounded,
                      size: isCompact ? 14 : 16,
                      color: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Active Added Stepper: [-] [qty] [+]
        final double screenHeight = MediaQuery.of(context).size.height;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isFullWidth ? double.infinity : null,
          height: isCompact ? 28 : 32,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Decrement / Delete
              InkWell(
                onTap: isUpdating
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        if (cartAttrId != null) {
                          await cartProv.decreaseCartQuantity(
                            context: context,
                            height: screenHeight,
                            cartid: cartAttrId.toString(),
                            qty: qty.toString(),
                          );
                        } else {
                          await cartProv.userCart(context: context, isSilent: true);
                        }
                      },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 5 : 7,
                    vertical: 4,
                  ),
                  child: Icon(
                    qty == 1
                        ? Icons.delete_outline_rounded
                        : Icons.remove_rounded,
                    size: isCompact ? 13 : 15,
                    color: Colors.white,
                  ),
                ),
              ),

              // Qty or Spinner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: isUpdating
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '$qty',
                        style: GoogleFonts.poppins(
                          fontSize: isCompact ? 11.5 : 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),

              // Increment
              InkWell(
                onTap: isUpdating
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        if (cartAttrId != null) {
                          await cartProv.increaseCartQuantity(
                            context: context,
                            height: screenHeight,
                            cartid: cartAttrId.toString(),
                            qty: qty.toString(),
                          );
                        } else {
                          await cartProv.userCart(context: context, isSilent: true);
                        }
                      },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 5 : 7,
                    vertical: 4,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: isCompact ? 14 : 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

