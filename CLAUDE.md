# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚀 Common Development Commands

### Code Generation & Build
```bash
# Generate Riverpod providers, Freezed classes, and JSON serialization
dart run build_runner build --delete-conflicting-outputs

# Watch mode for continuous code generation
dart run build_runner watch

# Run the app on emulator/device
flutter run

# Build APK or bundle
flutter build apk --split-per-abi
flutter build appbundle
```

### Testing
```bash
# Run all tests
flutter test

# Run tests for a specific file
flutter test test/data/repositories/patient_repository_impl_test.dart

# Run tests with coverage
flutter test --coverage

# Run a single test by name
flutter test --name "should return Patient when data source succeeds"
```

### Linting & Analysis
```bash
# Analyze code for lint issues
flutter analyze

# Format code
dart format lib test
```

### Firebase Development
```bash
cd firebase

# Start local emulators (Firestore, Auth, Functions)
firebase emulators:start

# Deploy cloud functions to production
firebase deploy --only functions

# Deploy Firestore security rules
firebase deploy --only firestore:rules

# Deploy storage rules
firebase deploy --only storage
```

**Important:** Before committing, ensure `useEmulator = false` in `lib/main.dart` for production builds.

---

## 🏗️ Architecture Overview

### Project Structure: Clean Architecture + Mono-Repo
```
lib/
├── domain/              # Pure business logic, entities, use cases, and abstract repositories
├── data/                # Firebase/Dio implementations, DTOs, repository implementations
├── presentation/        # Flutter widgets, pages, Riverpod providers
└── router/              # GoRouter configuration with deep linking support

firebase/
├── functions/src/       # TypeScript cloud functions (payments, cron tasks, webhooks)
├── firestore.rules      # Firestore security rules (multi-tenant isolation)
└── firestore.indexes.json

test/                    # Unit and integration tests (mirrored structure from lib/)
```

### Data Flow
1. **UI** calls **Providers** (Riverpod)
2. **Providers** execute **Use Cases**
3. **Use Cases** delegate to **Repositories**
4. **Repositories** call either **Firebase** (reads) or **Cloud Functions** (critical writes)
5. **Repositories** map Firebase objects to **Domain Entities** (via DTOs)
6. **Failures** are converted to domain `Failure` objects, never thrown as exceptions

### Core Patterns

#### State Management (Riverpod)
- Use `@riverpod` generators for providers (not manual `FamilyNotifier`)
- Prefer `async` providers that return `Future<T>` (auto-converts to `AsyncValue`)
- Implement optimistic UI updates: update local state immediately, revert on server error
- Use `.when()` to handle loading, data, and error states in UI

#### Multi-Tenancy & Security
- **Firestore Rules:** All queries must filter by `providerId` (healthcare provider ID)
- No cross-tenant data leakage; each rule enforces strict ownership checks
- Never log PII (patient names, phone numbers, debt amounts) in production

#### Cloud Functions (TypeScript)
- **Payments:** `registerPayment()` applies ledger logic using Firestore Transactions (FIFO debt settlement)
- **Cron:** `monthlyDebtProcessor` auto-applies compound interest on day 28
- **Webhooks:** `onPaymentCreated`, `onAppointmentDeleted` maintain data consistency
- All functions validate input and use `check()` for authorization
- **Errors:** Throw `HttpsError` with meaningful codes (e.g., `invalid-argument`, `permission-denied`)

#### Data Persistence
- **Reads:** Direct Firestore queries (low latency, offline support via caching)
- **Critical Writes:** Only via Cloud Functions (transactional, server-validated)
- **Idempotency:** Cloud Functions use check-before-write pattern to prevent duplicates

---

## 🧪 Testing & TDD

### Test Structure
- **Unit Tests:** Repositories, Use Cases, models
- **Integration Tests:** Riverpod providers with fake Firestore
- Use `fake_cloud_firestore` for offline testing without emulators
- Use `mocktail` for mocking external dependencies (Dio, Firebase Auth)

### Mandatory Test Coverage
- **Negative paths:** HTTP 401/404/500 errors, malformed JSON, network timeouts, user cancellations
- **Edge cases:** Empty lists, null values, boundary conditions (e.g., negative debt balances)
- **Firestore transactions:** Test concurrent writes and rollback scenarios
- **Use Case logic:** Test FIFO payment settlement, interest calculations, recurring appointments

### Running Tests Locally
```bash
# All tests
flutter test

# Specific test file
flutter test test/domain/use_cases/ledger_use_cases_test.dart

# Watch mode
dart run build_runner watch & flutter test --watch
```

---

## 🔥 Key Technical Decisions

