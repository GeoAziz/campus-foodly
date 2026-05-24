# Contributing to Campus Foodly

## Table of Contents
- [Development Setup](#development-setup)
- [Code Standards](#code-standards)
- [Git Workflow](#git-workflow)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Debugging Guide](#debugging-guide)

## Development Setup

### Prerequisites
- Flutter SDK 3.24.0 or later
- Dart 3.5.0 or later
- Android Studio / Xcode for mobile development
- Git for version control

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/yourorg/campus-foodly.git
cd campus-foodly

# Setup Flutter
flutter pub get

# Setup code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Setup Hive database
flutter packages get
```

### Environment Configuration

```bash
# Copy the example environment file
cp .env.example .env.development

# Edit with your local credentials
nano .env.development
```

**Never commit actual credentials!** The `.env.development` file is in `.gitignore`.

### Firebase Setup

1. **Android**:
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/`

2. **iOS**:
   - Download `GoogleService-Info.plist` from Firebase Console
   - Add to Xcode project (drag & drop)

### Running the App

```bash
# Development build
flutter run

# Release build
flutter build apk --release    # Android
flutter build ios --release    # iOS

# Web (if supported)
flutter run -d web
```

## Code Standards

### Naming Conventions
- **Classes**: `PascalCase` (e.g., `OrderRepository`)
- **Methods/Variables**: `camelCase` (e.g., `fetchOrders`)
- **Constants**: `camelCase` (e.g., `maxOrdersPerDay`)
- **Private members**: Prefix with `_` (e.g., `_logger`)
- **Files**: `snake_case` (e.g., `order_repository.dart`)

### Dart Best Practices

```dart
// ✓ Good: Type annotations, null safety
Future<List<Order>> fetchOrders(String userId) async {
  // Implementation
}

// ✗ Bad: Untyped, potential null errors
Future fetchOrders(userId) async {
  // Implementation
}
```

### Null Safety
- Use non-nullable by default (`String`, not `String?`)
- Use `?` only when null is acceptable
- Use `!` carefully; prefer defensive checks

```dart
// ✓ Good
final user = authProvider.valueOrNull;
if (user != null) {
  // Use user safely
}

// ✗ Bad
final user = authProvider.value!; // Unsafe!
```

### Comments & Documentation

```dart
/// Brief description of what this does
/// 
/// Longer description with examples and important notes
/// 
/// Example:
/// ```dart
/// final repository = OrderRepository();
/// final orders = await repository.fetchOrders(userId);
/// ```
/// 
/// Throws [Exception] if network error occurs.
Future<List<Order>> fetchOrders(String userId) async {
  // Implementation
}
```

### Error Handling

```dart
// ✓ Good: Specific error handling
try {
  final order = await createOrder(input);
  // Success
} on SocketException catch (e) {
  logger.e('Network error: $e');
  showErrorDialog('Check your internet connection');
} on FirebaseException catch (e) {
  logger.e('Firebase error: $e');
  showErrorDialog('Server error. Try again later.');
} catch (e) {
  logger.e('Unknown error: $e');
  showErrorDialog('An unexpected error occurred');
}

// ✗ Bad: Generic error handling
try {
  final order = await createOrder(input);
} catch (e) {
  print('Error: $e'); // Vague and no recovery!
}
```

## Git Workflow

### Branch Naming
- `feature/description`: New features (e.g., `feature/order-tracking`)
- `bugfix/description`: Bug fixes (e.g., `bugfix/payment-validation`)
- `refactor/description`: Code refactoring (e.g., `refactor/repository-pattern`)
- `hotfix/description`: Production fixes (e.g., `hotfix/crash-on-login`)

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add order pagination
fix: resolve duplicate order issue
docs: update architecture guide
refactor: simplify connectivity service
test: add unit tests for order creation
chore: update dependencies
```

### Workflow Steps

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes and commit
git add .
git commit -m "feat: implement order tracking"

# 3. Push to remote
git push origin feature/my-feature

# 4. Create Pull Request on GitHub
# → Provide detailed description
# → Link related issues
# → Request reviewers

# 5. After approval, merge to main
git merge --squash feature/my-feature
git push origin main
```

## Testing Requirements

### Unit Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/data/repositories/order_repository_test.dart

# Run with coverage
flutter test --coverage
```

### Writing Tests
```dart
void main() {
  group('OrderRepository', () {
    late OrderRepository repository;

    setUp(() {
      repository = InMemoryOrderRepository();
    });

    test('creates orders successfully', () async {
      final order = Order(...);
      await repository.saveOrder(order);
      
      final saved = await repository.fetchOrderById(order.id);
      expect(saved, isNotNull);
      expect(saved?.id, order.id);
    });
  });
}
```

### Test Coverage Goals
- **Critical paths**: 80%+ coverage
- **Business logic**: 70%+ coverage
- **Overall**: 60%+ coverage

## Pull Request Process

### Before Submitting

1. **Local checks**:
   ```bash
   flutter analyze
   dart format --set-exit-if-changed lib test
   flutter test
   ```

2. **Update documentation**:
   - Update CHANGELOG.md
   - Update API docs if applicable
   - Add inline comments for complex logic

3. **Test scenarios**:
   - Test on both Android and iOS
   - Test offline mode
   - Test error scenarios

### PR Template

```markdown
## Description
Brief description of what this PR does

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- Detail 1
- Detail 2

## Testing Done
- Tested on: Android/iOS/Web
- Test scenarios covered
- Edge cases handled

## Screenshots
(If UI changes)

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No new warnings in analysis
```

### Review Process
1. Automated checks must pass
2. At least 1 approval required
3. All conversations resolved
4. Merge to main or develop

## Debugging Guide

### Enable Debug Logging
```dart
// In main.dart
const bool kDebugMode = true; // Shows all logs

// Access logs
final logger = LoggerService();
logger.d('Debug info');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
```

### Firebase Emulator
```bash
# Start emulator
firebase emulators:start

# Use in app
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
```

### Debug Offline Mode
```dart
// Force offline in development
ConnectivityService().addListener((result) {
  logger.i('Network status: $result');
});
```

### Crash Reporting
```dart
// View crash reports
firebase crashlytics:symbolicate build/app/outputs/flutter-apk/app-release.apk

// Send test error
CrashReportingService().recordError(
  exception: Exception('Test error'),
  stackTrace: StackTrace.current,
);
```

## Performance Optimization

### Profile Your App
```bash
# Build with profiling
flutter run --profile

# Trace performance
flutter run --profile --trace-startup
```

### Check Widget Rebuilds
```dart
// Enable rendering statistics
WidgetsApp.showPerformanceOverlay = true;
```

---

For architecture details, see [ARCHITECTURE.md](ARCHITECTURE.md).
For security guidelines, see [SECURITY.md](SECURITY.md).
