-- Security Log Module
-- Logs system events with timestamps for audit trail purposes
-- Events are persisted to disk and survive application restarts

local SecurityLog = {}
SecurityLog.__index = SecurityLog

local LOG_FILE = "robco_security_log"

-- Log a security event with timestamp
-- event: table with {eventType="door_open", details={...}}
function SecurityLog.logEvent(eventType, details)
    details = details or {}
    
    local event = {
        timestamp = os.time(),
        eventType = eventType,
        details = details
    }
    
    -- Read existing log
    local events = SecurityLog.getAllEvents() or {}
    
    -- Append new event
    table.insert(events, event)
    
    -- Write updated log to file
    local file = fs.open(LOG_FILE, "w")
    if file then
        file.writeLine(textutils.serialize(events))
        file.close()
        return true
    end
    
    return false
end

-- Get all logged events
function SecurityLog.getAllEvents()
    if not fs.exists(LOG_FILE) then
        return {}
    end
    
    local file = fs.open(LOG_FILE, "r")
    if not file then
        return {}
    end
    
    local content = file.readAll()
    file.close()
    
    if not content or content == "" then
        return {}
    end
    
    local events = textutils.unserialize(content) or {}
    return events
end

-- Get events filtered by type
function SecurityLog.getEventsByType(eventType)
    local allEvents = SecurityLog.getAllEvents()
    local filtered = {}
    
    for _, event in ipairs(allEvents) do
        if event.eventType == eventType then
            table.insert(filtered, event)
        end
    end
    
    return filtered
end

-- Get most recent N events
function SecurityLog.getRecentEvents(count)
    count = count or 50
    local allEvents = SecurityLog.getAllEvents()
    local recent = {}
    
    -- Start from the end and work backwards
    for i = math.max(1, #allEvents - count + 1), #allEvents do
        table.insert(recent, allEvents[i])
    end
    
    return recent
end

-- Get total event count
function SecurityLog.getEventCount()
    return #SecurityLog.getAllEvents()
end

-- Clear all events (admin function)
function SecurityLog.clearAll()
    if fs.exists(LOG_FILE) then
        fs.delete(LOG_FILE)
        return true
    end
    return false
end

-- Format a timestamp for display
function SecurityLog.formatTimestamp(timestamp)
    local hours = math.floor(timestamp / 3600) % 24
    local minutes = math.floor(timestamp / 60) % 60
    local seconds = timestamp % 60
    
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Format an event for display
function SecurityLog.formatEvent(event)
    local timestamp = SecurityLog.formatTimestamp(event.timestamp)
    local details = ""
    
    if event.eventType == "door_open" then
        details = event.details.action .. " - Door: " .. event.details.doorLabel
    elseif event.eventType == "door_close" then
        details = event.details.action .. " - Door: " .. event.details.doorLabel
    else
        details = event.eventType
    end
    
    return timestamp .. " | " .. details
end

return SecurityLog
