# Copilot Instructions - BSS Monitor

## Project Overview
A modular Roblox Lua script for **Bee Swarm Simulator** private server monitoring. Scans player hives, checks level requirements, and auto-kicks non-compliant players via chat commands.

**Platform Support:**
- ✅ **Desktop**: Full auto-ban via VirtualInputManager, retries up to 3x
- ✅ **Mobile**: Tries VirtualInputManager first (3s check), falls back to Discord webhook with @mention + tap-to-copy `/ban`

## Architecture

### Module Structure
```
modules/
├── config.lua          # Configuration, whitelist, mobile & Discord notification settings
├── logger.lua          # Centralized logging with level-based console filtering & in-memory buffer
├── scanner.lua         # Hive scanning, bee level/gifted detection, requirement checking
├── chat.lua            # Chat command sender (VirtualInputManager), command queue with 1s delay
├── monitor/
│   ├── state.lua       # Shared state tables & utility functions (delegates logging to Logger)
│   ├── ban.lua         # Ban execution, verification, player checking & manual bans
│   ├── cycle.lua       # Scan cycle, scan timeout kicks, start/stop/toggle, status
│   └── init.lua        # Monitor orchestrator: inits sub-modules, player event connections, unified API
├── webhook/
│   ├── http.lua        # HTTP request abstraction (multi-executor), Discord colors, base Send function
│   ├── embeds.lua      # Discord embed builders for all notification types
│   └── init.lua        # Webhook orchestrator: merges Http + Embeds into unified API
└── gui/
    ├── theme.lua       # Color palette (Theme.C table) & layout size constants
    ├── helpers.lua     # UI primitives: addCorner, addStroke, addShadow, label, sectionHeader
    ├── components.lua  # UI component builders: toggle button, title bar, player/banned entries, footer
    └── init.lua        # GUI orchestrator: Create(), Update*(), collapse, drag, live refresh timer
```

### Entry Points
- `loader.lua` - Loadstring entry, loads all modules from GitHub with cache-busting (`?v=os.time()`). Loads sub-modules individually (e.g. `loadModule("gui/theme")`, `loadModule("monitor/state")`). GUI creation gated by `Config.SHOW_GUI`.
- `main.lua` - Direct execution entry (for local testing). Always creates GUI, handles auto-cleanup of previous sessions, stores `_connections` for cleanup.

### Module Loading Order (loader.lua)
1. Logger (standalone, no deps)
2. Config (standalone)
3. Scanner (standalone)
4. Chat (standalone)
5. Monitor sub-modules: state → ban → cycle → init
6. Webhook sub-modules: http → embeds → init
7. GUI sub-modules: theme → helpers → components → init
8. Initialization chain (see below)

### Initialization Chain
```lua
Logger.Init(Config)
MonitorState.Init(Logger)
Chat.Init(Config)
WebhookEmbeds.Init(WebhookHttp)
Webhook.Init(WebhookHttp, WebhookEmbeds)
GUIHelpers.Init(GUITheme)
GUIComponents.Init(GUITheme, GUIHelpers, Config, Monitor, Chat)
GUI.Init(Config, Monitor, Chat, GUITheme, GUIHelpers, GUIComponents)
Monitor.Init(Config, Scanner, Webhook, Chat, GUI, MonitorState, MonitorBan, MonitorCycle)
  └→ Ban.Init(State, Config, Scanner, Webhook, Chat, GUI)
  └→ Cycle.Init(State, Ban, Config, Scanner, Webhook, GUI, Chat)
```

**Key constraint:** Each module is loaded via `loadstring(game:HttpGet(url))()` individually. Sub-modules cannot `require()` each other — all dependencies are injected via `Init()` functions.

### Auto-Cleanup on Re-execution
Script can be re-executed safely. `main.lua` checks for existing `_G.BSSMonitor` and:
1. Stops monitoring via `Monitor.Stop()`
2. Destroys GUI via `GUI.ScreenGui:Destroy()`
3. Disconnects stored `_connections` (PlayerAdded/PlayerRemoving)
4. Clears `_G.BSSMonitor = nil`

