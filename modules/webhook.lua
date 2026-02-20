--[[
    BSS Monitor - Webhook Module
    Handles Discord webhook notifications
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Webhook = {}

local HttpService = game:GetService("HttpService")

-- Helper: Make HTTP request (works with most executors)
local function httpRequest(options)
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

-- Discord colors
local COLORS = {
    RED = 0xED4245,
    GREEN = 0x57F287,
    YELLOW = 0xFEE75C,
    ORANGE = 0xE67E22,
    BLUE = 0x5865F2,
    GOLD = 0xF1C40F,
    DARK = 0x2F3136,
}

-- Send a webhook message
-- content: optional text outside embed (used for @mentions that trigger mobile push notifications)
function Webhook.Send(config, embeds, content)
    if not config.WEBHOOK_ENABLED or config.WEBHOOK_URL == "" then
        return false, "Webhook disabled or URL not set"
    end
    
    -- Support single embed table or array of embeds
    if embeds.title or embeds.description then
        embeds = {embeds}
    end
    
    -- Add timestamp + footer to all embeds
    for _, embed in ipairs(embeds) do
        embed.timestamp = embed.timestamp or os.date("!%Y-%m-%dT%H:%M:%SZ")
        if not embed.footer then
            embed.footer = { text = "BSS Monitor 🐝" }
        end
    end
    
    local data = { embeds = embeds }
    if content and content ~= "" then
        data.content = content
    end
    
    local success, result = pcall(function()
        return httpRequest({
            Url = config.WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end)
    
    if success then
        return true, "Webhook sent"
    else
        return false, tostring(result)
    end
end

-- ═══════════════════════════════════════
-- BAN NOTIFICATION (auto-ban success)
-- ═══════════════════════════════════════
function Webhook.SendBanNotification(config, playerName, hiveData, checkResult)
    local pct = checkResult.percentAtLevel * 100
    local reqPct = config.REQUIRED_PERCENT * 100
    
    local embed = {
        title = config.DRY_RUN and "⚠️  DRY RUN — Would Ban" or "🔨  Player Banned",
        color = config.DRY_RUN and COLORS.YELLOW or COLORS.RED,
        description = string.format(
            ">>> **%s** was removed for not meeting requirements.",
            playerName
        ),
        fields = {
            {
                name = "📊 Hive Stats",
                value = string.format(
                    "```\n🐝 Bees: %d   ⭐ Gifted: %d\n📈 Avg Level: %.1f\n```",
                    hiveData.totalBees, hiveData.giftedCount, hiveData.avgLevel
                ),
                inline = false
            },
            {
                name = "❌ Requirement",
                value = string.format(
                    "`%.0f%%` at LVL %d+ — needed `%.0f%%`",
                    pct, config.MINIMUM_LEVEL, reqPct
                ),
                inline = false
            },
        },
    }
    
    if config.DRY_RUN then
        embed.description = string.format(
            ">>> **%s** would be banned — DRY RUN active, no action taken.",
            playerName
        )
    end
    
    return Webhook.Send(config, embed)
end

-- ═══════════════════════════════════════
-- MOBILE BAN FALLBACK (VIM failed, need manual ban)
-- ═══════════════════════════════════════
function Webhook.SendMobileBanNotification(config, playerName, hiveData, checkResult)
    local pct = checkResult.percentAtLevel * 100
    local reqPct = config.REQUIRED_PERCENT * 100
    local command = "/ban " .. playerName
    
    local embed = {
        title = "🚨  Action Required — Ban Player",
        color = COLORS.RED,
        description = string.format(
            ">>> Auto-ban failed for **%s**. Use the command below to ban manually.",
            playerName
        ),
        fields = {
            {
                name = "📱 Mobile — Tap to Copy",
                value = "`" .. command .. "`",
                inline = false
            },
            {
                name = "🖥️ Desktop",
                value = "```\n" .. command .. "\n```",
                inline = false
            },
            {
                name = "📊 Hive Stats",
                value = string.format(
                    "`🐝 %d bees` · `⭐ %d gifted` · `📈 Avg LVL %.1f`",
                    hiveData.totalBees, hiveData.giftedCount, hiveData.avgLevel
                ),
                inline = false
            },
            {
                name = "❌ Requirement",
                value = string.format(
                    "`%.0f%%` at LVL %d+ — needed `%.0f%%`",
                    pct, config.MINIMUM_LEVEL, reqPct
                ),
                inline = false
            },
        },
    }
    
    if config.DRY_RUN then
        embed.title = "⚠️  DRY RUN — Would Need Manual Ban"
        embed.color = COLORS.YELLOW
    end
    
    -- @mention outside embed triggers mobile push notification
    local content = nil
    if config.DISCORD_USER_ID and config.DISCORD_USER_ID ~= "" then
        content = "<@" .. config.DISCORD_USER_ID .. ">"
    end
    
    return Webhook.Send(config, embed, content)
end

-- ═══════════════════════════════════════
-- MONITOR START
-- ═══════════════════════════════════════
function Webhook.SendStartNotification(config)
    local embed = {
        title = "🟢  Monitor Started",
        color = COLORS.GREEN,
        description = "BSS Monitor is now watching this server.",
        fields = {
            {
                name = "⚙️ Settings",
                value = string.format(
                    "```\nMin Level    : LVL %d\nRequired     : %.0f%%\nInterval     : %ds\nGrace Period : %ds\nDry Run      : %s\nWhitelisted  : %d players\n```",
                    config.MINIMUM_LEVEL,
                    config.REQUIRED_PERCENT * 100,
                    config.CHECK_INTERVAL,
                    config.GRACE_PERIOD,
                    config.DRY_RUN and "Yes" or "No",
                    #config.WHITELIST
                ),
                inline = false
            },
        },
    }
    
    return Webhook.Send(config, embed)
end

-- ═══════════════════════════════════════
-- MONITOR STOP
-- ═══════════════════════════════════════
function Webhook.SendStopNotification(config)
    local embed = {
        title = "🔴  Monitor Stopped",
        color = COLORS.RED,
        description = "Server monitoring has been stopped.",
    }
    
    return Webhook.Send(config, embed)
end

-- ═══════════════════════════════════════
-- PLAYER PASSED CHECK (optional, not called by default)
-- ═══════════════════════════════════════
function Webhook.SendPlayerPassedNotification(config, playerName, hiveData, checkResult)
    local embed = {
        title = "✅  Player OK",
        color = COLORS.GREEN,
        description = string.format(
            "**%s** meets hive requirements.\n`%.0f%%` at LVL %d+ · `Avg LVL %.1f`",
            playerName,
            checkResult.percentAtLevel * 100,
            config.MINIMUM_LEVEL,
            hiveData.avgLevel
        ),
    }
    
    return Webhook.Send(config, embed)
end

-- ═══════════════════════════════════════
-- BAN FAILED
-- ═══════════════════════════════════════
function Webhook.SendBanFailedNotification(config, playerName, reason, attempts)
    local embed = {
        title = "⚠️  Ban Failed",
        color = COLORS.ORANGE,
        description = string.format(
            ">>> Could not remove **%s** after **%d** attempt%s.\nPlayer is still in the server.",
            playerName, attempts or 1, (attempts or 1) > 1 and "s" or ""
        ),
        fields = {
            {
                name = "Reason",
                value = "`" .. (reason or "Unknown") .. "`",
                inline = true
            },
            {
                name = "Attempts",
                value = "`" .. tostring(attempts or 1) .. "`",
                inline = true
            },
        },
    }
    
    return Webhook.Send(config, embed)
end

-- ═══════════════════════════════════════
-- BAN VERIFIED
-- ═══════════════════════════════════════
function Webhook.SendBanVerifiedNotification(config, playerName, reason, attempts)
    local embed = {
        title = "✅  Ban Confirmed",
        color = COLORS.GREEN,
        description = string.format(
            "**%s** has left the server.",
            playerName
        ),
        fields = {
            {
                name = "Reason",
                value = "`" .. (reason or "Unknown") .. "`",
                inline = true
            },
            {
                name = "Attempts",
                value = "`" .. tostring(attempts or 1) .. "`",
                inline = true
            },
        },
    }
    
    return Webhook.Send(config, embed)
end

return Webhook
