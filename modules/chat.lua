--[[
    BSS Monitor - Chat Module
    Handles sending chat messages/commands
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Chat = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Try to get chat channel
local function getTextChannel()
    local success, result = pcall(function()
        return TextChatService:WaitForChild("TextChannels", 3):WaitForChild("RBXGeneral", 3)
    end)
    if success then
        return result
    end
    return nil
end

-- Try legacy chat remote
local function getLegacyChatRemote()
    local success, result = pcall(function()
        return ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 3):WaitForChild("SayMessageRequest", 3)
    end)
    if success then
        return result
    end
    return nil
end

-- Method: Use StarterGui SetCore to chat (most reliable for commands)
local function sendViaSetCore(message)
    local success, err = pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "",
            Color = Color3.new(1, 1, 1),
            Font = Enum.Font.SourceSansBold,
            TextSize = 18
        })
    end)
    
    -- The actual chat send via SetCore SendChatMessage
    local chatSuccess = pcall(function()
        StarterGui:SetCore("SendChatMessage", message)
    end)
    
    return chatSuccess
end

-- Method: Fire the chat bar directly (simulates typing and sending)
local function sendViaChatBar(message)
    local success = pcall(function()
        local chatGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not chatGui then return false end
        
        local chat = chatGui:FindFirstChild("Chat")
        if not chat then return false end
        
        local frame = chat:FindFirstChild("Frame")
        if not frame then return false end
        
        local chatBarParent = frame:FindFirstChild("ChatBarParentFrame")
        if not chatBarParent then return false end
        
        local chatBar = chatBarParent:FindFirstChild("Frame")
        if not chatBar then return false end
        
        local boxFrame = chatBar:FindFirstChild("BoxFrame")
        if not boxFrame then return false end
        
        local chatBox = boxFrame:FindFirstChild("ChatBar")
        if chatBox then
            chatBox.Text = message
            chatBox:CaptureFocus()
            task.wait(0.05)
            chatBox:ReleaseFocus(true)
            return true
        end
    end)
    return success
end

-- Method: TextChatService modern chat
local function sendViaTextChatService(message)
    local textChannel = getTextChannel()
    if textChannel then
        local success, err = pcall(function()
            textChannel:SendAsync(message)
        end)
        return success, "TextChatService"
    end
    return false, "No TextChannel"
end

-- Method: Legacy chat system
local function sendViaLegacyChat(message)
    local legacyRemote = getLegacyChatRemote()
    if legacyRemote then
        local success, err = pcall(function()
            legacyRemote:FireServer(message, "All")
        end)
        return success, "LegacyChat"
    end
    return false, "No legacy remote"
end

-- Method: Use firesignal if available (exploit-specific)
local function sendViaFireSignal(message)
    if not firesignal then
        return false, "firesignal not available"
    end
    
    local success = pcall(function()
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local sayRequest = chatEvents:FindFirstChild("SayMessageRequest")
            if sayRequest then
                firesignal(sayRequest.OnClientEvent, message, "All")
                return true
            end
        end
    end)
    return success, "FireSignal"
end

-- Method: Use hookmetamethod/getnamecallmethod if available
local function sendViaHook(message)
    if not hookmetamethod then
        return false, "hookmetamethod not available"
    end
    
    local success = pcall(function()
        local legacyRemote = getLegacyChatRemote()
        if legacyRemote then
            legacyRemote:FireServer(message, "All")
        end
    end)
    return success, "Hook"
end

-- Send a chat message (tries multiple methods)
function Chat.SendMessage(message)
    -- Method 1: SetCore (most reliable for admin commands)
    local setcoreSuccess = sendViaSetCore(message)
    if setcoreSuccess then
        return true, "SetCore"
    end
    
    -- Method 2: Chat bar simulation
    local chatBarSuccess = sendViaChatBar(message)
    if chatBarSuccess then
        return true, "ChatBar"
    end
    
    -- Method 3: Legacy chat system (most compatible)
    local legacySuccess, legacyMethod = sendViaLegacyChat(message)
    if legacySuccess then
        return true, legacyMethod
    end
    
    -- Method 4: TextChatService modern
    local textSuccess, textMethod = sendViaTextChatService(message)
    if textSuccess then
        return true, textMethod
    end
    
    -- Method 5: FireSignal (exploit-specific)
    local fireSuccess, fireMethod = sendViaFireSignal(message)
    if fireSuccess then
        return true, fireMethod
    end
    
    -- Method 6: Hook method (exploit-specific)
    local hookSuccess, hookMethod = sendViaHook(message)
    if hookSuccess then
        return true, hookMethod
    end
    
    return false, "All chat methods failed"
end

-- Send ban command
function Chat.SendBanCommand(username)
    local command = "/ban " .. username
    return Chat.SendMessage(command)
end

-- Send a regular message (for testing)
function Chat.SendTestMessage()
    return Chat.SendMessage("BSS Monitor: Chat test successful!")
end

-- Check if chat is available
function Chat.IsAvailable()
    -- Check SetCore
    local setcoreAvailable = pcall(function()
        return StarterGui:GetCore("ChatWindowPosition")
    end)
    if setcoreAvailable then
        return true, "SetCore"
    end
    
    local textChannel = getTextChannel()
    if textChannel then
        return true, "TextChatService"
    end
    
    local legacyRemote = getLegacyChatRemote()
    if legacyRemote then
        return true, "LegacyChat"
    end
    
    return false, "No chat available"
end

return Chat
