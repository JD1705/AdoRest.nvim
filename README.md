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

## 🚀 Installation
Using lazy.nvim:
```Lua
{
  "tu-usuario/adore.nvim",
  dependencies = { "rcarriga/nvim-notify" }, -- Optional, for pretty notifications
  config = function()
    -- Keybinding to toggle the AdoRest sidebar
    vim.keymap.set('n', '<leader>ar', ':AdoRest<CR>', { silent = true })
  end
}
```

## 🛠 Usage

1. Open the sidebar with :AdoRest (or your custom shortcut).
2. Move the cursor to a request line (e.g., > GET).
3. Press Enter to execute the request.
4. The result will appear in a horizontal split below.

## 🚧 Roadmap

- [ ] Support for dynamic URLs in the sidebar.

- [ ] POST request body support.

- [ ] Header customization.

- [ ] Response history.
