# Appearance Settings Implementation

## Overview

Introduces a dedicated Appearance settings screen and replaces the boolean Liquid Glass debug flag with a real user setting, `KeklistInterfaceStyle` (Material / Liquid Glass). The screen also hosts the theme mode (light / dark / system), moved out of general settings.

Platform behavior:
- **Android / Web**: Material only. The interface-style control is hidden and the resolver always returns Material.
- **iOS**: Liquid Glass is the default (primary), and users can switch to Material.

## Implementation Details

### 1. Domain Layer

- `repositories/settings/keklist_interface_style.dart` — new `KeklistInterfaceStyle { material, liquidGlass }` enum with `fromIndex`.
- `repositories/settings/object/settings_object.dart` — persisted as `@HiveField(19, defaultValue: 1)` `interfaceStyleIndex` (1 = Liquid Glass). Mapped in `toSettings()`.
- `repositories/settings/settings_repository.dart` — `KeklistSettings.interfaceStyle` field (required), wired through `toObject()` and `initial()`; abstract `updateInterfaceStyle`.
- `repositories/settings/settings_hive_repository.dart` — `updateInterfaceStyle` writes `interfaceStyleIndex`.

The setting graduated out of the debug-menu subsystem: `DebugMenuType.uiTheme` and its debug tile were removed.

### 2. BLoC Layer

- `SettingsChangeInterfaceStyle` event + `_changeInterfaceStyle` handler in `SettingsBloc`.
- The value is read via the existing `SettingsDataState.settings`.

### 3. UI Layer

- `screens/appearance_settings/appearance_settings_screen.dart` — new screen. Interface-style segmented control (shown only when `isLiquidGlassAvailableOnThisPlatform()`), plus the theme picker moved from general settings.
- `screens/settings/settings_screen.dart` — the inline theme tile is replaced by an Appearance navigation tile; `_showThemePicker` removed.
- `core/helpers/interface_style_utils.dart` — `isLiquidGlassAvailableOnThisPlatform()` and `resolveUseLiquidGlass(style)`, the single place platform gating lives.

Consumers now read the interface style from `SettingsBloc` (previously `DebugMenuBloc`): `tabs_container_screen`, `tabs_settings_screen`, `kek_floating_button`.

## How It Works

1. `SettingsObject.interfaceStyleIndex` is loaded into `KeklistSettings.interfaceStyle`.
2. A widget reads `settings.interfaceStyle` and passes it to `resolveUseLiquidGlass`, which returns `true` only on iOS with the Liquid Glass style; every other platform gets Material.
3. Changing the control dispatches `SettingsChangeInterfaceStyle`; the repository persists it and the stream re-emits, rebuilding the tab bar and floating buttons.

## Updated Files

- Domain: `keklist_interface_style.dart` (new), `settings_object.dart`, `settings_repository.dart`, `settings_hive_repository.dart`, `debug_menu_repository.dart`, `debug_menu_hive_repository.dart`, `migration_runner.dart`
- BLoC: `settings_event.dart`, `settings_bloc.dart`, `lazy_onboarding_bloc.dart`
- UI: `appearance_settings_screen.dart` (new), `interface_style_utils.dart` (new), `settings_screen.dart`, `debug_menu_screen.dart`, `tabs_container_screen.dart`, `tabs_settings_screen.dart`, `kek_floating_button.dart`
- Localization: `interfaceStyle` key across all 12 ARB files

## Testing

- `fvm flutter analyze` — clean.
- `fvm flutter test` — updated `KeklistSettings` construction sites in migration and onboarding tests.
- Manual: on iOS switch Material/Liquid Glass in Settings → Appearance and confirm the tab bar and floating buttons update live; verify the control is hidden on Android.

## Edge Cases & Considerations

- No migration: the new Hive field defaults to Liquid Glass (index 1) for existing and new users; platform gating forces Material on non-iOS regardless.
- The previous debug-menu bool preference is not carried over (it was a debug-only, iOS-only toggle).
- `interfaceStyle` is a required field on `KeklistSettings` so every copy-site must preserve it; the resolver is the only place that decides the effective value.
