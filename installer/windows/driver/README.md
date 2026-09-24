# BlackDemon AV Windows minifilter (kernel-level real-time)

This is the **blueprint/scaffold** for true pre-execution blocking on Windows -
the equivalent of Linux `fanotify` (`aether protect`). It is a file-system
**minifilter**: it intercepts every file open/execute (`IRP_MJ_CREATE`), asks the
user-mode BlackDemon AV service to scan the file, and **denies the open** when the
verdict is malicious - before the code can run.

## Architecture
```
kernel: BlackDemon AV.sys (this minifilter)  <-- FltSendMessage -->  user mode: BlackDemon AV service (aether-core scanner)
            IRP_MJ_CREATE pre-op                                    scans bytes, returns allow/deny
```
- `BlackDemon AV.c`  - the minifilter (pre-create callback + communication port).
- `BlackDemon AV.inf` - install/altitude/service registration (load group "FSFilter Anti-Virus").
- User-mode side: a small Windows service that opens `\BlackDemon AVPort` and answers
  scan requests using the existing engine (reuse `aether-core`).

## Build (Windows only)
1. Install **Visual Studio + the Windows Driver Kit (WDK)**.
2. Create a "Kernel Mode Driver (KMDF/empty)" project, add `BlackDemon AV.c` + `BlackDemon AV.inf`.
3. Build `BlackDemon AV.sys` (x64).

## Signing (required to load on modern Windows)
Kernel drivers need more than Authenticode:
1. An **EV code-signing certificate**.
2. Register on the **Microsoft Partner Center** and submit the driver for
   **attestation signing** (or full WHQL). Without this, 64-bit Windows refuses
   to load the driver (except in test-signing mode).

## Why it is not built here
It requires the WDK + a Windows kernel toolchain (cannot compile on Linux) and a
signed driver to load. Until then, BlackDemon AV's Windows real-time protection runs
in **user mode** (the on-access watcher auto-started by the installer), which
detects + quarantines on file change but does not block pre-execution. This
minifilter is the upgrade path to kernel-level blocking.

## Run the user-mode service (`aether-rtsvc`)
Build (on Windows): `cargo build --release` inside `rtsvc/` -> `aether-rtsvc.exe`.
Register + start as an auto-start Windows Service (run elevated):
```cmd
sc create BlackDemon AVRealtime binPath= "C:\Program Files\BlackDemon AV\aether-rtsvc.exe" start= auto
sc description BlackDemon AVRealtime "BlackDemon AV real-time on-access scanning"
sc start BlackDemon AVRealtime
```
Debug in the foreground: `aether-rtsvc.exe --console`.

Note: the service needs `BlackDemon AV.sys` loaded to connect to `\BlackDemon AVPort`.
Until the signed driver is deployed, the installer's Real-Time component uses the
user-mode on-access watcher (`aether watch`) instead, which works without a driver.

