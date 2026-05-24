# Campus Foodly

A **production-grade** Flutter food delivery platform with real-time order tracking, payment processing, delivery management, and comprehensive security features.

![Preview](/foodly_thun.png)

## 🚀 Quick Start

### Prerequisites
- Flutter 3.24.0+
- Dart 3.5.0+
- Android SDK & Xcode (for mobile builds)
- Firebase Project configured

### Installation

```bash
# Clone and setup
git clone https://github.com/yourorg/campus-foodly.git
cd campus-foodly

# Get dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Configure environment
cp .env.example .env.development
# Edit .env.development with your credentials

# Run development app
flutter run
```

### Build Release Packages

**Android APK**:
```bash
bash scripts/build_release_android.sh
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**iOS IPA**:
```bash
flutter build ios --release --no-codesign
# Follow Xcode instructions for code signing
```

**Web**:
```bash
flutter build web --release
```

## 📋 Documentation

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design & patterns |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development workflow & standards |
| [SECURITY.md](SECURITY.md) | Security practices & compliance |

## ✨ Key Features

### User Features
- ✅ Real-time order tracking
- ✅ Multiple address management
- ✅ Secure payment processing (Stripe)
- ✅ Order history & ratings
- ✅ Push notifications
- ✅ Offline-first support

### Admin Features
- ✅ Restaurant management
- ✅ Menu & inventory control
- ✅ Order monitoring dashboard
- ✅ Delivery assignment system
- ✅ Analytics & reporting

### Technical Features
- ✅ Zero downtime deployment
- ✅ End-to-end encryption (transit)
- ✅ Automatic crash reporting
- ✅ Performance monitoring
- ✅ CI/CD pipeline (GitHub Actions)
- ✅ Comprehensive test suite
- ✅ Rate limiting & abuse prevention

## 🏗️ Architecture

### Tech Stack

**Frontend**:
- Flutter for cross-platform mobile
- Riverpod for state management
- GoRouter for navigation
- Freezed for code generation

**Backend**:
- Firebase Authentication
- Cloud Firestore (realtime database)
- Firebase Storage (media)
- Firebase Messaging (push notifications)
- Firebase Crashlytics (monitoring)

**Payment**:
- Stripe for payment processing
- PCI DSS Level 1 compliance

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/                     # Configuration & setup
├── data/                     # Data layer
│   ├── models/              # Dart models
│   ├── repositories/        # Data access
│   ├── services/            # Business logic
│   └── providers/           # Riverpod state
├── features/                # Feature modules
├── components/              # Reusable widgets
└── screens/                 # Page implementations
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system design.

## 🔒 Security

### Critical Features

✅ **Firebase App Check**: API abuse protection
✅ **Firestore Security Rules**: Row & field-level access control  
✅ **Rate Limiting**: Abuse prevention (10 orders/user/day)
✅ **Idempotency Keys**: Duplicate order prevention
✅ **Secrets Management**: No hardcoded credentials
✅ **Encryption**: TLS 1.2+ for transit, AES-256 at rest
✅ **Monitoring**: Firebase Crashlytics with user context

### Before Production

**Environment Setup**:
```bash
# Create environment file (DO NOT COMMIT)
cp .env.example .env.development

# Add credentials:
CLOUDINARY_CLOUD_NAME=your_cloud
CLOUDINARY_API_KEY=your_key
CLOUDINARY_API_SECRET=your_secret
```

**Firebase Configuration**:
1. Create Firebase project
2. Download `google-services.json` (Android)
3. Download `GoogleService-Info.plist` (iOS)
4. Enable Firestore, Auth, Storage, Messaging
5. Configure Firestore security rules
6. Setup App Check tokens

**Payment Setup**:
1. Create Stripe account
2. Add publishable & secret keys to `.env`
3. Configure webhook handlers
4. Test with Stripe test cards

**Deployment Checklist**:
- [ ] All tests passing (`flutter test`)
- [ ] No security warnings (`flutter analyze`)
- [ ] Code formatted (`dart format lib`)
- [ ] Secrets removed from repo
- [ ] Firestore rules deployed
- [ ] Rate limits configured
- [ ] Monitoring alerts setup
- [ ] Error reporting enabled

See [SECURITY.md](SECURITY.md) for comprehensive security guidelines.

## 🧪 Testing

### Run Tests

```bash
# Unit & widget tests
flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/data/repositories/order_repository_test.dart

