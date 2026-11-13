import 'package:apni_factory/api_services/notification_services.dart';
import 'package:apni_factory/model/notification_model.dart';
import 'package:apni_factory/provider/homeScreen_provider.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:apni_factory/res/widgets/circular_progress_indicator_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    await Provider.of<HomeScreenProvider>(context, listen: false)
        .notification(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notification Center",
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Refresh notifications",
            icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF64748B)),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadNotifications();
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildFilterChips(),
        ),
      ),
      body: Consumer<HomeScreenProvider>(
        builder: (context, provider, child) {
          if (provider.loadingNotification) {
            return const Center(
              child: CircularProgressIndicatorWidget(),
            );
          }

          final allList = provider.notificationModel?.data ?? [];
          final filteredList = _getFilteredList(allList);

          if (filteredList.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: _loadNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: filteredList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return _buildNotificationCard(item);
              },
            ),
          );
        },
      ),
    );
  }

  // Filter chips row
  Widget _buildFilterChips() {
    final filters = ['All', 'Orders', 'Offers & Deals', 'System'];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _activeFilter == f;
          return ChoiceChip(
            label: Text(f),
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            selected: isSelected,
            selectedColor: AppColors.primaryColor,
            backgroundColor: const Color(0xFFF1F5F9),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (val) {
              if (val) {
                HapticFeedback.selectionClick();
                setState(() => _activeFilter = f);
              }
            },
          );
        },
      ),
    );
  }

  List<Data> _getFilteredList(List<Data> list) {
    if (_activeFilter == 'Orders') {
      return list.where((item) {
        final t = (item.title ?? '').toLowerCase();
        final b = (item.body ?? '').toLowerCase();
        final sc = (item.screen ?? '').toLowerCase();
        return t.contains('order') || b.contains('order') || sc.contains('order');
      }).toList();
    } else if (_activeFilter == 'Offers & Deals') {
      return list.where((item) {
        final t = (item.type ?? '').toLowerCase();
        final sc = (item.screen ?? '').toLowerCase();
        return t == 'promo' || t == 'broadcast' || sc == 'coupon' || sc == 'product';
      }).toList();
    } else if (_activeFilter == 'System') {
      return list.where((item) {
        final t = (item.type ?? '').toLowerCase();
        return t == 'system' || t.isEmpty;
      }).toList();
    }
    return list;
  }

  // Modern Card
  Widget _buildNotificationCard(Data item) {
    final bool isUnread = (item.msgread ?? 0) == 0;
    final String type = (item.type ?? 'system').toLowerCase();
    final bool hasImage = item.image != null && item.image!.isNotEmpty;
    final bool hasDeepLink = item.screen != null &&
        item.screen!.isNotEmpty &&
        item.screen!.toLowerCase() != 'none';

    IconData iconData = Icons.notifications_active_rounded;
    Color iconBg = const Color(0xFFEFF6FF);
    Color iconColor = const Color(0xFF2563EB);

    if (type == 'order' || (item.title ?? '').toLowerCase().contains('order')) {
      iconData = Icons.local_shipping_rounded;
      iconBg = const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF16A34A);
    } else if (type == 'promo' || type == 'broadcast' || (item.title ?? '').toLowerCase().contains('sale')) {
      iconData = Icons.local_fire_department_rounded;
      iconBg = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFEA580C);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (hasDeepLink) {
            NotificationServices().handleNotificationNavigation({
              'screen': item.screen,
              'screenid': item.screenid ?? item.deepLink,
            });
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFFFFBF0) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Icon + Title + Time Ago + Unread dot)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title ?? "Notification",
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (item.timeAgo != null || item.createdAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.timeAgo ?? (item.createdAt ?? ''),
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isUnread) ...[
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA580C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Message Body
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  item.body ?? "",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.4,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),

              // Optional Banner Image
              if (hasImage) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.image!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],

              // Deep Link Action Pill
              if (hasDeepLink) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getActionLabel(item.screen),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEA580C),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: Color(0xFFEA580C),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getActionLabel(String? screen) {
    switch (screen?.toLowerCase()) {
      case 'product':
        return 'View Product';
      case 'category':
        return 'Explore Category';
      case 'brand':
        return 'View Brand Factory';
      case 'coupon':
        return 'View Offers';
      case 'orders':
      case 'orderdetail':
        return 'Track Order';
      case 'wishlist':
        return 'View Wishlist';
      default:
        return 'View Details';
    }
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 38,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You're all caught up!",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "No notifications in this category. We'll update you when factory updates or deals arrive.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
