-- Remote Trigger Monitor
-- Persistent background process for monitoring remote door triggers
-- Runs continuously to detect and execute door sequences on trigger signals

local RemoteTriggerMonitor = {}
RemoteTriggerMonitor.__index = RemoteTriggerMonitor

local CONFIG_FILE = "robco_trigger_monitor_config"
local PID_FILE = "robco_trigger_monitor_pid"

-- Check if there are any active remote triggers configured
function RemoteTriggerMonitor.hasActiveTriggers(activeSubmenus)
    for _, submenu in ipairs(activeSubmenus or {}) do
        if (submenu.label == "Open Door" or submenu.label == "Close Door") and submenu.params then
            local params = submenu.params
            if params.hasRemoteTrigger and params.remoteTriggerColor and params.side then
                return true
            end
        end
    end
    return false
end

-- Save trigger configuration to file for the background monitor
function RemoteTriggerMonitor.saveConfig(activeSubmenus)
    local triggers = {}
    
    for _, submenu in ipairs(activeSubmenus or {}) do
        if (submenu.label == "Open Door" or submenu.label == "Close Door") and submenu.params then
            local params = submenu.params
            if params.hasRemoteTrigger and params.remoteTriggerColor and params.side then
                table.insert(triggers, {
                    side = params.side,
                    triggerColor = params.remoteTriggerColor,
                    doorLabel = submenu.label,
                    doorState = submenu.doorState,
                    sequence = params.sequence,
                    closeSequence = params.closeSequence,
                    signalCount = params.signalCount,
                    colors = params.colors
                })
            end
        end
    end
    
    if #triggers > 0 then
        local file = fs.open(CONFIG_FILE, "w")
        if file then
            file.writeLine(textutils.serialize(triggers))
            file.close()
            return true
        end
    end
    
    return false
end

-- Load trigger configuration from file
function RemoteTriggerMonitor.loadConfig()
    if not fs.exists(CONFIG_FILE) then
        return nil
    end
    
    local file = fs.open(CONFIG_FILE, "r")
    if not file then
        return nil
    end
    
    local content = file.readAll()
    file.close()
    
    if not content or content == "" then
        return nil
    end
    
    local triggers = textutils.unserialize(content)
    return triggers
end

-- Start background monitoring process
function RemoteTriggerMonitor.startBackgroundMonitor()
    -- Create a small monitoring script
    local monitorScript = [[
local CONFIG_FILE = "robco_trigger_monitor_config"

local function deserializeConfig()
    if not fs.exists(CONFIG_FILE) then
        return nil
    end
    
    local file = fs.open(CONFIG_FILE, "r")
    if not file then
        return nil
    end
    
    local content = file.readAll()
    file.close()
    
    if not content or content == "" then
        return nil
    end
    
    local triggers = textutils.unserialize(content)
    return triggers
end

local function executeSequence(trigger)
    -- Execute the door open/close sequence
    local sequence = trigger.doorLabel == "Open Door" and trigger.sequence or trigger.closeSequence
    
    for i, step in ipairs(sequence) do
        local colorValue = colors["" .. step.color .. ""]
        local currentState = redstone.getBundledOutput("" .. trigger.side .. "")
        
        if step.state == "on" then
            currentState = colors.combine(currentState, colorValue)
        else
            currentState = colors.subtract(currentState, colorValue)
        end
        
        redstone.setBundledOutput("" .. trigger.side .. "", currentState)
        
        if step.delay > 0 then
            sleep(step.delay)
        end
    end
end

-- Main monitoring loop
while true do
    local triggers = deserializeConfig()
    
    if triggers and #triggers > 0 then
        for _, trigger in ipairs(triggers) do
            -- Check if trigger signal is active
            local triggerColorValue = colors["" .. trigger.triggerColor .. ""]
            local currentState = redstone.getBundledOutput("" .. trigger.side .. "")
            local isSignalActive = (colors.test(currentState, triggerColorValue) == true)
            
            if isSignalActive then
                -- Execute the sequence
                executeSequence(trigger)
                
                -- Wait for signal to go back off (pulse detection)
                while true do
                    currentState = redstone.getBundledOutput("" .. trigger.side .. "")
                    local stillActive = (colors.test(currentState, triggerColorValue) == true)
                    if not stillActive then
                        break
                    end
                    sleep(0.1)
                end
                
                -- Brief delay before checking again
                sleep(0.5)
            end
        end
    end
    
    -- Check every 0.1 seconds
    sleep(0.1)
end
]]
    
    -- Write the monitor script
    local scriptPath = ".robco_trigger_monitor"
    local file = fs.open(scriptPath, "w")
    if file then
        file.write(monitorScript)
        file.close()
        
        -- Start as background process using shell
        shell.run(scriptPath .. " &")
        return true
    end
    
    return false
end

-- Stop the background monitor
function RemoteTriggerMonitor.stopBackgroundMonitor()
    -- Delete the monitor config to stop monitoring
    if fs.exists(CONFIG_FILE) then
        fs.delete(CONFIG_FILE)
    end
    
    -- Clean up monitor script
    if fs.exists(".robco_trigger_monitor") then
        fs.delete(".robco_trigger_monitor")
    end
end

-- Initialize remote trigger monitoring on startup
-- Call this from main.lua during initialization
function RemoteTriggerMonitor.initializeOnStartup(activeSubmenus)
    -- Check if we have active triggers
    if RemoteTriggerMonitor.hasActiveTriggers(activeSubmenus) then
        -- Save the configuration
        RemoteTriggerMonitor.saveConfig(activeSubmenus)
        
        -- Start background monitor
        RemoteTriggerMonitor.startBackgroundMonitor()
        
        return true
    else
        -- Stop any existing monitor
        RemoteTriggerMonitor.stopBackgroundMonitor()
        
        return false
    end
end

return RemoteTriggerMonitor
