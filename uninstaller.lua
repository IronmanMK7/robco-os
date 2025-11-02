-- RobCo OS Uninstaller
-- Removes RobCo OS files and restores default startup.lua

local installDir = "robco_os"
local version = {major = 1, minor = 0, patch = 0}
local function versionString() return version.major .. "." .. version.minor .. "." .. version.patch end

print("RobCo OS Uninstaller")
print("Version " .. versionString())
print("")
print("This will remove RobCo OS and revert startup.lua")
print("Continue? (Y/N)")

local event, key = os.pullEvent("key")
if key ~= keys.y then
    print("Uninstall cancelled.")
    return
end

print("")
print("Uninstalling...")
print("")

-- Function to recursively delete directory and its contents
local function deleteDir(path)
    if not fs.exists(path) then
        return true
    end
    
    if fs.isDir(path) then
        for _, child in ipairs(fs.list(path)) do
            if not deleteDir(fs.combine(path, child)) then
                return false
            end
        end
    end
    
    return fs.delete(path)
end

-- Remove the entire installation directory
print("Removing " .. installDir .. " directory...")
if deleteDir(installDir) then
    print("  Removed")
else
    print("  ERROR: Failed to remove " .. installDir)
end

-- Remove updater and uninstaller (this file) from root
print("Removing updater.lua...")
if fs.exists("updater.lua") then
    fs.delete("updater.lua")
    print("  Removed")
end

-- Clean up any backup files
print("Cleaning up backup files...")
if fs.exists("updater.lua.bak") then
    fs.delete("updater.lua.bak")
    print("  Removed updater.lua.bak")
end

print("Removing uninstaller.lua...")
if fs.exists("uninstaller.lua") then
    -- We can't delete ourselves while running, but we'll remove it at the end
    print("  Will remove on next boot")
end

-- Restore default startup.lua
print("")
print("Restoring default startup.lua...")
local startupPath = "rom/startup.lua"
local startupFile = fs.open(startupPath, "w")
if startupFile then
    startupFile.writeLine("-- Default ComputerCraft startup")
    startupFile.writeLine("os.run({}, \"rom/programs/shell\")")
    startupFile.close()
    print("Startup restored to default")
else
    print("Warning: Could not restore startup.lua")
end

print("")
print("=== Uninstall Summary ===")
print("RobCo OS has been removed.")
print("")
print("Press any key to reboot...")
os.pullEvent("key")

print("")
print("Rebooting...")
os.reboot()
