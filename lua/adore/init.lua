local M = {}
M.ui = {win_ctrl_id = nil, win_data_id = nil, buf_url = nil, buf_body = nil, buf_header = nil, buf_query = nil, current_tab = "body"}

-- Function to make requests
M.execute_request = function(method, url, body)
    print("AdoRest: Launching " .. method .. " to " .. url .. "...")
    local cmd = { "http", "--ignore-stdin", "--raw", body, method, url }
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
                vim.cmd("belowright split")
                local res_win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_buf(res_win, res_buf)
                vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, clean_data)

                if vim.fn.executable("jq") == 1 and #clean_data > 0 then
                    vim.api.nvim_buf_call(res_buf, function()
                        vim.cmd("%!jq .")
                    end)
                end

                vim.api.nvim_set_option_value('filetype', 'json', { buf = res_buf })
                vim.keymap.set('n', 'q', ':close<CR>', { buffer = res_buf, silent = true })
                print("AdoRest: Success! JSON rendered.")
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
        local url = lines[2]:gsub("%s+", "") -- La URL está en la línea 2
        local method = lines[4]:match("Method: (%a+)")
        local body_lines = vim.api.nvim_buf_get_lines(M.buf_body, 1, -1, false)
        local body_str = table.concat(body_lines, "")
        if url == "" then
            print("AdoRest: Error - URL is empty!")
            return
        end
        M.execute_request(method, url, body_str)
    else
        print("AdoRest: Use Enter on Method or SEND.")
    end
end

M.set_buffers = function()
    vim.cmd("belowright split")
    M.buf_body = vim.api.nvim_create_buf(false, true)
    M.win_data_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.win_data_id, M.buf_body)
    vim.api.nvim_buf_set_lines(M.buf_body, 0, -1, false, {
        "[ BODY ]",
        "{",
        '"key":"value"',
        "}"
    })
    M.buf_header = vim.api.nvim_create_buf(false, true)
    -- vim.api.nvim_win_set_buf(M.win_data_id, M.buf_header)
    vim.api.nvim_buf_set_lines(M.buf_header, 0, -1, false, {
        "[ HEADER ]",
        "name: value"
    })
    M.buf_query = vim.api.nvim_create_buf(false, true)
    -- vim.api.nvim_win_set_buf(M.win_data_id, M.buf_header)
    vim.api.nvim_buf_set_lines(M.buf_query, 0, -1, false, {
        "[ QUERY ]",
        "name: value"
    })
end

M.open_bar = function()
    if M.win_ctrl_id and vim.api.nvim_win_is_valid(M.win_ctrl_id) then
        vim.api.nvim_win_close(M.win_ctrl_id, true)
        vim.api.nvim_win_close(M.win_data_id, true)
        M.win_ctrl_id = nil
        M.win_data_id = nil
        return
    end

    vim.cmd("vsplit")
    vim.cmd('vertical resize 50')
    vim.wo.winfixwidth = true
    M.win_ctrl_id = vim.api.nvim_get_current_win()

    M.buf_url = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(M.buf_url, 0, -1, false, {
        "  --- AdoRest ---  ",
        "http://127.0.0.1:8000/",
        "",
        "[  Method: GET  ]",
        "[  SEND  ]",
    })
    M.set_buffers()
    vim.api.nvim_set_option_value('filetype', 'json', { buf = M.buf_body })
    vim.keymap.set("n", "<Tab>", function()
        local windows = { M.win_ctrl_id, M.win_data_id }
        if vim.api.nvim_win_is_valid(M.win_ctrl_id) and vim.api.nvim_win_is_valid(M.win_data_id) then
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
    end)

    vim.keymap.set("n", "l", function()
        local buffers = { M.buf_body, M.buf_header, M.buf_query }
        if vim.api.nvim_win_is_valid(M.win_data_id) and vim.api.nvim_get_current_win() == M.win_data_id then
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
    end)
    vim.keymap.set("n", "h", function()
        local buffers = { M.buf_query, M.buf_header, M.buf_body }
        if vim.api.nvim_win_is_valid(M.win_data_id) and vim.api.nvim_get_current_win() == M.win_data_id then
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
    end)

    vim.keymap.set('n', '<CR>', handle_enter, { buffer = M.buf_url, silent = true })
    vim.keymap.set("n", "q", function()
        if vim.api.nvim_get_current_win() == M.win_ctrl_id or vim.api.nvim_get_current_win() == M.win_data_id then
            if vim.api.nvim_win_is_valid(M.win_ctrl_id) and vim.api.nvim_win_is_valid(M.win_data_id) then
                vim.api.nvim_win_close(M.win_ctrl_id, true)
                vim.api.nvim_win_close(M.win_data_id, true)
                M.win_ctrl_id = nil
                M.win_data_id = nil
            else
                vim.api.nvim_win_close(vim.api.nvim_get_current_win(), true)
            end
        end
    end, { silent = true })

    vim.api.nvim_win_set_buf(M.win_ctrl_id, M.buf_url)
    vim.api.nvim_set_current_win(M.win_ctrl_id)
end

M.world_domination = function()
    print("AdoRest: World Adomination!")
end

return M
