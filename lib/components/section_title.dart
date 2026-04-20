import 'package:flutter/material.dart';

import '../constants.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    this.isMainSection = true,
    this.showAction = true,
    required this.title,
    required this.press,
  });

// Main Section means on Home page section
  final bool isMainSection;
  final bool showAction;
  final String title;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isMainSection ? title : title.toUpperCase(),
            style: isMainSection
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.titleMedium,
          ),
          if (showAction)
            GestureDetector(
              onTap: press,
              child: Text(
                isMainSection ? "See all" : "Clear all".toUpperCase(),
                style: isMainSection
                    ? Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: primaryColor)
                    : TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: titleColor.withValues(alpha: 0.64),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
