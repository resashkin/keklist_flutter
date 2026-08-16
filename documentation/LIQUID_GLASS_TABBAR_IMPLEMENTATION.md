# Liquid Glass Tab Bar Implementation

## Overview

Adds an iOS-native `UITabBar` rendering path that picks up the iOS 26 **Liquid Glass** system effect, gated behind a debug-menu toggle. Android, Web, and iOS users with the toggle off continue to see the existing `AdaptiveBottomNavigationBar`.

Built on top of the [`native_liquid_glass`](https://pub.dev/packages/native_liquid_glass) package (`^0.2.10`), which bridges Flutter to a real `UITabBarController` via a platform view. On iOS 26 the system applies Liquid Glass automatically; on older iOS the package falls back to the standard system tab bar style.

The Flutter team has stated they will not add Liquid Glass to `CupertinoTabBar` until after the Material/Cupertino split (Flutter issue [#170310](https://github.com/flutter/flutter/issues/170310)), so a platform-view bridge is currently the only way to get the real OS effect.

## Implementation Details

### 1. Domain Layer

**`lib/domain/repositories/tabs/models/tabs_settings.dart`**
- Added `sfSymbolName` getter on `TabType`. Maps each tab to an SF Symbol so the native `UITabBar` can render it correctly under Liquid Glass:
  - `calendar` → `calendar`
  - `today` → `sun.max`
  - `insights` → `chart.bar.fill`
  - `profile` → `person.crop.circle`
  - `settings` → `gearshape`
  - `debugMenu` → `ant`

**`lib/domain/repositories/debug_menu/debug_menu_repository.dart`**
- Added `DebugMenuType.useLiquidGlass` flag.

**`lib/domain/repositories/debug_menu/debug_menu_hive_repository.dart`**
- Added a default of `true` for the new flag in `_getDefaultValueForFlag` — Liquid Glass is opt-out, not opt-in. No Hive migration required: `DebugMenuObject` stores flag-name strings, so new enum values are absorbed automatically on first launch via `_initializeDefaultValues`. Renaming the enum value also invalidates any older row under the old key, so the new default applies cleanly.

### 2. BLoC Layer

No new BLoCs or events. The existing `DebugMenuBloc` already streams the full flag list; `TabsContainerScreen` subscribes to it and extracts the `useLiquidGlass` value.

### 3. UI Layer

**`lib/presentation/core/widgets/liquid_glass_navigation_bar.dart`** *(new)*
- Wraps `LiquidGlassTabBar` from `native_liquid_glass`.
- Builds `LiquidGlassTabItem`s from `List<TabType>` with `NativeLiquidGlassIcon.sfSymbol(tab.sfSymbolName)` + `tab.localizedLabel(context)`.
- Tint = `Theme.of(context).colorScheme.primary`.
- Uses a `ValueKey` derived from the tab-name signature so the underlying platform view is rebuilt cleanly when the user reconfigures tabs at runtime.

**`lib/presentation/core/widgets/bottom_navigation_bar.dart`**
- `AdaptiveBottomNavigationBar` gained two optional parameters: `tabTypes` and `useLiquidGlass`.
- iOS branch: when `useLiquidGlass && tabTypes != null`, renders `LiquidGlassNavigationBar`; otherwise renders `CupertinoTabBar` as before.
- Android/Web branches unchanged.

**`lib/presentation/screens/tabs_container/tabs_container_screen.dart`**
- Subscribes to `DebugMenuBloc` and tracks `_useLiquidGlass` in local state (defaults `true`).
- Passes `tabTypes: _tabTypes` and `useLiquidGlass: _useLiquidGlass` to `AdaptiveBottomNavigationBar`.
- Sets `Scaffold.extendBody: _useLiquidGlass` so the body paints behind the bar. Liquid Glass relies on seeing the content underneath — without this the bar sits in an opaque strip and the effect is invisible. Scoped to the toggle so non-Liquid-Glass paths keep their current layout.
- Wraps the body in a `MediaQuery` override (`_wrapBodyForLiquidGlass`) that mirrors `padding.bottom` into `viewPadding.bottom`. Inner Scaffolds (e.g. `MindDayCollectionScreen`) anchor their `centerFloat` FAB to `viewPadding.bottom`; without the override, the FAB lands behind the floating tab bar.

**`lib/presentation/screens/tabs_settings/tabs_settings_screen.dart`**
- Subscribes to `DebugMenuBloc` and tracks `_useLiquidGlass` (defaults `true`).
- Builds a `_tabTypes` list parallel to `_tabItems` (debugMenu filtered out, matching the existing item list).
- Passes `tabTypes` + `useLiquidGlass` to `AdaptiveBottomNavigationBar` and sets `Scaffold.extendBody: _useLiquidGlass` so the demo bar at the bottom actually shows the effect.

**`lib/presentation/screens/debug_menu/debug_menu_screen.dart`**
- Added title and description strings for the new `useLiquidGlass` flag. Strings are hardcoded English (consistent with the rest of the debug menu — no ARB churn).

### 4. iOS Project

**`ios/Runner.xcodeproj/project.pbxproj`**
- `IPHONEOS_DEPLOYMENT_TARGET` bumped from `13.0` → `15.0` for all six Runner-target build configurations (Debug / Release / Profile, both project-level and target-level). Widget extension targets at `16.0` left untouched.

**`pubspec.yaml`**
- Added `native_liquid_glass: ^0.2.10`.

## How It Works

1. On app launch, `DebugMenuHiveRepository._initializeDefaultValues` ensures every `DebugMenuType` (including `useLiquidGlass`) has a row in the Hive box.
2. `TabsContainerScreen.initState` subscribes to `DebugMenuBloc`. When the flag changes, `_useLiquidGlass` updates and the tab bar rebuilds.
3. The user enables the flag in **Debug Menu → Feature Flags → "Liquid Glass Tab Bar (iOS)"**.
4. On iOS, `AdaptiveBottomNavigationBar` picks the `LiquidGlassNavigationBar` branch instead of `CupertinoTabBar`.
5. `LiquidGlassNavigationBar` builds a `LiquidGlassTabBar` with SF Symbol icons and the app's primary color as the selected tint.
6. The native `UITabBarController` renders. On iOS 26 the system applies Liquid Glass; on older iOS the bar looks like a standard system tab bar.

## Updated Files

**Domain**
- `lib/domain/repositories/tabs/models/tabs_settings.dart` (added `sfSymbolName`)
- `lib/domain/repositories/debug_menu/debug_menu_repository.dart` (new enum value)
- `lib/domain/repositories/debug_menu/debug_menu_hive_repository.dart` (default value)

**Presentation**
- `lib/presentation/core/widgets/liquid_glass_navigation_bar.dart` *(new)*
- `lib/presentation/core/widgets/bottom_navigation_bar.dart` (dispatcher)
- `lib/presentation/screens/tabs_container/tabs_container_screen.dart` (subscribe + pass flag)
- `lib/presentation/screens/debug_menu/debug_menu_screen.dart` (title/description strings)

**iOS / Build**
- `ios/Runner.xcodeproj/project.pbxproj` (deployment target 13.0 → 15.0)
- `pubspec.yaml` (added `native_liquid_glass`)

## Testing

Manual:
1. `fvm flutter pub get` (also triggers `pod install` on iOS).
2. `fvm flutter run -d <ios-26-simulator>`.
3. Open **Debug Menu** → enable **"Liquid Glass Tab Bar (iOS)"**.
4. Pop back to the tab container — the bar should switch instantly without restart.
5. Open Tab Settings, reconfigure the visible tabs, and confirm the Liquid Glass bar rebuilds with the new tabs.
6. On an iOS 15–25 simulator, repeat — the bar should render as a standard system tab bar (no glass, no errors).
7. Confirm Android/Web are unaffected.

No automated tests added — the widget is a thin wrapper around a platform view; integration tests against a `UiKitView` are not meaningfully isolatable.

## Edge Cases & Considerations

- **Reselect tap (`goToToday`)**: `LiquidGlassTabBar.onTabSelected` is treated as a change callback. The current behavior — tapping the active "Today" tab to scroll back — is preserved by the `onTap` wrapper in `TabsContainerScreen`, but only if the package fires the callback on re-tap. If iOS 26 swallows the re-tap, this will silently no-op. Acceptable per the design discussion.

- **Overlays above the bar**: Platform views render above Flutter content. Bottom sheets via `modal_bottom_sheet` and dialogs via `adaptive_dialog` need to layer above the native bar. `native_liquid_glass` documents route-aware hiding; if a regression appears (e.g. a sheet sliding under the bar), revisit by either disabling the toggle for that route or by wrapping problematic flows in a separate `Navigator`.

- **Dynamic tab reconfiguration**: When `TabsContainerBloc` reports a new tab set, `_tabTypes` changes and the `LiquidGlassNavigationBar` rebuilds with a new `ValueKey` (the tab-name signature). This forces the underlying platform view to recreate rather than reuse stale state.

- **iOS deployment target**: Bumped to 15.0. If `native_liquid_glass` ever requires a higher minimum (e.g. iOS 16), `pod install` will surface it and the target needs to be bumped further. Widget/Watch extension targets at 16.0 are independent and were not changed.

- **Fallback styling on iOS < 26**: No Liquid Glass effect — the package renders a standard system `UITabBar`. Visually similar to `CupertinoTabBar` but routed through a platform view, which carries the standard hybrid-composition perf cost. If this becomes a perceptible problem on older devices, gate the toggle behind a runtime iOS version check.

- **Localization**: Tab labels come from `TabType.localizedLabel(context)` (existing ARB keys), so all 11 languages remain supported. The debug-menu title/description are hardcoded English consistent with the rest of the debug menu.

- **Why not first-party Flutter support**: As of June 2026, `CupertinoTabBar` does not implement Liquid Glass and the Flutter team is not accepting contributions toward it until the Material/Cupertino split lands (issue [#101479](https://github.com/flutter/flutter/issues/101479)). Realistic ship window for first-party support is late 2026 at earliest. This implementation can be removed when that ships.
