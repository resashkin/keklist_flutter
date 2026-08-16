# ADR-0003 — Seeding the default emotions in the user's language

- **Status:** Implemented and verified (iPhone 17e simulator, device language ru)
- **Scope:** `lib/presentation/blocs/emotion_bloc/`,
  `lib/presentation/screens/emotions/emotion_marking_sheet.dart`,
  `lib/domain/repositories/settings/` (+ generated Hive adapter),
  `lib/domain/migrations/migrations/migration_v3_seed_emotions.dart`
- **Related:** [`ADR-0002`](ADR-0002-emotion-nesting-ui-removal.md)

## Context

The five starter emotions (Angry, Fear, Sad, Joy, Love) are hardcoded **English**
regardless of the user's language, even though the app ships 12 locales.

Two facts from the code shaped this decision:

1. **Seeding is a startup migration, not a UI action.**
   `MigrationV3SeedEmotions` runs inside `_runMigrations` during Hive init, long
   before any screen exists. It is guarded by `dataSchemaVersion` *and* an
   emptiness check.
2. **A `BuildContext` was never required to translate.**
   `lookupAppLocalizations(Locale)` exists in the generated
   `app_localizations.dart`, and `SettingsHiveRepository`'s constructor writes
   `KeklistSettings.initial()` — including `_detectDeviceLocale()` — *before*
   `MigrationRunner` is built. The language is therefore already known and usable
   at migration time.

So localizing the seed in place was possible without moving anything. Moving
creation to first sheet-open was nevertheless chosen (D1) — but on its merits,
not because translation forced it.

A third fact made the move safe: the marking sheet is the **only** surface that
renders the emotion list. Every other consumer (`mind_message_widget`,
`mind_iconed_list_widget`) merely resolves ids of emotions already tagged on a
mind, so an empty store before first open is harmless.

## Decisions

Confirmed in the grilling session.

### Where and when

| # | Decision | Rationale |
|---|---|---|
| D1 | **Seed on first open of `EmotionMarkingSheet`**, not at startup. | Creation happens at the moment the feature is first actually used. |
| D2 | **Guard is `!hasSeededEmotions && emotions.isEmpty`** — both conditions. A new `hasSeededEmotions` bool joins `KeklistSettings`. | The flag alone would seed duplicates on top of the author's existing emotions (their flag defaults to `false` while their store is non-empty). The emptiness check alone would resurrect all five after a user deliberately deletes them. Together they are correct in both directions. |
| D3 | **No loading gate on first paint.** | Seeding is a handful of local Hive writes; the brief empty state is acceptable and cheaper than a `_seeding` flag. |
| D4 | **A new `EmotionSeedDefaults` event on `EmotionBloc`** owns the guard, the language lookup and the writes; the sheet only dispatches it. | Matches the app's BLoC + Repository structure and keeps seeding policy out of a widget, where nothing else could reach or test it. |

### Language and content

| # | Decision | Rationale |
|---|---|---|
| D5 | **Language source is `settings.language`.** | It already resolves device locale → supported language → English fallback (including the `sr` / `sr_Latn` script split) *and* honours a manual override, so it covers both halves of the request with no new detection code. |
| D6 | **Titles come from a Dart `const` map keyed by `SupportedLanguage`**, not from ARB. | These are one-time seed **data**, not UI labels. In ARB they would be five keys that are read once at install and never rendered, permanently visible to every future translator. |
| D7 | **All 12 languages, with `sr` in Cyrillic and `sr_Latn` in Latin script.** Any language absent from the map falls back to English rather than throwing. | The ARB files already treat the two Serbian locales as distinct; reusing Cyrillic for a Latin-script user would clash with their otherwise-Latin UI. |
| D8 | **Titles are frozen after seeding.** Switching language later does not re-title them. | Once seeded they are ordinary user rows that can be renamed, archived or deleted. Re-titling would silently overwrite renames. |

### Migration

| # | Decision | Rationale |
|---|---|---|
| D9 | **`MigrationV3SeedEmotions` becomes a reserved no-op** — `run()` succeeds without writing; description records that emotions are now seeded on first sheet open. | Deleting it would leave the author's stored `dataSchemaVersion` of 3 ahead of a registry whose max is 2. Harmless today, but any future v3 would then never run on that device. Keeping the slot reserved removes the footgun. |

## Consequences

- **`SettingsObject` gains a field.** A new `@HiveField` plus a `build_runner`
  run. `MigrationRunner` reconstructs `KeklistSettings` field-by-field when it
  bumps the schema version, so that call site must be updated too or the new flag
  is silently dropped on every migration.
- **Emotion titles are deliberately outside the l10n pipeline.** `gen-l10n` will
  not report them as missing translations, so adding a 13th language means
  remembering to extend the const map as well as the ARB set. D7's English
  fallback keeps that failure soft.
- **Testing first-run requires deleting the app** from the simulator — an
  existing install has both emotions and (after first open) the flag set.
- **Existing data is safe.** With D2, a store that already holds emotions is
  never seeded; the flag is simply set to `true` on first open.

## Implementation sketch (not yet done)

1. **Settings** — add `hasSeededEmotions` to `SettingsObject` (`@HiveField`),
   `KeklistSettings` (constructor, `toObject`, `initial()` = `false`), the
   repository's `updateSettings`, and the field-by-field rebuild inside
   `MigrationRunner`. Run `build_runner`.
2. **Seed data** — a `const Map<SupportedLanguage, List<({String emoji, String title})>>`
   (or a per-language title list against a shared emoji order) in the domain
   layer, covering all 12 locales, with English as the fallback entry.
3. **Bloc** — `EmotionSeedDefaults` event; handler reads settings, returns early
   unless `!hasSeededEmotions && emotions.isEmpty`, writes the five emotions with
   `orderIndex` 0..4 and `parentId: null`, then sets the flag.
4. **Sheet** — dispatch `EmotionSeedDefaults` once from `initState`.
5. **Migration** — gut `MigrationV3SeedEmotions.run()` to a no-op and reword its
   `description`.
6. **Verify** — delete the app from the simulator, set the device/app language to
   a non-English locale, launch, open the marker, confirm the five titles are
   translated and that reopening does not duplicate them.

## Verified

On a **clean install** with the simulator set to Russian, opening the marker for
the first time produced Злость / Страх / Грусть / Радость / Любовь in the right
order with the right emoji, and closing and reopening the sheet did **not**
duplicate them.

`test/presentation/blocs/emotion_bloc/emotion_seed_defaults_test.dart` covers all
three guard branches, including the one that cannot be reached on a fresh device
— an existing emotion store with the flag still `false`, which must record the
flag without writing anything. That is the branch protecting data created before
the flag existed.

## Open items

- Whether the emoji set should ever vary by locale (assumed no — emoji are
  language-neutral and stay identical across all 12).
