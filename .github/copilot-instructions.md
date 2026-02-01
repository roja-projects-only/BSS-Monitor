# Copilot Instructions - BSS Monitor

## Project Overview
A modular Roblox Lua script for **Bee Swarm Simulator** private server monitoring. Scans player hives, checks level requirements, and auto-kicks non-compliant players via chat commands.

**Platform Support:**
- ✅ **Desktop**: Full auto-kick via VirtualInputManager
- ⚠️ **Mobile**: Clipboard + prefill mode (manual send required due to Roblox security)

## Architecture

### Module Structure
```
modules/
├── config.lua    # Configuration, whitelist & mobile settings
├── scanner.lua   # Hive scanning & requirement checking
├── monitor.lua   # Main monitoring loop, state management, ban verification
├── chat.lua      # Chat command sender (platform-aware: desktop auto-send vs mobile clipboard)
├── webhook.lua   # Discord webhook notifications
└── gui.lua       # Minimal GUI (player count, status, draggable)
```

### Entry Points
- `loader.lua` - Loadstring entry, loads modules from GitHub
- `main.lua` - Direct execution entry (for local testing), handles auto-cleanup

### Auto-Cleanup on Re-execution
Script can be re-executed safely. `main.lua` checks for existing `_G.BSSMonitor` and calls `cleanup()` before loading fresh modules.

### Global Variable
Uses `_G.BSSMonitor` for global state. All modules and functions accessible:
```lua
_G.BSSMonitor.start()
_G.BSSMonitor.stop()
_G.BSSMonitor.ban("username")
_G.BSSMonitor.cleanup()  -- For re-execution
```

### Data Flow
```
Scanner.ScanAllHives() → hiveData
    ↓
Monitor.CheckPlayer() → check requirements vs Config
    ↓
(if fails) → Desktop: Chat.SendKickCommand() with verification
             Mobile: Chat.CopyKickCommand() + Chat.PrefillKickCommand()
    ↓
Webhook.SendBanNotification()
    ↓
GUI.UpdateDisplay() → reflect state changes
```

## Platform Detection & Chat

### Mobile Limitation (IMPORTANT)
Roblox's TextChatService has **server-side validation** that detects and blocks programmatically-sent messages on mobile with "Your message could not be sent". This is a Roblox security feature that cannot be bypassed from client-side.

**Tested and confirmed non-working on mobile:**
- VirtualInputManager
- TextChannel:SendAsync()
- firesignal on FocusLost
- ReleaseFocus(true)
- keypress simulation
- All 12+ bypass methods tested

### Chat Module (Platform-Aware)
```lua
-- Desktop: VirtualInputManager (auto-sends)
-- Mobile: Clipboard + Prefill (user presses send)

Chat.IsMobile()             -- Returns true/false
Chat.SendMessage(msg)       -- Platform-aware send
Chat.CopyKickCommand(name)  -- Mobile: clipboard
Chat.PrefillKickCommand(name) -- Mobile: prefill chat input
```

### Mobile Workflow
1. Script detects player failing requirements
2. 📋 Copies `/kick username` to clipboard
3. 💬 Pre-fills the command in chat input
4. 🔔 Plays alert sound
5. 📱 Discord webhook sent with "Manual send required"
6. User just presses SEND

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
-- Try multiple methods for compatibility (Delta, Synapse, etc.)
if request then return request(options)
elseif syn and syn.request then return syn.request(options)
elseif http_request then return http_request(options)
-- ... more fallbacks
```

### Player State Tracking
```lua
Monitor.PlayerJoinTimes = {}   -- For grace period
Monitor.BannedPlayers = {}     -- Already banned (with verification status)
Monitor.CheckedPlayers = {}    -- Passed checks
Monitor.PendingBans = {}       -- Awaiting ban verification
```

### Ban Verification (Desktop)
```lua
-- Retries up to 3 times, waits 10s for player to leave
Monitor.ExecuteBanWithVerification(playerName, reason, maxRetries, timeout)
-- States: verified=true (success), verified=false (failed), mobileMode=true
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
All settings in `modules/config.lua`. Override via `_G.BSSMonitorConfig` before loading:
```lua
_G.BSSMonitorConfig = {
    DRY_RUN = false,
    USE_KICK = true,        -- Use /kick instead of /ban
    MOBILE_CLIPBOARD = true,
    MOBILE_PREFILL = true,
    MOBILE_SOUND = true
}
```

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
Use `Monitor.Log(type, message)` - types: "Ban", "BanVerified", "BanFailed", "Pass", "Skip", "Error", "Start", "Stop", "Info", "Mobile"

## Executor Compatibility
Tested on:
- **Delta** (mobile) - clipboard mode works
- **Seliware** (desktop) - VirtualInputManager works
- Should work on Synapse, Fluxus, etc.

## Testing Notes
- Enable `DRY_RUN = true` to test without kicking
- Use `testChat()` and `testWebhook()` to verify connectivity
- Check Discord webhook URL is set before enabling notifications
- Test files in `tests/` folder (gitignored) for isolated testing

## Tests Folder
`tests/` contains isolated test scripts:
- `test_mobile_chat.lua` - Test chat methods
- `test_bypass.lua` - Test various bypass methods
- `test_globalchat.lua` - Test BSS GlobalChatEvent
- `test_textsource.lua` - Test TextChannel TextSource

