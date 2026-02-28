local M = {}

M.world_domination = function()
    print("AdoRest: WORLD ADOMINATION!")
end

M.abrir_barra = function()
    vim.cmd("vsplit")
    vim.cmd('vertical resize 30')
    local buf =
    vim.api.nvim_create_buf(false, true)
    -- buffer thats not a file
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "  --- AdoRest ---  ", "", "  [ ] GET", "  [ ] POST" })
end

return M
