---@enum RoutineKinds
local kinds = {
    CODE = 0,
    TEXT = 1
}

---@class RoutineKind
local RoutineKind = {
    kinds = kinds
}

function RoutineKind:__index(key)
    return kinds[key]
end

---@param ... string
function RoutineKind:__call(...)
    ---@type string
    local str = ...

    return RoutineKind[str:upper()]
end

return RoutineKind
