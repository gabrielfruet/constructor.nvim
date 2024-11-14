--- @class Routine
--- @field prompt string
--- @field name string
--- @field description string
--- @field hook_wrappers table<string, HookWrapper>
--- @field kind RoutineMessageKind
--- @field output RoutineOutput
local Routine = {}
Routine.__index = Routine

local RoutineMessageKinds = require('constructor.routines.kinds')
local RoutineOutputs = require('constructor.routines.output')
local Messages = require('constructor.client.messages')

---@param tbl table<string,any> table should be on the next format:
---             prompt: string  
---                 The resulting prompt of a prompt template
---             name: string
---                 The name of the prompt
---             description: string | nil
---                 The description of the template
---             hook_wrapper: table<string, HookWrapper> | nil
---                 Wrappers around predefined hooks
---             kind: RountineKind
---                 Define the kind of output expected for the routine
---@return Routine instance
function Routine.new(tbl)
    if tbl.prompt == nil then
        error('Prompt is required')
    end

    if tbl.name == nil then
        error('Name is required')
    end

    local instance = setmetatable({}, Routine)

    instance.prompt = tbl.prompt
    instance.name = tbl.name or ''
    instance.description = tbl.description or ''
    instance.hook_wrappers = tbl.hook_wrappers or {}
    instance.hook_wrappers._noop = function(cb) return cb end
    instance.kind = tbl.kind or RoutineMessageKinds.code
    instance.output = tbl.output or RoutineOutputs.append_text

    --#TODO error prone
    setmetatable(instance.hook_wrappers, {
        __index = function(_, _)
            return instance.hook_wrappers._noop
        end
    })

    return instance
end

---@param role string
---@return Message prompt
function Routine:message(role)
    role = role or 'user'
    return Messages.new{
        content=self.prompt,
        role=role
    }
end

return Routine
