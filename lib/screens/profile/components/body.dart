import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/svg.dart';
import '../../../constants.dart';
import '../../../core/routes.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../data/providers/cart_provider.dart';

class Body extends ConsumerWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.system;
    final isDarkMode = themeMode == ThemeMode.dark;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding),
              Text("Account Settings",
                  style: Theme.of(context).textTheme.headlineMedium),
              Text(
                "Update your settings like notifications, payments, profile edit etc.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ProfileMenuCard(
                svgSrc: "assets/icons/profile.svg",
                title: "Profile Information",
                subTitle: "Change your account information",
                press: () => context.pushNamed(AppRoutes.profileEdit),
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/lock.svg",
                title: "Change Password",
                subTitle: "Change your password",
                press: () => context.pushNamed(AppRoutes.profilePassword),
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/card.svg",
                title: "Payment Methods",
                subTitle: "Add your credit & debit cards",
                press: () => context.pushNamed(AppRoutes.profilePaymentMethods),
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/marker.svg",
                title: "Locations",
                subTitle: "Add or remove your delivery locations",
                press: () => context.pushNamed(AppRoutes.profileAddresses),
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/fb.svg",
                title: "Add Social Account",
                subTitle: "Add Facebook, Twitter etc ",
                press: () => context.pushNamed(AppRoutes.profileSocial),
                isComingSoon: false,
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/share.svg",
                title: "Refer to Friends",
                subTitle: "Get \$10 for reffering friends",
                press: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Referral program coming soon')),
                  );
                },
                isComingSoon: true,
              ),
              const SizedBox(height: defaultPadding / 2),
              SwitchListTile(
                value: isDarkMode,
                onChanged: (value) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
                title: const Text("Dark Mode"),
                subtitle: const Text("Use Material You dark theme"),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: defaultPadding / 2),
              // Notifications Settings
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding / 2),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  onTap: () =>
                      context.pushNamed(AppRoutes.profileNotifications),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 24,
                          color: titleColor.withValues(alpha: 0.64),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Notifications",
                                maxLines: 1,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Manage your notification preferences",
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: titleColor.withValues(alpha: 0.54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios_outlined,
                          size: 20,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding / 2),
              ProfileMenuCard(
                svgSrc: "assets/icons/logout.svg",
                title: "Sign Out",
                subTitle: "Log out of your account",
                press: () async {
                  // Clear user-specific data BEFORE signout
                  await ref.read(cartProvider.notifier).clear();

                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.goNamed(AppRoutes.signIn);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({
    super.key,
    this.title,
    this.subTitle,
    this.svgSrc,
    this.press,
    this.isComingSoon = false,
  });

  final String? title, subTitle, svgSrc;
  final VoidCallback? press;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isComingSoon ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          onTap: isComingSoon ? null : press,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SvgPicture.asset(
                  svgSrc!,
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    titleColor.withValues(alpha: 0.64),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title!,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          if (isComingSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.2),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(4)),
                              ),
                              child: Text(
                                'Coming soon',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subTitle!,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          color: titleColor.withValues(alpha: 0.54),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 20,
                  color:
                      isComingSoon ? titleColor.withValues(alpha: 0.3) : null,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
