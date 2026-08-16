# Emotions Implementation

## Overview

Emotions let a user understand how they feel about a `Mind`. A user maintains their
own library of **emotions** (title + emoji) organized as an **unlimited-depth tree**:
any emotion can have a parent, so categories and specifics live in the same model
(e.g. Joy → Serenity → Calm). Any node — root or nested — can be tagged on a mind,
and a mind can carry multiple emotions.

The feature ships with five default emotions seeded on first launch: 😠 Angry,
😨 Fear, 😢 Sad, 😄 Joy, ❤️ Love (top-level). They are ordinary editable data
afterwards; the user builds depth by adding sub-emotions.

> History: an earlier iteration used single-level, title-only **folders**. Folders
> were removed in favor of parent emotions. Existing emotions simply become
> top-level (`parentId = null`); no folder migration is performed.

## Implementation Details

### 1. Domain Layer

**Entity** (`lib/domain/services/entities/emotion.dart`)
- `Emotion` — `id, title, emoji, parentId (String?), isArchived, orderIndex, creationDate`.
  `parentId == null` → top-level root; otherwise a child of that emotion.

**Hive object** (`lib/domain/repositories/emotion/object/emotion_object.dart`)
- `EmotionObject` — `@HiveType(typeId: 3)`. `parentId` at `@HiveField(7)`. Field
  index 3 (the old `folderIds`) is retired — new records omit it, old records
  ignore it on read.
- `MindObject` has `@HiveField(8) emotionIds` (default `[]`), surfaced on `Mind`.

**Repository** (`lib/domain/repositories/emotion/`)
- `EmotionRepository` / `EmotionHiveRepository` — stream-backed
  (`BehaviorSubject` + box `watch()`), DI singleton, one encrypted Hive box
  (`emotion_box`).

**Migration**
- `MigrationV3SeedEmotions` (schema v3) seeds the five defaults as top-level
  emotions (`parentId: null`), guarded by the schema version **and** an
  empty-box check. `MigrationContext`/`MigrationRunner` carry an `EmotionRepository`.

### 2. BLoC Layer

**`EmotionBloc`** (`lib/presentation/blocs/emotion_bloc/`)
- State `EmotionsList { emotions }` with tree helpers: `byId`, `activeEmotions`,
  `archivedEmotions`, `childrenOf(parentId)`, `rootEmotions`, `hasActiveChildren`,
  `ancestorsOf`, and `lineageEmojis` (all ancestor emojis + own).
- Events: `EmotionCreate {title, emoji, parentId}`, `EmotionUpdate`,
  `EmotionArchive`, `EmotionUnarchive`, `EmotionDelete`, `EmotionReorder`.
- **Cascade (recursive):** archiving a node archives its whole subtree. Deleting a
  node walks its subtree — any node still referenced by a mind is archived instead
  of hard-deleted; unreferenced nodes are deleted and stripped from minds.
- `orderIndex` is per-sibling-group; `EmotionReorder` persists a new sibling order.

**`MindBloc`**
- `MindSetEmotions { mindId, emotionIds }` (used by the marking sheet — persists
  immediately). `MindCreate` also accepts optional `emotionIds`.

### 3. UI Layer

- **`EmotionChip`** (`screens/emotions/widgets/emotion_chip.dart`) — shared pill
  that renders emojis **inline** (no clipping avatar — fixes the earlier cut-emoji
  bug), an optional chevron to hint long-press-drills, and a selected style.
- **`EmotionMarkingSheet`** — one tree level at a time. **Tap** a chip to toggle
  the tag, **long-press** to drill into its children (chevron badge marks parents).
  A "Selected" section shows tagged emotions with full-lineage chips; a breadcrumb
  header + back button navigate up; "Setup emotions" opens management.
- **`EmotionsScreen`** — expandable tree. Parents expand inline; per-node overflow
  menu: add sub-emotion / edit / archive / delete. Each sibling group is a
  non-scrolling `ReorderableListView` for drag-reorder; overflow → Archived.
- **`EmotionArchivedScreen`** — restore or permanently delete archived emotions
  (shown with lineage emojis).
- **`EmotionEditorScreen`** — create/edit an emotion (emoji picker + title). Tree
  position is fixed by `parentId` at creation.
- **Mind display** — `MindMessageWidget` renders tagged emotions as full-lineage
  `EmotionChip`s under the note; tapping a chip immediately untags it. Resolves ids
  via `EmotionBloc` (archived included, unresolved ids skipped).
- **Action menu** — "Edit emotions" (`AddEmotionsMenuActionModel`) in the per-mind
  action sheets (`MindInfoScreen`, `MindOneEmojiCollectionScreen`,
  `MindUniversalListScreen`), shown only for root minds (not comments).
- **Settings** — "Emotions" row under *User Data* opens the management screen.

## How It Works

1. On first launch, migration v3 seeds the five default top-level emotions.
2. The user tags a mind from its action menu → "Edit emotions" (marking sheet →
   `MindSetEmotions`, persisted immediately), or untags by tapping a chip on the mind.
3. Tree management happens in `EmotionsScreen` (Settings or the marking sheet).
   Ordering is `orderIndex`-driven per sibling group with drag-and-drop.
4. Nodes referenced by minds are archived rather than deleted, staying resolvable
   (with full lineage) on those minds while hidden from pickers.

## Testing

- `fvm flutter test` — full suite green (migration-runner test builds `Emotion`
  with `parentId`).
- Manual: tag a mind, drill into a parent via long-press, reorder siblings,
  archive/delete a parent (subtree cascades), confirm archived emotions still
  render on tagged minds but not in the picker, and that chips show the full
  ancestor-emoji lineage without clipping.

## Edge Cases & Considerations

- `emotionIds` defaults to `[]` via Hive `defaultValue`; existing minds need no
  data migration.
- `copyWith` cannot reset `parentId` to null (standard nullable-copyWith limit);
  parent is set once at creation. Cascade delete does not reparent (by design).
- Lineage resolves through archived ancestors too, so a deep tagged emotion still
  shows its full emoji chain even if an ancestor was archived.
- The box is AES-encrypted like minds/settings (emotion titles are user content).
