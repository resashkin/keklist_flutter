# ADR-0004 — Emotions in export/import, and an add-emotion anchor on the card

- **Status:** Implemented and verified (iPhone 17e simulator, device language ru)
- **Scope:** `lib/domain/services/export_import/export_import_service.dart`,
  `lib/domain/services/entities/mind.dart`,
  `lib/presentation/screens/mind_day_collection/widgets/messaged_list/mind_message_widget.dart`,
  `lib/presentation/screens/emotions/widgets/emotion_chip.dart`
- **Related:** [`ADR-0002`](ADR-0002-emotion-nesting-ui-removal.md),
  [`ADR-0003`](ADR-0003-localized-emotion-seeding.md)

## Context

### Export/import silently loses emotions today

`Mind.toCSVEntry()` emits **seven** positional fields and `emotionIds` is not one
of them. The importer rebuilds `Mind(...)` without it, so the field falls back to
its `const []` default. An export → import round-trip therefore drops every tag
on every mind, with no warning. This is existing data loss, not merely a missing
feature.

Emotion *definitions* are worse off: they live in their own Hive box that the
exporter never touches. Even with ids in the CSV, importing onto another device
leaves every id dangling. Nothing surfaces the failure — `_MindEmotionsRow`
resolves ids with `whereType<Emotion>()`, so unresolved tags just disappear. A
nested emotion whose parent is missing is worse still: it is invisible at every
level, because `childrenOf(null)` matches only `parentId == null`.

### The CSV shape happens to be forgiving

`minds.csv` has **no header row**; import reads fixed positions `row[0..6]` and
skips rows with `if (row.length < 7) continue`. Appending an eighth column is
therefore compatible in both directions: a new build reading an old 7-column file
still parses, and an old build reading a new 8-column file ignores the extra
field. Both encoder and decoder use `fieldDelimiter: ';'`, so a `,`-joined id
list needs no quoting.

### There is no anchor to add a first emotion

The emotions row is gated behind `if (mind.emotionIds.isNotEmpty)`, so a mind
with no tags renders nothing at all. The only way in is the `⋮` action menu,
which itself is gated on `mind.rootId == null`.

## Decisions

Confirmed in the grilling session.

### Export / import

| # | Decision | Rationale |
|---|---|---|
| D1 | **`minds.csv` gains an 8th column**: `emotionIds` joined with `,`. | Restores the tag→mind link. Safe against the `;` field delimiter, and compatible with old and new builds in both directions thanks to the header-less positional format. |
| D2 | **A second `emotions.csv` joins the ZIP** — not JSON — with columns `id, title, emoji, parentId, isArchived, orderIndex, creationDate`. | The user chose CSV for consistency with `minds.csv`, even though `Emotion` is already `@JsonSerializable`. One format to read, one convention to learn. |
| D3 | **The bare-CSV export writes the ids column anyway**, accepting that definitions cannot travel with a single flat file. | Re-importing on the *same* device restores tags correctly, since the ids still resolve locally. On another device the tags drop — exactly today's behaviour, so nothing regresses. |
| D4 | **`emotions.csv` contains every emotion, archived included.** | Archived emotions are still referenced by minds — that is the entire reason archiving exists instead of deletion. Exporting all of them also preserves parent-only "folder" emotions, without which nested children import as invisible orphans. |
| D5 | **Merge on import: reuse when identical, clone when different.** Same `id` + same `title`/`emoji`/`parentId` → reuse the local row. Same `id` with a changed definition → create a clone under a fresh id. | The user's first instinct was "always duplicate", which contradicts D3: on a same-device re-import every id collides *identically*, so always-duplicating would clone the entire emotion list on every import, and triple it on the second. Comparing the definition makes the common case a clean no-op while still never losing either version of a genuine conflict. |
| D6 | **Cloning implies remapping.** When an emotion is cloned, every imported `mind.emotionIds` entry and every imported child's `parentId` must be rewritten to the clone's id. | Without it, imported minds point at the local (differing) emotion, and cloned children keep pointing at the old parent — reintroducing the invisible-orphan bug. |
| D7 | **An archive with no `emotions.csv` imports as before.** | Old archives stay importable; their ids simply dangle, which is the current behaviour. |

