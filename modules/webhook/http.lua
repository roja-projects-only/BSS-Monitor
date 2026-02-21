--[[
    BSS Monitor - Webhook HTTP
    HTTP request abstraction, Discord colors, and base Send function
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Http = {}

local HttpService = game:GetService("HttpService")

-- Multi-executor HTTP request helper
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
        -- No HTTP method found; callers handle the nil return
        return nil
    end
end

-- Discord embed colors
Http.COLORS = {
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
function Http.Send(config, embeds, content)
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
            embed.footer = { text = "BSS Monitor \xF0\x9F\x90\x9D" }
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

return Http
