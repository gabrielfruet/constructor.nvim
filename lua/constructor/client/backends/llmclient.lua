--- @class LLMClient
--- Interface for objects that can start, stop, and update.
--- @field create_chat_completion fun(messages: Message[], opts: table | nil, on_stream: fun(msg: Message), on_done: fun(success: boolean)) to start the object.
local LLMClient = {}

