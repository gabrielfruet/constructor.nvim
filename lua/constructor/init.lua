local M = {
    clients={}
}

local bufops = require('constructor.bufops')

local ClientSession = require('constructor.client.client')
local ClientManager = require('constructor.client.manager')
local GroqClient = require('constructor.client.backends.groq')
local OllamaClient = require('constructor.client.backends.ollama')
local RoutineCollection = require('constructor.routines.collection')


--- Example opts
--- opts = {
---     backends = {
---         groq = {
---             api=os.getenv(GROQ_API_KEY)
---         }
---     }
---     routine_templates = {
---         
---     }
--- }
function M.setup(opts)
    local client_manager = ClientManager.new()
    client_manager:add_client(
        ClientSession.new(GroqClient.new(os.getenv('GROQ_API_KEY')), 'Default client')
        -- ClientSession.new(OllamaClient.new('qwen2.5-coder:latest'), 'Default client')
    )

    local function select_prompt()
        local items = {}
        for _, v in pairs(RoutineCollection) do
            table.insert(items, v)
        end

        vim.ui.select(items, {
            format_item = function (item)
                return item.name
            end
        }, function (prompt, idx)
                local client = client_manager:curr()

                if client == nil then return end

                client:run_routine(prompt,
                    function (msg)
                    end)
            end)
    end

    vim.api.nvim_create_user_command('ClientSendContext', function ()
        local client = client_manager:curr()

        if client == nil then return end

        local selected = table.concat(bufops.get_selection(), '\n')
        client:add_context(selected)
    end, {})

    vim.api.nvim_create_user_command('ClientClearContext', function ()
        local client = client_manager:curr()

        if client == nil then return end

        client:clear_context()
    end, {})

    vim.api.nvim_create_user_command('ClientClearHistory', function ()
        local client = client_manager:curr()

        if client == nil then return end

        client:clear_history()
    end, {})

    vim.api.nvim_create_user_command('NewClient', function ()
        vim.ui.input({ prompt = [[What's the name of the new client?]] }, function (input)
            if input == nil then return end

            local client = ClientSession.new(GroqClient.new(os.getenv('GROQ_API_KEY')), input)

            client_manager:add_client(client)
            client_manager:set_current(client)
        end)
    end, {})

    vim.api.nvim_create_user_command('SelectClient', function ()
        client_manager:select()
    end, {})

    vim.api.nvim_create_user_command('ClientGenerate', select_prompt, {})

    vim.api.nvim_create_user_command('ClientGetContext', function ()
        local client = client_manager:curr()

        if client == nil then return end

        vim.print(client.context)
    end, {})
end

return M



