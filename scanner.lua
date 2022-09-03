---@class FindPathToBlocks
-- Settings:
-- - Setting: ScanDataFile
-- - Setting: InterestingBlocks
-- - Setting: ScanFiltered
-- - Setting: ScanSorted
Scanner = {}





-- REQUIREMENTS
---@class HelperFunctions
local helper = require("HelperFunctions");
---@class turtleController
local tController = require("TurtleControler")
---@class SettingsService
local settingsService = require("SettingsService")
---@class Log
local log = require("Log")

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
    ["minecraft:deepslate_gold_ore"] = true
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
