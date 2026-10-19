# CreatorCut updates

Release packages only. The website source and customer projects are not stored here.

## Publish the next update

1. Open this repository and choose **Add file → Upload files**.
2. Upload the new release ZIP supplied to you, named **CreatorCut-OS.zip**, replacing the existing file.
3. Click **Commit changes** on the **main** branch.

That is all. No separate manifest, release tag, token or workflow is needed. Use a genuinely newer release: renaming an old ZIP does not create an update.

CreatorCut checks on startup and every six hours while open. After it verifies the newer ZIP, users see **Install update** on Home and Studio. Users click to install when their active work is finished. Projects, presets, editing memory, original footage and installed tools are preserved.

This channel is included in CreatorCut OS 2.3.2 and later. Older website-fed installations need the one-time migration update before they check this repository directly.

Do not upload customer recordings, projects, saved preferences, credentials or installed runtimes here.
