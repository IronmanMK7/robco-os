# RobCo OS - Copilot Coding Agent Instructions

## Repository Overview

**RobCo OS** is a pseudo-operating system written in **Lua** for **ComputerCraft** computers, inspired by the iconic RobCo terminals from the Fallout series. The project implements a text-based GUI with a memory dump puzzle login system and various menu-driven utilities.

- **Language:** Lua 5.1
- **Target Runtime:** ComputerCraft 1.80+
- **Project Size:** ~25 source files, ~4000 lines of Lua code
- **Architecture:** Object-oriented design with class hierarchies (UI base classes, puzzle inheritance, menu system)

## Key Architecture & File Layout

### Directory Structure
```
robco-os/
├── src/
│   ├── main.lua                 # Entry point; initializes header, statusbar, puzzle, main menu
│   ├── config/
│   │   ├── config.lua           # Config package entry point
│   │   └── settings.lua         # User settings persistence (Lua table serialization)
│   ├── puzzle/
│   │   ├── Puzzle.lua           # Base class for login puzzles
│   │   └── MemDumpPuzzle.lua    # Concrete puzzle implementation; generates random Fallout-themed word grids
│   ├── ui/
│   │   ├── UI.lua               # Base UI class with text wrapping and scrolling
│   │   ├── Header.lua           # Fixed header showing "ROBCO INDUSTRIES TERMLINK PROTOCOL"
│   │   ├── StatusBar.lua        # Fixed footer showing location, admin status, and time
│   │   └── menu/
│   │       ├── Menu.lua         # Base menu class with keyboard/mouse navigation
│   │       └── MainMenu.lua     # Main menu with dynamic submenu management
│   └── util/
│       ├── Admin.lua            # Simple admin privilege flag holder
│       └── faction/
│           └── Faction.lua      # Faction data (name, motto, headquarters, etc.)
├── installer.lua                # GitHub-based installation script (wget downloads)
├── updater.lua                  # Update script with file move detection and backup management
├── uninstaller.lua              # Cleanup and directory removal script
├── version.lua                  # Semantic versioning with compatibility checking
└── README.md
```

### Critical File Relationships

1. **main.lua** → Creates instances of `Header`, `StatusBar`, `Admin`, `MemDumpPuzzle`
2. **MemDumpPuzzle** → Extends `Puzzle` base class; inherits `showPassStatus()`, `showFailStatus()`
3. **MainMenu.lua** → Complex menu system using `Menu` class; manages dynamic submenu registration
4. **settings.lua** → Persisted as serialized Lua tables in `/robco_settings` (ComputerCraft filesystem)
5. **MemDumpPuzzle** → Generates word grids with random junk characters; clickable words trigger guesses

## Critical Development Notes

### Module Loading & Require Paths
The project uses dynamic package path setup in `main.lua`:
```lua
local sep = package.config:sub(1,1)
local base = debug.getinfo(1, 'S').source:sub(2):match('(.+)[/\\\\][^/\\\\]+$') or '.'
package.path = base .. sep .. "?.lua;" .. base .. sep .. "?" .. sep .. "init.lua;" .. package.path
```
**Always assume this is present when modules are loaded**. All `require()` paths are relative to the script's directory. When editing module files, use paths like `require("util.Admin")` (without `src/` prefix) because main.lua sets the base to `src/`.

### Object-Oriented Pattern
The codebase uses Lua's metatable pattern extensively:
```lua
local MyClass = {}
MyClass.__index = MyClass
function MyClass:new() ... end
function MyClass:method() ... end
```
Maintain this pattern in all new classes. Inheritance uses `setmetatable({}, {__index = ParentClass})`.

### Key Instance Variables to Preserve
- `header` - Header UI instance passed to many functions for drawing/hiding
- `admin` - Admin privilege object; `admin:grant()` / `admin:revoke()` / `admin:isAdminUser()`
- `statusBar` - Status bar instance passed to menu functions
- Colors are global ComputerCraft constants: `colors.green`, `colors.lime`, `colors.red`, etc.

### ComputerCraft API Dependencies
- `term.getSize()`, `term.setCursorPos()`, `term.write()`, `term.clear()`
- `fs.exists()`, `fs.isDir()`, `fs.list()`, `fs.makeDir()`, `fs.delete()`
- `io.open()` for reading/writing files
- `textutils.serialize()` / `textutils.unserialize()` for settings persistence
- `redstone.getBundledOutput()` / `redstone.setBundledOutput()` for door control (if applicable)
- `os.pullEvent()` for event handling (keyboard, mouse, etc.)
- `shell.run()` for executing `wget` commands (installer/updater use this)

### GUI Layout Conventions
- **Fixed areas:** Header (lines 1-2), StatusBar (last 2 lines)
- **Content area:** Lines between header and statusbar
- **Margins:** Typically 2-character left margin for menu items
- **Text centering:** Use `UI.centerTextBlock()` for modal dialogs
- **Menu selection:** Arrow keys and mouse clicks; `keys.enter` to confirm

