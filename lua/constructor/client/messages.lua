local utils = require('constructor.client.utils')

--- @class Message
--- @field role string
--- @field content string
--- @field metadata table
local Message = {}
Message.__index = Message

--- @param msg_list Message[]
--- @return Message
function Message.concat(msg_list, opts)
    opts = opts or {}
    opts.sep = opts.sep or '\n'

    if #msg_list == 0 then
        return Message.new{
            content='',
            role='user'
        }
    end

    local resulting_msg = msg_list[1]
    table.remove(msg_list, 1)
    for _, msg in ipairs(msg_list) do
        resulting_msg = resulting_msg .. opts.sep .. msg
    end

    return resulting_msg
end

function Message.new(tbl)
    if tbl == nil then
        error("llmclient is required")
    end
    local instance = setmetatable({}, Message)

    instance.role = tbl.role
    instance.content = tbl.content

    return instance
end

--- @return Message[]
function Message:extract_code_blocks()
    local codeblocks = utils.extract_code_blocks(self.content)

    local code_msg_list = {}

    for _, code in pairs(codeblocks) do
        table.insert(code_msg_list, Message.new({
            content = code,
            role = self.role
        }))
    end

    return code_msg_list
end

Message.__concat = function(left, right)
    if getmetatable(left) == Message and getmetatable(right) == Message then
        return Message.new({
            role = left.role,
            content = left.content .. right.content
        })
    end

    if getmetatable(left) == Message and type(right) == "string" then
        return Message.new({
            role = left.role,
            content = left.content .. right
        })
    end

    if type(left) == "string" and getmetatable(right) == Message then
        return Message.new({
            role = right.role,
            content = left .. right.content
        })
    end

    error("Invalid concatenation operation")
end



return Message
