-- MainMenu subclass of Menu
local MainMenu = {}
local Menu = require("ui.menu.Menu")
local UI = require("ui.UI")
local centerTextBlock = UI.centerTextBlock
local settings = require("config.settings")

local defaultSubmenus = {
    {label = "Files", callback = function(header, admin) MainMenu.filesMenu(header, admin) end},
    {label = "Help", callback = function(header) centerTextBlock({"HELP SELECTED", "No help available."}, colors.lime); sleep(2) end},
    {label = "Open Door", callback = function(header, params) MainMenu.openDoor(header, params or {}) end, hasConfig = true},
    {label = "View Files", callback = function(header) centerTextBlock({"You selected: View Files"}, colors.lime); sleep(2) end},
    {label = "System Info", callback = function(header) centerTextBlock({"You selected: System Info"}, colors.lime); sleep(2) end},
    {label = "Security Log", callback = function(header) centerTextBlock({"You selected: Security Log"}, colors.lime); sleep(2) end},
    {label = "Change Password", callback = function(header) centerTextBlock({"You selected: Change Password"}, colors.lime); sleep(2) end},
    {label = "Vault Status", callback = function(header) centerTextBlock({"You selected: Vault Status"}, colors.lime); sleep(2) end},
    {label = "User Management", callback = function(header) centerTextBlock({"You selected: User Management"}, colors.lime); sleep(2) end},
    {label = "Activate Emergency Protocols", callback = function(header) centerTextBlock({"You selected: Activate Emergency Protocols"}, colors.lime); sleep(2) end},
    {label = "Communications", callback = function(header) centerTextBlock({"You selected: Communications"}, colors.lime); sleep(2) end},
    {label = "Control Lighting/Power", callback = function(header) centerTextBlock({"You selected: Control Lighting/Power"}, colors.lime); sleep(2) end}
}

-- Load saved menu options or initialize empty
settings:load()
local activeSubmenus = {}

-- Load saved menu options from settings
if settings.activeMenuOptions then
    for _, optionLabel in ipairs(settings.activeMenuOptions) do
        for _, submenu in ipairs(defaultSubmenus) do
            if submenu.label == optionLabel then
                table.insert(activeSubmenus, submenu)
                break
            end
        end
    end
end

-- Helper function to save active menu labels only
local function saveActiveMenus()
    settings.activeMenuOptions = {}
    for _, active in ipairs(activeSubmenus) do
        table.insert(settings.activeMenuOptions, active.label)
    end
    settings:save()
end

function MainMenu:new(options, headerInstance, statusBar, adminActive)
    local obj = Menu.new(self, options, "MAIN MENU", headerInstance, adminActive)
    obj.welcomeText = ""
    obj.statusBar = statusBar
    obj.location = "VAULT 101" -- Default, can be set externally
    setmetatable(obj, self)
    return obj
end

function MainMenu:draw()
    term.clear()
    if self.header then self.header:draw() end
    local leftMargin = 2
    term.setCursorPos(leftMargin, self.y)
    term.setTextColor(colors.green)
    print("--- " .. self.title .. " ---")
    if self.welcomeText ~= "" then
        term.setCursorPos(leftMargin, self.y + 1)
        print(self.welcomeText)
    end
    local visibleOptions = {}
    for i, option in ipairs(self.options) do
        if option.enabled then
            table.insert(visibleOptions, option)
        end
    end
    for i, option in ipairs(visibleOptions) do
        term.setCursorPos(leftMargin, self.y + i + (self.welcomeText ~= "" and 1 or 0))
        if i == self.selected then
            term.setTextColor(colors.lime)
            term.write("> " .. option.label)
            term.setTextColor(colors.green)
        else
            term.write("  " .. option.label)
        end
    end
    -- Draw status bar if available
    if self.statusBar then
        self.statusBar:draw(self.location or "VAULT 101", self.adminActive or false)
    end
end