### Global Variable
Uses `_G.BSSMonitor` for global state. All modules and convenience functions accessible:
```lua
-- Core
_G.BSSMonitor.start()                -- Start monitoring loop
_G.BSSMonitor.stop()                 -- Stop monitoring loop
_G.BSSMonitor.toggle()               -- Toggle monitoring on/off
_G.BSSMonitor.scan()                 -- Run single scan cycle
_G.BSSMonitor.status()               -- Get status table (running, counts)
_G.BSSMonitor.ban("username")        -- Manual ban
_G.BSSMonitor.cleanup()              -- Full cleanup (main.lua only)

-- Whitelist
_G.BSSMonitor.whitelist("username")    -- Add to whitelist
_G.BSSMonitor.unwhitelist("username")  -- Remove from whitelist

-- GUI
_G.BSSMonitor.showGui()
_G.BSSMonitor.hideGui()

-- Testing
_G.BSSMonitor.testChat()              -- Send test chat message
_G.BSSMonitor.testWebhook()           -- Send test webhook

-- Direct module access
_G.BSSMonitor.Config, .Scanner, .Webhook, .Chat, .GUI, .Monitor
```

### Data Flow
```
Scanner.ScanAllHives() → {playerName: hiveData}
    ↓
Cycle.RunCycle() → for each player:
    Ban.CheckPlayer() → check whitelist → grace period → requirements vs Config
    ↓
  (if fails) → Ban.ExecuteWithVerification():
      1. Try VirtualInputManager /kick or /ban (both platforms)
      2. Wait for player to leave (3s mobile / 10s desktop)
      3. Desktop: retry up to 3x if still in server
      4. Mobile: fall back to Webhook.SendMobileBanNotification() with @mention + tap-to-copy
      5. On success: Webhook.SendBanNotification() (standard notification)
    ↓
  Scan timeout check → players with no hive data after GRACE_PERIOD + SCAN_TIMEOUT → /kick
    ↓
GUI.UpdateDisplay() → player list + banned list with status indicators
```

### Scan Timeout
After each scan cycle, `Cycle.RunCycle()` checks all non-whitelisted players. If a player has been in the server for `GRACE_PERIOD + SCAN_TIMEOUT` seconds (default 20+90=110s) and still has no entry in `LastScanResults` (no hive data found), they are kicked via `/kick` (always kick, never ban). A Discord webhook is sent with details. Tracked via `BannedPlayers[name].scanTimeout = true`.

## Platform Detection & Chat

### VirtualInputManager (Both Platforms)
VirtualInputManager now works on both desktop and mobile for sending chat commands. The chat module always attempts VIM first. If the ban doesn't take effect on mobile (player still in server after 3s), the monitor falls back to sending a Discord webhook notification.

### Chat Module
Platform detection uses 6 signals: TouchEnabled/KeyboardEnabled, IsTenFootInterface, viewport size, MouseEnabled, GyroscopeEnabled, GamepadEnabled. Re-checks 1s after load. **Config.MOBILE_MODE is the single source of truth** — when set to true/false it overrides auto-detection in all modules.

Chat input found via: `CoreGui.ExperienceChat` → descendant TextBox named "TextBox"

```lua
Chat.Init(Config)              -- Initialize with config (MUST be called before use)
Chat.IsMobile()                -- Returns true/false (checks Config.MOBILE_MODE first, then auto-detect)
Chat.GetPlatform()             -- Returns "Mobile" or "Desktop"
Chat.IsAvailable()             -- Check if chat input exists
Chat.SendMessage(msg)          -- Send via VirtualInputManager
Chat.SendKickCommand(name)     -- Send "/kick name"
Chat.SendBanCommand(name)      -- Send "/ban name"
Chat.SendTestMessage()         -- Send test message
```

### Mobile Fallback Workflow
When VIM ban doesn't remove the player on mobile (checked after 3s):

1. `Webhook.SendMobileBanNotification()` sends Discord embed with:
   - `<@DISCORD_USER_ID>` content field → triggers mobile push notification
   - Title: "🚫 Player Needs Ban"
   - Code block with `/ban PlayerName` → tap to copy on Discord mobile
   - Full hive stats (total bees, avg level, % at required level, gifted count)
2. Re-sends every `MOBILE_RENOTIFY_INTERVAL` seconds (default 300 = 5 min) while player is still in server
3. When player eventually leaves, marks as verified + sends confirmation webhook

