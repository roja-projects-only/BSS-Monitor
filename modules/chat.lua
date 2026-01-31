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

-- Send message via VirtualInputManager (simulates real typing + Enter)
local function sendViaVirtualInput(message)
    local chatInput = getChatInputBox()
    if not chatInput then
        return false, "Chat input not found"
    end
    
    local success, err = pcall(function()
        -- Focus the chat box
        chatInput:CaptureFocus()
        task.wait(0.1)
        
        -- Set the message text
        chatInput.Text = message
        task.wait(0.1)
        
        -- Simulate pressing Enter key
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)
    
    return success, err
end

-- Backup method: CaptureFocus + ReleaseFocus
local function sendViaReleaseFocus(message)
    local chatInput = getChatInputBox()
    if not chatInput then
        return false, "Chat input not found"
    end
    
    local success, err = pcall(function()
        chatInput:CaptureFocus()
        task.wait(0.1)
        chatInput.Text = message
        task.wait(0.1)
        chatInput:ReleaseFocus(true) -- true = enterPressed
    end)
    
    return success, err
end

-- Backup method: firesignal on FocusLost
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
        firesignal(chatInput.FocusLost, true)
    end)
    
    return success, err
end

-- Send a chat message (tries multiple methods)
function Chat.SendMessage(message)
    -- Method 1: VirtualInputManager (most reliable)
    local success1, err1 = sendViaVirtualInput(message)
    if success1 then
        return true, "VirtualInputManager"
    end
    
    -- Method 2: ReleaseFocus
    local success2, err2 = sendViaReleaseFocus(message)
    if success2 then
        return true, "ReleaseFocus"
    end
    
    -- Method 3: firesignal
    local success3, err3 = sendViaFireSignal(message)
    if success3 then
        return true, "FireSignal"
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
