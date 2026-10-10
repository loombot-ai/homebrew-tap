class Loom < Formula
  desc "First-principle agent that runs on your own machine"
  homepage "https://loombot.ai"
  license "Apache-2.0"

  # ---------------------------------------------------------------------------
  # ONE PLACE TO CHANGE.
  #
  # The v0.1.0 artifacts are served from Cloudflare R2 behind this prefix and
  # are anonymously downloadable. Change ONLY this line when they move again;
  # no other line in this file names a host.
  #
  # Every sha256 below is a PREBUILT bare binary, copied verbatim from the
  # release own SHA256SUMS. brew compiles nothing and fetches no source tarball;
  # the file name carries the target triple, which is why install globs.
  # ---------------------------------------------------------------------------
  BASE_URL = "https://downloads.loombot.dev/v0.1.0".freeze

  on_macos do
    on_arm do
      url "#{BASE_URL}/loom-0.1.0-aarch64-apple-darwin"
      sha256 "d9fdb645a2ba68a91c4df9733bc77e88e42470a32c8706fb70585524f38c5d67"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.1.0-aarch64-apple-darwin"
        sha256 "53191558f2674269d599c74b2372d8c1bf6187d1c3fcb91f4c46f1d1b2fc17ac"
      end
    end

    on_intel do
      url "#{BASE_URL}/loom-0.1.0-x86_64-apple-darwin"
      sha256 "016c578e3e91a5f36bf329e8e4d1bb0f39df1ba3e7b87a8195de9fac1bf7e247"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.1.0-x86_64-apple-darwin"
        sha256 "5ae97fecebab25108c36da7a150719a4c07deae8b078c8068826d3593c6cf92b"
      end
    end
  end

  on_linux do
    on_arm do
      url "#{BASE_URL}/loom-0.1.0-aarch64-unknown-linux-gnu"
      sha256 "8896efec9b9e49e67be834dac7e17c945263b76b02fd08f0580ea81351538dfd"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.1.0-aarch64-unknown-linux-gnu"
        sha256 "ad79a73302f8b8b42a09235d12fc92b90523fc43fa6af7d240d86d19389a20ae"
      end
    end

    on_intel do
      url "#{BASE_URL}/loom-0.1.0-x86_64-unknown-linux-gnu"
      sha256 "a2d78a6a7a5ca14a1323b2550c5aa5f94d52b024c8fec738c476809f26073ab9"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.1.0-x86_64-unknown-linux-gnu"
        sha256 "32a464d740d298591528655b82618dd93e8b4d6e0dede4f0f3fbe35ea16d9775"
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
