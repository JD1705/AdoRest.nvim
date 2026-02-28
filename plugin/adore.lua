vim.api.nvim_create_user_command("AdoRest",
function(opts)
    local internal = require("adore")
    -- first parameter if user writes "bar"
    if opts.args == "bar" then
        internal.abrir_barra()
    --if not then show the message
    else
        internal.world_domination()
    end
end, {
    nargs = "?" -- this makes the command to accept 0 or 1
})

