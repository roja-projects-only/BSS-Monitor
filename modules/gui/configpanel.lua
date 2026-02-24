--[[
    BSS Monitor - Config Panel GUI
    Settings panel: Requirements, Timing, Discord, Behavior, Whitelist, Advanced.
    Save writes to BSS-Monitor/config.json via Persist. Shows message if file access unavailable.
    https://github.com/roja-projects-only/BSS-Monitor
]]

local ConfigPanel = {}

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Theme, H, Config
local panelFrame, overlay, scroll, statusLabel
local inputRefs = {} -- key -> { type, ... } for reading on Save
local whitelistContainer

-- Consistent layout for all config rows
local ROW_HEIGHT = 28
local LABEL_W = 0.48
local INPUT_LEFT = 0.50
local INPUT_W = 0.50
local INPUT_H = 22
local INPUT_TOP = (ROW_HEIGHT - INPUT_H) / 2

-- Validation: min, max (for numbers)
local VALIDATION = {
    MINIMUM_LEVEL = { 1, 23 },
    REQUIRED_PERCENT = { 0, 1 },
    MIN_BEES_REQUIRED = { 1, 50 },
    CHECK_INTERVAL = { 1, 300 },
    GRACE_PERIOD = { 0, 120 },
    SCAN_TIMEOUT = { 1, 300 },
    BAN_COOLDOWN = { 1, 60 },
    MAX_PLAYERS = { 1, 6 },
    MOBILE_RENOTIFY_INTERVAL = { 60, 3600 },
}

local LOG_LEVEL_OPTIONS = { "DEBUG", "INFO", "WARN", "ERROR", "CRITICAL", "NONE" }

function ConfigPanel.Init(theme, helpers, config)
    Theme = theme
    H = helpers
    Config = config
    return ConfigPanel
end

local function getC()
    return Theme and Theme.C or {}
end

local function addSectionHeader(parent, text, yOffset)
    local C = getC()
    H.sectionHeader(parent, text, C.textDim, yOffset)
    return yOffset + 18
end

local function clampNumber(key, n)
    local v = VALIDATION[key]
    if not v or type(n) ~= "number" then return n end
    local low, high = v[1], v[2]
    if n ~= n then return low end
    return math.max(low, math.min(high, n))
end

local function addNumberRow(parent, key, labelText, value, yOffset)
    local C = getC()
    local row = Instance.new("Frame")
    row.Name = key
    row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    row.Position = UDim2.new(0, 0, 0, yOffset)
    row.BackgroundTransparency = 1
    row.Parent = parent

    H.label({
        text = labelText,
        color = C.textSec,
        size = 10,
        font = Enum.Font.GothamMedium,
        sizeUDim = UDim2.new(LABEL_W, -4, 1, 0),
        pos = UDim2.new(0, 0, 0, 0),
        parent = row,
    })

    local box = Instance.new("TextBox")
    box.Name = "Input"
    box.Size = UDim2.new(INPUT_W, -4, 0, INPUT_H)
    box.Position = UDim2.new(INPUT_LEFT, 0, 0, INPUT_TOP)
    box.BackgroundColor3 = C.surface
    box.BorderSizePixel = 0
    box.Text = tostring(value or 0)
    box.TextColor3 = C.text
    box.TextSize = 10
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = row
    H.addCorner(box, 4)

    inputRefs[key] = { type = "number", box = box, key = key }
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            n = clampNumber(key, key == "REQUIRED_PERCENT" and (n > 1 and n / 100 or n) or n)
            if key == "REQUIRED_PERCENT" then
                box.Text = string.format("%.2f", n)
            else
                box.Text = tostring(math.floor(n))
            end
        else
            box.Text = tostring(Config[key] or 0)
        end
    end)
    return yOffset + ROW_HEIGHT
end

