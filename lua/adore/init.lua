local M = {}
local win_id = nil

M.world_domination = function()
    print("AdoRest: WORLD ADOMINATION!")
end

M.abrir_barra = function()
    -- if the window already exist and is valid, we close it
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
        win_id = nil
        return
    end

    vim.cmd("vsplit")
    vim.cmd('vertical resize 30')
    win_id = vim.api.nvim_get_current_win()

    local buf =
    vim.api.nvim_create_buf(false, true)
    vim.keymap.set("n", "q", function()
        if vim.api.nvim_win_is_valid(win_id) then
            vim.api.nvim_win_close(win_id, true)
            win_id = nil
        end
    end, { buffer = buf, silent = true })
    -- buffer thats not a file
    vim.api.nvim_win_set_buf(win_id, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "  --- AdoRest ---  ", "", "  [ ] GET", "  [ ] POST" })
end

return M
