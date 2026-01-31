# Copilot Instructions - BSS Monitor

## Project Overview
A modular Roblox Lua script for **Bee Swarm Simulator** private server monitoring. Scans player hives, checks level requirements, and auto-bans non-compliant players via chat commands.

## Architecture

### Module Structure
```
modules/
├── config.lua    # Configuration & whitelist
├── scanner.lua   # Hive scanning & requirement checking
├── monitor.lua   # Main monitoring loop & state management
├── chat.lua      # Chat command sender (ban commands)
├── webhook.lua   # Discord webhook notifications
└── gui.lua       # Minimal GUI (player count, status, draggable)
```

### Entry Points
- `loader.lua` - Loadstring entry, loads modules from GitHub
- `main.lua` - Direct execution entry (for local testing)

### Global Variable
Uses `_G.BSSMonitor` for global state. All modules and functions accessible:
```lua
_G.BSSMonitor.start()
_G.BSSMonitor.stop()
_G.BSSMonitor.ban("username")
```

### Data Flow
```
Scanner.ScanAllHives() → hiveData
    ↓
Monitor.CheckPlayer() → check requirements vs Config
    ↓
(if fails) → Chat.SendBanCommand() + Webhook.SendBanNotification()
    ↓
GUI.UpdateDisplay() → reflect state changes
```

## Key Patterns

### Module Loading (from GitHub)
```lua
local function loadModule(name)
    local url = REPO_BASE .. "modules/" .. name .. ".lua"
    return loadstring(game:HttpGet(url))()
end
```

### HTTP Requests (executor-agnostic)
```lua
-- Try multiple methods for compatibility
if request then return request(options)
elseif syn and syn.request then return syn.request(options)
elseif http_request then return http_request(options)
-- ... more fallbacks
```

### Player State Tracking
```lua
Monitor.PlayerJoinTimes = {}   -- For grace period
Monitor.BannedPlayers = {}     -- Already banned
Monitor.CheckedPlayers = {}    -- Passed checks
```

### Requirement Checking
```lua
-- Pass if (beesAtOrAboveLevel / totalBees) >= REQUIRED_PERCENT
-- Skip if totalBees < MIN_BEES_REQUIRED
-- Skip if in WHITELIST
-- Skip if in grace period (< GRACE_PERIOD seconds since join)
```

## Code Conventions

### Config is Centralized
All settings in `modules/config.lua`. Override via `getgenv().BSSMonitorConfig` before loading.

### Module Initialization
Modules export tables with functions. Init with dependencies:
```lua
GUI.Init(Config, Monitor)
Monitor.Init(Config, Scanner, Webhook, Chat, GUI)
```

### Color Theme (GUI)
```lua
Colors.Accent = Color3.fromRGB(255, 180, 0)  -- Golden/yellow
Colors.Success = Color3.fromRGB(80, 200, 80)
Colors.Danger = Color3.fromRGB(200, 80, 80)
```

### Logging
Use `Monitor.Log(type, message)` - types: "Ban", "Pass", "Skip", "Error", "Start", "Stop", "Info"

## Testing Notes
- Enable `DRY_RUN = true` to test without banning
- Use `testChat()` and `testWebhook()` to verify connectivity
- Check Discord webhook URL is set before enabling notifications

