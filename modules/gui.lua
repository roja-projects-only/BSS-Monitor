--[[
    BSS Monitor - GUI Module
    Compatible with Seliware, KRNL, Wave executors
    https://github.com/roja-projects-only/BSS-Monitor
]]

local GUI = {}
GUI.ScreenGui = nil
GUI.PlayerCountLabel = nil
GUI.StatusLabel = nil
GUI.PlayerList = nil
GUI.BannedList = nil

local Config = nil
local Monitor = nil
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

function GUI.Init(config, monitor)
    Config = config
    Monitor = monitor
    return GUI
end

-- Make frame draggable (works on PC and Mobile)
local function makeDraggable(gui, handle)
    local dragging = false
    local dragInput, dragStart, startPos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function GUI.Create()
    pcall(function()
        if GUI.ScreenGui then
            GUI.ScreenGui:Destroy()
        end
    end)

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSSMonitorGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 220, 0, 280)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -140)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(255, 180, 0)
    mainStroke.Thickness = 2
    mainStroke.Parent = mainFrame

    -- Title Bar (draggable)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "BSS Monitor"
    titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    makeDraggable(mainFrame, titleBar)

    -- Player Count Section
    local countFrame = Instance.new("Frame")
    countFrame.Name = "CountFrame"
    countFrame.Size = UDim2.new(1, -16, 0, 40)
    countFrame.Position = UDim2.new(0, 8, 0, 38)
    countFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    countFrame.BorderSizePixel = 0
    countFrame.Parent = mainFrame

    local countCorner = Instance.new("UICorner")
    countCorner.CornerRadius = UDim.new(0, 6)
    countCorner.Parent = countFrame

    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(0.5, 0, 1, 0)
    countLabel.Position = UDim2.new(0, 10, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "Players:"
    countLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    countLabel.TextSize = 12
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    countLabel.Parent = countFrame

    local playerCountLabel = Instance.new("TextLabel")
    playerCountLabel.Name = "PlayerCount"
    playerCountLabel.Size = UDim2.new(0.5, -10, 1, 0)
    playerCountLabel.Position = UDim2.new(0.5, 0, 0, 0)
    playerCountLabel.BackgroundTransparency = 1
    playerCountLabel.Text = "0/6"
    playerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerCountLabel.TextSize = 18
    playerCountLabel.Font = Enum.Font.GothamBold
    playerCountLabel.TextXAlignment = Enum.TextXAlignment.Right
    playerCountLabel.Parent = countFrame
    GUI.PlayerCountLabel = playerCountLabel

    -- Status indicator
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -16, 0, 16)
    statusLabel.Position = UDim2.new(0, 8, 0, 82)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: RUNNING"
    statusLabel.TextColor3 = Color3.fromRGB(80, 200, 80)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    GUI.StatusLabel = statusLabel

    -- Players Section Label
    local playersLabel = Instance.new("TextLabel")
    playersLabel.Size = UDim2.new(1, -16, 0, 18)
    playersLabel.Position = UDim2.new(0, 8, 0, 100)
    playersLabel.BackgroundTransparency = 1
    playersLabel.Text = "Players in Server:"
    playersLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
    playersLabel.TextSize = 11
    playersLabel.Font = Enum.Font.GothamBold
    playersLabel.TextXAlignment = Enum.TextXAlignment.Left
    playersLabel.Parent = mainFrame

    -- Player List (ScrollingFrame)
    local playerList = Instance.new("ScrollingFrame")
    playerList.Name = "PlayerList"
    playerList.Size = UDim2.new(1, -16, 0, 70)
    playerList.Position = UDim2.new(0, 8, 0, 118)
    playerList.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    playerList.BorderSizePixel = 0
    playerList.ScrollBarThickness = 4
    playerList.ScrollBarImageColor3 = Color3.fromRGB(255, 180, 0)
    playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playerList.Parent = mainFrame
    GUI.PlayerList = playerList

    local playerListCorner = Instance.new("UICorner")
    playerListCorner.CornerRadius = UDim.new(0, 4)
    playerListCorner.Parent = playerList

    local playerListLayout = Instance.new("UIListLayout")
    playerListLayout.SortOrder = Enum.SortOrder.Name
    playerListLayout.Padding = UDim.new(0, 2)
    playerListLayout.Parent = playerList

    local playerListPadding = Instance.new("UIPadding")
    playerListPadding.PaddingTop = UDim.new(0, 4)
    playerListPadding.PaddingBottom = UDim.new(0, 4)
    playerListPadding.PaddingLeft = UDim.new(0, 4)
    playerListPadding.PaddingRight = UDim.new(0, 4)
    playerListPadding.Parent = playerList

    -- Banned Section Label
    local bannedLabel = Instance.new("TextLabel")
    bannedLabel.Size = UDim2.new(1, -16, 0, 18)
    bannedLabel.Position = UDim2.new(0, 8, 0, 192)
    bannedLabel.BackgroundTransparency = 1
    bannedLabel.Text = "Banned Players:"
    bannedLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
    bannedLabel.TextSize = 11
    bannedLabel.Font = Enum.Font.GothamBold
    bannedLabel.TextXAlignment = Enum.TextXAlignment.Left
    bannedLabel.Parent = mainFrame

    -- Banned List (ScrollingFrame)
    local bannedList = Instance.new("ScrollingFrame")
    bannedList.Name = "BannedList"
    bannedList.Size = UDim2.new(1, -16, 0, 60)
    bannedList.Position = UDim2.new(0, 8, 0, 210)
    bannedList.BackgroundColor3 = Color3.fromRGB(45, 30, 30)
    bannedList.BorderSizePixel = 0
    bannedList.ScrollBarThickness = 4
    bannedList.ScrollBarImageColor3 = Color3.fromRGB(200, 80, 80)
    bannedList.CanvasSize = UDim2.new(0, 0, 0, 0)
    bannedList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    bannedList.Parent = mainFrame
    GUI.BannedList = bannedList

    local bannedListCorner = Instance.new("UICorner")
    bannedListCorner.CornerRadius = UDim.new(0, 4)
    bannedListCorner.Parent = bannedList

    local bannedListLayout = Instance.new("UIListLayout")
    bannedListLayout.SortOrder = Enum.SortOrder.Name
    bannedListLayout.Padding = UDim.new(0, 2)
    bannedListLayout.Parent = bannedList

    local bannedListPadding = Instance.new("UIPadding")
    bannedListPadding.PaddingTop = UDim.new(0, 4)
    bannedListPadding.PaddingBottom = UDim.new(0, 4)
    bannedListPadding.PaddingLeft = UDim.new(0, 4)
    bannedListPadding.PaddingRight = UDim.new(0, 4)
    bannedListPadding.Parent = bannedList

    GUI.ScreenGui = screenGui

    -- Parent GUI (Seliware/KRNL/Wave compatible)
    local parented = false
    
    -- Try gethui() first (most executors)
    pcall(function()
        if gethui then
            screenGui.Parent = gethui()
            parented = true
        end
    end)
    
    -- Try CoreGui
    if not parented then
        pcall(function()
            screenGui.Parent = game:GetService("CoreGui")
            parented = true
        end)
    end
    
    -- Fallback to PlayerGui
    if not parented then
        pcall(function()
            screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end)
    end

    -- Initial update
    GUI.UpdatePlayerCount()
    GUI.UpdatePlayerList()

    -- Connect player events
    Players.PlayerAdded:Connect(function()
        GUI.UpdatePlayerCount()
        GUI.UpdatePlayerList()
    end)
    
    Players.PlayerRemoving:Connect(function()
        task.wait(0.1)
        GUI.UpdatePlayerCount()
        GUI.UpdatePlayerList()
    end)

    return screenGui
