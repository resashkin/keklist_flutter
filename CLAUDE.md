# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

keklist is an open-source Flutter app for collecting "minds" (emoji + text thoughts/moments) with offline support, available on iOS, Android, and Web. The app uses local-first architecture with Hive for storage and includes features like insights/analytics, calendar view, reflections, and audio notes.

## Commands

### Code Generation

The project uses code generation for Hive models, JSON serialization, and localization:

```bash
# Interactive generation menu (recommended)
./scripts/generate.sh

# Generate Hive adapters and JSON serialization (.g.dart files)
dart run build_runner build --delete-conflicting-outputs

# Generate localization files from ARB files
flutter gen-l10n

# Clean generated files
dart run build_runner clean
flutter clean
```

**Important**: After modifying Hive model classes (with `@HiveType` annotations) or classes with `@JsonSerializable`, you MUST run code generation to update the `.g.dart` files.

### Running the App

```bash
# Run on specific platform
flutter run -d <device>

# Run in release mode
flutter run --release
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/domain/services/entities/mind_note_content_test.dart

# Run tests with coverage
flutter test --coverage
```

### Linting

```bash
# Analyze code
flutter analyze
```

## Architecture

### High-Level Structure

The codebase follows a **BLoC + Repository** pattern with clear separation of concerns:

```
lib/
├── domain/              # Business logic & data layer
│   ├── repositories/    # Data access abstractions (interfaces + Hive implementations)
│   ├── services/        # Business entities (Mind, Settings, etc.)
│   └── migrations/      # Data schema migration system
├── presentation/        # UI layer
│   ├── blocs/          # BLoC state management
│   ├── cubits/         # Cubit state management (simpler than BLoC)
│   ├── screens/        # Screen-level widgets
│   └── core/           # Shared UI utilities, widgets, helpers
├── di/                 # Dependency injection container
├── l10n/               # Localization ARB files
└── native/             # Platform-specific code (iOS Watch, Web Telegram)
```

### Key Architectural Patterns

#### Repository Pattern
All data access goes through repository interfaces defined in `lib/domain/repositories/`. Implementations use Hive (local NoSQL database):

- `MindRepository` - CRUD operations for Mind entities
- `SettingsRepository` - App settings persistence
- `DebugMenuRepository` - Debug menu state
- `TabsSettingsRepository` - Tab configuration
- `AppFileRepository` - File system operations

#### BLoC State Management
The app uses `flutter_bloc` for state management:

- **BLoCs** are in `lib/presentation/blocs/` - handle complex state with events (e.g., `MindBloc`, `SettingsBloc`)
- **Cubits** are in `lib/presentation/cubits/` - handle simpler state without events (e.g., `MindSearcherCubit`)
- All BLoCs are provided at app level in `main.dart` via `MultiBlocProvider`

#### Dependency Injection
Uses `flutter_simple_dependency_injection` via `MainContainer` in `lib/di/containers.dart`. The container is initialized in `main.dart` and provides repositories and services to BLoCs.

#### Custom Base Classes
- `KekWidgetState<W>` - Base state class for stateful widgets, includes automatic subscription cleanup via `DisposeBag` mixin
- Use `subscribeToBloc<B>()` from `KekWidgetState` to listen to BLoC state changes
- Use `.disposed(by: this)` extension on `StreamSubscription` to auto-cancel on dispose

#### Migration System
The app includes a data migration system (`lib/domain/migrations/`) for schema changes:
- Migrations run automatically on app startup in `main.dart` via `MigrationRunner`
- Each migration has a version number and description
- Migrations are registered in `MigrationRegistry`
- Current schema version is tracked in `SettingsRepository.dataSchemaVersion`
- When adding migrations, increment version and implement the `Migration` interface

### Core Domain Entity: Mind

The central entity is `Mind` (`lib/domain/services/entities/mind.dart`):
- `id` - UUID
- `emoji` - Single emoji character
- `note` - Raw note string (can contain text + audio references)
- `dayIndex` - Day offset from epoch (for calendar organization)
- `creationDate` - Timestamp
- `sortIndex` - Position within a day
- `rootId` - Optional parent Mind ID (for reflections/nested minds)

The `note` field is parsed into `MindNoteContent` which can contain:
- Plain text pieces
- Audio note references (file paths)

### Localization

The app supports 11 languages (en, ru, es, it, de, ja, kk, ky, uz, zh, sr). Localization files are in `lib/l10n/`:
- ARB files: `app_<locale>.arb` (e.g., `app_en.arb`)
- Template: `app_en.arb`
- After modifying ARB files, run `flutter gen-l10n` to regenerate localization code
- Access translations via `AppLocalizations.of(context)!.translationKey`

#### Handling Quotes in ARB Files

**IMPORTANT**: ARB files are JSON files. Follow these rules for strings containing quotes:

1. **To include double quotes in a string**: Use `\"` (single backslash + quote)
   ```json
   "key": "Click \"Button\" to continue"
   ```
   Result: Click "Button" to continue

