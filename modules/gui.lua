local GUI = {}
GUI.ScreenGui = nil
GUI.PlayerCountLabel = nil
GUI.StatusLabel = nil
GUI.PlayerList = nil
GUI.BannedList = nil
GUI.MainFrame = nil
GUI.Content = nil
GUI.ToggleButton = nil
GUI.CollapseButton = nil
GUI.TitleCountLabel = nil
GUI.LastScanResults = {}
GUI.CheckedPlayers = {}
GUI.IsCollapsed = false
GUI.IsHidden = false

local Config = nil
local Monitor = nil
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Sizes
local EXPANDED_HEIGHT = 300
local COLLAPSED_HEIGHT = 36

-- Color palette
local Colors = {
    bg = Color3.fromRGB(18, 18, 22),
    bgSecondary = Color3.fromRGB(28, 28, 35),
    bgTertiary = Color3.fromRGB(38, 38, 48),
    accent = Color3.fromRGB(255, 193, 7),
    accentDark = Color3.fromRGB(200, 150, 0),
    text = Color3.fromRGB(245, 245, 245),
    textMuted = Color3.fromRGB(160, 160, 170),
    success = Color3.fromRGB(76, 175, 80),
    danger = Color3.fromRGB(244, 67, 54),
    warning = Color3.fromRGB(255, 152, 0),
    info = Color3.fromRGB(33, 150, 243),
}

function GUI.Init(config, monitor)
    Config = config
    Monitor = monitor
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
    stroke.Color = color or Colors.accent
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
    shadow.Size = UDim2.new(1, 24, 1, 24)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = parent
    return shadow
end

-- Helper to create padding
local function addPadding(parent, padding)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, padding or 8)
    p.PaddingBottom = UDim.new(0, padding or 8)
    p.PaddingLeft = UDim.new(0, padding or 8)
    p.PaddingRight = UDim.new(0, padding or 8)
    p.Parent = parent
    return p
end

