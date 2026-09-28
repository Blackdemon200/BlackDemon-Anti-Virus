# Client auto-update (always current)

So BlackDemon AV never falls behind, run the signed-feed updater automatically. The
update is safe over any transport because every feed is **Ed25519-signed**: a
forged or rolled-back feed is rejected (see `apply_signed`).

## Option A - systemd timer (recommended, headless/servers)

```bash
sudo install -m755 target/release/blackdemon /usr/local/bin/
sudo mkdir -p /opt/BlackDemon AV && sudo cp -r assets blackdemon.toml /opt/BlackDemon AV/
# set update.url in /opt/BlackDemon AV/blackdemon.toml to your published feed
sudo cp deploy/blackdemon-update.{service,timer} /etc/systemd/system/
sudo systemctl enable --now blackdemon-update.timer
```

Checks hourly (and right after boot); `Persistent=true` catches missed runs.

## Option B - long-running watcher

```bash
blackdemon -c blackdemon.toml update --watch            # uses update.interval_hours
blackdemon update --url https://feeds.example/blackdemon.json --watch --interval 1800
```

## Option C - desktop app

The desktop already auto-refreshes intel on a schedule and shows
**Auto Updates: ON**. Point `update.url` at your feed to also pull the signed
feed.

## Config (`blackdemon.toml`)

```toml
[update]
enabled = true
url = "https://feeds.example.com/blackdemon.json"   # your published SIGNED feed
interval_hours = 1
```

Integrity comes from the signature, not the transport - but use HTTPS anyway for
privacy.

