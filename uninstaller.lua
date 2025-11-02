-- RobCo OS Uninstaller
-- Removes RobCo OS installation dynamically
-- Can be run from anywhere and will locate and remove the robco_os directory

local version = {major = 2, minor = 0, patch = 0}
local function versionString() return version.major .. "." .. version.minor .. "." .. version.patch end

print("RobCo OS Uninstaller")
print("Version " .. versionString())
print("")

-- Function to recursively search for robco_os directory
local function findRobCoOSDir()
    local searchPath = ""
    
    -- First, check if robco_os exists in current directory
    if fs.exists("robco_os") and fs.isDir("robco_os") then
        return "robco_os"
    end
    
    -- If we're inside robco_os, find the parent
    local currentPath = shell.dir()
    if currentPath:match("robco_os") then
        -- Navigate up to find robco_os root
        local pathParts = {}
        for part in currentPath:gmatch("[^/]+") do
            if part ~= "robco_os" then
                table.insert(pathParts, part)
            else
                break
            end
        end
        local parentPath = table.concat(pathParts, "/")
        local robcoPath = fs.combine(parentPath, "robco_os")
        if fs.exists(robcoPath) and fs.isDir(robcoPath) then
            return robcoPath
        end
    end
    
    -- Search through common locations
    local locations = {"", "disk", "disk2", "disk3"}
    for _, loc in ipairs(locations) do
        local checkPath = fs.combine(loc, "robco_os")
        if fs.exists(checkPath) and fs.isDir(checkPath) then
            return checkPath
        end
    end
    
    return nil
end

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

-- Locate the robco_os directory
print("Locating RobCo OS installation...")
local installDir = findRobCoOSDir()

if not installDir then
    print("ERROR: Could not find robco_os directory")
    print("Press any key to exit...")
    os.pullEvent("key")
    return
end

print("Found: " .. installDir)
print("")
print("This will remove RobCo OS and all files within it.")
print("This action CANNOT be undone.")
print("")
print("Continue? (Y/N)")

local event, key = os.pullEvent("key")
if key ~= keys.y then
    print("Uninstall cancelled.")
    return
end

print("")
print("Uninstalling...")

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
    print("  Removed successfully")
else
    print("  ERROR: Failed to remove " .. installDir)
    print("  Some files may still exist")
end

-- Try to clean up any backup files in the same parent directory as robco_os
local parentDir = fs.getDir(installDir)
if parentDir == "" then parentDir = "" end

print("")
print("Cleaning up backup files...")

local backupFiles = {"updater.lua.bak", "uninstaller.lua.bak", "version.lua.bak"}
for _, backupFile in ipairs(backupFiles) do
    local fullPath = fs.combine(parentDir, backupFile)
    if fs.exists(fullPath) then
        fs.delete(fullPath)
        print("  Removed " .. fullPath)
    end
end

-- Try to remove standalone updater and uninstaller from parent directory
local filesToRemove = {"updater.lua", "uninstaller.lua", "version.lua"}
for _, file in ipairs(filesToRemove) do
    local fullPath = fs.combine(parentDir, file)
    if fs.exists(fullPath) and fullPath ~= shell.getRunningProgram() then
        fs.delete(fullPath)
        print("  Removed " .. fullPath)
    end
end

print("")
print("=== Uninstall Summary ===")
print("RobCo OS has been removed from: " .. installDir)
print("")

-- Offer to restore default startup if it exists
if fs.exists("rom/startup.lua") then
    print("Restore default startup.lua? (Y/N)")
    local event, key = os.pullEvent("key")
    if key == keys.y then
        print("Restoring default startup...")
        local startupFile = fs.open("rom/startup.lua", "w")
        if startupFile then
            startupFile.writeLine("-- Default ComputerCraft startup")
            startupFile.writeLine("os.run({}, \"rom/programs/shell\")")
            startupFile.close()
            print("Startup restored to default")
        else
            print("Warning: Could not restore startup.lua")
        end
    end
end

print("")
print("Uninstall complete!")
print("Press any key to return to shell...")
