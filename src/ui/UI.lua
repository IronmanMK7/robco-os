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
    
    -- Wrap each line to fit screen width
    local wrappedLines = {}
    for _, line in ipairs(lines) do
        local wrapped, count = UI.wrapText(line, termW - 2, 1, 1)
        for _, wrappedLine in ipairs(wrapped) do
            table.insert(wrappedLines, wrappedLine)
        end
    end
    
    local blockHeight = #wrappedLines
    local startY = math.floor((termH - blockHeight) / 2) + 1
    
    if color then term.setTextColor(color) end
    for i, line in ipairs(wrappedLines) do
        local lineLen = #line
        local startX = math.floor((termW - lineLen) / 2) + 1
        term.setCursorPos(startX, startY + i - 1)
        print(line)
    end
    term.setTextColor(colors.white)
end

-- Word wrap text to fit screen width with margin support
-- maxWidth: maximum width (if nil, uses screen width minus margins)
-- leftMargin: left margin in characters (default 1)
-- rightMargin: right margin in characters (default 1)
-- Returns: table of wrapped lines and total number of lines needed
function UI.wrapText(text, maxWidth, leftMargin, rightMargin)
    leftMargin = leftMargin or 1
    rightMargin = rightMargin or 1
    
    if not maxWidth then
        local screenW = term.getSize()
        maxWidth = screenW - leftMargin - rightMargin
    end
    
    local lines = {}
    local currentLine = ""
    
    for word in text:gmatch("%S+") do
        if currentLine == "" then
            currentLine = word
        elseif #(currentLine .. " " .. word) <= maxWidth then
            currentLine = currentLine .. " " .. word
        else
            table.insert(lines, currentLine)
            currentLine = word
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    return lines, #lines
end

-- Print text with automatic word wrapping and margin support
-- Returns the number of lines printed
function UI.printWrapped(text, startX, startY, maxWidth, color, leftMargin, rightMargin)
    leftMargin = leftMargin or 1
    rightMargin = rightMargin or 1
    
    if not maxWidth then
        local screenW = term.getSize()
        maxWidth = screenW - leftMargin - rightMargin
    end
    
    local lines, lineCount = UI.wrapText(text, maxWidth, leftMargin, rightMargin)
    
    if color then
        term.setTextColor(color)
    end
    
    for i, line in ipairs(lines) do
        term.setCursorPos(startX or (leftMargin + 1), (startY or 1) + i - 1)
        print(line)
    end
    
    term.setTextColor(colors.white)
    return lineCount
end

-- Set left and right margins for non-fixed UI elements
-- margin: number of characters to indent from edges
function UI.setMargin(margin)
    UI.leftMargin = margin or 1
    UI.rightMargin = margin or 1
end

-- Get current margins
function UI.getMargin()
    return UI.leftMargin or 1, UI.rightMargin or 1
end

-- Scrolling text buffer for handling overflow
-- fixedAreas: table of {startY, endY} for areas that should not scroll
-- Returns: scrolling text manager object
function UI.createScrollingBuffer(screenHeight, fixedAreas)
    local buffer = {
        content = {},           -- Array of text lines
        screenHeight = screenHeight,
        fixedAreas = fixedAreas or {},  -- {startY, endY, ...}
        currentScroll = 0
    }
    
    -- Calculate scrollable area
    function buffer:getScrollableArea()
        local scrollStart = 1
        local scrollEnd = self.screenHeight
        
        -- Adjust for fixed areas at top
        for i = 1, #self.fixedAreas, 2 do
            local fixedStart = self.fixedAreas[i]
            local fixedEnd = self.fixedAreas[i + 1]
            if fixedEnd >= scrollStart then
                scrollStart = math.max(scrollStart, fixedEnd + 1)
            end
        end
        
        return scrollStart, scrollEnd
    end
    
    -- Add text to buffer
    function buffer:addText(text, color)
        if type(text) == "string" then
            local lines = UI.wrapText(text)
            for _, line in ipairs(lines) do
                table.insert(self.content, {line = line, color = color})
            end
        elseif type(text) == "table" then
            for _, line in ipairs(text) do
                table.insert(self.content, {line = line, color = color})
            end
        end
    end
    
    -- Check if content will overflow
    function buffer:willOverflow()
        local scrollStart, scrollEnd = self:getScrollableArea()
        local scrollableLines = scrollEnd - scrollStart + 1
        local contentLines = #self.content
        return contentLines > scrollableLines
    end
    
    -- Render content to screen, scrolling if needed
    function buffer:render()
        local scrollStart, scrollEnd = self:getScrollableArea()
        local scrollableLines = scrollEnd - scrollStart + 1
        local contentLines = #self.content
        
        -- If content exceeds scrollable area, adjust scroll
        if contentLines > scrollableLines then
            self.currentScroll = contentLines - scrollableLines
        else
            self.currentScroll = 0
        end
        
        -- Clear scrollable area
        for y = scrollStart, scrollEnd do
            term.setCursorPos(1, y)
            term.clearLine()
        end
        
        -- Render visible content
        local displayStart = self.currentScroll + 1
        local displayEnd = math.min(self.currentScroll + scrollableLines, contentLines)
        
        for i = displayStart, displayEnd do
            local screenY = scrollStart + (i - displayStart)
            term.setCursorPos(2, screenY)
            if self.content[i].color then
                term.setTextColor(self.content[i].color)
            end
            print(self.content[i].line)
        end
        
        term.setTextColor(colors.white)
    end
    
    -- Clear buffer
    function buffer:clear()
        self.content = {}
        self.currentScroll = 0
    end
    
    return buffer
end

return UI

