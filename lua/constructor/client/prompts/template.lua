--- @class PromptTemplate
--- @field template string
local PromptTemplate = {}
PromptTemplate.__index = PromptTemplate

function PromptTemplate:new(tbl)
    local instance = setmetatable({}, PromptTemplate)

    instance.template = tbl.template
end