### Why Clean Architecture?
- **Testability:** Domain layer is 100% pure Dart (no Firebase, no Flutter)
- **Maintainability:** Clear separation of concerns across three layers
- **Scalability:** Easy to swap Firebase with another backend

### Why Riverpod over Provider/BLoC?
- **Type-safe:** Compile-time safety with code generation
- **Reactive:** Automatic dependency graph; changes propagate instantly
- **Testability:** Can pass custom dependencies in tests without InheritedWidget complexity
- **Optimistic updates:** `AsyncValue.guard()` enables easy rollback on failure

### Why Cloud Functions for Critical Writes?
- **Security:** Server validates all ledger operations; client can't manipulate balances
- **Atomicity:** Firestore Transactions ensure payment settlement is all-or-nothing
- **Audit trail:** All writes logged; easier to debug financial discrepancies

### Why GoRouter?
- **Type-safe:** Routes are strongly typed (e.g., `/patients/:id` → `PatientRoute(id)`)
- **Deep linking:** Share direct links to screens; IDs fetch data on-the-fly
- **Offline:** Routes persist across app restarts
- **Future-proof:** Same routing logic works on Web and native

---

## 📋 Important Conventions

### Naming & Modularization
- **Classes >200 lines:** Must be split; consider extracting logic to use cases or helper methods
- **Widgets >100 lines:** Extract to separate file in `presentation/widgets/`
- **Freezed classes:** Use `@freezed` for immutability; include `Equatable` mixin for value comparison
- **DTO naming:** Use `{EntityName}Model` for Firestore/API models; map to `{EntityName}` domain entities

### UI Standards (Material Design 3)
- **Never hardcode colors:** Use `Theme.of(context).colorScheme.primary`, `.surface`, etc.
- **Never hardcode spacing:** Use a constants class (e.g., `AppSpacing.md = 16`) or `SizedBox` with 8px increments
- **Skeleton loading:** Use `skeletonizer` for initial loads (not spinners)
- **Error handling in UI:** React to `AsyncError` state; show snackbars or error widgets

### Security & Validation
- **No PII in logs:** Never `print()` patient names, phone numbers, or debt amounts
- **Health data protection:** Only store "concept" (e.g., "Consultation"); never diagnoses or notes
- **Input validation:** Validate at data source boundaries (Firestore Rules, Cloud Functions, form inputs)
- **Secrets:** Use Firebase Secrets Manager or environment variables; never hardcode API keys

### Code Organization in Data Layer
- **DataSources:** Keep Firebase/Dio calls isolated in separate files (`firebase_data_source.dart`, `dio_data_source.dart`)
- **Repositories:** Map DataSource output to domain entities; handle errors and transformations
- **Models (DTOs):** Deserialize raw JSON; use Freezed + `json_serializable` for auto-generation

---

## 🔗 Dependencies & Versions

**Flutter SDK:** >=3.7.2
**State:** Riverpod 2.6.1 with code generation
**Routing:** GoRouter 12.1.1
**Firebase:** Auth 5.3.1, Cloud Firestore 5.4.3, Cloud Functions 5.6.2
**Data:** Freezed 2.5.7, Dio 5.7.0, fpdart (functional programming utilities)
**UI:** Material 3 (native), Google Fonts, Skeletonizer (skeleton loaders)
**Testing:** Mocktail 1.0.3, fake_cloud_firestore 3.1.0

---

## 🛠️ Development Workflow

### Before Implementing a Feature
1. **Design Phase:** Sketch domain entities (Patient, Appointment, Payment), use cases, and repository contracts
2. **Contract First:** Write abstract repository interfaces in `domain/`
3. **Test Driven:** Write failing tests in `test/domain/use_cases/` or `test/data/repositories/`

### During Implementation
1. **Bottom-Up:** Start with domain → data → providers → UI
2. **Code Gen:** Run `build_runner watch` continuously to catch serialization errors early
3. **Emulator-First:** Test all Firebase logic with local emulators before pushing to staging

### Before Pushing to Main
1. Run `flutter analyze` and `flutter test`
2. Ensure all tests pass (unit + integration)
3. Verify `useEmulator = false` in `main.dart`
4. Check for hardcoded colors/spacing/secrets in diffs

---

## 📖 Related Documentation

- **README.md:** High-level product and feature overview
- **docs/ARCHITECTURE.md:** Detailed technical approach (CQRS, Outbox Pattern, Optimistic UI)
- **docs/design_system.md:** Color palette, typography, spacing scale
- **.agent/rules/:** Project-specific coding rules (TDD, Firebase integration, security, UI standards)