### Webhook Notification Types
```lua
Webhook.Send(config, embeds, content)  -- Base send (content = text outside embed for @mentions)
Webhook.SendBanNotification(config, player, hiveData, checkResult)       -- Standard ban notification
Webhook.SendMobileBanNotification(config, player, hiveData, checkResult) -- Mobile: @mention + tap-to-copy
Webhook.SendStartNotification(config)          -- Monitor started
Webhook.SendStopNotification(config)           -- Monitor stopped
Webhook.SendPlayerJoinNotification(config, player, count, max)           -- Player joined
Webhook.SendPlayerLeaveNotification(config, player, count, max)          -- Player left (non-ban)
Webhook.SendBanFailedNotification(config, player, reason, attempts)      -- Ban verification failed
Webhook.SendBanVerifiedNotification(config, player, reason, attempts)    -- Ban verified
```

**Discord @mention design:** The `content` field (outside embed) with `<@USER_ID>` is required for mobile push notification pings. Mentions inside embeds do NOT trigger Discord mobile push notifications.

## Key Patterns

### Module Loading (from GitHub)
```lua
-- loader.lua: with cache busting
local url = REPO_BASE .. "modules/" .. name .. ".lua" .. "?v=" .. tostring(os.time())
return loadstring(game:HttpGet(url))()

-- main.lua: no cache busting
local url = REPO_BASE .. "modules/" .. name .. ".lua"
return loadstring(game:HttpGet(url))()
```

### HTTP Requests (executor-agnostic)
```lua
-- webhook.lua: fallback chain
if request then return request(options)
elseif http_request then return http_request(options)
elseif syn and syn.request then return syn.request(options)
elseif http and http.request then return http.request(options)
elseif fluxus and fluxus.request then return fluxus.request(options)
```

### Player State Tracking
```lua
-- In monitor/state.lua (shared state):
State.IsRunning = false            -- Monitoring loop active
State.PlayerJoinTimes = {}         -- {playerName: tick()} for grace period
State.BannedPlayers = {}           -- {playerName: {time, reason, verified, attempts, dryRun, mobileMode, webhookNotified, scanTimeout, ...}}
State.CheckedPlayers = {}          -- {playerName: {passed, reason, details}} players that passed checks
State.PendingBans = {}             -- {playerName: {startTime, reason, attempts, verified}} awaiting verification
State.LastScanResults = {}         -- Last ScanAllHives() results
State.Connections = {}             -- RBXScriptConnections for cleanup

-- Logger buffer (in logger.lua):
Logger.Buffer = {}                 -- In-memory log entries (max 100, newest first)
```

### Ban Verification (Unified)
```lua
-- Both platforms try VirtualInputManager first
-- Mobile: 3s quick check, then webhook fallback. Desktop: 10s, retries up to 3x
Monitor.ExecuteBanWithVerification(playerName, reason, maxRetries, timeout)
-- BannedPlayers states:
--   verified=true                   → player confirmed left
--   verified=false, failed          → desktop: all retries exhausted, player still in server
--   mobileMode=true, webhookNotified → mobile: VIM failed, webhook fallback sent
--   dryRun=true                     → DRY_RUN was active
```

### Requirement Checking
```lua
-- Pass if (beesAtOrAboveLevel / totalBees) >= REQUIRED_PERCENT
-- Skip (pass) if totalBees < MIN_BEES_REQUIRED (might be new player)
-- Skip if in WHITELIST (case-insensitive match)
-- Skip if in grace period (< GRACE_PERIOD seconds since join)
-- Kick (always /kick) if no hive data after GRACE_PERIOD + SCAN_TIMEOUT seconds
```

### Scanner Detection Methods
The scanner uses multiple fallback methods to extract data from honeycomb cells:

**Level extraction** (in priority order):
1. Named values: "BeeLvl", "BeeLevel", "Level", "Lvl", "CellLevel"
2. All IntValue/NumberValue children with level-like names
3. TextLabel descendants containing numbers (1-25)
4. Backplate descendant TextLabels

**Gifted detection** (in priority order):
1. BoolValue: "Gifted", "IsGifted", "CellGifted"
2. Backplate material: Neon or ForceField
3. ParticleEmitter with gifted/sparkle/star in name
4. Child parts with "star" or "gifted" in name

