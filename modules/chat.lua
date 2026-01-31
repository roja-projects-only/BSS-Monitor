--[[
    BSS Monitor - Chat Module
    Handles sending chat messages/commands
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Chat = {}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- Get the chat input TextBox from CoreGui
local function getChatInputBox()
    local chatInput = nil
    
    -- Direct path to ExperienceChat TextBox
    pcall(function()
        local expChat = CoreGui:FindFirstChild("ExperienceChat")
        if expChat then
            for _, desc in pairs(expChat:GetDescendants()) do
                if desc:IsA("TextBox") and desc.Name == "TextBox" then
                    chatInput = desc
                    break
                end
            end
        end
    end)
    
    return chatInput
end

-- METHOD 1: CaptureFocus + ReleaseFocus (most natural, like pressing Enter)
local function sendViaReleaseFocus(message)
    local chatInput = getChatInputBox()
    if not chatInput then
        return false, "Chat input not found"
    end
    
    local success, err = pcall(function()
        chatInput:CaptureFocus()
        task.wait(0.2)
        chatInput.Text = message
        task.wait(0.2)
        chatInput:ReleaseFocus(true) -- true = enterPressed
    end)
    
    return success, err
end

-- METHOD 2: firesignal on FocusLost (bypass some filters)
local function sendViaFireSignal(message)
    if not firesignal then
        return false, "firesignal not available"
    end
    
    local chatInput = getChatInputBox()
    if not chatInput then
        return false, "Chat input not found"
    end
    
    local success, err = pcall(function()
        chatInput.Text = message
        firesignal(chatInput.FocusLost, true) -- true = enterPressed
    end)
    
    return success, err
end

-- METHOD 3: VirtualInputManager (simulates Enter key)
local function sendViaVirtualInput(message)
    local chatInput = getChatInputBox()
    if not chatInput then
        return false, "Chat input not found"
    end
    
    local success, err = pcall(function()
        chatInput:CaptureFocus()
        task.wait(0.2)
        chatInput.Text = message
        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)
    
    return success, err
end

-- Send a chat message (tries multiple methods)
function Chat.SendMessage(message)
    -- Method 1: ReleaseFocus (most reliable for commands)
    local success1, err1 = sendViaReleaseFocus(message)
    if success1 then
        return true, "ReleaseFocus"
    end
    
    -- Method 2: firesignal on FocusLost
    local success2, err2 = sendViaFireSignal(message)
    if success2 then
        return true, "FireSignal"
    end
    
    -- Method 3: VirtualInputManager
    local success3, err3 = sendViaVirtualInput(message)
    if success3 then
        return true, "VirtualInputManager"
    end
    
    return false, "All methods failed: " .. tostring(err1)
end

-- Send ban command
function Chat.SendBanCommand(username)
    local command = "/ban " .. username
    return Chat.SendMessage(command)
end

-- Send a regular message (for testing)
function Chat.SendTestMessage()
    return Chat.SendMessage("BSS Monitor: Chat test!")
end

-- Check if chat is available
function Chat.IsAvailable()
    local chatInput = getChatInputBox()
    if chatInput then
        return true, "CoreGui.ExperienceChat"
    end
    return false, "Chat input not found"
end

return Chat
