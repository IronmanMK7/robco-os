-- RobCo OS Update Script
-- Updates existing installation from GitHub
-- Automatically discovers and dynamically updates all files in the robco_os directory
-- Intelligently handles file moves/renames using content hashing
-- Can be run from anywhere and will create/update robco_os directory

local baseUrl = "https://raw.githubusercontent.com/IronmanMK7/robco-os/main/"
local installDir = "robco_os"
local version = {major = 2, minor = 1, patch = 0}
local function versionString() return version.major .. "." .. version.minor .. "." .. version.patch end

-- Ensure robco_os directory exists
if not fs.exists(installDir) then
    fs.makeDir(installDir)
end

-- Files that should NOT be overwritten (user data)
local preserveFiles = {
    installDir .. "/src/config/settings.lua"  -- User settings and configurations
}

print("RobCo OS Update Script")
print("Version " .. versionString())
print("")

-- Helper function to check if file should be preserved
local function shouldPreserve(filepath)
    for _, preserve in ipairs(preserveFiles) do
        if filepath == preserve then
            return true
        end
    end
    return false
end

-- Compute simple hash of file content (for moved file detection)
local function hashFile(filepath)
    if not fs.exists(filepath) then return nil end
    local file = io.open(filepath, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    
    -- Simple hash: sum of byte values
    local hash = 0
    for i = 1, #content do
        hash = (hash + string.byte(content, i)) % 1000000
    end
    return hash
end

-- Recursively scan directory to get all Lua files
local function scanDirectory(dir)
    local files = {}
    local function scan(path)
        if fs.isDir(path) then
            for _, item in ipairs(fs.list(path)) do
                local fullPath = fs.combine(path, item)
                if fs.isDir(fullPath) then
                    scan(fullPath)
                elseif item:match("%.lua$") then
                    table.insert(files, fullPath)
                end
            end
        end
    end
    
    -- Scan src/ directory within robco_os
    local srcPath = fs.combine(installDir, "src")
    if fs.isDir(srcPath) then
        scan(srcPath)
    end
    
    -- Also include root-level lua files in robco_os (updater.lua, uninstaller.lua, version.lua)
    for _, file in ipairs(fs.list(installDir)) do
        if file:match("%.lua$") and file ~= "installer.lua" then
            table.insert(files, fs.combine(installDir, file))
        end
    end
    
    return files
end

-- Fetch file list from GitHub API to get remote structure
local function getRemoteFileList()
    -- Fetch from GitHub API (contents endpoint for repository root)
    local apiUrl = "https://api.github.com/repos/IronmanMK7/robco-os/contents?ref=main"
    local tempFile = ".gh_api_response"
    local success = shell.run("wget", "-q", apiUrl, "-O", tempFile)
    
    local files = {}
    if success and fs.exists(tempFile) then
        local file = io.open(tempFile, "r")
        if file then
            local content = file:read("*a")
            file:close()
            
            -- Parse JSON to extract file paths (both .lua files and special files)
            for path in content:gmatch('"path":"([^"]+)"') do
                if (path:match("%.lua$") and path ~= "installer.lua") or path:match("^%.github/copilot%-instructions%.md$") then
                    table.insert(files, path)
                end
            end
            
            fs.delete(tempFile)
        end
    end
    
    -- If dynamic discovery fails, error out (no hardcoded fallback)
    if #files == 0 then
        print("ERROR: Could not fetch file list from GitHub API")
        print("Please check your internet connection and try again.")
        return nil
    end
    
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

-- Detect if a moved file already exists locally with matching content
local function findMovedFile(remoteHash, excludePath)
    local localFiles = scanDirectory(installDir)
    for _, localFile in ipairs(localFiles) do
        if localFile ~= excludePath and hashFile(localFile) == remoteHash then
            return localFile
        end
    end
    return nil
end

local updated = 0
local failedFiles = {}
local movedFiles = {}

-- Get list of files to update from remote
local remoteFiles = getRemoteFileList()

-- Check if API fetch failed
if remoteFiles == nil then
    return
end

print("Found " .. #remoteFiles .. " files to check")
print("")

-- Build a set of remote files for easier lookup
local remoteSet = {}
for _, file in ipairs(remoteFiles) do
    remoteSet[installDir .. "/" .. file] = true
end

-- Remove local files that no longer exist in remote (except preserved files)
print("Checking for removed files...")
local localFiles = scanDirectory(installDir)
local removedCount = 0
for _, localFile in ipairs(localFiles) do
    if not remoteSet[localFile] and not shouldPreserve(localFile) then
        print("Removing: " .. localFile)
        fs.delete(localFile)
        removedCount = removedCount + 1
    end
end

if removedCount > 0 then
    print("Removed " .. removedCount .. " file(s)")
    print("")
end

-- Update all files
for i, file in ipairs(remoteFiles) do
    print("Updating " .. i .. "/" .. #remoteFiles .. ": " .. file)

    -- Skip files that should be preserved
    if shouldPreserve(file) then
        print("  Skipping (user data)")
    else
        -- Construct full path within robco_os directory
        local fullPath = fs.combine(installDir, file)
        local tmpPath = fullPath .. ".tmp"
        local fullUrl = baseUrl .. file
        
        local downloadSuccess = shell.run("wget", fullUrl, tmpPath)
        if downloadSuccess then
            local remoteHash = hashFile(tmpPath)
            
            -- Check if file exists locally
            if fs.exists(fullPath) then
                -- File exists in expected location
                local dir = fs.getDir(fullPath)
                if dir ~= "" and not fs.exists(dir) then
                    fs.makeDir(dir)
                end
                
                -- Backup current file
                fs.move(fullPath, fullPath .. ".bak")
                fs.move(tmpPath, fullPath)
                updated = updated + 1
                print("  Updated!")
            else
                -- File doesn't exist - check if it was moved
                local movedPath = findMovedFile(remoteHash, fullPath)
                if movedPath then
                    -- Found the file in a different location - this is a move/rename
                    print("  Detected file moved from: " .. movedPath)
                    
                    -- Create directory for new location
                    local dir = fs.getDir(fullPath)
                    if dir ~= "" and not fs.exists(dir) then
                        fs.makeDir(dir)
                    end
                    
                    -- Backup old file and move new one into place
                    fs.move(movedPath, movedPath .. ".bak")
                    fs.move(tmpPath, fullPath)
                    table.insert(movedFiles, {old = movedPath, new = fullPath})
                    updated = updated + 1
                    print("  Moved to new location!")
                else
                    -- New file
                    local dir = fs.getDir(fullPath)
                    if dir ~= "" and not fs.exists(dir) then
                        fs.makeDir(dir)
                    end
                    
                    fs.move(tmpPath, fullPath)
                    updated = updated + 1
                    print("  Added!")
                end
            end
        else
            print("  ERROR: Failed to download")
            table.insert(failedFiles, file)
            if fs.exists(tmpPath) then
                fs.delete(tmpPath)
            end
        end
    end
end

-- Clean up backup files
print("")
print("Cleaning up old backups...")
for _, file in ipairs(remoteFiles) do
    local fullPath = fs.combine(installDir, file)
    local backup = fullPath .. ".bak"
    if fs.exists(backup) then
        fs.delete(backup)
    end
end

-- Clean up old moved file backups
for _, moved in ipairs(movedFiles) do
    local oldBackup = moved.old .. ".bak"
    if fs.exists(oldBackup) then
        fs.delete(oldBackup)
    end
end

-- Clean up the updater backup file
local updaterBackup = fs.combine(installDir, "updater.lua.bak")
if fs.exists(updaterBackup) then
    fs.delete(updaterBackup)
end

print("")
print("=== Update Summary ===")
print("Updated/Added/Moved: " .. updated .. "/" .. #remoteFiles .. " files")

if #movedFiles > 0 then
    print("")
    print("Files relocated:")
    for _, moved in ipairs(movedFiles) do
        print("  " .. moved.old .. " -> " .. moved.new)
    end
end

if #failedFiles > 0 then
    print("")
    print("Failed: " .. #failedFiles .. " files")
    for _, file in ipairs(failedFiles) do
        print("  - " .. file)
    end
    print("")
    print("Please check your internet connection and try again.")
else
    print("")
    print("Update complete!")
    print("User settings preserved.")
    print("Run '" .. installDir .. "/src/main.lua' to start updated RobCo OS")
end