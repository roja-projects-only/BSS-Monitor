--[[
    Player Hive Checker v3
    Scans all players in the server and displays their hive slot count and bee levels.
    Uses universal variables for external executor compatibility.
    Displays results in GUI.
    Execute with a Roblox script executor.
]]

-- Universal variable setup for external executors
local env = getgenv and getgenv() or _G
env.HiveScanner = env.HiveScanner or {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local HIVE_SIZE_X = 5
local HIVE_SIZE_Y = 10
local MAX_SLOTS = HIVE_SIZE_X * HIVE_SIZE_Y -- 50

-- Store data globally
env.HiveScanner.Data = {}
env.HiveScanner.GUI = nil

-- Load game modules safely
local ClientStatCache, BeeStats, BeeTypes, HoneycombFileTools, LocalBees, Events

local function loadModules()
    local success, err = pcall(function()
        ClientStatCache = require(ReplicatedStorage:WaitForChild("ClientStatCache", 5))
        BeeStats = require(ReplicatedStorage:WaitForChild("BeeStats", 5))
        BeeTypes = require(ReplicatedStorage:WaitForChild("BeeTypes", 5))
        HoneycombFileTools = require(ReplicatedStorage:WaitForChild("HoneycombFileTools", 5))
        Events = require(ReplicatedStorage:WaitForChild("Events", 5))
        
        -- Try to load LocalBees for other players' bee data
        pcall(function()
            LocalBees = require(ReplicatedStorage:WaitForChild("LocalAnimation", 3):WaitForChild("LocalBees", 3))
        end)
    end)
    
    if not success then
        warn("Failed to load some modules:", err)
    end
    return success
end

-- Get local player's honeycomb data from ClientStatCache
local function getLocalPlayerHiveData()
    if not ClientStatCache then return nil end
    
    local stats = ClientStatCache:Get()
    if not stats then return nil end
    
    local result = {
        totalBees = 0,
        unlockedSlots = stats.UnlockedCells or 25,
        bees = {},
        levelSum = 0,
        giftedCount = 0,
        avgLevel = 0,
        byType = {},
        byColor = { Red = 0, Blue = 0, White = 0, Colorless = 0 }
    }
    
    local honeycomb = stats.Honeycomb
    if not honeycomb then return result end
    
    -- Iterate through honeycomb grid
    for x = 1, HIVE_SIZE_X do
        local column = honeycomb["x" .. x]
        if column then
            for y = 1, HIVE_SIZE_Y do
                local beeFile = column["y" .. y]
                if beeFile and beeFile.Type then
                    result.totalBees = result.totalBees + 1
                    
                    local beeType = beeFile.Type
                    local level = beeFile.Lvl or 1
                    local isGifted = false
                    
                    -- Check for gifted trait
                    if beeFile.Traits then
                        for _, trait in ipairs(beeFile.Traits) do
                            if trait == "Gifted" then
                                isGifted = true
                                result.giftedCount = result.giftedCount + 1
                                break
                            end
                        end
                    end
                    
                    result.levelSum = result.levelSum + level
                    result.byType[beeType] = (result.byType[beeType] or 0) + 1
                    
                    -- Get color
                    if BeeTypes then
                        local colorType = BeeTypes:GetStat(beeType, "ColorType")
                        if colorType == "Red" then
                            result.byColor.Red = result.byColor.Red + 1
                        elseif colorType == "Blue" then
                            result.byColor.Blue = result.byColor.Blue + 1
                        elseif colorType == "White" then
                            result.byColor.White = result.byColor.White + 1
                        else
                            result.byColor.Colorless = result.byColor.Colorless + 1
                        end
                    end
                    
                    table.insert(result.bees, {
                        x = x,
                        y = y,
                        type = beeType,
                        level = level,
                        gifted = isGifted,
                        bond = beeFile.Bond or 0
                    })
                end
            end
        end
    end
    
    if result.totalBees > 0 then
        result.avgLevel = result.levelSum / result.totalBees
    end
    
    return result
end

-- Get bee data from LocalBees module (shows active bees for all players)
local function getActiveBeesByOwner()
    local result = {}
    
    if LocalBees and LocalBees.GetOwnerBeeArrays then
        local ownerArrays = LocalBees.GetOwnerBeeArrays()
        if ownerArrays then
            for ownerId, beeArray in pairs(ownerArrays) do
                result[ownerId] = {
                    totalBees = 0,
                    bees = {},
                    levelSum = 0,
                    giftedCount = 0,
                    avgLevel = 0
                }
                
                for _, beeData in ipairs(beeArray) do
                    if beeData.File then
                        local file = beeData.File
                        result[ownerId].totalBees = result[ownerId].totalBees + 1
                        
                        local level = file.Lvl or 1
                        local isGifted = false
                        
                        if BeeStats and file.Traits then
                            isGifted = BeeStats.HasTrait(file, "Gifted")
                        end
                        
                        if isGifted then
                            result[ownerId].giftedCount = result[ownerId].giftedCount + 1
                        end
                        
                        result[ownerId].levelSum = result[ownerId].levelSum + level
                        
                        table.insert(result[ownerId].bees, {
                            type = file.Type or "Unknown",
                            level = level,
                            gifted = isGifted
                        })
                    end
                end
                
                if result[ownerId].totalBees > 0 then
                    result[ownerId].avgLevel = result[ownerId].levelSum / result[ownerId].totalBees
                end
            end
        end
    end
    
    return result
end

-- Helper function to check if cell is gifted
local function isCellGifted(cell)
    -- Method 1: Check for Gifted BoolValue
    local giftedVal = cell:FindFirstChild("Gifted") or cell:FindFirstChild("IsGifted") or cell:FindFirstChild("CellGifted")
    if giftedVal then
        if giftedVal:IsA("BoolValue") then
            return giftedVal.Value
        else
            return true
        end
    end
    
    -- Method 2: Check Backplate material - Gifted bees have Neon material (shiny golden)
    local backplate = cell:FindFirstChild("Backplate")
    if backplate then
        if backplate.Material == Enum.Material.Neon or backplate.Material == Enum.Material.ForceField then
            return true
        end
    end
    
    -- Method 3: Check for ParticleEmitter (gifted sparkles)
    for _, desc in ipairs(cell:GetDescendants()) do
        if desc:IsA("ParticleEmitter") then
            local name = desc.Name:lower()
            if name:find("gifted") or name:find("sparkle") or name:find("star") then
                return true
            end
            -- Gifted emitters usually have star-like textures
            if desc.Texture and desc.Texture:find("star") then
                return true
            end
        end
    end
    
    -- Method 4: Check for a "Star" or "GiftedStar" part
    for _, child in ipairs(cell:GetChildren()) do
        local lowerName = child.Name:lower()
        if lowerName:find("star") or lowerName:find("gifted") then
            return true
        end
    end
    
    -- Method 5: Check BeeFace decal for gifted texture
    local beeFace = cell:FindFirstChild("BeeFace")
    if beeFace then
        for _, decal in ipairs(beeFace:GetDescendants()) do
            if decal:IsA("Decal") or decal:IsA("Texture") then
                -- Gifted faces have different texture IDs
                if decal.Color3 then
                    -- Gifted faces tend to have golden/star color tint
                    local r, g, b = decal.Color3.R, decal.Color3.G, decal.Color3.B
                    -- Check if it's not the default white (gifted bees have colored faces)
                    if r ~= 1 or g ~= 1 or b ~= 1 then
                        -- Could be gifted - but this is unreliable, keep as fallback
                    end
                end
            end
        end
    end
    
    return false
end

-- Helper function to extract level from cell visual elements
local function extractLevelFromCell(cell)
    local level = 1
    
    -- Method 1: Check for various level value names directly on cell
    local possibleNames = {"BeeLvl", "BeeLevel", "Level", "Lvl", "CellLevel"}
    for _, name in ipairs(possibleNames) do
        local val = cell:FindFirstChild(name)
        if val then
            if val:IsA("IntValue") or val:IsA("NumberValue") then
                if val.Value and val.Value >= 1 then
                    return val.Value
                end
            elseif val:IsA("StringValue") then
                local num = tonumber(val.Value)
                if num and num >= 1 then
                    return num
                end
            end
        end
    end
    
    -- Method 2: Check all IntValue/NumberValue children for level-like values
    for _, child in ipairs(cell:GetChildren()) do
        if child:IsA("IntValue") or child:IsA("NumberValue") then
            local val = child.Value
            -- Level is usually between 1-25
            if val and val >= 1 and val <= 25 then
                -- Check if name suggests it's a level
                local lowerName = child.Name:lower()
                if lowerName:find("lvl") or lowerName:find("level") then
                    return val
                end
            end
        end
    end
    
    -- Method 3: Scan descendants for SurfaceGui or BillboardGui with TextLabel containing a number
    for _, descendant in ipairs(cell:GetDescendants()) do
        if descendant:IsA("TextLabel") then
            local text = descendant.Text
            if text then
                -- Try to extract a number (level is usually 1-25)
                local num = tonumber(text)
                if num and num >= 1 and num <= 25 then
                    level = num
                    return level
                end
            end
        end
    end
    
    -- Method 4: Check Backplate for any attached GUI with level
    local backplate = cell:FindFirstChild("Backplate")
    if backplate then
        for _, child in ipairs(backplate:GetDescendants()) do
            if child:IsA("TextLabel") and child.Text then
                local num = tonumber(child.Text)
                if num and num >= 1 and num <= 25 then
                    return num
                end
            end
        end
    end
    
    -- Method 5: Check WingLeft/WingRight parts for level display
    local wings = {cell:FindFirstChild("WingLeft"), cell:FindFirstChild("WingRight"), 
                   cell:FindFirstChild("Wings"), cell:FindFirstChild("Wing")}
    for _, wing in ipairs(wings) do
        if wing then
            for _, desc in ipairs(wing:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text then
                    local num = tonumber(desc.Text)
                    if num and num >= 1 and num <= 25 then
                        return num
                    end
                end
            end
        end
    end
    
    return level
end

-- Scan honeycomb cells from workspace (visual inspection)
local function scanWorkspaceHoneycombs()
    local results = {}
    
    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if not honeycombs then return results end
    
    for _, honeycomb in ipairs(honeycombs:GetChildren()) do
        local playerRef = honeycomb:FindFirstChild("PlayerRef") or honeycomb:FindFirstChild("Owner")
        local playerName = nil
        local playerId = 0
        
        -- Get player info - skip if no valid player
        if playerRef and playerRef:IsA("ObjectValue") and playerRef.Value then
            if playerRef.Value:IsA("Player") then
                playerName = playerRef.Value.Name
                playerId = playerRef.Value.UserId
            end
        end
        
        -- Only process honeycombs with a valid player (skip unclaimed or player left)
        if playerName then
            local cellsFolder = honeycomb:FindFirstChild("Cells")
            if cellsFolder then
                local hiveData = {
                playerName = playerName,
                playerId = playerId,
                totalBees = 0,
                unlockedSlots = 0,
                bees = {},
                levelSum = 0,
                giftedCount = 0,
                levelCounts = {} -- Track count per level
            }
            
            for _, cell in ipairs(cellsFolder:GetChildren()) do
                -- Check if cell is unlocked
                local cellLocked = cell:FindFirstChild("CellLocked")
                if cellLocked and not cellLocked.Value then
                    hiveData.unlockedSlots = hiveData.unlockedSlots + 1
                end
                
                -- Check cell type (BeeType)
                local cellType = cell:FindFirstChild("CellType")
                if cellType and cellType.Value and cellType.Value ~= "Empty" then
                    hiveData.totalBees = hiveData.totalBees + 1
                    
                    -- Cell type is like "BasicBee", "CarpenterBee", etc
                    local beeTypeName = cellType.Value:gsub("Bee$", "")
                    
                    -- Extract level from visual elements
                    local level = extractLevelFromCell(cell)
                    
                    -- Track level count
                    hiveData.levelCounts[level] = (hiveData.levelCounts[level] or 0) + 1
                    
                    -- Check for gifted using dedicated function
                    local isGifted = isCellGifted(cell)
                    
                    if isGifted then
                        hiveData.giftedCount = hiveData.giftedCount + 1
                    end
                    
                    hiveData.levelSum = hiveData.levelSum + level
                    
                    table.insert(hiveData.bees, {
                        type = beeTypeName,
                        cellType = cellType.Value,
                        level = level,
                        gifted = isGifted
                    })
                end
            end
            
            if hiveData.totalBees > 0 then
                hiveData.avgLevel = hiveData.levelSum / hiveData.totalBees
            else
                hiveData.avgLevel = 0
            end
            
            results[playerName] = hiveData
            end
        end
    end
    
    return results
end

-- Main scanner function
local function scanAllPlayers()
    print("\n" .. string.rep("=", 60))
    print("           PLAYER HIVE SCANNER v2")
    print(string.rep("=", 60))
    
    -- Scan workspace honeycombs
    local honeycombData = scanWorkspaceHoneycombs()
    local activeBees = getActiveBeesByOwner()
    
    print("Found " .. (function()
        local count = 0
        for _ in pairs(honeycombData) do count = count + 1 end
        return count
    end)() .. " hives in workspace\n")
    
    for playerName, data in pairs(honeycombData) do
        print(string.rep("-", 50))
        print("Player: " .. playerName)
        print(string.rep("-", 50))
        print("  Unlocked Slots: " .. data.unlockedSlots .. "/" .. MAX_SLOTS)
        print("  Bees in Hive: " .. data.totalBees)
        print("  Gifted Bees: " .. data.giftedCount)
        
        if data.totalBees > 0 then
            print("  Average Level: " .. string.format("%.2f", data.avgLevel))
            
            -- Show level distribution
            if data.levelCounts then
                print("\n  [Level Distribution]")
                local sortedLevels = {}
                for lvl, _ in pairs(data.levelCounts) do
                    table.insert(sortedLevels, lvl)
                end
                table.sort(sortedLevels, function(a, b) return a > b end)
                
                for _, lvl in ipairs(sortedLevels) do
                    local count = data.levelCounts[lvl]
                    if count > 0 then
                        local bar = string.rep("█", math.min(count, 25))
                        print(string.format("  Lvl %2d: %s (%d)", lvl, bar, count))
                    end
                end
            end
        end
        
        -- Check active bees from LocalBees
        if data.playerId > 0 and activeBees[data.playerId] then
            local active = activeBees[data.playerId]
            print("\n  [Active Flying Bees]")
            print("  Active: " .. active.totalBees)
            if active.totalBees > 0 then
                print("  Active Avg Lvl: " .. string.format("%.2f", active.avgLevel))
            end
        end
        
        print("")
    end
    
    print(string.rep("=", 60))
    print("Scan complete!")
    print(string.rep("=", 60))
end

-- Detailed local player scan
local function detailedScan()
    print("\n" .. string.rep("=", 60))
    print("DETAILED HIVE SCAN: " .. LocalPlayer.Name)
    print(string.rep("=", 60))
    
    local data = getLocalPlayerHiveData()
    
    if not data then
        print("Failed to get hive data. Make sure you're in the game with a hive.")
        return
    end
    
    print("\n[HIVE OVERVIEW]")
    print("  Unlocked Slots: " .. data.unlockedSlots .. "/" .. MAX_SLOTS)
    print("  Total Bees: " .. data.totalBees)
    print("  Gifted Bees: " .. data.giftedCount)
    print("  Average Level: " .. string.format("%.2f", data.avgLevel))
    print("  Total Level Sum: " .. data.levelSum)
    
    print("\n[COLOR DISTRIBUTION]")
    print("  Red: " .. data.byColor.Red)
    print("  Blue: " .. data.byColor.Blue)
    print("  White: " .. data.byColor.White)
    print("  Colorless: " .. data.byColor.Colorless)
    
    print("\n[LEVEL DISTRIBUTION]")
    local levelCounts = {}
    for _, bee in ipairs(data.bees) do
        levelCounts[bee.level] = (levelCounts[bee.level] or 0) + 1
    end
    
    local sortedLevels = {}
    for lvl, _ in pairs(levelCounts) do
        table.insert(sortedLevels, lvl)
    end
    table.sort(sortedLevels, function(a, b) return a > b end)
    
    for _, lvl in ipairs(sortedLevels) do
        local count = levelCounts[lvl]
        local bar = string.rep("█", math.min(count, 30))
        print(string.format("  Lvl %2d: %s (%d)", lvl, bar, count))
    end
    
    print("\n[ALL BEES]")
    print(string.format("  %-20s %-6s %-8s %-10s", "Type", "Level", "Gifted", "Bond"))
    print("  " .. string.rep("-", 50))
    
    -- Sort by level descending
    table.sort(data.bees, function(a, b) return a.level > b.level end)
    
    for _, bee in ipairs(data.bees) do
        local giftedMark = bee.gifted and "★" or ""
        print(string.format("  %-20s Lv%-4d %-8s %d", 
            bee.type, bee.level, giftedMark, bee.bond))
    end
end

-- Detailed local player scan (console version)
local function detailedScan()
    print("\n" .. string.rep("=", 60))
    print("DETAILED HIVE SCAN: " .. LocalPlayer.Name)
    print(string.rep("=", 60))
    
    local data = getLocalPlayerHiveData()
    
    if not data then
        print("Failed to get hive data. Make sure you're in the game with a hive.")
        return
    end
    
    print("\n[HIVE OVERVIEW]")
    print("  Unlocked Slots: " .. data.unlockedSlots .. "/" .. MAX_SLOTS)
    print("  Total Bees: " .. data.totalBees)
    print("  Gifted Bees: " .. data.giftedCount)
    print("  Average Level: " .. string.format("%.2f", data.avgLevel))
    print("  Total Level Sum: " .. data.levelSum)
    
    print("\n[COLOR DISTRIBUTION]")
    print("  Red: " .. data.byColor.Red)
    print("  Blue: " .. data.byColor.Blue)
    print("  White: " .. data.byColor.White)
    print("  Colorless: " .. data.byColor.Colorless)
    
    print("\n[LEVEL DISTRIBUTION]")
    local levelCounts = {}
    for _, bee in ipairs(data.bees) do
        levelCounts[bee.level] = (levelCounts[bee.level] or 0) + 1
    end
    
    local sortedLevels = {}
    for lvl, _ in pairs(levelCounts) do
        table.insert(sortedLevels, lvl)
    end
    table.sort(sortedLevels, function(a, b) return a > b end)
    
    for _, lvl in ipairs(sortedLevels) do
        local count = levelCounts[lvl]
        local bar = string.rep("█", math.min(count, 30))
        print(string.format("  Lvl %2d: %s (%d)", lvl, bar, count))
    end
    
    print("\n[ALL BEES]")
    print(string.format("  %-20s %-6s %-8s %-10s", "Type", "Level", "Gifted", "Bond"))
    print("  " .. string.rep("-", 50))
    
    -- Sort by level descending
    table.sort(data.bees, function(a, b) return a.level > b.level end)
    
    for _, bee in ipairs(data.bees) do
        local giftedMark = bee.gifted and "★" or ""
        print(string.format("  %-20s Lv%-4d %-8s %d", 
            bee.type, bee.level, giftedMark, bee.bond))
    end
end

-- Quick summary function (console version)
local function quickSummary()
    print("\n" .. string.rep("=", 60))
    print("[QUICK HIVE SUMMARY]")
    print(string.rep("=", 60))
    
    local honeycombData = scanWorkspaceHoneycombs()
    
    print(string.format("%-16s %-6s %-8s %-10s %-8s", "Player", "Slots", "Bees", "Avg Level", "Gifted"))
    print(string.rep("-", 55))
    
    for playerName, data in pairs(honeycombData) do
        local avgLvl = data.totalBees > 0 and string.format("%.1f", data.avgLevel) or "N/A"
        print(string.format("%-16s %-6d %-8d %-10s %-8d", 
            playerName:sub(1, 16), 
            data.unlockedSlots,
            data.totalBees, 
            avgLvl, 
            data.giftedCount
        ))
        
        -- Show level distribution if bees exist
        if data.totalBees > 0 and data.levelCounts then
            local levelStr = "  Levels: "
            local sortedLevels = {}
            for lvl, _ in pairs(data.levelCounts) do
                table.insert(sortedLevels, lvl)
            end
            table.sort(sortedLevels, function(a, b) return a > b end)
            
            local parts = {}
            for _, lvl in ipairs(sortedLevels) do
                local count = data.levelCounts[lvl]
                if count > 0 then
                    table.insert(parts, "Lv" .. lvl .. "=" .. count)
                end
            end
            print(levelStr .. table.concat(parts, ", "))
        end
    end
    
    -- Also show local player data from ClientStatCache if available
    local localData = getLocalPlayerHiveData()
    if localData and localData.totalBees > 0 then
        print("\n[YOUR DETAILED STATS]")
        print("  Bees: " .. localData.totalBees .. "/" .. localData.unlockedSlots)
        print("  Avg Level: " .. string.format("%.2f", localData.avgLevel))
        print("  Gifted: " .. localData.giftedCount)
        print("  Colors - R:" .. localData.byColor.Red .. " B:" .. localData.byColor.Blue .. " W:" .. localData.byColor.White)
    end
end

-- Create the main GUI
local function createMainGui()
    -- Destroy existing GUI
    if env.HiveScanner.GUI then
        env.HiveScanner.GUI:Destroy()
        env.HiveScanner.GUI = nil
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HiveScannerGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 450, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 180, 0)
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners of title
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0.5, 0)
    titleFix.Position = UDim2.new(0, 0, 0.5, 0)
    titleFix.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🐝 Hive Scanner v3"
    titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -32, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        env.HiveScanner.GUI = nil
    end)
    
    -- Content frame with scroll
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -20, 1, -80)
    contentFrame.Position = UDim2.new(0, 10, 0, 40)
    contentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 180, 0)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 6)
    contentCorner.Parent = contentFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = contentFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = contentFrame
    
    -- Bottom buttons
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Name = "Buttons"
    buttonFrame.Size = UDim2.new(1, -20, 0, 35)
    buttonFrame.Position = UDim2.new(0, 10, 1, -40)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = mainFrame
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonFrame
    
    local function createButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.Parent = buttonFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Store references
    env.HiveScanner.GUI = screenGui
    env.HiveScanner.ContentFrame = contentFrame
    
    -- Try different parent methods for executor compatibility
    local success = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
        end
    end)
    
    pcall(function()
        if gethui then
            screenGui.Parent = gethui()
        elseif game:GetService("CoreGui") then
            screenGui.Parent = game:GetService("CoreGui")
        else
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
    
    return screenGui, contentFrame, createButton
end

-- Add a player entry to the GUI
local function addPlayerEntry(contentFrame, playerName, data, order)
    local entry = Instance.new("Frame")
    entry.Name = playerName
    entry.Size = UDim2.new(1, -10, 0, 0)
    entry.AutomaticSize = Enum.AutomaticSize.Y
    entry.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    entry.BorderSizePixel = 0
    entry.LayoutOrder = order
    entry.Parent = contentFrame
    
    local entryCorner = Instance.new("UICorner")
    entryCorner.CornerRadius = UDim.new(0, 6)
    entryCorner.Parent = entry
    
    local entryPadding = Instance.new("UIPadding")
    entryPadding.PaddingTop = UDim.new(0, 8)
    entryPadding.PaddingBottom = UDim.new(0, 8)
    entryPadding.PaddingLeft = UDim.new(0, 10)
    entryPadding.PaddingRight = UDim.new(0, 10)
    entryPadding.Parent = entry
    
    local entryLayout = Instance.new("UIListLayout")
    entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    entryLayout.Padding = UDim.new(0, 4)
    entryLayout.Parent = entry
    
    -- Player name header
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "👤 " .. playerName
    nameLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.LayoutOrder = 1
    nameLabel.Parent = entry
    
    -- Stats row
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, 0, 0, 16)
    statsLabel.BackgroundTransparency = 1
    local avgLvl = data.totalBees > 0 and string.format("%.1f", data.avgLevel) or "N/A"
    statsLabel.Text = string.format("Slots: %d/%d  |  Bees: %d  |  Avg Lvl: %s  |  ⭐Gifted: %d", 
        data.unlockedSlots, MAX_SLOTS, data.totalBees, avgLvl, data.giftedCount)
    statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statsLabel.TextSize = 13
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.LayoutOrder = 2
    statsLabel.Parent = entry
    
    -- Level distribution
    if data.totalBees > 0 and data.levelCounts then
        local sortedLevels = {}
        for lvl, _ in pairs(data.levelCounts) do
            table.insert(sortedLevels, lvl)
        end
        table.sort(sortedLevels, function(a, b) return a > b end)
        
        local levelParts = {}
        for _, lvl in ipairs(sortedLevels) do
            local count = data.levelCounts[lvl]
            if count > 0 then
                table.insert(levelParts, "Lv" .. lvl .. "=" .. count)
            end
        end
        
        local levelLabel = Instance.new("TextLabel")
        levelLabel.Size = UDim2.new(1, 0, 0, 16)
        levelLabel.BackgroundTransparency = 1
        levelLabel.Text = "📊 " .. table.concat(levelParts, ", ")
        levelLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
        levelLabel.TextSize = 12
        levelLabel.Font = Enum.Font.Gotham
        levelLabel.TextXAlignment = Enum.TextXAlignment.Left
        levelLabel.TextWrapped = true
        levelLabel.AutomaticSize = Enum.AutomaticSize.Y
        levelLabel.LayoutOrder = 3
        levelLabel.Parent = entry
    end
    
    return entry