local function addTextRow(parent, key, labelText, value, yOffset)
    local C = getC()
    local row = Instance.new("Frame")
    row.Name = key
    row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    row.Position = UDim2.new(0, 0, 0, yOffset)
    row.BackgroundTransparency = 1
    row.ClipsDescendants = true
    row.Parent = parent

    H.label({
        text = labelText,
        color = C.textSec,
        size = 10,
        font = Enum.Font.GothamMedium,
        sizeUDim = UDim2.new(LABEL_W, -4, 1, 0),
        pos = UDim2.new(0, 0, 0, 0),
        parent = row,
    })

    local box = Instance.new("TextBox")
    box.Name = "Input"
    box.Size = UDim2.new(INPUT_W, -4, 0, INPUT_H)
    box.Position = UDim2.new(INPUT_LEFT, 0, 0, INPUT_TOP)
    box.BackgroundColor3 = C.surface
    box.BorderSizePixel = 0
    box.Text = (tostring(value or ""):gsub("^%s*(.-)%s*$", "%1"))
    box.TextColor3 = C.text
    box.TextSize = 10
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    if box.TextTruncate then
        box.TextTruncate = Enum.TextTruncate.AtEnd
    end
    box.Parent = row
    H.addCorner(box, 4)
    box.FocusLost:Connect(function()
        local trimmed = (box.Text or ""):gsub("^%s*(.-)%s*$", "%1")
        if trimmed ~= box.Text then box.Text = trimmed end
    end)

    inputRefs[key] = { type = "text", box = box }
    return yOffset + ROW_HEIGHT
end

local function addToggleRow(parent, key, labelText, value, yOffset)
    local C = getC()
    local row = Instance.new("Frame")
    row.Name = key
    row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    row.Position = UDim2.new(0, 0, 0, yOffset)
    row.BackgroundTransparency = 1
    row.Parent = parent

    H.label({
        text = labelText,
        color = C.textSec,
        size = 10,
        font = Enum.Font.GothamMedium,
        sizeUDim = UDim2.new(LABEL_W, -4, 1, 0),
        pos = UDim2.new(0, 0, 0, 0),
        parent = row,
    })

    local btn = Instance.new("TextButton")
    btn.Name = "Toggle"
    btn.Size = UDim2.new(INPUT_W, -4, 0, INPUT_H)
    btn.Position = UDim2.new(INPUT_LEFT, 0, 0, INPUT_TOP)
    btn.BackgroundColor3 = value and C.green or C.red
    btn.BorderSizePixel = 0
    btn.Text = value and "On" or "Off"
    btn.TextColor3 = C.text
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.Parent = row
    H.addCorner(btn, 4)

    inputRefs[key] = { type = "toggle", button = btn, value = value }
    btn.MouseButton1Click:Connect(function()
        inputRefs[key].value = not inputRefs[key].value
        btn.Text = inputRefs[key].value and "On" or "Off"
        btn.BackgroundColor3 = inputRefs[key].value and C.green or C.red
    end)
    return yOffset + ROW_HEIGHT
end

local DROPDOWN_LIST_W_PX = 132
local DROPDOWN_LIST_MAX_H_PX = 124

local function closeAllDropdowns()
    if not panelFrame then return end
    for _, d in ipairs(panelFrame:GetDescendants()) do
        if d.Name == "DropdownList" and d:IsA("Frame") then
            d.Visible = false
        end
    end
end