function GUI.Create()
    pcall(function()
        if GUI.ScreenGui then GUI.ScreenGui:Destroy() end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSSMonitorGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Mobile toggle button (bottom right)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 44, 0, 44)
    toggleButton.Position = UDim2.new(1, -56, 1, -56)
    toggleButton.BackgroundColor3 = Colors.accent
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "🐝"
    toggleButton.TextSize = 22
    toggleButton.Font = Enum.Font.SourceSans
    toggleButton.AutoButtonColor = true
    toggleButton.Parent = screenGui
    addCorner(toggleButton, 22)
    addShadow(toggleButton)
    GUI.ToggleButton = toggleButton

    -- Main container
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 240, 0, EXPANDED_HEIGHT)
    mainFrame.Position = UDim2.new(0, 16, 0.5, -EXPANDED_HEIGHT/2)
    mainFrame.BackgroundColor3 = Colors.bg
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    addCorner(mainFrame, 10)
    addStroke(mainFrame, Colors.accent, 2)
    addShadow(mainFrame)
    GUI.MainFrame = mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Colors.accent
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar

    -- Fix bottom corners of title bar
    local titleFix = Instance.new("Frame")
    titleFix.Name = "TitleFix"
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = Colors.accent
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleIcon = Instance.new("TextLabel")
    titleIcon.Size = UDim2.new(0, 26, 1, 0)
    titleIcon.Position = UDim2.new(0, 8, 0, 0)
    titleIcon.BackgroundTransparency = 1
    titleIcon.Text = "🐝"
    titleIcon.TextSize = 16
    titleIcon.Font = Enum.Font.SourceSans
    titleIcon.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0, 100, 1, 0)
    titleLabel.Position = UDim2.new(0, 32, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "BSS MONITOR"
    titleLabel.TextColor3 = Colors.bg
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Player count in title (shown when collapsed or always visible)
    local titleCountLabel = Instance.new("TextLabel")
    titleCountLabel.Name = "TitleCountLabel"
    titleCountLabel.Size = UDim2.new(0, 50, 1, 0)
    titleCountLabel.Position = UDim2.new(0, 130, 0, 0)
    titleCountLabel.BackgroundTransparency = 1
    titleCountLabel.Text = "0/6"
    titleCountLabel.TextColor3 = Colors.bg
    titleCountLabel.TextSize = 13
    titleCountLabel.Font = Enum.Font.GothamBold
    titleCountLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleCountLabel.Parent = titleBar
    GUI.TitleCountLabel = titleCountLabel

    -- Collapse button (dropdown arrow)
    local collapseButton = Instance.new("TextButton")
    collapseButton.Name = "CollapseButton"
    collapseButton.Size = UDim2.new(0, 30, 0, 30)
    collapseButton.Position = UDim2.new(1, -34, 0, 3)
    collapseButton.BackgroundColor3 = Colors.accentDark
    collapseButton.BorderSizePixel = 0
    collapseButton.Text = "▼"
    collapseButton.TextColor3 = Colors.bg
    collapseButton.TextSize = 12
    collapseButton.Font = Enum.Font.GothamBold
    collapseButton.AutoButtonColor = true
    collapseButton.Parent = titleBar
    addCorner(collapseButton, 6)
    GUI.CollapseButton = collapseButton

    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -48)
    content.Position = UDim2.new(0, 12, 0, 42)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    GUI.Content = content

    -- Stats row
    local statsRow = Instance.new("Frame")
    statsRow.Name = "StatsRow"
    statsRow.Size = UDim2.new(1, 0, 0, 46)
    statsRow.BackgroundColor3 = Colors.bgSecondary
    statsRow.BorderSizePixel = 0
    statsRow.Parent = content
    addCorner(statsRow, 8)

    -- Player count stat
    local playerStat = Instance.new("Frame")
    playerStat.Size = UDim2.new(0.5, -4, 1, 0)
    playerStat.BackgroundTransparency = 1
    playerStat.Parent = statsRow

    local playerCountLabel = Instance.new("TextLabel")
    playerCountLabel.Size = UDim2.new(1, 0, 0.55, 0)
    playerCountLabel.Position = UDim2.new(0, 0, 0, 4)
    playerCountLabel.BackgroundTransparency = 1
    playerCountLabel.Text = "0/6"
    playerCountLabel.TextColor3 = Colors.accent
    playerCountLabel.TextSize = 20
    playerCountLabel.Font = Enum.Font.GothamBold
    playerCountLabel.Parent = playerStat
    GUI.PlayerCountLabel = playerCountLabel

    local playerCountTitle = Instance.new("TextLabel")
    playerCountTitle.Size = UDim2.new(1, 0, 0.35, 0)
    playerCountTitle.Position = UDim2.new(0, 0, 0.58, 0)
    playerCountTitle.BackgroundTransparency = 1
    playerCountTitle.Text = "Players"
    playerCountTitle.TextColor3 = Colors.textMuted
    playerCountTitle.TextSize = 10
    playerCountTitle.Font = Enum.Font.Gotham
    playerCountTitle.Parent = playerStat

    -- Status stat
    local statusStat = Instance.new("Frame")
    statusStat.Size = UDim2.new(0.5, -4, 1, 0)
    statusStat.Position = UDim2.new(0.5, 4, 0, 0)
    statusStat.BackgroundTransparency = 1
    statusStat.Parent = statsRow

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0.55, 0)
    statusLabel.Position = UDim2.new(0, 0, 0, 4)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "ACTIVE"
    statusLabel.TextColor3 = Colors.success
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Parent = statusStat
    GUI.StatusLabel = statusLabel

    local statusTitle = Instance.new("TextLabel")
    statusTitle.Size = UDim2.new(1, 0, 0.35, 0)
    statusTitle.Position = UDim2.new(0, 0, 0.58, 0)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Text = "Status"
    statusTitle.TextColor3 = Colors.textMuted
    statusTitle.TextSize = 10
    statusTitle.Font = Enum.Font.Gotham
    statusTitle.Parent = statusStat

    -- Players section
    local playersSection = Instance.new("Frame")
    playersSection.Name = "PlayersSection"
    playersSection.Size = UDim2.new(1, 0, 0, 105)
    playersSection.Position = UDim2.new(0, 0, 0, 52)
    playersSection.BackgroundTransparency = 1
    playersSection.Parent = content

    local playersHeader = Instance.new("TextLabel")
    playersHeader.Size = UDim2.new(1, 0, 0, 18)
    playersHeader.BackgroundTransparency = 1
    playersHeader.Text = "PLAYERS"
    playersHeader.TextColor3 = Colors.textMuted
    playersHeader.TextSize = 10
    playersHeader.Font = Enum.Font.GothamBold
    playersHeader.TextXAlignment = Enum.TextXAlignment.Left
    playersHeader.Parent = playersSection

    local playerListContainer = Instance.new("Frame")
    playerListContainer.Name = "PlayerListContainer"
    playerListContainer.Size = UDim2.new(1, 0, 1, -20)
    playerListContainer.Position = UDim2.new(0, 0, 0, 20)
    playerListContainer.BackgroundColor3 = Colors.bgSecondary
    playerListContainer.BorderSizePixel = 0
    playerListContainer.ClipsDescendants = true
    playerListContainer.Parent = playersSection
    addCorner(playerListContainer, 6)

    local playerList = Instance.new("ScrollingFrame")
    playerList.Name = "PlayerList"
    playerList.Size = UDim2.new(1, -8, 1, -8)
    playerList.Position = UDim2.new(0, 4, 0, 4)
    playerList.BackgroundTransparency = 1
    playerList.BorderSizePixel = 0
    playerList.ScrollBarThickness = 2
    playerList.ScrollBarImageColor3 = Colors.accent
    playerList.ScrollBarImageTransparency = 0.3
    playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playerList.ScrollingDirection = Enum.ScrollingDirection.Y
    playerList.Parent = playerListContainer
    GUI.PlayerList = playerList

    local playerListLayout = Instance.new("UIListLayout")
    playerListLayout.SortOrder = Enum.SortOrder.Name
    playerListLayout.Padding = UDim.new(0, 3)
    playerListLayout.Parent = playerList

    -- Banned section
    local bannedSection = Instance.new("Frame")
    bannedSection.Name = "BannedSection"
    bannedSection.Size = UDim2.new(1, 0, 0, 80)
    bannedSection.Position = UDim2.new(0, 0, 0, 162)
    bannedSection.BackgroundTransparency = 1
    bannedSection.Parent = content

    local bannedHeader = Instance.new("TextLabel")
    bannedHeader.Size = UDim2.new(1, 0, 0, 18)
    bannedHeader.BackgroundTransparency = 1
    bannedHeader.Text = "BANNED"
    bannedHeader.TextColor3 = Colors.danger
    bannedHeader.TextSize = 10
    bannedHeader.Font = Enum.Font.GothamBold
    bannedHeader.TextXAlignment = Enum.TextXAlignment.Left
    bannedHeader.Parent = bannedSection

    local bannedListContainer = Instance.new("Frame")
    bannedListContainer.Name = "BannedListContainer"
    bannedListContainer.Size = UDim2.new(1, 0, 1, -20)
    bannedListContainer.Position = UDim2.new(0, 0, 0, 20)
    bannedListContainer.BackgroundColor3 = Color3.fromRGB(35, 25, 25)
    bannedListContainer.BorderSizePixel = 0
    bannedListContainer.ClipsDescendants = true
    bannedListContainer.Parent = bannedSection
    addCorner(bannedListContainer, 6)

    local bannedList = Instance.new("ScrollingFrame")
    bannedList.Name = "BannedList"
    bannedList.Size = UDim2.new(1, -8, 1, -8)
    bannedList.Position = UDim2.new(0, 4, 0, 4)
    bannedList.BackgroundTransparency = 1
    bannedList.BorderSizePixel = 0
    bannedList.ScrollBarThickness = 2
    bannedList.ScrollBarImageColor3 = Colors.danger
    bannedList.ScrollBarImageTransparency = 0.3
    bannedList.CanvasSize = UDim2.new(0, 0, 0, 0)
    bannedList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    bannedList.ScrollingDirection = Enum.ScrollingDirection.Y
    bannedList.Parent = bannedListContainer
    GUI.BannedList = bannedList

    local bannedListLayout = Instance.new("UIListLayout")
    bannedListLayout.SortOrder = Enum.SortOrder.Name
    bannedListLayout.Padding = UDim.new(0, 3)
    bannedListLayout.Parent = bannedList

    GUI.ScreenGui = screenGui

    -- Toggle button click handler (show/hide main panel)
    toggleButton.MouseButton1Click:Connect(function()
        GUI.IsHidden = not GUI.IsHidden
        mainFrame.Visible = not GUI.IsHidden
        toggleButton.Text = GUI.IsHidden and "🐝" or "✕"
        toggleButton.BackgroundColor3 = GUI.IsHidden and Colors.accent or Colors.danger
    end)

    -- Collapse button click handler (expand/collapse)
    collapseButton.MouseButton1Click:Connect(function()
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

    Players.PlayerAdded:Connect(function() GUI.UpdatePlayerCount() GUI.UpdatePlayerList() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1) GUI.UpdatePlayerCount() GUI.UpdatePlayerList() end)

    return screenGui
