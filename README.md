# AdoRest.nvim 🎤
### Request Workflow
[request.webm](https://github.com/user-attachments/assets/c2684e37-8b47-4bf2-8c8e-f9aeb4c666ab)

### Open AdoRest bar
[open_close.webm](https://github.com/user-attachments/assets/0d36f5d2-44ff-4013-80d0-7a8225b06030)

### Focus and Unfocus
[focus_unfocus.webm](https://github.com/user-attachments/assets/07240b67-696c-4830-ba34-72ffd3c63111)

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
  -- dependecies = { "nvim-telescope/telescope.nvim" } only needed if you want to use the history
}
```

## Configuration
```Lua
require("adore").setup({
    -- bar_pos: position of the bar, can be right or left
    bar_pos = "left", -- default is "right"
    -- floating_border: change the border for the response floating window
    floating_border = "rounded", -- default is "single"
    -- bar_width: AdoRest bar width
    bar_width = 30, -- default is 50
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
| bar_width | integer | 50 |

## Keymaps
- `<Tab>` to switch between the control section (url and buttons) and the data section (body, header & query)
- `h` and `l` to move between buffers in the data section
- `q` to close the windows
- `<Esc>` to unfocus the bar and `<Alt><Esc>` to focus it back

## Commands
- `:AdoRest` opens the sidebar
- `:AdoRestFocus` set the cursor on the sidebar if is open
- `:AdoRestUnfocus` set the cursor on the editor window
- `:AdoRestRequest` send the request (only if the AdoRest bar is open)
- `:AdoRestHistory` open a telescope window with the history of request/responses

## 🛠 Usage

1. Open the sidebar with :AdoRest or with
2. Modify the url in the second line
3. Move to the next window with <Tab> and modify the body, header and queries
4. Move the cursor to the send line 
5. Press Enter to execute the request.
6. The response will appear in a floating window

## Support
if you find this plugin useful and want to support my work, feel free to buy me a coffee!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/jd1705)
