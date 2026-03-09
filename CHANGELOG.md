# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## unreleased

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
