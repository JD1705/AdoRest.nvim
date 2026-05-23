local M = {}
local path = require("adore.init").config.collections_path
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local history = require("adore.history")
local entry_display = require("telescope.pickers.entry_display")
local util = require("lspconfig.util")
-- the displayer is used to give format to the options in telescope
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
            -- here we change the raw results
            entry_maker = function (entry)
                -- the regex used here captures the text, starting with the timestamp ([%d+:%d+:%d+%]) and finishing with the status code (%d+)
                local time, method, url, status= entry.request:match("^(%[%d+:%d+:%d+%])%s+(%S+)%s+(.+)%s+(%d+)$")
                -- from here on, the data is formatted to give it colors like mentioned below
                local status_hl = "TelescopeResultsVariable"
                if status:match("^2") then status_hl = "DiagnosticOk"    -- Green for 2xx
                elseif status:match("^4") then status_hl = "DiagnosticWarn" -- Yellow for 4xx
                elseif status:match("^5") then status_hl = "DiagnosticError" -- Red for 5xx
                end
                local make_display = function(ent)
                -- here the displayer format the data and give it a highlighting, ex. methods have the highlight of a function
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
        -- the previever is the one that shows the response saved in each request from the history
        previewer = previewers.new_buffer_previewer({
            title = "JSON Response",
            define_preview = function (self, entry, status)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.value.json_response)
                -- jq is necessary to format the responses, since theyre JSONs
                if vim.fn.executable("jq") then
                    vim.api.nvim_buf_call(self.state.bufnr, function()
                        vim.cmd("%!jq .")
                    end)
                end
                vim.api.nvim_set_option_value("filetype", "json", { buf = self.state.bufnr})
            end
        }),
        -- this block defines what will happen when one result is selected
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            -- print(vim.inspect(selection)) -- this will be used to test the selection, uncomment to use
            -- the actual action will display a floating window with the same logic as the one when a request is done.
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

M.apply_constants = function (text, constants)
    if not text then return "" end
    return text:gsub("{{(.-)}}", function(var)
        return constants[var:match("^%s*(.-)%s*$")] or "{{" .. var .. "}}"
    end)
end

M.extract_constant = function (file)
    local constants = {}
    
    for line in io.lines(file) do
        if line:sub(1, 1) == "@" then
            local key, value = line:match("^@%s*(.-)%s*=%s*(.-)$")
            constants[key] = value
        end
    end
    return constants
end

M.extract_data = function (pattern, file)
    local data = { method = "", url = "", headers = {}, body = ""}

    local constants = M.extract_constant(file)
    local state = "Waiting"
    for line in io.lines(file) do
        if state == "Waiting" then
            if line == pattern then
                local method, url = line:match("^([A-Z]+)%s+(.+)$")
                data.method = method
                data.url = M.apply_constants(url, constants)
                state = "Headers"
            end
        elseif state == "Headers" then
            if line == "" then
                state = "Body"
            else
                local key, value = line:match("^([^:]+):%s*(.+)$")
                value = M.apply_constants(value, constants)
                table.insert(data.headers, key .. ":" .. value)
            end
        elseif state == "Body" then
            if line:sub(1, 3) == "###" then
                break
            else
                data.body = data.body .. line
            end
        end
    end
    return data
end

M.http_picker = function (file)
    local lines = {}
    
    local re = vim.regex([[\v^(GET|POST|PUT|PATCH|DELETE)]])
    for line in io.lines(file) do
        local match = re:match_str(line)
        if match then
            table.insert(lines, line)
        end
    end
    pickers.new({}, {
        prompt_title = "collections",
        finder = finders.new_table({
            results = lines
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function (prompt_bufnr, map)
            actions.select_default:replace(function ()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                local data = M.extract_data(selection[1], file)
                print(vim.inspect(data))
                require("adore.init").execute_request(data.method, data.url, data.body, data.headers)
            end)
            return true
        end
    }):find()
end

M.collection_search = function (opts)
    opts = opts or {}
    require("telescope.builtin").find_files({
        cwd = path,
        attach_mappings = function (prompt_bufnr, map)
            actions.select_default:replace(function ()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                M.http_picker(path .. "/" .. selection[1])
            end)
            return true
        end
    })
end
return M
