local M = {}

function M.join_lists(lists)
    local final_tbl = {}

    for _, tbl in ipairs(lists) do
        for _, v in ipairs(tbl) do
            table.insert(final_tbl, v)
        end
    end

    return final_tbl
end

return M
