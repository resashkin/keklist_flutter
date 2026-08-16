# ADR-0002 — Retiring emotion nesting from the UI

- **Status:** Implemented and verified on an iPhone 17e simulator (iOS 26.4)
- **Scope:** `lib/presentation/screens/emotions/emotion_marking_sheet.dart`,
  `lib/presentation/screens/emotions/widgets/emotion_chip.dart`,
  `lib/presentation/screens/mind_day_collection/widgets/messaged_list/mind_message_widget.dart`,
  `lib/l10n/app_*.arb`
- **Supersedes:** parts of [`ADR-0001`](ADR-0001-emotion-drag-predictability.md) — D1 (tri-modal drag) is
  reduced to reorder-only; D2–D6 survive unchanged.
- **Vocabulary:** see [`EMOTION_DRAG_GLOSSARY.md`](../EMOTION_DRAG_GLOSSARY.md)

## Context

Nesting an emotion inside another emotion is powerful but confusing. It is
reached through a tri-modal drag gesture where the *same* long-press-drag means
reorder, nest, or navigate-up depending on where and how long the finger dwells
(`_springDelay`, central band vs edge band). Users cannot tell the modes apart
mid-gesture.

The tree itself is not the problem — the *authoring* of it is. The domain layer
(`Emotion.parentId`, `EmotionMove`/`_moveEmotion` with its cycle check,
`EmotionCreate(parentId:)`, `descendantIdsOf`, `lineageEmojis`) is sound and
should survive intact so the feature can return without a data migration.

## Decisions

Confirmed in the grilling session.

### Hierarchy

| # | Decision | Rationale |
|---|---|---|
| D1 | **Read-only tree.** Drill-in (long-press / chevron), the back button and `_path` all stay. Only nest *creation* is removed. | Users with pre-existing nests keep them reachable and taggable. A flat UI would have hidden their own data from them. |
| D2 | **`Add emotion` is hidden at nested levels**; at root it creates a top-level emotion as today. | `_openEditor` passes `parentId: _currentParentId` — at depth it is a nesting control. Hiding it closes the last UI path that creates a child. |
| D3 | **No un-nesting in the UI.** Losing spring-back means a legacy nested emotion can be viewed but never promoted out. Accepted. | Matches "remove from the UI only". The escape hatch (delete + recreate at root) exists, and promotion returns with the feature. |

### Drag

| # | Decision | Rationale |
|---|---|---|
| D4 | **Reorder is the only drop intent.** Delete `_springInto`, `_springBack`, `_springTimer`, `_backSpringTimer`, `_springTargetId`, `_overBack`, `_springDelay`, the back-arrow drop highlight and `_EditableChip.isNestTarget`. | One gesture, one meaning. The dwell-to-nest ambiguity was the core complaint. |
| D5 | **Dispatch `EmotionReorder(orderedEmotionIds:)`** instead of `EmotionMove`. | `_finishDrag` already only ever passed `newParentId: _currentParentId`, so the move semantics were vestigial. `EmotionReorder` names what the UI now does. |
| D6 | **No unit test for the preserved `_moveEmotion`.** Accepted risk, recorded below. | Explicitly chosen; see Consequences. |
| D7 | **Keep drag auto-scroll**, with a `ScrollController` owned by the state. | It previously borrowed the controller from `DraggableScrollableSheet`. With a fixed-height sheet that can no longer expand to 95%, auto-scroll matters *more*, not less. |
| D8 | ADR-0001's D2–D6 (ghost chip, instant net-zero gap, frozen jiggle) are **unaffected** and still apply to reorder. | The stability work was never about nesting. |

### Sheet chrome

| # | Decision | Rationale |
|---|---|---|
| D9 | **Static height: 50% of screen.** Replace `DraggableScrollableSheet` with `FractionallySizedBox(heightFactor: 0.5)`; drop `_dragController`, `_initialSize`/`_minSize`/`_maxSize`, `snapSizes`, `_onHandleDrag`, `_onHandleDragEnd` and the `DraggableScrollableNotification` dismiss listener. | The sheet resized under the finger during chip drags. A fixed frame makes the drag surface stable. |
| D10 | **Handle bar stays as decoration.** Swipe-to-dismiss comes free from `showModalBottomSheet`. | Keeps the dismissable affordance without the resize machinery. |
| D11 | **Header becomes `[Edit] title [X]` at root and `[←] title [X]` when nested** — back replaces Edit in the left slot. | Two controls, two slots. Editing is a root-level activity; nested levels only exist for legacy trees. |
| D12 | **The X is a pure dismiss.** No cancel, no revert, no Done. | `onSelectionChanged` already fires on every toggle, so nothing is ever pending. Buffering selection to support Cancel would be a behavior change beyond scope. |

### Tapping an emotion inside a Mind

