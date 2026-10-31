# CreatorCut — latest code for Claude review

Updated 31 October 2026. This is the latest **review snapshot**, including the visible-chat rebuild, Studio design, stock preview catalogue and music picker. It is not a customer installer and does not replace CreatorCut-OS.zip. The public customer download remains unchanged.

Download [source-review.zip](source-review.zip), unpack it, and review the code in `CreatorCut OS/`. `source-manifest.json` verifies every included byte. Large preview movies, photos, fonts and sounds are omitted; their identities are listed in `omitted-assets.json`. No customer videos, presets, private memory, accounts or installed runtimes are included. Rendering requires the proper local app/tools/assets; this snapshot is for code review, not a complete fresh-install test.

## What the system actually does

The default is `editor_mode=chat`. The user's visible Codex or Claude Code conversation is the editing owner. Studio captures settings, references and notes in one immutable request. While the conversation is listening, Make/Update delivers that request automatically to it. If listening is unavailable, the paste card sends the exact same request to that conversation. A valid claim starts editing; sending is not completion. The old managed engine is retained for explicit development/recovery only. It must never start automatically or act as fallback.

A user may also ask for revisions directly in their CreatorCut conversation. The AI must still select the exact project, respect its request and settings, retain one writer, and publish only a reviewed candidate. Normal host permission decisions still apply. The app cannot force a closed or stopped chat to execute.

## Latest checks

- 893 backend tests run: 881 passed, 12 environment-dependent skips; no failures.
- 29 interface suites passed.
- All 75 library selections checked through current project saving, immutable request, editor choices/context and exact source-integrity validation. All 20 caption styles additionally checked with Captions Off. This is not 75 complete end-to-end video renders.
- Six executable colour recipes; Original has no creative grade, reference colour uses scanned measurements, old pinned version-one recipes retained.
- Real public ccMixter search and Referer-backed streaming preview checked; selected library/uploaded audio hash-bound to its project and immutable request. Four short real mixer exports cover No music, Auto, library and upload, with voice/SFX preservation checked. Auto used an explicitly recorded choice in the synthetic test; not a newly automated full customer edit.
- Fixed a reproduced race: older queued music could override a newer choice after an edit finished. The newest immediate music choice now clears only older queued music, preserving unrelated pending settings. Music state refreshes when reopening a project.
- Earlier release evidence includes real 30–60-second source footage edited and published in both hosts, references, revisions, queueing, measured idle listening and older-version update/rollback. Those tests predate the latest design/music changes; do not equate them to a fresh full production acceptance of this exact snapshot.

## Final acceptance still outstanding

The final Claude paste-backup native-UI check, native closed-chat/reopen integration, native browser file-save completion, and a newly source-bound customer release build remain incomplete. The previous acceptance manifest is stale after the design/music changes. Build admission must stay enabled. Network/provider outages, account limits, disk space and host permissions remain real constraints; no 99%/100% never-freezes claim is supported.

## Useful places to review

- `kit/editkit/chat_execution.py`, `native_receiver.py`, `native_app.py`: delivery, ownership and listener.
- `kit/studio/app/core.js`, `views.js`, `creative.js`, `music.js`: UI saving/start, exact choice IDs, feedback and music.
- `kit/editkit/requests.py`, `videos.py`, `server.py`: immutable requests, active-edit protection and queued next settings.
- `kit/editkit/library.py`, `colour_choice.py`, `render_controls.py`, `music_library.py`, `music_provider.py`: actual executable choices and audio binding.
- `kit/tests/`: regression tests.

Please report concrete reproducible gaps, separating source review from actual end-to-end evidence. Do not recommend silently bypassing permissions, publishing stale/incomplete files, or substituting generic effects/music.
