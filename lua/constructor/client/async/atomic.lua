local AtomicVar = {}
AtomicVar.__index = AtomicVar

function AtomicVar:new(value)
    local instance = setmetatable({}, value)

    instance.value = value
    --instance.mutex = ?
end
