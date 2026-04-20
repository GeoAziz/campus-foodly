# OrderEats Flutter App

OrderEats is a Flutter food delivery application for Android and iOS with Riverpod state management, GoRouter navigation, Firebase-backed auth/data flows, and reusable UI components.

## Screenshots

![All pages](/preview.png)

![Preview](/foodly_thun.png)

## Build Android release APK

Use the project script:

```bash
bash scripts/build_release_android.sh
```

Generated APK path:

- `build/app/outputs/flutter-apk/app-release.apk`
- fallback: `build/app/outputs/apk/release/app-release.apk`

## Troubleshooting

If `flutter build apk --release -v` fails with `Gradle task assembleRelease failed with exit code 143`, use:

```bash
bash scripts/build_release_android.sh
```

This uses direct Gradle `assembleRelease`, which avoids the wrapper path that can terminate early on some environments.

## Partner Data Validation

Validate featured-partner data integrity before releasing:

```bash
node ./scripts/validate_partner_data.js
```

What this checks:

- missing partner-scoped sections (`restaurant_details`, `featured_items`, `menu_tabs`, `menu_items`)
- featured flag mismatches (`isFeatured` not aligned with scoped content)
- duplicate IDs inside normalized collections
- orphan `restaurantId` references to unknown restaurants

Exit code behavior:

- `0`: release gate checks pass
- `1`: one or more featured-partner contract violations or structural data issues found
