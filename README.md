# 🐝 BSS Monitor

Private server monitoring tool for **Bee Swarm Simulator**. Automatically monitors player hives and kicks/bans players who don't meet the level requirements.

## Features

- 🔍 **Hive Scanning** - Scans all player hives in the server
- 📊 **Level Verification** - Checks if players meet the 80%+ Lv17 requirement
- 🚫 **Auto-Kick/Ban** - Desktop: auto-sends `/kick` or `/ban` via VirtualInputManager
- 📱 **Mobile Support** - Sends Discord webhook with @mention ping and tap-to-copy `/ban` command
- ✅ **Ban Verification** - Confirms player actually leaves server, retries up to 3 times (desktop)
- 🔔 **Discord Webhooks** - Get notifications when players are kicked/banned
- 👑 **Whitelist** - Protect yourself and friends from being checked
- 🖥️ **Optional GUI** - Player list with status indicators
- 🔄 **Auto-Cleanup** - Re-execute script anytime, automatically cleans up previous session
- ✅ **Dry Run Mode** - Test the system without actually kicking anyone

## Installation

### Quick Start (Loadstring)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/roja-projects-only/BSS-Monitor/main/loader.lua"))()
```

### With Custom Configuration

```lua
_G.BSSMonitorConfig = {
    WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL",
    DISCORD_USER_ID = "YOUR_DISCORD_USER_ID",  -- For mobile @mention notifications
    DRY_RUN = false,           -- Set to false to actually kick/ban
    AUTO_START = true,         -- Start monitoring immediately
    USE_KICK = true,           -- Use /kick (true) or /ban (false)
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
| `MIN_BEES_REQUIRED` | 45 | Skip check if player has fewer bees (might be new) |
| `CHECK_INTERVAL` | 30 | Seconds between automatic scans |
| `GRACE_PERIOD` | 20 | Seconds to wait after player joins before checking |
| `BAN_COOLDOWN` | 5 | Seconds between ban commands |
| `MAX_PLAYERS` | 6 | Max players in private server |
| `DRY_RUN` | false | If true, logs but doesn't actually kick/ban |
| `AUTO_START` | true | Start monitoring automatically on load |
| `SHOW_GUI` | true | Show GUI (disabled by default for compatibility) |
| `USE_KICK` | false | Use `/kick` instead of `/ban` (some servers only support kick) |
| `MOBILE_MODE` | nil | nil = auto-detect, true = force mobile, false = force desktop |
| `WEBHOOK_ENABLED` | true | Enable Discord webhook notifications |
| `WEBHOOK_URL` | "" | Your Discord webhook URL |
| `DISCORD_USER_ID` | "" | Your Discord user ID for @mention in mobile ban notifications |

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
m.ban("username")      -- Manually kick/ban a player
m.whitelist("name")    -- Add to whitelist
m.unwhitelist("name")  -- Remove from whitelist

-- GUI
m.showGui()            -- Show the GUI
m.hideGui()            -- Hide the GUI

-- Testing
m.testChat()           -- Test chat functionality
m.testWebhook()        -- Test webhook connection

-- Session
m.cleanup()            -- Manually cleanup and unload the script
```

## Re-execution Support

You can re-execute the script at any time! The monitor automatically:
- Stops the previous monitoring loop
- Destroys the old GUI
- Disconnects all event handlers
- Loads fresh modules

Simply run the loadstring again to reload with updated settings.

## Ban Verification

### Desktop
When a player is kicked/banned, the monitor:
1. Sends the `/kick` or `/ban` command via VirtualInputManager
2. Waits up to 10 seconds to confirm player left
3. If still in server, retries up to 3 times
4. Sends Discord notification on success or failure

### Mobile
Roblox blocks programmatically-sent chat messages on mobile (server-side validation). The monitor uses Discord webhooks instead:
1. Detects player failing requirements
2. Sends Discord webhook with `<@YOUR_USER_ID>` to trigger a push notification
3. Embed includes a `/ban PlayerName` code block — tap to copy on Discord mobile
4. You paste the command into Roblox chat manually

Set `DISCORD_USER_ID` in your config for @mention pings to work.

**GUI Status Indicators:**
- ✅ Green = Verified (player left server)
- ⏳ Orange = Pending verification
- ❌ Red = Failed (player still in server)
- ⚠️ Yellow = Dry run mode

## GUI Features (Optional)

Enable with `SHOW_GUI = true` in config:

- **Player Count** - Shows current players (X/6)
- **Player List** - All players in server with hive status
- **Banned List** - Players that were kicked/banned with verification status
- **Status Indicator** - ACTIVE / PAUSED

**Banned Player Status:**
- ✅ Verified - Player successfully removed
- ⏳ Pending - Waiting for verification
- ❌ Failed - Could not remove player
- ⚠️ Dry Run - Would have been removed

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
3. Get your Discord user ID (enable Developer Mode → right-click your name → Copy User ID)
4. Set both in your config:

```lua
_G.BSSMonitorConfig = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL",
    DISCORD_USER_ID = "123456789012345678",  -- For mobile @mention pings
}
```

## Safety

⚠️ **DRY_RUN mode is enabled by default!**

This means the script will:
- ✅ Scan players and check requirements
- ✅ Log who would be kicked/banned
- ✅ Send webhook notifications (with [DRY RUN] prefix)
- ❌ NOT actually send kick/ban commands

To enable real kicks, set `DRY_RUN = false` in your config.

### Kick vs Ban

By default, `USE_KICK = true` which uses `/kick` instead of `/ban`. This is more reliable on most servers. Set `USE_KICK = false` to use `/ban` if your server supports it.

## File Structure

```
BSS-Monitor/
├── loader.lua          # Loadstring entry point
├── main.lua            # Main orchestrator (with auto-cleanup)
├── modules/
│   ├── config.lua      # Configuration settings
│   ├── scanner.lua     # Hive scanning logic
│   ├── monitor.lua     # Monitoring loop & ban verification
│   ├── chat.lua        # Chat command sender (VirtualInputManager)
│   ├── webhook.lua     # Discord integration
│   └── gui.lua         # User interface
├── tests/              # Test scripts (gitignored)
└── README.md
```

## Requirements

- Roblox script executor (Seliware, Delta, etc.)
- **Desktop**: VirtualInputManager support for auto-sending chat commands
- **Mobile**: Discord webhook with `DISCORD_USER_ID` for ban notifications
- Private server in Bee Swarm Simulator (with kick/ban permissions)
- HTTP requests enabled in executor (for webhooks)

## License

For personal use only. Not affiliated with Bee Swarm Simulator or Roblox.

---

Made with 🐝 by roja-projects-only
