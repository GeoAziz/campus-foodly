import 'package:flutter/material.dart';

class SkeletonRoundedContainer extends StatelessWidget {
  const SkeletonRoundedContainer({
    super.key,
    this.height = double.infinity,
    this.width = double.infinity,
    this.radius = 10,
  });

  final double height, width, radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}
