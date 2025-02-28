local M = {}

function M.create_wait_window()
    -- Create a buffer for the floating window
    local buf = vim.api.nvim_create_buf(false, true) -- Create an unlisted, scratch buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Waiting for the LLM response" })

    -- Define custom highlight groups for the floating window
    -- vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#80a0ff", bg = "#1e1e2e" }) -- Border color
    -- vim.api.nvim_set_hl(0, "FloatText", { fg = "#c0caf5", bg = "#1e1e2e" })   -- Text color
    -- vim.api.nvim_set_hl(0, "FloatElapsed", { fg = "#f7768e", bg = "#1e1e2e" }) -- Elapsed time color

    -- Apply highlights to the buffer
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_add_highlight(buf, -1, "FloatText", 0, 0, -1)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    -- Get the current editor dimensions
    local width = vim.o.columns
    local height = vim.o.lines

    -- Define the floating window dimensions and position
    local win_width = 40
    local win_height = 2
    local row = 2 -- Top margin
    local col = width - win_width - 2 -- Right margin

    -- Define the floating window options
    local opts = {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded", -- Rounded borders
        noautocmd = true,
    }

    -- Add border highlights
    opts.title = "LLM Response"
    opts.title_pos = "center"

    -- Create the floating window
    local win = vim.api.nvim_open_win(buf, false, opts) -- `false` ensures the window is not focused

    -- Animation logic for the "..."
    local dots = { "", ".", "..", "..." }
    local dot_index = 1
    local start_time = vim.loop.hrtime() -- Record the start time in nanoseconds
    local timer = vim.loop.new_timer()

    local function update_text()
        local elapsed_seconds = math.floor((vim.loop.hrtime() - start_time) / 1e9) -- Calculate elapsed time in seconds
        local base_text = string.format("Waiting for the LLM response (%ds)", elapsed_seconds)
        local text = base_text .. dots[dot_index]

        -- Update the buffer content
        vim.api.nvim_buf_set_option(buf, "modifiable", true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

        -- Highlight the elapsed time portion
        local elapsed_start = #("Waiting for the LLM response (") + 1
        local elapsed_end = elapsed_start + #tostring(elapsed_seconds) - 1
        vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1) -- Clear previous highlights
        vim.api.nvim_buf_add_highlight(buf, -1, "FloatElapsed", 0, elapsed_start, elapsed_end + 3) -- Highlight elapsed time
        vim.api.nvim_buf_add_highlight(buf, -1, "FloatText", 0, 0, -1) -- Highlight rest of the text
        vim.api.nvim_buf_set_option(buf, "modifiable", false)

        dot_index = dot_index % #dots + 1 -- Cycle through the dots
    end

    -- Start the animation loop
    timer:start(0, 500, vim.schedule_wrap(update_text)) -- Update every 500ms

    -- Function to close the window and clean up
    local function cancel()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
        if timer then
            timer:stop()
            timer:close()
        end
    end

    -- Return the cancel function
    return cancel
end

return M
