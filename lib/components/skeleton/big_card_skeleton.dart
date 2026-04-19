import 'package:flutter/material.dart';

import 'big_card_image_slide_skeleton.dart';
import 'skeleton_line.dart';

class BigCardSkeleton extends StatelessWidget {
  const BigCardSkeleton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AspectRatio(
          aspectRatio: 1.81,
          child: BigCardImageSlideSkeleton(),
        ),
        const SizedBox(height: 16),
        SkeletonLine(
          width: MediaQuery.of(context).size.width * 0.8,
        ),
        const SizedBox(height: 16),
        const SkeletonLine(),
        const SizedBox(height: 16),
        const SkeletonLine(),
      ],
    );
  }
}
