--[[
    BSS Monitor - GUI Components
    Reusable UI component builders (toggle button, title bar, player entries, footer)
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Components = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Dependencies (set by Init)
local Theme, H, Config, Monitor, Chat

function Components.Init(theme, helpers, config, monitor, chat)
    Theme = theme
    H = helpers
    Config = config
    Monitor = monitor
    Chat = chat
    return Components
end

-- ============================================
-- Toggle Button (floating bee icon)
-- ============================================
function Components.CreateToggleButton(screenGui)
    local C = Theme.C

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Toggle"
    toggleBtn.Size = UDim2.new(0, 48, 0, 48)
    toggleBtn.Position = UDim2.new(1, -60, 1, -60)
    toggleBtn.BackgroundColor3 = C.bg
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ""
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = screenGui
    H.addCorner(toggleBtn, 24)
    H.addStroke(toggleBtn, C.accent, 2)

    local toggleIcon = Instance.new("TextLabel")
    toggleIcon.Name = "Icon"
    toggleIcon.Size = UDim2.new(1, 0, 1, 0)
    toggleIcon.BackgroundTransparency = 1
    toggleIcon.Text = "\xF0\x9F\x90\x9D"
    toggleIcon.TextSize = 22
    toggleIcon.Font = Enum.Font.SourceSans
    toggleIcon.Parent = toggleBtn

    -- Hover effect
    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.surface }):Play()
    end)
    toggleBtn.MouseLeave:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.bg }):Play()
    end)

    return toggleBtn, toggleIcon
end

-- ============================================
-- Title Bar (draggable header with status dot, count pill, collapse button)
-- ============================================
function Components.CreateTitleBar(panel)
    local C = Theme.C
    local PADDING = Theme.PADDING
    local COLLAPSED_HEIGHT = Theme.COLLAPSED_HEIGHT

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, COLLAPSED_HEIGHT)
    titleBar.BackgroundColor3 = C.surface
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = panel

    -- Custom drag: only title bar moves the panel
    local dragging = false
    local dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

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

    -- Accent line under title bar
    local accentLine = Instance.new("Frame")
    accentLine.Name = "AccentLine"
    accentLine.Size = UDim2.new(1, 0, 0, 1)
    accentLine.Position = UDim2.new(0, 0, 1, 0)
    accentLine.BackgroundColor3 = C.accentDim
    accentLine.BackgroundTransparency = 0.5
    accentLine.BorderSizePixel = 0
    accentLine.Parent = titleBar

    -- Status dot
    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, PADDING, 0.5, -4)
    statusDot.BackgroundColor3 = C.green
    statusDot.BorderSizePixel = 0
    statusDot.Parent = titleBar
    H.addCorner(statusDot, 4)

    -- Title text
    H.label({
        text = "BSS Monitor",
        color = C.text,
        size = 13,
        font = Enum.Font.GothamBold,
        sizeUDim = UDim2.new(0, 120, 1, 0),
        pos = UDim2.new(0, PADDING + 14, 0, 0),
        parent = titleBar,
    })

    -- Player count pill
    local countPill = Instance.new("Frame")
    countPill.Name = "CountPill"
    countPill.Size = UDim2.new(0, 38, 0, 20)
    countPill.Position = UDim2.new(0, PADDING + 138, 0.5, -10)
    countPill.BackgroundColor3 = C.elevated
    countPill.BorderSizePixel = 0
    countPill.Parent = titleBar
    H.addCorner(countPill, 10)

    local countLabel = H.label({
        text = #Players:GetPlayers() .. "/" .. (Config and Config.MAX_PLAYERS or 6),
        color = C.accent,
        size = 11,
        font = Enum.Font.GothamBold,
        alignX = Enum.TextXAlignment.Center,
        parent = countPill,
    })

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
    H.addCorner(collapseBtn, 6)

    return {
        TitleBar = titleBar,
        TitleFix = titleFix,
        AccentLine = accentLine,
        StatusDot = statusDot,
        TitleCountLabel = countLabel,
        CollapseButton = collapseBtn,
    }
