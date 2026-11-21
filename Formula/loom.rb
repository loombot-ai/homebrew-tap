class Loom < Formula
  desc "First-principle agent that runs on your own machine"
  homepage "https://loombot.ai"

  # ---------------------------------------------------------------------------
  # ONE PLACE TO CHANGE.
  #
  # The artifacts of whichever version BASE_URL names are served from Cloudflare R2 behind this
  # are anonymously downloadable. Change ONLY this line when they move again;
  # no other line in this file names a host.
  #
  # PER RELEASE, TWO LINES CHANGE: this URL (which also carries the version - it is where brew
  # reads the formula's version from) and the sha256 under it.
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # ONE BUNDLE, EVERY PLATFORM (0.3.2, 2026-10-28).
  #
  # 0.2.x shipped eight PREBUILT BARE BINARIES - `loom-<version>-<target-triple>` and
  # `loombot-…`, one pair per target - which is why this file used to branch four ways over
  # `on_macos`/`on_linux` x `on_arm`/`on_intel` with eight sha256 values. 0.3.x publishes
  # ONE artifact for all four targets: `loom-bundle-<version>.tar.gz`, the same artifact
  # `install.sh` installs, so the two distribution paths cannot drift. The per-target names
  # 404 now (measured: `/v0.3.2/loom-bundle-0.3.2-x86_64-unknown-linux-gnu.tar.gz` -> 404).
  #
  # The bundle is JavaScript, not machine code: `loom.js` and `loombot.js`, each already
  # bundled by `deno bundle` (every module and npm package inside), run by the `deno` this
  # formula depends on. That is what makes one artifact serve every platform, and it is the
  # same reason the dependency comment below is not optional.
  # ---------------------------------------------------------------------------
  version "0.3.8"
  url "https://downloads.loombot.dev/v#{version}/loom-bundle-#{version}.tar.gz"
  sha256 "01a9370d5e0a8679f847a6d28410a4f822e2b657bbac7f83ee8e4fee0c0d69bb"

  license "Apache-2.0"

  # ---------------------------------------------------------------------------
  # THE ONE DEPENDENCY, AND WHERE BREW CAN BOTTLE IT (2026-11-12). A compiled loom spawns a
  # Deno child per repl - that child is what holds the repl's own read/write grant, so
  # without a `deno` on PATH loom starts and then cannot run a single line of code:
  #
  #   [loom] the repl cannot start. a compiled loom needs the Deno CLI on PATH to run the repl
  #
  # ...which is what `depends_on "deno"` prevents wherever brew can supply it: brew installs
  # deno and links it where the binary will find it. `deno` is a Homebrew formula, so this is
  # one word rather than a vendored runtime.
  #
  # ⚠️ NOT ON INTEL MACOS (owner's decision, 2026-11-12). homebrew-core publishes `deno`
  # bottles for arm64 macOS (`arm64_sequoia arm64_tahoe arm64_golden_gate`), arm64 Linux and
  # x86_64 Linux only, because Homebrew retired Intel x86_64 in September 2026. There the
  # dependency installs no package: it starts a source build of llvm, rust, cmake, ninja and
  # deno (hours), and on the owner's machine `brew reinstall` did not fail politely - it failed
  # THIS formula and installed nothing:
  #
  #   deno: A full installation of Xcode.app 15.0 is required to compile this software.
  #   Installing just the Command Line Tools is not sufficient.
  #   Error: An unsatisfied requirement failed this build.
  #
  # ...leaving the loom from an earlier release in the Cellar (0.3.4), while the one actually
  # used was ~/.deno/bin/loom. The bundle is JavaScript and needs nothing architecture-specific,
  # so on Intel it runs the `deno` already on PATH and the launcher refuses a wrong one with a
  # sentence naming the range and the command that installs it - said at install time by
  # #caveats, before the first command is ever typed. So: bottle-backed platforms keep the
  # dependency, Intel macOS has none, and `brew install` succeeds there in seconds.
  #
  # ⚠️ The rest is in loom, not here: the launcher trusts PATH alone rather than also looking in
  # ~/.deno/bin, which is where Deno's own installer writes the binary - hence the `export PATH`
  # line in the caveat.
  # ---------------------------------------------------------------------------
  # NO `deno` DEPENDENCY ON macOS, ON EITHER ARCHITECTURE (measured 2026-11-12 on Homebrew 7.0.15).
  #
  # The formula used to keep `depends_on "deno"` on Apple Silicon on the belief that brew had an arm64
  # bottle. `brew info deno` here shows NO bottle at all - only `Build (6): cmake, lld, llvm, ninja,
  # pkgconf, rust` and `Requirements: Build: Xcode >= 15.0 (on macOS)` - so on the owner's Mac, and on
  # any Mac, that dependency builds Deno from source: hours, and a full Xcode. The bundle is JavaScript
  # and needs nothing architecture-specific, so the launcher runs the `deno` on PATH and refuses a wrong
  # one with a sentence naming the range and the command that installs it.

  def install
    # WHAT IS IN THE TARBALL, and why the whole tree goes into libexec untouched:
    #
    #   bin/loom, bin/loombot  the launcher - one shell script, byte-identical under both
    #                         names; it decides WHICH program by the name it was invoked as
    #   loom.js, loombot.js    the two bundles, run by `deno run --allow-all --no-config`
    #   DENO_VERSION          the Deno version they were built and verified against (2.9.7);
    #                         the launcher refuses anything outside `>= that, < next major`
    #   loom/                 the files the bundle reads at run time at the paths it expects
    #                         (loom/library, loom/repl/js_repl.js, loom/worker/compactor.md)
    #
    # THE LAUNCHER'S ROOT IS THE DIRECTORY ABOVE bin/, and it resolves symlinks to find it:
    # `root=$(cd "$(dirname "$self")/.." && pwd)`, then it requires `$root/DENO_VERSION` and
    # execs `$root/<invoked name>.js`. So the layout has to keep bin/ one level below the
    # things it needs, and libexec is exactly that root. Installing the launcher into `bin`
    # and leaving the rest behind would put root at the Cellar prefix, where none of those
    # files are: the launcher exits 1 saying DENO_VERSION is missing. Hence the Homebrew
    # shape for a program that needs a directory beside it: everything in libexec, symlinks
    # in bin.
    libexec.install Dir["*"]

    # THE SYMLINKS ARE NOT COSMETIC, they are load-bearing on both ends: the launcher takes
    # the program name from `$0` BEFORE following links (so a link named `loombot` runs loombot),
    # and it follows the link chain afterwards to find libexec. brew's own links are relative
    # (`../Cellar/loom/<version>/libexec/bin/loom`), which that loop handles - verified by a
    # real install, both commands, and one repl.
    bin.install_symlink libexec/"bin/loom"
    bin.install_symlink libexec/"bin/loombot"
  end

  # THE PREREQUISITE, SAID WHERE A PERSON LOOKS AFTER INSTALLING (2026-11-12). On Intel macOS
  # this formula does not depend on `deno` (see the class body), so brew installs a working
  # bundle with no runtime at all - and the first thing that goes wrong is the first `loom`
  # command, whose launcher refuses with a good sentence that nobody reads because nobody types
  # a command before installing. A caveat is read at exactly that moment: it names the
  # prerequisite, the range the launcher enforces, and the command that installs it. The literal
  # 2.9.7 is the number the bundle ships in its own DENO_VERSION file and the floor the launcher
  # enforces; it moves only when a release's DENO_VERSION does.
  def caveats
    text = <<~EOS
      loom runs on Deno: a repl is a Deno child process, so `deno` has to stay on PATH for loom
      to run a line of code.

      Both commands share one bundle: #{opt_libexec}/bin holds the launcher, and the symlinks
      in #{opt_bin} point at it. The bundle also reads its own library from
      #{opt_libexec}/loom/library.
    EOS

    text += <<~EOS

      ⚠️  THIS FORMULA DOES NOT INSTALL DENO. `brew info deno` has no bottle on macOS (only build
      dependencies: llvm, rust, cmake, ninja, and a full Xcode), so a dependency on it means
      building Deno from source for hours. loom runs the `deno` on your PATH instead, and refuses
      anything outside >= 2.9.7, < 3.0 with a sentence naming that range. If you have none, or an
      older one:

        curl -fsSL https://deno.land/install.sh | sh -s v2.9.7
        export PATH="$HOME/.deno/bin:$PATH"

      The installer writes deno into ~/.deno/bin and does not put it on PATH for you. To check the
      result, `loom --doctor` answers whether the runtime loom can see will run a repl.
    EOS

    text
  end

  test do
    # The version brew resolved out of the file name, against what the bundle itself reports.
    # Both commands, because 0.2.x installed a second artifact for loombot and this one does not.
    assert_match version.to_s, shell_output("#{bin}/loom --version")
    assert_match version.to_s, shell_output("#{bin}/loombot --version")

    # THE RUNTIME, measured rather than assumed: `--doctor`'s RUNTIME row spawns a repl child,
    # which is a Deno process, and exits with that row's answer. With no `deno` on PATH this
    # line fails with "the repl cannot start" - what `depends_on "deno"` prevents on the
    # platforms brew can bottle it for, and what the caveat's installer command prevents on
    # Intel macOS, where this formula has no such dependency. No model, no network.
    assert_match "RUNTIME   can this build run a repl here: YES", shell_output("#{bin}/loom --doctor")
  end
end
