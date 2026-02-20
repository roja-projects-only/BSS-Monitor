local GUI = {}
GUI.ScreenGui = nil
GUI.PlayerCountLabel = nil
GUI.StatusLabel = nil
GUI.StatusDot = nil
GUI.PlayerList = nil
GUI.BannedList = nil
GUI.MainFrame = nil
GUI.Content = nil
GUI.Footer = nil
GUI.ToggleButton = nil
GUI.ToggleIcon = nil
GUI.CollapseButton = nil
GUI.TitleCountLabel = nil
GUI.TitleFix = nil
GUI.AccentLine = nil
GUI.LastScanResults = {}
GUI.CheckedPlayers = {}
GUI.IsCollapsed = false
GUI.IsHidden = false
GUI.Connections = {}  -- Store connections for cleanup

local Config = nil
local Monitor = nil
local Chat = nil
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Sizes
local PANEL_WIDTH = 280
local EXPANDED_HEIGHT = 340
local COLLAPSED_HEIGHT = 38
local PADDING = 10
local ENTRY_HEIGHT = 26
local ENTRY_GAP = 3
local BANNED_ENTRY_HEIGHT = 22
local INDICATOR_WIDTH = 3

-- Color palette (refined)
local C = {
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
-- Legacy alias for backward compat
local Colors = {
    bg = C.bg, bgSecondary = C.surface, bgTertiary = C.surfaceHL,
    accent = C.accent, accentDark = C.accentDim,
    text = C.text, textMuted = C.textSec,
    success = C.green, danger = C.red, warning = C.orange, info = C.blue,
}

function GUI.Init(config, monitor, chat)
    Config = config
    Monitor = monitor
    Chat = chat
    return GUI
end

-- Helper to create rounded corners
local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

-- Helper to create stroke
local function addStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or C.accent
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Helper to create shadow
local function addShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.4
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = parent
    return shadow
end

-- Helper to create text label
local function label(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Text = props.text or ""
    l.TextColor3 = props.color or C.text
    l.TextSize = props.size or 12
    l.Font = props.font or Enum.Font.Gotham
    l.TextXAlignment = props.alignX or Enum.TextXAlignment.Left
    l.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
    l.TextTruncate = props.truncate or Enum.TextTruncate.None
    l.Size = props.sizeUDim or UDim2.new(1, 0, 1, 0)
    l.Position = props.pos or UDim2.new(0, 0, 0, 0)
    if props.parent then l.Parent = props.parent end
    return l
end

-- Helper to create section header
local function sectionHeader(parent, text, color, yPos)
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 16)
    hdr.Position = UDim2.new(0, 0, 0, yPos)
    hdr.BackgroundTransparency = 1
    hdr.Parent = parent

    label({
        text = text,
        color = color or C.textDim,
        size = 9,
        font = Enum.Font.GothamBold,
        parent = hdr,
    })

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -#text * 5 - 8, 0, 1)
    line.Position = UDim2.new(0, #text * 5 + 8, 0.5, 0)
    line.BackgroundColor3 = C.surfaceHL
    line.BackgroundTransparency = 0.3
    line.BorderSizePixel = 0
    line.Parent = hdr

    return hdr
end

function GUI.Create()
    -- Clean up previous GUI instance
    pcall(function()
        if GUI.ScreenGui then GUI.ScreenGui:Destroy() end
    end)
    for _, conn in ipairs(GUI.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    GUI.Connections = {}

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSSMonitorGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Toggle button (bottom-right pill)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Toggle"
    toggleBtn.Size = UDim2.new(0, 48, 0, 48)
    toggleBtn.Position = UDim2.new(1, -60, 1, -60)
    toggleBtn.BackgroundColor3 = C.bg
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ""
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = screenGui
    addCorner(toggleBtn, 24)
    addStroke(toggleBtn, C.accent, 2)
    GUI.ToggleButton = toggleBtn

    -- Bee icon inside toggle
    local toggleIcon = Instance.new("TextLabel")
    toggleIcon.Name = "Icon"
    toggleIcon.Size = UDim2.new(1, 0, 1, 0)
    toggleIcon.BackgroundTransparency = 1
    toggleIcon.Text = "🐝"
    toggleIcon.TextSize = 22
    toggleIcon.Font = Enum.Font.SourceSans
    toggleIcon.Parent = toggleBtn
    GUI.ToggleIcon = toggleIcon

    -- Hover effect
    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.surface }):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.bg }):Play()
    end)

    -- Main panel
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, PANEL_WIDTH, 0, EXPANDED_HEIGHT)
    panel.Position = UDim2.new(0, 14, 0.5, -EXPANDED_HEIGHT / 2)
    panel.BackgroundColor3 = C.bg
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = true
    panel.ClipsDescendants = true
    panel.Parent = screenGui
    addCorner(panel, 12)
    addStroke(panel, C.accent, 1.5)
    addShadow(panel)
    GUI.MainFrame = panel

    -- Title bar (38px)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, COLLAPSED_HEIGHT)
    titleBar.BackgroundColor3 = C.surface
    titleBar.BorderSizePixel = 0
    titleBar.Parent = panel

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleFix = Instance.new("Frame")
    titleFix.Name = "Fix"
    titleFix.Size = UDim2.new(1, 0, 0, 14)
    titleFix.Position = UDim2.new(0, 0, 1, -14)
    titleFix.BackgroundColor3 = C.surface
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    GUI.TitleFix = titleFix

    -- Accent line under title bar
    local accentLine = Instance.new("Frame")
    accentLine.Name = "AccentLine"
    accentLine.Size = UDim2.new(1, 0, 0, 1)
    accentLine.Position = UDim2.new(0, 0, 1, 0)
    accentLine.BackgroundColor3 = C.accentDim
    accentLine.BackgroundTransparency = 0.5
    accentLine.BorderSizePixel = 0
    accentLine.Parent = titleBar
    GUI.AccentLine = accentLine

    -- Status dot (green/red circle)
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, PADDING, 0.5, -4)
    statusDot.BackgroundColor3 = C.green
    statusDot.BorderSizePixel = 0
    statusDot.Parent = titleBar
    addCorner(statusDot, 4)
    GUI.StatusDot = statusDot

    -- Title text
    label({
        text = "BSS Monitor",
        color = C.text,
        size = 13,
        font = Enum.Font.GothamBold,
        sizeUDim = UDim2.new(0, 120, 1, 0),
        pos = UDim2.new(0, PADDING + 14, 0, 0),
        parent = titleBar,
    })

    -- Player count pill in title
    local countPill = Instance.new("Frame")
    countPill.Name = "CountPill"
    countPill.Size = UDim2.new(0, 38, 0, 20)
    countPill.Position = UDim2.new(0, PADDING + 138, 0.5, -10)
    countPill.BackgroundColor3 = C.elevated
    countPill.BorderSizePixel = 0
    countPill.Parent = titleBar
    addCorner(countPill, 10)

    local countLabel = label({
        text = #Players:GetPlayers() .. "/" .. (Config and Config.MAX_PLAYERS or 6),
        color = C.accent,
        size = 11,
        font = Enum.Font.GothamBold,
        alignX = Enum.TextXAlignment.Center,
        parent = countPill,
    })
    GUI.TitleCountLabel = countLabel

    -- Collapse button
    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Name = "Collapse"
    collapseBtn.Size = UDim2.new(0, 28, 0, 28)
    collapseBtn.Position = UDim2.new(1, -PADDING - 28, 0.5, -14)
    collapseBtn.BackgroundColor3 = C.elevated
    collapseBtn.BorderSizePixel = 0
    collapseBtn.Text = "v"
    collapseBtn.TextColor3 = C.textSec
    collapseBtn.TextSize = 12
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.AutoButtonColor = true
    collapseBtn.Parent = titleBar
    addCorner(collapseBtn, 6)
    GUI.CollapseButton = collapseBtn

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -PADDING * 2, 1, -(COLLAPSED_HEIGHT + PADDING + 26))
    content.Position = UDim2.new(0, PADDING, 0, COLLAPSED_HEIGHT + 6)
    content.BackgroundTransparency = 1
    content.Parent = panel
    GUI.Content = content

    -- Stats row (two cards side by side)
    local statsRow = Instance.new("Frame")
    statsRow.Name = "Stats"
    statsRow.Size = UDim2.new(1, 0, 0, 50)
    statsRow.BackgroundTransparency = 1
    statsRow.Parent = content

    -- Stat card helper
    local function statCard(xPos, width, valueTxt, valueColor, labelTxt)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(width, -2, 1, 0)
        card.Position = UDim2.new(xPos, xPos > 0 and 2 or 0, 0, 0)
        card.BackgroundColor3 = C.surface
        card.BorderSizePixel = 0
        card.Parent = statsRow
        addCorner(card, 8)
        local val = label({
            text = valueTxt,
            color = valueColor,
            size = 20,
            font = Enum.Font.GothamBold,
            alignX = Enum.TextXAlignment.Center,
            sizeUDim = UDim2.new(1, 0, 0.55, 0),
            pos = UDim2.new(0, 0, 0, 2),
            parent = card,
        })
        label({
            text = labelTxt,
            color = C.textDim,
            size = 9,
            font = Enum.Font.GothamMedium,
            alignX = Enum.TextXAlignment.Center,
            sizeUDim = UDim2.new(1, 0, 0.35, 0),
            pos = UDim2.new(0, 0, 0.58, 0),
            parent = card,
        })
        return card, val
    end

    -- Determine mobile mode (Config.MOBILE_MODE overrides auto-detect)
    local isMobile
    if Config and Config.MOBILE_MODE ~= nil then
        isMobile = Config.MOBILE_MODE
    elseif Chat and Chat.IsMobile then
        isMobile = Chat.IsMobile()
    else
        isMobile = false
    end
    local platformStr = isMobile and "📱" or "🖥️"

    local _, playerCountVal = statCard(0, 0.5, #Players:GetPlayers() .. "/" .. (Config and Config.MAX_PLAYERS or 6), C.accent, "Players")
    GUI.PlayerCountLabel = playerCountVal

    local _, statusVal = statCard(0.5, 0.5, "ACTIVE", C.green, "Status · " .. platformStr)
    GUI.StatusLabel = statusVal

    -- Players section
    local playersY = 56
    sectionHeader(content, "PLAYERS", C.textDim, playersY)

    local playerListBg = Instance.new("Frame")
    playerListBg.Name = "PlayerListBg"
    playerListBg.Size = UDim2.new(1, 0, 0, 112)
    playerListBg.Position = UDim2.new(0, 0, 0, playersY + 18)
    playerListBg.BackgroundColor3 = C.surface
    playerListBg.BorderSizePixel = 0
    playerListBg.ClipsDescendants = true
    playerListBg.Parent = content
    addCorner(playerListBg, 8)

    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Name = "PlayerList"
    playerScroll.Size = UDim2.new(1, -6, 1, -6)
    playerScroll.Position = UDim2.new(0, 3, 0, 3)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 2
    playerScroll.ScrollBarImageColor3 = C.accent
    playerScroll.ScrollBarImageTransparency = 0.4
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    playerScroll.Parent = playerListBg
    GUI.PlayerList = playerScroll

    local playerLayout = Instance.new("UIListLayout")
    playerLayout.SortOrder = Enum.SortOrder.Name
    playerLayout.Padding = UDim.new(0, ENTRY_GAP)
    playerLayout.Parent = playerScroll

    -- Banned section
    local bannedY = playersY + 18 + 112 + 6
    sectionHeader(content, "BANNED", C.red, bannedY)

    local bannedListBg = Instance.new("Frame")
    bannedListBg.Name = "BannedListBg"
    bannedListBg.Size = UDim2.new(1, 0, 0, 72)
    bannedListBg.Position = UDim2.new(0, 0, 0, bannedY + 18)
    bannedListBg.BackgroundColor3 = C.surface
    bannedListBg.BorderSizePixel = 0
    bannedListBg.ClipsDescendants = true
    bannedListBg.Parent = content
    addCorner(bannedListBg, 8)

    local bannedScroll = Instance.new("ScrollingFrame")
    bannedScroll.Name = "BannedList"
    bannedScroll.Size = UDim2.new(1, -6, 1, -6)
    bannedScroll.Position = UDim2.new(0, 3, 0, 3)
    bannedScroll.BackgroundTransparency = 1
    bannedScroll.BorderSizePixel = 0
    bannedScroll.ScrollBarThickness = 2
    bannedScroll.ScrollBarImageColor3 = C.red
    bannedScroll.ScrollBarImageTransparency = 0.4
    bannedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    bannedScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    bannedScroll.Parent = bannedListBg
    GUI.BannedList = bannedScroll

    local bannedLayout = Instance.new("UIListLayout")
    bannedLayout.SortOrder = Enum.SortOrder.Name
    bannedLayout.Padding = UDim.new(0, ENTRY_GAP)
    bannedLayout.Parent = bannedScroll

    -- Footer bar
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 22)
    footer.Position = UDim2.new(0, 0, 1, -22)
    footer.BackgroundColor3 = C.surface
    footer.BorderSizePixel = 0
    footer.Parent = panel
    GUI.Footer = footer

    local footerCorner = Instance.new("UICorner")
    footerCorner.CornerRadius = UDim.new(0, 12)
    footerCorner.Parent = footer

    local footerFix = Instance.new("Frame")
    footerFix.Size = UDim2.new(1, 0, 0, 14)
    footerFix.BackgroundColor3 = C.surface
    footerFix.BorderSizePixel = 0
    footerFix.Parent = footer

    local footerLine = Instance.new("Frame")
    footerLine.Size = UDim2.new(1, -PADDING * 2, 0, 1)
    footerLine.Position = UDim2.new(0, PADDING, 0, 0)
    footerLine.BackgroundColor3 = C.surfaceHL
    footerLine.BackgroundTransparency = 0.3
    footerLine.BorderSizePixel = 0
    footerLine.Parent = footer

    local dryRun = Config and Config.DRY_RUN
    local modeText = dryRun and "DRY RUN" or (isMobile and "MOBILE" or "DESKTOP")
    local modeColor = dryRun and C.orange or C.textDim
    label({
        text = modeText,
        color = modeColor,
        size = 9,
        font = Enum.Font.GothamBold,
        sizeUDim = UDim2.new(0.5, 0, 1, 0),
        pos = UDim2.new(0, PADDING, 0, 0),
        parent = footer,
    })
    label({
        text = "v" .. (Config and Config.VERSION or "?.?.?"),
        color = C.textDim,
        size = 9,
        font = Enum.Font.Gotham,
        alignX = Enum.TextXAlignment.Right,
        sizeUDim = UDim2.new(0.5, -PADDING, 1, 0),
        pos = UDim2.new(0.5, 0, 0, 0),
        parent = footer,
    })

    GUI.ScreenGui = screenGui

    -- Toggle button click handler
    toggleBtn.MouseButton1Click:Connect(function()
        GUI.IsHidden = not GUI.IsHidden
        panel.Visible = not GUI.IsHidden
        toggleIcon.Text = GUI.IsHidden and "🐝" or "X"
        toggleIcon.Font = GUI.IsHidden and Enum.Font.SourceSans or Enum.Font.GothamBold
        toggleIcon.TextSize = GUI.IsHidden and 22 or 18
        toggleIcon.TextColor3 = GUI.IsHidden and C.text or C.red
        local borderColor = GUI.IsHidden and C.accent or C.red
        local s = toggleBtn:FindFirstChildOfClass("UIStroke")
        if s then s.Color = borderColor end
    end)

    -- Collapse button click handler
    collapseBtn.MouseButton1Click:Connect(function()
        GUI.ToggleCollapse()
    end)

    local parented = false
    pcall(function()
        if gethui then screenGui.Parent = gethui() parented = true end
    end)
    if not parented then
        pcall(function() screenGui.Parent = game:GetService("CoreGui") parented = true end)
    end
    if not parented then
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    GUI.UpdatePlayerCount()
    GUI.UpdatePlayerList()

    table.insert(GUI.Connections, Players.PlayerAdded:Connect(function() GUI.UpdatePlayerCount() GUI.UpdatePlayerList() end))
    table.insert(GUI.Connections, Players.PlayerRemoving:Connect(function() task.wait(0.1) GUI.UpdatePlayerCount() GUI.UpdatePlayerList() end))

    return screenGui
