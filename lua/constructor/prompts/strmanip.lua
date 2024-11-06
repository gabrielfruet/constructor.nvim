local M = {}

function M.extract_fstring_vars(fstring)
    local vars = {}
    local seen = {}

    for var in fstring:gmatch("{([%w_]+)}") do
        if not seen[var] then
            table.insert(vars, var)
            seen[var] = true
        end
    end

    return vars
end

function M.substitute_fstring_var(fstring, variable, value)
    local pattern = string.format("{%s}", variable)
    local result = fstring:gsub(pattern, value)

    return result
end

return M
