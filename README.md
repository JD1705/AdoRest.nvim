# AdoRest.nvim 🎤

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

## Keymaps
- `<leader>ar` to open the lateral bar
- `<Tab>` to switch between the control section (url and buttons) and the data section (body, header & query)
- `h` and `l` to move between buffers in the data section
- `q` to close the windows

## 🛠 Usage

1. Open the sidebar with :AdoRest or with <leader>ar
2. Modify the url in the second line
3. Move to the next window with <Tab> and modify the body, header and queries
4. Move the cursor to the send line 
5. Press Enter to execute the request.
6. The result will appear in a horizontal split below.

## 🚧 Roadmap

- [ ] Response history.
