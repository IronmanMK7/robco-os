-- RobCo OS GitHub Installer
-- Downloads all project files from GitHub into robco_os directory

local baseUrl = "https://raw.githubusercontent.com/IronmanMK7/robco-os/main/"
local installDir = "robco_os"
local version = {major = 1, minor = 0, patch = 0}
local function versionString() return version.major .. "." .. version.minor .. "." .. version.patch end
local files = {
    "src/main.lua",
    "src/config/config.lua",
    "src/config/settings.lua",
    "src/puzzle/MemDumpPuzzle.lua",
    "src/puzzle/Puzzle.lua",
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

print("RobCo OS GitHub Installer")
print("Version " .. versionString())
print("")
print("Creating installation directory...")

-- Create installation directory
if not fs.exists(installDir) then
    fs.makeDir(installDir)
    print("Created directory: " .. installDir)
else
    print("Directory already exists: " .. installDir)
end

print("")
print("Downloading files from GitHub...")
print("")

local downloaded = 0
local failedFiles = {}

for i, file in ipairs(files) do
    print("Downloading " .. i .. "/" .. #files .. ": " .. file)

    -- Create full path within installation directory
    local fullPath = fs.combine(installDir, file)
    local dir = fs.getDir(fullPath)
    if dir ~= "" and not fs.exists(dir) then
        print("  Creating directory: " .. dir)
        fs.makeDir(dir)
    end

    -- Download file
    local fullUrl = baseUrl .. file
    print("  URL: " .. fullUrl)
    local success = shell.run("wget", fullUrl, fullPath)
    if success then
        downloaded = downloaded + 1
        print("  Success!")
    else
        print("  ERROR: Failed to download")
        table.insert(failedFiles, file)
    end
end

-- Print summary
print("")
print("=== Installation Summary ===")
print("Downloaded: " .. downloaded .. "/" .. #files .. " files")

if #failedFiles > 0 then
    print("Failed: " .. #failedFiles .. " files")
    for _, file in ipairs(failedFiles) do
        print("  - " .. file)
    end
    print("")
    print("Installation incomplete. Please check your")
    print("internet connection and try again.")
else
    print("")
    print("Installation complete!")
    print("")
    print("Setting up startup.lua...")
    
    -- Create startup.lua in rom directory to auto-run RobCo OS
    local startupPath = "rom/startup.lua"
    local startupFile = fs.open(startupPath, "w")
    if startupFile then
        startupFile.writeLine("-- RobCo OS Auto-Startup")
        startupFile.writeLine("shell.run(\"" .. installDir .. "/src/main.lua\")")
        startupFile.close()
        print("Startup configured successfully!")
    else
        print("Warning: Could not create startup.lua")
    end
    
    print("")
    print("Press any key to reboot and start RobCo OS...")
    os.pullEvent("key")
    
    print("")
    print("Rebooting...")
    os.reboot()
end