local Hooks = {}

---@alias HookCallback fun(variable: string, value: string)

---@param cb HookCallback
---@param opts table
function Hooks.input(cb, opts)
    opts = opts or {}
    opts.prompt = opts.prompt or 'Enter your input'
    vim.ui.input({ prompt = opts.prompt }, function(input)
        cb('input', input)
    end)
end

---@param cb HookCallback
---@param opts table
function Hooks.bfiletype(cb, opts)
    cb('bfiletype', vim.bo.filetype)
end

--[[
-- HOOKS IDEAS
-- SELECTION (local hook)
--]]

return Hooks
