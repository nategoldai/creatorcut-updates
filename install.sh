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
case "$#" in
  0) ;;
  2) if [ "$1" = --directory ] && [ -n "$2" ]; then DEST=$2
     else echo 'Use --directory followed by the CreatorCut folder path.' >&2; exit 2; fi ;;
  *) echo 'Use --directory followed by the CreatorCut folder path.' >&2; exit 2 ;;
esac
case "$DEST" in /*) ;; *) DEST="$PWD/$DEST" ;; esac
case "$DEST" in
  *'
'*) echo 'Choose an app folder without line breaks in its name.' >&2; exit 2 ;;
esac
if [ -e "$DEST" ]; then
  if [ -f "$DEST/edit.py" ] && [ -f "$DEST/kit/setup/install.sh" ] && [ -f "$DEST/kit/SHA256-MANIFEST.json" ] &&
     ! [ -f "$DEST/kit/studio-out/.install-complete" ] &&
     ! grep -q '^window\.AIE_PROGRESS = {"state":"done"' "$DEST/kit/studio-out/progress.js" 2>/dev/null; then
    exec /bin/bash "$DEST/kit/setup/install.sh" --no-shortcut
  fi
  echo 'That folder already exists. Open Studio and press Download new version.'
  exit 1
fi
# Stage on the destination volume. Publishing is a rename, even for an external drive.
PARENT="$(dirname "$DEST")"
if ! mkdir -p "$PARENT" || ! WORK=$(mktemp -d "$PARENT/.creatorcut-install.XXXXXXXX"); then
  echo 'CreatorCut cannot write to that location. Choose a writable folder and try again.' >&2
  exit 1
fi
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
ZIP_COMPLETE=0
for ATTEMPT in 1 2 3; do
  if [ "$ZIP_COMPLETE" = 0 ]; then
    STATUS=0
    curl -fL -C - -D "$WORK/headers" --connect-timeout 20 --speed-limit 1024 --speed-time 90 --max-time 1800 "$BASE/CreatorCut-OS.zip" -o "$WORK/CreatorCut-OS.zip" || STATUS=$?
    if [ "$STATUS" = 0 ]; then ZIP_COMPLETE=1
    elif [ "$STATUS" = 33 ] || [ "$ATTEMPT" = 2 ]; then rm -f "$WORK/CreatorCut-OS.zip"
    fi
  fi
  if [ "$ZIP_COMPLETE" = 1 ] && \
     curl -fL -D "$WORK/headers" --retry 2 --connect-timeout 20 --max-time 60 "$BASE/CreatorCut-OS.zip.sha256" -o "$WORK/expected"; then
    EXPECTED=$(awk 'NR==1 {print $1}' "$WORK/expected")
    ACTUAL=$(shasum -a 256 "$WORK/CreatorCut-OS.zip" | awk '{print $1}')
    if [ "${#EXPECTED}" = 64 ] && [ "$ACTUAL" = "$EXPECTED" ]; then VERIFIED=1; break; fi
    rm -f "$WORK/CreatorCut-OS.zip"
    ZIP_COMPLETE=0
  fi
  if [ "$ATTEMPT" = 3 ]; then break; fi
  RETRY=$(awk '
    /^HTTP\// { limited=($2==429 || $2==503); wait="" }
    limited && tolower($1)=="retry-after:" { gsub(/\r/, "", $2); wait=$2 }
    END { if (wait ~ /^[0-9]+$/) print wait+0 }
  ' "$WORK/headers" 2>/dev/null || true)
  if [ -n "$RETRY" ] && [ "$RETRY" -gt 60 ]; then
    echo 'The download server is busy. Please try again in a few minutes; nothing was installed.'
    exit 1
  fi
  if [ -n "$RETRY" ] && [ "$RETRY" -gt "$ATTEMPT" ]; then sleep "$RETRY"; else sleep "$ATTEMPT"; fi
done
if [ "$VERIFIED" != 1 ]; then echo 'The download did not verify. Please retry; nothing was installed.'; exit 1; fi
if ! unzip -Z -1 "$WORK/CreatorCut-OS.zip" > "$WORK/list" ||
   ! unzip -Z -l "$WORK/CreatorCut-OS.zip" > "$WORK/details"; then
  echo 'The download is not a CreatorCut package. Please retry; nothing was installed.'
  exit 1
fi
# Info-ZIP displays control characters with a caret. The official archive
# uses plain ASCII paths, so reject those escapes as well as literal carets.
if ! LC_ALL=C awk '
    /[^[:print:]]/ || index($0, "^") || index($0, "\\") || index($0, ":") ||
    /^\// || /\/\// || /(^|\/)\.\.?($|\/)/ { exit 1 }
    {
      name=tolower($0)
      sub(/\/$/, "", name)
      if (seen[name]++) exit 1
    }
' "$WORK/list" || ! LC_ALL=C awk '
    NR > 2 && /^[lbcpDs]/ { exit 1 }
' "$WORK/details"; then
  echo 'Unsafe package entry. Nothing installed.'
  exit 1
fi
unzip -q "$WORK/CreatorCut-OS.zip" -d "$WORK/unpacked"
APP=''
for DIR in "$WORK"/unpacked/*/'CreatorCut OS'; do
 if [ -f "$DIR/edit.py" ]; then
  if [ -n "$APP" ]; then echo 'The package has more than one app. Please retry.'; exit 1; fi
  APP=$DIR
 fi
done
[ -n "$APP" ] || { echo 'The download is incomplete. Please retry.'; exit 1; }
chmod 700 "$APP"
# Recheck under the destination lock. Without this, mv can put the second
# extracted app inside the first one when both downloads finish together.
if /usr/bin/lockf -ks -t 0 "$DEST.install.guard" /bin/sh -c '
  if [ -e "$2" ] || [ -L "$2" ]; then
    echo "That folder already exists. Open Studio and press Download new version." >&2
    exit 1
  fi
  mv "$1" "$2"
' creatorcut-install "$APP" "$DEST"; then
  :
else
  RESULT=$?
  case "$RESULT" in
    75) echo 'CreatorCut is already being installed in that folder.' >&2 ;;
    73) echo 'CreatorCut cannot write to that location. Choose a writable folder and try again.' >&2 ;;
  esac
  exit 1
fi
rm -rf "$WORK"
trap - EXIT HUP INT TERM
exec /bin/bash "$DEST/kit/setup/install.sh" --no-shortcut
