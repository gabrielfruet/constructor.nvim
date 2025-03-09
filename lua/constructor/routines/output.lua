local bufops = require('constructor.bufops')
local Message = require('constructor.client.messages')

---@alias RoutineOutput {["on_done"]: OnDoneCallback, ["on_stream"]: OnStreamCallback}
---
---@alias OnStreamCallback fun(msg: Message)
---@alias OnDoneCallback fun(success: boolean)

---@class RoutineOutputs
local RoutineOutputs = {}

---@param kind RoutineMessageKind
---@return RoutineOutput
function RoutineOutputs.append_text(kind)
    local streamed_msgs = {}
    ---@param msg Message
    local function on_stream(msg)
        table.insert(streamed_msgs, msg)
    end

    ---@param success boolean
    local function on_done(success)
        if success then
            local msg = kind(Message.concat(streamed_msgs, {sep="", role="Assistant"}))
            if msg == nil then
                return
            end
            bufops.insert_at_cursor(msg.content)
        end
    end

    return {
        on_stream=on_stream,
        on_done=on_done
    }
end

---@param kind RoutineMessageKind
---@return RoutineOutput
function RoutineOutputs.replace_text(kind)
    local streamed_msgs = {}

    ---@param msg Message
    local function on_stream(msg)
        table.insert(streamed_msgs, msg)
    end

    ---@param success boolean
    local function on_done(success)
        if success then
            local msg = kind(Message.concat(streamed_msgs, {sep="", role="Assistant"}))
            if msg == nil then
                return
            end
            bufops.replace_visual_selection(msg.content)
        end
    end

    return {
        on_stream=on_stream,
        on_done=on_done
    }
end

---@param kind RoutineMessageKind
---@return RoutineOutput
function RoutineOutputs.streamed_window(kind, opts)
    opts = opts or {}
    opts.win_opts = opts.win_opts or {}
    opts.win_opts.width = opts.win_opts.width or 100

    local line_break = opts.line_break or 80

    -- Create a new buffer with markdown filetype
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)

    -- Create a vertical split window
    vim.cmd('rightbelow vnew') -- Create a vertical split
    local win = vim.api.nvim_get_current_win() -- Get the handle of the newly created window
    vim.api.nvim_win_set_buf(win, buf) -- Set the buffer to the new window

    -- Configure window dimensions if specified in config
    if opts.win_opts and opts.win_opts.width then
        vim.api.nvim_win_set_width(win, opts.win_opts.width)
    end

    local leftover = ''
    local done = false

    local on_stream = function(msg)
        if done then return end

        -- Extract content from the message
        local content = kind(msg).content

        -- Append leftover data from the previous call
        local full_data = leftover .. content

        -- Split the full data into lines, handling newlines explicitly
        local lines = vim.split(full_data, '\n', { plain = true })

        -- The last line might be incomplete (no newline at the end), so save it as leftover
        leftover = table.remove(lines)

        -- Process each line, applying the line break logic
        for _, line in ipairs(lines) do
            local num_full_chunks = math.floor(#line / line_break)
            for i = 1, num_full_chunks do
                local start = (i - 1) * line_break + 1
                local finish = i * line_break
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line:sub(start, finish) })
            end

            -- Append any remaining part of the line (less than line_break characters)
            if #line % line_break ~= 0 then
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line:sub(num_full_chunks * line_break + 1) })
            end
        end
    end

    local on_done = function(success)
    end

    return {
        on_stream = on_stream,
        on_done = on_done
    }
end

return RoutineOutputs
