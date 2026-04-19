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
