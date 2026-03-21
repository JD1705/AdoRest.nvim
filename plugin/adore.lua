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
