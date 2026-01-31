--[[
    BSS Monitor - GUI Module
    https://github.com/roja-projects-only/BSS-Monitor
]]

local GUI = {}
GUI.ScreenGui = nil
GUI.StatusLabel = nil
GUI.PlayerCountLabel = nil
GUI.ToggleBtn = nil

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
        if GUI.ScreenGui then
            GUI.ScreenGui:Destroy()
        end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BSSMonitorGui"
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 120, 0, 35)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -17)
    mainFrame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.1)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.new(1, 0.7, 0)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local playerCount = Instance.new("TextLabel")
    playerCount.Name = "PlayerCount"
    playerCount.Size = UDim2.new(0, 50, 0, 18)
    playerCount.Position = UDim2.new(0, 8, 0, 2)
    playerCount.BackgroundTransparency = 1
    playerCount.Text = "0/6"
    playerCount.TextColor3 = Color3.new(1, 1, 1)
    playerCount.TextSize = 14
    playerCount.Font = Enum.Font.SourceSansBold
    playerCount.TextXAlignment = Enum.TextXAlignment.Left
    playerCount.Parent = mainFrame
    GUI.PlayerCountLabel = playerCount

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(0, 50, 0, 12)
    statusLabel.Position = UDim2.new(0, 8, 0, 20)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "STOPPED"
    statusLabel.TextColor3 = Color3.new(0.8, 0.3, 0.3)
    statusLabel.TextSize = 10
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    GUI.StatusLabel = statusLabel

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Toggle"
    toggleBtn.Size = UDim2.new(0, 25, 0, 25)
    toggleBtn.Position = UDim2.new(1, -32, 0.5, -12)
    toggleBtn.BackgroundColor3 = Color3.new(0.3, 0.8, 0.3)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ">"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextSize = 14
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.Parent = mainFrame
    GUI.ToggleBtn = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        if Monitor then
            Monitor.Toggle()
        end
    end)

    GUI.ScreenGui = screenGui

    pcall(function()
        if gethui then
            screenGui.Parent = gethui()
            return
        end
    end)

    pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)

    if not screenGui.Parent then
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    local function updateCount()
        pcall(function()
            local count = #Players:GetPlayers()
            local max = Config and Config.MAX_PLAYERS or 6
            GUI.PlayerCountLabel.Text = count .. "/" .. max
        end)
    end

    Players.PlayerAdded:Connect(updateCount)
    Players.PlayerRemoving:Connect(updateCount)
    updateCount()

    return screenGui
end

function GUI.UpdateStatus(isRunning)
    pcall(function()
        if isRunning then
            GUI.StatusLabel.Text = "RUNNING"
            GUI.StatusLabel.TextColor3 = Color3.new(0.3, 0.8, 0.3)
            GUI.ToggleBtn.Text = "||"
            GUI.ToggleBtn.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3)
        else
            GUI.StatusLabel.Text = "STOPPED"
            GUI.StatusLabel.TextColor3 = Color3.new(0.8, 0.3, 0.3)
            GUI.ToggleBtn.Text = ">"
            GUI.ToggleBtn.BackgroundColor3 = Color3.new(0.3, 0.8, 0.3)
        end
    end)
end

function GUI.UpdatePlayerCount()
    pcall(function()
        local count = #Players:GetPlayers()
        local max = Config and Config.MAX_PLAYERS or 6
        GUI.PlayerCountLabel.Text = count .. "/" .. max
    end)
end

function GUI.UpdateDisplay() end
function GUI.UpdateLog() end
function GUI.Show() pcall(function() GUI.ScreenGui.Enabled = true end) end
function GUI.Hide() pcall(function() GUI.ScreenGui.Enabled = false end) end
function GUI.Toggle() pcall(function() GUI.ScreenGui.Enabled = not GUI.ScreenGui.Enabled end) end

return GUI
