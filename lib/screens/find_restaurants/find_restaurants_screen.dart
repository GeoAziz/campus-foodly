import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../components/buttons/secondary_button.dart';
import '../../components/welcome_text.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../data/services/location_service.dart';

class FindRestaurantsScreen extends ConsumerStatefulWidget {
  const FindRestaurantsScreen({super.key});

  @override
  ConsumerState<FindRestaurantsScreen> createState() =>
      _FindRestaurantsScreenState();
}

class _FindRestaurantsScreenState extends ConsumerState<FindRestaurantsScreen> {
  final _locationService = LocationService();
  String _locationLabel = 'Use current location';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.goNamed(AppRoutes.app);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeText(
                title: "Find restaurants near you ",
                text:
                    "Please enter your location or allow access to \nyour location to find restaurants near you.",
              ),

              // Getting Current Location
              SecondaryButton(
                press: () async {
                  try {
                    final position =
                        await _locationService.getCurrentPosition();
                    if (!context.mounted) return;
                    setState(() {
                      _locationLabel =
                          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
                    });
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/icons/location.svg",
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _locationLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: primaryColor),
                    )
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),

              // New Address Form
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      // onSaved: (value) => _location = value,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: titleColor),
                      cursorColor: primaryColor,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            "assets/icons/marker.svg",
                            colorFilter: const ColorFilter.mode(
                                bodyTextColor, BlendMode.srcIn),
                          ),
                        ),
                        hintText: "Enter a new address",
                        contentPadding: kTextFieldPadding,
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    ElevatedButton(
                      onPressed: () {
                        // Use your onw way how you combine both New Address and Current Location
                        context.goNamed(AppRoutes.app);
                      },
                      child: const Text("Continue"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
