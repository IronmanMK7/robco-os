-- MemDumpPuzzle subclass
local Puzzle = require("puzzle.Puzzle")
local Admin = require("util.Admin")
local Faction = require("util.faction.Faction")
local MemDumpPuzzle = setmetatable({}, {__index = Puzzle})
MemDumpPuzzle.__index = MemDumpPuzzle

-- Override adminBypass for ATTEMPTS click backdoor
function MemDumpPuzzle:adminBypass(event, x, y, attemptsColW)
    local termW, termH = term.getSize()
    local attemptsX = termW - attemptsColW + 1
    local attemptsY = (self.header and self.header:getHeight() or 0) + 3
    -- Track ATTEMPTS clicks in self.adminBypassClicks
    if not self.adminBypassClicks then self.adminBypassClicks = 0 end
    if event == "mouse_click" and x >= attemptsX and x <= attemptsX + 9 and y == attemptsY then
        self.adminBypassClicks = self.adminBypassClicks + 1
        if self.adminBypassClicks >= self.maxGuesses then
            self.adminBypassClicks = 0
            return true
        end
    else
        -- Reset if click is elsewhere
        self.adminBypassClicks = 0
    end
    return false
end

function MemDumpPuzzle:new(headerInstance, adminInstance, factionInstance)
    local obj = Puzzle:new(headerInstance, factionInstance or Faction:new())
    setmetatable(obj, self)
    obj.guessHistory = {}
    obj.maxGuesses = 8
    obj.hoveredWord = nil
    obj.header = headerInstance
    obj.admin = adminInstance
    obj.faction = factionInstance or Faction:new()
    return obj
end

