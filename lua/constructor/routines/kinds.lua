---@class RoutineMessageKinds
local RoutineMessageKinds = {}

---@alias RoutineMessageKind fun(msg: Message): Message

local Message = require'constructor.client.messages'

---@param msg Message
function RoutineMessageKinds.code(msg)
    return Message.concat(msg:extract_code_blocks())
end

---@param msg Message
function RoutineMessageKinds.text(msg)
    return msg
end

return RoutineMessageKinds
