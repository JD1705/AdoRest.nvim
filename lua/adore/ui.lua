local M = {}

-- principal container for ui management variables
M.ui = { win_ctrl_id = nil, win_data_id = nil, buf_url = nil, buf_body = nil, buf_header = nil, buf_query = nil, last_win = nil, current_tab = "body" }

-- necessary to cycle through buffers. can receive multiple parameters
M.iter_buffs = function (...)
    local buffers = {...}
    if M.ui.win_data_id ~= nil and vim.api.nvim_get_current_win() == M.ui.win_data_id then
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
end

-- used to unfocus the adorest bar and focus the editor window
M.unfocus_bar = function ()
    if vim.api.nvim_get_current_win() == M.ui.win_ctrl_id or vim.api.nvim_get_current_win() == M.ui.win_data_id then
        vim.api.nvim_set_current_win(M.ui.last_win)
    end
end

-- moves back from the editor window towards the bar (only if its open)
M.focus_bar = function()
    if vim.api.nvim_get_current_win() == M.ui.last_win and M.ui.win_ctrl_id ~= nil then
        vim.api.nvim_set_current_win(M.ui.win_ctrl_id)
    end
end

-- set keymaps to their respective buffer once the bar is open. needed to move through the bar windows and buffers
M.set_bar_keymaps = function(buf)
    -- set "tab" as the keymap to move between the adorest bar windows
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
    -- set "esc" as the keymap to unfocus the bar
    vim.keymap.set("n", "<Esc>", function ()
        M.unfocus_bar()
    end, { buffer = buf, noremap = true, silent = true })
    -- set "alt+esc" as the keymap to focus the bar
    vim.keymap.set("n", "<A-Esc>", function ()
        M.focus_bar()
    end, { noremap = true, silent = true })
    -- set "l" as the default key to cycle next data buffers
    vim.keymap.set("n", "l", function()
        M.iter_buffs(M.ui.buf_body, M.ui.buf_header, M.ui.buf_query)
    end, { buffer = buf, silent = true })
    -- set "h" as the default key to cycle previous data buffers
    vim.keymap.set("n", "h", function ()
        M.iter_buffs(M.ui.buf_query, M.ui.buf_header, M.ui.buf_body)
    end, { buffer = buf, silent = true})
    -- set "q" as the default key to close the adorest bar
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

-- create the buffers for the data window and define the buffers content
M.set_buffers = function()
    vim.cmd("belowright split")
    M.ui.win_data_id = vim.api.nvim_get_current_win()
    if M.ui.buf_body == nil then
        M.ui.buf_body = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(M.ui.buf_body, 0, -1, false, {
            "[ BODY ]",
            ""
        })
    end
    M.set_bar_keymaps(M.ui.buf_body)
    vim.api.nvim_win_set_buf(M.ui.win_data_id, M.ui.buf_body)
    local vt_ns = vim.api.nvim_create_namespace("adore_namespace")
    -- this set and use virtual text (extmark) as a guide for the user
    vim.api.nvim_buf_set_extmark(M.ui.buf_body, vt_ns, 1, 0, { virt_lines = {{{ "{" , "Comment" }}, {{ "  'key': 'value'", "Comment" }}, {{ "}", "Comment" }} }, virt_text_pos = "inline", hl_mode = "combine"})
    -- this autocmd is used to clean the virtual text once the user starts to type so it doesnt get in the middle
    vim.api.nvim_create_autocmd("InsertEnter", {
        buffer = M.ui.buf_body,
        callback = function ()
            vim.api.nvim_buf_clear_namespace(M.ui.buf_body, vt_ns, 0, -1)
        end
    })
    if M.ui.buf_header == nil then
        M.ui.buf_header = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(M.ui.buf_header, 0, -1, false, {
            "[ HEADER ]",
            ""
        })
    end
    M.set_bar_keymaps(M.ui.buf_header)
    vim.api.nvim_buf_set_extmark(M.ui.buf_header, vt_ns, 1, 0, { virt_text = {{ "name: value", "Comment"}}, virt_text_pos = "inline", hl_mode = "combine"})
    vim.api.nvim_create_autocmd("InsertEnter", {
        buffer = M.ui.buf_header,
        callback = function ()
            vim.api.nvim_buf_clear_namespace(M.ui.buf_header, vt_ns, 0, -1)
        end
    })
    if M.ui.buf_query == nil then
        M.ui.buf_query = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(M.ui.buf_query, 0, -1, false, {
            "[ QUERY ]",
            ""
        })
    end
    M.set_bar_keymaps(M.ui.buf_query)
    vim.api.nvim_buf_set_extmark(M.ui.buf_query, vt_ns, 1, 0, { virt_text = {{ "name: value", "Comment"}}, virt_text_pos = "inline", hl_mode = "combine"})
    vim.api.nvim_create_autocmd("InsertEnter", {
        buffer = M.ui.buf_query,
        callback = function ()
            vim.api.nvim_buf_clear_namespace(M.ui.buf_query, vt_ns, 0, -1)
        end
    })
end

return M
