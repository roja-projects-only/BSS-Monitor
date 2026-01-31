--[[
    BSS Monitor - Scanner Module
    Handles scanning player hives from workspace
    https://github.com/roja-projects-only/BSS-Monitor
]]

local Scanner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references (loaded lazily)
local BeeTypes = nil

-- Try to load BeeTypes for color/rarity info
pcall(function()
    BeeTypes = require(ReplicatedStorage:WaitForChild("BeeTypes", 5))
end)

-- Helper: Check if cell is gifted
function Scanner.IsCellGifted(cell)
    -- Method 1: Check for Gifted BoolValue
    local giftedVal = cell:FindFirstChild("Gifted") or cell:FindFirstChild("IsGifted") or cell:FindFirstChild("CellGifted")
    if giftedVal then
        if giftedVal:IsA("BoolValue") then
            return giftedVal.Value
        else
            return true
        end
    end
    
    -- Method 2: Check Backplate material - Gifted bees have Neon material
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
        end
    end
    
    -- Method 4: Check for a "Star" or "GiftedStar" part
    for _, child in ipairs(cell:GetChildren()) do
        local lowerName = child.Name:lower()
        if lowerName:find("star") or lowerName:find("gifted") then
            return true
        end
    end
    
    return false
end

-- Helper: Extract level from cell visual elements
function Scanner.ExtractLevelFromCell(cell)
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
    
    -- Method 2: Check all IntValue/NumberValue children
    for _, child in ipairs(cell:GetChildren()) do
        if child:IsA("IntValue") or child:IsA("NumberValue") then
            local val = child.Value
            if val and val >= 1 and val <= 25 then
                local lowerName = child.Name:lower()
                if lowerName:find("lvl") or lowerName:find("level") then
                    return val
                end
            end
        end
    end
    
    -- Method 3: Scan descendants for TextLabel containing a number
    for _, descendant in ipairs(cell:GetDescendants()) do
        if descendant:IsA("TextLabel") then
            local text = descendant.Text
            if text then
                local num = tonumber(text)
                if num and num >= 1 and num <= 25 then
                    return num
                end
            end
        end
    end
    
    -- Method 4: Check Backplate descendants
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
    
    return level
end

-- Scan a single honeycomb and return hive data
function Scanner.ScanHoneycomb(honeycomb, config)
    local playerRef = honeycomb:FindFirstChild("PlayerRef") or honeycomb:FindFirstChild("Owner")
    local playerName = nil
    local playerId = 0
    
    -- Get player info
    if playerRef and playerRef:IsA("ObjectValue") and playerRef.Value then
        if playerRef.Value:IsA("Player") then
            playerName = playerRef.Value.Name
            playerId = playerRef.Value.UserId
        end
    end
    
    if not playerName then
        return nil
    end
    
    local cellsFolder = honeycomb:FindFirstChild("Cells")
    if not cellsFolder then
        return nil
    end
    
    local hiveData = {
        playerName = playerName,
        playerId = playerId,
        totalBees = 0,
        unlockedSlots = 0,
        bees = {},
        levelSum = 0,
        giftedCount = 0,
        levelCounts = {},
        grid = {}
    }
    
    -- Initialize grid
    for x = 1, config.HIVE_SIZE_X do
        hiveData.grid[x] = {}
        for y = 1, config.HIVE_SIZE_Y do
            hiveData.grid[x][y] = nil
        end
    end
    
    for _, cell in ipairs(cellsFolder:GetChildren()) do
        -- Get cell position
        local cellX, cellY = cell.Name:match("C(%d+),(%d+)")
        cellX = tonumber(cellX)
        cellY = tonumber(cellY)
        
        if not cellX then
            local cellXVal = cell:FindFirstChild("CellX")
            local cellYVal = cell:FindFirstChild("CellY")
            if cellXVal and cellYVal then
                cellX = cellXVal.Value
                cellY = cellYVal.Value
            end
        end
        
        -- Check if cell is unlocked
        local cellLocked = cell:FindFirstChild("CellLocked")
        if cellLocked and not cellLocked.Value then
            hiveData.unlockedSlots = hiveData.unlockedSlots + 1
        end
        
        -- Check cell type
        local cellType = cell:FindFirstChild("CellType")
        if cellType and cellType.Value and cellType.Value ~= "Empty" then
            hiveData.totalBees = hiveData.totalBees + 1
            
            local beeTypeName = cellType.Value:gsub("Bee$", "")
            local level = Scanner.ExtractLevelFromCell(cell)
            local isGifted = Scanner.IsCellGifted(cell)
            
            hiveData.levelCounts[level] = (hiveData.levelCounts[level] or 0) + 1
            
            if isGifted then
                hiveData.giftedCount = hiveData.giftedCount + 1
            end
            
            hiveData.levelSum = hiveData.levelSum + level
            
            local beeInfo = {
                type = beeTypeName,
                cellType = cellType.Value,
                level = level,
                gifted = isGifted,
                x = cellX,
                y = cellY
            }
            
            table.insert(hiveData.bees, beeInfo)
            
            if cellX and cellY and cellX >= 1 and cellX <= config.HIVE_SIZE_X and cellY >= 1 and cellY <= config.HIVE_SIZE_Y then
                hiveData.grid[cellX][cellY] = beeInfo
            end
        end
    end
    
    if hiveData.totalBees > 0 then
        hiveData.avgLevel = hiveData.levelSum / hiveData.totalBees
    else
        hiveData.avgLevel = 0
    end
    
    return hiveData
