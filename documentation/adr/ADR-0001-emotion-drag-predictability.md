# ADR-0001 — Emotion drag: predictability & stability

- **Status:** Accepted (design), not yet implemented
- **Scope:** `lib/presentation/screens/emotions/emotion_marking_sheet.dart`
- **Vocabulary:** see [`EMOTION_DRAG_GLOSSARY.md`](../EMOTION_DRAG_GLOSSARY.md)

## Context

The emotion-marking sheet has a custom long-press drag (not Flutter's
`Draggable`). In edit mode a chip can be dragged to **reorder**, **nest** into
another chip (dwell on its central band), or **navigate up** a level (dwell on
the back arrow). Two complaints motivated this ADR:

1. *"Very shaky while holding."*
2. *"Not predictable where it will land."*

### What the code actually does (findings)

- A **floating proxy** already exists (`_buildDragFeedback`, opacity 0.92,
  `IgnorePointer`, positioned at `_pointerGlobal`). The originally-proposed fix
  ("add a transparent copy under the finger") was therefore already present —
  the real defects were elsewhere.
- The **reorder land-preview is invisible**: `_gap` is a bare `AnimatedContainer`
  with only width/height — no fill, no border. The user sees empty space grow.
- The **nest land-preview is visible**: the target chip gets a 2px `primary`
  ring via `_EditableChip(isNestTarget:)`. Asymmetry between the two modes.
- The **shake is the wrap re-laying-out**, not the proxy: `_gap` animates open
  over 150ms on every `_insertIndex` change, and chips hop across `Wrap` rows.
- Every chip runs a **continuous jiggle rotation** (`_EditableChipState`), which
  keeps running during a drag and adds to perceived instability.

### Diagnosis of the user's proposed fix

The proposed "transparent copy" targets the proxy, which was never the problem.
The problems are (a) an invisible reorder preview and (b) animated wrap reflow.

## Decisions

Confirmed in the grilling session:

| # | Decision | Rationale |
|---|---|---|
| D1 | **Keep all three drop intents** (reorder / nest / navigate-up) on the one long-press-drag gesture. | The tri-modal gesture is wanted; the fix is polish, not a redesign. |
| D2 | **Show a transparent ghost of the held chip** in the landing slot (opacity ~0.35), at the exact footprint it will occupy. | Reorder needs a crisp land-preview; a literal ghost of the chip is more legible than a thin bar. *(Superseded the earlier insertion-bar choice at the user's request.)* |
| D3 | **Keep the chip-width landing gap** — the ghost fills it. | The user wants the literal footprint preview. |
| D4 | **Make the gap instant** (no 150ms width animation). | The wobble came from *animating* the gap, not from the gap existing. Snapping removes the shake while preserving the footprint. |
| D5 | **Reserve the dragged chip's slot / keep net-zero width.** | Removing one chip and opening one gap nets to constant wrap length → rows stay put, minimal reflow. |
| D6 | **Freeze the per-chip jiggle during an active drag session**, resume on release. | Removes a layer of motion that reads as shakiness. |

### Reconciliation note (D2 + D3 + D4)

The land-preview and a chip-width gap compose once the gap is **instant** and
**net-zero width**: the single gap represents the dragged chip's own footprint
moving to `_insertIndex`, the ghost chip fills that footprint, and total wrap
length is unchanged so chips do not hop rows merely because the gap moved. The
shake was the 150ms animation, not the gap's presence.

## Consequences

- **Always a land-preview.** Reorder → bar + gap; nest → target ring; the modes
  stay visually distinct and there is no longer a preview dead-zone.
- **Stable grid.** Instant, net-zero gap + frozen jiggle removes the twitch
  without abandoning `Wrap`.
- **`Wrap` is retained.** Row-boundary snaps still exist but read as discrete
  (instant) rather than wobbling; acceptable for this effort level. Replacing
  `Wrap` with an animated reorderable layout was considered and **rejected** as
  higher risk than the problem warrants.
- The floating proxy is left as-is.

## Implementation sketch (not yet done)

1. `_gap`: instant (plain `SizedBox`, no `AnimatedContainer`); when `open`,
   render an `Opacity(0.35)` ghost of the held chip (`EmotionChip` built from the
   dragged `Emotion`) filling the chip-width footprint.
2. Keep the dragged chip's footprint reserved so net width is constant (verify
   the current `SizedBox.shrink` + single grown gap already nets out; adjust if
   not).
3. Freeze jiggle: gate `_EditableChipState`'s `repeat()` on "no active drag"
   (pass an `isDragging` flag down, stop/reset the controller while true).
4. Leave nest ring and navigate-up spring behavior unchanged.

## Open items

- Exact insertion-bar placement at row boundaries / list ends.
- Whether nest-arming should also briefly show the bar fading into the ring for
  continuity (deferred).
