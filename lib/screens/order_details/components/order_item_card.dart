import 'package:flutter/material.dart';

import '../../../constants.dart';

class OrderedItemCard extends StatelessWidget {
  const OrderedItemCard({
    super.key,
    required this.numOfItem,
    required this.title,
    required this.description,
    required this.price,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
  });
  final int numOfItem;
  final String? title, description;
  final double? price;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NumOfItems(numOfItem: numOfItem),
            const SizedBox(width: defaultPadding * 0.75),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: defaultPadding / 4),
                  Text(
                    description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (onIncrement != null && onDecrement != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onDecrement,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(numOfItem.toString()),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onIncrement,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        if (onRemove != null)
                          TextButton(
                            onPressed: onRemove,
                            child: const Text('Remove'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: defaultPadding / 2),
            Text(
              "USD$price",
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(color: primaryColor),
            )
          ],
        ),
        const SizedBox(height: defaultPadding / 2),
        const Divider(),
      ],
    );
  }
}

class NumOfItems extends StatelessWidget {
  const NumOfItems({
    super.key,
    required this.numOfItem,
  });

  final int numOfItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(
            width: 0.5, color: const Color(0xFF868686).withValues(alpha: 0.3)),
      ),
      child: Text(
        numOfItem.toString(),
        style: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(color: primaryColor),
      ),
    );
  }
}