end

-- Display scan results in GUI
local function displayResults()
    local gui, contentFrame, createButton = createMainGui()
    
    -- Clear existing content (except layout)
    for _, child in ipairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Scan and display
    local honeycombData = scanWorkspaceHoneycombs()
    env.HiveScanner.Data = honeycombData
    
    local order = 1
    for playerName, data in pairs(honeycombData) do
        addPlayerEntry(contentFrame, playerName, data, order)
        order = order + 1
    end
    
    -- Add buttons
    createButton("Refresh", function()
        displayResults()
    end)
    
    createButton("My Hive", function()
        showDetailedHive()
    end)
    
    print("🐝 Hive Scanner: Displayed " .. (order - 1) .. " hives in GUI")
end

-- Show detailed view of local player's hive
local function showDetailedHive()
    local data = getLocalPlayerHiveData()
    if not data or data.totalBees == 0 then
        warn("No hive data found for local player")
        return
    end
    
    local gui, contentFrame = createMainGui()
    
    -- Clear existing content
    for _, child in ipairs(contentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Header
    local headerEntry = Instance.new("Frame")
    headerEntry.Size = UDim2.new(1, -10, 0, 80)
    headerEntry.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    headerEntry.BorderSizePixel = 0
    headerEntry.Parent = contentFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 6)
    headerCorner.Parent = headerEntry
    
    local headerText = Instance.new("TextLabel")
    headerText.Size = UDim2.new(1, -20, 1, 0)
    headerText.Position = UDim2.new(0, 10, 0, 0)
    headerText.BackgroundTransparency = 1
    headerText.Text = string.format(
        "🐝 YOUR HIVE\n\nBees: %d/%d  |  Avg Level: %.2f  |  ⭐Gifted: %d\nColors - 🔴Red: %d  🔵Blue: %d  ⚪White: %d",
        data.totalBees, data.unlockedSlots, data.avgLevel, data.giftedCount,
        data.byColor.Red, data.byColor.Blue, data.byColor.White
    )
    headerText.TextColor3 = Color3.fromRGB(255, 200, 0)
    headerText.TextSize = 14
    headerText.Font = Enum.Font.GothamBold
    headerText.TextXAlignment = Enum.TextXAlignment.Left
    headerText.TextYAlignment = Enum.TextYAlignment.Center
    headerText.Parent = headerEntry
    
    -- Level distribution
    local levelCounts = {}
    for _, bee in ipairs(data.bees) do
        levelCounts[bee.level] = (levelCounts[bee.level] or 0) + 1
    end
    
    local sortedLevels = {}
    for lvl, _ in pairs(levelCounts) do
        table.insert(sortedLevels, lvl)
    end
    table.sort(sortedLevels, function(a, b) return a > b end)
    
    for _, lvl in ipairs(sortedLevels) do
        local count = levelCounts[lvl]
        if count > 0 then
            local lvlEntry = Instance.new("Frame")
            lvlEntry.Size = UDim2.new(1, -10, 0, 25)
            lvlEntry.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
            lvlEntry.BorderSizePixel = 0
            lvlEntry.Parent = contentFrame
            
            local lvlCorner = Instance.new("UICorner")
            lvlCorner.CornerRadius = UDim.new(0, 4)
            lvlCorner.Parent = lvlEntry
            
            local lvlLabel = Instance.new("TextLabel")
            lvlLabel.Size = UDim2.new(0, 60, 1, 0)
            lvlLabel.Position = UDim2.new(0, 10, 0, 0)
            lvlLabel.BackgroundTransparency = 1
            lvlLabel.Text = "Lv " .. lvl
            lvlLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            lvlLabel.TextSize = 14
            lvlLabel.Font = Enum.Font.GothamBold
            lvlLabel.TextXAlignment = Enum.TextXAlignment.Left
            lvlLabel.Parent = lvlEntry
            
            -- Bar
            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -100, 0, 15)
            barBg.Position = UDim2.new(0, 70, 0.5, -7)
            barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            barBg.BorderSizePixel = 0
            barBg.Parent = lvlEntry
            
            local barBgCorner = Instance.new("UICorner")
            barBgCorner.CornerRadius = UDim.new(0, 3)
            barBgCorner.Parent = barBg
            
            local barFill = Instance.new("Frame")
            local fillPercent = math.min(count / data.totalBees, 1)
            barFill.Size = UDim2.new(fillPercent, 0, 1, 0)
            barFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
            barFill.BorderSizePixel = 0
            barFill.Parent = barBg
            
            local barFillCorner = Instance.new("UICorner")
            barFillCorner.CornerRadius = UDim.new(0, 3)
            barFillCorner.Parent = barFill
            
            local countLabel = Instance.new("TextLabel")
            countLabel.Size = UDim2.new(0, 30, 1, 0)
            countLabel.Position = UDim2.new(1, -35, 0, 0)
            countLabel.BackgroundTransparency = 1
            countLabel.Text = tostring(count)
            countLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            countLabel.TextSize = 13
            countLabel.Font = Enum.Font.Gotham
            countLabel.Parent = lvlEntry
        end
    end
