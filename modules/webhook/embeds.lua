--[[
    BSS Monitor - Webhook Embeds
    All Discord notification embed builders
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Embeds = {}

-- Dependencies (set by Init)
local Http

function Embeds.Init(http)
    Http = http
    return Embeds
end

local function C()
    return Http.COLORS
end

-- ═══════════════════════════════════════
-- PLAYER JOIN
-- ═══════════════════════════════════════
function Embeds.SendPlayerJoinNotification(config, playerName, playerCount, maxPlayers)
    local embed = {
        title = "\xF0\x9F\x93\xA5  Player Joined",
        color = C().BLUE,
        description = string.format("**%s** joined the server.", playerName),
        fields = {
            {
                name = "\xF0\x9F\x91\xA5 Players",
                value = string.format("`%d / %d`", playerCount, maxPlayers),
                inline = true
            },
        },
    }
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- PLAYER LEAVE (natural leave only, not bans)
-- ═══════════════════════════════════════
function Embeds.SendPlayerLeaveNotification(config, playerName, playerCount, maxPlayers)
    local embed = {
        title = "\xF0\x9F\x93\xA4  Player Left",
        color = C().DARK,
        description = string.format("**%s** left the server.", playerName),
        fields = {
            {
                name = "\xF0\x9F\x91\xA5 Players",
                value = string.format("`%d / %d`", playerCount, maxPlayers),
                inline = true
            },
        },
    }
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- BAN NOTIFICATION (auto-ban success)
-- ═══════════════════════════════════════
function Embeds.SendBanNotification(config, playerName, hiveData, checkResult)
    local pct = checkResult.percentAtLevel * 100
    local reqPct = config.REQUIRED_PERCENT * 100

    local embed = {
        title = config.DRY_RUN and "\xE2\x9A\xA0\xEF\xB8\x8F  DRY RUN \xE2\x80\x94 Would Ban" or "\xF0\x9F\x94\xA8  Player Banned",
        color = config.DRY_RUN and C().YELLOW or C().RED,
        description = string.format(
            ">>> **%s** was removed for not meeting requirements.",
            playerName
        ),
        fields = {
            {
                name = "\xF0\x9F\x93\x8A Hive Stats",
                value = string.format(
                    "```\n\xF0\x9F\x90\x9D Bees: %d   \xE2\xAD\x90 Gifted: %d\n\xF0\x9F\x93\x88 Avg Level: %.1f\n```",
                    hiveData.totalBees, hiveData.giftedCount, hiveData.avgLevel
                ),
                inline = false
            },
            {
                name = "\xE2\x9D\x8C Requirement",
                value = string.format(
                    "`%.0f%%` at LVL %d+ \xE2\x80\x94 needed `%.0f%%`",
                    pct, config.MINIMUM_LEVEL, reqPct
                ),
                inline = false
            },
        },
    }

    if config.DRY_RUN then
        embed.description = string.format(
            ">>> **%s** would be banned \xE2\x80\x94 DRY RUN active, no action taken.",
            playerName
        )
    end

    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- MOBILE BAN FALLBACK (VIM failed, need manual ban)
-- ═══════════════════════════════════════
function Embeds.SendMobileBanNotification(config, playerName, hiveData, checkResult)
    local pct = checkResult.percentAtLevel * 100
    local reqPct = config.REQUIRED_PERCENT * 100
    local command = "/ban " .. playerName

    local embed = {
        title = "\xF0\x9F\x9A\xA8  Action Required \xE2\x80\x94 Ban Player",
        color = C().RED,
        description = string.format(
            ">>> Auto-ban failed for **%s**. Use the command below to ban manually.",
            playerName
        ),
        fields = {
            {
                name = "\xF0\x9F\x93\xB1 Mobile \xE2\x80\x94 Tap to Copy",
                value = "`" .. command .. "`",
                inline = false
            },
            {
                name = "\xF0\x9F\x96\xA5\xEF\xB8\x8F Desktop",
                value = "```\n" .. command .. "\n```",
                inline = false
            },
            {
                name = "\xF0\x9F\x93\x8A Hive Stats",
                value = string.format(
                    "`\xF0\x9F\x90\x9D %d bees` \xC2\xB7 `\xE2\xAD\x90 %d gifted` \xC2\xB7 `\xF0\x9F\x93\x88 Avg LVL %.1f`",
                    hiveData.totalBees, hiveData.giftedCount, hiveData.avgLevel
                ),
                inline = false
            },
            {
                name = "\xE2\x9D\x8C Requirement",
                value = string.format(
                    "`%.0f%%` at LVL %d+ \xE2\x80\x94 needed `%.0f%%`",
                    pct, config.MINIMUM_LEVEL, reqPct
                ),
                inline = false
            },
        },
    }

    if config.DRY_RUN then
        embed.title = "\xE2\x9A\xA0\xEF\xB8\x8F  DRY RUN \xE2\x80\x94 Would Need Manual Ban"
        embed.color = C().YELLOW
    end

    -- @mention outside embed triggers mobile push notification
    local content = nil
    if config.DISCORD_USER_ID and config.DISCORD_USER_ID ~= "" then
        content = "<@" .. config.DISCORD_USER_ID .. ">"
    end

    return Http.Send(config, embed, content)
end

-- ═══════════════════════════════════════
-- MONITOR START
-- ═══════════════════════════════════════
function Embeds.SendStartNotification(config)
    local embed = {
        title = "\xF0\x9F\x9F\xA2  Monitor Started",
        color = C().GREEN,
        description = "BSS Monitor is now watching this server.",
        fields = {
            {
                name = "\xE2\x9A\x99\xEF\xB8\x8F Settings",
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
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- MONITOR STOP
-- ═══════════════════════════════════════
function Embeds.SendStopNotification(config)
    local embed = {
        title = "\xF0\x9F\x94\xB4  Monitor Stopped",
        color = C().RED,
        description = "Server monitoring has been stopped.",
    }
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- PLAYER PASSED CHECK (optional, not called by default)
-- ═══════════════════════════════════════
function Embeds.SendPlayerPassedNotification(config, playerName, hiveData, checkResult)
    local embed = {
        title = "\xE2\x9C\x85  Player OK",
        color = C().GREEN,
        description = string.format(
            "**%s** meets hive requirements.\n`%.0f%%` at LVL %d+ \xC2\xB7 `Avg LVL %.1f`",
            playerName,
            checkResult.percentAtLevel * 100,
            config.MINIMUM_LEVEL,
            hiveData.avgLevel
        ),
    }
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- SCAN TIMEOUT (player kicked for no hive data)
-- ═══════════════════════════════════════
function Embeds.SendScanTimeoutNotification(config, playerName, elapsedSeconds)
    local embed = {
        title = "\xE2\x8F\xB0  Scan Timeout \xE2\x80\x94 Player Kicked",
        color = C().ORANGE,
        description = string.format("**%s** was kicked for having no hive data after %d seconds.", playerName, elapsedSeconds),
    }
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- KICK CONFIRMED (scan timeout player left)
-- ═══════════════════════════════════════
function Embeds.SendKickConfirmedNotification(config, playerName)
    local embed = {
        title = "\xE2\x9C\x85  Kick Confirmed",
        color = C().GREEN,
        description = string.format("**%s** has left the server (scan timeout).", playerName),
    }
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- BAN FAILED
-- ═══════════════════════════════════════
function Embeds.SendBanFailedNotification(config, playerName, reason, attempts)
    local embed = {
        title = "\xE2\x9A\xA0\xEF\xB8\x8F  Ban Failed",
        color = C().ORANGE,
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
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- BAN VERIFIED
-- ═══════════════════════════════════════
function Embeds.SendBanVerifiedNotification(config, playerName, reason, attempts)
    local embed = {
        title = "\xE2\x9C\x85  Ban Confirmed",
        color = C().GREEN,
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
    return Http.Send(config, embed)
end

return Embeds
