import 'package:apni_factory/provider/cart_screen_provider.dart';
import 'package:apni_factory/provider/homeScreen_provider.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/textstyle.dart';
import 'package:apni_factory/res/widgets/add_address_widget.dart';
import 'package:apni_factory/res/widgets/personal_add_address_widget.dart';
import 'package:apni_factory/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProv = Provider.of<HomeScreenProvider>(context, listen: false);
      homeProv.getAddressList(context: context);
      homeProv.stateDropDown(context: context);

      final cartProv = Provider.of<CartScreenProvider>(context, listen: false);
      cartProv.getAddressList(context: context);
      cartProv.stateDropDown(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          "My Addresses",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.secondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<HomeScreenProvider>(
        builder: (context, homeProvider, child) {
          final cartProvider = Provider.of<CartScreenProvider>(context, listen: false);

          if (homeProvider.loadingGetAddressList) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          final allAddresses = homeProvider.getAddressListModel?.data ?? [];
          final personalAddresses = allAddresses.where((e) => e.type == "personal").toList();
          final deliveryAddresses = allAddresses.where((e) => e.type != "personal").toList();

          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () async {
              await homeProvider.getAddressList(context: context);
              await cartProvider.getAddressList(context: context);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // SECTION 1: COMMUNICATION ADDRESS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Communication Address",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    if (personalAddresses.isEmpty)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => PersonalAddAddressWidget(provider: homeProvider),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16, color: AppColors.primaryColor),
                        label: Text(
                          "Add",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (personalAddresses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF9CA3AF), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Communication address is not added yet.",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...personalAddresses.map((addr) => _buildAddressCard(
                        context: context,
                        height: height,
                        address: addr,
                        isPersonal: true,
                        onEdit: () {
                          homeProvider.getIdAddress(
                            context: context,
                            addressId: addr.id.toString(),
                          );
                        },
                        onDelete: () {
                          Utils.commonShowDialog(
                            context: context,
                            height: height,
                            title: "Are you sure you want to remove this communication address?",
                            cancelButton: () => Navigator.pop(context),
                            okayButton: () {
                              homeProvider.deleteAddress(
                                context: context,
                                dialogContext: context,
                                height: height,
                                addressid: addr.id.toString(),
                              );
                            },
                          );
                        },
                      )),

                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 20),

                // SECTION 2: DELIVERY / TRANSPORT ADDRESSES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Delivery / Site Addresses",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AddAddressWidget(provider: cartProvider),
                        );
                      },
                      icon: const Icon(Icons.add_location_alt_outlined, size: 16, color: AppColors.primaryColor),
                      label: Text(
                        "Add New",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (deliveryAddresses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.local_shipping_outlined, color: Color(0xFF9CA3AF), size: 36),
                        const SizedBox(height: 10),
                        Text(
                          "No delivery address added yet.",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => AddAddressWidget(provider: cartProvider),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16, color: Colors.white),
                          label: Text(
                            "Add Delivery Location",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...deliveryAddresses.map((addr) => _buildAddressCard(
                        context: context,
                        height: height,
                        address: addr,
                        isPersonal: false,
                        onEdit: () {
                          cartProvider.getIdAddress(
                            context: context,
                            addressId: addr.id.toString(),
                          );
                        },
                        onDelete: () {
                          Utils.commonShowDialog(
                            context: context,
                            height: height,
                            title: "Are you sure you want to remove this delivery address?",
                            cancelButton: () => Navigator.pop(context),
                            okayButton: () {
                              cartProvider.deleteAddress(
                                context: context,
                                dialogContext: context,
                                height: height,
                                addressid: addr.id.toString(),
                              );
                            },
                          );
                        },
                      )),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressCard({
    required BuildContext context,
    required double height,
    required dynamic address,
    required bool isPersonal,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final title = (address.identityname != null && address.identityname.toString().trim().isNotEmpty)
        ? address.identityname.toString().trim()
        : (isPersonal ? "Home / Office" : "Transport / Site");

    final name = (address.name != null && address.name.toString().trim().isNotEmpty)
        ? address.name.toString().trim()
        : "";

    final parts = [
      if (address.landmark1 != null && address.landmark1.toString().trim().isNotEmpty)
        address.landmark1.toString().trim(),
      if (address.landmark2 != null && address.landmark2.toString().trim().isNotEmpty)
        address.landmark2.toString().trim(),
      if (address.city != null && address.city.toString().trim().isNotEmpty)
        address.city.toString().trim(),
      if (address.state != null && address.state.toString().trim().isNotEmpty)
        address.state.toString().trim(),
      if (address.country != null && address.country.toString().trim().isNotEmpty)
        address.country.toString().trim(),
    ];
    final fullAddress = parts.join(", ");
    final pincode = address.pincode != null ? address.pincode.toString().trim() : "";
    final phone = address.phoneno != null ? address.phoneno.toString().trim() : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPersonal ? const Color(0xFFEFF6FF) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPersonal ? const Color(0xFF1D4ED8) : const Color(0xFFEA580C),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4B5563)),
                onPressed: onEdit,
                tooltip: "Edit Address",
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                onPressed: onDelete,
                tooltip: "Delete Address",
              ),
            ],
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            pincode.isNotEmpty ? "$fullAddress - $pincode" : fullAddress,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.4,
              color: const Color(0xFF4B5563),
            ),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  phone,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
