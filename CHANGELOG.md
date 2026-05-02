# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## unreleased

## [2.1.0] - 2026-05-02

### Added
- implement user command to send requests (only if the bar is open)
- add width variable to `M.config` table to be modifiable by the user
- add a table to save request & response data in `lua/adore/history.lua`
- implement history of request & response per session (only with telescope installed)
- create & configure a telescope picker in `lua/adore/picker.lua`
### Changed
- move data recollection logic from `handle_enter` to `M.get_data`

## [2.0.0] - 2026-04-18

### Added
- create user commands for focus, unfocus, open_bar and message functions
- virtual text to show an example of how the data should be written for bodies, queries and headers
- setup function that receive parameters from the user and modifies the configuration table

### Changed
- Result window now opens as a floating window rather than a split in the middle of the bar
- response message now changes dynamically depending on the status code
- changed focus keymap to `Alt+Esc` for user-friendly without depending on `<leader>`
- changed bar to the right side of the window

### Fixed
- UI variable references now point to the specified table
- fix focus/unfocus functions from local to be part of the M table

### Removed
- delete "on" and "off" buttons for data activation

## [1.2.0] - 2026-03-09

### Added
- UI table in M to manage windows id and buffers
- movement between windows using <Tab>
- implement function to set each data buffer for body, header and query in data section window
- keymaps for buffer movement in data section using `l` and `h`
- set filetypes for each buffer to have correct highlighting instead of plain text
- implement focus/unfocus functions to improve the movement between the bar and the main window

### Changed
- separate bar into control section (send button, methods & url) and data section (Body, Header & Query)
- the keymap to close windows in open_bar() now manages windows validation
- headers and queries now are readed and send along with the request
- activation buttons for body, headers and queries in control section

### Fixed
- conflict between global keymaps through implementation of an auxiliary function for buffer-local keymaps

## [1.1.0] - 2026-03-03

### Added
- Automatic formating for JSON response using `jq`
- Ciclyc selector for each HTTP methods (GET, POST, PUT, DELETE)
- Function `world_domination()` to declare our goal

### Fixed
- Error where an empty response windows is opened during a conection failure

## [1.0.0] - 2026-03-02

### Added
- CHANGELOG.md file

### Changed
- implement logic to send requests with Body for POST, PUT and DELETE methods, excluding GET
