--- @class RoutineTemplate
--- @field template string
--- @field name string
--- @field description string
--- @field hook_wrappers table<string, HookWrapper>
--- @field kind RoutineMessageKinds
--- @field output RoutineOutput
local RoutineTemplate = {}
RoutineTemplate.__index = RoutineTemplate

local strmanip = require('constructor.routines.strmanip')
local default_hooks = require('constructor.routines.hooks.init')
local Message = require('constructor.client.messages')
local RoutineOutputs = require('constructor.routines.output')
local RoutineMessageKind = require('constructor.routines.kinds')
local Routine = require('constructor.routines.routine')


---@param tbl table<string,any> table should be on the next format:
---             template: string  
---                 The prompt template string
---             name: string
---                 The name of the prompt
---             description: string | nil
---                 The description of the template
---             hook_wrapper: table<string, HookWrapper> | nil
---                 Wrappers around predefined hooks
---             kind: RountineKind
---                 Define the kind of output expected for the routine
---@return RoutineTemplate instance
function RoutineTemplate.new(tbl)
    if tbl.template == nil then
        error('Template is required')
    end

    if tbl.name == nil then
        error('Name is required')
    end

    local instance = setmetatable({}, RoutineTemplate)

    instance.template = tbl.template
    instance.name = tbl.name or ''
    instance.description = tbl.description or ''
    instance.hook_wrappers = tbl.hook_wrappers or {}
    instance.hook_wrappers._noop = function(cb) return cb end
    instance.kind = tbl.kind or RoutineMessageKind.code
    local output
    if type(tbl.output) == 'string' then
        output = RoutineOutputs[tbl.output]
    else
        output = tbl.output
    end
    instance.output = output or RoutineOutputs.append_text

    setmetatable(instance.hook_wrappers, {
        __index = function(_, _)
            return instance.hook_wrappers._noop
        end
    })

    return instance
end

---@return table
local function tbl_shallow_copy(tbl, except)
    local copy = {}
    local dont_copy = {}

    for _,v in pairs(except) do
        dont_copy[v] = true
    end

    for k,v in pairs(tbl) do
        if dont_copy[k] then goto continue end

        copy[k] = v
        ::continue::
    end

    return copy
end

---@async
---@param on_done fun(result: Routine)
---@param hooks table<string, fun(cb:function, opts: table|nil)> | nil
function RoutineTemplate:subs(on_done, hooks)
    hooks = hooks or {}
    local required_vars = strmanip.extract_fstring_vars(self.template)

    local prompt = self.template
    local semaphore = #required_vars

    local function on_done_cb()
        local routine = tbl_shallow_copy(self, {'template'})
        routine.prompt = prompt

        on_done(Routine.new(routine))
    end

    ---@param variable string
    ---@return HookCallback
    local function callback_on_variable(variable)
        ---@param value string | nil if the value is nil, it will be considered an error
        return function (value)
            if value == nil then return end

            prompt = strmanip.substitute_fstring_var(prompt, variable, value)

            semaphore = semaphore - 1
            if semaphore == 0 then
                on_done_cb()
            end
        end
    end

    for _, var in pairs(required_vars) do
        local wrapper = self.hook_wrappers[var]

        local cb = wrapper(callback_on_variable(var))

        if default_hooks[var] then
            default_hooks[var](cb)
        elseif hooks[var] then
            hooks[var](cb)
        else
            semaphore = semaphore - 1
        end
    end
end

return RoutineTemplate