**Hive data structure:**
```lua
{
    playerName, playerId, totalBees, unlockedSlots,
    bees = {{type, cellType, level, gifted, x, y}, ...},
    levelSum, avgLevel, giftedCount,
    levelCounts = {[level] = count},
    grid = {[x][y] = beeInfo}  -- 5x10 grid
}
```

## Code Conventions

### Config is Centralized
All settings in `modules/config.lua`. Override via `_G.BSSMonitorConfig` before loading:
```lua
_G.BSSMonitorConfig = {
    -- Requirements
    MINIMUM_LEVEL = 17,         -- Min bee level to count
    REQUIRED_PERCENT = 0.80,    -- 80% must be at level
    MIN_BEES_REQUIRED = 35,     -- Skip if fewer bees

    -- Timing
    CHECK_INTERVAL = 30,        -- Seconds between scans
    GRACE_PERIOD = 20,          -- Seconds before first check
    SCAN_TIMEOUT = 90,          -- Seconds after grace before kicking (no hive data)
    BAN_COOLDOWN = 5,           -- Seconds between ban commands

    -- Behavior
    DRY_RUN = false,            -- Log-only mode
    AUTO_START = true,          -- Start on load
    SHOW_GUI = false,           -- Headless mode (loader.lua only)
    USE_KICK = true,            -- /kick vs /ban
    MAX_PLAYERS = 6,            -- Private server max

    -- Mobile
    MOBILE_MODE = nil,              -- nil=auto, true=force mobile, false=force desktop

    -- Discord Notification
    DISCORD_USER_ID = "",       -- Discord user ID for @mention in ban notifications

    -- Webhook
    WEBHOOK_ENABLED = true,
    WEBHOOK_URL = "",
}
```

**Config helper functions:**
```lua
Config.IsWhitelisted(username)        -- Case-insensitive check
Config.AddToWhitelist(username)       -- Returns true if added
Config.RemoveFromWhitelist(username)  -- Returns true if removed
```

**Hive grid constants:** `HIVE_SIZE_X = 5`, `HIVE_SIZE_Y = 10`, `MAX_SLOTS = 50`

### Module Initialization
Modules export tables with functions. Init with dependencies:
```lua
Logger.Init(Config)
MonitorState.Init(Logger)
Chat.Init(Config)
WebhookEmbeds.Init(WebhookHttp)
Webhook.Init(WebhookHttp, WebhookEmbeds)
GUIHelpers.Init(GUITheme)
GUIComponents.Init(GUITheme, GUIHelpers, Config, Monitor, Chat)
GUI.Init(Config, Monitor, Chat, GUITheme, GUIHelpers, GUIComponents)
Monitor.Init(Config, Scanner, Webhook, Chat, GUI, MonitorState, MonitorBan, MonitorCycle)
```

### GUI Details
Collapsible panel with dark theme, positioned on left side of screen. Key features:
- **Toggle button**: Bee emoji (🐝) in bottom-right corner, shows/hides main panel
- **Title bar**: Golden accent, "BSS Monitor" with player count, collapse arrow. Drag restricted to title bar only.
- **Stats row**: Player count (X/6) + status indicator (ACTIVE/PAUSED) with platform emoji
- **Player list**: Per-player entries showing name, avg level, percentage at required level. Color-coded: green (pass), red (fail), orange (grace/too few bees), blue (whitelisted/scanning)
- **Scanning state**: Displays "SCANNING" (no dots) in blue while hive data is loading
- **Grace period**: Shows "⏳ Xs" countdown. Live refresh timer extends 2s past grace end to avoid hang at "1s"
- **Banned list**: Status indicators per player: ✅ verified, ❌ failed, ⚠️ dry run, ⏳ pending
- **Footer**: Mode label (DRY RUN / MOBILE / DESKTOP) + version
- **Draggable**: Custom drag on title bar only (not full panel)
- **Collapse animation**: TweenService, Quart easing, 0.2s

**GUI parent priority:** `gethui()` → `CoreGui` → `PlayerGui`

