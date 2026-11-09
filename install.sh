#!/bin/sh
set -eu
if [ "$(uname -s)" != Darwin ]; then echo 'Mac only for now.'; exit 1; fi
# Keep this floor in sync with the pinned Python 3.12 arm64 ONNX Runtime wheel.
mac_version="$(sw_vers -productVersion)"
mac_major="${mac_version%%.*}"
mac_arch="$(uname -m)"
if [ "$mac_arch" != arm64 ] && [ "$(sysctl -n hw.optional.arm64 2>/dev/null || true)" = 1 ]; then
  mac_arch=arm64  # The installer itself can be launched under Rosetta.
fi
if [ "$mac_arch" != arm64 ] || ! [ "$mac_major" -ge 14 ] 2>/dev/null; then
  printf '%s\n' "This Mac has $mac_arch and macOS $mac_version. CreatorCut needs an Apple silicon Mac (M1 or newer) with macOS 14 or later. Nothing was installed." >&2
  exit 1
fi
DEST="$HOME/CreatorCut"
if [ "${1:-}" = --directory ] && [ -n "${2:-}" ]; then DEST=$2; fi
if [ -e "$DEST" ]; then
  if [ -f "$DEST/edit.py" ] && [ -f "$DEST/kit/setup/install.sh" ] && [ -f "$DEST/kit/SHA256-MANIFEST.json" ] &&
     ! [ -f "$DEST/kit/studio-out/.install-complete" ] &&
     ! grep -q '^window\.AIE_PROGRESS = {"state":"done"' "$DEST/kit/studio-out/progress.js" 2>/dev/null; then
    exec /bin/bash "$DEST/kit/setup/install.sh" --no-shortcut
  fi
  echo 'That folder already exists. Open Studio and press Download new version.'
  exit 1
fi
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
BASE=${CREATORCUT_PACKAGE_BASE:-https://raw.githubusercontent.com/nategoldai/creatorcut-updates/main}
# Pin both files to one commit; a publication during installation cannot mix releases.
if [ -z "${CREATORCUT_PACKAGE_BASE:-}" ]; then
  if curl -fsSL --retry 2 --connect-timeout 10 --max-time 30 -H 'Accept: application/vnd.github.sha' \
      https://api.github.com/repos/nategoldai/creatorcut-updates/commits/main -o "$WORK/commit"; then
    COMMIT=$(tr -d '\r\n' < "$WORK/commit")
    case "$COMMIT" in *[!0-9a-f]*|'') ;; *)
      if [ "${#COMMIT}" = 40 ]; then BASE="https://raw.githubusercontent.com/nategoldai/creatorcut-updates/$COMMIT"; fi ;;
    esac
  fi
fi
VERIFIED=0
for ATTEMPT in 1 2 3; do
  if curl -fL -C - --connect-timeout 20 --speed-limit 1024 --speed-time 90 --max-time 1800 "$BASE/CreatorCut-OS.zip" -o "$WORK/CreatorCut-OS.zip" && \
     curl -fL --retry 2 --connect-timeout 20 --max-time 60 "$BASE/CreatorCut-OS.zip.sha256" -o "$WORK/expected"; then
    EXPECTED=$(awk 'NR==1 {print $1}' "$WORK/expected")
    ACTUAL=$(shasum -a 256 "$WORK/CreatorCut-OS.zip" | awk '{print $1}')
    if [ "${#EXPECTED}" = 64 ] && [ "$ACTUAL" = "$EXPECTED" ]; then VERIFIED=1; break; fi
    rm -f "$WORK/CreatorCut-OS.zip"
  elif [ "$ATTEMPT" = 2 ]; then
    rm -f "$WORK/CreatorCut-OS.zip"
  fi
  sleep "$ATTEMPT"
done
if [ "$VERIFIED" != 1 ]; then echo 'The download did not verify. Please retry; nothing was installed.'; exit 1; fi
unzip -Z -1 "$WORK/CreatorCut-OS.zip" > "$WORK/list"
while IFS= read -r NAME; do case "$NAME" in /*|../*|*/../*|*/..) echo 'Unsafe package path. Nothing installed.'; exit 1;; esac; done < "$WORK/list"
unzip -q "$WORK/CreatorCut-OS.zip" -d "$WORK/unpacked"
APP=''
for DIR in "$WORK"/unpacked/*/'CreatorCut OS'; do
 if [ -f "$DIR/edit.py" ]; then
  if [ -n "$APP" ]; then echo 'The package has more than one app. Please retry.'; exit 1; fi
  APP=$DIR
 fi
done
[ -n "$APP" ] || { echo 'The download is incomplete. Please retry.'; exit 1; }
mkdir -p "$(dirname "$DEST")"
chmod 700 "$APP"
mv "$APP" "$DEST"
rm -rf "$WORK"
trap - EXIT HUP INT TERM
exec /bin/bash "$DEST/kit/setup/install.sh" --no-shortcut