end

-- ============================================
-- Stats Row (Players count + Status cards)
-- ============================================
function Components.CreateStatsRow(parent)
    local C = Theme.C

    local statsRow = Instance.new("Frame")
    statsRow.Name = "Stats"
    statsRow.Size = UDim2.new(1, 0, 0, 50)
    statsRow.BackgroundTransparency = 1
    statsRow.Parent = parent

    local function statCard(xPos, width, valueTxt, valueColor, labelTxt)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(width, -2, 1, 0)
        card.Position = UDim2.new(xPos, xPos > 0 and 2 or 0, 0, 0)
        card.BackgroundColor3 = C.surface
        card.BorderSizePixel = 0
        card.Parent = statsRow
        H.addCorner(card, 8)
        local val = H.label({
            text = valueTxt,
            color = valueColor,
            size = 20,
            font = Enum.Font.GothamBold,
            alignX = Enum.TextXAlignment.Center,
            sizeUDim = UDim2.new(1, 0, 0.55, 0),
            pos = UDim2.new(0, 0, 0, 2),
            parent = card,
        })
        H.label({
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

    -- Determine mobile mode
    local isMobile
    if Config and Config.MOBILE_MODE ~= nil then
        isMobile = Config.MOBILE_MODE
    elseif Chat and Chat.IsMobile then
        isMobile = Chat.IsMobile()
    else
        isMobile = false
    end
    local platformStr = isMobile and "\xF0\x9F\x93\xB1" or "\xF0\x9F\x96\xA5\xEF\xB8\x8F"

    local playerText = #Players:GetPlayers() .. "/" .. (Config and Config.MAX_PLAYERS or 6)
    local _, playerCountVal = statCard(0, 0.5, playerText, C.accent, "Players")
    local _, statusVal = statCard(0.5, 0.5, "ACTIVE", C.green, "Status \xC2\xB7 " .. platformStr)

    return {
        PlayerCountLabel = playerCountVal,
        StatusLabel = statusVal,
        isMobile = isMobile,
    }
end

-- ============================================
-- Player List Section
-- ============================================
function Components.CreatePlayerListSection(parent, yPos)
    local C = Theme.C
    local ENTRY_GAP = Theme.ENTRY_GAP

    H.sectionHeader(parent, "PLAYERS", C.textDim, yPos)

    local playerListBg = Instance.new("Frame")
    playerListBg.Name = "PlayerListBg"
    playerListBg.Size = UDim2.new(1, 0, 0, 112)
    playerListBg.Position = UDim2.new(0, 0, 0, yPos + 18)
    playerListBg.BackgroundColor3 = C.surface
    playerListBg.BorderSizePixel = 0
    playerListBg.ClipsDescendants = true
    playerListBg.Parent = parent
    H.addCorner(playerListBg, 8)

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

    local playerLayout = Instance.new("UIListLayout")
    playerLayout.SortOrder = Enum.SortOrder.Name
    playerLayout.Padding = UDim.new(0, ENTRY_GAP)
    playerLayout.Parent = playerScroll

    return playerScroll
end

-- ============================================
-- Banned List Section
-- ============================================
function Components.CreateBannedListSection(parent, yPos)
    local C = Theme.C
    local ENTRY_GAP = Theme.ENTRY_GAP

    H.sectionHeader(parent, "BANNED", C.red, yPos)

    local bannedListBg = Instance.new("Frame")
    bannedListBg.Name = "BannedListBg"
    bannedListBg.Size = UDim2.new(1, 0, 0, 72)
    bannedListBg.Position = UDim2.new(0, 0, 0, yPos + 18)
    bannedListBg.BackgroundColor3 = C.surface
    bannedListBg.BorderSizePixel = 0
    bannedListBg.ClipsDescendants = true
    bannedListBg.Parent = parent
    H.addCorner(bannedListBg, 8)

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

    local bannedLayout = Instance.new("UIListLayout")
    bannedLayout.SortOrder = Enum.SortOrder.Name
    bannedLayout.Padding = UDim.new(0, ENTRY_GAP)
    bannedLayout.Parent = bannedScroll

    return bannedScroll
end

-- ============================================
-- Footer Bar
-- ============================================
function Components.CreateFooter(panel, isMobile)
    local C = Theme.C
    local PADDING = Theme.PADDING

    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 22)
    footer.Position = UDim2.new(0, 0, 1, -22)
    footer.BackgroundColor3 = C.surface
    footer.BorderSizePixel = 0
    footer.Parent = panel

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
    H.label({
        text = modeText,
        color = modeColor,
        size = 9,
        font = Enum.Font.GothamBold,
        sizeUDim = UDim2.new(0.5, 0, 1, 0),
        pos = UDim2.new(0, PADDING, 0, 0),
        parent = footer,
    })
    H.label({
        text = "v" .. (Config and Config.VERSION or "?.?.?"),
        color = C.textDim,
        size = 9,
        font = Enum.Font.Gotham,
        alignX = Enum.TextXAlignment.Right,
        sizeUDim = UDim2.new(0.5, -PADDING, 1, 0),
        pos = UDim2.new(0.5, 0, 0, 0),
        parent = footer,
    })

    return footer
end

-- ============================================
-- Player Entry Row (for player list)
-- ============================================
function Components.CreatePlayerEntry(playerName, hiveData, checkedData)
    local C = Theme.C
    local ENTRY_HEIGHT = Theme.ENTRY_HEIGHT
    local INDICATOR_WIDTH = Theme.INDICATOR_WIDTH

    local entry = Instance.new("Frame")
    entry.Name = playerName
    entry.Size = UDim2.new(1, -2, 0, ENTRY_HEIGHT)
    entry.BackgroundColor3 = C.surfaceHL
    entry.BorderSizePixel = 0
    H.addCorner(entry, 5)
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

    -- Check if in grace period
    local inGrace = false
    local graceRemaining = 0
    if Monitor and Monitor.PlayerJoinTimes and Monitor.PlayerJoinTimes[playerName] then
        local elapsed = tick() - Monitor.PlayerJoinTimes[playerName]
        local gracePeriod = Config and Config.GRACE_PERIOD or 20
        if elapsed < gracePeriod then
            inGrace = true
            graceRemaining = math.ceil(gracePeriod - elapsed)
        end
    end

    -- Determine colors & stats
    if isWhitelisted then
        if hiveData then
            statsLabel.Text = string.format("LVL %.1f  WL", hiveData.avgLevel or 0)
        else
            statsLabel.Text = "whitelisted"
        end
        statsLabel.TextColor3 = C.blue
        nameLabel.TextColor3 = C.blue
        indicator.BackgroundColor3 = C.blue
        entry.BackgroundColor3 = C.blueBg
    elseif inGrace then
        statsLabel.Text = string.format("\u{23f3} %ds", graceRemaining)
        statsLabel.TextColor3 = C.orange
        indicator.BackgroundColor3 = C.orange
        entry.BackgroundColor3 = C.orangeBg
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

        statsLabel.Text = string.format("LVL %.1f  %.0f%%", avgLvl, pct)

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
        statsLabel.Text = "SCANNING..."
        statsLabel.TextColor3 = C.blue
        indicator.BackgroundColor3 = C.blue
    end

    return entry
end

-- ============================================
-- Banned Entry Row (for banned list)
-- ============================================
function Components.CreateBannedEntry(playerName, banData)
    local C = Theme.C
    local BANNED_ENTRY_HEIGHT = Theme.BANNED_ENTRY_HEIGHT
    local INDICATOR_WIDTH = Theme.INDICATOR_WIDTH

    local entry = Instance.new("Frame")
    entry.Name = playerName
    entry.Size = UDim2.new(1, -2, 0, BANNED_ENTRY_HEIGHT)
    entry.BorderSizePixel = 0
    entry.ClipsDescendants = true
    H.addCorner(entry, 4)

    -- Determine state
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

    -- Status icon
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

    return entry
end

return Components
