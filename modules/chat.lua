--[[
    BSS Monitor - Chat Module
    Handles sending chat messages/commands
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Chat = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

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

-- Send a chat message
function Chat.SendMessage(message)
    -- Method 1: TextChatService (modern)
    local textChannel = getTextChannel()
    if textChannel then
        local success, err = pcall(function()
            textChannel:SendAsync(message)
        end)
        if success then
            return true, "TextChatService"
        end
    end
    
    -- Method 2: Legacy chat system
    local legacyRemote = getLegacyChatRemote()
    if legacyRemote then
        local success, err = pcall(function()
            legacyRemote:FireServer(message, "All")
        end)
        if success then
            return true, "LegacyChat"
        end
    end
    
    -- Method 3: Direct chat (firesignal if available)
    if firesignal then
        local success, err = pcall(function()
            local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvent then
                local sayRequest = chatEvent:FindFirstChild("SayMessageRequest")
                if sayRequest then
                    firesignal(sayRequest.OnClientEvent, message, "All")
                    return true
                end
            end
        end)
        if success then
            return true, "FireSignal"
        end
    end
    
    return false, "No chat method available"
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
