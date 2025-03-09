local bufops = require('constructor.bufops')
local Message = require('constructor.client.messages')

---@alias RoutineOutput [OnStreamCallback, OnDoneCallback]
---@alias OnStreamCallback fun(msg: Message)
---@alias OnDoneCallback fun(success: boolean)

---@class RoutineOutputs
local RoutineOutputs = {}

function RoutineOutputs.append_text()
    local streamed_msgs = {}
    ---@param msg Message
    local function on_stream(msg)
        table.insert(streamed_msgs, msg)
    end

    ---@param success boolean
    local function on_done(success)
        if success then
            local msg = Message.concat(streamed_msgs)
            bufops.insert_at_cursor(msg.content)
        end
    end

    return on_stream, on_done
end

function RoutineOutputs.replace_text()
    local streamed_msgs = {}

    ---@param msg Message
    local function on_stream(msg)
        table.insert(streamed_msgs, msg)
    end

    ---@param success boolean
    local function on_done(success)
        if success then
            local msg = Message.concat(streamed_msgs)
            bufops.replace_visual_selection(msg.content)
        end
    end

    return on_stream, on_done
end

return RoutineOutputs
