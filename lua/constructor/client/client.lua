local Message = require('constructor.client.messages')
---
--- @class ClientSession
--- @field messages Message[]
--- @field llmclient LLMClient
local ClientSession = {}
ClientSession.__index = ClientSession

--- Creates a new ClientSession instance.
--- @param llmclient LLMClient: The LLM client to associate with this session.
--- @return ClientSession: A new ClientSession instance.
--- @error If llmclient is nil.
function ClientSession:new(llmclient)
    if llmclient == nil then
        error("llmclient is required")
    end
    local instance = setmetatable({}, ClientSession)

    instance.llmclient = llmclient
    instance.messages = {}

    return instance
end

--- Creates a new message history by merging the existing messages and the new messages.
--- 
--- @param new_messages table of table containing message data
--- @return table of Message objects, the new message history
function ClientSession:new_history(new_messages)
    local history = {}

    for _, msg_container in ipairs({self.messages, new_messages}) do
        for _, msg in ipairs(msg_container) do
            table.insert(history, Message:new(msg))
        end
    end

    return history
end

--- @param messages Message[]
--- @param opts table|nil
--- @return Message
function ClientSession:generate_code(messages, opts)
    opts = opts or {}

    local session_messages = self:new_history(messages)

    local message = self.llmclient:create_chat_completion(session_messages)
    vim.print(message)
    local code_list = message:extract_code_blocks()

    local code = Message.concat(code_list)

    table.insert(self.messages, code)

    return code
end

return ClientSession
