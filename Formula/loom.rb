class Loom < Formula
  desc "First-principle agent that runs on your own machine"
  homepage "https://loombot.ai"
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
  # ---------------------------------------------------------------------------
  depends_on "deno"

  # ---------------------------------------------------------------------------
  # ONE PLACE TO CHANGE.
  #
  # The artifacts of whichever version BASE_URL names are served from Cloudflare R2 behind this
  # are anonymously downloadable. Change ONLY this line when they move again;
  # no other line in this file names a host.
  #
  # Every sha256 below is a PREBUILT bare binary, copied verbatim from the
  # release own SHA256SUMS. brew compiles nothing and fetches no source tarball;
  # the file name carries the target triple, which is why install globs.
  # ---------------------------------------------------------------------------
  BASE_URL = "https://downloads.loombot.dev/v0.2.5".freeze

  on_macos do
    on_arm do
      url "#{BASE_URL}/loom-0.2.5-aarch64-apple-darwin"
      sha256 "0aeb86235b3aa481f7521e8364ceeba6a023dd87b393bc91ad6ed14a2f6af827"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.5-aarch64-apple-darwin"
        sha256 "c4591c3646b62612f4e2fd633976e91e811e494eddccc174ce05b77eb1bc2bc5"
      end
    end

    on_intel do
      url "#{BASE_URL}/loom-0.2.5-x86_64-apple-darwin"
      sha256 "a61f4ba8dd3b0a8c1b966484c7d0943c289a17b7662e1eb870aafc9d00f2eeb6"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.5-x86_64-apple-darwin"
        sha256 "f0d68d2a075776196d0e2116fd39a002dc20fef0c8615160e0c47f641fc248d6"
      end
    end
  end

  on_linux do
    on_arm do
      url "#{BASE_URL}/loom-0.2.5-aarch64-unknown-linux-gnu"
      sha256 "8fa871384ec64cab108d72bbdf62780a29142c33141628da2cbf7b17af6029c6"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.5-aarch64-unknown-linux-gnu"
        sha256 "3e8aa3b47b198f96103a42614f182a9a13fae4639232e83c58151e86598d1a48"
      end
    end

    on_intel do
      url "#{BASE_URL}/loom-0.2.5-x86_64-unknown-linux-gnu"
      sha256 "b6095cac8b7caacc1edb84892c3b7dfd1708e549db8897126dfcbb69561723be"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.5-x86_64-unknown-linux-gnu"
        sha256 "a6021c67398f18c00c623f43a27f68f79669110ecc8c19d5a9c2dc081f7bb544"
      end
    end
  end

  def install
    # Bare executables, not tarballs, and the file name carries the target
    # triple - hence the glob rather than a literal name.
    bin.install Dir["loom-*"].first => "loom"
    resource("loomd").stage do
      bin.install Dir["loomd-*"].first => "loomd"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/loom --version")
    assert_path_exists bin/"loomd"
  end
end
