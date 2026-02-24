# BSS Monitor 🐝

Private server monitor for **Bee Swarm Simulator**. Enforces hive level rules (e.g. 80% of bees at level 17+), auto-kicks or bans players who don’t meet them, and notifies you on Discord. Works on desktop and mobile with an in-game settings panel; optional whitelist and dry-run mode.

---

## Quick start

Run this in your executor (e.g. Delta, Seliware):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/loader.lua"))()
```

Monitoring starts automatically. Use the bee icon in the bottom-right to open the main panel; use the gear in that panel to open **Settings** and change options or whitelist.

**First time:** If you set config in the script (see below), it’s saved to `BSS-Monitor/config.json` so the next run uses your saved settings. After that, the file overrides the script so you can edit settings in-game and have them persist.

---

## Config before loading (optional)

You can set options before running the script. Only include what you want to override:

```lua
_G.BSSMonitorConfig = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/...",
    DISCORD_USER_ID = "123456789012345678",  -- For mobile @mention pings
    DRY_RUN = true,        -- true = log only, no kick/ban (good for testing)
    MINIMUM_LEVEL = 17,     -- Bees must be this level to count
    REQUIRED_PERCENT = 0.80,-- 80% of bees must meet the level
    USE_KICK = true,        -- Use /kick (true) or /ban (false)
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/loader.lua"))()
```

Important options:

| Option | What it does |
|--------|----------------|
| `WEBHOOK_URL` | Discord webhook for join/leave/ban notifications. Leave empty to disable. |
| `DISCORD_USER_ID` | Your Discord user ID so mobile ban alerts can @mention you. |
| `DRY_RUN` | `true` = only log who would be kicked, don’t actually kick/ban. |
| `USE_KICK` | `true` = use `/kick`, `false` = use `/ban` (if your server supports it). |
| `MINIMUM_LEVEL` | Minimum bee level that counts (1–23). |
| `REQUIRED_PERCENT` | Fraction of bees that must meet the level (e.g. 0.80 = 80%). |
| `GRACE_PERIOD` | Seconds after join before a player is checked (default 20). |
| `SCAN_TIMEOUT` | Seconds without hive data before kick (default 90). |

Full options (requirements, timing, whitelist, log level, etc.) can be set in the in-game **Settings** panel and are saved to `BSS-Monitor/config.json`.

---

## Whitelist

Whitelisted players are never checked or kicked. Add/remove in **Settings → Whitelist** or at runtime:

```lua
_G.BSSMonitor.whitelist("FriendName")
_G.BSSMonitor.unwhitelist("FriendName")
```

---

## Discord notifications

1. In Discord: Server Settings → Integrations → Webhooks → New webhook. Copy the URL.
2. Enable Developer Mode, then right-click your name → Copy User ID (for mobile @mentions).
3. In BSS Monitor **Settings**, turn on Notifications, paste the Webhook URL and (optionally) your Discord user ID. Save.

If the URL is empty or notifications are off, no Discord messages are sent and nothing related to Discord is logged.

On **mobile**, if the script can’t kick the player itself, it sends a Discord notification with a tap-to-copy `/ban` command so you can run it manually.

---

## Safety and testing

- **DRY_RUN** — When `true`, the script only logs who would be kicked/banned and does not send kick/ban commands. Use this first to confirm behavior.
- **Kick vs ban** – Default is `/kick` (`USE_KICK = true`). Switch to `/ban` in Settings if your server supports it.
- You can re-run the loadstring anytime; the script cleans up the previous session before loading again.

---

## What the script does

- Scans every player’s hive and checks whether enough bees meet your level rule (e.g. 80% at level 17+).
- Players who don’t meet it (and aren’t whitelisted) get a `/kick` or `/ban` sent via chat. The script checks that they actually leave.
- New players get a short grace period before they’re checked; if someone has no hive data for too long (grace + scan timeout), they’re kicked as a timeout.
- On mobile, if the in-game kick doesn’t work, you get a Discord alert with a copy-paste ban command.

---

## Requirements

- Roblox script executor (e.g. Delta, Seliware) with HTTP allowed.
- Bee Swarm Simulator private server where you can use `/kick` or `/ban`.
- For Discord alerts: webhook URL (and optionally your user ID for mobile pings).

---

*BSS Monitor — for personal use. Not affiliated with Bee Swarm Simulator or Roblox.*
