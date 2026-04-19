import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../components/price_range_and_food_type.dart';
import '../../../components/rating_with_counter.dart';
import '../../../constants.dart';

class RestaurantInfo extends StatelessWidget {
  const RestaurantInfo({
    super.key,
    required this.name,
    required this.foodType,
    required this.rating,
    required this.numOfRating,
    required this.deliveryFee,
    required this.deliveryTime,
    this.takeAwayLabel = 'Take away',
  });

  final String name;
  final List<String> foodType;
  final double rating;
  final int numOfRating;
  final String deliveryFee;
  final int deliveryTime;
  final String takeAwayLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.headlineMedium,
            maxLines: 1,
          ),
          const SizedBox(height: defaultPadding / 2),
          PriceRangeAndFoodtype(
            foodType: foodType,
          ),
          const SizedBox(height: defaultPadding / 2),
          RatingWithCounter(rating: rating, numOfRating: numOfRating),
          const SizedBox(height: defaultPadding),
          Row(
            children: [
              DeliveryInfo(
                iconSrc: "assets/icons/delivery.svg",
                text: deliveryFee,
                subText: "Delivery",
              ),
              const SizedBox(width: defaultPadding),
              DeliveryInfo(
                iconSrc: "assets/icons/clock.svg",
                text: '$deliveryTime',
                subText: "Minutes",
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(takeAwayLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DeliveryInfo extends StatelessWidget {
  const DeliveryInfo({
    super.key,
    required this.iconSrc,
    required this.text,
    required this.subText,
  });

  final String iconSrc, text, subText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          iconSrc,
          height: 20,
          width: 20,
          colorFilter: const ColorFilter.mode(
            primaryColor,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            text: "$text\n",
            style: Theme.of(context).textTheme.labelLarge,
            children: [
              TextSpan(
                text: subText,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall!
                    .copyWith(fontWeight: FontWeight.normal),
              )
            ],
          ),
        ),
      ],
    );
  }
}
