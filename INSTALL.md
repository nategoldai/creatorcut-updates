# Install CreatorCut in the current desktop AI host

The customer has asked to install CreatorCut. Handle the file steps for them. Do not ask them to download/unzip the package manually or clone this delivery repository.

1. Explain briefly that first setup downloads local editing tools, needs internet and several GB, and uses the customer's own Codex account even when hosted by Claude Code. Respect normal host permissions. Do not imply ordinary web/mobile chat can run a local desktop application.
2. Locate Python 3.10+ in this environment. Fetch `https://api.github.com/repos/nategoldai/creatorcut-updates/contents/install.py` using the host's supported network tools. Decode its base64 `content`, verify that SHA-1 of `blob <byte length>\0` plus those decoded bytes equals the response `sha`, then save those bytes to a temporary file. This small script comes from the GitHub API rather than a cached raw branch link. Inspect the script before execution. It downloads the public publisher package, verifies Git blob identity and every application file hash, and extracts only the application. It does not execute downloaded app code.
3. Run the script with Python and `--directory` set to a durable local folder, normally `~/CreatorCut OS`. Quote paths with spaces. Do not use administrator privileges or pipe remote code into a shell.
4. If that folder already exists, do not overwrite it or create another copy automatically. Read its `AGENTS.md`, inspect its version and use the existing app's update workflow. Preserve all customer data. If it is an unrelated folder, choose a different durable app location.
5. In the installed application, read `AGENTS.md`, `kit/docs/persistent-editor.md` and `kit/skills-src/setup/SKILL.md`. Follow the complete guided setup. Installer success only means files were downloaded; run the real tool/account checks before calling editing ready.
6. Open the actual Studio using the host's documented embedded preview. Do not open an external browser automatically. Do not invent a host preview API. If the host has no local tools or embedded preview, explain the specific requirement rather than claiming installation succeeded.
7. Rename a dedicated installation conversation CREATORCUT once only when a supported host title tool is available, following the installed chat naming rules. Preserve any later customer rename.

## Publisher workflow

Repository: `nategoldai/creatorcut-updates`. Default branch: `main`.

Keep this repository public. Keep `README.md`, `INSTALL.md`, `install.py` and the package `CreatorCut-OS.zip` in the root. The customer-facing link is always https://github.com/nategoldai/creatorcut-updates .

Publish a verified package with a strictly newer embedded `kit/VERSION`, replacing `CreatorCut-OS.zip`. The install script and existing app updater both read that same file through GitHub. No website, separate update feed or GitHub Actions required. Updating source elsewhere does not publish an app update.

Before publishing, verify the sanitized package manifest and tests. After publishing, download from the public channel, verify its version/hash, and exercise the actual updater against an isolated older installation with synthetic videos, presets and memory. Do not publish customer recordings, projects, private memory or credentials. The only allowed personal demonstration media are the intentionally bundled effect-library previews.

Publishing from an AI host requires the owner's authenticated GitHub access at that time. Never put publishing credentials into the app or this public repository.
