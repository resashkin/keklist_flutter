# Lazy Onboarding Implementation

## Overview
This document describes the correct implementation of the lazy onboarding feature using ID prefixing instead of rootId markers.

## Key Architecture Decision: ID Prefix vs RootId

### ❌ Wrong Approach (Initial Implementation)
```dart
// WRONG: Using rootId for parent minds
Mind(
  id: uuid.v4(),
  rootId: 'ONBOARDING', // ❌ Parent minds should NEVER have rootId
  // ...
)
```

**Problem**: Parent minds should have `rootId = null` because they ARE the root. Setting `rootId` to a marker value makes them appear as child minds.

### ✅ Correct Approach (Current Implementation)
```dart
// CORRECT: Using ID prefix for parent minds
Mind(
  id: 'ONBOARDING_${uuid.v4()}', // ✅ Prefix identifies onboarding minds
  rootId: null,                   // ✅ Parent minds have no rootId
  // ...
)

// Comment minds reference parent
Mind(
  id: uuid.v4(),
  rootId: 'ONBOARDING_parent-id', // ✅ rootId points to actual parent
  // ...
)
```

## Mind Structure

### Parent Minds (6 total)
- **ID**: `ONBOARDING_<uuid>` (prefixed with `ONBOARDING_`)
- **rootId**: `null` (they are root minds)
- **Emojis**: 👋, 😊, 📅, 🧙, 🔒, 👇
- **Translations**: Function references to `AppLocalizations` (type-safe, no string keys!)

### Comment Minds (2 total)
- **ID**: `<uuid>` (regular UUID)
- **rootId**: Parent mind's ID (e.g., `ONBOARDING_<parent-uuid>`)
- **Parents**:
  - Mind 2 (😊) has 2 comments

## Localization Approach

### ✅ Type-Safe Translation Functions (Current)
```dart
class OnboardingMindData {
  final String emoji;
  final String Function(AppLocalizations) translation; // Direct function reference!
  final int sortIndex;
}

// Usage in constants:
static List<OnboardingMindData> parentMinds = [
  OnboardingMindData(
    emoji: '👋',
    translation: (l10n) => l10n.onboardingMind1, // Type-safe!
    sortIndex: 0,
  ),
  // ...
];

// Usage in code:
final text = parentData.translation(l10n); // Simple and clean!
```

### ❌ String Keys Approach (Avoided)
```dart
// BAD: String keys require switch/map and prone to typos
class OnboardingMindData {
  final String translationKey; // String-based, error-prone
}

String _getTranslation(AppLocalizations l10n, String key) {
  switch (key) { // Verbose and fragile
    case 'onboardingMind1': return l10n.onboardingMind1;
    // ... many more cases
  }
}
```

### Benefits of Function Reference Approach
1. **Type-Safe**: Compiler catches typos at compile time
2. **Refactor-Friendly**: Renaming translations updates automatically
3. **No Boilerplate**: No switch statements or string mappings needed
4. **Clean Code**: Direct function call `translation(l10n)`
5. **IDE Support**: Autocomplete and go-to-definition work perfectly

## Helper Methods

### `OnboardingConstants.isOnboardingMindId(String id)`
Checks if an ID has the `ONBOARDING_` prefix.

```dart
OnboardingConstants.isOnboardingMindId('ONBOARDING_123'); // true
OnboardingConstants.isOnboardingMindId('regular-id');     // false
```

### `OnboardingConstants.isOnboardingMind(String id, String? rootId)`
Checks if a mind is part of onboarding (parent or child).

```dart
// Parent onboarding mind
OnboardingConstants.isOnboardingMind('ONBOARDING_123', null); // true

// Child of onboarding mind
OnboardingConstants.isOnboardingMind('comment-id', 'ONBOARDING_parent'); // true

// Regular mind
OnboardingConstants.isOnboardingMind('regular-id', null); // false
```

## Filtering Onboarding Minds

### In Queries
```dart
// Exclude onboarding minds
final realMinds = allMinds.where(
  (m) => !OnboardingConstants.isOnboardingMind(m.id, m.rootId),
).toList();

// Get only onboarding minds
final onboardingMinds = allMinds.where(
  (m) => OnboardingConstants.isOnboardingMind(m.id, m.rootId),
).toList();
```

### In Deletion
```dart
// Delete parent onboarding minds
await repository.deleteMindsWhere(
  (mind) => OnboardingConstants.isOnboardingMindId(mind.id),
);

// Delete comment minds (children of onboarding parents)
final parentIds = allMinds
  .where((m) => OnboardingConstants.isOnboardingMindId(m.id))
  .map((m) => m.id)
  .toSet();

await repository.deleteMindsWhere(
  (mind) => mind.rootId != null && parentIds.contains(mind.rootId),
);
```

## Unit Tests

Comprehensive tests are in `test/presentation/blocs/lazy_onboarding_bloc/lazy_onboarding_bloc_test.dart`:

### Test Philosophy
- **Focus on structure, not content**: Tests verify correct number of minds, ID prefixes, and parent-child relationships
- **No string content validation**: Translations are implementation details - existence of onboarding minds is sufficient
- **Localization uses fallback**: Tests use English localization fallback automatically, no manual mocking needed

### Test Coverage

1. **LazyOnboardingCheck**
   - ✅ Doesn't show when user has seen onboarding
   - ✅ Shows when totalMinds < 10
   - ✅ Shows when no minds in last 30 days
   - ✅ Doesn't show when conditions not met

2. **LazyOnboardingCreate**
   - ✅ Creates correct count: 8 total (6 parents + 2 comments)
   - ✅ Parent minds have `ONBOARDING_` prefix in ID
   - ✅ Parent minds have `rootId = null`
   - ✅ Comment minds reference parent IDs in `rootId`
   - ✅ All comment rootIds point to valid parent minds
   - ℹ️ Note: Tests verify structure only, not string content

3. **LazyOnboardingDelete**
   - ✅ Deletes all parent onboarding minds
   - ✅ Deletes all comment minds

4. **LazyOnboardingMarkAsSeen**
   - ✅ Updates `hasSeenLazyOnboarding = true`

5. **OnboardingConstants helpers**
   - ✅ `isOnboardingMindId()` correctly identifies prefixed IDs
   - ✅ `isOnboardingMind()` correctly identifies all onboarding minds

## Running Tests

```bash
# Run all tests
flutter test

# Run only onboarding tests
flutter test test/presentation/blocs/lazy_onboarding_bloc/

# Run with coverage
flutter test --coverage
```

## Benefits of ID Prefix Approach

1. **Semantically Correct**: Parent minds are true roots with `rootId = null`
2. **Easy Identification**: Simple string prefix check
3. **No Database Schema Changes**: Uses existing Mind structure
4. **Cascade Deletion Works**: Comment minds are properly linked via rootId
5. **Filtering Efficient**: Single helper method for all cases

## Migration Path

No migration needed! The new approach:
- Doesn't change existing mind structure
- Only affects new onboarding minds created going forward
- Existing users won't see onboarding (already have `hasSeenLazyOnboarding = true` or enough minds)
