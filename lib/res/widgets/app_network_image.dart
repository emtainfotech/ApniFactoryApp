import 'package:apni_factory/res/asset_image.dart';
import 'package:apni_factory/res/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Disk-and-memory cached network image widget with graceful broken-image fallback.
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_not_supported_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final String url = AppAssetImage.buildStorageImageUrl(imageUrl);
    Widget child;

    if (url.isEmpty ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      child = _fallbackBox();
    } else {
      final int? cacheW = (width != null && width!.isFinite && width! > 0)
          ? (width! * 2).round()
          : null;
      final int? cacheH = (height != null && height!.isFinite && height! > 0)
          ? (height! * 2).round()
          : null;

      child = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        placeholder: (context, _) => Container(
          width: width,
          height: height,
          color: const Color(0xFFF3F4F6),
          alignment: Alignment.center,
          child: Icon(
            fallbackIcon,
            color: const Color(0xFFD1D5DB),
            size: (width != null && width! < 60) ? 20 : 28,
          ),
        ),
        errorWidget: (context, _, __) => _fallbackBox(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }

  Widget _fallbackBox() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            fallbackIcon,
            color: const Color(0xFF94A3B8),
            size: (width != null && width! < 70) ? 20 : 28,
          ),
          if (width != null && width! >= 90) ...[
            const SizedBox(height: 3),
            const Text(
              'APNI FACTORY',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
