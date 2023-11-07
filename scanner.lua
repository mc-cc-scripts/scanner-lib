---@class Scanner
-- Settings:
-- - Setting: ScanDataFile
-- - Setting: InterestingBlocks
-- - Setting: ScanFiltered
-- - Setting: ScanSorted
Scanner = {}





-- REQUIREMENTS
--@requires helperFunctions
---@class HelperFunctions
local helper = require("./libs/helperFunctions");
--@requires turtleController
---@class turtleController
local tController = require("./libs/turtleController")
--@requires settingsManager
---@class settingManager
local settingsService = require("./libs/settingsManager")
--@requires log
---@class Log
local log = require("./libs/log")

-- DEFINITIONS

-- DEFINITIONS
---@class ScanData
---@field x number
---@field y number
---@field z number
---@field name string

---@class ScanDataTable
---@field _ ScanData


local defaultInterestingBlocks = {
    ["minecraft:deepslate_gold_ore"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:deepslate_iron_ore"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:deepslate_coal_ore"] = true,
    ["minecraft:coal_ore"] = true,
    ["minecraft:deepslate_copper_ore"] = true,
    ["minecraft:copper_ore"] = true,
    ["minecraft:deepslate_emerald_ore"] = true,
    ["minecraft:emerald_ore"] = true,
    ["minecraft:deepslate_lapis_ore"] = true,
    ["minecraft:lapis_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true,
    ["minecraft:diamond_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    ["minecraft:nether_gold_ore"] = true,
    ["minecraft:nether_quartz_ore"] = true,
    ["thermal:apatite_ore"] = true,
    ["thermal:deepslate_apatite_ore"] = true,
    ["thermal:niter_ore"] = true,
    ["thermal:deepslate_niter_ore"] = true,
    ["thermal:nickel_ore"] = true,
    ["thermal:deepslate_nickel_ore"] = true,
    ["thermal:tin_ore"] = true,
    ["thermal:deepslate_tin_ore"] = true,
    ["thermal:silver_ore"] = true,
    ["thermal:deepslate_silver_ore"] = true,
    ["thermal:lead_ore"] = true,
    ["thermal:deepslate_lead_ore"] = true,
    ["thermal:cinnabar_ore"] = true,
    ["thermal:deepslate_cinnabar_ore"] = true,
    ["rftoolsbase:dimensionalshard_end"] = true,
    ["create:zinc_ore"] = true,
    ["create:deepslate_zinc_ore"] = true,
    ["rftoolsbase:dimensionalshard_overworld"] = true,
    ["rftoolsbase:dimensionalshard_nether"] = true,
}

---comment
---@param radius any
---@return ScanDataTable
local function scan(radius)
    ---@type table
    local g = peripheral.find("geoScanner")
    if g == 0 then return nil end
    ---@type ScanDataTable
    local result = g.scan(radius)
    if type(result) == "string" then
        return nil;
    end
    local mapfunc = function(value)
        value["tags"] = nil
        return value
    end
    result = helper.map(result, mapfunc) --[[@as ScanDataTable]]
    -- Should be on its own program
    local filePath = settingsService.setget("ScanDataFile", nil, "./ScanData/LastScanData.lua");
    log.write(result, filePath, "w+")
    return result;
end

-- CONTENT

---local function, required for the filter after the scan
---@param value ScanData
---@param interestingBlocks table
---@return boolean interesting passed the filter?
local filterFunction = function(value, interestingBlocks)
    if type(value) ~= "table" or value.name == nil then
        return false
    end
    return interestingBlocks[value.name] ~= nil
end

--- Find ores nearby (distance), specified by the "interestingBlocks" Setting \n
--- Writes into the filepath specified in the "ScanFiltered" Setting
---@param distance number
---@return ScanDataTable
function Scanner.find(distance)
    local scanResult = scan(distance)
    local interestingBlocks = settingsService.setget("InterestingBlocks", nil, defaultInterestingBlocks)
    scanResult = helper.filter(scanResult, filterFunction, interestingBlocks)
    local filePathFiltered = settingsService.setget("ScanFiltered", nil, "./ScanData/LastScanFiltered.lua");
    log.write(scanResult, filePathFiltered, "w+")
    return scanResult
end

--- Sorts the Table by distance. Distance is recalculated after each closest Or is found
--- Writes into the filePath specified in the "ScanSorted" Setting
--- TODO: Dont let the Quicksort run completly, maybe do a bubblesort for this
---@param scanResult ScanDataTable
---@return ScanDataTable
function Scanner.sortFilteredScan(scanResult)
    local currentPosition = { x = 0, y = 0, z = 0 }
    local func = function(block1, block2, cPosition)
        local calcDist = function(block, currPos)
            local x = block.x - currPos.x;
            local y = block.y - currPos.y;
            local z = block.z - currPos.z;

            return math.sqrt(x ^ 2 + y ^ 2 + z ^ 2)
        end
        return (calcDist(block1, cPosition) > calcDist(block2, cPosition));
    end
    for i = 1, #scanResult, 1 do
        scanResult = HelperFunctions.quickSort(scanResult, i, #scanResult, func, currentPosition);
        currentPosition = scanResult[i];
    end
    local filePathSorted = settingsService.setget("ScanSorted", nil, "./ScanData/LastScanSorted.lua");
    log.write(scanResult, filePathSorted, "w+")
    return scanResult;
end

---@alias rotation
---| 0 # +X
---| 1 # +Z
---| 2 # -X
---| 3 # -Z

---corrects the ScannedPoints relative to the direction the turtle is facing
---@param dataTable ScanDataTable
---@param rotation rotation
function Scanner.correctToFacing(dataTable, rotation)
    ---comment
    ---@param data ScanData
    ---@param rotation rotation
    function map(data, rotation)
        if rotation == 1 then
            local temp = data.x
            data.x = data.z
            data.z = temp * -1
        end
        if rotation == 2 then
            data.x = data.x * -1
            data.z = data.z * -1
        end
        if rotation == 3 then
            local temp = data.x
            data.x = data.z * -1
            data.z = temp
        end
        return data
    end

    return helper.map(dataTable, map, rotation)
end

---Creates a Path from a Table of <ScanData>
---@param orderedScanData ScanDataTable
---@return table Path Example: {"f4, u2, tR, f2", "d2, tR, f2, tR, f4"}
function Scanner.createPath(orderedScanData)
    local currentPosition = { x = 0, y = 0, z = 0 }
    local path = {}
    local rotation = 0;
    local changePos
    local cPath
    local orderedScanDataCopy = helper.copyTable(orderedScanData)
    orderedScanDataCopy[#orderedScanDataCopy + 1] = { x = 0, y = 0, z = 0 }
    for _, v in pairs(orderedScanDataCopy) do
        cPath = ""
        -- y / Height
        if currentPosition.y > v.y then
            cPath = "d" .. currentPosition.y - v.y
        elseif v.y > currentPosition.y then
            cPath = "u" .. v.y - currentPosition.y;
        end

        -- x / Forward / Back
        if v.x > currentPosition.x then
            if cPath ~= "" then cPath = cPath .. "," end
            changePos, rotation = tController:changeRotationTo(tController.roation["forward"], rotation)
            if changePos ~= "" then
                cPath = cPath .. changePos .. ",";
            end
            cPath = cPath .. "f" .. (v.x - currentPosition.x);
        end
        if currentPosition.x > v.x then
            if cPath ~= "" then cPath = cPath .. "," end
            changePos, rotation = tController:changeRotationTo(tController.roation["back"], rotation)
            if changePos ~= "" then
                cPath = cPath .. changePos .. ",";
            end
            cPath = cPath .. "f" .. (currentPosition.x - v.x);
        end
        -- z / left / right
        if v.z > currentPosition.z then
            if cPath ~= "" then cPath = cPath .. "," end
            changePos, rotation = tController:changeRotationTo(tController.roation["right"], rotation)
            if changePos ~= "" then
                cPath = cPath .. changePos .. ",";
            end
            cPath = cPath .. "f" .. (v.z - currentPosition.z);
        end
        if currentPosition.z > v.z then
            if cPath ~= "" then cPath = cPath .. "," end
            changePos, rotation = tController:changeRotationTo(tController.roation["left"], rotation)
            if changePos ~= "" then
                cPath = cPath .. changePos .. ",";
            end
            cPath = cPath .. "f" .. (currentPosition.z - v.z);
        end

        table.insert(path, cPath)
        currentPosition = v;
    end
    local resetRotation = tController:changeRotationTo(0, rotation)
    if resetRotation ~= "" then
        table.insert(path, resetRotation)
    end
    return path;
end

return Scanner
