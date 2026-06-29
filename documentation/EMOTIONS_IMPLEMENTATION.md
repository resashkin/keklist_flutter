# Emotions Implementation

## Overview

Emotions let a user understand how they feel about a `Mind`. A user maintains their
own library of **emotions** (title + emoji) which can optionally be grouped into
flat (single-level) **folders**. Any mind can be tagged with multiple emotions.

The feature ships with five default emotions seeded on first launch: 😠 Angry,
😨 Fear, 😢 Sad, 😄 Joy, ❤️ Love (loose — no folder). They are ordinary editable
data afterwards.

## Implementation Details

### 1. Domain Layer

**Entities** (`lib/domain/services/entities/`)
- `Emotion` — `id, title, emoji, folderIds (List<String>), isArchived, orderIndex, creationDate`.
  Storage supports membership in many folders; the UI assigns a single one.
- `EmotionFolder` — `id, title, orderIndex, creationDate` (title-only, no emoji).

**Hive objects** (`lib/domain/repositories/emotion/object/`)
- `EmotionObject` — `@HiveType(typeId: 3)`
- `EmotionFolderObject` — `@HiveType(typeId: 5)`
- `MindObject` gained `@HiveField(8) emotionIds` (default `[]`), surfaced on `Mind`.

**Repositories** (`lib/domain/repositories/emotion/`)
- `EmotionRepository` / `EmotionHiveRepository`
- `EmotionFolderRepository` / `EmotionFolderHiveRepository`
- Both are stream-backed (`BehaviorSubject` + box `watch()`), registered as DI
  singletons, and use two new encrypted Hive boxes (`emotion_box`,
  `emotion_folder_box`).

**Migration**
- `MigrationV3SeedEmotions` (schema v3) seeds the five defaults, guarded by the
  schema version **and** an empty-box check (so deleting all emotions does not
  re-seed). `MigrationContext`/`MigrationRunner` now carry an `EmotionRepository`.

### 2. BLoC Layer

**`EmotionBloc`** (`lib/presentation/blocs/emotion_bloc/`)
- State `EmotionsList { emotions, folders }` with helpers: `activeEmotions`,
  `archivedEmotions`, `looseEmotions`, `emotionsInFolder(id)`.
- Events: create / update / archive / unarchive / delete / reorder emotions;
  create / update / delete / reorder folders.
- **Archive vs delete**: deleting an emotion strips its id from every mind.
  Deleting a folder cascades — emotions still referenced by minds are archived,
  the rest are deleted.
- Listens to both repository streams and re-emits.

**`MindBloc`**
- New `MindSetEmotions { mindId, emotionIds }` event (used by the marking sheet —
  persists immediately).
- `MindCreate` gained an `emotionIds` parameter so new minds carry their tags.

### 3. UI Layer

- **`EmotionMarkingSheet`** — grouped single-scroll bottom sheet (loose emotions +
  folder sections), multi-select chips, "Setup emotions" button. Calls
  `onSelectionChanged` on every toggle. Also surfaces selected-but-archived
  emotions so they can be untagged.
- **`EmotionsScreen`** — management screen: add menu (emotion/folder), overflow →
  Archived. Per-section `ReorderableListView` for drag-and-drop ordering. Row
  action shows **Archive** (if used by minds) or **Delete**.
- **`EmotionArchivedScreen`** — restore or permanently delete archived emotions.
- **`EmotionEditorScreen`** — create/edit an emotion (emoji picker + title +
  optional single folder).
- **`MindCreatorScreen`** — "+ Add emotions" link / chips rendered under the main
  emoji; `onDone` now returns `(text, emoji, emotionIds)`.
- **Action menu** — `AddEmotionsMenuActionModel` added to the mind action sheet in
  `MindInfoScreen`; opens the marking sheet and saves immediately.
- **Mind display** — `MindMessageWidget` (the per-mind bubble in `MindInfoScreen`)
  renders the tagged emotions as chips directly under the main emoji, resolving
  ids via `EmotionBloc` (archived included, unresolved ids skipped). This is the
  live "real mind" surface.
- **Mind card** — `MindWidget` also accepts an optional `emotionEmojis` list
  (small scaled-down row at the bottom) for the icon-grid representation; emoji-
  only widgets (pickers, suggestions) pass none. Note: the icon-grid list widget
  is not currently mounted in the day view (which uses an emoji-row card), so the
  primary visible display is `MindMessageWidget`.
- **Settings** — "Emotions" row under *User Data* opens the management screen.

## How It Works

1. On first launch, migration v3 seeds the five default emotions.
2. The user tags a mind either while editing (`MindCreatorScreen` → marking sheet,
   persisted on Save via `MindCreate`/edit) or from a mind's action menu
   (marking sheet → `MindSetEmotions`, persisted immediately).
3. Emotion/folder management happens in `EmotionsScreen`, reachable from Settings
   or the marking sheet. Ordering is `orderIndex`-driven with drag-and-drop.
4. Emotions referenced by minds are archived rather than deleted, staying
   resolvable on those minds while hidden from pickers.

## Updated Files

**Domain**: `entities/emotion.dart`, `entities/emotion_folder.dart`,
`repositories/emotion/*`, `repositories/mind/object/mind_object.dart`,
`services/entities/mind.dart`, `hive_constants.dart`,
`migrations/migration.dart`, `migrations/migration_runner.dart`,
`migrations/migration_registry.dart`, `migrations/migrations/migration_v3_seed_emotions.dart`

**DI / bootstrap**: `di/containers.dart`, `main.dart`

**BLoC**: `blocs/emotion_bloc/*`, `blocs/mind_bloc/mind_event.dart`,
`blocs/mind_bloc/mind_bloc.dart`

**UI**: `screens/emotions/*`, `screens/mind_creator/mind_creator_screen.dart`,
`screens/mind_day_collection/mind_day_collection_screen.dart`,
`screens/mind_info/mind_info_screen.dart`, `screens/actions/action_model.dart`,
`screens/settings/settings_screen.dart`

**Localization**: 18 keys added to all 12 ARB files (default emotion names are
plain data, not localized).

## Testing

- `fvm flutter test` — full suite green (migration tests updated for schema v3).
- Manual: first launch seeds five emotions; tag a mind from the editor and from
  the action menu; create/rename/reorder/archive/delete emotions and folders;
  confirm archived emotions still show on tagged minds but not in the picker.

## Edge Cases & Considerations

- `emotionIds` defaults to `[]` via Hive `defaultValue`, so existing minds need no
  data migration.
- A single `orderIndex` orders an emotion within its one UI folder; per-folder
  ordering would be needed only if multi-folder UI is later exposed.
- Boxes are AES-encrypted like minds/settings (emotion titles are user content).
