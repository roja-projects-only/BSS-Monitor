--[[
    BSS Monitor - Chat Module
    Handles sending chat messages/commands
    https://github.com/roja-projects-only/BSS-Monitor
    
    VirtualInputManager now works on both desktop and mobile.
    On mobile, if VIM fails the monitor falls back to webhook notification.
]]

local Chat = {}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Detect platform with multiple signals for reliability
local isMobile = nil

local function detectMobile()
    -- Signal 1: Touch + no keyboard (standard check)
    local touch = UserInputService.TouchEnabled
    local keyboard = UserInputService.KeyboardEnabled
    if touch == true and keyboard == false then
        return true
    end
    if touch == false then
        return false
    end

    -- Signal 2: GuiService - IsTenFootInterface means console, not mobile
    local isTenFoot = false
    pcall(function() isTenFoot = GuiService.IsTenFootInterface end)
    if isTenFoot then
        return false
    end

    -- Signal 3: Screen size heuristic (mobile screens are small)
    local viewportX = nil
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then viewportX = cam.ViewportSize.X end
    end)
    if viewportX then
        if viewportX < 800 then return true end
        if viewportX > 1200 and keyboard ~= false then return false end
    end

    -- Signal 4: Mouse presence
    local hasMouse = UserInputService.MouseEnabled
    if hasMouse == true and touch ~= true then
        return false
    end

    -- Signal 5: Gyroscope (only present on mobile devices)
    local hasGyro = false
    pcall(function() hasGyro = UserInputService.GyroscopeEnabled end)
    if hasGyro == true then
        return true
    end

    -- Signal 6: Gamepad (if gamepad only, it's console, not mobile)
    local hasGamepad = UserInputService.GamepadEnabled
    if hasGamepad == true and touch ~= true then
        return false
    end

    -- Fallback: if touch is true and we couldn't disprove mobile, assume mobile
    if touch == true then
        return true
    end

    -- Default to desktop
    return false
end

isMobile = detectMobile()

-- Re-check after a short delay in case services weren't ready at load time
task.defer(function()
    task.wait(1)
    local recheck = detectMobile()
    if recheck ~= isMobile then
        isMobile = recheck
        print("[BSS Monitor] Platform re-detected: " .. (isMobile and "Mobile" or "Desktop"))
    end
end)

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

-- VirtualInputManager method (works on both desktop and mobile)
local function sendViaVirtualInput(message)
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

-- Send a chat message (always tries VirtualInputManager first)
function Chat.SendMessage(message)
    local success, err = sendViaVirtualInput(message)
    if success then
        return true, "VirtualInputManager"
    end
    return false, "Send failed: " .. tostring(err)
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

-- Override for Config.MOBILE_MODE (set externally after load)
Chat.MobileOverride = nil

-- Check platform (respects forced override)
function Chat.IsMobile()
    if Chat.MobileOverride ~= nil then
        return Chat.MobileOverride
    end
    return isMobile
end

-- Get platform name
function Chat.GetPlatform()
    return Chat.IsMobile() and "Mobile" or "Desktop"
end

return Chat
