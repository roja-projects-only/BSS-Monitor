# 🐝 BSS Monitor

Private server monitoring tool for **Bee Swarm Simulator**. Automatically monitors player hives and bans players who don't meet the level requirements.

## Features

- 🔍 **Hive Scanning** - Scans all player hives in the server
- 📊 **Level Verification** - Checks if players meet the 80%+ Lv17 requirement
- 🚫 **Auto-Ban** - Automatically sends `/ban <user>` command for non-compliant players
- 🔔 **Discord Webhooks** - Get notifications when players are banned
- 👑 **Whitelist** - Protect yourself and friends from being checked
- 📱 **Optional GUI** - Player list and banned players display (disabled by default)
- ✅ **Dry Run Mode** - Test the system without actually banning anyone

## Installation

### Quick Start (Loadstring)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/loader.lua"))()
```

### With Custom Configuration

```lua
_G.BSSMonitorConfig = {
    WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL",
    DRY_RUN = false,           -- Set to false to actually ban
    AUTO_START = true,         -- Start monitoring immediately
    MINIMUM_LEVEL = 17,        -- Minimum bee level
    REQUIRED_PERCENT = 0.80,   -- 80% of bees must meet level
    GRACE_PERIOD = 120,        -- Seconds before checking new players
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/loader.lua"))()
```

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `MINIMUM_LEVEL` | 17 | Minimum bee level to count as "meeting requirement" |
| `REQUIRED_PERCENT` | 0.80 | Percentage of bees that must meet MINIMUM_LEVEL (0.80 = 80%) |
| `MIN_BEES_REQUIRED` | 35 | Skip check if player has fewer bees (might be new) |
| `CHECK_INTERVAL` | 30 | Seconds between automatic scans |
| `GRACE_PERIOD` | 120 | Seconds to wait after player joins before checking |
| `BAN_COOLDOWN` | 5 | Seconds between ban commands |
| `MAX_PLAYERS` | 6 | Max players in private server |
| `DRY_RUN` | true | If true, logs but doesn't actually ban |
| `AUTO_START` | true | Start monitoring automatically on load |
| `SHOW_GUI` | false | Show GUI (disabled by default for compatibility) |
| `WEBHOOK_ENABLED` | true | Enable Discord webhook notifications |
| `WEBHOOK_URL` | "" | Your Discord webhook URL |

## Commands

Access via `_G.BSSMonitor`:

```lua
local m = _G.BSSMonitor

-- Monitoring
m.start()              -- Start monitoring loop
m.stop()               -- Stop monitoring
m.toggle()             -- Toggle monitoring
m.scan()               -- Run single scan cycle
m.status()             -- Get current status

-- Player Management
m.ban("username")      -- Manually ban a player
m.whitelist("name")    -- Add to whitelist
m.unwhitelist("name")  -- Remove from whitelist

-- GUI
m.showGui()            -- Show the GUI
m.hideGui()            -- Hide the GUI

-- Testing
m.testChat()           -- Test chat functionality
m.testWebhook()        -- Test webhook connection
```

## GUI Features (Optional)

Enable with `SHOW_GUI = true` in config:

- **Player Count** - Shows current players (X/6)
- **Player List** - All players in server
- **Banned List** - Players that were banned
- **Status Indicator** - RUNNING / STOPPED

## Whitelist

By default, only `a210w` is whitelisted. Add more players in `modules/config.lua`:

```lua
Config.WHITELIST = {
    "a210w",          -- Owner
    "FriendName1",
    "FriendName2",
}
```

Or at runtime:
```lua
_G.BSSMonitor.whitelist("FriendName")
```

## Discord Webhook Setup

1. In Discord, go to Server Settings → Integrations → Webhooks
2. Create a new webhook and copy the URL
3. Set the URL in your config:

```lua
_G.BSSMonitorConfig = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"
}
```

## Safety

⚠️ **DRY_RUN mode is enabled by default!**

This means the script will:
- ✅ Scan players and check requirements
- ✅ Log who would be banned
- ✅ Send webhook notifications (with [DRY RUN] prefix)
- ❌ NOT actually send ban commands

To enable real bans, set `DRY_RUN = false` in your config.

## File Structure

```
BSS-Monitor/
├── loader.lua          # Loadstring entry point
├── main.lua            # Main orchestrator
├── modules/
│   ├── config.lua      # Configuration settings
│   ├── scanner.lua     # Hive scanning logic
│   ├── monitor.lua     # Monitoring loop & player tracking
│   ├── chat.lua        # Chat command sender
│   ├── webhook.lua     # Discord integration
│   └── gui.lua         # User interface
└── README.md
```

## Requirements

- Roblox script executor (Synapse, KRNL, Fluxus, etc.)
- Private server in Bee Swarm Simulator (with ban permissions)
- HTTP requests enabled in executor

## License

For personal use only. Not affiliated with Bee Swarm Simulator or Roblox.

---

Made with 🐝 by roja-projects-only
