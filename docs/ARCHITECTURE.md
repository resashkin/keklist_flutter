# keklist Architecture

This document describes the overall architecture and design patterns used in keklist.

## Overview

keklist follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│  (UI, Widgets, BLoCs/Cubits)        │
├─────────────────────────────────────┤
│         Domain Layer                │
│  (Business Logic, Entities)         │
├─────────────────────────────────────┤
│         Data Layer                  │
│  (Repositories, Local Storage)      │
└─────────────────────────────────────┘
```

## Layers

### Presentation Layer

Located in `lib/presentation/`

**Responsibilities:**
- UI rendering
- User interaction handling
- State management
- Navigation

**Components:**
- **Screens**: Full-page views (`lib/presentation/screens/`)
- **Widgets**: Reusable UI components (`lib/presentation/core/widgets/`)
- **BLoCs/Cubits**: State management (`lib/presentation/blocs/`, `lib/presentation/cubits/`)

**Pattern: BLoC (Business Logic Component)**

We use the BLoC pattern for state management:

```dart
// Event
class MindCreate extends MindEvent {
  final String note;
  final String emoji;
  // ...
}

// State
class MindList extends MindState {
  final Iterable<Mind> values;
  // ...
}

// BLoC
class MindBloc extends Bloc<MindEvent, MindState> {
  MindBloc() {
    on<MindCreate>(_createMind);
    // ...
  }

  Future<void> _createMind(MindCreate event, Emitter emit) {
    // Handle event
  }
}
```

### Domain Layer

Located in `lib/domain/`

**Responsibilities:**
- Business logic
- Entity definitions
- Repository interfaces
- Services

**Key Entities:**

#### Mind
```dart
class Mind {
  final String id;
  final String emoji;
  final String note;
  final int dayIndex;
  final DateTime creationDate;
  final int sortIndex;
  final String? rootId;
}
```

A Mind is the core entity representing a single entry (thought/emotion/moment).

**Repository Pattern:**

Repositories abstract data access:

```dart
abstract class MindRepository {
  Stream<Iterable<Mind>> get stream;
  Future<Mind> createMind({required Mind mind});
  Future<void> updateMind({required Mind mind});
  Future<void> deleteMind({required String mindId});
  // ...
}
```

### Data Layer

Located in `lib/domain/repositories/*/`

**Responsibilities:**
- Data persistence
- Local storage (Hive)
- Data transformation

**Hive Storage:**

We use Hive for local-first data storage:

```dart
@HiveType(typeId: 1)
class MindObject extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String emoji;
  // ...
}
```

## State Management

### BLoC Pattern

**Why BLoC?**
- Clear separation between UI and business logic
- Testable
- Reactive
- Framework agnostic

**BLoC vs Cubit:**

- **BLoC**: For complex state with multiple events → Use for minds, settings
- **Cubit**: For simpler state with direct functions → Use for search, simple toggles

### State Flow

```
User Action
    ↓
Event Dispatched
    ↓
BLoC Receives Event
    ↓
Repository Called
    ↓
State Emitted
    ↓
UI Rebuilds
```

Example:

```dart
// 1. User taps create button
// UI dispatches event
context.read<MindBloc>().add(MindCreate(
  note: 'My first mind',
  emoji: '😊',
));

// 2. BLoC handles event
Future<void> _createMind(MindCreate event, Emitter emit) async {
  final mind = Mind(/* ... */);
  await _repository.createMind(mind: mind);
}

