# CreatorCut — current code for review

Updated 2026-11-04T11:06:08.997633+00:00. This is the current **2.8.0 source snapshot**, including the visible-chat architecture and the latest fixes. It is not a verified customer release. The normal customer installer remains 2.7.23; this publication does not change its update channel.

Download [source-review.zip](source-review.zip), unpack it, and review `CreatorCut OS/`. The archive contains 1593 exact current CreatorCut text/code files, including development tests. Generated third-party dependency skills are excluded; CreatorCut’s own canonical and mirrored skills are retained unchanged. [source-manifest.json](source-manifest.json) hashes every included byte. [omitted-assets.json](omitted-assets.json) identifies omitted preview videos, photos, fonts, sounds and any owner-specific paths. No real footage, projects, chat logs, profile, personal presets, memory, credentials, installed runtimes or account data is included.

## Architecture now

Studio saves immutable requests. The user's visible chat is the only editor. Claude's open chat wakes through one background waiter; Codex uses **go**. The hidden editor, clipboard/delivery-token handoff and creative release paperwork were removed from the customer path. Studio reads one engine-owned status, with real command activity, monotonic progress, Stop and plain needs-you states. Existing design, all 46 effects, 9 overall styles and 20 caption styles remain.

## Latest fixes in this exact snapshot

- Effects use the ungraded cut; colour is applied last, with the unchanged strict effect checks.
- Explicit colour choices now override stock photographic tint overlays, including Fireside. Real Source snapshots passed for B&W, Original and Warm; B&W sampled RGB spread was 0.0.
- Reference speech uses the already-verified installed model with local-only loading. A real 45.9-second reference produced 169 words with network attempts blocked and no new model-cache files.
- Pinned renderer audio headroom, private local fonts/browser/cache, and one same-quality retry for actual partial parallel-capture failures. No retry bypasses a host denial. The real 4.6-second Spotlight variant passed strict checks.
- Failed previews no longer become premature omission notices while the chat is still fixing them. A still-unresolved effect is reported at publication; unchecked effects cannot attach. Storage/missing-footage pauses are not mislabelled as creative omissions.
- Presets preserve immutable editable HTML/effect design. New edit requests resolve current library code without rewriting old saved choices or weakening strict old-pin lookup.
- The journey verifier now checks B&W in both published versions, not only the first.

## What actually passed, and what did not

The last full regression passed 780 tests with 0 failures, 0 errors and 2 skips; 29 UI suites passed. **Those runs predate the latest changes.** Focused tests passed for the new model/colour/retry/revision checks; there is no claim that this exact snapshot passed a new full suite. See [review-summary.json](review-summary.json).

A real fresh Claude diagnostic installed the exact then-candidate, woke from idle on Make, produced 17.733-second v1 and 15.7-second v2 with Spotlight, applied two UI notes and downloaded the result. Zero recorded permission denials and zero customer technical-text hits. It was **not accepted as a complete journey**: enlarged exit text lingered just after the five-second boundary, reference influence was not conclusively verified, and test-only duplicate cache was manually cleaned. Product Source changed during that diagnostic.

Actual old 2.7.23 Update-button test, with its GitHub candidate download replaced locally, preserved all 10 sample customer-data files. Real effects tested include Frame Break, Spotlight, Orbit, Couch Wall, Freeze Sticker, Type Wall and UI World in colour/B&W; the full 46-effect matrix is incomplete.

Codex's ordinary restricted environment on this Mac denies the local browser connection and crashes Chromium. A file-only alternative failed too. No permission was changed, no denial bypassed, and no Codex render is marked passed. Desktop Trust-click testing, final exact-build journeys, complete option/learning/recovery tests and final-source regressions remain unfinished. Acceptance stays false.

The working App remains 2.7.23, deliberately separate from canonical 2.8 Source until acceptance. Review current Source here; do not assume an older running App has already received these changes.

Please report concrete reproducible issues and distinguish code reading, unit tests, component renders and complete customer journeys.
