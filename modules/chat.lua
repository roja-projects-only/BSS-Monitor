--[[
    BSS Monitor - Chat Module
    Handles sending chat messages/commands
    https://github.com/roja-projects-only/BSS-Monitor
    
    NOTE: Mobile cannot auto-send chat due to Roblox server-side validation.
    On mobile, use clipboard mode (auto-copies command for manual paste).
]]

local Chat = {}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- Detect platform
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Get the chat input TextBox from CoreGui
local function getChatInputBox()
    local chatInput = nil
    
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

-- Desktop method: VirtualInputManager (confirmed working on PC)
local function sendViaVirtualInput(message)
    if isMobile then
        return false, "VirtualInputManager doesn't work on mobile"
    end
    
    local chatInput = getChatInputBox()
    if not chatInput then
        return false, "Chat input not found"
    end
    
    local VirtualInputManager = game:GetService("VirtualInputManager")
    
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

-- Mobile method: Copy to clipboard (user must paste manually)
local function copyToClipboard(message)
    if not setclipboard then
        return false, "setclipboard not available"
    end
    
    local success, err = pcall(function()
        setclipboard(message)
    end)
    
    return success, err
end

-- Mobile method: Pre-fill chat input (user just presses send)
local function prefillChatInput(message)
    local chatInput = getChatInputBox()
    if not chatInput then
        return false, "Chat input not found"
    end
    
    local success, err = pcall(function()
        chatInput:CaptureFocus()
        task.wait(0.1)
        chatInput.Text = message
        -- Don't send - user will manually press enter/send
    end)
    
    return success, err
end

-- Send a chat message (platform-aware)
function Chat.SendMessage(message)
    if isMobile then
        -- Mobile: Copy to clipboard + prefill
        local clipSuccess = copyToClipboard(message)
        local prefillSuccess = prefillChatInput(message)
        
        if clipSuccess or prefillSuccess then
            return true, "Mobile (clipboard + prefill)"
        end
        return false, "Mobile send failed"
    else
        -- Desktop: Use VirtualInputManager
        local success, err = sendViaVirtualInput(message)
        if success then
            return true, "VirtualInputManager"
        end
        return false, "Desktop send failed: " .. tostring(err)
    end
end

-- Send kick command
function Chat.SendKickCommand(username)
    local command = "/kick " .. username
    return Chat.SendMessage(command)
end

-- Send ban command
function Chat.SendBanCommand(username)
    local command = "/ban " .. username
    return Chat.SendMessage(command)
end

-- Copy kick command to clipboard only (for notification mode)
function Chat.CopyKickCommand(username)
    local command = "/kick " .. username
    return copyToClipboard(command)
end

-- Copy ban command to clipboard only
function Chat.CopyBanCommand(username)
    local command = "/ban " .. username
    return copyToClipboard(command)
end

-- Prefill kick command in chat (user sends manually)
function Chat.PrefillKickCommand(username)
    local command = "/kick " .. username
    return prefillChatInput(command)
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

-- Check platform
function Chat.IsMobile()
    return isMobile
end

-- Get platform name
function Chat.GetPlatform()
    return isMobile and "Mobile" or "Desktop"
end

return Chat
