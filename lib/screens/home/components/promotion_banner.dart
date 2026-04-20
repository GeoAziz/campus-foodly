import 'package:flutter/material.dart';

import '../../../core/constants.dart';

class PromotionBanner extends StatelessWidget {
  const PromotionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: AspectRatio(
          aspectRatio: 1.97,
          child: Image.asset(
            'assets/images/Banner.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
