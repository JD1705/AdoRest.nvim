local M = {}
M.ui = {win_ctrl_id = nil, win_data_id = nil, buf_url = nil, buf_body = nil, buf_header = nil, current_tab = "body"}

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
        local body_lines = vim.api.nvim_buf_get_lines(bufnr, 7, -1, false)
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

M.open_bar = function()
        return
    end

    vim.cmd("vsplit")
    vim.cmd('vertical resize 50')
    vim.wo.winfixwidth = true

        "  --- AdoRest ---  ",
        "http://127.0.0.1:8000/",
        "",
        "[  Method: GET  ]",
        "[  SEND  ]",
    })

    vim.keymap.set("n", "q", function()
        end

end

M.world_domination = function()
    print("AdoRest: World Adomination!")
end

return M
