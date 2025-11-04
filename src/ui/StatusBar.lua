-- StatusBar class, subclass of UI
local UI = require("ui.UI")
local StatusBar = setmetatable({}, {__index = UI})
StatusBar.__index = StatusBar

function StatusBar:new(text)
    local termW, termH = term.getSize()
    local obj = UI.new(self)
    obj.text = text or ""
    obj.line = termH
    obj.width = termW
    obj.isFixed = true  -- Mark status bar as fixed area
    setmetatable(obj, self)
    return obj
end

function StatusBar:setText(newText)
    self.text = newText
end



function StatusBar:draw(location, adminActive)
    if not self.visible then return end
    local termW, termH = term.getSize()
    -- Draw line of underscores above status bar
    term.setCursorPos(1, termH - 1)
    term.setTextColor(colors.green)
    term.write(string.rep("_", termW))

    -- Prepare status bar text
    term.setCursorPos(1, termH)
    term.setTextColor(colors.green)

    -- Left: location with 1-char margin
    local left = " " .. (location or "")

    -- Center: ADMIN MODE if adminActive
    local center = adminActive and "ADMIN MODE" or ""

    -- Right: Minecraft gametime clock with 1-char margin
    local time = (os.time and os.time()) and os.time() or 0
    local hour = math.floor(time)
    local min = math.floor((time - hour) * 60)
    local right = string.format("%02d:%02d ", hour, min)

    -- Calculate positions
    local leftLen = #left
    local rightLen = #right
    local centerLen = #center
    local centerPos = math.floor((termW - centerLen) / 2) + 1
    local rightPos = termW - rightLen + 1

    -- Build line
    local line = string.rep(" ", termW)
    line = left .. line:sub(leftLen + 1)
    if centerLen > 0 then
        line = line:sub(1, centerPos - 1) .. center .. line:sub(centerPos + centerLen)
    end
    line = line:sub(1, rightPos - 1) .. right .. line:sub(rightPos + rightLen)

    term.write(line)
end

return StatusBar
