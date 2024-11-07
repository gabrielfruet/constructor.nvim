---@type table<string, Hook>
local Hooks = {}
local bufops = require('constructor.bufops')

---@alias HookCallback fun(value: string | nil) if the value is nil, then it will be considered an error
---@alias HookWrapper fun(cb: HookCallback): HookCallback
---@alias Hook fun(cb: HookCallback, opts: table | nil)

---@async
---@param cb HookCallback
function Hooks.input(cb, opts)
    opts = opts or {}
    opts.prompt = opts.prompt or 'Enter your input'
    vim.ui.input({ prompt = opts.prompt }, function(input)
        cb(input)
    end)
end

---@param cb HookCallback
function Hooks.bfiletype(cb, opts)
    cb(vim.bo.filetype)
end

---@param cb HookCallback
function Hooks.selection(cb, opts)
    cb(table.concat(bufops.get_selection(), '\n'))
end

--[[
-- HOOKS IDEAS
-- SELECTION (local hook)
--]]

return Hooks
