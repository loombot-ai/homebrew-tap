# Publishing the v0.1.0 artifacts - both routes, every parameter explicit

Nothing here has been run. No artifacts are hosted yet, so the formula BASE_URL
is still a placeholder and no install can download. Whichever route wins, the
prefix is the only line in the formula that changes.

## The nine files (about 707 MB)

    gh release download v0.1.0 --repo loombot-ai/loom --dir ./artifacts
    cd ./artifacts && shasum -a 256 -c SHA256SUMS    # all OK, 2026-10-10

## Route A - Cloudflare R2 (free egress), the owner first choice

BLOCKED: R2 is not enabled on the account. `wrangler r2 bucket list` answers
"Please enable R2 through the Cloudflare Dashboard. [code: 10042]" - the
product is switched off, which is neither a login nor a scope problem. The
wrangler session is fine (OAuth, account fa8c9e5e3648e795860ff4fafe976aa4) and
its token carries no r2 scope either.

    npx wrangler r2 bucket create <BUCKET>
    for f in artifacts/loom-* artifacts/loomd-* artifacts/SHA256SUMS; do
      npx wrangler r2 object put "<BUCKET>/v0.1.0/$(basename $f)" --file "$f"
    done

    # then point the formula at one of:
    #   https://<BUCKET>.<ACCOUNT_ID>.r2.dev/v0.1.0      (public r2.dev url)
    #   https://downloads.loombot.dev/v0.1.0             (CNAME on the same zone)
    # the second needs no formula edit at all.

## Route B - S3

NOT blocked on permissions. The IAM user in this shell (`ruby`, account
093594090567) has AdministratorAccess and AmazonS3FullAccess, and the account
has no account-level public-access block (GetPublicAccessBlock returns
NoSuchPublicAccessBlockConfiguration). An empty bucket named loom-releases was
created during probing and deleted again - nothing is left behind.

    aws s3api create-bucket --bucket <BUCKET> --region us-east-1
    aws s3api put-public-access-block --bucket <BUCKET> \
      --public-access-block-configuration \
      "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
    aws s3api put-bucket-policy --bucket <BUCKET> --policy file://policy.json
    aws s3 cp artifacts/ s3://<BUCKET>/v0.1.0/ --recursive --exclude "*" \
      --include "loom-*" --include "loomd-*" --include "SHA256SUMS"

policy.json - public READ only, never write:

    {"Version":"2012-10-17","Statement":[{"Sid":"PublicRead","Effect":"Allow",
      "Principal":"*","Action":"s3:GetObject",
      "Resource":"arn:aws:s3:::<BUCKET>/*"}]}

    # then BASE_URL = "https://<BUCKET>.s3.us-east-1.amazonaws.com/v0.1.0"

## Route C - a public artifacts-only repo (no cloud account at all)

Source stays closed: binaries and SHA256SUMS, nothing else. Note that
`loombot/releases` is NOT creatable with this shell credentials - see
BLOCKERS.md. Under an org this shell administers:

    gh repo create <OWNER>/releases --public
    gh release create v0.1.0 --repo <OWNER>/releases artifacts/*
    # then BASE_URL = "https://github.com/<OWNER>/releases/download/v0.1.0"

## The anonymous check, whichever route wins

    BASE=<the prefix>; for f in loom-0.1.0-aarch64-apple-darwin \
      loom-0.1.0-x86_64-apple-darwin loom-0.1.0-aarch64-unknown-linux-gnu \
      loom-0.1.0-x86_64-unknown-linux-gnu SHA256SUMS; do
      printf "%s %s\n" "$(curl -sS -o /dev/null -w "%{http_code}" -L "$BASE/$f")" "$f"
    done     # every line must read 200

## Linux, once the artifacts are up

`brew install` on ubuntu-latest and ubuntu-24.04-arm is part of the CI guard
and turns itself on when the prefix serves 200. Until then the Linux leg is
UNVERIFIED - there is no container runtime on this machine.

Fallback that needs no brew, per artifact:

    BASE=<the prefix>; T=loom-0.1.0-x86_64-unknown-linux-gnu
    curl -fsSLO "$BASE/$T" && curl -fsSLO "$BASE/SHA256SUMS"
    grep " $T$" SHA256SUMS | shasum -a 256 -c -
    chmod +x "$T" && sudo mv "$T" /usr/local/bin/loom && loom --version
