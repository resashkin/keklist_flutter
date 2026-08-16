# keklist Documentation

This folder contains detailed implementation documentation for non-trivial features and architectural changes in the keklist app.

## Purpose

Each document provides:
- **Overview** - What the feature does and why it was implemented
- **Implementation Details** - Technical architecture across domain, BLoC, and UI layers
- **How It Works** - Step-by-step flow explanation
- **Updated Files** - Complete list of modified/created files
- **Testing** - Manual and automated testing instructions
- **Edge Cases** - Important considerations and caveats

## Available Documentation

### Conventions

- **[CODE_STYLE.md](./CODE_STYLE.md)**
  Source of truth for code style: one-line comments only, self-documenting code, and moving complex descriptions into this folder.

### Features

- **[APPEARANCE_SETTINGS_IMPLEMENTATION.md](./APPEARANCE_SETTINGS_IMPLEMENTATION.md)**
  Dedicated Appearance screen with interface style (Material / Liquid Glass, iOS-only) and theme mode. Replaces the boolean Liquid Glass debug flag with a persisted `KeklistInterfaceStyle` user setting.

- **[LAZY_ONBOARDING_IMPLEMENTATION.md](./LAZY_ONBOARDING_IMPLEMENTATION.md)**
  Lazy onboarding system that shows educational minds to new users. Uses ID prefix pattern for identification and function references for type-safe localization.

- **[DEBUG_MENU_IMPLEMENTATION.md](./DEBUG_MENU_IMPLEMENTATION.md)**
  Hidden debug menu accessible via 10-tap unlock on Settings appbar. Includes lazy onboarding reset functionality for development/testing.

## Contributing Documentation

When implementing new features, follow the documentation template defined in [CLAUDE.md](../CLAUDE.md#documentation).

### Template Structure

```markdown
# Feature Name Implementation

## Overview
Brief description

## Implementation Details
### 1. Domain Layer
### 2. BLoC Layer
### 3. UI Layer

## How It Works
Step-by-step flow

## Updated Files
List by layer

## Testing
Manual and unit tests

## Edge Cases & Considerations
Important notes
```

### When to Document

✅ **Do document:**
- New features
- Architectural changes
- Complex implementations
- Features with edge cases

❌ **Don't document:**
- Trivial bug fixes
- Simple refactoring
- Minor UI tweaks
- Localization updates

## Maintenance

Keep documentation up-to-date when features evolve. If a documented feature is removed, archive or delete the corresponding documentation file.
