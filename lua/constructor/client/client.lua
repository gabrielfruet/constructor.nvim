local Message = require('constructor.client.messages')
local waitwin = require('constructor.waitwin')
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
--- @param opts table|nil
--- @param on_stream fun(msg: Message)
--- @param on_done fun(success: boolean)
function ClientSession:generate(messages, opts, on_stream, on_done)
    opts = opts or {}
    local session_messages = self:new_history(messages, {previous=false})

    local cancel = waitwin.create_wait_window()
    self.llmclient:create_chat_completion(session_messages, {},
        function (msg)
            on_stream(msg)
        end,
        function (success)
            cancel()
            on_done(success)
        end)

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
function ClientSession:new_history(new_messages, opts)
    local history = {}
    local previous = opts.previous or false

    local n = #self.messages <= self.history_size and #self.messages or self.history_size

    if previous then
        for i=n,1,-1 do
            table.insert(history, self.messages[#self.messages - i + 1])
        end
    end

    for _, msg in ipairs(new_messages) do
        table.insert(history, msg)
    end

    return history
end

---@param routine_template RoutineTemplate
---@param on_done fun(result: Message | nil)
---@async
function ClientSession:run_routine(routine_template, on_done)
    if routine_template == nil then return end

    routine_template:subs(
        function (routine)
            local kind = routine.kind
            local on_stream_routine, on_done_routine = routine.output(kind)

            if routine == nil then
                return
            end
            local prompt = routine:message('user')
            local function on_stream_subs(generated_msg)
                table.insert(self.messages, prompt)
                table.insert(self.messages, generated_msg)

                on_stream_routine(generated_msg)
            end

            local function on_done_subs(success)
                on_done_routine(success)
                on_done(success)
            end

            self:generate({prompt}, {}, on_stream_subs, on_done_subs)

        end
        ,self.hooks)
end

return ClientSession