end

-- Scan all honeycombs in workspace
function Scanner.ScanAllHives(config)
    local results = {}
    
    local honeycombs = workspace:FindFirstChild("Honeycombs")
    if not honeycombs then return results end
    
    for _, honeycomb in ipairs(honeycombs:GetChildren()) do
        local hiveData = Scanner.ScanHoneycomb(honeycomb, config)
        if hiveData then
            results[hiveData.playerName] = hiveData
        end
    end
    
    return results
end

-- Check if a hive meets requirements
function Scanner.CheckRequirements(hiveData, config)
    local result = {
        passes = false,
        reason = "",
        beesAtLevel = 0,
        percentAtLevel = 0,
        details = {}
    }
    
    -- Check minimum bees
    if hiveData.totalBees < config.MIN_BEES_REQUIRED then
        result.reason = string.format("Not enough bees (%d/%d required)", hiveData.totalBees, config.MIN_BEES_REQUIRED)
        result.passes = true -- Pass if they don't have enough bees (might be new)
        result.details.skipped = true
        return result
    end
    
    -- Count bees at or above minimum level
    local beesAtOrAbove = 0
    for level, count in pairs(hiveData.levelCounts) do
        if level >= config.MINIMUM_LEVEL then
            beesAtOrAbove = beesAtOrAbove + count
        end
    end
    
    result.beesAtLevel = beesAtOrAbove
    result.percentAtLevel = beesAtOrAbove / hiveData.totalBees
    
    -- Check if meets percentage requirement
    if result.percentAtLevel >= config.REQUIRED_PERCENT then
        result.passes = true
        result.reason = string.format("%.1f%% bees at Lv%d+ (%.1f%% required)", 
            result.percentAtLevel * 100, config.MINIMUM_LEVEL, config.REQUIRED_PERCENT * 100)
    else
        result.passes = false
        result.reason = string.format("Only %.1f%% bees at Lv%d+ (%.1f%% required)", 
            result.percentAtLevel * 100, config.MINIMUM_LEVEL, config.REQUIRED_PERCENT * 100)
    end
    
    result.details = {
        totalBees = hiveData.totalBees,
        beesAtLevel = beesAtOrAbove,
        percentAtLevel = result.percentAtLevel,
        avgLevel = hiveData.avgLevel,
        giftedCount = hiveData.giftedCount
    }
    
    return result
end

return Scanner