2. **DO NOT double-escape**: `\\\"` will display backslashes in the UI
   ```json
   "key": "Click \\\"Button\\\""  ❌ WRONG - displays: Click \"Button\"
   ```

3. **Single quotes don't need escaping**: Can be used directly
   ```json
   "key": "Click 'Button' to continue"
   ```
   Result: Click 'Button' to continue

4. **Language-specific quotation marks**: Different languages use different conventions
   - English: "double" or 'single'
   - Russian/German: «guillemets»
   - Japanese: 「corner brackets」
   - Choose appropriate style for each language, all work in ARB files without escaping

#### Removing Unused Localization Keys

**IMPORTANT**: When removing UI features or dialogs, always clean up their unused localization keys:

1. **Remove from ALL 11 language files**: Keys must be removed from all ARB files:
   - `app_en.arb`, `app_ru.arb`, `app_es.arb`, `app_it.arb`, `app_de.arb`
   - `app_ja.arb`, `app_kk.arb`, `app_ky.arb`, `app_uz.arb`, `app_zh.arb`
   - `app_sr.arb`, `app_sr_Latn.arb`

2. **Remove both key and metadata**: In files that have metadata (like English), remove both:
   ```json
   "unusedKey": "Some text",  ❌ Remove this
   "@unusedKey": {            ❌ Remove this too
       "description": "..."
   },
   ```

3. **Fix trailing commas**: After removing the last key in a file, remove the comma from the previous key:
   ```json
   "lastKey": "Text",  ❌ Remove comma
   }
   ```
   Should be:
   ```json
   "lastKey": "Text"   ✅ No comma before closing brace
   }
   ```

4. **Regenerate localization**: After removing keys, run `flutter gen-l10n` to update generated files

5. **Why this matters**: Unused localization keys:
   - Increase app bundle size
   - Create maintenance burden
   - Confuse future developers
   - Make translation updates more expensive

### Environment Variables

Environment variables are stored in `dotenv` file (not committed, template shown):
- `REVENUE_CAT_TEST_API_KEY` - RevenueCat API key for debug builds
- `REVENUE_CAT_PROD_API_KEY` - RevenueCat API key for release builds

Load with `await dotenv.load(fileName: 'dotenv')` in `main.dart`.

### Platform-Specific Code

- **iOS Watch**: `lib/presentation/native/ios/watch/` - Apple Watch communication via `WatchCommunicationManager`
- **Web Telegram**: `lib/native/web/telegram/` - Telegram Web App integration
- Platform detection via `DeviceUtils.safeGetPlatform()` returns `SupportedPlatform` enum

## Important Conventions

### Hive Models
Classes stored in Hive must:
1. Have `@HiveType(typeId: X)` annotation with unique typeId
2. Have `@HiveField(Y)` on each persisted field
3. Have a separate `*Object` class extending `HiveObject` (e.g., `MindObject`, `SettingsObject`)
4. Implement conversion methods: `toObject()` and `fromObject()`
5. Be registered in `main.dart` via `Hive.registerAdapter()`

### JSON Serialization
Classes using JSON serialization must:
1. Have `@JsonSerializable()` annotation
2. Import `part '<filename>.g.dart';`
3. Implement `fromJson` and `toJson` factory/methods
4. Run `dart run build_runner build` after changes

### DisposeBag Pattern
When creating `StreamSubscription` in `KekWidgetState`:
```dart
subscribeToBloc<SettingsBloc>(
  onNewState: (state) {
    // Handle state
  },
)?.disposed(by: this); // Auto-cleanup on dispose
```

### BLoC Event Naming
Events follow the pattern: `<Entity><Action>Event` (e.g., `MindCreatedEvent`, `SettingsUpdatedEvent`)

### Testing
- Unit tests go in `test/` mirroring `lib/` structure
- Use `mocktail` for mocking
- Test files end with `_test.dart`

## Documentation

### Feature Documentation

**IMPORTANT**: When implementing non-trivial features or changes, create comprehensive documentation in the `documentation/` folder.

Documentation should be created for:
- New features (e.g., lazy onboarding, debug menu)
- Architectural changes or patterns
- Complex implementations that future developers need to understand
- Features with specific edge cases or caveats

**Documentation structure:**
```markdown
# Feature Name Implementation

## Overview
Brief description of the feature and its purpose

## Implementation Details
### 1. Domain Layer
- Files modified
- New entities/models added
- Repository changes

### 2. BLoC Layer (if applicable)
- New events/states
- BLoC handlers
- State management logic

### 3. UI Layer
- Screen changes
- Widget additions
- User interactions

## How It Works
Step-by-step explanation of the feature flow

## Updated Files
List of all modified/created files organized by layer

## Testing
How to test the feature manually or via unit tests

## Edge Cases & Considerations
Important notes about the implementation
```

**Example documentation files:**
- `documentation/LAZY_ONBOARDING_IMPLEMENTATION.md` - Lazy onboarding feature
- `documentation/DEBUG_MENU_IMPLEMENTATION.md` - Debug menu visibility implementation

**When NOT to create documentation:**
- Trivial bug fixes
- Simple refactoring without architectural changes
- Minor UI tweaks
- Localization updates
