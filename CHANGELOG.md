# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
