--[[
    BSS Monitor - GUI Module (Minimal)
    https://github.com/roja-projects-only/BSS-Monitor
]]

local GUI = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- State
GUI.ScreenGui = nil
GUI.StatusLabel = nil
GUI.PlayerCountLabel = nil
GUI.ToggleBtn = nil

-- Dependencies
local Config = nil
local Monitor = nil

-- Initialize
function GUI.Init(config, monitor)
    Config = config
    Monitor = monitor
    return GUI
end

-- Create the minimal GUI
function GUI.Create()
    if GUI.ScreenGui then
        pcall(function() GUI.ScreenGui:Destroy() end)
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSSMonitorGui"
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 130, 0, 40)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 180, 0)
    stroke.Thickness = 2
    stroke.Parent = mainFrame

    local playerCount = Instance.new("TextLabel")
    playerCount.Name = "PlayerCount"
    playerCount.Size = UDim2.new(0, 50, 0, 20)
    playerCount.Position = UDim2.new(0, 10, 0, 3)
    playerCount.BackgroundTransparency = 1
    playerCount.Text = "0/6"
    playerCount.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerCount.TextSize = 16
    playerCount.Font = Enum.Font.GothamBold
    playerCount.TextXAlignment = Enum.TextXAlignment.Left
    playerCount.Parent = mainFrame
    GUI.PlayerCountLabel = playerCount

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(0, 55, 0, 14)
    statusLabel.Position = UDim2.new(0, 10, 0, 22)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "STOPPED"
    statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
    statusLabel.TextSize = 10
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    GUI.StatusLabel = statusLabel

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Toggle"
    toggleBtn.Size = UDim2.new(0, 30, 0, 30)
    toggleBtn.Position = UDim2.new(1, -38, 0.5, -15)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    toggleBtn.Text = ">"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 16
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = mainFrame
    GUI.ToggleBtn = toggleBtn

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        if Monitor then
            Monitor.Toggle()
        end
    end)

    GUI.ScreenGui = screenGui

    -- Parent GUI
    local ok = pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(screenGui) end
    end)

    local parented = pcall(function()
        if gethui then screenGui.Parent = gethui() return true end
    end)

    if not parented then
        parented = pcall(function()
            screenGui.Parent = game:GetService("CoreGui")
        end)
    end

    if not parented then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Update player count
    local function updateCount()
        local count = #Players:GetPlayers()
        local max = 6
        if Config and Config.MAX_PLAYERS then max = Config.MAX_PLAYERS end
        if GUI.PlayerCountLabel then
            GUI.PlayerCountLabel.Text = tostring(count) .. "/" .. tostring(max)
        end
    end

    Players.PlayerAdded:Connect(updateCount)
    Players.PlayerRemoving:Connect(updateCount)
    updateCount()

    return screenGui
end

function GUI.UpdateStatus(isRunning)
    if GUI.StatusLabel then
        if isRunning then
            GUI.StatusLabel.Text = "RUNNING"
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(80, 200, 80)
        else
            GUI.StatusLabel.Text = "STOPPED"
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
        end
    end
    if GUI.ToggleBtn then
        if isRunning then
            GUI.ToggleBtn.Text = "||"
            GUI.ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        else
            GUI.ToggleBtn.Text = ">"
            GUI.ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
        end
    end
end

function GUI.UpdatePlayerCount()
    local count = #Players:GetPlayers()
    local max = 6
    if Config and Config.MAX_PLAYERS then max = Config.MAX_PLAYERS end
    if GUI.PlayerCountLabel then
        GUI.PlayerCountLabel.Text = tostring(count) .. "/" .. tostring(max)
    end
end

function GUI.UpdateDisplay() end
function GUI.UpdateLog() end
function GUI.Show() if GUI.ScreenGui then GUI.ScreenGui.Enabled = true end end
function GUI.Hide() if GUI.ScreenGui then GUI.ScreenGui.Enabled = false end end
function GUI.Toggle() if GUI.ScreenGui then GUI.ScreenGui.Enabled = not GUI.ScreenGui.Enabled end end

return GUI
