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
    final String url = (imageUrl ?? '').trim();
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
          color: AppColors.greyColor.withOpacity(0.25),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryColor,
            ),
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
      color: AppColors.greyColor.withOpacity(0.2),
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: Colors.grey.shade500,
        size: 24,
      ),
    );
  }
}
