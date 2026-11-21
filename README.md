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

### So every line here is fully qualified - there is no bare-name form

Naming the tap explicitly IS the trust decision, which is why the one line at the
top needs no `brew trust`. The two-line form is refused on a machine that has not
trusted the tap - and would still not install this formula on macOS:

    $ brew tap loombot-ai/tap
    $ brew install loom
    Error: Refusing to load formula loombot-ai/tap/loom from untrusted tap
    loombot-ai/tap. Run `brew trust loombot-ai/tap` to trust it.

On macOS `brew install loom` is the cask even when the tap IS trusted, so the
formula is `loombot-ai/tap/loom` with `--formula`, on every line - install, info,
upgrade and uninstall alike. `brew install loom` alone moves
`/Applications/Loom.app` into place: measured, the screen recorder, 0.379.4.

## Status: published and live - 0.3.8

The 0.3.8 bundle is served from Cloudflare R2 at
`https://downloads.loombot.dev/v0.3.8/`, anonymously - no token, no account. The
formula's `url` is the only line in it that names a host, its one `version`
literal is where the version lives, and its sha256 is the published artifact's,
verbatim.

## What it installs

ONE artifact for every platform: `loom-bundle-<version>.tar.gz`, the same bundle
`install.sh` installs, so the two distribution paths cannot drift. It is
JavaScript, not machine code, run by a `deno` - installed by brew where brew can
bottle it, and taken from PATH on Intel macOS. That dependency is the only thing
the formula branches on, so there is still no per-target artifact.

What the tarball holds, and where each piece lands:

    bin/loom, bin/loombot    -> libexec/bin/    one launcher, byte-identical under both
                                              names; the name it is invoked as picks
                                              which program runs ($0, before links)
    loom.js, loombot.js      -> libexec/        the two bundles
    DENO_VERSION           -> libexec/        the Deno version they are built against;
                                              the launcher enforces >= that, < next major
    loom/                  -> libexec/loom/   library, repl and compactor at the paths
                                              the bundle reads at run time

and `bin/loom` + `bin/loombot` in the Cellar are SYMLINKS into `libexec/bin`, because
the launcher's root is the directory ABOVE the script it is running - it resolves
its own symlinks to find `loom.js` and `DENO_VERSION` there.

0.2.x shipped eight bare per-target binaries (`loom-<version>-<target-triple>`
and `loombot-…`); those URLs 404 from 0.3.0 on, and so does the per-target bundle
name (`/v0.3.2/loom-bundle-0.3.2-x86_64-unknown-linux-gnu.tar.gz` -> 404,
measured). There is exactly one file per release now.

### Intel macOS: no `deno` dependency, so the install succeeds

The bundle is platform-independent. The dependency never was: homebrew-core
publishes `deno` bottles for arm64 macOS (sequoia, tahoe, golden_gate), arm64
Linux and x86_64 Linux only, because Homebrew retired Intel x86_64 in September
2026. So on an Intel Mac `depends_on "deno"` installed no package - it started a
source build of llvm, rust, cmake, ninja and deno, measured on macOS 15.7 /
Homebrew 7.0.11 as 12 dependencies with cmake still bootstrapping after seven
minutes. On the owner's machine `brew reinstall loombot-ai/tap/loom` did not even
get that far, and installed nothing:

    deno: A full installation of Xcode.app 15.0 is required to compile this software.
    Installing just the Command Line Tools is not sufficient.
    Error: An unsatisfied requirement failed this build.

**Since 2026-11-12 the formula does not depend on `deno` on Intel macOS**
(`Formula/loom.rb`, the `on_macos`/`on_arm` block). brew has nothing to build
there, so `brew install --formula loombot-ai/tap/loom` succeeds on an Intel Mac -
and what it needs first is a Deno of its own, because loom runs on one:

    curl -fsSL https://deno.land/install.sh | sh -s v2.9.7
    export PATH="$HOME/.deno/bin:$PATH"

That is Deno's own installer at the exact version the release is built and
verified against (the bundle ships it as `DENO_VERSION`), and the `export` matters
because the installer does not put `~/.deno/bin` on PATH. The launcher refuses
anything outside `>= 2.9.7, < 3.0` with a sentence naming that range and the same
command; the formula's caveats say it after the install, which is where a person
looks first, and `loom --doctor` answers whether the runtime loom can see will run
a repl. Nothing else on this platform is special: on the three platforms brew CAN
bottle `deno` for, the formula still depends on it and installs it.

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

That probe has now been wrong twice, in the same way - it stopped following the
formula and nothing said so. First it curled a hard-coded `loom-0.1.0-…` name
(404 since 0.2.0, fixed 2026-10-28). Then it substituted a `BASE_URL` constant
that the formula no longer has, leaving a literal `#{version}` in the URL: 404,
`live=false`, and the whole install job - all four legs - skipped while the run
read green. Fixed 2026-11-12: the probe reads the formula's `version` literal and
substitutes that, so all it assumes is that the `url` line interpolates `version`.

`macos-15-intel` installs Deno with Deno's own installer rather than brew's,
because the formula no longer depends on `deno` on that platform (see above) - the
leg runs with the runtime an Intel user actually has, and asserts the formula's
own three checks by hand.