function MemDumpPuzzle:generateMemoryDumpGrid(words)
    local chars = "!@#$%^&*()-_=+[]{}|;:',.<>/?"
    local termW, termH = term.getSize()
    local margin = 2
    local addrWidth = 7
    local attemptsColW = 17
    local separation = 2
    local colWidth = termW - attemptsColW - margin - addrWidth - separation
    if colWidth < 8 then colWidth = 8 end
    local linesPerCol = math.min(10, termH - 7)
    if linesPerCol < #words then linesPerCol = #words end
    local grid = {}
    local wordPositions = {}
    local usedLines = {}
    local wordSlots = {}
    for i = 1, #words do
        local n
        repeat
            n = math.random(1, linesPerCol)
        until not usedLines[n]
        usedLines[n] = true
        table.insert(wordSlots, {line=n, word=words[i]})
    end
    for y = 1, linesPerCol do
        local word = nil
        local wordPos = nil
        
        -- Find if there's a word for this line
        for _, slot in ipairs(wordSlots) do
            if slot.line == y then
                word = slot.word
                break
            end
        end
        
        -- Create an array to build the line
        local lineChars = {}
        
        -- Fill entire line with random junk characters first
        for x = 1, colWidth do
            local randomIndex = math.random(1, #chars)
            lineChars[x] = chars:sub(randomIndex, randomIndex)
        end
        
        -- If there's a word for this line, place it at a random position
        if word then
            local maxPos = colWidth - #word + 1
            if maxPos >= 1 then
                local pos = math.random(1, maxPos)
                wordPos = pos
                
                -- Replace junk characters with word characters
                for i = 1, #word do
                    lineChars[pos + i - 1] = word:sub(i, i)
                end
            end
        end
        
        -- Convert array to string
        local line = table.concat(lineChars)
        grid[y] = line
        if word and wordPos then
            local xStart = margin + addrWidth
            local screenX = xStart + wordPos - 1
            local screenY = y + (self.header and self.header:getHeight() or 0) + 3
            table.insert(wordPositions, {word=word, x=screenX, y=screenY, line=y, wordPos=wordPos})
        end
    end
    return grid, wordPositions, colWidth, linesPerCol, addrWidth, margin, attemptsColW, separation
end

function MemDumpPuzzle:drawMemoryDump(grid, wordPositions, hoveredWord, colWidth, linesPerCol, addrWidth, margin, separation)
    local termW, termH = term.getSize()
    for y = 1, linesPerCol do
        local address = string.format("0x%04X", 0xF000 + (y - 1) * 16)
        local line = grid[y] or ""
        local xStart = margin
        if #line > colWidth then
            line = line:sub(1, colWidth)
        elseif #line < colWidth then
            line = line .. string.rep(" ", colWidth - #line)
        end
        term.setCursorPos(xStart, y + (self.header and self.header:getHeight() or 0) + 3)
        
        -- Draw address
        term.setTextColor(colors.green)
        term.write(address .. " ")
        
        -- Draw line character by character, highlighting words
        for x = 1, #line do
            local char = line:sub(x, x)
            local isWordChar = false
            local isHovered = false
            
            -- Check if this character is part of a word
            for _, wordData in ipairs(wordPositions) do
                if wordData.line == y then
                    local wordStart = wordData.wordPos
                    local wordEnd = wordData.wordPos + #wordData.word - 1
                    if x >= wordStart and x <= wordEnd then
                        isWordChar = true
                        if wordData.word == hoveredWord then
                            isHovered = true
                        end
                        break
                    end
                end
            end
            
            -- Set color based on word status
            if isWordChar then
                term.setTextColor(isHovered and colors.lime or colors.green)
            else
                term.setTextColor(colors.green)
            end
            
            term.write(char)
        end
        
        term.write(string.rep(" ", separation))
    end
end

function MemDumpPuzzle:drawGuessHistory(attemptsColW, separation)
    local termW, termH = term.getSize()
    local colX = termW - attemptsColW + 1
    if colX - separation < 1 then colX = separation + 1 end
    local colY = (self.header and self.header:getHeight() or 0) + 3
    term.setTextColor(colors.green)
    term.setCursorPos(colX, colY)
    term.write("[ATTEMPTS]")
    for i = 1, self.maxGuesses do
        local entry = self.guessHistory[i]
        term.setCursorPos(colX, colY + i + 1)
        if entry then
            local guessStr = entry.word
            if #guessStr > 8 then guessStr = guessStr:sub(1,8) end
            term.write(guessStr .. " | " .. entry.likeness)
        else
            term.write("________ | _")
        end
    end
end

function MemDumpPuzzle:getWordAt(wordPositions, x, y)
    for i, wordData in ipairs(wordPositions) do
        local startX = wordData.x
        local endX = startX + #wordData.word - 1
        if y == wordData.y and x >= startX and x <= endX then
            return wordData.word, i
        end
    end
    return nil, nil
end

-- Generate the word list for the puzzle
function MemDumpPuzzle:generateWords()
    -- Varied 8-character words for Fallout-themed terminal
    local wordBank = {
        "TERMINAL", "PASSWORD", "COMPUTER", "ACTIVATE", "SHUTDOWN", "OVERRIDE", 
        "LOCKDOWN", "SECURITY", "CONTROLS", "DATABASE", "INITIATE", "PROTOCOL",
        "RESEARCH", "REACTION", "MUTATION", "CREATURE", "SPECIMEN", "FACILITY",
        "CHAMBERS", "ANALYSIS", "BIOLOGIC", "CHEMICAL", "GENETICS", "SEQUENCE",
        "COMPOUND", "MATERIAL", "HARDWARE", "SOFTWARE", "DOWNLOAD", "FIREWALL",
        "BACKDOOR", "BOOTLOAD", "PARALLEL", "FUNCTION", "VARIABLE", "REGISTRY",
        "PATHOGEN", "IMMUNITY", "ANTIBODY", "CELLULAR", "ORGANISM", "BACTERIA",
        "ROBOTICS", "CYBERNET", "DATACORE", "SYSTRACE", "NETWORK", "MAINLOOP",
        "EXECMODE", "RUNTIME", "KERNELS", "MODULES", "PROCESS", "THREADS"
    }
    
    -- Select 8 random words from the bank
    local selectedWords = {}
    local usedIndices = {}
    while #selectedWords < 8 do
        local idx = math.random(1, #wordBank)
        if not usedIndices[idx] then
            usedIndices[idx] = true
            table.insert(selectedWords, wordBank[idx])
        end
    end
    
    self.words = selectedWords
    self.correctWord = self.words[math.random(1, #self.words)]
    self.attemptsLeft = self.maxGuesses
    return self.words
end

-- Check the guess against the correct word
function MemDumpPuzzle:checkGuess(guess)
    local isCorrect = guess == self.correctWord
    local likeness = 0
    for i = 1, math.min(#guess, #self.correctWord) do
        if guess:sub(i,i) == self.correctWord:sub(i,i) then
            likeness = likeness + 1
        end
    end
    if not isCorrect then
        self.attemptsLeft = self.attemptsLeft - 1
    end
    return isCorrect, likeness, self.attemptsLeft
end

function MemDumpPuzzle:run()
    -- Use MemDumpPuzzle's own puzzle logic methods
    local words = self:generateWords() -- should return the word list
    local grid, wordPositions, colWidth, linesPerCol, addrWidth, margin, attemptsColW, separation = self:generateMemoryDumpGrid(words)
    self.guessHistory = {}
    self.hoveredWord = nil
    local likeness, attemptsLeft = 0, self.maxGuesses
    local lastGuess = ""
    local puzzleActive = true
    while puzzleActive do
        term.clear()
        if self.header then
            self.header:draw()
        end
        self:drawMemoryDump(grid, wordPositions, self.hoveredWord, colWidth, linesPerCol, addrWidth, margin, separation)
        self:drawGuessHistory(attemptsColW, separation)
        local event, p1, p2, p3 = os.pullEvent()
        if event == "mouse_move" or event == "mouse_drag" or event == "mouse_click" then
            local x, y = p2, p3
            if self:adminBypass(event, x, y, attemptsColW) then
                if self.admin then self.admin:grant() end
                self:showPassStatus(self.admin and self.admin:isAdminUser())
                puzzleActive = false
            else
                local word, idx = self:getWordAt(wordPositions, x, y)
                if word then
                    self.hoveredWord = word
                    if event == "mouse_click" then
                        local guess = word
                        lastGuess = guess
                        local isCorrect, likeness, attemptsLeft = self:checkGuess(guess)
                        table.insert(self.guessHistory, 1, {word=guess, likeness=likeness})
                        if #self.guessHistory > self.maxGuesses then table.remove(self.guessHistory) end
                        if isCorrect then
                            self:showPassStatus(self.admin and self.admin:isAdminUser())
                            puzzleActive = false
                        elseif attemptsLeft == 0 then
                            self:showFailStatus()
                            puzzleActive = false
                        end
                    end
                else
                    self.hoveredWord = nil
                end
            end
        end
    end
end

local puzzle = MemDumpPuzzle:new(header)

return MemDumpPuzzle
