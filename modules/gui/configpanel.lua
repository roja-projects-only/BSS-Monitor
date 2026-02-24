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
local inputRefs = {} -- key -> TextBox or toggle value ref for reading on Save
local whitelistContainer

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

local function addRow(parent, key, labelText, value, isNumber, yOffset)
    local C = getC()
    local row = Instance.new("Frame")
    row.Name = key
    row.Size = UDim2.new(1, 0, 0, 24)
    row.Position = UDim2.new(0, 0, 0, yOffset)
    row.BackgroundTransparency = 1
    row.Parent = parent

    H.label({
        text = labelText,
        color = C.textSec,
        size = 10,
        font = Enum.Font.GothamMedium,
        sizeUDim = UDim2.new(0.45, 0, 1, 0),
        pos = UDim2.new(0, 0, 0, 0),
        parent = row,
    })

    local box = Instance.new("TextBox")
    box.Name = "Input"
    box.Size = UDim2.new(0.52, 0, 0, 20)
    box.Position = UDim2.new(0.48, 0, 0, 2)
    box.BackgroundColor3 = C.surface
    box.BorderSizePixel = 0
    box.Text = tostring(value or "")
    box.TextColor3 = C.text
    box.TextSize = 10
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = row
    H.addCorner(box, 4)

    inputRefs[key] = { type = "text", box = box, isNumber = isNumber }
    return yOffset + 26
end

local function addToggleRow(parent, key, labelText, value, yOffset)
    local C = getC()
    local row = Instance.new("Frame")
    row.Name = key
    row.Size = UDim2.new(1, 0, 0, 24)
    row.Position = UDim2.new(0, 0, 0, yOffset)
    row.BackgroundTransparency = 1
    row.Parent = parent

    H.label({
        text = labelText,
        color = C.textSec,
        size = 10,
        font = Enum.Font.GothamMedium,
        sizeUDim = UDim2.new(0.55, 0, 1, 0),
        pos = UDim2.new(0, 0, 0, 0),
        parent = row,
    })

    local btn = Instance.new("TextButton")
    btn.Name = "Toggle"
    btn.Size = UDim2.new(0, 44, 0, 20)
    btn.Position = UDim2.new(0.58, 0, 0, 2)
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
    return yOffset + 26
end

