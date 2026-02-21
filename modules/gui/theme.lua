--[[
    BSS Monitor - GUI Theme
    Color palette, layout sizes, and visual constants
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Theme = {}

-- Layout sizes
Theme.PANEL_WIDTH = 280
Theme.EXPANDED_HEIGHT = 340
Theme.COLLAPSED_HEIGHT = 38
Theme.PADDING = 10
Theme.ENTRY_HEIGHT = 26
Theme.ENTRY_GAP = 3
Theme.BANNED_ENTRY_HEIGHT = 22
Theme.INDICATOR_WIDTH = 3

-- Color palette
Theme.C = {
    -- Backgrounds
    bg        = Color3.fromRGB(16, 16, 20),
    surface   = Color3.fromRGB(24, 24, 30),
    surfaceHL = Color3.fromRGB(32, 32, 40),
    elevated  = Color3.fromRGB(40, 40, 50),
    -- Accent
    accent    = Color3.fromRGB(255, 193, 7),
    accentDim = Color3.fromRGB(180, 135, 5),
    -- Text
    text      = Color3.fromRGB(240, 240, 245),
    textSec   = Color3.fromRGB(150, 150, 165),
    textDim   = Color3.fromRGB(100, 100, 115),
    -- Status
    green     = Color3.fromRGB(72, 199, 116),
    red       = Color3.fromRGB(237, 66, 69),
    orange    = Color3.fromRGB(245, 166, 35),
    blue      = Color3.fromRGB(88, 101, 242),
    blueDim   = Color3.fromRGB(55, 65, 145),
    -- Subtle tints (entry backgrounds)
    greenBg   = Color3.fromRGB(22, 35, 28),
    redBg     = Color3.fromRGB(38, 22, 22),
    orangeBg  = Color3.fromRGB(38, 33, 18),
    blueBg    = Color3.fromRGB(20, 25, 45),
    verifiedBg = Color3.fromRGB(22, 38, 22),
    failedBg  = Color3.fromRGB(50, 20, 20),
    pendingBg = Color3.fromRGB(40, 35, 18),
    dryRunBg  = Color3.fromRGB(40, 40, 22),
}

return Theme
