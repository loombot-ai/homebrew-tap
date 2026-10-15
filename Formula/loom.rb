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
  BASE_URL = "https://downloads.loombot.dev/v0.2.4".freeze

  on_macos do
    on_arm do
      url "#{BASE_URL}/loom-0.2.4-aarch64-apple-darwin"
      sha256 "0b943b04310e91f922e2bc1f86682375f0db24dc4e66c09c1abdaf0804bdfeab"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.4-aarch64-apple-darwin"
        sha256 "a366039afe910067c47a89af418ce47d99a0342a8ca9a5c64170a797a22b6808"
      end
    end

    on_intel do
      url "#{BASE_URL}/loom-0.2.4-x86_64-apple-darwin"
      sha256 "e4b8752e740318e0f9dba234fdbf3671a29be115ddf190fa2de3e06c1c34bdde"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.4-x86_64-apple-darwin"
        sha256 "982a20c43c460e245611b257da0114782b35568d5457c57699ff3c7c8bdcb070"
      end
    end
  end

  on_linux do
    on_arm do
      url "#{BASE_URL}/loom-0.2.4-aarch64-unknown-linux-gnu"
      sha256 "f69e13d005a17fa8c42dd05ae54328542505294197a2f244360a755f46bc0362"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.4-aarch64-unknown-linux-gnu"
        sha256 "cddd751d99378f0e907874968c0bb599b088e1cb62a98e7b2596dee5465e3554"
      end
    end

    on_intel do
      url "#{BASE_URL}/loom-0.2.4-x86_64-unknown-linux-gnu"
      sha256 "461d78d9d9da49358384ab2b70b24eb54f2ddc8c0df11c0f5171fd3c18464be7"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.4-x86_64-unknown-linux-gnu"
        sha256 "90ed26a5172bdd51a2b840d68c53bbc7671870f399fa172b187185dbfdd0e245"
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
