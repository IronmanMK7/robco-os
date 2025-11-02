-- RobCo OS Version Information
-- Production-grade versioning system used by installer, updater, uninstaller, and main application

local version = {
    -- Core Version (Semantic Versioning)
    major = 1,
    minor = 0,
    patch = 0,
    
    -- Release Information
    status = "stable",  -- alpha, beta, rc, stable
    label = "Initial Release",
    releaseDate = "2025-11-02",
    
    -- Build Information
    buildNumber = 1,
    gitCommit = "1070e32",  -- Last commit hash
    
    -- System Requirements
    requirements = {
        ccVersion = "1.80",  -- Minimum ComputerCraft version
        javaVersion = "1.12"  -- Minimum Java version
    },
    
    -- Changelog (most recent first)
    changelog = {
        {version = "1.0.0", date = "2025-11-02", items = {
            "Initial release",
            "GitHub-based installer and updater",
            "Auto-startup configuration",
            "Comprehensive uninstaller",
            "Production-grade versioning system",
            "Detailed installation/update summaries"
        }}
    }
}

-- Convert version to string format (e.g., "1.0.0")
function version:toString()
    return self.major .. "." .. self.minor .. "." .. self.patch
end

-- Get full version string with status (e.g., "v1.0.0-stable")
function version:toStringWithStatus()
    local statusStr = self.status ~= "stable" and "-" .. self.status or ""
    return "v" .. self:toString() .. statusStr
end

-- Get complete version information
function version:full()
    return "RobCo OS " .. self:toStringWithStatus() .. " - " .. self.label .. " (" .. self.releaseDate .. ")"
end

-- Get build information
function version:buildInfo()
    return "Build #" .. self.buildNumber .. " | Commit: " .. self.gitCommit
end

-- Check if current version meets minimum requirements
function version:check(requiredVersion)
    -- requiredVersion format: "1.0.0"
    local major, minor, patch = requiredVersion:match("(%d+)%.(%d+)%.(%d+)")
    major = tonumber(major) or 0
    minor = tonumber(minor) or 0
    patch = tonumber(patch) or 0
    
    if self.major > major then return true end
    if self.major < major then return false end
    
    if self.minor > minor then return true end
    if self.minor < minor then return false end
    
    if self.patch >= patch then return true end
    return false
end

-- Check if system meets requirements
function version:checkSystemRequirements()
    local ccVersion = os.version()
    -- Extract version number from string like "CraftOS 1.80"
    local major, minor = ccVersion:match("(%d+)%.(%d+)")
    
    if not major or not minor then
        return false, "Could not determine ComputerCraft version"
    end
    
    local currentVersion = major .. "." .. minor
    local reqVersion = self.requirements.ccVersion
    
    -- Compare versions
    local currentMajor, currentMinor = currentVersion:match("(%d+)%.(%d+)")
    local reqMajor, reqMinor = reqVersion:match("(%d+)%.(%d+)")
    
    currentMajor = tonumber(currentMajor)
    currentMinor = tonumber(currentMinor)
    reqMajor = tonumber(reqMajor)
    reqMinor = tonumber(reqMinor)
    
    if currentMajor > reqMajor then
        return true, "ComputerCraft " .. currentVersion .. " (Required: " .. reqVersion .. ")"
    elseif currentMajor < reqMajor then
        return false, "ComputerCraft " .. currentVersion .. " is too old (Required: " .. reqVersion .. " or newer)"
    end
    
    if currentMinor >= reqMinor then
        return true, "ComputerCraft " .. currentVersion .. " (Required: " .. reqVersion .. ")"
    else
        return false, "ComputerCraft " .. currentVersion .. " is too old (Required: " .. reqVersion .. " or newer)"
    end
end

-- Get latest changelog entry
function version:getLatestChanges()
    if self.changelog and self.changelog[1] then
        return self.changelog[1].items
    end
    return {}
end

-- Compare two version strings, returns: -1 (first is older), 0 (equal), 1 (first is newer)
function version:compare(versionString)
    local major, minor, patch = versionString:match("(%d+)%.(%d+)%.(%d+)")
    major = tonumber(major) or 0
    minor = tonumber(minor) or 0
    patch = tonumber(patch) or 0
    
    if self.major > major then return 1 end
    if self.major < major then return -1 end
    
    if self.minor > minor then return 1 end
    if self.minor < minor then return -1 end
    
    if self.patch > patch then return 1 end
    if self.patch < patch then return -1 end
    
    return 0
end

-- Print version banner
function version:printBanner()
    print(self:full())
    print(self:buildInfo())
end

-- Print changelog for current version
function version:printChangelog()
    if self.changelog and self.changelog[1] then
        local latest = self.changelog[1]
        print("Changes in " .. latest.version .. ":")
        for _, item in ipairs(latest.items) do
            print("  - " .. item)
        end
    end
end

return version