### Color Theme (GUI)
Defined in `gui/theme.lua` as `Theme.C`:
```lua
Theme.C = {
    bg        = Color3.fromRGB(16, 16, 20),       -- Dark background
    surface   = Color3.fromRGB(24, 24, 30),
    surfaceHL = Color3.fromRGB(32, 32, 40),
    elevated  = Color3.fromRGB(40, 40, 50),
    accent    = Color3.fromRGB(255, 193, 7),       -- Golden/amber
    accentDim = Color3.fromRGB(180, 135, 5),
    text      = Color3.fromRGB(240, 240, 245),
    textSec   = Color3.fromRGB(150, 150, 165),
    textDim   = Color3.fromRGB(100, 100, 115),
    green     = Color3.fromRGB(72, 199, 116),
    red       = Color3.fromRGB(237, 66, 69),
    orange    = Color3.fromRGB(245, 166, 35),
    blue      = Color3.fromRGB(88, 101, 242),
    -- Subtle tint backgrounds for entries
    greenBg, redBg, orangeBg, blueBg, verifiedBg, failedBg, pendingBg, dryRunBg
}
```

### Logging
Centralized via `modules/logger.lua`. All logs stored in-memory (`Logger.Buffer`, max 100 entries) regardless of console output level. Console output controlled by `Config.LOG_LEVEL`.

**Log function:** `Logger.Log(actionType, message)` or via shortcuts `Logger.Debug()`, `Logger.Info()`, `Logger.Warn()`, `Logger.Error()`.

**State module delegates:** `State.Log(type, message)` → `Logger.Log(type, message)`

**Action types → levels:**
- **DEBUG (1)**: `Scan`
- **INFO (2)**: `Start`, `Stop`, `Info`, `Pass`, `Skip`, `PlayerJoin`, `PlayerLeave`
- **WARN (3)**: `Ban`, `BanVerified`, `Mobile`
- **ERROR (4)**: `BanFailed`, `Error`

**Listeners:** `Logger.OnLog(callback)` — GUI or other modules can register for real-time log notifications.

**Global access:** `_G.BSSMonitorLogger` is set early in loader.lua so modules that load before full init can access the logger.

## Executor Compatibility
Tested on:
- **Delta** (mobile) - VIM auto-ban + webhook fallback
- **Seliware** (desktop) - VirtualInputManager works
- Should work on Synapse, Fluxus, etc.

## Workflow Rules
- **Always commit after each task is completed.** When you finish a task (bug fix, feature, refactor, etc.), stage and commit the changes immediately before moving on to the next task. Use clear, descriptive commit messages summarizing what was done.
- **Use conventional commit prefixes** for automatic semantic versioning:
  - `fix:` → patch bump (1.0.0 → 1.0.1)
  - `feat:` → minor bump (1.0.0 → 1.1.0)
  - `feat!:` or `BREAKING CHANGE` → major bump (1.0.0 → 2.0.0)
  - anything else (`chore:`, `docs:`, etc.) → patch bump
- **Never edit `Config.VERSION` manually.** It is auto-bumped by the CI workflow (`.github/workflows/version-bump.yml`) on every push to main.
- **Commit freely without pulling first.** `git commit` is local and never requires a pull. Only pull before **pushing**: `git pull --rebase; git push`. The CI version-bump workflow pushes a commit back to `main`, so the remote will be ahead after each push.

## Testing Notes
- Enable `DRY_RUN = true` to test without kicking
- Use `testChat()` and `testWebhook()` to verify connectivity
- Check Discord webhook URL is set before enabling notifications
- Set `DISCORD_USER_ID` for mobile @mention push notifications
- Test files in `tests/` folder (gitignored) for isolated testing

## Tests Folder
`tests/` contains isolated test scripts:
- `test_mobile_chat.lua` - Test chat methods
- `test_bypass.lua` - Test various bypass methods
- `test_globalchat.lua` - Test BSS GlobalChatEvent
- `test_textsource.lua` - Test TextChannel TextSource
- `test_gui.lua` - Test GUI creation
- `test_bss_chat.lua` - Test BSS-specific chat
- `test_chat.lua` - General chat tests
- `test_find_chatbar.lua` - Test chat input discovery
- `test_typing.lua` - Test typing simulation
- `test_final_mobile.lua`, `test_mobile_deep.lua` - Deep mobile tests
- `test_isolated.lua`, `test_alternative.lua` - Alternative approach tests