// 3. Repository stream emits new state
// 4. BlocBuilder rebuilds UI
```

## Dependency Injection

Located in `lib/di/`

We use `flutter_simple_dependency_injection` for DI:

```dart
class MainContainer {
  Injector initialize(Injector injector) {
    // Register repositories
    injector.map<MindRepository>(
      (i) => MindHiveRepository(/* ... */),
      isSingleton: true,
    );

    // Register BLoCs
    injector.map<MindBloc>(
      (i) => MindBloc(
        mindRepository: i.get<MindRepository>(),
      ),
    );

    return injector;
  }
}
```

## Data Flow

### Creating a Mind

```
┌──────────┐  Event   ┌──────────┐  Call    ┌────────────┐
│   UI     │ ───────> │ MindBloc │ ───────> │ Repository │
└──────────┘          └──────────┘          └────────────┘
                            │                      │
                            │                      ↓
                            │                ┌──────────┐
                            │                │   Hive   │
                            │                └──────────┘
                            │                      │
                            │ ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
                            ↓           Stream
                      ┌──────────┐
                      │  State   │
                      └──────────┘
                            │
                            ↓
                      ┌──────────┐
                      │    UI    │
                      │ Rebuilds │
                      └──────────┘
```

## Localization

We use Flutter's built-in localization with ARB files:

```
lib/l10n/
├── app_en.arb     # English (source)
├── app_ru.arb     # Russian
├── app_de.arb     # German
└── ...
```

**Usage:**

```dart
// In widget
final localizations = AppLocalizations.of(context)!;
Text(localizations.welcomeMessage);
```

**Adding new strings:**

1. Add to `app_en.arb`:
```json
{
  "myNewString": "Hello World",
  "@myNewString": {
    "description": "Greeting message"
  }
}
```

2. Run `flutter gen-l10n`

3. Use in code: `localizations.myNewString`

## Navigation

We use Flutter's built-in navigation:

```dart
// Push new screen
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => MindInfoScreen(mind: mind),
  ),
);

// Pop
Navigator.of(context).pop();
```

**Main navigation is tab-based:**
- Calendar (Mind Collection)
- Insights
- Settings
- Profile
- Today (optional)
- Debug Menu (dev only)

## Offline-First Architecture

keklist is designed to work offline-first:

1. **All data stored locally** in Hive
2. **No network dependency** for core functionality
3. **Data export/import** via CSV for backup

### Hive Boxes

```dart
// Initialize Hive
await Hive.initFlutter();

// Open boxes
await Hive.openBox<MindObject>('minds');
await Hive.openBox<SettingsObject>('settings');
```

## Feature: Onboarding

New users see an onboarding flow:

```
┌─────────────┐
│ App Launch  │
└──────┬──────┘
       │
       ↓
┌─────────────────┐
│ Check Settings  │
│ hasSeenOnboard? │
└──────┬──────────┘
       │
   ┌───┴───┐
   │       │
  No      Yes
   │       │
   ↓       ↓
┌──────┐ ┌──────┐
│Onboard│ │ Main │
│Screen │ │ App  │
└───┬───┘ └──────┘
    │
    ↓
┌─────────┐
│ Create  │
│ Sample  │
│ Minds   │
└────┬────┘
     │
     ↓
┌─────────┐
│  Main   │
│   App   │
└─────────┘
```

## Code Generation

We use `build_runner` for:

1. **Hive TypeAdapters** (`*.g.dart`)
2. **JSON Serialization** (`*.g.dart`)

```bash
# Generate code
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generate on file changes)
dart run build_runner watch
```

## Testing Strategy

```
lib/                    test/
├── domain/            ├── domain/
│   └── *.dart        │   └── *_test.dart
├── presentation/      ├── presentation/
│   └── *.dart        │   └── *_test.dart
```

**Test Types:**

1. **Unit Tests**: Business logic, utilities
2. **Widget Tests**: UI components
3. **Integration Tests**: Full user flows

## Performance Considerations

1. **Lazy Loading**: Minds loaded on-demand via infinite scroll
2. **Efficient Indexing**: Day index for quick date-based queries
3. **Stream-based Updates**: Reactive UI updates
4. **Local Storage**: No network latency

## Security

1. **Local-First**: All data stored locally
2. **No External APIs** for core functionality
3. **Optional Biometric Auth**: For sensitive content
4. **Sensitive Content Toggle**: Hide mind content

## Future Considerations

- Cloud sync (optional)
- End-to-end encryption for cloud storage
- Cross-device synchronization
- Collaborative features

---

For questions or clarifications, contact [@resashkin](https://t.me/resashkin)
