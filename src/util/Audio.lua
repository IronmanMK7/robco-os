-- Audio utility for playing DFPWM audio files
-- Uses dfpwm.lua from GitHub gist

local Audio = {}
Audio.__index = Audio

-- URL to the DFPWM player library
local DFPWM_PLAYER_URL = "https://gist.githubusercontent.com/Cheatoid/e798988c54b411e9d1b64e7aa7057d91/raw/7add100b2ea00eeae77142e4f53d7584d599f5e3/dfpwm.lua"
local DFPWM_CACHE_FILE = "dfpwm_player"

-- Download DFPWM player if not cached
local function ensureDFPWMPlayer()
    if not fs.exists(DFPWM_CACHE_FILE) then
        local tempFile = ".dfpwm_download"
        if shell.run("wget", DFPWM_PLAYER_URL, tempFile) then
            fs.move(tempFile, DFPWM_CACHE_FILE)
            return true
        else
            if fs.exists(tempFile) then
                fs.delete(tempFile)
            end
            return false
        end
    end
    return true
end

-- Load the DFPWM player
local function loadDFPWMPlayer()
    if not ensureDFPWMPlayer() then
        return nil
    end
    
    local playerFunc = loadfile(DFPWM_CACHE_FILE)
    if playerFunc then
        return playerFunc()
    end
    return nil
end

function Audio:new()
    local obj = {}
    setmetatable(obj, self)
    obj.dfpwmPlayer = nil
    return obj
end

-- Play a DFPWM audio file
function Audio:playFile(filename)
    if not fs.exists(filename) then
        return false, "File not found: " .. filename
    end
    
    -- Load DFPWM player if not already loaded
    if not self.dfpwmPlayer then
        self.dfpwmPlayer = loadDFPWMPlayer()
        if not self.dfpwmPlayer then
            return false, "Could not load DFPWM player"
        end
    end
    
    -- Open and read the audio file
    local file = fs.open(filename, "rb")
    if not file then
        return false, "Could not open audio file"
    end
    
    local content = file.readAll()
    file.close()
    
    if not content or #content == 0 then
        return false, "Audio file is empty"
    end
    
    -- Play the audio
    local success, err = pcall(function()
        self.dfpwmPlayer(content)
    end)
    
    if success then
        return true
    else
        return false, "Playback error: " .. tostring(err)
    end
end

-- Download a DFPWM audio file from a URL
function Audio:downloadFile(url, destPath)
    -- Create directory if needed
    local dir = fs.getDir(destPath)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Download the file
    local success = shell.run("wget", url, destPath)
    return success, success and "Download complete" or "Download failed"
end

-- Play a DFPWM file from a URL (downloads then plays)
function Audio:playFromURL(url, cacheFile)
    cacheFile = cacheFile or ".audio_cache"
    
    -- Download the file
    local dlSuccess, dlMsg = self:downloadFile(url, cacheFile)
    if not dlSuccess then
        return false, dlMsg
    end
    
    -- Play the downloaded file
    local playSuccess, playMsg = self:playFile(cacheFile)
    
    -- Clean up cache file
    if fs.exists(cacheFile) then
        fs.delete(cacheFile)
    end
    
    return playSuccess, playMsg
end

return Audio