-- Utility functions for menu actions
local createdFiles = {}

function MainMenu.printHeaderOnly(header)
    term.clear()
    header:draw()
end

function MainMenu.printHeader(header)
    term.clear()
    header:draw()
    term.setCursorPos(1, header:getHeight() + 1)
    term.setTextColor(colors.green)
    print("[LOGIN REQUIRED]")
end

function MainMenu.filesMenu(header, admin)
    local fileOptions = {
        {label = "[+] Create New File", enabled = true, callback = function()
            local termW, termH = term.getSize()
            term.setCursorPos(2, termH)
            term.setTextColor(colors.yellow)
            term.write("Enter new file name: ")
            local name = read()
            if name and name ~= "" then
                table.insert(createdFiles, name)
            end
        end}
    }
    for _, fname in ipairs(createdFiles) do
        table.insert(fileOptions, {label = fname, enabled = true, callback = function()
            -- Stub: open/edit file logic here
        end})
    end
    local Menu = require("ui.menu.Menu")
    local menu = Menu:new(fileOptions, "FILES", header, admin:isAdminUser())
    menu:handleInput()
end

function MainMenu.logout(header)
    term.clear()
    centerTextBlock("Logging out...", colors.green)
    sleep(1)
    term.clear()
    sleep(3)
    -- Return to puzzle (main loop will handle)
end

