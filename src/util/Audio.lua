-- Audio utility for playing DFPWM audio files
-- Uses dfpwm.lua from GitHub gist
-- Streams audio directly from URLs to avoid disk space issues

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

-- Play a DFPWM audio file from disk
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

-- Stream and play DFPWM audio directly from a URL without caching to disk
-- This reads the audio data directly from the HTTP response
function Audio:playFromURL(url)
    -- Load DFPWM player if not already loaded
    if not self.dfpwmPlayer then
        self.dfpwmPlayer = loadDFPWMPlayer()
        if not self.dfpwmPlayer then
            return false, "Could not load DFPWM player"
        end
    end
    
    -- Create a temporary file for wget to pipe into
    local tempFile = ".audio_stream"
    
    -- Download directly to temp file (wget will handle the streaming)
    local dlSuccess = shell.run("wget", url, "-O", tempFile)
    if not dlSuccess then
        if fs.exists(tempFile) then
            fs.delete(tempFile)
        end
        return false, "Failed to download audio from URL"
    end
    
    -- Read the streamed content
    local file = fs.open(tempFile, "rb")
    if not file then
        fs.delete(tempFile)
        return false, "Could not read streamed audio data"
    end
    
    local content = file.readAll()
    file.close()
    
    -- Clean up temp file immediately
    fs.delete(tempFile)
    
    if not content or #content == 0 then
        return false, "Audio stream is empty"
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

-- Play a DFPWM file from a URL (old method - kept for compatibility)
-- NOTE: This method is deprecated due to disk space issues. Use playFromURL() instead.
function Audio:playFromURLCached(url, cacheFile)
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
