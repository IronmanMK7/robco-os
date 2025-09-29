-- Header class, subclass of UI
local UI = require("ui.UI")
local Header = setmetatable({}, {__index = UI})
Header.__index = Header

function Header:new()
    local termW, _ = term.getSize()
    local obj = UI.new(self)
    obj.visible = true
    obj.text = "ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL"
    obj.color = colors.green
    obj.line = 1
    obj.height = 1
    obj.width = termW
    setmetatable(obj, self)
    return obj
end


function Header:show()
    self.visible = true
end

function Header:hide()
    self.visible = false
end

function Header:setText(newText)
    self.text = newText
end

function Header:setColor(newColor)
    self.color = newColor
end

function Header:setLine(newLine)
    self.line = newLine
end

function Header:toggle()
    self.visible = not self.visible
    if self.visible then self:draw() else self:clear() end
end

function Header:clear()
    local termW, _ = term.getSize()
    term.setCursorPos(1, self.line)
    term.setTextColor(colors.black)
    term.write(string.rep(" ", termW))
end

function Header:getHeight()
    return self.visible and 2 or 0
end


function Header:draw()
    if not self.visible then return end
    local termW, _ = term.getSize()
    term.setCursorPos(1, self.line)
    term.setTextColor(self.color)
    term.write(self.text)
    term.setCursorPos(1, self.line + 1)
    term.setTextColor(self.color)
    term.write(string.rep("-", termW))
end

function Header:isVisible()
    return self.visible
end

return Header
