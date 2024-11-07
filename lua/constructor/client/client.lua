local Message = require('constructor.client.messages')
---
--- @class ClientSession
--- @field messages Message[]
--- @field llmclient LLMClient
--- @field context string[]
--- @field hooks table<string, Hook>
--- @field name string
--- @field history_size integer?
local ClientSession = {}
ClientSession.__index = ClientSession

local RoutineKind = require('constructor.routines.kinds')

ClientSession._kind_to_method_tbl = {
    [RoutineKind.kinds.CODE] = 'generate_code',
    [RoutineKind.kinds.TEXT] = 'generate_text',
}

--- Creates a new ClientSession instance.
--- @param llmclient LLMClient: The LLM client to associate with this session.
--- @param name string: the name of the client
--- @param opts table | nil: the opts table
--- @return ClientSession: A new ClientSession instance.
--- @error If llmclient is nil.
function ClientSession.new(llmclient, name, opts)
    if llmclient == nil then
        error("llmclient is required")
    end

    local instance = setmetatable({}, ClientSession)

    opts = opts or {}

    instance.llmclient = llmclient
    instance.messages = {}
    instance.context = {}
    instance.name = name
    instance.history_size = opts.history_size or 10

    instance.hooks = {
        context = function (cb, opts)
            cb(Message.concat(instance.context).content)
        end
    }

    return instance
end

--- @param messages Message[]
--- @param kind RoutineKinds
--- @param opts table|nil
--- @return Message
function ClientSession:generate_kind(messages, kind, opts)
    opts = opts or {}
    kind = kind or RoutineKind.kinds.CODE
    local method = ClientSession._kind_to_method_tbl[kind]

    return self[method](self, messages, opts)
end


---@param msg string | Message
function ClientSession:add_context(msg)

    if type(msg) == 'string' then
        msg = Message.new{
            content=msg,
            role='user'
        }
    end

    table.insert(self.context, msg)
end

function ClientSession:clear_context()
    self.context = {}
end

function  ClientSession:clear_history()
    self.history = {}
end

--- Creates a new message history by merging the existing messages and the new messages.
--- 
--- @param new_messages table of table containing message data
--- @return table of Message objects, the new message history
function ClientSession:new_history(new_messages)
    local history = {}

    local n = #self.messages <= self.history_size and #self.messages or self.history_size

    for i=n,1,-1 do
        table.insert(history, self.messages[#self.messages - i + 1])
    end

    for _, msg in ipairs(new_messages) do
        table.insert(history, msg)
    end

    return history
end

---@param routine_template RoutineTemplate
---@param on_done fun(result: Message)
---@async
function ClientSession:run_routine(routine_template, on_done)
    routine_template:subs(
        function (routine)
            local prompt = routine:message('user')
            local kind = routine.kind

            local generated_msg = self:generate_kind({prompt}, kind)
            on_done(generated_msg)
        end
        ,self.hooks)
end

--- @param messages Message[]
--- @param opts table|nil
--- @return Message
function ClientSession:generate_code(messages, opts)
    local message = self:generate_text(messages, opts)
    local code_list = message:extract_code_blocks()

    local code = Message.concat(code_list)

    table.insert(self.messages, code)

    return code
end

--- @param messages Message[]
--- @param opts table|nil
--- @return Message
function ClientSession:generate_text(messages, opts)
    opts = opts or {}

    local session_messages = self:new_history(messages)

    local message = self.llmclient:create_chat_completion(session_messages)

    return message
end
return ClientSession
