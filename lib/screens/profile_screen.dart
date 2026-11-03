import 'package:apni_factory/provider/homeScreen_provider.dart';
import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/screens/address_screen.dart';
import 'package:apni_factory/screens/change_password_screen.dart';
import 'package:apni_factory/screens/Coupon_offer_screen.dart';
import 'package:apni_factory/screens/faq_screen.dart';
import 'package:apni_factory/screens/order_history_screen.dart';
import 'package:apni_factory/screens/pages_screen.dart';
import 'package:apni_factory/screens/policies_screen.dart';
import 'package:apni_factory/screens/send_feedback_screen.dart';
import 'package:apni_factory/screens/sign_in.dart';
import 'package:apni_factory/screens/ticket_screen.dart';
import 'package:apni_factory/screens/web_vview_screen.dart';
import 'package:apni_factory/screens/wishlist_screen.dart';
import 'package:apni_factory/screens/your_profile_screen.dart';
import 'package:apni_factory/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userName;
  String? userEmail;
  String? userMobile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await SharedPref.getUserName();
    final email = await SharedPref.getUserEmailId();
    final mobile = await SharedPref.getUserMobile();
    if (mounted) {
      setState(() {
        userName = name;
        userEmail = email;
        userMobile = mobile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Sleek Gradient Hero App Bar / Header
          SliverToBoxAdapter(
            child: _buildProfileHero(context),
          ),

          // 2. Quick Stat Tiles Row (Orders, Wishlist, Coupons, Tickets)
          SliverToBoxAdapter(
            child: _buildQuickActionRow(context),
          ),

          // 3. Grouped Settings Sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader("MY PURCHASES & PREFERENCES"),
                _buildCardGroup([
                  _buildMenuTile(
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFFEA580C),
                    iconBg: const Color(0xFFFFF7ED),
                    title: "My Orders",
                    subtitle: "Track live shipments, invoices & reorders",
                    onTap: () => _navigate(context, const OrderHistoryScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.favorite_outline_rounded,
                    iconColor: const Color(0xFFE11D48),
                    iconBg: const Color(0xFFFFF1F2),
                    title: "Wishlist",
                    subtitle: "Your saved factory direct items",
                    onTap: () => _navigate(context, const WishlistScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFF0F9FF),
                    title: "Delivery Addresses",
                    subtitle: "Manage factory & delivery locations",
                    onTap: () => _navigate(context, const AddressScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.local_offer_outlined,
                    iconColor: const Color(0xFF16A34A),
                    iconBg: const Color(0xFFF0FDF4),
                    title: "Coupons & Discounts",
                    subtitle: "Active factory promotions & discount vouchers",
                    onTap: () => _navigate(context, const CouponOfferScreen(couponof: "customer")),
                    showDivider: false,
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionHeader("HELP & CUSTOMER CARE"),
                _buildCardGroup([
                  _buildMenuTile(
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFF5F3FF),
                    title: "Support Tickets",
                    subtitle: "Raise issues and view response status",
                    onTap: () => _navigate(context, const TicketScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFFFBEB),
                    title: "Help Center",
                    subtitle: "Guides and ordering assistance",
                    onTap: () => _navigate(context, const PagesScreen(slug: "helpforapp")),
                  ),
                  _buildMenuTile(
                    icon: Icons.quiz_outlined,
                    iconColor: const Color(0xFF0D9488),
                    iconBg: const Color(0xFFF0FDFA),
                    title: "Frequently Asked Questions",
                    subtitle: "Common questions & quick answers",
                    onTap: () => _navigate(context, const FaqScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.rate_review_outlined,
                    iconColor: const Color(0xFF475569),
                    iconBg: const Color(0xFFF1F5F9),
                    title: "Send Feedback",
                    subtitle: "Help us improve your factory buying experience",
                    onTap: () => _navigate(context, const SendFeedbackScreen()),
                    showDivider: false,
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionHeader("ABOUT & POLICIES"),
                _buildCardGroup([
                  _buildMenuTile(
                    icon: Icons.business_outlined,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFEFF6FF),
                    title: "About Apni Factory",
                    subtitle: "India's factory-direct industrial marketplace",
                    onTap: () => _navigate(context, const PagesScreen(slug: "aboutus")),
                  ),
                  _buildMenuTile(
                    icon: Icons.policy_outlined,
                    iconColor: const Color(0xFF475569),
                    iconBg: const Color(0xFFF1F5F9),
                    title: "Terms & Privacy Policies",
                    subtitle: "Usage conditions and privacy guarantee",
                    onTap: () => _navigate(
                      context,
                      PolicyScreen(
                        provider: Provider.of<HomeScreenProvider>(context, listen: false),
                      ),
                    ),
                  ),
                  _buildMenuTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEF2F2),
                    title: "Data Deletion Request",
                    subtitle: "Request deletion of user account data",
                    onTap: () => _navigate(context, const DataDeletionWebView()),
                    showDivider: false,
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionHeader("ACCOUNT SECURITY"),
                _buildCardGroup([
                  _buildMenuTile(
                    icon: Icons.lock_reset_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFEFF6FF),
                    title: "Change Password",
                    subtitle: "Update account access security",
                    onTap: () => _navigate(context, const ChangePasswordScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEF2F2),
                    title: "Log Out",
                    subtitle: "Sign out of your account on this device",
                    isDestructive: true,
                    onTap: () => _showLogoutDialog(context),
                    showDivider: false,
                  ),
                ]),

                const SizedBox(height: 30),
                // Footer Brand & Version
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        AppAssetImage.logo,
                        height: 24,
                        errorBuilder: (_, __, ___) => Text(
                          "APNI FACTORY",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Direct Factory Rates • Verified Manufacturers",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Version 1.0.0 (Build 2)",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Profile Hero Section
  Widget _buildProfileHero(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final initial = (userName?.isNotEmpty ?? false) ? userName![0].toUpperCase() : "U";

    return Container(
      padding: EdgeInsets.only(top: topPadding + 16, bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
            Color(0xFF334155), // Slate 700
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top bar: Title + Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Account",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: () => _navigate(context, const YourProfileScreen()),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Edit",
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Avatar + User Details
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name, Email/Phone, Verified Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName ?? "Factory Direct Buyer",
                      style: GoogleFonts.poppins(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      userMobile ?? (userEmail ?? "Member Account"),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF34D399)),
                          const SizedBox(width: 4),
                          Text(
                            "Verified B2B Direct Account",
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34D399),
                              letterSpacing: 0.3,
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
        ],
      ),
    );
  }

  // 2. Quick Action 4-Tiles Row
  Widget _buildQuickActionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildQuickTile(
            icon: Icons.inventory_2_rounded,
            label: "Orders",
            color: const Color(0xFFEA580C),
            onTap: () => _navigate(context, const OrderHistoryScreen()),
          ),
          const SizedBox(width: 10),
          _buildQuickTile(
            icon: Icons.favorite_rounded,
            label: "Wishlist",
            color: const Color(0xFFE11D48),
            onTap: () => _navigate(context, const WishlistScreen()),
          ),
          const SizedBox(width: 10),
          _buildQuickTile(
            icon: Icons.confirmation_number_rounded,
            label: "Coupons",
            color: const Color(0xFF16A34A),
            onTap: () => _navigate(context, const CouponOfferScreen(couponof: "customer")),
          ),
          const SizedBox(width: 10),
          _buildQuickTile(
            icon: Icons.headset_mic_rounded,
            label: "Support",
            color: const Color(0xFF7C3AED),
            onTap: () => _navigate(context, const TicketScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDestructive ? const Color(0xFFDC2626).withOpacity(0.7) : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 64,
            endIndent: 14,
            color: Color(0xFFF1F5F9),
          ),
      ],
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showLogoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              "Log Out of Apni Factory?",
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You can log back in anytime with your mobile number or credentials.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await SharedPref.setIsLoggedIn(false);
                      await SharedPref.clearToken();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => SignInScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Log Out",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
