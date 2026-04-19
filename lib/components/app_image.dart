import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String? source;
  final BoxFit fit;
  final double? width;
  final double? height;

  static bool isNetworkSource(String value) {
    final normalized = value.trim();
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final normalized = source?.trim() ?? '';
    if (normalized.isEmpty) {
      return _fallback();
    }

    if (isNetworkSource(normalized)) {
      final localAssetFallback = _assetPathFromCloudinaryUrl(normalized);
      return Image.network(
        normalized,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) {
          if (localAssetFallback != null) {
            return Image.asset(
              localAssetFallback,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => _fallback(),
            );
          }

          return _fallback();
        },
      );
    }

    return Image.asset(
      normalized,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  String? _assetPathFromCloudinaryUrl(String url) {
    final marker = '/assets/';
    final markerIndex = url.indexOf(marker);
    if (markerIndex < 0) {
      return null;
    }

    var path = url.substring(markerIndex + 1);
    final queryIndex = path.indexOf('?');
    if (queryIndex >= 0) {
      path = path.substring(0, queryIndex);
    }

    if (path.isEmpty || !path.startsWith('assets/')) {
      return null;
    }

    return path;
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F1F1),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }
}
