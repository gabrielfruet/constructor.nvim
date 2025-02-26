local M = {}

local GroqClient = require('constructor.client.backends.groq')
local ClientSession = require('constructor.client.client')
local utils = require('constructor.client.utils')

local tblutils = require('constructor.tblutils')

function M.insert_lines(text, row)
    if type(text) == 'string' then
        text = vim.split(text, '\n')
    end

    -- Get all lines from cursor position to end
    local end_line = vim.api.nvim_buf_line_count(0)
    local lines_after = vim.api.nvim_buf_get_lines(0, row, end_line, false)

    -- Insert new lines
    vim.api.nvim_buf_set_lines(0, row, end_line, false, {})
    vim.api.nvim_buf_set_lines(0, row, row, true, text)

    -- Append the previous lines after the inserted text
    if #lines_after > 0 then
        vim.api.nvim_buf_set_lines(0, row + #text, row + #text, false, lines_after)
    end
end

---@param text string
function M.insert_at_cursor(text)
    local _, row, _ , _ = unpack(vim.fn.getpos("."))
    M.insert_lines(text, row)
end

--- Returns the selected text in the current buffer.
--- 
--- This function retrieves the text that is currently selected in the buffer,
--- either as a single line or a range of lines, and returns it as a table of strings.
--- 
--- @return string[] lines A table of strings representing the selected text.
function M.get_selection()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), 'x', true)

    local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
    local _, end_row, end_col, _ = unpack(vim.fn.getpos("'>"))

    --- Calculates the length of a line in the buffer.
    --- 
    --- This function takes into account the `vim.v.maxcol` value to determine the
    --- actual column length of the line.
    --- 
    --- @param n number The line number (1-indexed).
    --- @return number The length of the line in columns.
    local function nth_line_len(n)
        local line = vim.api.nvim_buf_get_lines(0, n-1, n, true)
        local linelen = #line
        local linecol = vim.v.maxcol == end_col and linelen or end_col
        return linecol
    end

    local fcol = nth_line_len(start_row)
    local lcol = nth_line_len(end_row)

    local line_count = vim.api.nvim_buf_line_count(0)

    if line_count == end_row then
        end_row = -1
    end

    lcol = -1

    local lines

    if start_row == end_row then
        lines = vim.api.nvim_buf_get_text(0, start_row-1, start_col-1, start_row-1, fcol, {})
    else
        lines = tblutils.join_lists{
            vim.api.nvim_buf_get_text(0, start_row-1, start_col-1, start_row-1, -1, {}),
            vim.api.nvim_buf_get_text(0, start_row, 0, end_row, lcol, {})
        }
    end

    return lines
end


--#TODO fix this function to a more clever solution
function M.replace_visual_selection(text)

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), 'x', true)
    local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
    local _, end_row, end_col, _ = unpack(vim.fn.getpos("'>"))

    local mode = vim.fn.visualmode()
    if mode == '\22' then  -- Visual block mode
        vim.api.nvim_err_writeln("Block mode is not supported")
        return
    end


    local function nth_line_len(n)
        local line = vim.api.nvim_buf_get_lines(0, n-1, n, true)[1]
        local linelen = #line
        local linecol = vim.v.maxcol == end_col and linelen or end_col
        return linecol
    end


    local fcol = nth_line_len(start_row)
    local lcol = nth_line_len(end_row)
    local lines = vim.fn.split(text, '\n')

    if start_row == end_row then
        vim.api.nvim_buf_set_text(0, start_row-1, start_col-1, start_row-1, fcol, {})

        vim.api.nvim_buf_set_text(0, start_row-1, start_col-1, start_row-1, -1, {lines[1]})
    else
        vim.api.nvim_buf_set_text(0, start_row-1, start_col-1, start_row-1, -1, {})
        vim.api.nvim_buf_set_text(0, start_row, 0, end_row-1, lcol, {})

        vim.api.nvim_buf_set_text(0, start_row-1, start_col-1, start_row-1, -1, {lines[1]})
        table.remove(lines, 1)
        M.insert_lines(lines, start_row)
    end
end

local function first_to_upper(str)
    return (str:gsub("^%l", string.upper))
end


---@param message Message
function M.write_message_to_end_of_buffer(bufnr, message)
    local Message = require('constructor.client.messages')

    message = message or Message.new{content='testing', role='user'}
    local nlines = vim.api.nvim_buf_line_count(bufnr)
    M.insert_lines(first_to_upper(message.role) .. ':\n', nlines)
    M.insert_lines(message.content, nlines+1)
end

_G.wmteob = M.write_message_to_end_of_buffer
_G.wmmteob = function ()
    local client_manager = require('constructor.client.manager'):new()

    local client = client_manager:curr()
    if client == nil then
        print('No client selected')
        return
    end

    for _, msg in ipairs(client.messages) do
        M.write_message_to_end_of_buffer(0, msg)
    end

end

function M.generate_and_replace()
    local selected_text = table.concat(M.get_selection(), '\n')

    local client = ClientSession.new(GroqClient.new(os.getenv('GROQ_API_KEY')), 'generate and replace client')
    local code = client:generate_code({
        {
            content = string.format([[
            Document the next piece of code, using the %s docstring format,

            1. Do not use comments
            2. Only use the appropriate Docstring for the language
            3. Use types when can be inferred
            4. Try to explain the main functionality of the function, not tying to the underlying logic
            5. Try to infer the types as maximum as you can.

            Code: %s]], vim.bo.filetype, selected_text),
            role='user'
        }
    })
    M.replace_visual_selection(code.content)
end

-- Map the function to a key (optional)
vim.keymap.set("v", "<C-g>", M.generate_and_replace, { noremap = true, silent = true })

return M
