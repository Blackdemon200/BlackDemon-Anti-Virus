#!/usr/bin/env bash
# Build a Debian/Ubuntu .deb for the BlackDemon AV CLI engine.
#   ./build-deb.sh                 -> dist/BlackDemonAV_<ver>_amd64.deb
#   ARCH=arm64 ./build-deb.sh      -> dist/BlackDemonAV_<ver>_arm64.deb
# ARCH is the Debian arch name (amd64 / arm64); the engine binary must already
# be built for that arch (native runner or cross-compile) at target/release/blackdemon.
set -euo pipefail
cd "$(dirname "$0")/../.."   # repo root

VER="${VER:-2026.1.0}"
ARCH="${ARCH:-amd64}"
BIN="$(ls target/release/blackdemon 2>/dev/null || ls target/debug/blackdemon 2>/dev/null || true)"
[ -n "$BIN" ] || { echo "build the engine first: cargo build --release -p blackdemon-cli"; exit 1; }

STAGE="$(mktemp -d)"
PKG="$STAGE/blackdemonav"
mkdir -p "$PKG/DEBIAN" "$PKG/usr/bin" "$PKG/usr/share/blackdemonav" "$PKG/usr/share/doc/blackdemonav"

install -Dm755 "$BIN" "$PKG/usr/bin/blackdemon"
[ -d assets/signatures ] && cp -r assets/. "$PKG/usr/share/blackdemonav/" || true
cp installer/LICENSE_EULA.txt "$PKG/usr/share/doc/blackdemonav/copyright" 2>/dev/null || true

cat > "$PKG/DEBIAN/control" <<EOF
Package: blackdemonav
Version: ${VER}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: BlackDemon AV <https://github.com/Blackdemon200>
Depends: libc6
Description: BlackDemon AV - open-source antivirus engine
 Modern, open-source antivirus with on-device AI (Aegis-50M), behavioral
 defense, anti-ransomware rollback, a threat-intelligence firewall, web
 protection and tamper-proof signed updates. Local-first and private.
EOF

cat > "$PKG/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
# Grant fanotify/firewall capabilities so real-time works without full root.
if command -v setcap >/dev/null 2>&1; then
  setcap 'cap_sys_admin,cap_net_admin,cap_dac_read_search+ep' /usr/bin/blackdemon 2>/dev/null || true
fi
echo "BlackDemon AV installed. Try: blackdemon scan ~/Downloads"
echo "Enable real-time: sudo blackdemon protect /home --quarantine"
exit 0
EOF
chmod 755 "$PKG/DEBIAN/postinst"

mkdir -p dist
OUT="dist/BlackDemonAV_${VER}_${ARCH}.deb"
fakeroot dpkg-deb --build "$PKG" "$OUT" >/dev/null
rm -rf "$STAGE"
echo "built: $OUT"
dpkg-deb --info "$OUT" | sed -n '1,12p'


