vim.api.nvim_create_user_command("AdoRest", function()
    require('adore').open_bar()
end, { desc = "Open AdoRest client"})

vim.api.nvim_create_user_command("AdoRestFocus", function ()
    require('adore').focus_bar()
end, { desc = "Focus the cursor on the Client"})

vim.api.nvim_create_user_command("AdoRestUnFocus", function ()
    require('adore').unfocus_bar()
end, { desc = "Unfocus the cursor from the client and focus on the editor window"})

vim.api.nvim_create_user_command("AdoRestMessage", function ()
    require('adore').world_domination()
end, { desc = "Print a message"})

vim.api.nvim_create_user_command("AdoRestRequest", function ()
    local adorest = require("adore")
    local lines = vim.api.nvim_buf_get_lines(adorest.ui.buf_url, 0, -1, false)
    local request = adorest.get_data(lines)
    if request.url == "" then
        print("AdoRest: Error - URL is empty!")
        return
    end
    adorest.execute_request(request.method, request.url, request.body, request.header, request.query)
end, { desc = "Send a request if the bar is open"})
