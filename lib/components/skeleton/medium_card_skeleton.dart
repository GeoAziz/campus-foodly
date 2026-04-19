import 'package:flutter/material.dart';

import 'skeleton_line.dart';
import 'skeleton_rounded_container.dart';

class MediumCardSkeleton extends StatelessWidget {
  const MediumCardSkeleton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.25,
            child: SkeletonRoundedContainer(),
          ),
          SizedBox(height: 16),
          SkeletonLine(width: 150),
          SizedBox(height: 16),
          SkeletonLine(),
          SizedBox(height: 16),
          SkeletonLine(),
        ],
      ),
    );
  }
}
