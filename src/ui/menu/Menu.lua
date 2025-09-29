-- Menu class, subclass of UI
local UI = require("ui.UI")
local Menu = setmetatable({}, {__index = UI})
Menu.__index = Menu

function Menu:new(options, title, headerInstance, adminActive, previousMenuFunc)
    local termW, termH = term.getSize()
    local obj = UI.new(self)
    obj.options = options or {}
    obj.title = title or "MENU"
    obj.selected = 1
    obj.timeout = 60
    obj.active = true
    obj.x = 1
    obj.header = headerInstance
    obj.y = (headerInstance and headerInstance:getHeight() or 0) + 2
    obj.width = termW
    obj.height = termH
    obj.hasBackOption = true
    obj.adminActive = adminActive or false
    obj.previousMenuFunc = previousMenuFunc
    if title ~= "MAIN MENU" then
        table.insert(obj.options, {label = "Back", enabled = true, callback = function()
            if obj.previousMenuFunc then
                obj.active = false
                obj.previousMenuFunc()
            else
                obj:exit()
            end
        end})
    else
        obj.hasBackOption = false
    end
    setmetatable(obj, self)
    return obj
end

function Menu:draw()
    term.clear()
    if self.header then self.header:draw() end
    local leftMargin = 2
    term.setCursorPos(leftMargin, self.y)
    term.setTextColor(colors.green)
    print("--- " .. self.title .. " ---")
    local visibleOptions = {}
    local backIndex = nil
    for i, option in ipairs(self.options) do
        if option.enabled and option.label ~= "Back" then
            table.insert(visibleOptions, option)
        elseif option.label == "Back" then
            backIndex = i
        end
    end
    for i, option in ipairs(visibleOptions) do
        term.setCursorPos(leftMargin, self.y + i)
        if i == self.selected then
            term.setTextColor(colors.lime)
            term.write("> " .. option.label)
            term.setTextColor(colors.green)
        else
            term.write("  " .. option.label)
        end
    end
    -- Draw Back option at the bottom
    if backIndex then
        local termW, termH = term.getSize()
        local backY = termH - (self.statusBar and 2 or 1)
        term.setCursorPos(leftMargin, backY)
        if self.selected == #visibleOptions + 1 then
            term.setTextColor(colors.lime)
            term.write("> Back")
            term.setTextColor(colors.green)
        else
            term.write("  Back")
        end
    end
    -- Draw status bar if available
    if self.statusBar then
        self.statusBar:draw(self.location or "VAULT 101", self.adminActive or false)
    end
end

function Menu:handleInput()
    local startTime = os.clock()
    local visibleOptions = {}
    local backIndex = nil
    for i, option in ipairs(self.options) do
        if option.enabled and option.label ~= "Back" then
            table.insert(visibleOptions, option)
        elseif option.label == "Back" then
            backIndex = i
        end
    end
    local leftMargin = 2
    local totalOptions = #visibleOptions + (backIndex and 1 or 0)
    while self.active do
        self:draw()
        local event, p1, p2, p3 = os.pullEvent()
        if os.clock() - startTime > self.timeout then
            self:exit()
            break
        end
        if event == "key" then
            local key = p1
            if key == keys.up then
                self.selected = self.selected - 1
                if self.selected < 1 then self.selected = totalOptions end
            elseif key == keys.down then
                self.selected = self.selected + 1
                if self.selected > totalOptions then self.selected = 1 end
            elseif key == keys.enter then
                if self.selected <= #visibleOptions then
                    self:selectOption(self.selected)
                elseif backIndex then
                    self.options[backIndex].callback()
                end
                break
            end
        elseif event == "mouse_move" or event == "mouse_drag" then
            local mx, my = p2, p3
            for i = 1, #visibleOptions do
                if mx >= leftMargin and mx <= leftMargin + 20 and my == self.y + i then
                    self.selected = i
                end
            end
            if backIndex then
                local termW, termH = term.getSize()
                local backY = termH - (self.statusBar and 2 or 1)
                if mx >= leftMargin and mx <= leftMargin + 20 and my == backY then
                    self.selected = totalOptions
                end
            end
        elseif event == "mouse_click" then
            local mx, my = p2, p3
            for i = 1, #visibleOptions do
                if mx >= leftMargin and mx <= leftMargin + 20 and my == self.y + i then
                    self.selected = i
                    self:selectOption(self.selected)
                    break
                end
            end
        end
    end
end

function Menu:selectOption(index)
    local visibleOptions = {}
    for i, option in ipairs(self.options) do
        if option.enabled then
            table.insert(visibleOptions, option)
        end
    end
    local option = visibleOptions[index]
    if option and option.callback then
        option.callback()
    end
    self:exit()
end

function Menu:updateOptions(newOptions)
    self.options = newOptions
end

function Menu:setTitle(newTitle)
    self.title = newTitle
end

function Menu:setTimeout(seconds)
    self.timeout = seconds
end

function Menu:exit()
    self.active = false
end

return Menu