| # | Decision | Rationale |
|---|---|---|
| D13 | **Tap opens the marking sheet in normal (tagging) mode** instead of untagging immediately. | Untagging on a single tap was too easy to trigger by accident. Untag is now: open, tap the highlighted chip. |
| D14 | **`_MindEmotionsRow` opens the sheet itself.** | The leaf already reads `MindBloc`; ~4 lines versus threading `onEmotionTap` through five call sites — one of which (`mind_search_result_widget.dart`) has no emotion handler at all and would otherwise behave differently. |
| D15 | **`EmotionMarkingSheet.show` gains `focusEmotionId`.** The sheet walks `parentId` upward to seed `_path` with the full ancestor chain, then scrolls to the chip **and shows a highlight ring on it for 1.8s.** | Without the ancestor walk the feature silently fails for exactly the nested chips that render lineage emojis. Without the ring it is invisible whenever the list already fits — which, at a fixed 50% height, is the common case. |
| D15a | **The focus ring is 3px, not 2px.** | Found on device: at 2px the ring was not legible. The app's theme is deliberately monochrome (`ColorScheme.light(primary: Colors.black, secondary: Colors.grey)` in `domain/constants.dart`), so the ring competes with the chip's own 1.5px border and the grey `secondaryContainer` fill of a selected chip rather than reading as an accent. 3px separates cleanly; `primary` is still the right colour (`error` is reserved for the armed-delete state). |

### Colour

| # | Decision | Rationale |
|---|---|---|
| D16 | **Chips inside a Mind adopt the comment bubble's colours**: `primaryContainer` fill, `onPrimaryContainer` label, border `primary`. Sheet chips keep `secondaryContainer`. | Aligns the card's two content types. The sheet still needs secondary-vs-surface to signal selected/unselected. |
| D17 | **Keep the 1.5px border** in the new colour rather than going borderless like the bubble. | `EmotionChip` holds border width constant across states specifically so a chip never resizes when toggled. |

## Consequences

- **The tri-modal gesture is gone.** Long-press-drag now means exactly one thing.
  ADR-0001's stability fixes still govern how it looks.
- **Dead-by-design domain code.** `EmotionMove`, `_moveEmotion` (including its
  cycle check) and `EmotionCreate(parentId:)` end up with **zero callers**. Per
  D6 there is also zero test coverage — `test/` has no emotion tests today. This
  logic is preserved in name only: nothing will detect a silent break in it. If
  the feature is ever restored, treat `_moveEmotion` as unverified and test it
  before wiring it back up.
- **Nested emotions are a one-way door.** They can be viewed, tagged, renamed,
  deleted and reordered within their level, but never created and never promoted.
- **`_openEditor` at depth is unreachable**, so `EmotionEditorSheet`'s `parentId`
  parameter is only ever `null` from production code.
- **Localization.** `emotionPickHint` keeps "long-press to go deeper" (drill-in
  survives) but `emotionEditHint` must describe drag-to-reorder instead of
  nesting. Both keys change in all 12 `app_*.arb` files, followed by
  `fvm flutter gen-l10n`.

## Implementation sketch (not yet done)

1. **Sheet frame** — swap `DraggableScrollableSheet` for
   `FractionallySizedBox(heightFactor: 0.5)`; own a `ScrollController`; delete the
   size constants and both handle drag handlers; keep `handleBar`.
2. **Header** — `_buildHeader` renders Edit on the left only when
   `!_canGoBack`, back on the left otherwise, and an X on the right calling
   `Navigator.pop`.
3. **Drag** — strip every spring member listed in D4; `_updateHover` keeps only
   the `_insertIndex` computation (drop the `frac` central-band branch); `_finishDrag`
   builds the reordered id list for the current level and dispatches
   `EmotionReorder`.
4. **Add link** — wrap the `TextButton.icon` in `if (_currentParentId == null)`.
5. **Deep link** — add `focusEmotionId` to `EmotionMarkingSheet.show`; on the
   first frame where state is `EmotionsList`, walk ancestors into `_path`, then
   `Scrollable.ensureVisible(_chipKey(id).currentContext!)` in a post-frame
   callback and drive a one-shot ring animation. Gate on the state being loaded —
   the first frame is a `CircularProgressIndicator`.
6. **Mind row** — `_MindEmotionsRow._remove` becomes `_openSheet`, calling
   `EmotionMarkingSheet.show(focusEmotionId: emotion.id, ...)` and dispatching
   `MindSetEmotions` from `onSelectionChanged`.
7. **Chip colour** — add a flag (or an explicit colour pair) to `EmotionChip` so
   the in-Mind row renders `primaryContainer`/`onPrimaryContainer`/`primary`
   while the sheet keeps the secondary palette.
8. **l10n** — update `emotionEditHint` (and `emotionPickHint` if reworded) across
   all 12 ARB files; run `fvm flutter gen-l10n`.

## Verified on device

Checked on an iPhone 17e simulator against a mind tagged with a nested emotion
(Joy → Love):

- Sheet is fixed-height and no longer resizable; header reads `[Edit] Emotions [X]`.
- Drilling into Joy swaps the left slot to `[←]` and **hides `Add emotion`**, so
  no UI path creates a child.
- Dragging a chip across the *centre* of other chips reorders only — Angry moved
  from first to last with no nesting — and the new order survives closing and
  reopening the sheet, confirming `EmotionReorder` persists.
- Tapping the nested chip in the mind card opens the sheet **already inside Joy**
  with Love ringed, rather than untagging it.
- The chip in the mind card and the comment bubble render as the same fill.
- Edit-mode hint reads "Tap to rename · ✕ to remove · drag to reorder".

## Open items

- Whether 50% remains right on tablets (a fixed-dp variant was considered and
  deferred).
- `EmotionEditorSheet.parentId` is now always `null` from production code; it is
  part of the preserved-logic surface but is the kind of parameter that rots.
