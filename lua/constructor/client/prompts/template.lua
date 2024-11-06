
--- @class PromptTemplate
--- @field template string
--- @field name string
--- @field description string
--- @field hook_wrappers table<string, HookWrapper>
local PromptTemplate = {}
PromptTemplate.__index = PromptTemplate

local strmanip = require('constructor.client.prompts.strmanip')
local default_hooks = require('constructor.client.prompts.hooks.init')
local Message = require('constructor.client.messages')


---@param tbl table<string,any> table should be on the next format:
---             template: string  
---                 The prompt template string
---             name: string
---                 The name of the prompt
---             description: string | nil
---                 The description of the template
---             hook_wrapper: table<string, HookWrapper> | nil
---                 Wrappers around predefined hooks
---@return PromptTemplate instance
function PromptTemplate.new(tbl)
    if tbl.template == nil then
        error('Template is required')
    end

    if tbl.name == nil then
        error('Name is required')
    end

    local instance = setmetatable({}, PromptTemplate)

    instance.template = tbl.template
    instance.name = tbl.name or ''
    instance.description = tbl.description or ''
    instance.hook_wrappers = tbl.hook_wrappers or {}
    instance.hook_wrappers._noop = function(cb) return cb end

    --#TODO error prone
    setmetatable(instance.hook_wrappers, {
        __index = function(_, _)
            return instance.hook_wrappers._noop
        end
    })

    return instance
end

---@async
---@param on_done fun(result: Message)
---@param hooks table<string, fun(cb:function, opts: table|nil)> | nil
function PromptTemplate:subs(on_done, hooks)
    hooks = hooks or {}
    local required_vars = strmanip.extract_fstring_vars(self.template)

    local result = self.template
    local semaphore = #required_vars

    local function on_done_cb()
        on_done(Message.new{
            content = result,
            role = 'user',
        })
    end

    local function callback(variable, value)
        result = strmanip.substitute_fstring_var(result, variable, value)

        semaphore = semaphore - 1
        if semaphore == 0 then
            on_done_cb()
        end
    end

    for _, var in pairs(required_vars) do
        local wrapper = self.hook_wrappers[var]

        local cb = wrapper(callback)

        if default_hooks[var] then
            default_hooks[var](cb)
        elseif hooks[var] then
            hooks[var](cb)
        else
            semaphore = semaphore - 1
        end
    end
end

return PromptTemplate
