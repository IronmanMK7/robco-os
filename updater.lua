-- RobCo OS Update Script
-- Updates existing installation from GitHub
-- Automatically discovers and updates all files in the repository

local baseUrl = "https://raw.githubusercontent.com/IronmanMK7/robco-os/main/"
local installDir = "robco_os"
local version = {major = 1, minor = 0, patch = 0}
local function versionString() return version.major .. "." .. version.minor .. "." .. version.patch end

-- Files that should NOT be overwritten (user data)
local preserveFiles = {
    "src/config/settings.lua"  -- User settings and configurations
}

print("RobCo OS Update Script")
print("Version " .. versionString())
print("")

-- Helper function to check if file should be preserved
local function shouldPreserve(filepath)
    for _, preserve in ipairs(preserveFiles) do
        if filepath == preserve or filepath == installDir .. "/" .. preserve then
            return true
        end
    end
    return false
end

-- Recursively scan directory structure to get all files
local function getFileList(url, path)
    -- For now, we'll use a hardcoded list since GitHub API would require more complex parsing
    -- In production, this could be expanded to actually fetch from a GitHub API endpoint
    -- Note: installer.lua is NOT included to avoid overwriting the bootstrap script
    local files = {
        "src/main.lua",
        "src/config/config.lua",
        "src/config/settings.lua",
        "src/puzzle/Puzzle.lua",
        "src/puzzle/MemDumpPuzzle.lua",
        "src/ui/Header.lua",
        "src/ui/StatusBar.lua",
        "src/ui/UI.lua",
        "src/ui/menu/Menu.lua",
        "src/ui/menu/MainMenu.lua",
        "src/util/Admin.lua",
        "src/util/faction/Faction.lua",
        "updater.lua",
        "uninstaller.lua",
        "version.lua"
    }
    return files
end

print("Checking for updates...")

local function downloadFile(url, filepath)
    local success = shell.run("wget", url, filepath .. ".tmp")
    if success then
        -- Ensure directory exists
        local dir = fs.getDir(filepath)
        if dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        -- Backup current file
        if fs.exists(filepath) then
            fs.move(filepath, filepath .. ".bak")
        end
        -- Move new file into place
        fs.move(filepath .. ".tmp", filepath)
        return true
    else
        -- Clean up temp file if download failed
        if fs.exists(filepath .. ".tmp") then
            fs.delete(filepath .. ".tmp")
        end
        return false
    end
end

local function restoreBackup(filepath)
    if fs.exists(filepath .. ".bak") then
        fs.move(filepath .. ".bak", filepath)
        print("Restored backup for: " .. filepath)
    end
end

local updated = 0
local failedFiles = {}

-- Get list of files to update
local files = getFileList(baseUrl, installDir)

-- Update all files
for i, file in ipairs(files) do
    print("Updating " .. i .. "/" .. #files .. ": " .. file)

    -- Skip files that should be preserved
    if shouldPreserve(file) then
        print("  Skipping (user data)")
    else
        -- Create full path within installation directory
        local fullPath = fs.combine(installDir, file)
        
        -- Create directory if needed
        local dir = fs.getDir(fullPath)
        if dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        -- Download and update the file
        local fullUrl = baseUrl .. file
        if downloadFile(fullUrl, fullPath) then
            updated = updated + 1
            print("  Updated!")
        else
            print("  ERROR: Failed to update")
            table.insert(failedFiles, file)
            restoreBackup(fullPath)
        end
    end
end

-- Clean up backup files
print("")
print("Cleaning up old backups...")
for _, file in ipairs(files) do
    local fullPath = fs.combine(installDir, file)
    local backup = fullPath .. ".bak"
    if fs.exists(backup) then
        fs.delete(backup)
    end
end

-- Clean up the updater backup file
if fs.exists("updater.lua.bak") then
    fs.delete("updater.lua.bak")
end

print("")
print("=== Update Summary ===")
print("Updated: " .. updated .. "/" .. #files .. " files")

if #failedFiles > 0 then
    print("Failed: " .. #failedFiles .. " files")
    for _, file in ipairs(failedFiles) do
        print("  - " .. file)
    end
    print("")
    print("Backups have been restored for failed files.")
    print("Please check your internet connection and try again.")
else
    print("")
    print("Update complete!")
    print("User settings preserved.")
    print("Run 'robco_os/src/main.lua' to start updated RobCo OS")
end