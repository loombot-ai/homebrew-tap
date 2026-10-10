# loom - Homebrew tap

    brew install --formula loombot/tap/loom

That one line taps and installs in a single go, and it needs no `brew trust`.
Everything below is a footnote to it.

## What does NOT work, and why

Both facts measured on Homebrew 7.0.9, on macOS 15.7 (Intel) and on Ubuntu
24.04.5 with linuxbrew.

### `brew install loom` on macOS installs the WRONG software

homebrew/cask has a cask named `loom` - Loom.app, the screen recorder, 0.379.4 -
and it shadows this formula even with the tap already tapped:

    $ brew install loom
    Warning: Treating loom as a cask. For the formula, use loombot/tap/loom
             or specify the `--formula` flag.
    ==> Installing Cask loom (0.379.4)
    ==> Moving App 'Loom.app' to '/Applications/Loom.app'

`brew info loom` and `brew upgrade loom` resolve to the cask as well. So does
`brew upgrade loom` on Linux, where there is no cask installed to upgrade:
`Warning: Treating loom as a cask` + `Error: Cask loom is not installed`. Use
the fully qualified name for all of them.

### The two-line form is refused on a machine that has not trusted the tap

    $ brew tap loombot/tap
    $ brew install loom
    Error: Refusing to load formula loombot/tap/loom from untrusted tap
    loombot/tap. Run `brew trust loombot/tap` to trust it.

If the bare name is what you want, trust the tap first:

    brew tap loombot/tap
    brew trust loombot/tap
    brew install loom

The qualified name skips that step: naming the tap explicitly IS the trust
decision, so nothing is shadowed by surprise.

## Status: published and live

The v0.1.0 artifacts are served from Cloudflare R2 at
`https://downloads.loombot.dev/v0.1.0/`, anonymously - no token, no account.
That is the prefix `BASE_URL` names, and it is the only line in the formula
that names a host.

The eight sha256 values are final: copied verbatim from the release own
`SHA256SUMS`, every one a PREBUILT bare binary. brew compiles nothing and
fetches no source tarball.

## What it installs

Both commands the release promises, `loom` and `loomd`, one artifact each per
platform, picked by `on_macos`/`on_linux` x `on_arm`/`on_intel` across the four
targets `aarch64`/`x86_64` x `apple-darwin`/`unknown-linux-gnu`.

## Linux

Homebrew on Linux is supported and tested, not assumed: this tap was installed
and uninstalled on Ubuntu 24.04.5 (linuxbrew 7.0.9, x86_64) and on GitHub
ubuntu-24.04-arm (aarch64). See the CI job below.

## The CI guard

`.github/workflows/ci.yml` runs `brew audit --strict` on every push, then a real
`brew install --formula` followed by the formula own `brew test` and a clean
`brew uninstall` on four runners: ubuntu-latest, ubuntu-24.04-arm, macos-14 and
macos-13. audit checks the formula text; only a real install catches a 404 or a
wrong hash, which is what breaks when artifacts move host.
