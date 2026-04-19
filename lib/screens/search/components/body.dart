import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../core/constants.dart';

import '../../../components/cards/big/restaurant_info_big_card.dart';
import '../../../components/skeleton/big_card_skeleton.dart';
import '../../../data/services/mock_data_service.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final _formKey = GlobalKey<FormState>();

  bool _showSearchResult = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void showResult() {
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _showSearchResult = true;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('Search', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: defaultPadding),
            buildSearchForm(),
            const SizedBox(height: defaultPadding),
            Text(_showSearchResult ? "Search Results" : "Top Restaurants",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: defaultPadding),
            Expanded(
              child: ListView.builder(
                itemCount: _isLoading ? 2 : 5, //5 is demo length of your data
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  child: _isLoading
                      ? const BigCardSkeleton()
                      : Builder(
                          builder: (context) {
                            final restaurant = demoMediumCardData[
                                index % demoMediumCardData.length];
                            final categories = (restaurant['categories']
                                    as List<dynamic>? ??
                                const ["Chinese", "American", "Deshi food"])
                                .map((item) => item.toString())
                                .toList(growable: false);

                            return RestaurantInfoBigCard(
                              images: [restaurant['image'] as String],
                              name: restaurant['name'] as String,
                              rating: (restaurant['rating'] as num).toDouble(),
                              numOfRating:
                                  (restaurant['ratingCount'] as num? ?? 200)
                                      .toInt(),
                              deliveryTime:
                                  (restaurant['deliveryTime'] as num? ?? 25)
                                      .toInt(),
                              foodType: categories,
                              press: () {},
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Form buildSearchForm() {
    return Form(
      key: _formKey,
      child: TextFormField(
        onChanged: (value) {
          // get data while typing
          if (value.length >= 3) showResult();
        },
        onFieldSubmitted: (value) {
          if (_formKey.currentState!.validate()) {
            // If all data are correct then save data to out variables
            _formKey.currentState!.save();

            // Once user pree on submit
            showResult();
          } else {}
        },
        validator: requiredValidator.call,
        style: Theme.of(context).textTheme.labelLarge,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search OrderEats restaurants',
          contentPadding: kTextFieldPadding,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset(
              'assets/icons/search.svg',
              colorFilter: const ColorFilter.mode(
                bodyTextColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
