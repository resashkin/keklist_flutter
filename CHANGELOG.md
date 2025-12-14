# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Interactive onboarding flow for new users
  - 4-page walkthrough with custom SVG illustrations
  - Localized content (English and Russian)
  - Automatic sample minds creation
  - Skip functionality for quick access
- New settings flag: `hasSeenOnboarding`
- Onboarding service for creating demo minds

### Changed
- App initialization now checks onboarding status
- Settings repository extended with onboarding support

## [4.1.1] - 2024

### Features
- iOS, Android, and Web support
- Infinite calendar of minds
- Home screen with insights (charts and analytics)
- Offline-first architecture with Hive
- Dark mode support
- Multi-language support (English, Russian, German, Spanish, Italian, Japanese, Chinese, Kazakh, Kyrgyz, Serbian, Uzbek)
- Data export/import via CSV
- WatchOS app support
- iOS widgets
- Subscription support via RevenueCat
- Customizable tabs
- Debug menu for developers

### User Interface
- Calendar view with infinite scrolling
- Insights screen with charts and analytics
- Profile screen with user statistics
- Settings screen with extensive customization
- Mind creator with emoji picker
- Mind discussion/reflection support

### Technical
- BLoC/Cubit architecture for state management
- Hive for local data persistence
- Dependency injection with flutter_simple_dependency_injection
- Code generation with build_runner
- Localization via ARB files
- Platform-specific native integrations

### Data Management
- Create, read, update, delete minds
- Emoji categorization
- Day index-based organization
- Mind reflection/discussion support
- CSV export/import
- Local-first with offline support

---

## Version History

For detailed version history, see [Releases](https://github.com/resashkin/keklist_flutter/releases)

---

## Types of Changes

- `Added` for new features
- `Changed` for changes in existing functionality
- `Deprecated` for soon-to-be removed features
- `Removed` for now removed features
- `Fixed` for any bug fixes
- `Security` in case of vulnerabilities
