# Sourced by every tests/<name>.test.sh. Needs SRC (repo root); the flake check sets it.
set -euo pipefail
: "${SRC:?set SRC to the repo root}"
export QOL_LIB=$SRC/lib/ui.sh QOL_ASSUME_TTY=1
unset WAYLAND_DISPLAY KITTY_WINDOW_ID FZF_DEFAULT_OPTS
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home XDG_CACHE_HOME=$T/cache
mkdir -p "$T/bin" "$HOME"
cp "$SRC"/tests/stubs/* "$T/bin/"
chmod +x "$T"/bin/*
sed -i "1s|.*|#!$BASH|" "$T"/bin/* # the build sandbox has no /usr/bin/env
export PATH=$T/bin:$PATH
fails=0

ok() { printf 'ok   %s\n' "$1"; }
fail() {
  printf 'FAIL %s\n' "$1"
  fails=$((fails + 1))
}
eq() { # <name> <got> <want>
  if [[ $2 == "$3" ]]; then ok "$1"; else fail "$1: got [$2] want [$3]"; fi
}
has() { # <name> <text> <part>
  if [[ $2 == *"$3"* ]]; then ok "$1"; else fail "$1: [$3] not in [$2]"; fi
}
hasnt() { # <name> <text> <part>
  if [[ $2 != *"$3"* ]]; then ok "$1"; else fail "$1: [$3] found in [$2]"; fi
}
check() { # <name> <cmd>...: pass when the command succeeds
  local name=$1
  shift
  if "$@"; then ok "$name"; else fail "$name"; fi
}
# shellcheck disable=SC2034 # out and rc are read by the test files
run() { # <cmd>...: sets $out (stdout and stderr) and $rc; never trips set -e
  rc=0
  out=$("$@" 2>&1) || rc=$?
}
finish() {
  if ((fails)); then
    echo "$fails failed"
    exit 1
  fi
  echo "all passed"
}
