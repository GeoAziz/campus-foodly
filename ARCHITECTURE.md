# Campus Foodly - Architecture Documentation

## Table of Contents
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
- [Architecture Patterns](#architecture-patterns)
- [Data Flow](#data-flow)
- [Security Architecture](#security-architecture)
- [Offline-First Design](#offline-first-design)

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── core/
│   ├── theme.dart           # Theme configuration
│   └── router.dart          # GoRouter navigation setup
├── data/
│   ├── models/              # Data models (Order, User, Restaurant, etc.)
│   ├── repositories/        # Data access layer (Firebase, in-memory)
│   ├── services/            # Business logic services
│   │   ├── firebase_service.dart
│   │   ├── connectivity_service.dart
│   │   ├── idempotency_service.dart
│   │   ├── crash_reporting_service.dart
│   │   ├── app_check_service.dart
│   │   └── logger_service.dart
│   └── providers/           # Riverpod state management
├── features/                # Feature modules
│   ├── auth/
│   ├── orders/
│   ├── restaurants/
│   └── delivery/
├── components/              # Reusable UI components
└── screens/                 # Screen implementations
```

## Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Riverpod**: State management and dependency injection
- **GoRouter**: Declarative routing and navigation
- **Freezed**: Code generation for models and unions

### Backend Services
- **Firebase Authentication**: User authentication and identity
- **Cloud Firestore**: Real-time database
- **Firebase Storage**: Media file storage
- **Firebase Messaging**: Push notifications
- **Firebase App Check**: API abuse protection
- **Firebase Crashlytics**: Crash reporting and analytics

### Supporting Libraries
- **Hive**: Local offline-first caching
- **Connectivity Plus**: Network connectivity monitoring
- **Logger**: Structured logging
- **Stripe**: Payment processing

## Architecture Patterns

### Clean Architecture
The project follows Clean Architecture principles with clear separation of concerns:

```
Presentation Layer (UI Components & Screens)
    ↓
Domain Layer (Riverpod Providers)
    ↓
Data Layer (Repositories & Services)
    ↓
Firebase / External APIs
```

### State Management (Riverpod)
- **Providers**: Manage application state
- **Watch**: Reactive dependency tracking
- **Listen**: Side effects and notifications
- **Override**: Testing and configuration

Example:
```dart
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.fetchOrdersForUser(userId);
});
```

### Repository Pattern
Each domain entity has a repository:
- **OrderRepository**: Order CRUD operations
- **RestaurantRepository**: Restaurant data access
- **MenuRepository**: Menu item management

Repositories provide abstract interfaces for testability.

## Data Flow

### Typical User Order Flow

```
User Input
    ↓
Order Service (Idempotency check)
    ↓
Connectivity Check
    ↓
Order Repository (Create with validation)
    ↓
Firebase Firestore (Server-side rules validation)
    ↓
Success/Error Response
    ↓
Provider State Update
    ↓
UI Re-render
```

### Real-time Data Updates
- Cloud Firestore listeners provide real-time updates
- Riverpod providers handle automatic re-fetching
- Offline-first caching stores local snapshots

## Security Architecture

### Authentication Flow
1. User signup/login via Firebase Auth
2. ID token issued and cached locally
3. Token automatically refreshed before expiry
4. Token invalidated on logout

### API Protection
- **Firebase App Check**: Verify requests from genuine app instances
- **Firestore Security Rules**: Row-level and field-level access control
- **Rate Limiting**: Prevent abuse (10 orders/user/day, 5 payments/user/day)

### Data Validation
- **Client-side**: Input validation before sending
- **Server-side**: Firestore rules enforce schema
- **Idempotency**: Duplicate operation prevention

### Secrets Management
- Environment variables stored in `.env` files (NOT in repo)
- Firebase credentials in `GoogleService-Info.plist` and `google-services.json`
- Service account keys secured in Firebase Console

## Offline-First Design

### Local Caching with Hive
- Order history cached locally
- Quick access without network
- Automatic sync on reconnection

### Connectivity Service
```dart
// Check online status
if (connectivityService.isOnline) {
  // Perform network operation
}

// Retry with exponential backoff
await connectivityService.retryWithBackoff(() => createOrder());
```

### Conflict Resolution
1. Idempotency keys prevent duplicates
2. Server wins on conflicts
3. User notified of resolution

## Error Handling

### Crash Reporting
- Firebase Crashlytics captures all uncaught exceptions
- Custom error tracking with context
- User attribution for debugging

### Logging Strategy
- **Production**: Warning and above logged to Crashlytics
- **Development**: All levels logged to console
- **Debug info**: User ID, order context, network state

## Testing Strategy

### Unit Tests
- Mock Firebase services
- Test business logic isolation
- Repository pattern enables mocking

### Widget Tests
- UI component validation
- State management testing
- Navigation flow verification

### Integration Tests
- End-to-end user flows
- Real Firebase emulator testing
- Performance benchmarking

## Performance Optimization

### Image Optimization
- Cloudinary for dynamic resizing
- WebP format when supported
- Lazy loading on scroll

### Database Optimization
- Indexed queries for fast retrieval
- Pagination for large datasets
- Firestore composite indexes

### Code Optimization
- Tree-shaking enabled
- Lazy loading for routes
- Efficient provider dependencies

## Monitoring & Analytics

### Firebase Analytics
- User engagement tracking
- Conversion funnel analysis
- Crash insights

### Custom Metrics
- Order success rate
- Payment processing time
- Delivery time tracking

## Deployment Pipeline

See `.github/workflows/` for automated:
1. **Lint**: Code quality checks
2. **Test**: Unit and integration tests
3. **Build**: APK and IPA generation
4. **Security**: Vulnerability scanning
5. **Deploy**: Manual approval to stores

---

For questions about architecture, see CONTRIBUTING.md for development guidelines.
