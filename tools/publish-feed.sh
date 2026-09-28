#!/usr/bin/env bash
# Build, sign, and stage the daily feed clients auto-pull.
#
# Run this on the OFFLINE signer (the only machine with the private key) after
# refreshing intel (abuse.ch ingestion + the analysis worker). It:
#   1. exports the current intel store as an unsigned feed (version = now),
#   2. signs it with the offline Ed25519 key (embeds the signature),
#   3. stages dist-feed/blackdemon.json -> upload that to your update.url.
#
# Clients verify the signature + reject rollbacks (apply_signed), so the file is
# safe to serve from any CDN, even over plain HTTP.
set -euo pipefail
cd "$(dirname "$0")/.."

KEY="${BLACKDEMON_KEY:-assets/keys/feed_private.key}"
STORE="${BLACKDEMON_STORE:-assets/models/intel.json}"
BLACKDEMON="${BLACKDEMON_BIN:-target/release/blackdemon}"
OUT="dist-feed"

[ -f "$KEY" ]   || { echo "private key not found: $KEY (keep it offline)"; exit 1; }
[ -x "$BLACKDEMON" ] || BLACKDEMON="target/debug/blackdemon"
[ -x "$BLACKDEMON" ] || { echo "build first: cargo build --release -p blackdemon-cli"; exit 1; }

mkdir -p "$OUT"
# Reuse the run's version if set (so the full file's version == the store version
# == the IOC stamps, which the server's delta endpoint relies on).
VER="${FEED_VERSION:-$(date +%s)}"

echo ">> exporting feed v$VER from $STORE"
"$BLACKDEMON" intel export-feed --store "$STORE" -o "$OUT/blackdemon.unsigned.json" --feed-version "$VER"

echo ">> signing (offline key)"
"$BLACKDEMON" feedsign "$OUT/blackdemon.unsigned.json" "$OUT/blackdemon.json" --key "$KEY"

echo ">> verifying our own output"
"$BLACKDEMON" feedverify "$OUT/blackdemon.json"

echo ">> publish this file to your update.url:"
ls -lh "$OUT/blackdemon.json"
