---@type table<string, Hook>
local Hooks = {}
local bufops = require('constructor.bufops')

---@alias HookCallback fun(variable: string, value: string)
---@alias HookWrapper fun(cb: HookCallback): HookCallback
---@alias Hook fun(cb: HookCallback, opts: table)

function Hooks.input(cb, opts)
    opts = opts or {}
    opts.prompt = opts.prompt or 'Enter your input'
    vim.ui.input({ prompt = opts.prompt }, function(input)
        cb('input', input)
    end)
end

function Hooks.bfiletype(cb, opts)
    cb('bfiletype', vim.bo.filetype)
end

function Hooks.selection(cb, opts)
    cb('selection', table.concat(bufops.get_selection(), '\n'))
end

--[[
-- HOOKS IDEAS
-- SELECTION (local hook)
--]]

return Hooks
