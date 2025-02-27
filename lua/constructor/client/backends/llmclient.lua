--- @class LLMClient
--- Interface for objects that can start, stop, and update.
--- @field create_chat_completion fun(messages: Message[], opts: table | nil, on_done: fun(msg: Message)) to start the object.
local LLMClient = {}

