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
  BASE_URL = "https://downloads.loombot.dev/v0.3.2".freeze

  # ---------------------------------------------------------------------------
  # ONE BUNDLE, EVERY PLATFORM (0.3.2, 2026-10-28).
  #
  # 0.2.x shipped eight PREBUILT BARE BINARIES - `loom-<version>-<target-triple>` and
  # `loomd-…`, one pair per target - which is why this file used to branch four ways over
  # `on_macos`/`on_linux` x `on_arm`/`on_intel` with eight sha256 values. 0.3.x publishes
  # ONE artifact for all four targets: `loom-bundle-<version>.tar.gz`, the same artifact
  # `install.sh` installs, so the two distribution paths cannot drift. The per-target names
  # 404 now (measured: `/v0.3.2/loom-bundle-0.3.2-x86_64-unknown-linux-gnu.tar.gz` -> 404).
  #
  # The bundle is JavaScript, not machine code: `loom.js` and `loomd.js`, each already
  # bundled by `deno bundle` (every module and npm package inside), run by the `deno` this
  # formula depends on. That is what makes one artifact serve every platform, and it is the
  # same reason the dependency comment below is not optional.
  # ---------------------------------------------------------------------------
  url "#{BASE_URL}/loom-bundle-0.3.2.tar.gz"
  sha256 "e197312c47e49809058c5590bace5aee36db97cc6168f6ee9c75fa96fedcd26d"

  license "Apache-2.0"

  # ---------------------------------------------------------------------------
  # THE ONE DEPENDENCY, AND WHY IT IS NOT OPTIONAL (2026-10-15). A compiled loom spawns a
  # Deno child per repl - that child is what holds the repl's own read/write grant, so
  # without a `deno` on PATH loom starts and then cannot run a single line of code:
  #
  #   [loom] the repl cannot start. a compiled loom needs the Deno CLI on PATH to run the repl
  #
  # Xiaohu hit exactly that on a machine where deno WAS installed, because the directory it
  # lives in was not on PATH - which is the failure this line prevents. brew installs deno and
  # links it where the binary will find it. `deno` is a Homebrew formula, so this is one word
  # rather than a vendored runtime.
  #
  # ⚠️ The rest of the fix is in loom, not here: the binary should also look in the usual
  # places (~/.deno/bin, /opt/homebrew/bin) rather than trusting PATH alone. This line makes
  # the common case work; that change makes the uncommon case work.
  #
  # ⚠️ MEASURED 2026-10-28, and it is Homebrew's business rather than this formula's:
  # homebrew-core publishes `deno` bottles for arm64 macOS, arm64 Linux and x86_64 Linux only
  # (`arm64_sequoia arm64_tahoe arm64_golden_gate arm64_linux x86_64_linux`) - there is no
  # Intel-macOS bottle, because Homebrew retired that platform in September 2026. On an Intel
  # Mac this dependency therefore builds Deno FROM SOURCE (llvm, rust, cmake, ninja: hours),
  # which is what `brew install` will do there. The bundle itself is JavaScript and needs
  # nothing architecture-specific, so the formula is correct on Intel; only brew's route to
  # `deno` is expensive. See README.md.
  # ---------------------------------------------------------------------------
  depends_on "deno"

  def install
    # WHAT IS IN THE TARBALL, and why the whole tree goes into libexec untouched:
    #
    #   bin/loom, bin/loomd   the launcher - one shell script, byte-identical under both
    #                         names; it decides WHICH program by the name it was invoked as
    #   loom.js, loomd.js     the two bundles, run by `deno run --allow-all --no-config`
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
    # the program name from `$0` BEFORE following links (so a link named `loomd` runs loomd),
    # and it follows the link chain afterwards to find libexec. brew's own links are relative
    # (`../Cellar/loom/<version>/libexec/bin/loom`), which that loop handles - verified by a
    # real install, both commands, and one repl.
    bin.install_symlink libexec/"bin/loom"
    bin.install_symlink libexec/"bin/loomd"
  end

  def caveats
    <<~EOS
      loom runs on the Deno this formula installs with it. A repl is a Deno child process, so
      `deno` has to stay on PATH for loom to run a line of code.

      Both commands share one bundle: #{opt_libexec}/bin holds the launcher, and the symlinks
      in #{opt_bin} point at it. The bundle also reads its own library from
      #{opt_libexec}/loom/library.
    EOS
  end

  test do
    # The version brew resolved out of the file name, against what the bundle itself reports.
    # Both commands, because 0.2.x installed a second artifact for loomd and this one does not.
    assert_match version.to_s, shell_output("#{bin}/loom --version")
    assert_match version.to_s, shell_output("#{bin}/loomd --version")

    # THE DEPENDENCY'S WHOLE POINT, measured rather than assumed: `--doctor`'s RUNTIME row
    # spawns a repl child, which is a Deno process, and exits with that row's answer. With no
    # `deno` on PATH this line fails with "the repl cannot start" - which is exactly the
    # failure `depends_on "deno"` is here to prevent. No model, no network.
    assert_match "RUNTIME   can this build run a repl here: YES", shell_output("#{bin}/loom --doctor")
  end
end
