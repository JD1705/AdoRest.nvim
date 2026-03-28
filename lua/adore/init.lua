local M = {}
M.ui = {win_ctrl_id = nil, win_data_id = nil, buf_url = nil, buf_body = nil, buf_header = nil, buf_query = nil, last_win = nil, current_tab = "body"}

M.unfocus_bar = function ()
    if vim.api.nvim_get_current_win() == M.ui.win_ctrl_id or vim.api.nvim_get_current_win() == M.ui.win_data_id then
        vim.api.nvim_set_current_win(M.ui.last_win)
    end
end
M.focus_bar = function()
    if vim.api.nvim_get_current_win() == M.ui.last_win and M.ui.win_ctrl_id ~= nil then
        vim.api.nvim_set_current_win(M.ui.win_ctrl_id)
    end
end



local function set_bar_keymaps(buf)
    vim.keymap.set("n", "<Tab>", function()
        if vim.api.nvim_get_current_win() == M.ui.win_ctrl_id or vim.api.nvim_get_current_win() == M.ui.win_data_id then
            local windows = { M.ui.win_ctrl_id, M.ui.win_data_id }
            if vim.api.nvim_win_is_valid(M.ui.win_ctrl_id) and vim.api.nvim_win_is_valid(M.ui.win_data_id) then
                local current_window = vim.api.nvim_get_current_win()
                local next_idx = 1
                for i, m in ipairs(windows) do
                    if m == current_window then
                        next_idx = (i % #windows) + 1
                        break
                    end
                end
                vim.api.nvim_set_current_win(windows[next_idx])
            end
        end
    end, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "<Esc>", function ()
        M.unfocus_bar()
    end, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "<A-Esc>", function ()
        M.focus_bar()
    end, { noremap = true, silent = true })
    vim.keymap.set("n", "l", function()
        local buffers = { M.ui.buf_body, M.ui.buf_header, M.ui.buf_query }
        if vim.api.nvim_win_is_valid(M.ui.win_data_id) and vim.api.nvim_get_current_win() == M.ui.win_data_id then
            local current_buf = vim.api.nvim_get_current_buf()
            local next_idx = 1
            for i, m in ipairs(buffers) do
                if m == current_buf then
                    next_idx = (i % #buffers) + 1
                    break
                end
            end
            vim.api.nvim_set_current_buf(buffers[next_idx])
        end
    end, { buffer = buf, silent = true })
    vim.keymap.set("n", "h", function()
        local buffers = { M.ui.buf_query, M.ui.buf_header, M.ui.buf_body }
        if vim.api.nvim_win_is_valid(M.ui.win_data_id) and vim.api.nvim_get_current_win() == M.ui.win_data_id then
            local current_buf = vim.api.nvim_get_current_buf()
            local next_idx = 1
            for i, m in ipairs(buffers) do
                if m == current_buf then
                    next_idx = (i % #buffers) + 1
                    break
                end
            end
            vim.api.nvim_set_current_buf(buffers[next_idx])
        end
    end, { buffer = buf, silent = true})
    vim.keymap.set("n", "q", function()
        if vim.api.nvim_get_current_win() == M.ui.win_ctrl_id or vim.api.nvim_get_current_win() == M.ui.win_data_id then
            if vim.api.nvim_win_is_valid(M.ui.win_ctrl_id) and vim.api.nvim_win_is_valid(M.ui.win_data_id) then
                vim.api.nvim_win_close(M.ui.win_ctrl_id, true)
                vim.api.nvim_win_close(M.ui.win_data_id, true)
                M.ui.win_ctrl_id = nil
                M.ui.win_data_id = nil
            else
                vim.api.nvim_win_close(vim.api.nvim_get_current_win(), true)
            end
        end
    end, { buffer = buf, silent = true })
end

-- Function to make requests
M.execute_request = function(method, url, body, headers, queries)
    print("AdoRest: Launching " .. method .. " to " .. url .. "...")
    local cmd = { "http", "--ignore-stdin", "-v", method, url }
    if body ~= "" then
        cmd = { "http", "--ignore-stdin", "-v", "--raw", body, method, url }
    end
    if headers ~= "" then
        for _, h in ipairs(headers) do
            table.insert(cmd, h)
        end
    end
    if queries ~= "" then
        for _, q in ipairs(queries) do
            table.insert(cmd, q)
        end
    end
    vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            local clean_data = {}
            if data then
                for _, line in ipairs(data) do
                    if line ~= "" and line:gsub("%s+", "") ~= "" then
                        table.insert(clean_data, line)
                    end
                end
            end

            if #clean_data == 0 then
                print("AdoRest: Didn't receive any data.")
                return
            end

            vim.schedule(function()
                local res_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_open_win(res_buf, true, { relative = "editor", width = 100, height = 25, style = "minimal", border = "single", row = vim.o.lines/5, col = vim.o.columns/4})
                local res_win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_buf(res_win, res_buf)
                local json = {}
                table.insert(json, clean_data[#clean_data])
                vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, json)

                if vim.fn.executable("jq") == 1 and #clean_data > 0 then
                    vim.api.nvim_buf_call(res_buf, function()
                        vim.cmd("%!jq .")
                    end)
                end

                vim.api.nvim_set_option_value('filetype', 'json', { buf = res_buf })
                vim.keymap.set('n', 'q', ':close<CR>', { buffer = res_buf, silent = true })
                for _, line in ipairs(clean_data) do
                    local status_code = line:match("HTTP/%d.%d%s(%d+)")
                    if status_code ~= nil then
                        if string.sub(status_code, 1, 1) == "2" then
                            print("AdoRest: Successful Response with Code " .. status_code)
                        elseif string.sub(status_code, 1, 1) == "3" then
                            print("AdoRest: You have been Redirected Successfully with Code " .. status_code)
                        elseif string.sub(status_code,1 ,1) == "4" then
                            print("AdoRest: A Client-side error ocurred with Code " .. status_code)
                        elseif string.sub(status_code,1,1) == "5" then
                            print("AdoRest: A Server-side error ocurred with Code " .. status_code)
                        end
                    end
                end
            end)
        end,
        on_stderr = function(_, data)
            if data and data[1] ~= "" then
                print("Error from AdoRest: " .. table.concat(data, " "))
            end
        end,
    })
end

local function handle_enter()
    local bufnr = vim.api.nvim_get_current_buf()
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    if curr_line == 4 then
        local metodos = { "GET", "POST", "PUT", "DELETE" }
        local current_method = lines[4]:match("Method: (%a+)")
        local next_idx = 1
        for i, m in ipairs(metodos) do
            if m == current_method then
                next_idx = (i % #metodos) + 1
                break
            end
        end
        vim.api.nvim_buf_set_lines(bufnr, 3, 4, false, { "[  Method: " .. metodos[next_idx] .. "  ]" })

    elseif curr_line == 5 then
        local url = lines[2]:gsub("%s+", "")
        local method = lines[4]:match("Method: (%a+)")
        local body_lines = vim.api.nvim_buf_get_lines(M.ui.buf_body, 1, -1, false)
        local body_str = table.concat(body_lines, "")
        local headers_table = {}
        local header_lines = vim.api.nvim_buf_get_lines(M.ui.buf_header, 1, -1, false)
        for _, line in ipairs(header_lines) do
            if line ~= "" then
                local key, value = line:match("([^:]+):%s*(.*)")
                table.insert(headers_table, key .. ": " .. value)
            end
        end
        local query_table = {}
        local query_lines = vim.api.nvim_buf_get_lines(M.ui.buf_query, 1, -1, false)
        for _, line in ipairs(query_lines) do
            if line ~= "" then
                local key, value = line:match("([^:]+):%s*(.*)")
                table.insert(query_table, key .. "==" .. value)
            end
        end
        if url == "" then
            print("AdoRest: Error - URL is empty!")
            return
        end
        M.execute_request(method, url, body_str, headers_table, query_table)
    else
        print("AdoRest: Use Enter on Method or SEND.")
    end
end

M.set_buffers = function()
    vim.cmd("belowright split")
    M.ui.buf_body = vim.api.nvim_create_buf(false, true)
    M.ui.win_data_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.ui.win_data_id, M.ui.buf_body)
    set_bar_keymaps(M.ui.buf_body)
    vim.api.nvim_buf_set_lines(M.ui.buf_body, 0, -1, false, {
        "[ BODY ]",
        ""
    })
    local vt_ns = vim.api.nvim_create_namespace("adore_namespace")
    M.ui.buf_header = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_extmark(M.ui.buf_body, vt_ns, 1, 0, { virt_lines = {{{ "{" , "Comment" }}, {{ "  'key': 'value'", "Comment" }}, {{ "}", "Comment" }} }, virt_text_pos = "inline", hl_mode = "combine"})
    vim.api.nvim_create_autocmd("InsertEnter", {
        buffer = M.ui.buf_body,
        callback = function ()
            vim.api.nvim_buf_clear_namespace(M.ui.buf_body, vt_ns, 0, -1)
        end
    })
    set_bar_keymaps(M.ui.buf_header)
    vim.api.nvim_buf_set_lines(M.ui.buf_header, 0, -1, false, {
        "[ HEADER ]",
        ""
    })
    vim.api.nvim_buf_set_extmark(M.ui.buf_header, vt_ns, 1, 0, { virt_text = {{ "name: value", "Comment"}}, virt_text_pos = "inline", hl_mode = "combine"})
    vim.api.nvim_create_autocmd("InsertEnter", {
        buffer = M.ui.buf_header,
        callback = function ()
            vim.api.nvim_buf_clear_namespace(M.ui.buf_header, vt_ns, 0, -1)
        end
    })
    M.ui.buf_query = vim.api.nvim_create_buf(false, true)
    set_bar_keymaps(M.ui.buf_query)
    vim.api.nvim_buf_set_lines(M.ui.buf_query, 0, -1, false, {
        "[ QUERY ]",
        ""
    })
    vim.api.nvim_buf_set_extmark(M.ui.buf_query, vt_ns, 1, 0, { virt_text = {{ "name: value", "Comment"}}, virt_text_pos = "inline", hl_mode = "combine"})
    vim.api.nvim_create_autocmd("InsertEnter", {
        buffer = M.ui.buf_query,
        callback = function ()
            vim.api.nvim_buf_clear_namespace(M.ui.buf_query, vt_ns, 0, -1)
        end
    })
end

M.open_bar = function()
    M.ui.last_win = vim.api.nvim_get_current_win()
    if M.ui.win_ctrl_id and vim.api.nvim_win_is_valid(M.ui.win_ctrl_id) then
        vim.api.nvim_win_close(M.ui.win_ctrl_id, true)
        vim.api.nvim_win_close(M.ui.win_data_id, true)
        M.ui.win_ctrl_id = nil
        M.ui.win_data_id = nil
        return
    end

    vim.cmd("vsplit")
    vim.cmd('vertical resize 50')
    vim.wo.winfixwidth = true
    M.ui.win_ctrl_id = vim.api.nvim_get_current_win()

    M.ui.buf_url = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(M.ui.buf_url, 0, -1, false, {
        "  --- AdoRest ---  ",
        "http://127.0.0.1:8000/",
        "",
        "[  Method: GET  ]",
        "[  SEND  ]"
    })
    M.set_buffers()
    vim.api.nvim_set_option_value('filetype', 'json', { buf = M.ui.buf_body })
    vim.api.nvim_set_option_value('filetype', 'vim', { buf = M.ui.buf_header })
    vim.api.nvim_set_option_value('filetype', 'vim', { buf = M.ui.buf_query })
    vim.api.nvim_set_option_value('filetype', 'vim', { buf = M.ui.buf_url })

    vim.keymap.set('n', '<CR>', handle_enter, { buffer = M.ui.buf_url, silent = true })
    set_bar_keymaps(M.ui.buf_url)
    vim.api.nvim_win_set_buf(M.ui.win_ctrl_id, M.ui.buf_url)
    vim.api.nvim_set_current_win(M.ui.win_ctrl_id)
end

M.world_domination = function()
    print("AdoRest: World Adomination!")
end

return M
