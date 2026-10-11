class Loom < Formula
  desc "First-principle agent that runs on your own machine"
  homepage "https://loombot.ai"
  license "Apache-2.0"

  # ---------------------------------------------------------------------------
  # ONE PLACE TO CHANGE.
  #
  # The v0.2.0 artifacts are served from Cloudflare R2 behind this prefix and
  # are anonymously downloadable. Change ONLY this line when they move again;
  # no other line in this file names a host.
  #
  # Every sha256 below is a PREBUILT bare binary, copied verbatim from the
  # release own SHA256SUMS. brew compiles nothing and fetches no source tarball;
  # the file name carries the target triple, which is why install globs.
  # ---------------------------------------------------------------------------
  BASE_URL = "https://downloads.loombot.dev/v0.2.0".freeze

  on_macos do
    on_arm do
      url "#{BASE_URL}/loom-0.2.0-aarch64-apple-darwin"
      sha256 "88ddf8ca4019cac872edecb4f0b0a646b0a09a590cc92a079ad0e993e61425f4"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.0-aarch64-apple-darwin"
        sha256 "7b67d7804de9e2d6f51fe427124d23ef72d9209511c7f7b9611dfe8d62ee9f06"
      end
    end

    on_intel do
      url "#{BASE_URL}/loom-0.2.0-x86_64-apple-darwin"
      sha256 "9ab2bbbc949a280dd5aa31d2f8eb9a22ec8560100671825248a222c589829b1d"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.0-x86_64-apple-darwin"
        sha256 "705c0eac7ffaf205352609b3459698cbf7edcde2ea2655f56a9accb50ac1a7e7"
      end
    end
  end

  on_linux do
    on_arm do
      url "#{BASE_URL}/loom-0.2.0-aarch64-unknown-linux-gnu"
      sha256 "f9d927aee390de2ab577cf5de2de198e299c66c626d94db65096c3746609dbbb"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.0-aarch64-unknown-linux-gnu"
        sha256 "b1a47049ceee2e7a1d10f57b346d0ee5ed570cb2e9e188be506891cca8fdfda7"
      end
    end

    on_intel do
      url "#{BASE_URL}/loom-0.2.0-x86_64-unknown-linux-gnu"
      sha256 "700d4618c22054a7d4a079c0016156266304027047e0e0a61fc990737e0594e3"

      resource "loomd" do
        url "#{BASE_URL}/loomd-0.2.0-x86_64-unknown-linux-gnu"
        sha256 "46e5ba886325f48ec6c1dc3500e289c4498e88496eb6427ea0af2b6f65a1539e"
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
