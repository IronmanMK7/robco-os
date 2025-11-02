-- MainMenu subclass of Menu
local MainMenu = {}
local Menu = require("ui.menu.Menu")
local centerTextBlock = require("ui.UI").centerTextBlock
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
        print("How many redstone signals are required to operate the door?")
        term.setCursorPos(2, 11)
        print("Enter a number between 1 and 16:")
        term.setCursorPos(2, 12)
        local input = read()
        local num = tonumber(input)
        if num and num >= 1 and num <= 16 and math.floor(num) == num then
            config.signalCount = num
            break
        else
            term.setCursorPos(2, 14)
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
        print("Valid options: TOP, BOTTOM, LEFT, RIGHT, BACK, FRONT")
        term.setCursorPos(2, 12)
        print("Hint: Use the side connected to your bundled cable")
        term.setCursorPos(2, 13)
        local input = string.upper(read())
        if input == "TOP" or input == "BOTTOM" or input == "LEFT" or input == "RIGHT" or input == "BACK" or input == "FRONT" then
            config.side = string.lower(input)
            break
        else
            term.setCursorPos(2, 15)
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
            term.setCursorPos(2, 12)
            print("Valid colors: white, orange, magenta, lightBlue, yellow,")
            term.setCursorPos(2, 13)
            print("lime, pink, gray, lightGray, cyan, purple, blue,")
            term.setCursorPos(2, 14)
            print("brown, green, red, black")
            term.setCursorPos(2, 15)
            local input = string.lower(read())
            local validColor = false
            for _, color in ipairs(validColors) do
                if input == color then
                    validColor = true
                    break
                end
            end
            if validColor then
                config.colors[i] = input
                break
            else
                term.setCursorPos(2, 17)
                term.setTextColor(colors.red)
                print("Invalid color. Please enter a valid RedNet cable color.")
                sleep(2)
            end
        end
    end
    
    -- Question 4: Sequence Editor
    config.sequence = MainMenu.sequenceEditor(header, config.colors, "OPEN")
    
    -- Question 5: Close Door Configuration
    config.closeSequence = MainMenu.configureCloseDoor(header, config.colors, config.sequence)
    
    return config
end

function MainMenu.configureCloseDoor(header, availableColors, openSequence)
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
            
            return MainMenu.sequenceEditor(header, availableColors, "CLOSE", preloadedSequence)
        end
    end
end

function MainMenu.sequenceEditor(header, availableColors, sequenceType, preloadedSequence)
    local sequence = preloadedSequence or {}
    local selectedStep = math.max(1, #sequence)
    local mode = "navigate" -- "navigate", "edit"
    sequenceType = sequenceType or "OPEN"
    
    local function drawSequenceEditor()
        term.clear()
        header:draw()
        term.setCursorPos(2, 8)
        term.setTextColor(colors.yellow)
        print("SEQUENCE EDITOR - " .. sequenceType .. " Door")
        
        -- Table header
        term.setCursorPos(2, 10)
        term.setTextColor(colors.white)
        print("Step | Color      | State | Delay")
        term.setCursorPos(2, 11)
        print("-----|------------|-------|------")
        
        -- Sequence steps
        for i, step in ipairs(sequence) do
            term.setCursorPos(2, 12 + i - 1)
            if i == selectedStep and mode == "navigate" then
                term.setTextColor(colors.lime)
                term.write("> ")
            else
                term.setTextColor(colors.white)
                term.write("  ")
            end
            
            local colorName = step.color:sub(1,1):upper() .. step.color:sub(2)
            local stateName = step.state:upper()
            local delayText = step.delay .. "s"
            
            term.write(string.format("%-2d | %-10s | %-5s | %s", i, colorName, stateName, delayText))
        end
        
        -- Instructions
        local instructY = math.max(18, 12 + #sequence + 2)
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
        
        while mode == "edit" do
            drawSequenceEditor()
            
            -- Highlight current field
            term.setCursorPos(2, 12 + selectedStep - 1)
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
            
            term.setCursorPos(2, 20)
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
                -- Edit delay
                term.setCursorPos(2, 21)
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
        centerTextBlock({"Testing sequence...", "Press any key to stop"}, colors.yellow)
        
        for i, step in ipairs(sequence) do
            term.setCursorPos(2, 12)
            term.setTextColor(colors.lime)
            print("Step " .. i .. ": " .. step.color:upper() .. " " .. step.state:upper())
            
            -- Here you would actually send the redstone signal
            -- redstone.setBundledOutput(side, colors[step.color], step.state == "on")
            
            if step.delay > 0 then
                for j = 1, math.floor(step.delay * 10) do
                    if os.pullEvent("key") then return end
                    sleep(0.1)
                end
            end
        end
        
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

function MainMenu.openDoor(header, params)
    if not params.signalCount then
        centerTextBlock({"Open Door not configured!", "Please remove and re-add this option."}, colors.red)
        sleep(3)
        return
    end
    
    MainMenu.printHeaderOnly(header)
    centerTextBlock({"Opening door...", "Sending " .. params.signalCount .. " signals on " .. string.upper(params.side) .. " side"}, colors.lime)
    
    -- Send redstone signals
    for i, color in ipairs(params.colors) do
        redstone.setBundledOutput(params.side, colors[color], true)
    end
    
    sleep(2)
    centerTextBlock({"Door opened!", "Press any key to close door..."}, colors.green)
    os.pullEvent("key")
    
    -- Turn off redstone signals
    for i, color in ipairs(params.colors) do
        redstone.setBundledOutput(params.side, colors[color], false)
    end
    
    centerTextBlock({"Door closed!"}, colors.green)
    sleep(1)
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
                            configuredSubmenu.params = config
                            configuredSubmenu.callback = function(header) MainMenu.openDoor(header, config) end
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
