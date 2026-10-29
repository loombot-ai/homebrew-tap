# Where the artifacts live, and how they got there

> **0.3.x, 2026-10-28 - read this before following anything below.** Everything
> under `v0.1.0/` below is the HISTORICAL procedure for eight per-target bare
> binaries, and 0.3.x does not publish those any more. One release now publishes
> ONE file, the same bundle `install.sh` installs:
>
>     loom-downloads/v0.3.2/loom-bundle-0.3.2.tar.gz   2,126,191 bytes
>     sha256 e197312c47e49809058c5590bace5aee36db97cc6168f6ee9c75fa96fedcd26d
>
> and the check that has to pass, per release, is one line:
>
>     URL=$(sed -n 's/^  url "\(.*\)"$/\1/p' Formula/loom.rb | head -n 1)
>     URL=${URL//\#\{BASE_URL\}/https://downloads.loombot.dev/v0.3.2}
>     curl -sSL "$URL" | shasum -a 256      # the formula's sha256, and nothing else
>
> The per-target names are gone and 404: `/v0.3.2/loom-bundle-0.3.2-x86_64-unknown-linux-gnu.tar.gz`
> -> 404, measured. The bucket, the custom domain and the upload loop below are
> unchanged - only the object names and the count are.

## Published, live, anonymous


Cloudflare R2, bucket `loom-downloads`, nine objects under the `v0.1.0/` key
prefix. Two URLs serve the same bytes:

    https://downloads.loombot.dev/v0.1.0/<name>                        # custom domain
    https://pub-53223debab1f43c1b291993fa3c1a837.r2.dev/v0.1.0/<name> # r2.dev

The custom domain is the one in the formula `BASE_URL`. It is a CNAME on the
`loombot.dev` zone, which is already in the same Cloudflare account, so moving
the bucket later does not change the URL the formula points at.

    loom-downloads/v0.1.0/loom-0.1.0-aarch64-apple-darwin
    loom-downloads/v0.1.0/loom-0.1.0-x86_64-apple-darwin
    loom-downloads/v0.1.0/loom-0.1.0-aarch64-unknown-linux-gnu
    loom-downloads/v0.1.0/loom-0.1.0-x86_64-unknown-linux-gnu
    loom-downloads/v0.1.0/loomd-0.1.0-aarch64-apple-darwin
    loom-downloads/v0.1.0/loomd-0.1.0-x86_64-apple-darwin
    loom-downloads/v0.1.0/loomd-0.1.0-aarch64-unknown-linux-gnu
    loom-downloads/v0.1.0/loomd-0.1.0-x86_64-unknown-linux-gnu
    loom-downloads/v0.1.0/SHA256SUMS

LICENSE and NOTICE were left out: nothing downloads them, and they are in the
repository. `SHA256SUMS` IS up, because the formula sha256 values come from it.

## How it was done, so it can be redone

    npx wrangler r2 bucket create loom-downloads
    npx wrangler r2 bucket dev-url enable loom-downloads
    npx wrangler r2 bucket domain add loom-downloads \
      --domain downloads.loombot.dev \
      --zone-id 9b98a638317c5d9b2836920d244fd94a      # loombot.dev

    gh release download v0.1.0 --repo loombot-ai/loom --dir ./artifacts
    cd ./artifacts && shasum -a 256 -c SHA256SUMS      # all OK
    for f in loom-* loomd-* SHA256SUMS; do
      npx wrangler@latest r2 object put "loom-downloads/v0.1.0/$f" \
        --file "$f" --remote
    done

Two things worth knowing before doing it again. `wrangler r2 object put` failed
with `fetch failed` on three of the eleven attempts, all of them the larger
files, so uploading is not one-shot - verify every object afterwards rather
than trusting the loop exit code. And wrangler outputs on stdout with terminal
escape sequences, so `gh api .../logs` needs `--allow-escape-sequences`.

## The check that has to pass, per artifact

    BASE=https://downloads.loombot.dev/v0.1.0
    for f in loom-0.1.0-aarch64-apple-darwin loom-0.1.0-x86_64-apple-darwin \
             loom-0.1.0-aarch64-unknown-linux-gnu loom-0.1.0-x86_64-unknown-linux-gnu \
             loomd-0.1.0-aarch64-apple-darwin loomd-0.1.0-x86_64-apple-darwin \
             loomd-0.1.0-aarch64-unknown-linux-gnu loomd-0.1.0-x86_64-unknown-linux-gnu \
             SHA256SUMS; do
      printf "%s  %s\n" "$(curl -sS -o /dev/null -w "%{http_code}" -L "$BASE/$f")" "$f"
    done       # every line read 200, 2026-10-10

And that the bytes are the released bytes, not merely present:

    curl -sSL "$BASE/loomd-0.1.0-x86_64-apple-darwin" | shasum -a 256
    grep " loomd-0.1.0-x86_64-apple-darwin$" SHA256SUMS
    # both 5ae97fecebab25108c36da7a150719a4c07deae8b078c8068826d3593c6cf92b

## The fallback that needs no brew

    BASE=https://downloads.loombot.dev/v0.1.0
    T=loom-0.1.0-x86_64-unknown-linux-gnu
    curl -fsSLO "$BASE/$T" && curl -fsSLO "$BASE/SHA256SUMS"
    grep " $T$" SHA256SUMS | shasum -a 256 -c -
    chmod +x "$T" && sudo mv "$T" /usr/local/bin/loom && loom --version

Verified end to end on Ubuntu 24.04.5: checksum OK, `0.1.0` printed.
