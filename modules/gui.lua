--[[
    BSS Monitor - GUI Module (Minimal)
    Compact monitoring display for PC and Mobile
    https://github.com/roja-projects-only/BSS-Monitor
]]

local GUI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- State
GUI.ScreenGui = nil
GUI.MainFrame = nil
GUI.StatusLabel = nil
GUI.PlayerCountLabel = nil

-- Dependencies
local Config = nil
local Monitor = nil

-- Colors
local Colors = {
    Background = Color3.fromRGB(20, 20, 25),
    Surface = Color3.fromRGB(35, 35, 45),
    Accent = Color3.fromRGB(255, 180, 0),
    Text = Color3.fromRGB(255, 255, 255),
    TextMuted = Color3.fromRGB(150, 150, 150),
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
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

-- Create the minimal GUI
function GUI.Create()
    -- Destroy existing
    if GUI.ScreenGui then
        GUI.ScreenGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSSMonitorGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main frame (compact pill shape)
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
    
    -- Drag handle (full area)
    local dragHandle = Instance.new("Frame")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(1, 0, 1, 0)
    dragHandle.BackgroundTransparency = 1
    dragHandle.Parent = mainFrame
    
    makeDraggable(mainFrame, dragHandle)
    
    -- Bee icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 8, 0.5, -15)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = ""
    iconLabel.TextSize = 22
    iconLabel.Parent = mainFrame
    
    -- Player count
    local playerCount = Instance.new("TextLabel")
    playerCount.Name = "PlayerCount"
    playerCount.Size = UDim2.new(0, 50, 0, 20)
    playerCount.Position = UDim2.new(0, 38, 0, 5)
    playerCount.BackgroundTransparency = 1
    playerCount.Text = "0/6"
    playerCount.TextColor3 = Colors.Text
    playerCount.TextSize = 18
    playerCount.Font = Enum.Font.GothamBold
    playerCount.TextXAlignment = Enum.TextXAlignment.Left
    playerCount.Parent = mainFrame
    GUI.PlayerCountLabel = playerCount
    
    -- Status indicator
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(0, 50, 0, 14)
    statusLabel.Position = UDim2.new(0, 38, 0, 26)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "STOPPED"
    statusLabel.TextColor3 = Colors.Danger
    statusLabel.TextSize = 10
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    GUI.StatusLabel = statusLabel
    
    -- Toggle button (play/pause)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Toggle"
    toggleBtn.Size = UDim2.new(0, 35, 0, 35)
    toggleBtn.Position = UDim2.new(1, -42, 0.5, -17)
    toggleBtn.BackgroundColor3 = Colors.Success
    toggleBtn.Text = ""
    toggleBtn.TextColor3 = Colors.Text
    toggleBtn.TextSize = 16
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = mainFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleBtn
    
    toggleBtn.MouseButton1Click:Connect(function()
        if Monitor then
            Monitor.Toggle()
        end
    end)
    
    -- Store references
    GUI.ScreenGui = screenGui
    GUI.MainFrame = mainFrame
    GUI.ToggleBtn = toggleBtn
    
    -- Parent GUI
    local parented = false
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
        end
    end)
    
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
    
    -- Update player count on player changes
    local function updatePlayerCount()
        local count = #Players:GetPlayers()
        if GUI.PlayerCountLabel then
            GUI.PlayerCountLabel.Text = count .. "/" .. Config.MAX_PLAYERS
        end
    end
    
    Players.PlayerAdded:Connect(updatePlayerCount)
    Players.PlayerRemoving:Connect(updatePlayerCount)
    updatePlayerCount()
    
    return screenGui
end

-- Update status indicator
function GUI.UpdateStatus(isRunning)
    if GUI.StatusLabel then
        if isRunning then
            GUI.StatusLabel.Text = "RUNNING"
            GUI.StatusLabel.TextColor3 = Colors.Success
        else
            GUI.StatusLabel.Text = "STOPPED"
            GUI.StatusLabel.TextColor3 = Colors.Danger
        end
    end
    
    if GUI.ToggleBtn then
        if isRunning then
            GUI.ToggleBtn.Text = ""
            GUI.ToggleBtn.BackgroundColor3 = Colors.Danger
        else
            GUI.ToggleBtn.Text = ""
            GUI.ToggleBtn.BackgroundColor3 = Colors.Success
        end
    end
end

-- Update player count display
function GUI.UpdatePlayerCount()
    if GUI.PlayerCountLabel then
        local count = #Players:GetPlayers()
        GUI.PlayerCountLabel.Text = count .. "/" .. Config.MAX_PLAYERS
    end
end

-- Stub functions for compatibility
function GUI.UpdateDisplay() end
function GUI.UpdateLog() end

-- Show/hide
function GUI.Show()
    if GUI.ScreenGui then
        GUI.ScreenGui.Enabled = true
    end
end

function GUI.Hide()
    if GUI.ScreenGui then
        GUI.ScreenGui.Enabled = false
    end
end

function GUI.Toggle()
    if GUI.ScreenGui then
        GUI.ScreenGui.Enabled = not GUI.ScreenGui.Enabled
    end
end

return GUI