end

-- Debug function to inspect cell structure
local function debugCell()
    print("\n[DEBUG: Cell Structure Inspection]")
    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if not honeycombs then 
        print("No Honeycombs folder found!")
        return 
    end
    
    for _, honeycomb in ipairs(honeycombs:GetChildren()) do
        local cells = honeycomb:FindFirstChild("Cells")
        if cells then
            for _, cell in ipairs(cells:GetChildren()) do
                local cellType = cell:FindFirstChild("CellType")
                if cellType and cellType.Value and cellType.Value ~= "Empty" then
                    print("\n=== Cell: " .. cell.Name .. " ===")
                    print("CellType: " .. tostring(cellType.Value))
                    
                    -- Check gifted status
                    print("Gifted check: " .. tostring(isCellGifted(cell)))
                    
                    -- Check backplate material
                    local backplate = cell:FindFirstChild("Backplate")
                    if backplate then
                        print("Backplate Material: " .. tostring(backplate.Material))
                        print("Backplate Color: " .. tostring(backplate.Color))
                    end
                    
                    -- List all direct children
                    print("Direct children:")
                    for _, child in ipairs(cell:GetChildren()) do
                        local valStr = ""
                        if child:IsA("ValueBase") then
                            valStr = " = " .. tostring(child.Value)
                        end
                        print("  - " .. child.Name .. " (" .. child.ClassName .. ")" .. valStr)
                    end
                    
                    -- List all descendants with text
                    print("Descendants with Text property:")
                    for _, desc in ipairs(cell:GetDescendants()) do
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                            print("  - " .. desc:GetFullName() .. " Text: '" .. tostring(desc.Text) .. "'")
                        end
                    end
                    
                    -- Check for particle emitters
                    print("Particle Emitters:")
                    for _, desc in ipairs(cell:GetDescendants()) do
                        if desc:IsA("ParticleEmitter") then
                            print("  - " .. desc.Name .. " (Texture: " .. tostring(desc.Texture) .. ")")
                        end
                    end
                    
                    -- Only inspect first non-empty cell
                    return
                end
            end
        end
    end
    print("No non-empty cells found!")
end

-- Initialize
print("🐝 Hive Scanner v3 Loading...")
loadModules()
print("🐝 Hive Scanner v3 Loaded!")
print("Commands (also available via getgenv().HiveScanner):")
print("  displayResults()  - Open GUI with all hives")
print("  showDetailedHive() - Show your detailed hive in GUI")
print("  detailedScan()    - Print your detailed hive to console")
print("  scanAllPlayers()  - Print scan to console")
print("  quickSummary()    - Print summary to console")
print("  debugCell()       - Debug cell structure")
print("")

-- Store functions in universal variable
env.HiveScanner.display = displayResults
env.HiveScanner.myHive = showDetailedHive
env.HiveScanner.scan = scanAllPlayers
env.HiveScanner.quick = quickSummary
env.HiveScanner.detail = detailedScan
env.HiveScanner.debug = debugCell
env.HiveScanner.reload = loadModules

-- Auto-display GUI
displayResults()

-- Return functions for manual use
return {
    display = displayResults,
    myHive = showDetailedHive,
    scan = scanAllPlayers,
    quick = quickSummary,
    detail = detailedScan,
    debug = debugCell,
    reload = loadModules,
    getData = function() return env.HiveScanner.Data end
}
