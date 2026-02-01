--[[
    BSS Monitor - Bridge Module
    Mobile Automation Bridge HTTP client
    https://github.com/roja-projects-only/BSS-Monitor
    
    Sends kick/ban commands to bridge server for mobile automation.
    Falls back to clipboard mode if bridge is unavailable.
]]

local Bridge = {}

local HttpService = game:GetService("HttpService")

-- State
local Config = nil
local isInitialized = false
local isAvailable = false

-- Initialize bridge with configuration
function Bridge.Init(config)
    Config = config
    isInitialized = true
    
    -- Validate configuration
    if not Config.BRIDGE_ENABLED then
        isAvailable = false
        return true -- Not an error, just disabled
    end
    
    if not Config.BRIDGE_URL or Config.BRIDGE_URL == "" then
        warn("[Bridge] BRIDGE_URL not configured")
        isAvailable = false
        return false
    end
    
    -- Ensure URL doesn't end with slash
    if Config.BRIDGE_URL:sub(-1) == "/" then
        Config.BRIDGE_URL = Config.BRIDGE_URL:sub(1, -2)
    end
    
    -- Validate URL format
    if not Config.BRIDGE_URL:match("^https?://") then
        warn("[Bridge] BRIDGE_URL must start with http:// or https://")
        isAvailable = false
        return false
    end
    
    -- API key is optional (for development)
    if not Config.BRIDGE_API_KEY or Config.BRIDGE_API_KEY == "" then
        warn("[Bridge] BRIDGE_API_KEY not set - using development mode")
    end
    
    -- Set timeout default
    if not Config.BRIDGE_TIMEOUT or Config.BRIDGE_TIMEOUT <= 0 then
        Config.BRIDGE_TIMEOUT = 5
    end
    
    isAvailable = true
    print("[Bridge] Initialized - URL:", Config.BRIDGE_URL)
    return true
end

-- Check if bridge is available
function Bridge.IsAvailable()
    return isInitialized and isAvailable and Config and Config.BRIDGE_ENABLED
end

-- Make HTTP request with fallbacks
local function makeHttpRequest(options)
    local methods = {
        -- Try request first (most common)
        function() return request(options) end,
        -- Try syn.request (Synapse)
        function() return syn and syn.request and syn.request(options) end,
        -- Try http_request (some executors)
        function() return http_request and http_request(options) end,
        -- Try HttpService (if enabled)
        function()
            if HttpService.HttpEnabled then
                local response = HttpService:RequestAsync(options)
                return {
                    StatusCode = response.StatusCode,
                    Body = response.Body,
                    Headers = response.Headers,
                    Success = response.Success
                }
            end
            return nil
        end
    }
    
    local lastError = nil
    
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            return result, nil
        else
            lastError = result or "Method not available"
        end
    end
    
    return nil, lastError
end

-- Send command to bridge server
function Bridge.SendCommand(commandType, playerName)
    if not Bridge.IsAvailable() then
        return false, "Bridge not available"
    end
    
    -- Validate inputs
    if not commandType or (commandType ~= "kick" and commandType ~= "ban") then
        return false, "Invalid command type: " .. tostring(commandType)
    end
    
    if not playerName or playerName == "" then
        return false, "Player name is required"
    end
    
    -- Prepare request
    local requestBody = {
        type = commandType,
        player = playerName,
        timestamp = os.time()
    }
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    -- Add API key if configured
    if Config.BRIDGE_API_KEY and Config.BRIDGE_API_KEY ~= "" then
        headers["X-API-Key"] = Config.BRIDGE_API_KEY
    end
    
    local options = {
        Url = Config.BRIDGE_URL .. "/api/command",
        Method = "POST",
        Headers = headers,
        Body = HttpService:JSONEncode(requestBody),
        Timeout = Config.BRIDGE_TIMEOUT
    }
    
    -- First attempt
    local response, error = makeHttpRequest(options)
    
    if response and response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300 then
        print("[Bridge] Command sent successfully:", commandType, playerName)
        return true, "Success"
    end
    
    -- Handle specific error codes
    if response and response.StatusCode then
        if response.StatusCode == 401 then
            warn("[Bridge] Authentication failed - check API key")
            isAvailable = false -- Disable bridge on auth failure
            return false, "Authentication failed"
        elseif response.StatusCode == 409 then
            -- Duplicate command - this is actually success
            print("[Bridge] Duplicate command ignored:", commandType, playerName)
            return true, "Duplicate (ignored)"
        elseif response.StatusCode >= 400 and response.StatusCode < 500 then
            warn("[Bridge] Client error:", response.StatusCode, response.Body or "")
            return false, "Client error: " .. response.StatusCode
        elseif response.StatusCode >= 500 then
            warn("[Bridge] Server error:", response.StatusCode, response.Body or "")
            -- Don't disable bridge on server errors, might be temporary
        end
    end
    
    -- Single retry on network/server errors
    warn("[Bridge] First attempt failed, retrying... Error:", error or "Unknown")
    task.wait(1) -- Brief delay before retry
    
    response, error = makeHttpRequest(options)
    
    if response and response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300 then
        print("[Bridge] Command sent successfully on retry:", commandType, playerName)
        return true, "Success (retry)"
    end
    
    -- Both attempts failed
    local errorMsg = "Network error"
    if response and response.StatusCode then
        errorMsg = "HTTP " .. response.StatusCode
    elseif error then
        errorMsg = tostring(error)
    end
    
    warn("[Bridge] Failed to send command after retry:", errorMsg)
    return false, errorMsg
end

-- Test connection to bridge server
function Bridge.TestConnection()
    if not Bridge.IsAvailable() then
        return false, 0, "Bridge not available"
    end
    
    local startTime = tick()
    
    local headers = {}
    if Config.BRIDGE_API_KEY and Config.BRIDGE_API_KEY ~= "" then
        headers["X-API-Key"] = Config.BRIDGE_API_KEY
    end
    
    local options = {
        Url = Config.BRIDGE_URL .. "/api/status",
        Method = "GET",
        Headers = headers,
        Timeout = Config.BRIDGE_TIMEOUT
    }
    
    local response, error = makeHttpRequest(options)
    local latency = math.floor((tick() - startTime) * 1000) -- Convert to milliseconds
    
    if response and response.StatusCode == 200 then
        print("[Bridge] Connection test successful - Latency:", latency .. "ms")
        return true, latency, "Connected"
    else
        local errorMsg = "Connection failed"
        if response and response.StatusCode then
            errorMsg = "HTTP " .. response.StatusCode
        elseif error then
            errorMsg = tostring(error)
        end
        warn("[Bridge] Connection test failed:", errorMsg)
        return false, latency, errorMsg
    end
end

-- Get bridge status
function Bridge.GetStatus()
    return {
        initialized = isInitialized,
        available = isAvailable,
        enabled = Config and Config.BRIDGE_ENABLED or false,
        url = Config and Config.BRIDGE_URL or "",
        hasApiKey = Config and Config.BRIDGE_API_KEY and Config.BRIDGE_API_KEY ~= "" or false,
        timeout = Config and Config.BRIDGE_TIMEOUT or 5
    }
end

return Bridge