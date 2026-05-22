local M = {}
M.ui = require("adore.ui").ui
M.iter_buffs = require("adore.ui").iter_buffs
M.focus_bar = require("adore.ui").focus_bar
M.unfocus_bar = require("adore.ui").unfocus_bar
M.set_bar_keymaps = require("adore.ui").set_bar_keymaps
M.set_buffers = require("adore.ui").set_buffers
M.config = {floating_border = "single", bar_pos = "right", bar_width = 50, collections_path = "tests/request" }
M.history = require("adore.history")


-- this open the request/response history. itll only work if telescope is installed, otherwise, a message will be displayed
M.open_history = function ()
    local has_telescope, telescope = pcall(require, "telescope")
    -- this validates if telescope is in the system
    if not has_telescope then
        vim.notify("AdoRest: Telescope is not installed", vim.log.levels.ERROR)
        return
    end
    require("adore.picker").history_s()
end

-- IMPORTANT!!: this function receive the user options. if doesnt receive anything it will use the default ones
function M.setup(user_opts)
    M.config = vim.tbl_deep_extend("force", M.config, user_opts or {})
end

-- this functions runs the principal logic for the requests
M.execute_request = function(method, url, body, headers, queries)
    print("AdoRest: Launching " .. method .. " to " .. url .. "...")
    -- cmd is the table with the data that will be send with httpie
    local cmd = { "http", "--ignore-stdin", "-v", method, url }
    -- these conditionals validate whether there is something on the body, header and query, if not they wont be append
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
    -- this will proceed to send the data in cmd
    vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        -- stdout refers to the result or response, the json is at the end of the response
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

            -- vim.schedule is used to keep neovim running while wait for the response (or else it will freeze)
            vim.schedule(function()
                -- from here the response window is assembled
                local res_buf = vim.api.nvim_create_buf(false, true)
                local json_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_open_win(json_buf, true, { relative = "editor", width = 100, height = 15, style = "minimal", border = M.config.floating_border, row = 6, col = 47 })
                local res_win = vim.api.nvim_get_current_win()
                vim.api.nvim_open_win(res_buf, true, { relative = "editor", width = 100, height = 15, style = "minimal", border = M.config.floating_border, row = 23, col = 47 })
                local json_win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_buf(json_win, json_buf)
                vim.api.nvim_win_set_buf(res_win, res_buf)
                local json = {}
                local heads = table.move(clean_data, 1, #clean_data -1, 1, {})
                table.insert(json, clean_data[#clean_data])
                vim.api.nvim_buf_set_lines(json_buf, 0, -1, false, json)
                vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, heads)
                -- print(vim.inspect(clean_data))

                -- jq is used to format the json response and give indentation
                if vim.fn.executable("jq") == 1 and #clean_data > 0 then
                    vim.api.nvim_buf_call(json_buf, function()
                        vim.cmd("%!jq . 2>/dev/null || echo 'Oops. Looks like something went wrong. You may want to check if the server is running...'")
                    end)
                end

                vim.api.nvim_set_option_value("filetype", "http", { buf = res_buf})
                vim.api.nvim_set_option_value('filetype', 'json', { buf = json_buf })
                vim.keymap.set('n', 'q', function ()
                    vim.api.nvim_win_close(res_win,true)
                    vim.api.nvim_win_close(json_win, true)
                end, { buffer = json_buf, silent = true })
                vim.keymap.set('n', 'q', function ()
                    vim.api.nvim_win_close(res_win,true)
                    vim.api.nvim_win_close(json_win, true)
                end, { buffer = res_buf, silent = true })

                -- buffer cycling for the response windows
                vim.keymap.set("n", "<Tab>", function ()
                    if vim.api.nvim_get_current_win() == res_win or vim.api.nvim_get_current_win() == json_win then
                        local windows = { res_win, json_win }
                        if vim.api.nvim_win_is_valid(res_win) and vim.api.nvim_win_is_valid(json_win) then
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
                end, { buffer = json_buf })
                vim.keymap.set("n", "<Tab>", function ()
                    if vim.api.nvim_get_current_win() == res_win or vim.api.nvim_get_current_win() == json_win then
                        local windows = { res_win, json_win }
                        if vim.api.nvim_win_is_valid(res_win) and vim.api.nvim_win_is_valid(json_win) then
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
                end, { buffer = res_buf })

                -- extraction of the status code to be displayed through a message
                for _, line in ipairs(clean_data) do
                    Status_code = line:match("HTTP/%d.%d%s(%d+)")
                    if Status_code ~= nil then
                        if string.sub(Status_code, 1, 1) == "2" then
                            print("AdoRest: Successful Response with Code " .. Status_code)
                        elseif string.sub(Status_code, 1, 1) == "3" then
                            print("AdoRest: You have been Redirected Successfully with Code " .. Status_code)
                        elseif string.sub(Status_code,1 ,1) == "4" then
                            print("AdoRest: A Client-side error ocurred with Code " .. Status_code)
                        elseif string.sub(Status_code,1,1) == "5" then
                            print("AdoRest: A Server-side error ocurred with Code " .. Status_code)
                        end
                    -- here the data is saved and stored in the history
                    local lines = vim.api.nvim_buf_get_lines(M.ui.buf_url, 0, -1, false)
                    local request_data = M.get_data(lines)
                    local timestamp = os.date("%H:%M:%S")
                    local response = { request = "[" .. timestamp .. "]" .. " " .. request_data.method .. " " .. "[" .. request_data.url .. "]" .. " " .. Status_code, json_response = json }

                    table.insert(M.history, response)
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

-- this function extract the data from each buffer and then return it ready to be used
M.get_data = function (lines)
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
    return { url = url, method = method, body = body_str, header = headers_table, query = query_table}
end

-- handle_enter manage the logic to send the request when enter is pressed over the SEND button (in the adorest bar). also, manages the cycle of methods
local function handle_enter()
    local bufnr = vim.api.nvim_get_current_buf()
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- this block verifies if the cursor is over the line 4 (where the method buttons is) and cycle between methods
    if curr_line == 4 then
        local methods = { "GET", "POST", "PUT", "DELETE" }
        local current_method = lines[4]:match("Method: (%a+)")
        local next_idx = 1
        for i, m in ipairs(methods) do
            if m == current_method then
                next_idx = (i % #methods) + 1
                break
            end
        end
        vim.api.nvim_buf_set_lines(bufnr, 3, 4, false, { "[  Method: " .. methods[next_idx] .. "  ]" })

    -- this block verifies if the cursor is over the SEND button, if it is, then it will send the request (this can also be done with :AdoRestRequest)
    elseif curr_line == 5 then
        local request = M.get_data(lines)
        if request.url == "" then
            print("AdoRest: Error - URL is empty!")
            return
        end
        M.execute_request(request.method, request.url, request.body, request.header, request.query)
    else
        print("AdoRest: Use Enter on Method or SEND.")
    end
end

-- set the buffers and windows for the bar
M.open_bar = function()
    M.ui.last_win = vim.api.nvim_get_current_win()
    if M.ui.win_ctrl_id and vim.api.nvim_win_is_valid(M.ui.win_ctrl_id) then
        vim.api.nvim_win_close(M.ui.win_ctrl_id, true)
        vim.api.nvim_win_close(M.ui.win_data_id, true)
        M.ui.win_ctrl_id = nil
        M.ui.win_data_id = nil
        return
    end
    if M.config.bar_pos == "right" then
        vim.cmd("rightbelow vsplit")
    elseif M.config.bar_pos == "left" then
        vim.cmd("vsplit")
    end
    vim.cmd('vertical resize ' .. M.config.bar_width )
    vim.wo.winfixwidth = true
    M.ui.win_ctrl_id = vim.api.nvim_get_current_win()

    if M.ui.buf_url == nil then
        M.ui.buf_url = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(M.ui.buf_url, 0, -1, false, {
            "  --- AdoRest ---  ",
            "http://127.0.0.1:8000/",
            "",
            "[  Method: GET  ]",
            "[  SEND  ]"
        })
    end
    M.set_buffers()
    vim.api.nvim_set_option_value('filetype', 'json', { buf = M.ui.buf_body })
    vim.api.nvim_set_option_value('filetype', 'vim', { buf = M.ui.buf_header })
    vim.api.nvim_set_option_value('filetype', 'vim', { buf = M.ui.buf_query })
    vim.api.nvim_set_option_value('filetype', 'vim', { buf = M.ui.buf_url })

    vim.keymap.set('n', '<CR>', handle_enter, { buffer = M.ui.buf_url, silent = true })
    M.set_bar_keymaps(M.ui.buf_url)
    vim.api.nvim_win_set_buf(M.ui.win_ctrl_id, M.ui.buf_url)
    vim.api.nvim_set_current_win(M.ui.win_ctrl_id)
end

-- IMPORTANT DONT DELETE!!! if deleted this will break the entire plugin (kidding)
M.world_domination = function()
    print("AdoRest: World Adomination!")
end

return M