end

-- Toggle collapse state with animation
function GUI.ToggleCollapse()
    GUI.IsCollapsed = not GUI.IsCollapsed
    
    local targetHeight = GUI.IsCollapsed and COLLAPSED_HEIGHT or EXPANDED_HEIGHT
    
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(GUI.MainFrame, tweenInfo, {
        Size = UDim2.new(0, PANEL_WIDTH, 0, targetHeight)
    })
    tween:Play()
    
    if GUI.CollapseButton then
        GUI.CollapseButton.Text = GUI.IsCollapsed and ">" or "v"
        GUI.CollapseButton.TextSize = GUI.IsCollapsed and 14 or 12
    end
    
    if GUI.Content then
        GUI.Content.Visible = not GUI.IsCollapsed
    end
    if GUI.Footer then
        GUI.Footer.Visible = not GUI.IsCollapsed
    end
    if GUI.TitleFix then
        GUI.TitleFix.Visible = not GUI.IsCollapsed
    end
    if GUI.AccentLine then
        GUI.AccentLine.Visible = not GUI.IsCollapsed
    end
end

function GUI.UpdatePlayerCount()
    pcall(function()
        local count = #Players:GetPlayers()
        local max = Config and Config.MAX_PLAYERS or 6
        local text = count .. "/" .. max
        if GUI.PlayerCountLabel then
            GUI.PlayerCountLabel.Text = text
        end
        if GUI.TitleCountLabel then
            GUI.TitleCountLabel.Text = text
        end
    end)
