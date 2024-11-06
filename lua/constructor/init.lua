local M = {
    clients={}
}

local bufops = require('constructor.bufops')

local ClientSession = require('constructor.client.client')
local Groq = require('constructor.client.backends.groq')

local PromptCollection = require('constructor.client.prompts.collection')


function M.setup(opts)
    local client = ClientSession.new(Groq.new(os.getenv('GROQ_API_KEY')))

    local function select_prompt()
        local items = {}
        for _, v in pairs(PromptCollection) do
            table.insert(items, v)
        end

        vim.ui.select(items, {
            format_item = function (item)
                return item.name
            end
        }, function (prompt, idx)
            client:run_prompt(prompt, function (msg)
                bufops.insert_at_cursor(msg.content)
            end)
        end)
    end

    vim.api.nvim_create_user_command('ClientSendContext', function ()
        local selected = table.concat(bufops.get_selection(), '\n')
        client:add_context(selected)
    end, {})

    vim.api.nvim_create_user_command('ClientGenerate', select_prompt, {})

    vim.api.nvim_create_user_command('ClientGetContext', function ()
        vim.print(client.context)
    end, {})
end

return M



