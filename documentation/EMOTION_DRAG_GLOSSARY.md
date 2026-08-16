# Emotion Drag — Glossary

Working vocabulary for the emotion-marking drag-and-drop interaction
(`lib/presentation/screens/emotions/emotion_marking_sheet.dart`). Built during a
design grilling; terms here are the shared language for the ADR that follows.

| Term | Meaning | Code anchor |
|---|---|---|
| **Chip** | A single emotion tag (emoji + label) rendered in the wrap. | `_staticChip`, `EmotionChip` |
| **Edit mode** | The state (`_editMode`) in which chips become draggable and show a delete cross. | `_toggleEditMode` |
| **Drag session** | Lifecycle from long-press recognition to release. | `_startDrag` → `_finishDrag`/`_cancelDrag` |
| **Floating proxy** | The overlay copy of the chip drawn under the finger during a drag session. **This is the "transparent copy" the user proposed — it already exists.** | `_buildDragFeedback`, opacity 0.92 |
| **Landing slot / gap** | The animated placeholder that opens in the wrap to preview where the chip will land on release. | `_gap`, `_insertIndex` |
| **Reorder** | Drop intent: move the chip to a new position among its siblings. Since ADR-0002 this is the *only* drop intent. | `_insertIndex` in `_updateHover` |
| **Level / path** | The current nesting depth being viewed; a stack of parent ids. | `_path`, `_currentParentId` |

### Retired by ADR-0002

These described nesting-by-drag and no longer exist in the UI. Kept here so the
terms are recognisable in ADR-0001 and in the domain layer, which still supports
nesting.

| Term | Meaning | Status |
|---|---|---|
| **Nest / spring-into** | Drop intent: make the dragged chip a child of a hovered chip, by dwelling on its central band for `_springDelay`. | Removed from the UI. `EmotionMove`/`_moveEmotion` survive in `EmotionBloc` with no callers. |
| **Navigate-up / spring-back** | Mid-drag level change: dwelling on the back arrow popped the path up one level, which doubled as the only way to promote a nested emotion out. | Removed. Un-nesting is no longer possible from the UI. |
| **Spring delay** | Dwell time before a hover converted into a nest or navigate action. | Removed. |
| **Central band vs edge band** | Horizontal thirds of a hovered chip: middle (0.25–0.75) = nest, edges = reorder. | Removed — the whole chip is now a reorder zone. |

## Problems — resolved

Root causes were confirmed and the fixes decided in
[`adr/ADR-0001-emotion-drag-predictability.md`](adr/ADR-0001-emotion-drag-predictability.md):

1. **"Shaky while holding"** — confirmed: the `Wrap` reflows because the landing
   gap *animates* over 150ms on every `_insertIndex` change, plus a continuous
   per-chip jiggle. The floating proxy was never the cause. → Fix: instant
   net-zero gap + freeze jiggle during drag.
2. **"Unpredictable landing"** — confirmed: the reorder gap (`_gap`) is drawn
   with no fill/border, so the land-preview is literally invisible; nest, by
   contrast, shows a ring. → Fix: a transparent **ghost** of the held chip fills
   the landing slot at its exact footprint.

## New terms from the ADR

| Term | Meaning |
|---|---|
| **Ghost chip** | A transparent (opacity ~0.35) copy of the held chip drawn inside the landing slot, at the exact footprint it will occupy on release — the visible replacement for the previously-invisible gap. |
| **Net-zero width** | Invariant: removing the dragged chip and opening exactly one landing gap keeps total wrap length constant, so rows don't hop as the gap moves. |
| **Instant gap** | The landing gap snaps to its new position with no width animation; the 150ms animation was the source of the wobble. |

## New terms from ADR-0002

See [`adr/ADR-0002-emotion-nesting-ui-removal.md`](adr/ADR-0002-emotion-nesting-ui-removal.md).

| Term | Meaning | Code anchor |
|---|---|---|
| **Read-only tree** | Nested emotions can be viewed, tagged, renamed, deleted and reordered within their level — but never created and never promoted out. Levels only exist for data authored before ADR-0002. | `_path`, `_drillInto`, `_goBack` |
| **Preserved logic** | Domain capability kept alive with zero UI callers so the feature can return without a data migration: `EmotionMove`, `_moveEmotion` (and its cycle check), `EmotionCreate(parentId:)`. Untested — see ADR-0002 D6. | `EmotionBloc` |
| **Focused chip / deep link** | Opening the sheet aimed at one emotion: seed `_path` with its ancestor chain, scroll it into view, then pulse a ring on it for ~1s. Entry point for tapping a chip inside a Mind. | `EmotionMarkingSheet.show(focusEmotionId:)` |
| **Static frame** | The sheet is a fixed 50% of screen height. The handle bar is decoration only; dismissal is swipe-down, tap-outside, or the header X. | `FractionallySizedBox(heightFactor: 0.5)` |
| **Comment palette** | The colours of the reflection bubble (`primaryContainer` / `onPrimaryContainer`), adopted by emotion chips rendered inside a Mind card. Sheet chips keep the secondary palette. | `MindBulletWidget`, `_MindEmotionsRow` |
