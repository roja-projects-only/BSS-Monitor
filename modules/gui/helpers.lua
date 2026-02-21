--[[
    BSS Monitor - GUI Helpers
    Reusable UI primitive builders (corners, strokes, shadows, labels, headers)
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Helpers = {}

local C -- color palette reference

function Helpers.Init(theme)
    C = theme.C
    return Helpers
end

function Helpers.addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

function Helpers.addStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or C.accent
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

function Helpers.addShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.4
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = parent
    return shadow
end

function Helpers.label(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Text = props.text or ""
    l.TextColor3 = props.color or C.text
    l.TextSize = props.size or 12
    l.Font = props.font or Enum.Font.Gotham
    l.TextXAlignment = props.alignX or Enum.TextXAlignment.Left
    l.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
    l.TextTruncate = props.truncate or Enum.TextTruncate.None
    l.Size = props.sizeUDim or UDim2.new(1, 0, 1, 0)
    l.Position = props.pos or UDim2.new(0, 0, 0, 0)
    if props.parent then l.Parent = props.parent end
    return l
end

function Helpers.sectionHeader(parent, text, color, yPos)
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 16)
    hdr.Position = UDim2.new(0, 0, 0, yPos)
    hdr.BackgroundTransparency = 1
    hdr.Parent = parent

    Helpers.label({
        text = text,
        color = color or C.textDim,
        size = 9,
        font = Enum.Font.GothamBold,
        parent = hdr,
    })

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -#text * 5 - 8, 0, 1)
    line.Position = UDim2.new(0, #text * 5 + 8, 0.5, 0)
    line.BackgroundColor3 = C.surfaceHL
    line.BackgroundTransparency = 0.3
    line.BorderSizePixel = 0
    line.Parent = hdr

    return hdr
end

return Helpers
