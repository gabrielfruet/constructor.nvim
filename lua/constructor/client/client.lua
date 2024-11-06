local Message = require('constructor.client.messages')
---
--- @class ClientSession
--- @field messages Message[]
--- @field llmclient LLMClient
--- @field context string[]
--- @field hooks table<string, Hook>
local ClientSession = {}
ClientSession.__index = ClientSession

--- Creates a new ClientSession instance.
--- @param llmclient LLMClient: The LLM client to associate with this session.
--- @return ClientSession: A new ClientSession instance.
--- @error If llmclient is nil.
function ClientSession.new(llmclient)
    if llmclient == nil then
        error("llmclient is required")
    end
    local instance = setmetatable({}, ClientSession)

    instance.llmclient = llmclient
    instance.messages = {}
    instance.context = {}

    instance.hooks = {
        context = function (cb, opts)
            cb(Message.concat(instance.context).content)
        end
    }

    return instance
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

--- Creates a new message history by merging the existing messages and the new messages.
--- 
--- @param new_messages table of table containing message data
--- @return table of Message objects, the new message history
function ClientSession:new_history(new_messages)
    local history = {}

    for _, msg_container in ipairs({self.messages, new_messages}) do
        for _, msg in ipairs(msg_container) do
            table.insert(history, Message.new(msg))
        end
    end

    return history
end

---@param prompt PromptTemplate
---@param on_done fun(result: Message)
---@async
function ClientSession:run_prompt(prompt, on_done)
    prompt:subs(function(result)
        local message = ClientSession:generate_code(result)
        on_done(message)
    end, self.hooks)
end

--- @param messages Message[]
--- @param opts table|nil
--- @return Message
function ClientSession:generate_code(messages, opts)
    opts = opts or {}

    local session_messages = self:new_history(messages)

    local message = self.llmclient:create_chat_completion(session_messages)
    local code_list = message:extract_code_blocks()

    local code = Message.concat(code_list)

    table.insert(self.messages, code)

    return code
end

return ClientSession
