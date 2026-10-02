## What's new in v2026.1.1

### 🔧 Bug Fixes

- **Windows**: Fixed `VCRUNTIME140.dll` / `VCRUNTIME140_1.dll` missing errors on clean Windows installs (VMs, fresh systems, Windows without Visual C++ Redistributable). The installer now **bundles all required Microsoft Visual C++ Runtime DLLs** directly — no manual VC++ Redist installation needed.
- **Windows**: Enabled static CRT linking (`+crt-static`) as an additional safeguard, so both the CLI engine and the desktop app no longer depend on the system VC runtime at all.

---

## Install

Download the installer for your OS and CPU below.

| OS | File | Architectures |
|----|------|---------------|
| 🪟 Windows | `BlackDemonAV-Setup-*.exe` | x86_64 · arm64 |
| 🍎 macOS | `BlackDemon AV-*.pkg` / `BlackDemon AV-*.dmg` | universal (Intel + Apple Silicon) |
| 🐧 Linux | `BlackDemonAV_*.deb` / `BlackDemonAV-linux-*.tar.gz` | x86_64 · aarch64 |

### ⚠️ Unsigned on purpose — needs admin/root, and your OS will warn you

BlackDemon AV is **not** signed with a paid code-signing certificate. That's by design:
a paid cert only proves someone paid a CA — it says nothing about whether the code
is safe. Instead you get a **stronger, auditable trust path**: reproducible builds
plus an **Ed25519-signed `SHA256SUMS`** you can verify yourself. Installing a
real-time security service needs **administrator / root** on any OS.

- **🪟 Windows** — run `BlackDemonAV-Setup-*.exe`. If SmartScreen warns
  (*"Windows protected your PC"*) → **More info → Run anyway**, then approve the
  **administrator (UAC)** prompt.
- **🍎 macOS** — *"unidentified developer"*: **right-click → Open → Open**
  (not double-click), or `xattr -dr com.apple.quarantine <file>`. It asks for your
  password to install the service.
- **🐧 Linux** — needs **`sudo`**: `sudo apt install ./BlackDemonAV_*.deb`
  (or `sudo ./install.sh`).

### ✅ Verify your download (5 seconds, beats any paid cert)

```bash
sha256sum -c SHA256SUMS          # bytes match the published hashes
blackdemon verifyfile SHA256SUMS     # the hash list is Ed25519-signed by us -> TRUSTED
```
