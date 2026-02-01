# Debug Menu Visibility Implementation

## Overview
Implemented a hidden debug menu that becomes visible after tapping the Settings appbar title 10 times. The visibility state is persisted in settings.

## Implementation Details

### 1. Domain Layer

**File: `lib/domain/repositories/settings/settings_repository.dart`**
- Added `isDebugMenuVisible` field to `KeklistSettings`
- Defaults to `false` in `initial()` factory

**File: `lib/domain/repositories/settings/object/settings_object.dart`**
- Added `@HiveField(10, defaultValue: false) late bool isDebugMenuVisible;`
- Generated adapter includes read/write for the field

### 2. BLoC Layer

**File: `lib/presentation/blocs/settings_bloc/settings_event.dart`**
- Added `SettingsEnableDebugMenu` event

**File: `lib/presentation/blocs/settings_bloc/settings_bloc.dart`**
- Registered handler: `on<SettingsEnableDebugMenu>(_enableDebugMenu);`
- Handler updates settings with `isDebugMenuVisible: true`

### 3. UI Layer

**File: `lib/presentation/screens/settings/settings_screen.dart`**

State variables:
- `int _appBarTapCount = 0;` - Tap counter
- `bool _isDebugMenuVisible = false;` - Visibility flag from settings

AppBar with tap detector:
```dart
appBar: AppBar(
  title: GestureDetector(
    onTap: _handleAppBarTap,
    child: Text(context.l10n.settings),
  ),
),
```

Tap handler:
- Counts taps on "Settings" title
- After 10 taps: dispatches `SettingsEnableDebugMenu` event
- Shows confirmation snackbar
- Resets counter

Conditional debug menu tile:
```dart
if (_isDebugMenuVisible)
  SettingsTile.navigation(
    title: Text(context.l10n.debugMenu),
    leading: const Icon(Icons.bug_report, color: Colors.orange),
    onPressed: (_) => _showDebugMenu(),
  ),
```

### 4. Debug Menu Features

**File: `lib/presentation/screens/debug_menu/debug_menu_screen.dart`**
- Feature Flags section (existing debug toggles)
- Development Tools section with "Reset Lazy Onboarding" functionality

Reset Lazy Onboarding:
- Deletes all onboarding parent minds (with `ONBOARDING_` prefix)
- Deletes all comment minds (children of onboarding parents)
- Resets `hasSeenLazyOnboarding` flag to `false`
- Shows confirmation dialog before executing

## Updated Files

### Domain
- `lib/domain/repositories/settings/settings_repository.dart`
- `lib/domain/repositories/settings/object/settings_object.dart`
- `lib/domain/repositories/settings/object/settings_object.g.dart` (generated)
- `lib/domain/migrations/migration_runner.dart`

### Presentation
- `lib/presentation/blocs/settings_bloc/settings_bloc.dart`
- `lib/presentation/blocs/settings_bloc/settings_event.dart`
- `lib/presentation/blocs/lazy_onboarding_bloc/lazy_onboarding_bloc.dart`
- `lib/presentation/blocs/lazy_onboarding_bloc/lazy_onboarding_event.dart`
- `lib/presentation/blocs/lazy_onboarding_bloc/lazy_onboarding_state.dart`
- `lib/presentation/screens/settings/settings_screen.dart`
- `lib/presentation/screens/debug_menu/debug_menu_screen.dart`
- `lib/presentation/screens/tabs_settings/tabs_settings_screen.dart`

### Tests
- `test/presentation/blocs/lazy_onboarding_bloc/lazy_onboarding_bloc_test.dart`
- `test/domain/migrations/migration_runner_test.dart`

## How It Works

1. User opens Settings screen
2. User taps on "Settings" title 10 times
3. After 10th tap:
   - `SettingsEnableDebugMenu` event is dispatched
   - Settings updated with `isDebugMenuVisible = true`
   - "Debug menu enabled" snackbar appears
   - Debug menu tile becomes visible
4. Debug menu remains visible on subsequent app launches
5. User can access debug menu → Reset Lazy Onboarding

## Testing

1. Open Settings
2. Tap "Settings" title 10 times
3. Verify snackbar appears
4. Verify "Debug Menu" appears in Appearance section
5. Tap Debug Menu
6. Verify "Reset Lazy Onboarding" option exists
7. Test reset functionality
8. Restart app - verify debug menu is still visible

## Bug Fixes

- Fixed syntax error in `settings_screen.dart`: Changed `mode: .externalApplication` to `mode: LaunchMode.externalApplication`
- Fixed naming conflict: Changed state from `LazyOnboardingReset` to `LazyOnboardingResetComplete`
- Added all required `isDebugMenuVisible` parameters to KeklistSettings constructors throughout codebase