## Build, Test, and Validation

### Verification Steps (No Build System)
RobCo OS is **Lua-only**; no compilation is required. The code is directly interpreted by ComputerCraft. To validate changes:

1. **Syntax Check:** Manually inspect Lua for syntax errors (unclosed strings, mismatched `end` statements, typos in identifiers)
2. **Require Path Validation:** Ensure all `require()` calls use correct relative paths from the `src/` directory
3. **Logic Review:** Verify object instantiation and method calls match the class definitions
4. **Testing Approach:** Run the installer/updater scripts in a test environment if available; otherwise rely on code review

### Known Workarounds & Issues

**Settings Persistence:**
- Settings are saved to `/robco_settings` as serialized Lua tables using `textutils.serialize()`
- The `settings:load()` function is called at module initialization; always ensure it's invoked before accessing `settings` properties
- **Workaround:** MainMenu.lua explicitly calls `settings:load()` at the top to initialize active menu options

**Module Import Order:**
- MainMenu.lua must be lazy-loaded (via `require()` inside `main()`) to avoid circular dependencies with settings
- **Never** move MainMenu to a global require at the top of main.lua

**Puzzle Restart Loop:**
- After puzzle completion (pass or fail), `main()` re-instantiates the puzzle and menu
- Menu state persists across puzzle retries via settings file
- **Preserve this behavior** when modifying the main loop

## Installer & Updater Behavior

### installer.lua
- Dynamically discovers all repository files from GitHub (excludes installer.lua itself)
- Searches for existing `robco_os/` directory on the computer; creates one at home directory if not found
- Downloads all discovered files with their full directory structure preserved (relative to repository root)
- Uses `shell.run("wget", url, filepath)` for downloads
- Fails silently if any file download fails (reports summary)
- Modifies `rom/startup.lua` to launch `robco_os/src/main.lua` on boot

### updater.lua
- Dynamically discovers all repository files from GitHub (similar to installer.lua approach)
- Searches for existing `robco_os/` directory on the computer; creates one at home directory if not found
- Downloads all discovered files and compares against local versions using content hashing
- Removes local files that no longer exist in the remote repository
- Preserves `src/config/settings.lua` (user data) and skips it during updates
- Backs up modified files with `.bak` extension before overwriting; deletes backups after successful update
- Uses `shell.run("wget", url, filepath)` for downloads
- **Critical:** Dynamically fetches file list from GitHub; no hardcoded fallback needed
- Handles moved files by matching content hashes across directory structure
- Reports summary of added, updated, removed, and skipped files

### uninstaller.lua
- Searches for existing `robco_os/` directory on the computer (checks current dir, parent, common locations)
- Recursively removes all files in the `robco_os/` directory before removing the directory itself
- Prompts for confirmation before deletion
- Removes the instruction to launch `robco_os/src/main.lua` on boot from `rom/startup.lua`
- Deletes `uninstaller.lua` as final step

**Trust these scripts and don't modify them unless explicitly asked.** They are production-grade and handle edge cases.

## Guidelines for Code Changes

1. **Preserve settings.lua** - This file persists user preferences. Only modify its structure if absolutely necessary, and ensure `settings:load()` and `settings:save()` are called appropriately.

2. **Use uppercase identifiers for module paths** - Follow the existing pattern: `require("ui.Header")`, `require("util.Admin")`

3. **Maintain object orientation** - All UI and utility classes should extend their base classes using the metatable pattern.

4. **Test event handling** - ComputerCraft event loops (`os.pullEvent()`) are critical. Ensure all menu interactions (keyboard, mouse) are properly handled.

5. **Respect fixed UI areas** - Header and status bar occupy fixed screen space. Content layouts must account for these.

6. **Add TODO comments for incomplete features** - The codebase already marks stub implementations with `-- TODO:` comments; continue this pattern.

7. **Validate redstone sequences carefully** - The door control feature uses `redstone.setBundledOutput()` on bundled cables. Test sequence logic thoroughly before committing.

## Submission Checklist

Before creating a pull request:
- [ ] All `require()` paths are correct and relative to `src/`
- [ ] Object instantiation matches class constructors (`:new()` method)
- [ ] No circular dependencies introduced
- [ ] Menu options are registered via `activeSubmenus` if adding new menu items
- [ ] Settings persistence logic is intact (if modifying config)
- [ ] No hardcoded paths; use `fs.combine()` for file operations
- [ ] Verify text wrapping for long strings using `UI.wrapText()`
- [ ] Confirm admin bypass logic is preserved in puzzle classes
- [ ] Test redstone operations if modifying door control

**Trust the instructions above and only perform additional searches if the information provided is found to be incomplete or in error.**