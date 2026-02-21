--[[
    BSS Monitor - Webhook (Init / Orchestrator)
    Merges Http + Embeds into a single Webhook API
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Webhook = {}

local Http, Embeds

function Webhook.Init(http, embeds)
    Http = http
    Embeds = embeds

    -- Expose base Send from Http
    Webhook.Send = Http.Send
    Webhook.COLORS = Http.COLORS

    -- Expose all embed builders
    Webhook.SendPlayerJoinNotification   = Embeds.SendPlayerJoinNotification
    Webhook.SendPlayerLeaveNotification  = Embeds.SendPlayerLeaveNotification
    Webhook.SendBanNotification          = Embeds.SendBanNotification
    Webhook.SendMobileBanNotification    = Embeds.SendMobileBanNotification
    Webhook.SendStartNotification        = Embeds.SendStartNotification
    Webhook.SendStopNotification         = Embeds.SendStopNotification
    Webhook.SendPlayerPassedNotification = Embeds.SendPlayerPassedNotification
    Webhook.SendBanFailedNotification    = Embeds.SendBanFailedNotification
    Webhook.SendBanVerifiedNotification  = Embeds.SendBanVerifiedNotification

    return Webhook
end

return Webhook
