#!/bin/sh
set -u
BUNDLE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GAME_BIN="$BUNDLE_DIR/lantern_house_internal.x86_64"
if [ ! -x "$GAME_BIN" ]; then
  echo "ERROR: Required executable is missing or not executable: lantern_house_internal.x86_64" >&2
  echo "Re-extract the complete internal playtest bundle and try again." >&2
  exit 2
fi
"$GAME_BIN" "$@"
exit $?
