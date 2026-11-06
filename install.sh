#!/bin/sh
set -eu
if [ "$(uname -s)" != Darwin ]; then echo 'Mac only for now.'; exit 1; fi
DEST="$HOME/CreatorCut"
if [ "${1:-}" = --directory ] && [ -n "${2:-}" ]; then DEST=$2; fi
if [ -e "$DEST" ]; then echo 'That folder already exists. Open it and ask your chat to update CreatorCut; your videos are kept.'; exit 1; fi
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
BASE=${CREATORCUT_PACKAGE_BASE:-https://raw.githubusercontent.com/nategoldai/creatorcut-updates/main}
curl -fL --retry 3 --connect-timeout 20 --max-time 300 "$BASE/CreatorCut-OS.zip" -o "$WORK/CreatorCut-OS.zip"
curl -fL --retry 3 --connect-timeout 20 --max-time 60 "$BASE/CreatorCut-OS.zip.sha256" -o "$WORK/expected"
EXPECTED=$(awk 'NR==1 {print $1}' "$WORK/expected")
ACTUAL=$(shasum -a 256 "$WORK/CreatorCut-OS.zip" | awk '{print $1}')
if [ "${#EXPECTED}" != 64 ] || [ "$ACTUAL" != "$EXPECTED" ]; then echo 'The download did not verify. Please retry; nothing was installed.'; exit 1; fi
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
mv "$APP" "$DEST"
cd "$DEST"
rm -rf "$WORK"
trap - EXIT HUP INT TERM
exec /bin/bash kit/setup/install.sh --no-shortcut
