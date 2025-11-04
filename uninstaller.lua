-- RobCo OS Uninstaller
-- Removes RobCo OS installation and cleans up startup configuration

local version = {major = 2, minor = 0, patch = 0}
local function versionString() return version.major .. "." .. version.minor .. "." .. version.patch end

print("RobCo OS Uninstaller")
print("Version " .. versionString())
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

-- Function to recursively search for robco_os directory
local function findRobCoOSDir()
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

-- Remove the entire installation directory
print("Removing " .. installDir .. " directory...")
if deleteDir(installDir) then
    print("  Removed successfully")
else
    print("  ERROR: Failed to remove " .. installDir)
    print("  Some files may still exist")
end

-- Remove startup.lua modifications
print("")
print("Cleaning up startup configuration...")
if fs.exists("rom/startup.lua") then
    local startupFile = fs.open("rom/startup.lua", "r")
    if startupFile then
        local content = startupFile.readAll()
        startupFile.close()
        
        -- Remove RobCo OS launch instruction from startup
        local lines = {}
        for line in content:gmatch("[^\n]+") do
            if not line:match("robco_os") and not line:match("RobCo OS") then
                table.insert(lines, line)
            end
        end
        
        -- Rewrite startup.lua if we removed anything
        if #lines < content:gmatch("\n") then
            local startupFile = fs.open("rom/startup.lua", "w")
            if startupFile then
                for _, line in ipairs(lines) do
                    startupFile.writeLine(line)
                end
                startupFile.close()
                print("  Removed RobCo OS from startup")
            end
        end
    end
end

-- Delete uninstaller.lua as final step
print("")
print("Finalizing uninstall...")
local uninstallerPath = shell.getRunningProgram()
-- Schedule deletion after uninstaller exits
print("=== Uninstall Summary ===")
print("RobCo OS has been removed from: " .. installDir)
print("")
print("Uninstall complete!")
print("Press any key to return to shell...")
os.pullEvent("key")

-- Delete self after a brief delay to allow exit
local tempFile = ".uninstall_cleanup"
local cleanupScript = fs.open(tempFile, "w")
if cleanupScript then
    cleanupScript.writeLine("sleep(0.5)")
    cleanupScript.writeLine("if fs.exists('" .. uninstallerPath .. "') then")
    cleanupScript.writeLine("  fs.delete('" .. uninstallerPath .. "')")
    cleanupScript.writeLine("end")
    cleanupScript.writeLine("if fs.exists('.uninstall_cleanup') then fs.delete('.uninstall_cleanup') end")
    cleanupScript.close()
    shell.run(tempFile)
end
