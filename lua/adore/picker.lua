local M = {}
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local history = require("adore.history")
local entry_display = require("telescope.pickers.entry_display")
local displayer = entry_display.create({
separator = " ",
items = {
        { width = 10 }, -- Timestamp: [HH:MM:SS]
        { width = 3 },  -- Method: GET, POST
        { remaining = true }, -- URL
        { width = 4 },  -- Status: 200, 404
    },
})

M.history_s = function (opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "history",
        finder = finders.new_table({
            results = history,
            entry_maker = function (entry)
                local time, method, url, status= entry.request:match("^(%[%d+:%d+:%d+%])%s+(%S+)%s+(.+)%s+(%d+)$")
                local status_hl = "TelescopeResultsVariable"
                if status:match("^2") then status_hl = "DiagnosticOk"    -- Green for 2xx
                elseif status:match("^4") then status_hl = "DiagnosticWarn" -- Yellow for 4xx
                elseif status:match("^5") then status_hl = "DiagnosticError" -- Red for 5xx
                end
                local make_display = function(ent)
                return displayer {
                { time, "Comment" },
                { method, "Function" },
                {url, "Keyword"},
                { status, status_hl},
                }
            end
                return {
                    value = entry,
                    display = make_display,
                    ordinal = entry.request
                }
            end
        }),
        sorter = conf.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer({
            title = "JSON Response",
            define_preview = function (self, entry, status)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.value.json_response)
                if vim.fn.executable("jq") then
                    vim.api.nvim_buf_call(self.state.bufnr, function()
                        vim.cmd("%!jq .")
                    end)
                end
                vim.api.nvim_set_option_value("filetype", "json", { buf = self.state.bufnr})
            end
        }),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            -- print(vim.inspect(selection))
            local res_buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_open_win(res_buf, true, { relative = "editor", width = 100, height = 25, style = "minimal", border = "rounded", row = vim.o.lines/5, col = vim.o.columns/4})
            local res_win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_buf(res_win, res_buf)
            local full_data = selection.value
            vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, full_data.json_response)
            if vim.fn.executable("jq") then
                vim.api.nvim_buf_call(res_buf, function()
                    vim.cmd("%!jq .")
                end)
            end
            vim.api.nvim_set_option_value('filetype', 'json', { buf = res_buf })
            vim.keymap.set('n', 'q', ':close<CR>', { buffer = res_buf, silent = true })
          end)
          return true
    end,
    }):find()
end

return M
