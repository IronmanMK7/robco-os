-- UI base class
local UI = {}
UI.__index = UI

function UI:new()
    local obj = {}
    setmetatable(obj, self)
    obj.visible = true
    return obj
end


-- Show the UI element
function UI:show()
    self.visible = true
end

-- Hide the UI element
function UI:hide()
    self.visible = false
end

-- Check if UI element is visible
function UI:isVisible()
    return self.visible
end

-- Base draw method (should be overridden)
function UI:draw()
    -- Default: do nothing
end

function UI.centerTextBlock(lines, color)
    local termW, termH = term.getSize()
    if type(lines) == "string" then lines = {lines} end
    local blockHeight = #lines
    local startY = math.floor((termH-blockHeight)/2)+1
    for i, line in ipairs(lines) do
        local lineLen = #line
        local startX = math.floor((termW-lineLen)/2)+1
        if color then term.setTextColor(color) end
        term.setCursorPos(startX, startY+i-1)
        print(line)
    end
    term.setTextColor(colors.white)
end

return UI
