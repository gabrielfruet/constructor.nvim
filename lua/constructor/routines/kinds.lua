---@class RoutineMessageKinds
local RoutineMessageKinds = {}

---@alias RoutineMessageKind fun(msg: Message): Message | nil

local Message = require'constructor.client.messages'

---@param msg Message
---@return Message|nil
function RoutineMessageKinds.code(msg)
    if msg == nil then return nil end
    return Message.concat(msg:extract_code_blocks())
end

---@param msg Message
---@return Message|nil
function RoutineMessageKinds.text(msg)
    if msg == nil then return nil end
    return msg
end

return RoutineMessageKinds
