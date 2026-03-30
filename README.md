# AdoRest.nvim 🎤
[Vídeo 2026-03-06 20-36-52.webm](https://github.com/user-attachments/assets/29e0aa5a-d354-430b-97e5-5957541f2035)

A lightweight, asynchronous HTTP client for Neovim inspired by Thunder Client. 
Written in Lua, powered by **httpie**.

## ✨ Features
* **Sidebar Menu**: Manage your requests in a dedicated, non-intrusive sidebar.
* **Asynchronous**: Doesn't block your Neovim UI. Your editor stays responsive while waiting for the server.
* **Auto-Formatting**: Automatic JSON syntax highlighting for responses.
* **Integrated**: Designed to work alongside `nvim-tree` and other sidebars without layout breaking.

## 📋 Prerequisites
You need to have `httpie` installed in your system:
```bash
# Ubuntu/Debian
sudo apt install httpie

# Arch Linux
sudo pacman -S httpie
```
`jq` is also required for JSON formating:
```bash
# Ubuntu/Debian
sudo apt install jq

# Arch Linux
sudo pacman -S jq
```

## 🚀 Installation
Using lazy.nvim:
```Lua
return {
  "JD1705/AdoRest.nvim",
}
```

## Configuration
```Lua
require("adore").setup({
    -- bar_pos: position of the bar, can be right or left
    bar_pos = "left", -- default is "right"
    -- floating_border: change the border for the response floating window
    floating_border = "rounded" -- default is "single"
})
```

### Setup Parameters
| Parameter | Type | Valid Options |
| ------------- | -------------- | -------------- |
| bar_pos | string | "left" |
|  |  | "right" |
| floating_border | string | "rounded" |
|  |  | "single" |
|  |  | "none" |
|  |  | "double" |
|  |  | "solid" |


## Keymaps
- `<Tab>` to switch between the control section (url and buttons) and the data section (body, header & query)
- `h` and `l` to move between buffers in the data section
- `q` to close the windows
- `<Esc>` to unfocus the bar and `<Alt><Esc>` to focus it back

## Commands
- `:AdoRest` opens the sidebar
- `:AdoRestFocus` set the cursor on the sidebar if is open
- `:AdoRestUnfocus` set the cursor on the editor window

## 🛠 Usage

1. Open the sidebar with :AdoRest or with
2. Modify the url in the second line
3. Move to the next window with <Tab> and modify the body, header and queries
4. Move the cursor to the send line 
5. Press Enter to execute the request.
6. The response will appear in a floating window

## 🚧 Roadmap

- [ ] Response history.
