# ADR-0006 — Submitting an iOS build for App Store review

- **Status:** Accepted (design), implemented, not yet run
- **Scope:** `ios/fastlane/Fastfile`, `ios/fastlane/metadata/`
- **Related:** [`ADR-0005`](ADR-0005-play-promote-lane.md) — the Play equivalent

## Context

The ask was "do the same lane for iOS". It cannot be the same lane, because the
App Store model differs from Play in three ways that each change the design.

App Store Connect state when this was decided:

| Version | Platform | State |
|---|---|---|
| 1.1 For Remove | MAC_OS | PREPARE_FOR_SUBMISSION |
| 1.0 | MAC_OS | READY_FOR_SALE |
| 5.0.0 | IOS | READY_FOR_SALE |
| 4.7.0 / 4.6.1 | IOS | READY_FOR_SALE |

1. **There is no track promotion.** Play moved version code 132 from internal to
   production under one listing. The App Store requires a *new marketing version*
   for each submission, and `5.0.0` — what `pubspec.yaml` still says — is already
   `READY_FOR_SALE`.
2. **Review is a human gate.** A lane can submit; Apple decides when it ships.
   With `releaseType = AFTER_APPROVAL`, release then happens automatically, so a
   separate "release" lane would have nothing to trigger.
3. **`deliver` is far more dangerous than `supply`.** It manages the entire store
   listing — description, keywords, screenshots — and there is no
   `fastlane/metadata` or `Deliverfile` on the iOS side to constrain it.

A fourth fact emerged while grounding: **the same app record holds a live macOS
app.** Any version lookup that does not filter by platform will see macOS rows.

## Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | **Marketing version is read from `pubspec.yaml`.** If that version is already the live App Store version, the lane aborts telling you to bump it. | Chosen over a `version:` parameter. One source of truth, at the cost of the lane being unusable until pubspec is bumped — today it says `5.0.0`, which is live, so the first run will abort by design. |
| D2 | **Submit for review only.** `releaseType` stays `AFTER_APPROVAL`, so Apple releases on approval. | Mirrors `promote_to_production`'s single-command shape as closely as the App Store permits. No second lane that could only ever no-op. |
| D3 | **Changelog-only metadata tree.** `notes:` is written to `fastlane/metadata/en-US/release_notes.txt`; screenshots and everything else are explicitly skipped. | Identical guard to ADR-0005 D6, and far more important here: unconstrained `deliver` can overwrite a live store listing. Nothing outside release notes is ever uploaded. |
| D4 | **Every lookup is filtered to `platform: ios`.** | Without it, the guard against "an editable version already exists" would trip on the macOS `1.1 For Remove` and block every iOS release. The bug was found during grilling, before it was written. |
| D5 | **The build is the newest on TestFlight**, echoed before acting. | Same shape as the Play lane reading the highest internal code. Build 152 today. |
| D6 | **`1.1 For Remove` is left alone.** | It cannot be deleted. Apple returns `409 STATE_ERROR`: only the first version of a platform is deletable, and not once any build exists for that platform. It is inert, and D4 keeps it out of the iOS path. |

## Consequences

- **The lane will refuse to run until `pubspec.yaml` is bumped** past `5.0.0`.
  That is D1 working, not a failure — but it means the first invocation aborts.
- **Apple decides the ship moment.** The lane's job ends at submission; approval
  can take hours or days, and release then happens without further action.
- **No rollback.** As with ADR-0005 D3, there is no staged rollout and no halt;
  a bad build is fixed forward with a new version.
- **`en-US` is assumed the primary locale**, consistent with Play. A wrong guess
  fails loudly rather than shipping the wrong text.
- Release notes accumulate one file per version, committed, so what users were
  told about each release lives in git history.

## Implementation

`submit_to_review` in `ios/fastlane/Fastfile`:

```bash
bundle exec fastlane submit_to_review notes:"What changed"
```

1. Require `notes:`; read the version from `pubspec.yaml`.
2. Resolve the API key, read the live iOS version, abort if it equals pubspec's.
3. Read the newest TestFlight build; echo `version (build N) → review`.
4. Write `fastlane/metadata/en-US/release_notes.txt`.
5. `upload_to_app_store` with `skip_binary_upload`, `skip_screenshots`,
   `submit_for_review`, `automatic_release`, `platform: ios`.

## Open items

- The submission answers (`export_compliance_uses_encryption`,
  `add_id_info_uses_idfa`) are set in the lane; if App Review's questionnaire
  changes, they may need revisiting.
- Localized release notes for the other 11 languages; today all fall back to the
  `en-US` text.