local function addDropdownRow(parent, key, labelText, options, currentValue, yOffset, dropdownParent)
    local C = getC()
    local row = Instance.new("Frame")
    row.Name = key
    row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    row.Position = UDim2.new(0, 0, 0, yOffset)
    row.BackgroundTransparency = 1
    row.Parent = parent

    H.label({
        text = labelText,
        color = C.textSec,
        size = 10,
        font = Enum.Font.GothamMedium,
        sizeUDim = UDim2.new(LABEL_W, -4, 1, 0),
        pos = UDim2.new(0, 0, 0, 0),
        parent = row,
    })

    local isKeyed = type(options[1]) == "table" and options[1].display ~= nil
    local currentDisplay = currentValue or (isKeyed and options[1].display or options[1])
    local currentVal
    if isKeyed then
        for _, o in ipairs(options) do
            if o.display == currentDisplay then currentVal = o.value break end
        end
        currentVal = currentVal or options[1].value
    else
        currentVal = currentDisplay
    end

    local btn = Instance.new("TextButton")
    btn.Name = "Dropdown"
    btn.Size = UDim2.new(INPUT_W, -4, 0, INPUT_H)
    btn.Position = UDim2.new(INPUT_LEFT, 0, 0, INPUT_TOP)
    btn.BackgroundColor3 = C.elevated
    btn.BorderSizePixel = 0
    btn.Text = tostring(currentDisplay)
    btn.TextColor3 = C.text
    btn.TextSize = 10
    btn.Font = Enum.Font.Gotham
    btn.AutoButtonColor = true
    btn.Parent = row
    H.addCorner(btn, 4)

    local listParent = (dropdownParent and dropdownParent ~= parent) and dropdownParent or row
    local listFrame = Instance.new("Frame")
    listFrame.Name = "DropdownList"
    listFrame.Size = UDim2.new(0, DROPDOWN_LIST_W_PX, 0, math.min(#options * 22, DROPDOWN_LIST_MAX_H_PX))
    listFrame.Position = listParent == row and UDim2.new(INPUT_LEFT, 0, 0, ROW_HEIGHT) or UDim2.new(0, 0, 0, 0)
    listFrame.BackgroundColor3 = C.surfaceHL
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 50
    listFrame.Parent = listParent
    H.addCorner(listFrame, 4)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 1)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame

    for i, opt in ipairs(options) do
        local displayText = isKeyed and opt.display or tostring(opt)
        local val = isKeyed and opt.value or opt
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, -4, 0, 20)
        optBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 21)
        optBtn.BackgroundColor3 = C.surface
        optBtn.BorderSizePixel = 0
        optBtn.Text = tostring(displayText)
        optBtn.TextColor3 = C.text
        optBtn.TextSize = 9
        optBtn.Font = Enum.Font.Gotham
        optBtn.LayoutOrder = i
        optBtn.ZIndex = 51
        optBtn.Parent = listFrame
        H.addCorner(optBtn, 2)
        optBtn.MouseButton1Click:Connect(function()
            inputRefs[key].value = val
            btn.Text = tostring(displayText)
            listFrame.Visible = false
        end)
    end

    inputRefs[key] = { type = "dropdown", button = btn, value = currentVal, options = options, isKeyed = isKeyed }
    btn.MouseButton1Click:Connect(function()
        local wasOpen = listFrame.Visible
        closeAllDropdowns()
        if wasOpen then return end
        if listParent == dropdownParent and dropdownParent then
            local px = dropdownParent.AbsolutePosition.X
            local py = dropdownParent.AbsolutePosition.Y
            local relX = btn.AbsolutePosition.X - px
            local relY = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y - py
            listFrame.Position = UDim2.new(0, relX, 0, relY)
        end
        listFrame.Visible = true
    end)
    return yOffset + ROW_HEIGHT
end

local function updateContentHeight(container, scroll)
    local maxY = 0
    for _, child in ipairs(container:GetChildren()) do
        local h = child.Size.Y.Offset or 0
        local bottom = child.Position.Y.Offset + h
        if bottom > maxY then maxY = bottom end
    end
    container.Size = UDim2.new(1, 0, 0, maxY + 20)
    scroll.CanvasSize = UDim2.new(0, 0, 0, maxY + 20)
end