function MainMenu.configureOpenDoor(header)
    local config = {}
    
    -- Question 1: Number of redstone signals (1-16)
    while true do
        term.clear()
        header:draw()
        term.setCursorPos(2, 8)
        term.setTextColor(colors.green)
        print("OPEN DOOR CONFIGURATION")
        
        term.setCursorPos(2, 10)
        term.setTextColor(colors.green)
        local question = "How many redstone signals are required to operate the door?"
        local lines = UI.wrapText(question, term.getSize() - 3)
        local currentY = 10
        
        for _, line in ipairs(lines) do
            term.setCursorPos(2, currentY)
            print(line)
            currentY = currentY + 1
        end
        
        -- Adjust cursor position for input based on number of wrapped lines
        term.setCursorPos(2, currentY)
        print("Enter a number between 1 and 16:")
        term.setCursorPos(2, currentY + 1)
        local input = read()
        local num = tonumber(input)
        if num and num >= 1 and num <= 16 and math.floor(num) == num then
            config.signalCount = num
            break
        else
            term.setCursorPos(2, 10 + #lines + 3)
            term.setTextColor(colors.red)
            print("Invalid input. Please enter a whole number between 1 and 16.")
            sleep(2)
        end
    end
    
    -- Question 2: Computer side
    while true do
        term.clear()
        header:draw()
        term.setCursorPos(2, 8)
        term.setTextColor(colors.green)
        print("OPEN DOOR CONFIGURATION")
        term.setCursorPos(2, 10)
        term.setTextColor(colors.green)
        print("Which side of the computer should output signals?")
        term.setCursorPos(2, 11)
        print("Hint: Use the side connected to your bundled cable")
        
        -- Display valid sides with word wrapping
        local sideDisplay = "top, bottom, left, right, back, front"
        local sideLines = UI.wrapText(sideDisplay, 48)
        local currentY = 12
        
        term.setCursorPos(2, currentY)
        print("Valid options: ")
        currentY = currentY + 1
        
        for _, line in ipairs(sideLines) do
            term.setCursorPos(2, currentY)
            print(line)
            currentY = currentY + 1
        end
        
        term.setCursorPos(2, currentY)
        local input = string.lower(read())
        if input == "top" or input == "bottom" or input == "left" or input == "right" or input == "back" or input == "front" then
            config.side = string.lower(input)
            break
        else
            term.setCursorPos(2, currentY + 2)
            term.setTextColor(colors.red)
            print("Invalid input. Please enter one of the valid sides.")
            sleep(2)
        end
    end
    
    -- Question 3: Colors for each signal
    config.colors = {}
    local validColors = {"white", "orange", "magenta", "lightBlue", "yellow", "lime", "pink", "gray", "lightGray", "cyan", "purple", "blue", "brown", "green", "red", "black"}
    
    for i = 1, config.signalCount do
        while true do
            term.clear()
            header:draw()
            term.setCursorPos(2, 8)
            term.setTextColor(colors.green)
            print("OPEN DOOR CONFIGURATION")
            term.setCursorPos(2, 10)
            term.setTextColor(colors.green)
            print("Signal " .. i .. " of " .. config.signalCount)
            term.setCursorPos(2, 11)
            print("Enter the color for this redstone signal:")
            
            -- Display available colors with word wrapping
            local colorDisplay = table.concat(validColors, ", ")
            local colorLines = UI.wrapText(colorDisplay, 48)
            local currentY = 12
            
            term.setCursorPos(2, currentY)
            print("Available colors: ")
            currentY = currentY + 1
            
            for _, line in ipairs(colorLines) do
                term.setCursorPos(2, currentY)
                print(line)
                currentY = currentY + 1
            end
            
            term.setCursorPos(2, currentY)
            local input = string.lower(read())
            local validColor = false
            local colorIndex = 0
            
            -- Check if input is in validColors list
            for idx, color in ipairs(validColors) do
                if input == color then
                    validColor = true
                    colorIndex = idx
                    break
                end
            end
            
            -- Also validate that the color exists in the colors table
            if validColor and colors[input] == nil then
                validColor = false
            end
            if validColor then
                config.colors[i] = input
                -- Remove this color from the valid colors list
                table.remove(validColors, colorIndex)
                break
            else
                term.setCursorPos(2, currentY + 2)
                term.setTextColor(colors.red)
                print("Invalid color. Please enter an available color.")
                sleep(2)
            end
        end
    end
    
    -- Question 4: Sequence Editor
    config.sequence = MainMenu.sequenceEditor(header, config.colors, "OPEN", nil, config.side)
    
    -- Check if user cancelled
    if #config.sequence == 0 then
        return nil
    end
    
    -- Question 5: Close Door Configuration
    config.closeSequence = MainMenu.configureCloseDoor(header, config.colors, config.sequence, config.side)
    
    -- Check if user cancelled
    if config.closeSequence == nil or (type(config.closeSequence) == "table" and #config.closeSequence == 0) then
        return nil
    end
    
    -- Question 6: Remote Trigger Configuration
    while true do
        term.clear()
        header:draw()
        
        term.setCursorPos(2, 8)
        term.setTextColor(colors.yellow)
        print("REMOTE TRIGGER CONFIGURATION")
        
        term.setCursorPos(2, 10)
        term.setTextColor(colors.white)
        print("Will this door have remote trigger")
        print("capability (e.g., triggered by redstone)?")
        
        term.setCursorPos(2, 13)
        term.setTextColor(colors.cyan)
        print("[Y] Yes - Add remote trigger")
        print("[N] No - Skip remote trigger")
        
        local event, key = os.pullEvent("key")
        if key == keys.y then
            -- Ask for remote trigger color
            while true do
                -- Build list of used colors from sequences
                local usedColors = {}
                for _, step in ipairs(config.sequence) do
                    usedColors[step.color] = true
                end
                for _, step in ipairs(config.closeSequence) do
                    usedColors[step.color] = true
                end
                
                -- Sort colors: unused first, then used
                local unusedColors = {}
                local usedColorList = {}
                for _, color in ipairs(config.colors) do
                    if not usedColors[color] then
                        table.insert(unusedColors, color)
                    else
                        table.insert(usedColorList, color)
                    end
                end
                
                -- Combine: unused colors first, then used colors
                local colorsToDisplay = {}
                for _, color in ipairs(unusedColors) do
                    table.insert(colorsToDisplay, color)
                end
                for _, color in ipairs(usedColorList) do
                    table.insert(colorsToDisplay, color)
                end
                
                term.clear()
                header:draw()
                term.setCursorPos(2, 8)
                term.setTextColor(colors.yellow)
                print("SELECT REMOTE TRIGGER COLOR")
                
                term.setCursorPos(2, 10)
                term.setTextColor(colors.white)
                print("Which color wire will send the")
                print("remote trigger signal?")
                
                -- Display available colors with word wrapping
                local colorDisplay = table.concat(colorsToDisplay, ", ")
                local colorLines = UI.wrapText(colorDisplay, 48)
                local currentY = 12
                
                term.setCursorPos(2, currentY)
                print("Available colors: ")
                currentY = currentY + 1
                
                for _, line in ipairs(colorLines) do
                    term.setCursorPos(2, currentY)
                    print(line)
                    currentY = currentY + 1
                end
                
                term.setCursorPos(2, currentY)
                print("Enter color name: ")
                term.setCursorPos(2, currentY + 1)
                local input = string.lower(read())
                
                -- Check if color is in the user's configured colors
                local validColor = false
                for _, color in ipairs(config.colors) do
                    if color == input then
                        validColor = true
                        break
                    end
                end
                
                if validColor then
                    config.remoteTriggerColor = input
                    config.hasRemoteTrigger = true
                    break
                else
                    term.setCursorPos(2, currentY + 3)
                    term.setTextColor(colors.red)
                    print("Invalid color. Please try again.")
                    sleep(2)
                end
            end
            break
        elseif key == keys.n then
            config.hasRemoteTrigger = false
            config.remoteTriggerColor = nil
            break
        end
    end
    
    return config
end

function MainMenu.configureCloseDoor(header, availableColors, openSequence, side)
    term.clear()
    header:draw()
    
    term.setCursorPos(2, 8)
    term.setTextColor(colors.yellow)
    print("CLOSE DOOR CONFIGURATION")
    
    term.setCursorPos(2, 10)
    term.setTextColor(colors.white)
    print("Can the door be closed by reversing the")
    print("open sequence?")
    
    term.setCursorPos(2, 13)
    term.setTextColor(colors.cyan)
    print("[Y] Yes - Use reversed open sequence")
    print("[N] No - Create custom close sequence")
    
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.y then
            -- Reverse the open sequence
            local closeSequence = {}
            for i = #openSequence, 1, -1 do
                local step = openSequence[i]
                table.insert(closeSequence, {
                    color = step.color,
                    state = (step.state == "on") and "off" or "on", -- Flip state
                    delay = step.delay
                })
            end
            return closeSequence
        elseif key == keys.n then
            -- Create reversed sequence as starting point but allow editing
            local preloadedSequence = {}
            for i = #openSequence, 1, -1 do
                local step = openSequence[i]
                table.insert(preloadedSequence, {
                    color = step.color,
                    state = (step.state == "on") and "off" or "on", -- Flip state
                    delay = step.delay
                })
            end
            
            term.clear()
            header:draw()
            centerTextBlock({
                "CLOSE DOOR SEQUENCE EDITOR",
                "",
                "Starting with reversed open sequence.",
                "Edit as needed for your door mechanism.",
                "",
                "Press any key to continue..."
            }, colors.yellow)
            os.pullEvent("key")
            
            return MainMenu.sequenceEditor(header, availableColors, "CLOSE", preloadedSequence, side)
        end
    end
end

function MainMenu.sequenceEditor(header, availableColors, sequenceType, preloadedSequence, side)
    local sequence = preloadedSequence or {}
    local selectedStep = math.max(1, #sequence)
    local mode = "navigate" -- "navigate", "edit"
    sequenceType = sequenceType or "OPEN"
    side = side or "back"
    local scrollOffset = 0 -- Track which step is at the top of the visible area
    
    local function drawSequenceEditor()
        term.clear()
        header:draw()
        
        -- Get screen dimensions
        local screenWidth, screenHeight = term.getSize()
        
        -- Position title right after header
        local titleY = (header:getHeight() or 7) + 1
        term.setCursorPos(2, titleY)
        term.setTextColor(colors.yellow)
        print("SEQUENCE EDITOR - " .. sequenceType .. " Door")
        
        -- Calculate available space for table rows
        local headerRow = titleY + 2
        local separatorRow = headerRow + 1
        local tableStartRow = separatorRow + 1
        local instructY = screenHeight - 1 -- Reserve last 2 rows for instructions
        local maxVisibleRows = instructY - tableStartRow
        
        -- Adjust scroll offset if needed
        if selectedStep - 1 < scrollOffset then
            scrollOffset = selectedStep - 1
        elseif selectedStep - 1 >= scrollOffset + maxVisibleRows then
            scrollOffset = selectedStep - maxVisibleRows
        end
        
        -- Table header (fixed)
        term.setCursorPos(2, headerRow)
        term.setTextColor(colors.white)
        print("Step | Color      | State | Delay")
        term.setCursorPos(2, separatorRow)
        print("-----|------------|-------|-------")
        
        -- Sequence steps (scrollable)
        for displayRow = 1, maxVisibleRows do
            local stepIndex = scrollOffset + displayRow
            local screenRow = tableStartRow + displayRow - 1
            term.setCursorPos(2, screenRow)
            
            if stepIndex <= #sequence then
                local step = sequence[stepIndex]
                if stepIndex == selectedStep and mode == "navigate" then
                    term.setTextColor(colors.lime)
                    term.write("> ")
                else
                    term.setTextColor(colors.white)
                    term.write("  ")
                end
                
                local colorName = step.color:sub(1,1):upper() .. step.color:sub(2)
                local stateName = step.state:upper()
                local delayText = step.delay .. "s"
                
                term.write(string.format("%-2d | %-10s | %-5s | %s", stepIndex, colorName, stateName, delayText))
            else
                term.setTextColor(colors.white)
                term.write("  ")
            end
        end
        
        -- Instructions (fixed at bottom)
        term.setCursorPos(2, instructY)
        term.setTextColor(colors.cyan)
        if mode == "navigate" then
            print("[A]dd [E]dit [D]elete [T]est [S]ave [C]ancel")
            term.setCursorPos(2, instructY + 1)
            print("Use arrow keys to select step")
        else
            print("Editing step " .. selectedStep .. " - LEFT/RIGHT: move fields, UP/DOWN: adjust values")
            term.setCursorPos(2, instructY + 1)
            print("Press ENTER when done (ENTER on delay field for precise input)")
        end
    end
    
    local function addStep()
        table.insert(sequence, {color = availableColors[1], state = "on", delay = 0})
        selectedStep = #sequence
    end
    
    local function deleteStep()
        if #sequence > 0 then
            table.remove(sequence, selectedStep)
            if selectedStep > #sequence then
                selectedStep = math.max(1, #sequence)
            end
        end
    end
    
    local function editStep()
        if #sequence == 0 then return end
        mode = "edit"
        local step = sequence[selectedStep]
        local editField = 1 -- 1=color, 2=state, 3=delay
        
        local screenWidth, screenHeight = term.getSize()
        local titleY = (header:getHeight() or 7) + 1
        local headerRow = titleY + 2
        local separatorRow = headerRow + 1
        local tableStartRow = separatorRow + 1
        local instructY = screenHeight - 1
        local maxVisibleRows = instructY - tableStartRow
        
        while mode == "edit" do
            drawSequenceEditor()
            
            -- Calculate screen row for selected step based on scroll offset
            local screenRow = tableStartRow + (selectedStep - 1 - scrollOffset)
            
            -- Highlight current field
            term.setCursorPos(2, screenRow)
            term.setTextColor(colors.yellow)
            local colorName = step.color:sub(1,1):upper() .. step.color:sub(2)
            local stateName = step.state:upper()
            local delayText = step.delay .. "s"
            
            if editField == 1 then
                term.write(string.format("> %-2d | [%-10s] | %-5s | %s", selectedStep, colorName, stateName, delayText))
            elseif editField == 2 then
                term.write(string.format("> %-2d | %-10s | [%-5s] | %s", selectedStep, colorName, stateName, delayText))
            else
                term.write(string.format("> %-2d | %-10s | %-5s | [%s]", selectedStep, colorName, stateName, delayText))
            end
            
            term.setCursorPos(2, instructY)
            term.setTextColor(colors.white)
            if editField == 1 then
                print("Color: " .. colorName .. " (UP/DOWN to change)")
            elseif editField == 2 then
                print("State: " .. stateName .. " (UP/DOWN to toggle)")
            else
                print("Delay: " .. delayText .. " (UP/DOWN to adjust, ENTER to edit)")
            end
            
            local event, key = os.pullEvent("key")
            if key == keys.enter and editField ~= 3 then
                mode = "navigate"
                break
            elseif key == keys.left and editField > 1 then
                editField = editField - 1
            elseif key == keys.right and editField < 3 then
                editField = editField + 1
            elseif key == keys.up or key == keys.down then
                if editField == 1 then
                    -- Change color
                    local currentIndex = 1
                    for i, color in ipairs(availableColors) do
                        if color == step.color then currentIndex = i break end
                    end
                    if key == keys.up then
                        currentIndex = currentIndex + 1
                        if currentIndex > #availableColors then currentIndex = 1 end
                    else
                        currentIndex = currentIndex - 1
                        if currentIndex < 1 then currentIndex = #availableColors end
                    end
                    step.color = availableColors[currentIndex]
                elseif editField == 2 then
                    -- Toggle state
                    step.state = (step.state == "on") and "off" or "on"
                elseif editField == 3 then
                    -- Adjust delay
                    local increment = 0.5
                    if key == keys.up then
                        step.delay = step.delay + increment
                    else
                        step.delay = math.max(0, step.delay - increment)
                    end
                end
            elseif key == keys.enter and editField == 3 then
                -- Edit delay precisely
                term.setCursorPos(2, instructY + 1)
                term.setTextColor(colors.yellow)
                term.write("Enter delay (seconds): ")
                local input = read()
                local delay = tonumber(input)
                if delay and delay >= 0 then
                    step.delay = delay
                end
            end
        end
    end
    
    local function testSequence()
        term.clear()
        header:draw()
        centerTextBlock({"Testing sequence...", "Press any key to continue"}, colors.yellow)
        
        -- DEBUG: Print sequence count
        term.setCursorPos(2, 1)
        term.setTextColor(colors.gray)
        print("Sequence count: " .. #sequence)
        
        -- Send sequence
        for i, step in ipairs(sequence) do
            -- DEBUG: Print step being executed
            term.setCursorPos(2, 2)
            print("Executing step: " .. i)
            
            -- Get current bundled output state
            local currentState = redstone.getBundledOutput("" .. side .. "")
            local colorValue = colors["" .. step.color .. ""]
            
            -- Combine or subtract the signal based on state
            if step.state == "on" then
                currentState = colors.combine(currentState, colorValue)
            else
                currentState = colors.subtract(currentState, colorValue)
            end
            
            -- Apply the new state
            redstone.setBundledOutput("" .. side .. "", currentState)
            
            -- Wait for inter-step delay
            if step.delay > 0 then
                sleep(step.delay)
            end
        end
        
        -- Turn off all signals
        redstone.setBundledOutput("" .. side .. "", 0)   
        
        centerTextBlock({"Test complete!", "Press any key to continue"}, colors.green)
        os.pullEvent("key")
    end
    
    -- Main editor loop
    while true do
        drawSequenceEditor()
        
        if mode == "navigate" then
            local event, key = os.pullEvent("key")
            
            if key == keys.up and selectedStep > 1 and #sequence > 0 then
                selectedStep = selectedStep - 1
            elseif key == keys.down and selectedStep < #sequence then
                selectedStep = selectedStep + 1
            elseif key == keys.a then
                addStep()
            elseif key == keys.e and #sequence > 0 then
                editStep()
            elseif key == keys.d then
                deleteStep()
            elseif key == keys.t and #sequence > 0 then
                testSequence()
            elseif key == keys.s then
                return sequence
            elseif key == keys.c then
                return {}
            end
        end
    end
end

function MainMenu.openDoor(header, params, statusBar, admin)
    if not params.signalCount then
        centerTextBlock({"Open Door not configured!", "Please remove and re-add this option."}, colors.red)
        sleep(3)
        return
    end
    
    -- Find the door submenu entry to update state
    local doorSubmenu = nil
    for _, submenu in ipairs(activeSubmenus) do
        if submenu.label == "Open Door" or submenu.label == "Close Door" then
            doorSubmenu = submenu
            break
        end
    end
    
    -- Mark sequence as running
    if doorSubmenu then
        doorSubmenu.sequenceRunning = true
    end
    
    MainMenu.printHeaderOnly(header)
    
    -- Determine what action to take based on door state
    local shouldOpen = doorSubmenu and doorSubmenu.doorState == "closed"
    
    local sequence = shouldOpen and params.sequence or params.closeSequence
    local action = shouldOpen and "Opening" or "Closing"
    
    centerTextBlock({action .. " door...", "Sending " .. params.signalCount .. " signals on " .. string.upper(params.side) .. " side"}, colors.lime)
    
    -- Execute sequence and maintain final state
    local finalState = redstone.getBundledOutput("" .. params.side .. "")
    
    for i, step in ipairs(sequence) do
        local colorName = step.color
        local colorValue = colors["" .. colorName .. ""]
        
        -- Get current bundled output state
        local currentState = redstone.getBundledOutput("" .. params.side .. "")
        
        -- Combine or subtract the signal based on state
        if step.state == "on" then
            currentState = colors.combine(currentState, colorValue)
        else
            currentState = colors.subtract(currentState, colorValue)
        end
        
        -- Apply the new state
        redstone.setBundledOutput("" .. params.side .. "", currentState)
        finalState = currentState
        
        -- Wait for inter-step delay
        if step.delay > 0 then
            sleep(step.delay)
        end
    end
    
    -- Ensure final state is maintained
    redstone.setBundledOutput("" .. params.side .. "", finalState)
    
    -- Update door state
    if doorSubmenu then
        if shouldOpen then
            doorSubmenu.doorState = "open"
            doorSubmenu.label = "Close Door"
        else
            doorSubmenu.doorState = "closed"
            doorSubmenu.label = "Open Door"
        end
        doorSubmenu.callback = function(header) MainMenu.openDoor(header, params, statusBar, admin) end
    end
    
    -- Mark sequence as not running
    if doorSubmenu then
        doorSubmenu.sequenceRunning = false
    end
    
    -- Save updated menu state
    saveActiveMenus()
    
    -- Return to main menu
    MainMenu.mainMenu(header, statusBar, admin)
end

function MainMenu.createSubmenuMenu(header, statusBar, admin)
    MainMenu.printHeaderOnly(header)
    local parentMenuFunc = function() MainMenu.mainMenu(header, statusBar, admin) end
    local menuOpts = {}
    for _, submenu in ipairs(defaultSubmenus) do
        local alreadyActive = false
        for _, active in ipairs(activeSubmenus) do
            if submenu.label == active.label then alreadyActive = true break end
        end
        if not alreadyActive then
            table.insert(menuOpts, {
                label = submenu.label,
                enabled = true,
                callback = function()
                    local configuredSubmenu = {label = submenu.label, callback = submenu.callback}
                    
                    -- If submenu has configuration, collect parameters
                    if submenu.hasConfig then
                        if submenu.label == "Open Door" then
                            local config = MainMenu.configureOpenDoor(header)
                            
                            -- If user cancelled configuration, don't add the menu
                            if config == nil then
                                MainMenu.mainMenu(header, statusBar, admin)
                                return
                            end
                            
                            configuredSubmenu.params = config
                            configuredSubmenu.doorState = "closed"  -- Initialize door state
                            configuredSubmenu.callback = function(header) MainMenu.openDoor(header, config, statusBar, admin) end
                        end
                    end
                    
                    table.insert(activeSubmenus, configuredSubmenu)
                    saveActiveMenus()
                    centerTextBlock({submenu.label .. " added to main menu."}, colors.lime)
                    sleep(1)
                    MainMenu.mainMenu(header, statusBar, admin)
                end
            })
        end
    end
    local Menu = require("ui.menu.Menu")
    local menu = Menu:new(menuOpts, "CREATE SUBMENU", header, admin:isAdminUser(), parentMenuFunc)
    menu:handleInput()
end

function MainMenu.removeSubmenuMenu(header, statusBar, admin)
    MainMenu.printHeaderOnly(header)
    local parentMenuFunc = function() MainMenu.mainMenu(header, statusBar, admin) end
    local menuOpts = {}
    for i, submenu in ipairs(activeSubmenus) do
        if submenu.label ~= "[+] Create Submenu" and submenu.label ~= "[-] Remove Submenu" and submenu.label ~= "Exit Admin Mode" and submenu.label ~= "Logout" then
            table.insert(menuOpts, {
                label = submenu.label,
                enabled = true,
                callback = function()
                    table.remove(activeSubmenus, i)
                    saveActiveMenus()
                    centerTextBlock({submenu.label .. " removed from main menu."}, colors.red)
                    sleep(1)
                    MainMenu.mainMenu(header, statusBar, admin)
                end
            })
        end
    end
    local Menu = require("ui.menu.Menu")
    local menu = Menu:new(menuOpts, "REMOVE SUBMENU", header, admin:isAdminUser(), parentMenuFunc)
    menu:handleInput()
    -- end
end

function MainMenu.mainMenu(header, statusBar, admin)
    local isAdmin = admin:isAdminUser()
    local menuOptions = {
        {label = "[+] Create Submenu", enabled = isAdmin, callback = function()
            MainMenu.createSubmenuMenu(header, statusBar, admin)
        end},
        {label = "[-] Remove Submenu", enabled = isAdmin, callback = function()
            MainMenu.removeSubmenuMenu(header, statusBar, admin)
        end}
    }
    -- Add active submenus to menuOptions in order
    for _, submenu in ipairs(activeSubmenus) do
        table.insert(menuOptions, {
            label = submenu.label,
            enabled = true,
            callback = function() 
                if submenu.label == "Files" then
                    submenu.callback(header, admin)
                else
                    submenu.callback(header) 
                end
            end
        })
    end
    -- Add Exit Admin Mode option for admins
    if isAdmin then
        table.insert(menuOptions, {label = "Exit Admin Mode", enabled = true, callback = function()
            admin:revoke()
            MainMenu.mainMenu(header, statusBar, admin)
        end})
    end
    -- Always add Logout as the last option
    table.insert(menuOptions, {label = "Logout", enabled = true, callback = function() MainMenu.logout(header) end})
    local menuOpts = {}
    for i, opt in ipairs(menuOptions) do
        if opt.enabled then
            table.insert(menuOpts, {label=opt.label, enabled=opt.enabled, callback=opt.callback})
        end
    end
    local Menu = require("ui.menu.Menu")
    local menu = Menu:new(menuOpts, "MAIN MENU", header, admin:isAdminUser())
    menu.adminActive = admin:isAdminUser()
    menu:handleInput()
end

return MainMenu
