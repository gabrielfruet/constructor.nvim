local ClientManager = {}
ClientManager.__index = ClientManager

function ClientManager.new()
    local instance = setmetatable({}, ClientManager)

    instance.clients = {}
    instance.current = nil

    return instance
end

---@param client LLMClient
function ClientManager:add_client(client)
    table.insert(self.clients, client)
end