local function buildWhitelistRows(container, whitelistContainer, whitelistStartY, addRowFrame, scroll)
    local C = getC()
    for _, c in ipairs(whitelistContainer:GetChildren()) do
        c:Destroy()
    end
    local wl = Config.WHITELIST or {}
    for i, name in ipairs(wl) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 22)
        row.Position = UDim2.new(0, 0, 0, (i - 1) * 24)
        row.BackgroundColor3 = C.surface
        row.BorderSizePixel = 0
        H.addCorner(row, 4)
        row.Parent = whitelistContainer

        H.label({
            text = name,
            color = C.text,
            size = 10,
            font = Enum.Font.GothamMedium,
            sizeUDim = UDim2.new(1, -50, 1, 0),
            pos = UDim2.new(0, 6, 0, 0),
            parent = row,
        })

        local removeBtn = Instance.new("TextButton")
        removeBtn.Size = UDim2.new(0, 40, 0, 18)
        removeBtn.Position = UDim2.new(1, -44, 0.5, -9)
        removeBtn.BackgroundColor3 = C.red
        removeBtn.BorderSizePixel = 0
        removeBtn.Text = "Remove"
        removeBtn.TextColor3 = C.text
        removeBtn.TextSize = 9
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.Parent = row
        H.addCorner(removeBtn, 4)
        removeBtn.MouseButton1Click:Connect(function()
            Config.RemoveFromWhitelist(name)
            buildWhitelistRows(container, whitelistContainer, whitelistStartY, addRowFrame, scroll)
        end)
    end
    whitelistContainer.Size = UDim2.new(1, 0, 0, #wl * 24)
    addRowFrame.Position = UDim2.new(0, 0, 0, whitelistStartY + #wl * 24)
    updateContentHeight(container, scroll)
end

local function buildContent(container, dropdownParent)
    local C = getC()
    local PADDING = Theme.PADDING
    inputRefs = {}
    for _, child in ipairs(container:GetChildren()) do
        child:Destroy()
    end

    local y = 0

    -- Requirements
    y = addSectionHeader(container, "REQUIREMENTS", y)
    y = addNumberRow(container, "MINIMUM_LEVEL", "Min bee level (1–23)", Config.MINIMUM_LEVEL, y)
    y = addNumberRow(container, "REQUIRED_PERCENT", "Required % (0–1)", Config.REQUIRED_PERCENT, y)
    y = addNumberRow(container, "MIN_BEES_REQUIRED", "Min bees to count", Config.MIN_BEES_REQUIRED, y)
    y = y + 4

    -- Timing
    y = addSectionHeader(container, "TIMING", y)
    y = addNumberRow(container, "CHECK_INTERVAL", "Scan interval (s)", Config.CHECK_INTERVAL, y)
    y = addNumberRow(container, "GRACE_PERIOD", "Grace period (s)", Config.GRACE_PERIOD, y)
    y = addNumberRow(container, "SCAN_TIMEOUT", "Scan timeout (s)", Config.SCAN_TIMEOUT, y)
    y = addNumberRow(container, "BAN_COOLDOWN", "Ban cooldown (s)", Config.BAN_COOLDOWN, y)
    y = y + 4

    -- Discord
    y = addSectionHeader(container, "DISCORD", y)
    y = addToggleRow(container, "WEBHOOK_ENABLED", "Notifications", Config.WEBHOOK_ENABLED, y)
    y = addTextRow(container, "WEBHOOK_URL", "Webhook URL", Config.WEBHOOK_URL or "", y)
    y = addTextRow(container, "DISCORD_USER_ID", "Discord user ID (@mention)", Config.DISCORD_USER_ID or "", y)
    y = y + 4

    -- Behavior
    y = addSectionHeader(container, "BEHAVIOR", y)
    y = addToggleRow(container, "DRY_RUN", "Dry run (no ban)", Config.DRY_RUN, y)
    y = addToggleRow(container, "USE_KICK", "Use /kick (not /ban)", Config.USE_KICK, y)
    y = addNumberRow(container, "MAX_PLAYERS", "Max players (1–6)", Config.MAX_PLAYERS, y)
    y = y + 4

    -- Whitelist
    y = addSectionHeader(container, "WHITELIST", y)
    local wlCount = #(Config.WHITELIST or {})
    whitelistContainer = Instance.new("Frame")
    whitelistContainer.Name = "WhitelistList"
    whitelistContainer.Size = UDim2.new(1, 0, 0, wlCount * 24)
    whitelistContainer.Position = UDim2.new(0, 0, 0, y)
    whitelistContainer.BackgroundTransparency = 1
    whitelistContainer.Parent = container

    local addRowFrame = Instance.new("Frame")
    addRowFrame.Name = "WhitelistAddRow"
    addRowFrame.Size = UDim2.new(1, 0, 0, 28)
    addRowFrame.Position = UDim2.new(0, 0, 0, y + wlCount * 24)
    addRowFrame.BackgroundTransparency = 1
    addRowFrame.Parent = container

    local scroll = container.Parent
    buildWhitelistRows(container, whitelistContainer, y, addRowFrame, scroll)

    local addBox = Instance.new("TextBox")
    addBox.Name = "AddName"
    addBox.Size = UDim2.new(0.6, -4, 0, 22)
    addBox.Position = UDim2.new(0, 0, 0, 2)
    addBox.PlaceholderText = "Username"
    addBox.BackgroundColor3 = C.surface
    addBox.BorderSizePixel = 0
    addBox.Text = ""
    addBox.TextColor3 = C.text
    addBox.TextSize = 10
    addBox.Font = Enum.Font.Gotham
    addBox.ClearTextOnFocus = false
    addBox.Parent = addRowFrame
    H.addCorner(addBox, 4)

    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0, 60, 0, 22)
    addBtn.Position = UDim2.new(0.62, 0, 0, 2)
    addBtn.BackgroundColor3 = C.green
    addBtn.BorderSizePixel = 0
    addBtn.Text = "Add"
    addBtn.TextColor3 = C.text
    addBtn.TextSize = 10
    addBtn.Font = Enum.Font.GothamBold
    addBtn.Parent = addRowFrame
    H.addCorner(addBtn, 4)
    addBtn.MouseButton1Click:Connect(function()
        local name = addBox.Text and addBox.Text:gsub("^%s*(.-)%s*$", "%1") or ""
        if #name > 0 and Config.AddToWhitelist(name) then
            addBox.Text = ""
            buildWhitelistRows(container, whitelistContainer, y, addRowFrame, scroll)
        end
    end)

    y = y + wlCount * 24 + 32
    y = y + 4

    -- Advanced
    y = addSectionHeader(container, "ADVANCED", y)
    local logLevel = Config.LOG_LEVEL or "WARN"
    if not table.find(LOG_LEVEL_OPTIONS, logLevel) then
        logLevel = "WARN"
    end
    y = addDropdownRow(container, "LOG_LEVEL", "Log level", LOG_LEVEL_OPTIONS, logLevel, y, dropdownParent)
    y = addNumberRow(container, "MOBILE_RENOTIFY_INTERVAL", "Mobile re-notify (s)", Config.MOBILE_RENOTIFY_INTERVAL, y)
    local mobileModeOptions = { { display = "Auto", value = nil }, { display = "Mobile", value = true }, { display = "Desktop", value = false } }
    local modeVal = Config.MOBILE_MODE
    local modeDisplay = modeVal == nil and "Auto" or (modeVal and "Mobile" or "Desktop")
    y = addDropdownRow(container, "MOBILE_MODE", "Mobile mode", mobileModeOptions, modeDisplay, y, dropdownParent)

    return y
end

local function validateDiscordFields(t)
    local url = type(t.WEBHOOK_URL) == "string" and t.WEBHOOK_URL:gsub("^%s*(.-)%s*$", "%1") or ""
    if t.WEBHOOK_ENABLED and url == "" then
        return "Notifications are on but Webhook URL is empty. Set a URL or turn Notifications off."
    end
    if url ~= "" and not url:match("^https?://") then
        return "Webhook URL should start with https://"
    end
    local discordId = type(t.DISCORD_USER_ID) == "string" and t.DISCORD_USER_ID:gsub("^%s*(.-)%s*$", "%1") or ""
    if discordId ~= "" and not discordId:match("^%d+$") then
        return "Discord user ID must be numbers only (e.g. 123456789012345678)"
    end
    return nil
end

local function gatherFromUI()
    local t = {}
    for key, ref in pairs(inputRefs) do
        if ref.type == "number" and ref.box then
            local v = ref.box.Text
            local n = tonumber(v)
            if n then
                if key == "REQUIRED_PERCENT" and n > 1 then
                    n = n / 100
                end
                n = clampNumber(key, key == "REQUIRED_PERCENT" and n or math.floor(n))
                t[key] = key == "REQUIRED_PERCENT" and n or math.floor(n)
            else
                t[key] = Config[key] or 0
            end
        elseif ref.type == "text" and ref.box then
            t[key] = (ref.box.Text or ""):gsub("^%s*(.-)%s*$", "%1")
        elseif ref.type == "toggle" then
            t[key] = ref.value
        elseif ref.type == "dropdown" then
            t[key] = ref.value
        end
    end
    t.WHITELIST = {}
    for _, name in ipairs(Config.WHITELIST or {}) do
        table.insert(t.WHITELIST, name)
    end
    return t
end

function ConfigPanel.Create(parent)
    if panelFrame and panelFrame.Parent then
        return
    end
    local C = getC()
    local PANEL_WIDTH = Theme.PANEL_WIDTH
    local PANEL_HEIGHT = 400
    local PADDING = Theme.PADDING

    overlay = Instance.new("Frame")
    overlay.Name = "ConfigOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 10
    overlay.Visible = false
    overlay.Parent = parent

    panelFrame = Instance.new("Frame")
    panelFrame.Name = "ConfigPanel"
    panelFrame.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
    panelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    panelFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    panelFrame.BackgroundColor3 = C.bg
    panelFrame.BorderSizePixel = 0
    panelFrame.ZIndex = 11
    panelFrame.Parent = overlay
    H.addCorner(panelFrame, 12)
    H.addStroke(panelFrame, C.accent, 1.5)

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = C.surface
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 11
    titleBar.Parent = panelFrame
    H.addCorner(titleBar, 12)
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 14)
    titleFix.Position = UDim2.new(0, 0, 1, -14)
    titleFix.BackgroundColor3 = C.surface
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    H.label({
        text = "Settings",
        color = C.text,
        size = 14,
        font = Enum.Font.GothamBold,
        sizeUDim = UDim2.new(1, -80, 1, 0),
        pos = UDim2.new(0, PADDING, 0, 0),
        parent = titleBar,
    })

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 36, 0, 28)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -14)
    closeBtn.BackgroundColor3 = C.elevated
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = C.text
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 12
    closeBtn.Parent = titleBar
    H.addCorner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function()
        ConfigPanel.Hide()
    end)

    scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -PADDING * 2, 1, -32 - 60 - PADDING)
    scroll.Position = UDim2.new(0, PADDING, 0, 36)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = C.accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.CanvasPosition = Vector2.new(0, 0)
    scroll.ZIndex = 11
    scroll.Parent = panelFrame
    scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(closeAllDropdowns)

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -4, 0, 0)
    content.Position = UDim2.new(0, 0, 0, 0)
    content.BackgroundTransparency = 1
    content.Parent = scroll

    local contentHeight = buildContent(content, panelFrame)
    content.Size = UDim2.new(1, 0, 0, contentHeight + 20)
    scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20)

    local footer = Instance.new("Frame")
    footer.Size = UDim2.new(1, -PADDING * 2, 0, 50)
    footer.Position = UDim2.new(0, PADDING, 1, -56)
    footer.BackgroundTransparency = 1
    footer.ZIndex = 11
    footer.Parent = panelFrame

    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 16)
    statusLabel.Position = UDim2.new(0, 0, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = C.textDim
    statusLabel.TextSize = 9
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.ZIndex = 11
    statusLabel.Parent = footer

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0, 100, 0, 28)
    saveBtn.Position = UDim2.new(0, 0, 0, 22)
    saveBtn.BackgroundColor3 = C.green
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = "Save"
    saveBtn.TextColor3 = C.text
    saveBtn.TextSize = 12
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.ZIndex = 11
    saveBtn.Parent = footer
    H.addCorner(saveBtn, 6)
    saveBtn.MouseButton1Click:Connect(function()
        local t = gatherFromUI()
        local err = validateDiscordFields(t)
        if err then
            statusLabel.Text = err
            statusLabel.TextColor3 = C.red
            return
        end
        if Config.ApplyFromTable then
            Config.ApplyFromTable(t)
        end
        local Persist = _G.BSSMonitor and _G.BSSMonitor.Persist
        if not Persist or not Persist.Save then
            statusLabel.Text = "Config not saved — file access not available"
            statusLabel.TextColor3 = C.red
            return
        end
        local exportTable = Config.ExportToTable and Config.ExportToTable() or t
        local ok, err = pcall(function()
            local jsonStr = HttpService:JSONEncode(exportTable)
            return Persist.Save(jsonStr)
        end)
        if ok and err == true then
            statusLabel.Text = "Saved to BSS-Monitor/config.json"
            statusLabel.TextColor3 = C.green
            -- Dynamically update main panel and re-run one cycle with new settings
            local bss = _G.BSSMonitor
            if bss and bss.GUI and bss.GUI.RefreshFromConfig then
                bss.GUI.RefreshFromConfig()
            end
            if bss and bss.Monitor and bss.Monitor.RunCycle then
                bss.Monitor.RunCycle()
            end
        else
            statusLabel.Text = "Config not saved — file access not available"
            statusLabel.TextColor3 = C.red
        end
    end)

    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Target == overlay then
                ConfigPanel.Hide()
            end
        end
    end)
end

function ConfigPanel.Show(parent)
    if not parent then return end
    ConfigPanel.Create(parent)
    -- Refresh content from Config
    if scroll and scroll:FindFirstChild("Content") and panelFrame then
        local content = scroll.Content
        local contentHeight = buildContent(content, panelFrame)
        content.Size = UDim2.new(1, 0, 0, contentHeight + 20)
        scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20)
    end
    if statusLabel then
        local Persist = _G.BSSMonitor and _G.BSSMonitor.Persist
        if Persist and Persist.IsAvailable and not Persist.IsAvailable() then
            statusLabel.Text = "Config will not persist — file access not available"
            statusLabel.TextColor3 = getC().orange
        else
            statusLabel.Text = ""
        end
    end
    overlay.Visible = true
end

function ConfigPanel.Hide()
    if overlay then
        overlay.Visible = false
    end
end

--- Destroy config panel UI and clear refs so re-execute or Create() starts clean.
function ConfigPanel.Cleanup()
    pcall(function()
        if overlay and overlay.Parent then
            overlay:Destroy()
        end
    end)
    overlay = nil
    panelFrame = nil
    scroll = nil
    statusLabel = nil
    whitelistContainer = nil
    inputRefs = {}
end

return ConfigPanel