end

-- Toggle collapse state with animation
function GUI.ToggleCollapse()
    GUI.IsCollapsed = not GUI.IsCollapsed
    
    local targetHeight = GUI.IsCollapsed and COLLAPSED_HEIGHT or EXPANDED_HEIGHT
    
    -- Animate size only, keep current position
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(GUI.MainFrame, tweenInfo, {
        Size = UDim2.new(0, 240, 0, targetHeight)
    })
    tween:Play()
    
    -- Update arrow and title bar
    if GUI.CollapseButton then
        GUI.CollapseButton.Text = GUI.IsCollapsed and "▲" or "▼"
    end
    
    -- Hide/show title fix (bottom corners)
    local titleFix = GUI.MainFrame and GUI.MainFrame:FindFirstChild("TitleBar") and GUI.MainFrame.TitleBar:FindFirstChild("TitleFix")
    if titleFix then
        titleFix.Visible = not GUI.IsCollapsed
    end
    
    -- Show/hide content
    if GUI.Content then
        GUI.Content.Visible = not GUI.IsCollapsed
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
    entry.Size = UDim2.new(1, -4, 0, 22)
    entry.BackgroundColor3 = Colors.bgTertiary
    entry.BorderSizePixel = 0
    addCorner(entry, 4)
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 6, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = Colors.text
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = entry
    
    -- Stats container (right side)
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0.42, 0, 1, 0)
    statsLabel.Position = UDim2.new(0.55, 0, 0, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextSize = 10
    statsLabel.Font = Enum.Font.GothamMedium
    statsLabel.TextXAlignment = Enum.TextXAlignment.Right
    statsLabel.Parent = entry
    
    -- Determine stats to display
    if hiveData then
        local avgLvl = hiveData.avgLevel or 0
        local totalBees = hiveData.totalBees or 0
        
        -- Calculate percentage at required level
        local percentAtLevel = 0
        if checkedData and checkedData.details and checkedData.details.percentAtLevel then
            percentAtLevel = checkedData.details.percentAtLevel * 100
        elseif totalBees > 0 and Config then
            local beesAtOrAbove = 0
            for level, count in pairs(hiveData.levelCounts or {}) do
                if level >= (Config.MINIMUM_LEVEL or 15) then
                    beesAtOrAbove = beesAtOrAbove + count
                end
            end
            percentAtLevel = (beesAtOrAbove / totalBees) * 100
        end
        
        statsLabel.Text = string.format("Lv%.1f  %.0f%%", avgLvl, percentAtLevel)
        
        -- Color based on pass/fail
        local requiredPct = Config and (Config.REQUIRED_PERCENT or 0.9) * 100 or 90
        if percentAtLevel >= requiredPct then
            statsLabel.TextColor3 = Colors.success
            entry.BackgroundColor3 = Color3.fromRGB(30, 45, 30)
        elseif totalBees < (Config and Config.MIN_BEES_REQUIRED or 35) then
            statsLabel.TextColor3 = Colors.warning
            entry.BackgroundColor3 = Color3.fromRGB(45, 40, 25)
        else
            statsLabel.TextColor3 = Colors.danger
            entry.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
        end
    else
        statsLabel.Text = "scanning..."
        statsLabel.TextColor3 = Colors.textMuted
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
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local hiveData = GUI.LastScanResults and GUI.LastScanResults[player.Name]
                local checkedData = GUI.CheckedPlayers and GUI.CheckedPlayers[player.Name]
                local entry = createPlayerEntry(player.Name, hiveData, checkedData)
                entry.Parent = GUI.PlayerList
            end
        end
        
        -- Show empty state if no other players
        if #Players:GetPlayers() <= 1 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Name = "_Empty"
            emptyLabel.Size = UDim2.new(1, 0, 0, 22)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No other players"
            emptyLabel.TextColor3 = Colors.textMuted
            emptyLabel.TextSize = 11
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.Parent = GUI.PlayerList
        end
    end)
