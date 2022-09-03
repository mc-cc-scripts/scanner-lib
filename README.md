# scanner-lib

library for the scanner - from Advanced Peripherals

---

## functions

```lua
--- Find ores nearby (distance), specified by the "interestingBlocks" Setting \n
--- Writes into the filepath specified in the "ScanFiltered" Setting
---@param distance number
---@return ScanDataTable | table
function Scanner.find(distance)

--- Sorts the Table by distance. Distance is recalculated after each closest Or is found
--- Writes into the filePath specified in the "ScanSorted" Setting
--- TODO: Dont let the Quicksort run completly, maybe do a bubblesort for this
---@param scanResult ScanDataTable
---@return ScanDataTable | table
function Scanner.sortFilteredScan(scanResult)

---Creates a Path from a Table of <ScanData>
---@param orderedScanData ScanDataTable | table
---@return table Path Example: {"f4, u2, tR, f2", "d2, tR, f2, tR, f4"}
function Scanner.createPath(orderedScanData)
```

---

## Example

```lua
---@class Scanner
local scanner = require("Scanner");

---@class turtleController
-- used to interpet & execute the path
local tController = require("TurtleControler")

-- <turtleController specific>
-- Allow the turtle to make the specified path and break the block
tController.canBeakblocks = true

local distance = ScanSettings.setGet("Scan", nil, 7)

local scan = scanner.find(distance);
scan = scanner.sortFilteredScan(scan)
local path = scanner.createPath(scan);
-- for testing:
-- textutils.pagedPrint(textutils.serialise(path))

for k, v in pairs(path) do
    tController:compactMove(v)
end
```
