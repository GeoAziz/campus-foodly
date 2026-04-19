import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../app_image.dart';
import '../../rating.dart';
import '../../small_dot.dart';

class RestaurantInfoMediumCard extends StatelessWidget {
  const RestaurantInfoMediumCard({
    super.key,
    required this.image,
    required this.name,
    required this.location,
    required this.rating,
    required this.deliveryTime,
    required this.press,
    this.heroTag,
  });

  final String image, name, location;
  final double rating;
  final int deliveryTime;
  final VoidCallback press;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: (heroTag != null && heroTag!.trim().isNotEmpty)
                    ? Hero(
                        tag: heroTag!,
                        child: AppImage(source: image, fit: BoxFit.cover),
                      )
                    : AppImage(source: image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: defaultPadding / 4),
            Text(
              location,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: defaultPadding / 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Rating(rating: rating),
                Text(
                  "$deliveryTime min",
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: titleColor.withValues(alpha: 0.74)),
                ),
                const SmallDot(),
                Text(
                  "Free delivery",
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium!
                      .copyWith(color: titleColor.withValues(alpha: 0.74)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