end

function GUI.UpdateBannedList(bannedPlayers)
    pcall(function()
        if not GUI.BannedList then return end
        for _, child in ipairs(GUI.BannedList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
        
        local hasBanned = false
        if bannedPlayers then
            for playerName, banData in pairs(bannedPlayers) do
                hasBanned = true
                local entry = Instance.new("Frame")
                entry.Name = playerName
                entry.Size = UDim2.new(1, -4, 0, 20)
                entry.BorderSizePixel = 0
                addCorner(entry, 4)
                
                -- Color based on verification status
                local bgColor, textColor, statusIcon
                if banData.dryRun then
                    bgColor = Color3.fromRGB(60, 60, 30) -- Yellow-ish for dry run
                    textColor = Colors.warning
                    statusIcon = "⚠️"
                elseif banData.verified then
                    bgColor = Color3.fromRGB(30, 60, 30) -- Green for verified
                    textColor = Colors.success
                    statusIcon = "✅"
                elseif banData.failed then
                    bgColor = Color3.fromRGB(80, 30, 30) -- Dark red for failed
                    textColor = Color3.fromRGB(255, 100, 100)
                    statusIcon = "❌"
                else
                    bgColor = Color3.fromRGB(60, 50, 30) -- Orange for pending
                    textColor = Colors.warning
                    statusIcon = "⏳"
                end
                entry.BackgroundColor3 = bgColor
                
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -24, 1, 0)
                nameLabel.Position = UDim2.new(0, 6, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = playerName
                nameLabel.TextColor3 = textColor
                nameLabel.TextSize = 11
                nameLabel.Font = Enum.Font.GothamMedium
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                nameLabel.Parent = entry
                
                -- Status indicator
                local statusLabel = Instance.new("TextLabel")
                statusLabel.Size = UDim2.new(0, 18, 1, 0)
                statusLabel.Position = UDim2.new(1, -20, 0, 0)
                statusLabel.BackgroundTransparency = 1
                statusLabel.Text = statusIcon
                statusLabel.TextSize = 10
                statusLabel.Font = Enum.Font.Gotham
                statusLabel.Parent = entry
                
                entry.Parent = GUI.BannedList
            end
        end
        
        if not hasBanned then
            local noneLabel = Instance.new("TextLabel")
            noneLabel.Name = "_None"
            noneLabel.Size = UDim2.new(1, 0, 0, 20)
            noneLabel.BackgroundTransparency = 1
            noneLabel.Text = "None"
            noneLabel.TextColor3 = Colors.textMuted
            noneLabel.TextSize = 11
            noneLabel.Font = Enum.Font.Gotham
            noneLabel.Parent = GUI.BannedList
        end
    end)
end

function GUI.UpdateStatus(isRunning)
    pcall(function()
        if GUI.StatusLabel then
            if isRunning then
                GUI.StatusLabel.Text = "ACTIVE"
                GUI.StatusLabel.TextColor3 = Colors.success
            else
                GUI.StatusLabel.Text = "PAUSED"
                GUI.StatusLabel.TextColor3 = Colors.danger
            end
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