end

-- Helper to create a player entry row
local function createPlayerEntry(playerName, hiveData, checkedData)
    local entry = Instance.new("Frame")
    entry.Name = playerName
    entry.Size = UDim2.new(1, -2, 0, ENTRY_HEIGHT)
    entry.BackgroundColor3 = C.surfaceHL
    entry.BorderSizePixel = 0
    addCorner(entry, 5)
    entry.ClipsDescendants = true

    -- Left indicator bar
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, INDICATOR_WIDTH, 1, 0)
    indicator.BackgroundColor3 = C.textDim
    indicator.BorderSizePixel = 0
    indicator.Parent = entry
    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 5)
    indCorner.Parent = indicator
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.55, -INDICATOR_WIDTH - 4, 1, 0)
    nameLabel.Position = UDim2.new(0, INDICATOR_WIDTH + 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = C.text
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = entry
    
    -- Stats (right side)
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0.42, -4, 1, 0)
    statsLabel.Position = UDim2.new(0.58, 0, 0, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "..."
    statsLabel.TextColor3 = C.textSec
    statsLabel.TextSize = 10
    statsLabel.Font = Enum.Font.GothamMedium
    statsLabel.TextXAlignment = Enum.TextXAlignment.Right
    statsLabel.Parent = entry
    
    -- Check if whitelisted
    local isWhitelisted = Config and Config.IsWhitelisted(playerName)
    
    -- Determine colors & stats
    if isWhitelisted then
        if hiveData then
            statsLabel.Text = string.format("Lv%.1f  WL", hiveData.avgLevel or 0)
        else
            statsLabel.Text = "whitelisted"
        end
        statsLabel.TextColor3 = C.blue
        nameLabel.TextColor3 = C.blue
        indicator.BackgroundColor3 = C.blue
        entry.BackgroundColor3 = C.blueBg
    elseif hiveData then
        local avgLvl = hiveData.avgLevel or 0
        local totalBees = hiveData.totalBees or 0
        local pct = 0
        
        if checkedData and checkedData.details and checkedData.details.percentAtLevel then
            pct = checkedData.details.percentAtLevel * 100
        elseif totalBees > 0 and Config then
            local beesAtOrAbove = 0
            for level, count in pairs(hiveData.levelCounts or {}) do
                if level >= (Config.MINIMUM_LEVEL or 15) then
                    beesAtOrAbove = beesAtOrAbove + count
                end
            end
            pct = (beesAtOrAbove / totalBees) * 100
        end
        
        statsLabel.Text = string.format("Lv%.1f  %.0f%%", avgLvl, pct)
        
        local reqPct = Config and (Config.REQUIRED_PERCENT or 0.9) * 100 or 90
        if pct >= reqPct then
            statsLabel.TextColor3 = C.green
            indicator.BackgroundColor3 = C.green
            entry.BackgroundColor3 = C.greenBg
        elseif totalBees < (Config and Config.MIN_BEES_REQUIRED or 35) then
            statsLabel.TextColor3 = C.orange
            indicator.BackgroundColor3 = C.orange
            entry.BackgroundColor3 = C.orangeBg
        else
            statsLabel.TextColor3 = C.red
            indicator.BackgroundColor3 = C.red
            entry.BackgroundColor3 = C.redBg
        end
    else
        statsLabel.Text = "scanning..."
        statsLabel.TextColor3 = C.textDim
        indicator.BackgroundColor3 = C.textDim
    end
    
    return entry
end

function GUI.UpdatePlayerList()
    pcall(function()
        if not GUI.PlayerList then return end
        for _, child in ipairs(GUI.PlayerList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
        
        local localPlayer = Players.LocalPlayer
        local entryCount = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local hiveData = GUI.LastScanResults and GUI.LastScanResults[player.Name]
                local checkedData = GUI.CheckedPlayers and GUI.CheckedPlayers[player.Name]
                local entry = createPlayerEntry(player.Name, hiveData, checkedData)
                entry.Parent = GUI.PlayerList
                entryCount = entryCount + 1
            end
        end
        
        -- Show empty state if no other players
        if entryCount == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Name = "_Empty"
            emptyLabel.Size = UDim2.new(1, 0, 0, ENTRY_HEIGHT)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No other players"
            emptyLabel.TextColor3 = C.textDim
            emptyLabel.TextSize = 11
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.Parent = GUI.PlayerList
            entryCount = 1
        end
        
        -- Update canvas size manually
        GUI.PlayerList.CanvasSize = UDim2.new(0, 0, 0, entryCount * ENTRY_HEIGHT + math.max(0, entryCount - 1) * ENTRY_GAP)
    end)
end

function GUI.UpdateBannedList(bannedPlayers)
    pcall(function()
        if not GUI.BannedList then return end
        for _, child in ipairs(GUI.BannedList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
        
        local bannedCount = 0
        if bannedPlayers then
            for playerName, banData in pairs(bannedPlayers) do
                local entry = Instance.new("Frame")
                entry.Name = playerName
                entry.Size = UDim2.new(1, -2, 0, BANNED_ENTRY_HEIGHT)
                entry.BorderSizePixel = 0
                entry.ClipsDescendants = true
                addCorner(entry, 4)
                
                -- Determine state (text icons instead of emoji)
                local bgColor, textColor, statusIcon, indicatorColor
                if banData.dryRun then
                    bgColor = C.dryRunBg
                    textColor = C.orange
                    indicatorColor = C.orange
                    statusIcon = "!"
                elseif banData.verified then
                    bgColor = C.verifiedBg
                    textColor = C.green
                    indicatorColor = C.green
                    statusIcon = "OK"
                elseif banData.failed then
                    bgColor = C.failedBg
                    textColor = Color3.fromRGB(255, 100, 100)
                    indicatorColor = C.red
                    statusIcon = "F"
                else
                    bgColor = C.pendingBg
                    textColor = C.orange
                    indicatorColor = C.orange
                    statusIcon = "..."
                end
                entry.BackgroundColor3 = bgColor

                -- Left indicator bar
                local ind = Instance.new("Frame")
                ind.Size = UDim2.new(0, INDICATOR_WIDTH, 1, 0)
                ind.BackgroundColor3 = indicatorColor
                ind.BorderSizePixel = 0
                ind.Parent = entry
                local ic = Instance.new("UICorner")
                ic.CornerRadius = UDim.new(0, 4)
                ic.Parent = ind
                
                -- Name
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -INDICATOR_WIDTH - 30, 1, 0)
                nameLabel.Position = UDim2.new(0, INDICATOR_WIDTH + 8, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = playerName
                nameLabel.TextColor3 = textColor
                nameLabel.TextSize = 10
                nameLabel.Font = Enum.Font.GothamMedium
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.Parent = entry
                
                -- Status icon (text)
                local statusLabel = Instance.new("TextLabel")
                statusLabel.Size = UDim2.new(0, 22, 1, 0)
                statusLabel.Position = UDim2.new(1, -24, 0, 0)
                statusLabel.BackgroundTransparency = 1
                statusLabel.Text = statusIcon
                statusLabel.TextColor3 = textColor
                statusLabel.TextSize = 9
                statusLabel.Font = Enum.Font.GothamBold
                statusLabel.TextXAlignment = Enum.TextXAlignment.Center
                statusLabel.Parent = entry
                
                entry.Parent = GUI.BannedList
                bannedCount = bannedCount + 1
            end
        end
        
        if bannedCount == 0 then
            local noneLabel = Instance.new("TextLabel")
            noneLabel.Name = "_None"
            noneLabel.Size = UDim2.new(1, 0, 0, BANNED_ENTRY_HEIGHT)
            noneLabel.BackgroundTransparency = 1
            noneLabel.Text = "None"
            noneLabel.TextColor3 = C.textDim
            noneLabel.TextSize = 10
            noneLabel.Font = Enum.Font.Gotham
            noneLabel.TextXAlignment = Enum.TextXAlignment.Center
            noneLabel.Parent = GUI.BannedList
            bannedCount = 1
        end
        
        -- Update canvas size manually
        GUI.BannedList.CanvasSize = UDim2.new(0, 0, 0, bannedCount * BANNED_ENTRY_HEIGHT + math.max(0, bannedCount - 1) * ENTRY_GAP)
    end)
end

function GUI.UpdateStatus(isRunning)
    pcall(function()
        if GUI.StatusLabel then
            if isRunning then
                GUI.StatusLabel.Text = "ACTIVE"
                GUI.StatusLabel.TextColor3 = C.green
            else
                GUI.StatusLabel.Text = "PAUSED"
                GUI.StatusLabel.TextColor3 = C.red
            end
        end
        if GUI.StatusDot then
            GUI.StatusDot.BackgroundColor3 = isRunning and C.green or C.red
        end
    end)
end

function GUI.UpdateDisplay(scanResults, checkedPlayers, bannedPlayers)
    GUI.LastScanResults = scanResults or {}
    GUI.CheckedPlayers = checkedPlayers or {}
    GUI.UpdatePlayerList()
    GUI.UpdateBannedList(bannedPlayers)
end

function GUI.UpdateLog() end
function GUI.Show() pcall(function() if GUI.ScreenGui then GUI.ScreenGui.Enabled = true end end) end
function GUI.Hide() pcall(function() if GUI.ScreenGui then GUI.ScreenGui.Enabled = false end end) end
function GUI.Toggle() pcall(function() if GUI.ScreenGui then GUI.ScreenGui.Enabled = not GUI.ScreenGui.Enabled end end) end

return GUI
