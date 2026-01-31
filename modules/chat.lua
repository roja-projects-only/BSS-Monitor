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

-- METHOD 1: Fire Player.Chatted event directly (exploit-specific, most reliable for commands)
local function sendViaChattedEvent(message)
    -- This fires the Chatted event which servers listen to for commands
    if firesignal then
        local success = pcall(function()
            firesignal(LocalPlayer.Chatted, message)
        end)
        if success then
            return true
        end
    end
    
    -- Alternative: use fireclickdetector pattern
    if fireproximityprompt then
        -- Some executors support this
    end
    
    return false
end

-- METHOD 2: Legacy chat remote (works on older games)
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

-- METHOD 3: TextChatService modern chat
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

-- METHOD 4: Use StarterGui SetCore
local function sendViaSetCore(message)
    local success = pcall(function()
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[You]: " .. message,
            Color = Color3.new(1, 1, 1),
            Font = Enum.Font.SourceSansBold,
            TextSize = 18
        })
    end)
    return success
end

-- METHOD 5: Simulate chat bar input
local function sendViaChatBar(message)
    local success = pcall(function()
        -- Try to find and use the chat bar directly
        local chatGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not chatGui then return false end
        
        -- Look for TextChatService input
        local chatInputBar = chatGui:FindFirstChild("ExperienceChat")
        if chatInputBar then
            local chatInput = chatInputBar:FindFirstChild("chatInputBar", true)
            if chatInput and chatInput:IsA("TextBox") then
                chatInput.Text = message
                chatInput:CaptureFocus()
                task.wait(0.05)
                chatInput:ReleaseFocus(true)
                return true
            end
        end
        
        -- Legacy chat bar
        local chat = chatGui:FindFirstChild("Chat")
        if chat then
            local frame = chat:FindFirstChild("Frame")
            if frame then
                local chatBarParent = frame:FindFirstChild("ChatBarParentFrame")
                if chatBarParent then
                    local chatBar = chatBarParent:FindFirstChild("Frame")
                    if chatBar then
                        local boxFrame = chatBar:FindFirstChild("BoxFrame")
                        if boxFrame then
                            local chatBox = boxFrame:FindFirstChild("ChatBar")
                            if chatBox then
                                chatBox.Text = message
                                chatBox:CaptureFocus()
                                task.wait(0.05)
                                chatBox:ReleaseFocus(true)
                                return true
                            end
                        end
                    end
                end
            end
        end
    end)
    return success
end

-- METHOD 6: Fire using getconnections (exploit-specific)
local function sendViaGetConnections(message)
    if not getconnections then
        return false
    end
    
    local success = pcall(function()
        for _, connection in pairs(getconnections(LocalPlayer.Chatted)) do
            if connection.Function then
                connection.Function(message)
            end
        end
    end)
    return success
end

-- Send a chat message (tries multiple methods)
function Chat.SendMessage(message)
    local methods = {}
    
    -- Method 1: Fire Chatted event directly (best for commands)
    local chattedSuccess = sendViaChattedEvent(message)
    if chattedSuccess then
        table.insert(methods, "Chatted")
    end
    
    -- Method 2: getconnections
    local connectionsSuccess = sendViaGetConnections(message)
    if connectionsSuccess then
        table.insert(methods, "Connections")
    end
    
    -- Method 3: Legacy chat 
    local legacySuccess = sendViaLegacyChat(message)
    if legacySuccess then
        table.insert(methods, "LegacyChat")
    end
    
    -- Method 4: TextChatService
    local textSuccess = sendViaTextChatService(message)
    if textSuccess then
        table.insert(methods, "TextChatService")
    end
    
    -- Method 5: ChatBar simulation
    local chatBarSuccess = sendViaChatBar(message)
    if chatBarSuccess then
        table.insert(methods, "ChatBar")
    end
    
    if #methods > 0 then
        return true, table.concat(methods, "+")
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
    return Chat.SendMessage("BSS Monitor: Chat test!")
end

-- Check what chat methods are available
function Chat.GetAvailableMethods()
    local available = {}
    
    if firesignal then
        table.insert(available, "firesignal")
    end
    
    if getconnections then
        table.insert(available, "getconnections")
    end
    
    local legacyRemote = getLegacyChatRemote()
    if legacyRemote then
        table.insert(available, "LegacyChat")
    end
    
    local textChannel = getTextChannel()
    if textChannel then
        table.insert(available, "TextChatService")
    end
    
    return available
end

-- Check if chat is available
function Chat.IsAvailable()
    local methods = Chat.GetAvailableMethods()
    if #methods > 0 then
        return true, table.concat(methods, ", ")
    end
    return false, "No chat methods available"
end

return Chat
