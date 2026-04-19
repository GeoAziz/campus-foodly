import 'package:flutter/material.dart';
import '../../app_image.dart';

class BigCardImage extends StatelessWidget {
  const BigCardImage({
    super.key,
    required this.image,
    this.heroTag,
  });

  final String image;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: SizedBox.expand(
        child: AppImage(source: image, fit: BoxFit.cover),
      ),
    );

    if (heroTag == null) {
      return child;
    }

    return Hero(tag: heroTag!, child: child);
  }
}
