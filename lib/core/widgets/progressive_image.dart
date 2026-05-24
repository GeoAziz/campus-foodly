import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Helper widget for progressive image loading with placeholder
class ProgressiveImage extends StatelessWidget {
  const ProgressiveImage({
    Key? key,
    required this.imageUrl,
    this.height = 200,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.placeholderColor = Colors.grey,
    this.errorBuilder,
  }) : super(key: key);

  final String imageUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final Color placeholderColor;
  final Widget Function(BuildContext, String, Object)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (context, url) => Container(
          color: placeholderColor.withOpacity(0.2),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                placeholderColor.withOpacity(0.5),
              ),
            ),
          ),
        ),
        errorWidget: errorBuilder ??
            (context, url, error) => Container(
                  color: placeholderColor.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: placeholderColor.withOpacity(0.7),
                    ),
                  ),
                ),
        fadeInDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

/// Extension to easily create progressive images with theme colors
extension ProgressiveImageBuilder on BuildContext {
  Widget progressiveImage(
    String url, {
    double height = 200,
    double width = double.infinity,
    BoxFit fit = BoxFit.cover,
  }) {
    return ProgressiveImage(
      imageUrl: url,
      height: height,
      width: width,
      fit: fit,
      placeholderColor: Theme.of(this).colorScheme.outline,
    );
  }
}
