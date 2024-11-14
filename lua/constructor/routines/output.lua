local bufops = require('constructor.bufops')

---@alias RoutineOutput fun(msg: Message)

---@class RoutineOutputs
local RoutineOutputs = {}

---@param msg Message
function RoutineOutputs.append_text(msg)
    bufops.insert_at_cursor(msg.content)
end

---@param msg Message
function RoutineOutputs.replace_text(msg)
    vim.print('got here')
    bufops.replace_visual_selection(msg.content)
end

return RoutineOutputs
