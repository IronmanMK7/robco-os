-- ComputerCraft main.lua for RobCo OS
-- Expects login/puzzle.lua to be present and correct

local sep = package.config:sub(1,1)
local base = debug.getinfo(1, 'S').source:sub(2):match('(.+)[/\\\\][^/\\\\]+$') or '.'
package.path = base .. sep .. "?.lua;" .. base .. sep .. "?" .. sep .. "init.lua;" .. package.path


local Admin = require("util.Admin")
local admin = Admin:new(false)

local Header = require("ui.Header")
local header = Header:new()

local StatusBar = require("ui.StatusBar")
local statusBar = StatusBar:new()

local MemDumpPuzzle = require("puzzle.MemDumpPuzzle")
local centerTextBlock = require("ui.UI").centerTextBlock

local function buildMenuOptions(menuOptions)
    local menuOpts = {}
    for i, opt in ipairs(menuOptions) do
        if opt.enabled then
            table.insert(menuOpts, {label=opt.label, enabled=opt.enabled, callback=opt.callback})
        end
    end
    return menuOpts
end

-- Use the global admin instance created above

local function main()
    while true do
        local puzzle = MemDumpPuzzle:new(header, admin)
        puzzle:run()
        local MainMenu = require("ui.menu.MainMenu")
        MainMenu.mainMenu(header, statusBar, admin)
    end
end

local function openDoor()
    -- TODO: Implement open door logic
    printHeaderOnly()
    centerTextBlock({"OPEN DOOR SELECTED"}, colors.lime)
    sleep(2)
end

local function viewFiles()
    -- TODO: Implement file viewing logic
    printHeaderOnly()
    centerTextBlock({"VIEW FILES SELECTED"}, colors.lime)
    sleep(2)
end

local function systemInfo()
    -- TODO: Implement system info logic
    printHeaderOnly()
    centerTextBlock({"SYSTEM INFO SELECTED"}, colors.lime)
    sleep(2)
end

local function securityLog()
    -- TODO: Implement security log logic
    printHeaderOnly()
    centerTextBlock({"SECURITY LOG SELECTED"}, colors.lime)
    sleep(2)
end

local function changePassword()
    -- TODO: Implement password change logic
    printHeaderOnly()
    centerTextBlock({"CHANGE PASSWORD SELECTED"}, colors.lime)
    sleep(2)
end

local function vaultStatus()
    -- TODO: Implement vault status logic
    printHeaderOnly()
    centerTextBlock({"VAULT STATUS SELECTED"}, colors.lime)
    sleep(2)
end

local function userManagement()
    -- TODO: Implement user management logic
    printHeaderOnly()
    centerTextBlock({"USER MANAGEMENT SELECTED"}, colors.lime)
    sleep(2)
end

local function activateEmergencyProtocols()
    -- TODO: Implement emergency protocols logic
    printHeaderOnly()
    centerTextBlock({"EMERGENCY PROTOCOLS SELECTED"}, colors.lime)
    sleep(2)
end

local function communications()
    -- TODO: Implement communications logic
    printHeaderOnly()
    centerTextBlock({"COMMUNICATIONS SELECTED"}, colors.lime)
    sleep(2)
end

local function controlLightingPower()
    -- TODO: Implement lighting/power control logic
    printHeaderOnly()
    centerTextBlock({"CONTROL LIGHTING/POWER SELECTED"}, colors.lime)
    sleep(2)
end

local function logout()
    printHeaderOnly()
    centerTextBlock("Logging out...", colors.green)
    sleep(1)
    term.clear()
    sleep(3)
    -- Return to puzzle (main loop will handle)
end

main()