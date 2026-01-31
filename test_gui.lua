--[[
    BSS Monitor - GUI Test Script
    Run this in your executor to test the GUI in isolation
    Each section is wrapped in pcall to identify which line fails
]]

print("=== GUI TEST START ===")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Test 1: Basic ScreenGui
print("Test 1: Creating ScreenGui...")
local success1, err1 = pcall(function()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TestGui"
    screenGui.ResetOnSpawn = false
    print("  ScreenGui created")
    
    -- Try parenting
    local parented = false
    
    pcall(function()
        if gethui then
            screenGui.Parent = gethui()
            parented = true
            print("  Parented to gethui()")
        end
    end)
    
    if not parented then
        pcall(function()
            screenGui.Parent = game:GetService("CoreGui")
            parented = true
            print("  Parented to CoreGui")
        end)
    end
    
    if not parented then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        print("  Parented to PlayerGui")
    end
    
    return screenGui
end)
if not success1 then
    warn("Test 1 FAILED: " .. tostring(err1))
    return
end
print("Test 1 PASSED")
local screenGui = success1 and err1 or nil

-- Test 2: Basic Frame
print("Test 2: Creating Frame...")
local success2, err2 = pcall(function()
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 200, 0, 200)
    frame.Position = UDim2.new(0.5, -100, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = screenGui
    print("  Frame created")
    return frame
end)
if not success2 then
    warn("Test 2 FAILED: " .. tostring(err2))
    return
end
print("Test 2 PASSED")
local mainFrame = err2

-- Test 3: Draggable property
print("Test 3: Setting Draggable...")
local success3, err3 = pcall(function()
    mainFrame.Draggable = true
    print("  Draggable = true")
end)
if not success3 then
    warn("Test 3 FAILED (Draggable not supported): " .. tostring(err3))
    -- Continue anyway
end
print("Test 3 " .. (success3 and "PASSED" or "SKIPPED"))

-- Test 4: UICorner
print("Test 4: Creating UICorner...")
local success4, err4 = pcall(function()
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    print("  UICorner created")
end)
if not success4 then
    warn("Test 4 FAILED: " .. tostring(err4))
end
print("Test 4 " .. (success4 and "PASSED" or "FAILED"))

-- Test 5: UIStroke
print("Test 5: Creating UIStroke...")
local success5, err5 = pcall(function()
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 180, 0)
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    print("  UIStroke created")
end)
if not success5 then
    warn("Test 5 FAILED: " .. tostring(err5))
end
print("Test 5 " .. (success5 and "PASSED" or "FAILED"))

-- Test 6: TextLabel
print("Test 6: Creating TextLabel...")
local success6, err6 = pcall(function()
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = "BSS Monitor Test"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.Parent = mainFrame
    print("  TextLabel created")
end)
if not success6 then
    warn("Test 6 FAILED: " .. tostring(err6))
end
print("Test 6 " .. (success6 and "PASSED" or "FAILED"))

-- Test 7: ScrollingFrame
print("Test 7: Creating ScrollingFrame...")
local success7, err7 = pcall(function()
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 0, 100)
    scroll.Position = UDim2.new(0, 8, 0, 40)
    scroll.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = mainFrame
    print("  ScrollingFrame created")
    return scroll
end)
if not success7 then
    warn("Test 7 FAILED: " .. tostring(err7))
end
print("Test 7 " .. (success7 and "PASSED" or "FAILED"))
local scrollFrame = err7

-- Test 8: AutomaticCanvasSize
print("Test 8: Setting AutomaticCanvasSize...")
local success8, err8 = pcall(function()
    if scrollFrame then
        scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        print("  AutomaticCanvasSize = Y")
    end
end)
if not success8 then
    warn("Test 8 FAILED (AutomaticCanvasSize not supported): " .. tostring(err8))
end
print("Test 8 " .. (success8 and "PASSED" or "FAILED"))

-- Test 9: UIListLayout
print("Test 9: Creating UIListLayout...")
local success9, err9 = pcall(function()
    if scrollFrame then
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.Name
        layout.Padding = UDim.new(0, 2)
        layout.Parent = scrollFrame
        print("  UIListLayout created")
    end
end)
if not success9 then
    warn("Test 9 FAILED: " .. tostring(err9))
end
print("Test 9 " .. (success9 and "PASSED" or "FAILED"))

-- Test 10: UIPadding
print("Test 10: Creating UIPadding...")
local success10, err10 = pcall(function()
    if scrollFrame then
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 4)
        padding.PaddingBottom = UDim.new(0, 4)
        padding.PaddingLeft = UDim.new(0, 4)
        padding.PaddingRight = UDim.new(0, 4)
        padding.Parent = scrollFrame
        print("  UIPadding created")
    end
end)
if not success10 then
    warn("Test 10 FAILED: " .. tostring(err10))
end
print("Test 10 " .. (success10 and "PASSED" or "FAILED"))

-- Test 11: Add player entries
print("Test 11: Adding player entries...")
local success11, err11 = pcall(function()
    if scrollFrame then
        for _, player in ipairs(Players:GetPlayers()) do
            local entry = Instance.new("TextLabel")
            entry.Name = player.Name
            entry.Size = UDim2.new(1, -8, 0, 16)
            entry.BackgroundTransparency = 1
            entry.Text = player.Name
            entry.TextColor3 = Color3.fromRGB(220, 220, 220)
            entry.TextSize = 11
            entry.Font = Enum.Font.Gotham
            entry.TextXAlignment = Enum.TextXAlignment.Left
            entry.Parent = scrollFrame
        end
        print("  Added " .. #Players:GetPlayers() .. " player entries")
    end
end)
if not success11 then
    warn("Test 11 FAILED: " .. tostring(err11))
end
print("Test 11 " .. (success11 and "PASSED" or "FAILED"))

-- Test 12: ZIndexBehavior
print("Test 12: Testing ZIndexBehavior...")
local success12, err12 = pcall(function()
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    print("  ZIndexBehavior = Sibling")
end)
if not success12 then
    warn("Test 12 FAILED: " .. tostring(err12))
end
print("Test 12 " .. (success12 and "PASSED" or "FAILED"))

print("")
print("=== GUI TEST COMPLETE ===")
print("If you see the GUI, it works!")
print("Check which tests FAILED to identify the issue.")
print("")
print("To remove test GUI, run:")
print("  game:GetService('CoreGui'):FindFirstChild('TestGui'):Destroy()")
