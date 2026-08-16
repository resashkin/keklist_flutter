# ADR-0005 — Promoting an internal build to Play production

- **Status:** Accepted (design), implemented, not yet run against Play
- **Scope:** `android/fastlane/Fastfile`, `android/fastlane/metadata/`
- **Related:** the version-code auto-fetch added to `build_and_upload_to_internal`

## Context

Releasing to production is a Play Console click today. The API supports doing it
from a lane, and the service account already has the access — it read every track
and uploaded version code 132 during this session.

Track state when this was decided:

| Track | Version code |
|---|---|
| internal | 132 |
| beta | *(empty)* |
| production | 130 (live) |

Two facts shaped the design:

- **`alpha` does not exist.** Reading it raises `undefined method 'flat_map' for
  nil`, which is why the version-code helper rescues per track rather than
  letting one missing track abort the lane.
- **supply has no inline release-notes option.** Notes must exist on disk as
  `metadata/android/<locale>/changelogs/<version_code>.txt`, so any lane that
  sets "What's new" has to write that file first.

## Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | **Promote-only — never rebuild.** `skip_upload_aab`/`skip_upload_apk` true, `track: 'internal'`, `track_promote_to: 'production'`. | Production gets the exact bytes already exercised on internal. A rebuild could differ from what was tested, and would burn a version code for nothing. |
| D2 | **The version code is read from the internal track**, highest wins, and is echoed with the current production code before acting. | No argument to mistype. The log line records precisely what was promoted and what it replaced. |
| D3 | **Always a full 100% release** — `release_status: 'completed'`, no `rollout`. | Chosen deliberately. See the consequence below: it forfeits the ability to halt. |
| D4 | **No `halt` / `bump` / `complete` lanes.** | They only operate on an in-progress staged rollout, which D3 guarantees never exists. Shipping them would mean three lanes that can only ever error. |
| D5 | **Release notes are a required `notes:` parameter**, written to `fastlane/metadata/android/en-US/changelogs/<version_code>.txt` and committed. | A release can never go out silently carrying 130's stale notes. Committing the file puts "what users were told about this version" in git history. |
| D6 | **The metadata directory holds changelogs only.** No listing, images or screenshots. | supply uploads whatever it finds. Keeping the tree changelog-only is what makes it safe to run with `skip_upload_metadata: false` without touching the store listing. |
| D7 | **internal → production directly; no beta step.** | Beta has never held a release. A ladder through an empty track is ceremony, not safety. |

## Consequences

- **There is no kill switch.** A full release cannot be halted — Play can only
  halt a rollout that is still in progress. A bad production build must be fixed
  forward with a new version code. With beta unused, the internal track is the
  only gate before real users. This is the accepted cost of D3; adding an
  optional `rollout:` parameter later restores the option without changing
  anything else in the lane.
- **`en-US` is assumed to be the default listing locale.** If Play's default is
  something else, supply fails loudly on an unknown locale rather than shipping
  the wrong thing — an easy fix, not a silent one.
- **Promoting to production submits for review** under Play's normal rules; the
  lane does not set `changes_not_sent_for_review`.
- The changelog file accumulates one small text file per released version code.

## Implementation

`promote_to_production` in `android/fastlane/Fastfile`:

1. Read internal and production version codes; abort if internal is empty or not
   ahead of production.
2. Write the notes file for that version code.
3. `upload_to_play_store` with `skip_upload_aab: true`, `version_code`,
   `track: 'internal'`, `track_promote_to: 'production'`,
   `release_status: 'completed'`, images/screenshots skipped.

```bash
bundle exec fastlane promote_to_production notes:"Emotions in export, add-emotion button"
```

## Open items

- Whether to add an optional `rollout:` parameter later, which would make a
  `halt` lane meaningful again.
- Localized changelogs for the other 11 languages; today all locales fall back to
  the `en-US` text.
