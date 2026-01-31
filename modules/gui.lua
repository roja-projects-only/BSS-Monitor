local GUI = {}
GUI.ScreenGui = nil
GUI.PlayerCountLabel = nil
GUI.StatusLabel = nil
GUI.PlayerList = nil
GUI.BannedList = nil

local Config = nil
local Monitor = nil
local Players = game:GetService("Players")

function GUI.Init(config, monitor)
    Config = config
    Monitor = monitor
    return GUI
end

function GUI.Create()
    pcall(function()
        if GUI.ScreenGui then GUI.ScreenGui:Destroy() end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSSMonitorGui"
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 200, 0, 250)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(255, 180, 0)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    titleLabel.BorderSizePixel = 0
    titleLabel.Text = "BSS Monitor"
    titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = mainFrame

    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, -10, 0, 20)
    countLabel.Position = UDim2.new(0, 5, 0, 30)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Players: 0/6"
    countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    countLabel.TextSize = 14
    countLabel.Font = Enum.Font.SourceSansBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = mainFrame
    GUI.PlayerCountLabel = countLabel

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 16)
    statusLabel.Position = UDim2.new(0, 5, 0, 50)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: RUNNING"
    statusLabel.TextColor3 = Color3.fromRGB(80, 200, 80)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    GUI.StatusLabel = statusLabel

    local playersHeader = Instance.new("TextLabel")
    playersHeader.Size = UDim2.new(1, -10, 0, 16)
    playersHeader.Position = UDim2.new(0, 5, 0, 70)
    playersHeader.BackgroundTransparency = 1
    playersHeader.Text = "Players:"
    playersHeader.TextColor3 = Color3.fromRGB(255, 180, 0)
    playersHeader.TextSize = 11
    playersHeader.Font = Enum.Font.SourceSansBold
    playersHeader.TextXAlignment = Enum.TextXAlignment.Left
    playersHeader.Parent = mainFrame

    local playerList = Instance.new("Frame")
    playerList.Name = "PlayerList"
    playerList.Size = UDim2.new(1, -10, 0, 60)
    playerList.Position = UDim2.new(0, 5, 0, 86)
    playerList.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    playerList.BorderSizePixel = 0
    playerList.Parent = mainFrame
    GUI.PlayerList = playerList

    local playerListLayout = Instance.new("UIListLayout")
    playerListLayout.SortOrder = Enum.SortOrder.Name
    playerListLayout.Padding = UDim.new(0, 2)
    playerListLayout.Parent = playerList

    local bannedHeader = Instance.new("TextLabel")
    bannedHeader.Size = UDim2.new(1, -10, 0, 16)
    bannedHeader.Position = UDim2.new(0, 5, 0, 150)
    bannedHeader.BackgroundTransparency = 1
    bannedHeader.Text = "Banned:"
    bannedHeader.TextColor3 = Color3.fromRGB(200, 80, 80)
    bannedHeader.TextSize = 11
    bannedHeader.Font = Enum.Font.SourceSansBold
    bannedHeader.TextXAlignment = Enum.TextXAlignment.Left
    bannedHeader.Parent = mainFrame

    local bannedList = Instance.new("Frame")
    bannedList.Name = "BannedList"
    bannedList.Size = UDim2.new(1, -10, 0, 50)
    bannedList.Position = UDim2.new(0, 5, 0, 166)
    bannedList.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
    bannedList.BorderSizePixel = 0
    bannedList.Parent = mainFrame
    GUI.BannedList = bannedList

    local bannedListLayout = Instance.new("UIListLayout")
    bannedListLayout.SortOrder = Enum.SortOrder.Name
    bannedListLayout.Padding = UDim.new(0, 2)
    bannedListLayout.Parent = bannedList

    GUI.ScreenGui = screenGui

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

function GUI.UpdatePlayerCount()
    pcall(function()
        local count = #Players:GetPlayers()
        local max = Config and Config.MAX_PLAYERS or 6
        if GUI.PlayerCountLabel then
            GUI.PlayerCountLabel.Text = "Players: " .. count .. "/" .. max
        end
    end)
end

function GUI.UpdatePlayerList()
    pcall(function()
        if not GUI.PlayerList then return end
        for _, child in ipairs(GUI.PlayerList:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            local entry = Instance.new("TextLabel")
            entry.Name = player.Name
            entry.Size = UDim2.new(1, 0, 0, 14)
            entry.BackgroundTransparency = 1
            entry.Text = "  " .. player.Name
            entry.TextColor3 = Color3.fromRGB(220, 220, 220)
            entry.TextSize = 11
            entry.Font = Enum.Font.SourceSans
            entry.TextXAlignment = Enum.TextXAlignment.Left
            entry.Parent = GUI.PlayerList
        end
    end)
end

function GUI.UpdateBannedList(bannedPlayers)
    pcall(function()
        if not GUI.BannedList then return end
        for _, child in ipairs(GUI.BannedList:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        if bannedPlayers then
            for playerName, _ in pairs(bannedPlayers) do
                local entry = Instance.new("TextLabel")
                entry.Name = playerName
                entry.Size = UDim2.new(1, 0, 0, 14)
                entry.BackgroundTransparency = 1
                entry.Text = "  " .. playerName
                entry.TextColor3 = Color3.fromRGB(255, 100, 100)
                entry.TextSize = 11
                entry.Font = Enum.Font.SourceSans
                entry.TextXAlignment = Enum.TextXAlignment.Left
                entry.Parent = GUI.BannedList
            end
        end
        if #GUI.BannedList:GetChildren() <= 1 then
            local noneLabel = Instance.new("TextLabel")
            noneLabel.Name = "_None"
            noneLabel.Size = UDim2.new(1, 0, 0, 14)
            noneLabel.BackgroundTransparency = 1
            noneLabel.Text = "  None"
            noneLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
            noneLabel.TextSize = 11
            noneLabel.Font = Enum.Font.SourceSans
            noneLabel.TextXAlignment = Enum.TextXAlignment.Left
            noneLabel.Parent = GUI.BannedList
        end
    end)
end

function GUI.UpdateStatus(isRunning)
    pcall(function()
        if GUI.StatusLabel then
            if isRunning then
                GUI.StatusLabel.Text = "Status: RUNNING"
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(80, 200, 80)
            else
                GUI.StatusLabel.Text = "Status: STOPPED"
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
            end
        end
    end)
end

function GUI.UpdateDisplay(scanResults, checkedPlayers, bannedPlayers)
    GUI.UpdatePlayerList()
    GUI.UpdateBannedList(bannedPlayers)
end

function GUI.UpdateLog() end
function GUI.Show() pcall(function() if GUI.ScreenGui then GUI.ScreenGui.Enabled = true end end) end
function GUI.Hide() pcall(function() if GUI.ScreenGui then GUI.ScreenGui.Enabled = false end end) end
function GUI.Toggle() pcall(function() if GUI.ScreenGui then GUI.ScreenGui.Enabled = not GUI.ScreenGui.Enabled end end) end

return GUI
