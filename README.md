# loom - Homebrew tap

    brew install --formula loombot-ai/tap/loom

That one line taps and installs in a single go, and it needs no `brew trust`.
Everything below is a footnote to it.

The tap lives in the `loombot-ai` org. The transcripts below were recorded before it was renamed, and their tap names have been corrected in place: the old `loombot/tap` no longer resolves (`git ls-remote` -> "Repository not found").

## What does NOT work, and why

Both facts measured on Homebrew 7.0.9, on macOS 15.7 (Intel) and on Ubuntu
24.04.5 with linuxbrew.

### `brew install loom` on macOS installs the WRONG software

homebrew/cask has a cask named `loom` - Loom.app, the screen recorder, 0.379.4 -
and it shadows this formula even with the tap already tapped:

    $ brew install loom
    Warning: Treating loom as a cask. For the formula, use loombot-ai/tap/loom
             or specify the `--formula` flag.
    ==> Installing Cask loom (0.379.4)
    ==> Moving App 'Loom.app' to '/Applications/Loom.app'

`brew info loom` and `brew upgrade loom` resolve to the cask as well. So does
`brew upgrade loom` on Linux, where there is no cask installed to upgrade:
`Warning: Treating loom as a cask` + `Error: Cask loom is not installed`. Use
the fully qualified name for all of them.

### The two-line form is refused on a machine that has not trusted the tap

    $ brew tap loombot-ai/tap
    $ brew install loom
    Error: Refusing to load formula loombot-ai/tap/loom from untrusted tap
    loombot-ai/tap. Run `brew trust loombot-ai/tap` to trust it.

If the bare name is what you want, trust the tap first:

    brew tap loombot-ai/tap
    brew trust loombot-ai/tap
    brew install loom

The qualified name skips that step: naming the tap explicitly IS the trust
decision, so nothing is shadowed by surprise.

## Status: published and live - 0.3.4

The 0.3.4 bundle is served from Cloudflare R2 at
`https://downloads.loombot.dev/v0.3.4/`, anonymously - no token, no account.
That is the prefix `BASE_URL` names, and it is the only line in the formula that
names a host. The formula's sha256 is the published artifact's, verbatim.

## What it installs

ONE artifact for every platform: `loom-bundle-<version>.tar.gz`, the same bundle
`install.sh` installs, so the two distribution paths cannot drift. It is
JavaScript, not machine code, run by the `deno` this formula depends on - which
is why there is no per-target branch left, and no `on_macos`/`on_linux` at all.

What the tarball holds, and where each piece lands:

    bin/loom, bin/loomd    -> libexec/bin/    one launcher, byte-identical under both
                                              names; the name it is invoked as picks
                                              which program runs ($0, before links)
    loom.js, loomd.js      -> libexec/        the two bundles
    DENO_VERSION           -> libexec/        the Deno version they are built against;
                                              the launcher enforces >= that, < next major
    loom/                  -> libexec/loom/   library, repl and compactor at the paths
                                              the bundle reads at run time

and `bin/loom` + `bin/loomd` in the Cellar are SYMLINKS into `libexec/bin`, because
the launcher's root is the directory ABOVE the script it is running - it resolves
its own symlinks to find `loom.js` and `DENO_VERSION` there.

0.2.x shipped eight bare per-target binaries (`loom-<version>-<target-triple>`
and `loomd-…`); those URLs 404 from 0.3.0 on, and so does the per-target bundle
name (`/v0.3.2/loom-bundle-0.3.2-x86_64-unknown-linux-gnu.tar.gz` -> 404,
measured). There is exactly one file per release now.

### Intel macOS makes brew build Deno

The bundle is platform-independent. The dependency is not: homebrew-core
publishes `deno` bottles for arm64 macOS (sequoia, tahoe, golden_gate), arm64
Linux and x86_64 Linux only, because Homebrew retired Intel x86_64 in September
2026. On an Intel Mac `brew install --formula loombot-ai/tap/loom` therefore builds
llvm, rust, cmake and deno FROM SOURCE before it installs this formula - measured
on macOS 15.7 / Homebrew 7.0.11, where brew announced 12 dependencies to install
and was still compiling cmake after seven minutes. The cheap route there is to
install Deno with Deno's own installer first
(`curl -fsSL https://deno.land/install.sh | sh -s v2.9.7`) and then
`brew install --ignore-dependencies --formula loombot-ai/tap/loom`, which is what
the tap's CI does on that one runner.

## Linux

Homebrew on Linux is supported and tested, not assumed: this tap was installed
and uninstalled on Ubuntu 24.04.5 (linuxbrew 7.0.9, x86_64) and on GitHub
ubuntu-24.04-arm (aarch64). See the CI job below.

## The CI guard

`.github/workflows/ci.yml` runs `brew audit --strict` on every push, then a real
`brew install --formula` followed by the formula own `brew test` and a clean
`brew uninstall` on four runners: ubuntu-latest, ubuntu-24.04-arm, macos-14 and
macos-15-intel. audit checks the formula text; only a real install catches a 404
or a wrong hash, which is what breaks when artifacts move host. That install is
gated on a probe of the formula's OWN `url` line: until that URL serves 200 the
install is skipped rather than failed, and it starts by itself when it does.
(The probe used to curl a hard-coded `loom-0.1.0-…` name, which had been 404
since 0.2.0 - so the install job had silently stopped running. Fixed
2026-10-28.) On `macos-15-intel` the leg installs Deno without brew and passes
`--ignore-dependencies`, for the reason above.

