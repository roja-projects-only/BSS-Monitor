--[[
    BSS Monitor - GUI Module (Minimal)
    Compact monitoring display for PC and Mobile
    https://github.com/roja-projects-only/BSS-Monitor
]]

local GUI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- State
GUI.ScreenGui = nil
GUI.MainFrame = nil
GUI.StatusLabel = nil
GUI.PlayerCountLabel = nil
GUI.ToggleBtn = nil

-- Dependencies
local Config = nil
local Monitor = nil

-- Colors
local Colors = {
    Background = Color3.fromRGB(20, 20, 25),
    Accent = Color3.fromRGB(255, 180, 0),
    Text = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(80, 200, 80),
    Danger = Color3.fromRGB(200, 80, 80),
}

-- Initialize
function GUI.Init(config, monitor)
    Config = config
    Monitor = monitor
    return GUI
end

-- Make frame draggable (PC + Mobile)
local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Create the minimal GUI
function GUI.Create()
    if GUI.ScreenGui then
        GUI.ScreenGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSSMonitorGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 140, 0, 45)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -22)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Accent
    stroke.Thickness = 2
    stroke.Parent = mainFrame

    local dragHandle = Instance.new("Frame")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(1, 0, 1, 0)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Parent = mainFrame

    makeDraggable(mainFrame, dragHandle)

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 5, 0.5, -15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "B"
    iconLabel.TextColor3 = Colors.Accent
    iconLabel.TextSize = 22
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = mainFrame

    local playerCount = Instance.new("TextLabel")
    playerCount.Name = "PlayerCount"
    playerCount.Size = UDim2.new(0, 50, 0, 20)
    playerCount.Position = UDim2.new(0, 32, 0, 5)
    playerCount.BackgroundTransparency = 1
    playerCount.Text = "0/6"
    playerCount.TextColor3 = Colors.Text
    playerCount.TextSize = 18
    playerCount.Font = Enum.Font.GothamBold
    playerCount.TextXAlignment = Enum.TextXAlignment.Left
    playerCount.Parent = mainFrame
    GUI.PlayerCountLabel = playerCount

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(0, 55, 0, 14)
    statusLabel.Position = UDim2.new(0, 32, 0, 26)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "STOPPED"
    statusLabel.TextColor3 = Colors.Danger
    statusLabel.TextSize = 10
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    GUI.StatusLabel = statusLabel

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Toggle"
    toggleBtn.Size = UDim2.new(0, 35, 0, 35)
    toggleBtn.Position = UDim2.new(1, -42, 0.5, -17)
    toggleBtn.BackgroundColor3 = Colors.Success
    toggleBtn.Text = ">"
    toggleBtn.TextColor3 = Colors.Text
    toggleBtn.TextSize = 18
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = mainFrame
    GUI.ToggleBtn = toggleBtn

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        if Monitor then
            Monitor.Toggle()
        end
    end)

    GUI.ScreenGui = screenGui
    GUI.MainFrame = mainFrame

    -- Parent GUI safely
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
        end
    end)

    local parented = false
    pcall(function()
        if gethui then
            screenGui.Parent = gethui()
            parented = true
        end
    end)

    if not parented then
        pcall(function()
            screenGui.Parent = game:GetService("CoreGui")
            parented = true
        end)
    end

    if not parented then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Update player count
    local function updatePlayerCount()
        local count = #Players:GetPlayers()
        local maxPlayers = Config and Config.MAX_PLAYERS or 6
        if GUI.PlayerCountLabel then
            GUI.PlayerCountLabel.Text = count .. "/" .. maxPlayers
        end
    end

    Players.PlayerAdded:Connect(updatePlayerCount)
    Players.PlayerRemoving:Connect(updatePlayerCount)
    updatePlayerCount()

    return screenGui
end

function GUI.UpdateStatus(isRunning)
    if GUI.StatusLabel then
        GUI.StatusLabel.Text = isRunning and "RUNNING" or "STOPPED"
        GUI.StatusLabel.TextColor3 = isRunning and Colors.Success or Colors.Danger
    end
    if GUI.ToggleBtn then
        GUI.ToggleBtn.Text = isRunning and "||" or ">"
        GUI.ToggleBtn.BackgroundColor3 = isRunning and Colors.Danger or Colors.Success
    end
end

function GUI.UpdatePlayerCount()
    local count = #Players:GetPlayers()
    local maxPlayers = Config and Config.MAX_PLAYERS or 6
    if GUI.PlayerCountLabel then
        GUI.PlayerCountLabel.Text = count .. "/" .. maxPlayers
    end
end

function GUI.UpdateDisplay() end
function GUI.UpdateLog() end

function GUI.Show()
    if GUI.ScreenGui then GUI.ScreenGui.Enabled = true end
end

function GUI.Hide()
    if GUI.ScreenGui then GUI.ScreenGui.Enabled = false end
end

function GUI.Toggle()
    if GUI.ScreenGui then GUI.ScreenGui.Enabled = not GUI.ScreenGui.Enabled end
end

return GUI
