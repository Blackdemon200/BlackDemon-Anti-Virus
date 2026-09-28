#!/usr/bin/env bash
# Build the release binaries, hash them, and sign the SHA256SUMS with the
# OFFLINE Ed25519 key. Run this on the air-gapped signer (the only machine that
# holds assets/keys/feed_private.key). Publish: the binaries + SHA256SUMS +
# SHA256SUMS.sig. Users verify with `blackdemon verifyfile SHA256SUMS`.
set -euo pipefail
cd "$(dirname "$0")/.."

KEY="${BLACKDEMON_KEY:-assets/keys/feed_private.key}"
[ -f "$KEY" ] || { echo "private key not found: $KEY (keep it offline)"; exit 1; }

echo ">> building release (locked deps)"
cargo build --release --locked -p blackdemon-cli

OUT="dist"
mkdir -p "$OUT"
cp target/release/blackdemon "$OUT/"

echo ">> hashing"
( cd "$OUT" && sha256sum blackdemon > SHA256SUMS )

echo ">> signing SHA256SUMS (offline key)"
./target/release/blackdemon signfile "$OUT/SHA256SUMS" --key "$KEY"

echo ">> done. publish these:"
ls -1 "$OUT"/{blackdemon,SHA256SUMS,SHA256SUMS.sig}