# Watch mode
flutter test --watch
```

### Test Structure

```
test/
├── firebase_mocks.dart                    # Mock setup
├── data/
│   ├── repositories/                      # Repository tests
│   └── services/                          # Service tests
└── screens/                               # UI tests
```

**Coverage Goals**:
- Critical paths: 80%+
- Business logic: 70%+
- Overall: 60%+

## 📊 CI/CD Pipeline

Automated checks on every push and PR:

**Lint & Analysis** (`.github/workflows/lint-analyze.yml`):
```bash
flutter analyze          # Code quality
dart format --check     # Code formatting
dart pub outdated       # Dependency check
```

**Testing** (`.github/workflows/test.yml`):
```bash
flutter test --coverage
codecov upload
```

**Building** (`.github/workflows/build.yml`):
```bash
flutter build apk --release
flutter build ios --release
```

### Manual Deployment

```bash
# Build signed Android release
flutter build apk --release

# Build iOS release (requires Apple Developer account)
flutter build ios --release

# Deploy to Google Play / App Store using respective CLIs
```

## 🐛 Debugging

### Enable Logging

```dart
// Access logger in any part of app
final logger = LoggerService();
logger.i('Info message');
logger.e('Error message');
```

### Firebase Emulator

```bash
# Start local emulators
firebase emulators:start

# Connect app in development
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

### View Crash Reports

```bash
# Real-time Crashlytics logs
firebase crashlytics:symbols
```

### Offline Testing

```dart
// Force offline mode
ConnectivityService().addListener((status) {
  print('Network: $status');
});
```

## 📈 Monitoring & Analytics

### Firebase Dashboard
- Real-time user activity
- Crash analysis & trends
- Performance metrics
- Engagement funnel

### Custom Metrics
- Order success rate
- Payment processing time
- Delivery time average
- Customer satisfaction

### Error Tracking
- Automatic uncaught exception capture
- Custom error logging
- User context attribution
- Stack trace symbolication

## 🛠️ Development Workflow

### Contributing

1. See [CONTRIBUTING.md](CONTRIBUTING.md) for:
   - Code standards
   - Git workflow
   - PR process
   - Testing requirements

2. Quick summary:
   ```bash
   git checkout -b feature/my-feature
   # ... make changes ...
   flutter test
   flutter analyze
   git add .
   git commit -m "feat: description"
   git push origin feature/my-feature
   # → Create PR on GitHub
   ```

### Common Tasks

**Add a new feature**:
```bash
flutter create lib/features/my_feature
# Implement repository, service, provider, UI
flutter test
```

**Debug connectivity issues**:
```dart
final connectivity = ConnectivityService();
print('Online: ${connectivity.isOnline}');
connectivity.addListener((status) => print('Status: $status'));
```

**Test payment flow**:
```dart
// Use Stripe test cards
// 4242 4242 4242 4242 (success)
// 4000 0000 0000 0002 (declined)
```

## 📦 Dependencies

Key packages:
- `firebase_core`, `cloud_firestore`, `firebase_auth`
- `flutter_riverpod`, `riverpod_annotation`
- `go_router`, `freezed`
- `stripe_flutter`, `http`, `dio`
- `hive`, `connectivity_plus`
- `firebase_crashlytics`, `firebase_app_check`

See `pubspec.yaml` for all dependencies and versions.

## 🚨 Troubleshooting

### Build Fails with "Gradle task assembleRelease failed"

```bash
# Use direct gradle instead
bash scripts/build_release_android.sh
```

### Data Validation Issues

```bash
# Validate partner data integrity
node ./scripts/validate_partner_data.js
```

Expected exit codes:
- `0`: All checks pass
- `1`: Data validation errors found

### Firebase Initialization Error

- Ensure `google-services.json` (Android) is in `android/app/`
- Ensure `GoogleService-Info.plist` (iOS) is in Xcode project
- Verify Firebase project credentials in Firebase Console

### Network/Connectivity Issues

```dart
// Check and retry with backoff
final connectivity = ConnectivityService();
await connectivity.retryWithBackoff(
  () => createOrder(),
  maxRetries: 3,
);
```

## 📄 License & Legal

- See LICENSE file for terms
- See [SECURITY.md](SECURITY.md) for security policy
- See PRIVACY.md for privacy practices

## 📞 Support & Reporting

### Security Issues

⚠️ **Never open public issues for security vulnerabilities!**

Email: security@campusfoodly.dev

### Bug Reports

1. Check [GitHub Issues](https://github.com/yourorg/campus-foodly/issues)
2. Create detailed issue with:
   - Reproduction steps
   - Expected vs actual behavior
   - Device/OS info
   - Logs/screenshots

### Feature Requests

Open a discussion in [GitHub Discussions](https://github.com/yourorg/campus-foodly/discussions)

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and breaking changes.

---

**Version**: 1.0.0  
**Status**: Production Ready  
**Last Updated**: 2024

For detailed documentation, see [ARCHITECTURE.md](ARCHITECTURE.md), [CONTRIBUTING.md](CONTRIBUTING.md), and [SECURITY.md](SECURITY.md).
