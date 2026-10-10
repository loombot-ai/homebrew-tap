#!/usr/bin/env bash
# Prove Formula/loom.rb installs, WITHOUT any hosting.
#
# The formula text is the committed one; the ONLY substitution is BASE_URL,
# rewritten to the directory the artifacts already sit in. Everything else -
# the platform branch, the bare-binary (not tarball) install, the sha256, the
# two installed command names - is exercised for real by a real brew.
#
#   tools/verify-local.sh <artifacts-dir> [tap-name]
set -euo pipefail

ARTIFACTS=$(cd "${1:?usage: verify-local.sh <artifacts-dir> [tap-name]}" && pwd)
TAPNAME="${2:-loomtest/tap}"
HERE=$(cd "$(dirname "$0")/.." && pwd)

WORK=$(mktemp -d)
mkdir -p "$WORK/tap/Formula"
sed "s|^  BASE_URL = \".*\"$|  BASE_URL = \"file://$ARTIFACTS\"|" \
  "$HERE/Formula/loom.rb" > "$WORK/tap/Formula/loom.rb"

echo "== the one substituted line =="
grep -n "BASE_URL =" "$WORK/tap/Formula/loom.rb"
echo "== every other line is byte-identical to the committed formula =="
if diff <(grep -v "BASE_URL =" "$HERE/Formula/loom.rb") \
        <(grep -v "BASE_URL =" "$WORK/tap/Formula/loom.rb") >/dev/null; then
  echo "identical OK"
else
  echo "DIFFERS - refusing to test"; exit 1
fi

git -C "$WORK/tap" init -q
git -C "$WORK/tap" add -A
git -C "$WORK/tap" -c user.email=v@v -c user.name=v commit -qm local-verify

echo
echo "== brew tap $TAPNAME $WORK/tap =="
brew tap "$TAPNAME" "$WORK/tap"

echo
echo "== brew install loom =="
brew install loom

echo
echo "== loom --version =="
loom --version

echo
echo "== command -v loom / loomd =="
command -v loom
command -v loomd

echo
echo "== brew test loom =="
brew test loom

echo
echo "== brew uninstall loom =="
brew uninstall loom
if command -v loom >/dev/null 2>&1; then echo "STILL ON PATH"; exit 1; fi
echo "loom and loomd gone from PATH"

echo
echo "== cleanup =="
brew untap "$TAPNAME"
rm -rf "$WORK"
echo "OK"
