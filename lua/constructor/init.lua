local M = {
    clients={}
}

require('constructor.bufops')

M.clients.groq = require('constructor.client.backends.groq')

function M.setup(opts)
end

return M