local function buildContent(container)
    local C = getC()
    local PADDING = Theme.PADDING
    inputRefs = {}
    for _, child in ipairs(container:GetChildren()) do
        child:Destroy()
    end

    local y = 0

    -- Requirements
    y = addSectionHeader(container, "REQUIREMENTS", y)
    y = addRow(container, "MINIMUM_LEVEL", "Min bee level", Config.MINIMUM_LEVEL, true, y)
    y = addRow(container, "REQUIRED_PERCENT", "Required % (0-1)", Config.REQUIRED_PERCENT, true, y)
    y = addRow(container, "MIN_BEES_REQUIRED", "Min bees to count", Config.MIN_BEES_REQUIRED, true, y)
    y = y + 4

    -- Timing
    y = addSectionHeader(container, "TIMING", y)
    y = addRow(container, "CHECK_INTERVAL", "Scan interval (s)", Config.CHECK_INTERVAL, true, y)
    y = addRow(container, "GRACE_PERIOD", "Grace period (s)", Config.GRACE_PERIOD, true, y)
    y = addRow(container, "SCAN_TIMEOUT", "Scan timeout (s)", Config.SCAN_TIMEOUT, true, y)
    y = addRow(container, "BAN_COOLDOWN", "Ban cooldown (s)", Config.BAN_COOLDOWN, true, y)
    y = y + 4

    -- Discord
    y = addSectionHeader(container, "DISCORD", y)
    y = addToggleRow(container, "WEBHOOK_ENABLED", "Notifications", Config.WEBHOOK_ENABLED, y)
    y = addRow(container, "WEBHOOK_URL", "Webhook URL", Config.WEBHOOK_URL or "", false, y)
    y = addRow(container, "DISCORD_USER_ID", "Discord user ID (@mention)", Config.DISCORD_USER_ID or "", false, y)
    y = y + 4

    -- Behavior
    y = addSectionHeader(container, "BEHAVIOR", y)
    y = addToggleRow(container, "DRY_RUN", "Dry run (no ban)", Config.DRY_RUN, y)
    y = addToggleRow(container, "AUTO_START", "Auto-start monitor", Config.AUTO_START, y)
    y = addToggleRow(container, "USE_KICK", "Use /kick (not /ban)", Config.USE_KICK, y)
    y = addRow(container, "MAX_PLAYERS", "Max players", Config.MAX_PLAYERS, true, y)
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

    for i, name in ipairs(Config.WHITELIST or {}) do
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
            row:Destroy()
        end)
    end

    local addRowFrame = Instance.new("Frame")
    addRowFrame.Size = UDim2.new(1, 0, 0, 28)
    addRowFrame.Position = UDim2.new(0, 0, 0, y + wlCount * 24)
    addRowFrame.BackgroundTransparency = 1
    addRowFrame.Parent = container

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
            -- Rebuild whitelist section so new name appears (or add row dynamically)
            buildContent(container)
        end
    end)

    y = y + wlCount * 24 + 32
    y = y + 4

    -- Advanced
    y = addSectionHeader(container, "ADVANCED", y)
    y = addRow(container, "LOG_LEVEL", "Log level", Config.LOG_LEVEL or "WARN", false, y)
    y = addRow(container, "MOBILE_RENOTIFY_INTERVAL", "Mobile re-notify (s)", Config.MOBILE_RENOTIFY_INTERVAL, true, y)
    -- MOBILE_MODE: nil / true / false - use dropdown or 3 buttons
    local modeRow = Instance.new("Frame")
    modeRow.Name = "MOBILE_MODE"
    modeRow.Size = UDim2.new(1, 0, 0, 24)
    modeRow.Position = UDim2.new(0, 0, 0, y)
    modeRow.BackgroundTransparency = 1
    modeRow.Parent = container
    H.label({
        text = "Mobile mode",
        color = C.textSec,
        size = 10,
        font = Enum.Font.GothamMedium,
        sizeUDim = UDim2.new(0.4, 0, 1, 0),
        pos = UDim2.new(0, 0, 0, 0),
        parent = modeRow,
    })
    local modeVal = Config.MOBILE_MODE
    local modeStr = modeVal == nil and "Auto" or (modeVal and "Mobile" or "Desktop")
    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0, 70, 0, 20)
    modeBtn.Position = UDim2.new(0.42, 0, 0, 2)
    modeBtn.BackgroundColor3 = C.elevated
    modeBtn.BorderSizePixel = 0
    modeBtn.Text = modeStr
    modeBtn.TextColor3 = C.text
    modeBtn.TextSize = 9
    modeBtn.Font = Enum.Font.Gotham
    modeBtn.Parent = modeRow
    H.addCorner(modeBtn, 4)
    inputRefs["MOBILE_MODE"] = { type = "mobileMode", button = modeBtn, value = modeVal }
    modeBtn.MouseButton1Click:Connect(function()
        local nextVal = (inputRefs["MOBILE_MODE"].value == nil and true) or (inputRefs["MOBILE_MODE"].value == true and false) or nil
        inputRefs["MOBILE_MODE"].value = nextVal
        modeBtn.Text = nextVal == nil and "Auto" or (nextVal and "Mobile" or "Desktop")
    end)
    y = y + 26

    return y
end

local function gatherFromUI()
    local t = {}
    for key, ref in pairs(inputRefs) do
        if ref.type == "text" and ref.box then
            local v = ref.box.Text
            if ref.isNumber then
                local n = tonumber(v)
                if key == "REQUIRED_PERCENT" and n and n > 1 then
                    n = n / 100
                end
                t[key] = n and (key == "REQUIRED_PERCENT" and math.clamp(n, 0, 1) or math.floor(n)) or (Config[key] or 0)
            else
                t[key] = v or ""
            end
        elseif ref.type == "toggle" then
            t[key] = ref.value
        elseif ref.type == "mobileMode" then
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
    panelFrame.Position = UDim2.new(0.5, -PANEL_WIDTH / 2, 0.5, -PANEL_HEIGHT / 2)
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

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -4, 0, 0)
    content.Position = UDim2.new(0, 0, 0, 0)
    content.BackgroundTransparency = 1
    content.Parent = scroll

    local contentHeight = buildContent(content)
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
        -- Gather from UI into table, apply to Config, then export and persist
        local t = gatherFromUI()
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
    if scroll and scroll:FindFirstChild("Content") then
        local content = scroll.Content
        local contentHeight = buildContent(content)
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

return ConfigPanel
