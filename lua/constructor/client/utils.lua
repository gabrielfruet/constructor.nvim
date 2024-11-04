local M = {}

M.pattern = "```[%w]*\n(.-)\n```"

--- Extracts code blocks from a given text.
--- 
--- @param text string The text to extract code blocks from.
--- @return string[] code_blocks A table containing the extracted code blocks.
function M.extract_code_blocks(text)
    local code_blocks = {}

    for code in text:gmatch(M.pattern) do
        table.insert(code_blocks, code)
    end

    return code_blocks
end


return M
