local M = {}
local win_id = nil

M.world_domination = function()
    print("AdoRest: WORLD ADOMINATION!")
end

M.open_bar = function()
    -- if the window already exist and is valid, we close it
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
        win_id = nil
        return
    end

    vim.cmd("vsplit")
    vim.cmd('vertical resize 50')
    vim.wo.winfixwidth = true
    win_id = vim.api.nvim_get_current_win()

    local buf =
    vim.api.nvim_create_buf(false, true)
    -- Map enter only for this buffer
    vim.keymap.set('n', '<CR>', function()
      -- Get the current line (cursor return {line, column})
      local line = vim.api.nvim_win_get_cursor(0)[1]
      local content = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]

      if content:match("GET") then
          local url = "http://127.0.0.1:8000/"
          print("AdoRest: Launching GET request...")
          vim.fn.jobstart({ "http", "--ignore-stdin", "GET", url }, {
              stdout_buffered = true,
              on_stdout = function(_, data)
                    local res_buf = vim.api.nvim_create_buf(false, true)
                    -- Open a split at the bottom of the bar
                    vim.cmd("belowright split")
                    local res_win = vim.api.nvim_get_current_win()
                    vim.api.nvim_win_set_buf(res_win, res_buf)
                    -- Put the JSON in the buffer
                    vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, data)
                    -- Set the format
                    vim.api.nvim_set_option_value('filetype', 'json', { buf = res_buf })
                    vim.keymap.set('n', 'q', ':close<CR>', { buffer = res_buf, silent = true })
                    print("AdoRest: ¡Success! Received " .. #data .. " fragments of JSON.")
              end,
              on_stderr = function(_, data)
                if data and data[1] ~= "" then
                  print("Error from AdoRest: " .. table.concat(data, " "))
              end
                end,
                on_exit = function(_, code)
                if code ~= 0 then
                    print("AdoRest: the process died with the code " .. code .. ". do you have httpie installed?")
                end
              end,
            })
      elseif content:match("POST") then
        print("AdoRest: Preparing POST request...")
      else
        print("AdoRest: Here is nothing to press")
      end
    end, { buffer = buf, silent = true })

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
