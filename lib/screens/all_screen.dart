import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/screens/cart_screen.dart';
import 'package:apni_factory/screens/home_screen.dart';
import 'package:apni_factory/screens/profile_screen.dart';
import 'package:apni_factory/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AllScreen extends StatefulWidget {
  const AllScreen({super.key});

  @override
  State<AllScreen> createState() => _AllScreenState();
}

class _AllScreenState extends State<AllScreen> {
  int selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    WishlistScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<CartScreenProvider>(
      builder: (context, cartProvider, child) {
        final int cartCount = cartProvider.userCartModel?.data?.length ?? 0;
        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.storefront_outlined,
                      activeIcon: Icons.storefront_rounded,
                      label: "Home",
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.favorite_border_rounded,
                      activeIcon: Icons.favorite_rounded,
                      label: "Wishlist",
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.shopping_bag_outlined,
                      activeIcon: Icons.shopping_bag_rounded,
                      label: "Cart",
                      badgeCount: cartCount,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: "Account",
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () {
        if (selectedIndex != index) {
          setState(() {
            selectedIndex = index;
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 24,
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.lightText,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? "9+" : "$badgeCount",
                          style: GoogleFonts.poppins(
                            color: AppColors.whiteColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
