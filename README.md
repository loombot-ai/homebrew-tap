# loom - Homebrew tap

    brew install loombot/tap/loom

## Read this before copying the two-line form

Do NOT write `brew install loom`. On Homebrew 7 that installs the CASK named
`loom` - Loom the screen recorder - not this formula. Measured on Homebrew
7.0.9, with this tap already tapped:

    $ brew install loom
    Warning: Treating loom as a cask. For the formula, use loomtest/tap/loom
             or specify the `--formula` flag.
    ==> Fetching downloads for: loom
    ==> Installing Cask loom (0.379.4)

Use the fully qualified name. Homebrew prints the correct form itself:

    brew install loombot/tap/loom     # taps and installs in one go
    brew install --formula loom       # only if the tap is already present

## Status: the formula ships, the artifacts do not yet

`BASE_URL` at the top of `Formula/loom.rb` is a PLACEHOLDER
(`https://downloads.loombot.dev/v0.1.0`) and nothing is served there, so no
install can download yet. Change that ONE line once the artifacts are up; no
other line in the formula names a host.

The eight `sha256` values are final: copied verbatim from the v0.1.0 release
own `SHA256SUMS`, all of them PREBUILT bare binaries. brew compiles nothing.

## What it installs

Both commands the release promises: `loom` and `loomd`. One artifact each per
platform, picked by `on_macos`/`on_linux` x `on_arm`/`on_intel`, for four
targets: `aarch64`/`x86_64` x `apple-darwin`/`unknown-linux-gnu`.

## Linux

Homebrew runs on Linux, so the same commands are meant to cover it and the
formula carries the two `on_linux` branches with real sha256 values. That is a
claim about the formula text, NOT a test result - see MANIFEST-upload.md.

## Verifying the formula without any hosting

    tools/verify-local.sh <artifacts-dir>

Runs a real `brew install` against the same formula with BASE_URL rewritten to
the directory the artifacts already sit in. Proven this way: the platform
branch, the bare-binary install, every sha256, the installed names, brew test,
and a clean uninstall.

## The CI guard

`.github/workflows/ci.yml` runs `brew audit --strict` on every push, and a real
`brew install` on four runners (linux x86_64, linux arm64, macOS intel, macOS
arm) as soon as the base URL starts returning 200. audit checks the formula;
only a real install catches a 404 or a wrong sha256 - which is what breaks when
artifacts move.
