--[[
    BSS Monitor - Webhook Module
    Handles Discord webhook notifications
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Webhook = {}

local HttpService = game:GetService("HttpService")

-- Helper: Make HTTP request (works with most executors)
local function httpRequest(options)
    -- Try different HTTP methods based on executor
    if request then
        return request(options)
    elseif http_request then
        return http_request(options)
    elseif syn and syn.request then
        return syn.request(options)
    elseif http and http.request then
        return http.request(options)
    elseif fluxus and fluxus.request then
        return fluxus.request(options)
    else
        warn("[Webhook] No HTTP method available")
        return nil
    end
end

-- Send a webhook message
function Webhook.Send(config, title, description, color, fields)
    if not config.WEBHOOK_ENABLED or config.WEBHOOK_URL == "" then
        return false, "Webhook disabled or URL not set"
    end
    
    local embed = {
        title = title,
        description = description,
        color = color or 16744576, -- Orange default
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = {
            text = "BSS Monitor"
        },
        fields = fields or {}
    }
    
    local data = {
        embeds = {embed}
    }
    
    local success, result = pcall(function()
        return httpRequest({
            Url = config.WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        })
    end)
    
    if success then
        return true, "Webhook sent"
    else
        return false, tostring(result)
    end
end

-- Pre-defined webhook messages
function Webhook.SendBanNotification(config, playerName, hiveData, checkResult)
    local fields = {
        {
            name = "Player",
            value = playerName,
            inline = true
        },
        {
            name = "Total Bees",
            value = tostring(hiveData.totalBees),
            inline = true
        },
        {
            name = "Average Level",
            value = string.format("%.1f", hiveData.avgLevel),
            inline = true
        },
        {
            name = "Bees at Lv" .. config.MINIMUM_LEVEL .. "+",
            value = string.format("%d (%.1f%%)", checkResult.beesAtLevel, checkResult.percentAtLevel * 100),
            inline = true
        },
        {
            name = "Required",
            value = string.format("%.0f%%", config.REQUIRED_PERCENT * 100),
            inline = true
        },
        {
            name = "Gifted Bees",
            value = tostring(hiveData.giftedCount),
            inline = true
        }
    }
    
    local title = "🚫 Player Banned"
    local description = string.format("**%s** has been banned for not meeting hive requirements.", playerName)
    local color = 15158332 -- Red
    
    if config.DRY_RUN then
        title = "⚠️ [DRY RUN] Would Ban Player"
        description = string.format("**%s** would be banned (DRY_RUN mode active)", playerName)
        color = 16776960 -- Yellow
    end
    
    return Webhook.Send(config, title, description, color, fields)
end

function Webhook.SendStartNotification(config)
    local fields = {
        {
            name = "Minimum Level",
            value = tostring(config.MINIMUM_LEVEL),
            inline = true
        },
        {
            name = "Required %",
            value = string.format("%.0f%%", config.REQUIRED_PERCENT * 100),
            inline = true
        },
        {
            name = "Check Interval",
            value = config.CHECK_INTERVAL .. "s",
            inline = true
        },
        {
            name = "Grace Period",
            value = config.GRACE_PERIOD .. "s",
            inline = true
        },
        {
            name = "DRY_RUN Mode",
            value = config.DRY_RUN and "✅ Enabled" or "❌ Disabled",
            inline = true
        },
        {
            name = "Whitelisted",
            value = tostring(#config.WHITELIST) .. " players",
            inline = true
        }
    }
    
    return Webhook.Send(config, "🐝 BSS Monitor Started", "Server monitoring has begun.", 3066993, fields)
end

function Webhook.SendStopNotification(config)
    return Webhook.Send(config, "🛑 BSS Monitor Stopped", "Server monitoring has been stopped.", 10038562, {})
end

function Webhook.SendPlayerPassedNotification(config, playerName, hiveData, checkResult)
    local fields = {
        {
            name = "Player",
            value = playerName,
            inline = true
        },
        {
            name = "Bees at Lv" .. config.MINIMUM_LEVEL .. "+",
            value = string.format("%d (%.1f%%)", checkResult.beesAtLevel, checkResult.percentAtLevel * 100),
            inline = true
        },
        {
            name = "Average Level",
            value = string.format("%.1f", hiveData.avgLevel),
            inline = true
        }
    }
    
    return Webhook.Send(config, "✅ Player Passed Check", string.format("**%s** meets requirements.", playerName), 3066993, fields)
end

return Webhook
