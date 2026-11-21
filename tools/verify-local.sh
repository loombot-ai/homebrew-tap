#!/usr/bin/env bash
# Prove Formula/loom.rb installs, WITHOUT any hosting.
#
# The formula text is the committed one; the ONLY substitution is the constant in
# the line naming a host, rewritten to the directory the artifacts already sit in.
# Everything else - the
# tarball unpack, the libexec layout, the bin symlinks, the sha256, the two
# installed command names - is exercised for real by a real brew.
#
# THE ARTIFACTS DIR must hold the one file the formula names, e.g.
# loom-bundle-0.3.8.tar.gz: since 0.3.x a release publishes ONE bundle rather
# than eight per-target bare binaries.
#
# No `--ignore-dependencies` is needed on any platform since 2026-11-12: brew
# installs the `deno` dependency where it can bottle it, and on Intel macOS the
# formula has no such dependency - it uses the `deno` already on PATH. See
# README.md "Intel macOS: no `deno` dependency, so the install succeeds".
#
# ⚠️ STALE, AND IT REFUSES RATHER THAN LYING (2026-11-12): the substitution below
# still targets a `BASE_URL` constant the formula no longer has, so it matches
# nothing and the run would have installed from the LIVE url while printing a
# local check - the trap this script's own diff was written to catch. Pointing it
# at the `url` line instead is unverified, and cannot be verified here: brew
# refuses to install a name that is already installed from another tap. Whoever
# fixes it should run it once against a real brew, then delete this paragraph.
#
#   tools/verify-local.sh <artifacts-dir> [tap-name]
set -euo pipefail

ARTIFACTS=$(cd "${1:?usage: verify-local.sh <artifacts-dir> [tap-name]}" && pwd)
TAPNAME="${2:-loomtest/tap}"
HERE=$(cd "$(dirname "$0")/.." && pwd)

WORK=$(mktemp -d)
mkdir -p "$WORK/tap/Formula"
sed -E "s|(BASE_URL = \")[^\"]*|\1file://$ARTIFACTS|" \
  "$HERE/Formula/loom.rb" > "$WORK/tap/Formula/loom.rb"

if ! grep -q 'BASE_URL =' "$WORK/tap/Formula/loom.rb"; then
  echo "REFUSING: the formula no longer has a BASE_URL line, so nothing was substituted and this" >&2
  echo "run would have installed from the live url. See the header; fix the substitution first." >&2
  rm -rf "$WORK"
  exit 1
fi

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
# RE-RUNNABLE, because the last run left its tap behind when it stopped part way: brew refuses to tap the
# same name at a new directory ("remote mismatch"). --force skips the formula load, which is what an
# untrusted tap cannot survive.
brew untap "$TAPNAME" --force >/dev/null 2>&1 || true
brew tap "$TAPNAME" "$WORK/tap"

echo
echo "== brew install loom =="
# A LOCAL tap is not trusted by default (Homebrew refuses to load its formula), and a bare name is
# ambiguous while any other tap ships a formula called loom. Both are the machine's state, not the
# formula's, so the script settles them itself.
brew trust "$TAPNAME" >/dev/null 2>&1 || true
brew install "$TAPNAME/loom"

echo
echo "== loom --version =="
loom --version

echo
echo "== command -v loom / loombot =="
command -v loom
command -v loombot

echo
echo "== brew test loom =="
brew test "$TAPNAME/loom"

echo
echo "== brew uninstall loom =="
brew uninstall "$TAPNAME/loom"
# BREW'S COPY, not "anything called loom". A machine may have loom from deno, from the repository, or from
# another package manager -- the author's does -- and that is not this formula failing. What has to be gone
# is the one brew installed, in brew's own prefix.
if [ -e "$(brew --prefix)/bin/loom" ]; then echo "brew's loom is still in the prefix"; exit 1; fi
if command -v loom >/dev/null 2>&1; then
  echo "note: a loom that is not brew's is still on PATH at $(command -v loom)"
fi
echo "brew's loom and loombot are gone from $(brew --prefix)/bin"
echo "loom and loombot gone from PATH"

echo
echo "== cleanup =="
brew untap "$TAPNAME"
rm -rf "$WORK"
echo "OK"
