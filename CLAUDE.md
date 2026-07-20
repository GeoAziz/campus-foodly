# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (Freezed, Riverpod, JSON, Hive)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run

# Analyze code (linting)
flutter analyze

# Format code
dart format lib test

# Run all tests
flutter test --coverage

# Run a single test file
flutter test test/features/profile/providers/addresses_controller_test.dart

# Run tests matching a name pattern
flutter test --name "cart provider"
```

## Architecture

The app is a Flutter food-delivery client named **ordereats** (package name) / **Campus Foodly** (display name). It targets Android, iOS, Linux, and Windows.

### Layer structure

```
lib/
├── main.dart              # App bootstrap; initializes Firebase, AppCheck, Crashlytics,
│                          # ConnectivityService, IdempotencyService before runApp
├── entry_point.dart       # Bottom-nav shell (Home / Search / Orders / Profile tabs)
├── core/
│   ├── router.dart        # GoRouter with auth redirect guards + RBAC route checks
│   ├── routes.dart        # Route name constants (AppRoutes)
│   └── theme.dart         # buildLightThemeData / buildDarkThemeData
├── data/
│   ├── models/            # Plain Dart model classes (AppUser, Order, CartItem, …)
│   ├── repositories/      # Abstract interfaces + Firebase implementations
│   ├── providers/         # Riverpod providers (state + DI)
│   └── services/          # Cross-cutting services (connectivity, idempotency, logger, …)
├── features/              # Vertical slices: order_tracking, payments, profile, recommendations
│   └── <feature>/
│       ├── models/
│       ├── presentation/  # Screens
│       ├── providers/     # Feature-scoped Riverpod providers
│       └── repositories/
├── screens/               # Screens that don't yet have a features/ slice
│   └── <screen>/
│       └── components/    # Screen-local widgets
├── components/            # Shared, reusable widgets (cards, buttons, skeletons, …)
└── admin/                 # Admin entry point, router, dashboard (separate sub-app)
```

### State management

Riverpod is used throughout. Key patterns:

- **`authControllerProvider`** (`AsyncNotifierProvider<AuthController, AppUser?>`) — central auth state; the router `redirect` function watches it.
- **`cartProvider`** (`StateNotifierProvider<CartController, List<CartItem>>`) — persisted to device via `CartPersistenceService` (Hive). Initialized lazily on first `ref.watch` inside `EntryPoint`.
- **`routerProvider`** (`Provider<GoRouter>`) — watches auth state and `userRoleProvider` to compute redirects on every navigation.
- Feature providers (orders, payments, profile, etc.) live under `features/<feature>/providers/`.

### Navigation

`GoRouter` with named routes (`AppRoutes` constants). Auth guard in the `redirect` callback: unauthenticated users → `/sign-in`; authenticated users hitting auth routes → `/app`. Role-based admin routes enforced via `RoleBasedAccessControl.canAccessRoute`.

Route data passing: complex objects go via `state.extra`; simple scalars use query parameters.

### Code generation

The project uses `build_runner` for:
- **Freezed** — model unions/sealed classes
- **Riverpod generator** — `@riverpod` annotated providers
- **json_serializable** — `fromJson/toJson`
- **hive_generator** — `@HiveType` adapters

Always run `build_runner build` after adding/modifying annotated models or providers.

### Firebase & backend

| Service | Purpose |
|---|---|
| Firebase Auth | Email/password, phone OTP |
| Cloud Firestore | Primary database; security rules in `firestore.rules` |
| Firebase Storage | Media uploads |
| Firebase Messaging | Push notifications |
| Firebase App Check | Request authenticity |
| Firebase Crashlytics | Crash reporting via `CrashReportingService` |
| Hive | Local offline cache (cart persistence, idempotency keys) |

Firestore security rules enforce RBAC (user / restaurantOwner / delivery / admin roles), order idempotency (duplicate key rejection), and rate limits (10 orders/user/day, 5 payments/user/day).

### Services & Resilience

All services live in `lib/data/services/` and `lib/features/*/services/`. They are singletons with proper initialization, error handling, and recovery strategies.

**Core Services:**

- **`ConnectivityService`** — Multi-listener support for network state. Call `isOnline` before payments/orders. Use `retryWithBackoff()` for exponential backoff. Custom `ConnectivityException` on failures.
- **`IdempotencyService`** — UUID-based duplicate prevention (Hive-backed). Automatic cleanup after 24 hours. Storage limit of 1000 keys; periodic cleanup every hour. Wire into M-Pesa and order creation.
- **`OfflineDataService`** — Persistent offline cache for orders, addresses, profiles (Hive-backed). Survives app restart. Auto-expires after 12 hours.
- **`LocationService`** — Caching (5-min TTL) to reduce repeated calls. Custom `LocationException` for clarity. Includes permission checking.
- **`StorageService`** — Retry logic (3 attempts max), progress callbacks, and proper error handling. Graceful fallback on resolution failures.

**Payment & Transactions:**

- **`MpesaService`** — Validates credentials (rejects PLACEHOLDER values). Integrates `IdempotencyService` to prevent duplicate charges. Checks `ConnectivityService` before requests. Polling callbacks `onAttempt` / `onError` for UI feedback. Throws `MpesaException` with descriptive messages (not silent failures).

**User & State:**

- **`NotificationService`** — FCM with configurable retry (default 3). Proper permission error handling. WidgetsBinding for navigation instead of arbitrary delays.
- **`CrashReportingService`** — Breadcrumb tracking (50-item buffer, auto-rotate). `clearUserInfo()` implementation on logout. Custom key-value context for every error.
- **`OrderValidationService`** — Configurable via `OrderValidationConfig`. Amount tolerance and minimum order amount are adjustable (not hard-coded).

**Configuration:**

- **`AppCheckService`** — Retry logic (2-3 attempts) on token generation. Timeout protection (10s). Visible error logging (not silent fail).
- **`AddressLoadingService`** — Automatic cleanup of stale requests after 5 minutes. Memory-safe: no unbounded request ID accumulation.
- **`CartPersistenceService`** — Schema versioning and migration support. Graceful degradation on parse errors. Note: Ready for `encrypted_shared_preferences` when GDPR encryption is required.

**Recommendations:**

- **`RecommendationService`** — 1-hour cache (configurable `RecommendationScoreConfig`). Scoring weights adjustable (order history, location, rating). Error fallback returns stale cache if available. No silent failures.

### Role system

`UserRole` enum: `customer`, `restaurantOwner`, `deliveryDriver`, `admin`. Stored on the Firestore `/users/{uid}` document. `RoleBasedAccessControl` in `role_based_access_provider.dart` maps roles to allowed routes and actions.

### Idempotency

`IdempotencyService` (Hive-backed singleton) generates UUID v4 keys for all operations that must be idempotent (orders, payments). Keys are validated and stored locally; Firestore rules enforce server-side validation. Auto-expires after 24 hours. Includes periodic cleanup timer and storage limits (1000 keys max). Call `.initialize()` at app startup and `.dispose()` on shutdown.

```dart
final idempotency = IdempotencyService();
await idempotency.initialize();
final key = idempotency.generateKey();
// Include key in order/payment request
```

### Offline support

Offline data is persisted via `OfflineDataService` (Hive-backed) for orders, addresses, and profiles. Data survives app restarts (unlike in-memory cache). Expires after 12 hours.

Network detection via `ConnectivityService`: check `isOnline` before critical operations like payments. Use `retryWithBackoff()` for exponential backoff on network failures. Multiple components can listen via `addListener()` / `removeListener()`.

Cart persistence via `CartPersistenceService` with schema versioning and migration. Note: Currently uses SharedPreferences; ready to migrate to `encrypted_shared_preferences` when GDPR encryption is required.

```dart
final connectivity = ConnectivityService();
if (!connectivity.isOnline) {
  throw ConnectivityException('Offline');
}
final result = await connectivity.retryWithBackoff(() => apiCall());
```

### Testing

- Unit/widget tests in `test/`; mocks via `mockito`/`mocktail`
- Firebase mocks shared in `test/firebase_mocks.dart`
- Integration tests in `test/integration/` and `integration_test/`
- CI uses Flutter 3.24.0 stable

### CI/CD

Three workflows (`.github/workflows/`):
- `lint-analyze.yml` — `flutter analyze`, `dart format`, TruffleHog secret scan
- `test.yml` — `flutter test --coverage`, Codecov upload
- `build.yml` — Android APK + iOS IPA artifacts