### Add-emotion anchor

| # | Decision | Rationale |
|---|---|---|
| D8 | **The emotions row always renders for root minds**, with a trailing outlined **⊕ chip** after any existing chips. | The messenger reaction pattern. One consistent anchor whether or not the mind is tagged — unlike an empty-state-only button, which vanishes exactly when the user wants to add a *second* emotion. |
| D9 | **Root minds only** (`mind.rootId == null`). | Mirrors the existing `⋮` menu gate. The anchor appears only where tagging is actually possible; extending tagging to comments would be a feature change beyond the ask, and comments render as bullets, not cards. |
| D10 | **All five `MindMessageWidget` render sites get it**, search results included. | Since ADR-0002, `_MindEmotionsRow` opens the marking sheet from its own context, so no callback threading is required anywhere — including `mind_search_result_widget`, which has no emotion handler of its own. A card should not behave differently depending on how it was reached. |

## Consequences

- **Every root card gets taller**, including untagged ones, because the row now
  always renders. This is a visible change to dense lists (day collection,
  search results) and is the main cost of D8.
- **Import gains a resolution pass.** Emotions must be reconciled and the id
  remap built *before* minds are written, so tags land on the right rows.
- **`emotions.csv` is written even when empty-ish**, since D4 exports archived
  and unused rows; the file is small but always present in new ZIPs.
- **Old builds are unaffected**: they ignore the 8th column and an unknown
  `emotions.csv` entry in the archive.
- **The bare-CSV path remains lossy across devices** by construction (D3). Worth
  saying in the UI if the export screen ever explains the formats.

## Implementation sketch (not yet done)

1. `Mind.toCSVEntry()` — append `emotionIds.join(',')`.
2. Importer — read `row.length > 7 ? row[7] : ''`, split on `,`, drop empties,
   and pass into `Mind(emotionIds: ...)`. Both import paths (lines ~219 and ~328)
   need it; they are duplicated today.
3. Exporter — build `emotions.csv` from `EmotionRepository.values` (all rows) and
   `archive.addFile` it next to `minds.csv`.
4. Importer — parse `emotions.csv` if present, reconcile per D5, build
   `Map<String, String>` of incoming id → effective id, apply it to cloned
   children's `parentId` and to every imported mind's `emotionIds`, then
   `createEmotions` for the new rows.
5. `EmotionChip` (or a sibling widget) — an outlined `⊕` variant with no label.
6. `MindMessageWidget` — drop the `isNotEmpty` guard for root minds, render the
   row unconditionally, append the ⊕ chip, and open the marking sheet with no
   `focusEmotionId`.
7. Tests — round-trip a mind with tags through export→import; assert identical
   re-import is a no-op (no clones); assert a changed definition clones and
   remaps both the tag and a child's `parentId`.

## Verified

`test/domain/services/export_import/emotion_round_trip_test.dart` — 9 tests
covering the CSV column (round-trip, legacy 7-column row, untagged mind) and the
full ZIP path: import onto an empty device, identical re-import creating nothing,
a changed definition cloning and remapping the tag, a cloned parent carrying its
child's `parentId`, an archive with no `emotions.csv`, and archived emotions
surviving with their `isArchived`/`orderIndex` intact.

On device, a real export triggered from Settings produced an archive containing
both `minds.csv` and `emotions.csv`. Every mind row carried **8** columns;
untagged minds ended in an empty field, and a mind tagged with two emotions
carried both ids comma-joined in column 8, matching the ids in `emotions.csv`.
`emotions.csv` held all five starter emotions with their localized titles,
`parentId` of `null`, and `orderIndex` preserved.

The ⊕ chip renders on every root card — alone on untagged ones, trailing the
chips on tagged ones (`[😠 Злость] [❤️ Любовь] [＋]`) — and correctly does **not**
appear on comment bubbles. Tapping it opens the marking sheet at the top level
with nothing focused.

Import was exercised by the unit tests rather than on device, since importing
would require the file picker and would duplicate the live data set.

## Open items

- Whether the ⊕ chip should be hidden while the day list is in any compact or
  read-only mode (none exists today).
- `ExportImportService` duplicates its CSV row parsing in two places; folding
  them together would keep the new column from drifting between paths.
