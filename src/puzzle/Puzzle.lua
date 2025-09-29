-- Puzzle base class for RobCo terminal login minigame
local Puzzle = {}
Puzzle.__index = Puzzle


-- Constructor for Puzzle base class
function Puzzle:new(headerInstance, faction)
    local obj = setmetatable({}, self)
    obj.header = headerInstance
    obj.faction = faction or {getName = function() return "Vault-Tec" end}
    return obj
end

-- Show pass status message
function Puzzle:showPassStatus(isAdmin)
    if self.header then self.header:hide() end
    term.clear()
    local factionName = self.faction and self.faction:getName() or "Vault-Tec"
    local factionNameUpper = string.upper(factionName)
    local lines
    if isAdmin then
        lines = {
            "ACCESS GRANTED",
            "WELCOME " .. factionNameUpper .. " ADMINISTRATOR",
        }
    else
        lines = {
            "ACCESS GRANTED",
            "WELCOME " .. factionNameUpper .. " USER"
        }
    end
    local termW, termH = term.getSize()
    local blockH = #lines
    local startY = math.floor((termH - blockH) / 2) + 1
    for i, line in ipairs(lines) do
        local pad = math.floor((termW - #line) / 2)
        term.setCursorPos(pad + 1, startY + i - 1)
        term.setTextColor(colors.lime)
        term.write(line)
    end
    sleep(2)
    if self.header then self.header:show() end
end

-- Show fail status message
function Puzzle:showFailStatus()
    if self.header then self.header:hide() end
    term.clear()
    local factionName = self.faction and self.faction:getName() or "Vault-Tec"
    local infoLines = {
        "TERMINAL LOCKED",
        "PLEASE CONTACT AN ADMINISTRATOR",
        "",
        "Your incorrect login attempt has been noted.",
        factionName .. " has been alerted to this",
        "security breach.",
        "",
        "This terminal will be unlocked in [10] seconds."
    }
    local termW, termH = term.getSize()
    local blockH = #infoLines
    local startY = math.floor((termH - blockH) / 2) + 1
    for t = 10, 1, -1 do
        term.clear()
        for i, line in ipairs(infoLines) do
            local out = line
            if i == #infoLines then
                out = "This terminal will be unlocked in [" .. t .. "] seconds."
            end
            local pad = math.floor((termW - #out) / 2)
            term.setCursorPos(pad + 1, startY + i - 1)
            if i <= 2 then
                term.setTextColor(colors.red)
            else
                term.setTextColor(colors.green)
            end
            term.write(out)
        end
        sleep(1)
    end
    if self.header then self.header:show() end
end

-- Base admin bypass function (must be overridden)
function Puzzle:adminBypass(event, x, y)
    -- Default: no bypass, subclasses should override
    return false
end

return Puzzle
