# RobCo OS - AI Agent Instructions

## Project Overview
RobCo OS is a ComputerCraft pseudo-OS inspired by Fallout's RobCo terminals. It features a text-based GUI, login puzzle, and configurable door control systems with redstone signal sequencing.

## Architecture

### Core Entry Point
- **src/main.lua**: Initializes header, status bar, admin system, and runs puzzle → main menu loop
- Uses `package.path` manipulation for cross-directory module loading

### UI Layer (src/ui/)
- **UI.lua**: Base class with text wrapping, margins, and scrolling utilities
  - All text output should call `wrapText()` to handle overflow
  - `centerTextBlock()` uses wrapText for automatic word wrapping
  - `setMargin(margin)` controls left/right indentation for non-fixed areas
- **Header.lua**: Fixed header element (marked as non-scrollable)
- **StatusBar.lua**: Fixed status bar element (marked as non-scrollable)
- **menu/MainMenu.lua**: Main menu system with submenu management
  - `activeSubmenus`: Global table storing configured menu items
  - Door control stores `doorState` ("open"/"closed"), `sequenceRunning` flag
  - Menu labels dynamically update based on door state

### Sequence Editor (src/ui/menu/MainMenu.lua)
- **sequenceEditor()**: Scrollable table for configuring redstone sequences
  - Sequence structure: `{color, state ("on"/"off"), delay (seconds)}`
  - Supports Add/Edit/Delete/Test/Save/Cancel operations
  - Cancel returns `{}` and exits without proceeding to next config step
  - Test sequence does NOT affect door state tracking

### Door Control Configuration (configureOpenDoor)
- 6-step wizard stored in configuredSubmenu
  1. Signal count (1-16)
  2. Computer side (top/bottom/left/right/back/front)
  3. Color selection for signals
  4. Open sequence editor
  5. Close sequence editor
  6. Remote trigger configuration (if enabled, shows unused colors first)
- Returns `nil` if user cancels at any step
- Door initialized with `doorState = "closed"`

### Redstone Signal Management
- **Smart bundled cable handling**: Use `colors.combine()` and `colors.subtract()` with `redstone.getBundledOutput()`
- Signals remain active after sequences to maintain door state
- Each step: read current state → combine/subtract color → apply state
- Example from openDoor():
  ```lua
  local currentState = redstone.getBundledOutput(side)
  if step.state == "on" then
    currentState = colors.combine(currentState, colorValue)
  else
    currentState = colors.subtract(currentState, colorValue)
  end
  redstone.setBundledOutput(side, currentState)
  ```

### Text Layout Conventions
- **maxWidth default**: `term.getSize() - leftMargin - rightMargin` (default margins = 1)
- **Fixed areas**: Header (rows 1-7) and status bar (row 24) never scroll
- **Word wrap**: Always applies margins and preserves complete words
- **Dynamic menu text**: "Open Door" ↔ "Close Door" based on `doorState`

## Key Patterns

### Menu Callbacks with Closures
Callbacks capture `statusBar` and `admin` through closure:
```lua
configuredSubmenu.callback = function(header) 
    MainMenu.openDoor(header, params, statusBar, admin) 
end
```

### Settings Persistence
- Settings stored via `require("config.settings"):save()`
- Active menu options stored as labels only, looked up from `defaultSubmenus`

### Dynamic Menu Updates
After door operation completes:
1. Update `doorSubmenu.doorState` and `doorSubmenu.label`
2. Update callback with new params
3. Call `saveActiveMenus()` to persist
4. Return to `MainMenu.mainMenu()` instead of modal dialogs

### Scrollable Tables
- Fixed headers and instructions at top/bottom
- Row calculations: `screenRow = tableStartRow + (stepIndex - 1 - scrollOffset)`
- Auto-scroll keeps selected step in viewport

## Development Workflow

### Building/Running
- Load `src/main.lua` in ComputerCraft
- Installer/uninstaller/updater handle dynamic directory detection

### Testing Sequences
- `testSequence()` runs without affecting door state
- Debug flags available in testSequence for step-by-step verification

### Adding New UI Functions
1. Should accept text and return wrapped lines
2. Call `UI.wrapText()` to handle overflow
3. Respect margins: `leftMargin = 1, rightMargin = 1` by default
4. Never manually word-wrap; use utility functions

## Common Tasks

### Add Remote Trigger Monitoring
- Check `config.hasRemoteTrigger` and `config.remoteTriggerColor`
- Block input while `doorSubmenu.sequenceRunning` is true
- Execute appropriate sequence based on `doorSubmenu.doorState`

### Update Menu After State Change
```lua
doorSubmenu.doorState = "open"
doorSubmenu.label = "Close Door"
doorSubmenu.callback = function(header) MainMenu.openDoor(header, params, statusBar, admin) end
saveActiveMenus()
```

### Handle Configuration Cancellation
```lua
if config == nil then
    MainMenu.mainMenu(header, statusBar, admin)
    return
end
```