end

function GUI.UpdatePlayerCount()
    pcall(function()
        local count = #Players:GetPlayers()
        local max = Config and Config.MAX_PLAYERS or 6
        if GUI.PlayerCountLabel then
            GUI.PlayerCountLabel.Text = count .. "/" .. max
        end
    end)
end

function GUI.UpdatePlayerList()
    pcall(function()
        if not GUI.PlayerList then return end
        
        -- Clear existing entries
        for _, child in ipairs(GUI.PlayerList:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        -- Add current players
        for _, player in ipairs(Players:GetPlayers()) do
            local entry = Instance.new("TextLabel")
            entry.Name = player.Name
            entry.Size = UDim2.new(1, -8, 0, 16)
            entry.BackgroundTransparency = 1
            entry.Text = player.Name
            entry.TextColor3 = Color3.fromRGB(220, 220, 220)
            entry.TextSize = 11
            entry.Font = Enum.Font.Gotham
            entry.TextXAlignment = Enum.TextXAlignment.Left
            entry.TextTruncate = Enum.TextTruncate.AtEnd
            entry.Parent = GUI.PlayerList
        end
    end)
end

function GUI.UpdateBannedList(bannedPlayers)
    pcall(function()
        if not GUI.BannedList then return end
        
        -- Clear existing entries
        for _, child in ipairs(GUI.BannedList:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        -- Add banned players
        if bannedPlayers then
            for playerName, _ in pairs(bannedPlayers) do
                local entry = Instance.new("TextLabel")
                entry.Name = playerName
                entry.Size = UDim2.new(1, -8, 0, 16)
                entry.BackgroundTransparency = 1
                entry.Text = playerName
                entry.TextColor3 = Color3.fromRGB(255, 100, 100)
                entry.TextSize = 11
                entry.Font = Enum.Font.Gotham
                entry.TextXAlignment = Enum.TextXAlignment.Left
                entry.TextTruncate = Enum.TextTruncate.AtEnd
                entry.Parent = GUI.BannedList
            end
        end
        
        -- Show "None" if empty
        if #GUI.BannedList:GetChildren() <= 3 then -- UIListLayout, UIPadding, UICorner
            local noneLabel = Instance.new("TextLabel")
            noneLabel.Name = "_None"
            noneLabel.Size = UDim2.new(1, -8, 0, 16)
            noneLabel.BackgroundTransparency = 1
            noneLabel.Text = "None"
            noneLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
            noneLabel.TextSize = 11
            noneLabel.Font = Enum.Font.Gotham
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

-- Compatibility stubs
function GUI.UpdateDisplay(scanResults, checkedPlayers, bannedPlayers)
    GUI.UpdatePlayerList()
    GUI.UpdateBannedList(bannedPlayers)
end

function GUI.UpdateLog() end

function GUI.Show()
    pcall(function()
        if GUI.ScreenGui then GUI.ScreenGui.Enabled = true end
    end)
end

function GUI.Hide()
    pcall(function()
        if GUI.ScreenGui then GUI.ScreenGui.Enabled = false end
    end)
end

function GUI.Toggle()
    pcall(function()
        if GUI.ScreenGui then GUI.ScreenGui.Enabled = not GUI.ScreenGui.Enabled end
    end)
end

return GUI
