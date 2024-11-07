---@class ClientManager
---@field clients ClientSession[]
---@field current ClientSession | nil
---@field instance ClientManager | nil
---Singleton class that manages the clients
local ClientManager = {}
ClientManager.__index = ClientManager


---Provide the ClientManager singleton instance
---@return ClientManager singleton
function ClientManager.new()
    if ClientManager.instance == nil then
        local instance = setmetatable({}, ClientManager)

        instance.clients = {}
        instance.current = nil

        ClientManager.instance = instance
    end

    return ClientManager.instance
end

---@param client ClientSession
--- If the current was nil, set it to client
function ClientManager:add_client(client)
    table.insert(self.clients, client)

    if self.current == nil then
        self.current = client
    end
end

---@return ClientSession | nil current
function ClientManager:curr()
    return self.current
end

---@param client ClientSession
---@return boolean is_managed
function ClientManager:_is_managed(client)
    local already_managed = false

    for _, client_i in pairs(self.clients) do
        if client_i == client then
            already_managed = true
            break
        end
    end

    return already_managed
end

---@param new_current ClientSession
function ClientManager:set_current(new_current)
    local already_managed = self:_is_managed(new_current)

    if not already_managed then
        self:add_client(new_current)
    end

    self.current = new_current
end

---@async
--- Uses vim.ui.select API to change the current client
function ClientManager:select()
    vim.ui.select(self.clients, {
        prompt='Select the client you want to use',
        format_item = function (item)
            return item.name
        end
    }, function (new_client)
        if new_client == nil then return end
        self.current = new_client
    end)
end

return ClientManager
