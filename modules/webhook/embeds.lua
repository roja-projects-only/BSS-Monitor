--[[
    BSS Monitor - Webhook Embeds
    All Discord notification embed builders
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Embeds = {}

-- Custom Discord server emojis
local E = {
    alert   = "<:bss_alert:1474707497813282868>",
    ban     = "<:bss_ban:1474707504205402152>",
    banfail = "<:bss_banfail:1474707512648400977>",
    banok   = "<:bss_banok:1474707521804701778>",
    bee     = "<:bss_bee:1474707526632083668>",
    config  = "<:bss_config:1474707530604351590>",
    desktop = "<:bss_desktop:1474707539391156345>",
    dryrun  = "<:bss_dryrun:1474707541853212722>",
    fail    = "<:bss_fail:1474707458537689109>",
    gifted  = "<:bss_gifted:1474707461943595150>",
    hive    = "<:bss_hive:1474707464418099323>",
    join    = "<:bss_join:1474707467412967454>",
    leave   = "<:bss_leave:1474707469908316200>",
    level   = "<:bss_level:1474707473112895488>",
    mobile  = "<:bss_mobile:1474707476476723292>",
    pass    = "<:bss_pass:1474707478594977832>",
    players = "<:bss_players:1474707480452927691>",
    start   = "<:bss_start:1474707483514765392>",
    stop    = "<:bss_stop:1474707492692037652>",
    timeout = "<:bss_timeout:1474707495040712755>",
}

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
        title = E.join .. "  Player Joined",
        color = C().BLUE,
        description = string.format("**%s** joined the server.", playerName),
        fields = {
            {
                name = E.players .. " Players",
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
local function formatPlaytime(seconds)
    if not seconds then return "\xE2\x80\x94" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%dh %dm %ds", h, m, s)
    elseif m > 0 then
        return string.format("%dm %ds", m, s)
    else
        return string.format("%ds", s)
    end
end

function Embeds.SendPlayerLeaveNotification(config, playerName, playerCount, maxPlayers, playtimeSeconds)
    local embed = {
        title = E.leave .. "  Player Left",
        color = C().DARK,
        description = string.format("**%s** left the server.", playerName),
        fields = {
            {
                name = E.players .. " Players",
                value = string.format("`%d / %d`", playerCount, maxPlayers),
                inline = true
            },
            {
                name = "⏱️ Playtime",
                value = "`" .. formatPlaytime(playtimeSeconds) .. "`",
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
        title = config.DRY_RUN and (E.dryrun .. "  DRY RUN — Would Ban") or (E.ban .. "  Player Banned"),
        color = config.DRY_RUN and C().YELLOW or C().RED,
        description = string.format(
            ">>> **%s** was removed for not meeting requirements.",
            playerName
        ),
        fields = {
            {
                name = E.hive .. " Hive Stats",
                value = string.format(
                    "```\n🐝 Bees: %d   ⭐ Gifted: %d\n📈 Avg Level: %.1f\n```",
                    hiveData.totalBees, hiveData.giftedCount, hiveData.avgLevel
                ),
                inline = false
            },
            {
                name = E.fail .. " Requirement",
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
        title = E.alert .. "  Action Required — Ban Player",
        color = C().RED,
        description = string.format(
            ">>> Auto-ban failed for **%s**. Use the command below to ban manually.",
            playerName
        ),
        fields = {
            {
                name = E.mobile .. " Mobile — Tap to Copy",
                value = "`" .. command .. "`",
                inline = false
            },
            {
                name = E.desktop .. " Desktop",
                value = "```\n" .. command .. "\n```",
                inline = false
            },
            {
                name = E.hive .. " Hive Stats",
                value = string.format(
                    "🐝 %d bees · ⭐ %d gifted · 📈 Avg LVL %.1f",
                    hiveData.totalBees, hiveData.giftedCount, hiveData.avgLevel
                ),
                inline = false
            },
            {
                name = E.fail .. " Requirement",
                value = string.format(
                    "`%.0f%%` at LVL %d+ \xE2\x80\x94 needed `%.0f%%`",
                    pct, config.MINIMUM_LEVEL, reqPct
                ),
                inline = false
            },
        },
    }

    if config.DRY_RUN then
        embed.title = E.dryrun .. "  DRY RUN — Would Need Manual Ban"
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
        title = E.start .. "  Monitor Started",
        color = C().GREEN,
        description = "BSS Monitor is now watching this server.",
        fields = {
            {
                name = E.config .. " Settings",
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
        title = E.stop .. "  Monitor Stopped",
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
        title = E.pass .. "  Player OK",
        color = C().GREEN,
        description = string.format(
            "**%s** meets hive requirements.\n`%.0f%%` at LVL %d+ · `Avg LVL %.1f`",
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
        title = E.timeout .. "  Scan Timeout — Player Kicked",
        color = C().ORANGE,
        description = string.format("**%s** was kicked for having no hive data after %d seconds.", playerName, elapsedSeconds),
    }
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- KICK CONFIRMED (scan timeout player left)
-- ═══════════════════════════════════════
function Embeds.SendKickConfirmedNotification(config, playerName, elapsedSeconds)
    local embed = {
        title = E.timeout .. "  Scan Timeout — Player Kicked",
        color = C().ORANGE,
        description = string.format("**%s** was kicked and has left the server.", playerName),
        fields = {
            {
                name = "Reason",
                value = "`No hive data detected`",
                inline = true
            },
            {
                name = "Missing For",
                value = elapsedSeconds and string.format("`%ds`", elapsedSeconds) or "`unknown`",
                inline = true
            },
        },
    }
    return Http.Send(config, embed)
end

-- ═══════════════════════════════════════
-- BAN FAILED
-- ═══════════════════════════════════════
function Embeds.SendBanFailedNotification(config, playerName, reason, attempts)
    local embed = {
        title = E.banfail .. "  Ban Failed",
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
        title = E.banok .. "  Ban Confirmed",
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
