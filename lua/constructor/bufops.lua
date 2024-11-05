local M = {}

local GroqClient = require('constructor.client.backends.groq')
local ClientSession = require('constructor.client.client')
local utils = require('constructor.client.utils')

local tblutils = require('constructor.tblutils')

local function insert_lines(text, row)

    -- Get all lines from cursor position to end
    local end_line = vim.api.nvim_buf_line_count(0)
    local lines_after = vim.api.nvim_buf_get_lines(0, row, end_line, false)

    -- Insert new lines
    vim.api.nvim_buf_set_lines(0, row, end_line, false, {})
    vim.api.nvim_buf_set_lines(0, row, row, false, text)

    -- Append the previous lines after the inserted text
    vim.api.nvim_buf_set_lines(0, row + #text, row + #text, false, lines_after)
end

--- Returns the selected text in the current buffer.
--- 
--- This function retrieves the text that is currently selected in the buffer,
--- either as a single line or a range of lines, and returns it as a table of strings.
--- 
--- @return string[] lines A table of strings representing the selected text.
local function get_selection()
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

    local lines

    if start_row == end_row then
        lines = vim.api.nvim_buf_get_text(0, start_row-1, start_col-1, start_row-1, fcol, {})
    else
        lines = tblutils.join_lists{
            vim.api.nvim_buf_get_text(0, start_row-1, start_col-1, start_row-1, -1, {}),
            vim.api.nvim_buf_get_text(0, start_row, 0, end_row-1, lcol, {})
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
        --vim.api.nvim_buf_set_lines(0, start_row, end_row-1, false, lines)
        insert_lines(lines, start_row)
        --vim.api.nvim_buf_set_text(0, start_row, 0, end_row-1, -1, lines)
    end
end

function M.generate_and_replace()
    local selected_text = table.concat(get_selection(), '\n')

    local client = ClientSession:new(GroqClient.new(os.getenv('GROQ_API_KEY')))
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
